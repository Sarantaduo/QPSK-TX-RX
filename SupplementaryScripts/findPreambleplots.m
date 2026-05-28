function [frame, is_valid] = findPreambleplots(signal, cfg)
    persistent buffer preamble_modulated

    if isempty(buffer)
        buffer = [];
        preamble_bits      = [(cfg.BarkerCode+1)/2; (cfg.BarkerCode+1)/2];
        preamble_modulated = qpskModulate(preamble_bits);
    end

    buffer   = [buffer; signal(:)];
    is_valid = false;
    frame    = [];

    if length(buffer) < cfg.FrameSize
        return;
    end

    search_len = length(buffer) - cfg.FrameSize + 1;
    if search_len < 1
        return;
    end

    pream_len  = length(preamble_modulated);
    pream_norm = norm(preamble_modulated);
    correlation = zeros(search_len, 1);

    for i = 1:search_len
        segment        = buffer(i : i + pream_len - 1);
        correlation(i) = abs(segment' * preamble_modulated) / ...
            (norm(segment) * pream_norm + eps);
    end

    [max_corr, max_idx] = max(correlation);

    if max_corr > cfg.PreambleThreshold
        frame           = buffer(max_idx : max_idx + cfg.FrameSize - 1);
        is_valid        = true;
        buffer_snapshot = buffer;
        buffer          = buffer(max_idx + cfg.FrameSize : end);
        fprintf('Поиск преамбулы: найдена! Корреляция = %.2f, позиция = %d\n', max_corr, max_idx);
        plotDetection(correlation, buffer_snapshot, max_idx, max_corr, pream_len, cfg);
    else
        if length(buffer) > cfg.FrameSize * 3
            buffer = buffer(end - cfg.FrameSize : end);
        end
        fprintf('Поиск преамбулы: max корреляция = %.2f (порог = %.2f)\n', max_corr, cfg.PreambleThreshold);
    end
end

function plotDetection(correlation, buf, max_idx, max_corr, pream_len, cfg)
    figure('Name', 'Preamble Detection', 'NumberTitle', 'off', ...
           'Position', [150 100 980 580]);

    fr_hi            = min(max_idx + cfg.FrameSize - 1, length(buf));
    pr_hi            = min(max_idx + pream_len - 1, length(buf));
    frame_re         = real(buf(max_idx:fr_hi));
    n_frame          = length(frame_re);
    pr_len_in_frame  = pr_hi - max_idx + 1;

    % ── Верхний: корреляция ───────────────────────────────────────────────
    ax1 = subplot(2,1,1);
    plot(1:length(correlation), correlation, ...
         'Color', [0.35 0.70 0.95], 'LineWidth', 1.4);
    hold on;

    yline(cfg.PreambleThreshold, '--', ...
          'Color', [1.0 0.55 0.20], 'LineWidth', 1.6, ...
          'Label', sprintf('threshold = %.2f', cfg.PreambleThreshold), ...
          'LabelVerticalAlignment', 'bottom', ...
          'LabelHorizontalAlignment', 'right');

    plot(max_idx, max_corr, 'o', ...
         'MarkerSize', 10, 'MarkerFaceColor', [0.25 0.88 0.45], ...
         'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
    text(max_idx + length(correlation)*0.02, max_corr - 0.08, ...
         sprintf('R = %.3f', max_corr), ...
         'FontSize', 9, 'Color', [0.25 0.88 0.45], 'FontWeight', 'bold');

    xlim([1 length(correlation)]);
    ylim([0 1.15]);
    xlabel('Symbol index');
    ylabel('R(i)');
    title('Normalised cross-correlation with preamble');
    grid on;

    % ── Нижний: кадр ─────────────────────────────────────────────────────
    ax2 = subplot(2,1,2);
    plot(1:n_frame, frame_re, 'Color', [0.55 0.65 0.85], 'LineWidth', 0.9);
    hold on;

    y_lo = min(frame_re) * 1.2;
    y_hi = max(frame_re) * 1.2;

    % Преамбула — зелёный
    patch([1 1 pr_len_in_frame pr_len_in_frame], [y_lo y_hi y_hi y_lo], ...
          [0.25 0.88 0.45], 'FaceAlpha', 0.15, 'EdgeColor', 'none');

    % Payload — синий
    patch([pr_len_in_frame pr_len_in_frame n_frame n_frame], [y_lo y_hi y_hi y_lo], ...
          [0.35 0.55 0.95], 'FaceAlpha', 0.10, 'EdgeColor', 'none');

    % Линии
    xline(1, '-', 'Color', [0.25 0.88 0.45], 'LineWidth', 1.8, ...
          'LabelVerticalAlignment', 'bottom');
    xline(pr_len_in_frame, '--', 'Color', [0.60 0.60 0.60], 'LineWidth', 1.2);

    % Подписи регионов
    text(pr_len_in_frame / 2, y_hi * 0.75, 'preamble', ...
         'HorizontalAlignment', 'center', 'FontSize', 9, ...
         'Color', [0.20 0.75 0.35], 'FontWeight', 'bold');
    text(pr_len_in_frame + (n_frame - pr_len_in_frame)/2, y_hi * 0.75, 'payload', ...
         'HorizontalAlignment', 'center', 'FontSize', 9, ...
         'Color', [0.45 0.65 0.95], 'FontWeight', 'bold');

    xlim([1 n_frame]);
    ylim([y_lo y_hi]);
    xlabel('Symbol index (within frame)');
    ylabel('Re\{symbols\}  (a.u.)');
    title('Extracted frame');
    grid on;

    drawnow;
end
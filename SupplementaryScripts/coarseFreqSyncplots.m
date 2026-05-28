function [corrected, freq_offset] = coarseFreqSyncplots(signal, cfg)
%COARSEFREQSYNC - грубая частотная оценка (метод x^4)

    signal_4 = signal .^ 4;

    N          = length(signal_4);
    fft_4_sh   = fftshift(abs(fft(signal_4)));
    fft_raw_sh = fftshift(abs(fft(signal)));

    fs        = cfg.Fs/2;
    freq_axis = (-N/2 : N/2-1) * fs / N;

    [peak_val, max_idx] = max(fft_4_sh);
    noise_floor = mean(fft_4_sh);

    if peak_val < 5 * noise_floor
        freq_offset = 0;
        corrected   = signal;
        fprintf('Частотная синхронизация: офсет не обнаружен (пик/шум = %.1f)\n', ...
                peak_val / noise_floor);
        plotSpectra(freq_axis, fft_raw_sh, fft_4_sh, 0, false);
        return;
    end

    freq_offset = freq_axis(max_idx) / 4;
    freq_offset = max(min(freq_offset, cfg.MaxFreqOffset), -cfg.MaxFreqOffset);

    t         = (0 : length(signal)-1)' / fs;
    corrected = signal .* exp(-1i * 2 * pi * freq_offset * t);

    fprintf('Частотная синхронизация: offset = %.1f Hz (пик/шум = %.1f)\n', ...
            freq_offset, peak_val / noise_floor);

    plotSpectr(freq_axis, fft_raw_sh, fft_4_sh, freq_offset, true);
end

function plotSpectr(freq_axis, spec_raw, spec_4, freq_offset, found)
    freq_kHz   = freq_axis / 1e3;
    raw_db     = 20*log10(spec_raw / max(spec_raw) + eps);
    s4_db      = 20*log10(spec_4  / max(spec_4)   + eps);

    figure('Name', 'Грубая частотная синхронизация', ...
           'NumberTitle', 'off', 'Position', [100 100 960 560]);

    % ── Спектр входного сигнала ──────────────────────────────────────────
    subplot(2,1,1);
    plot(freq_kHz, raw_db, 'Color', [0.30 0.65 0.90], 'LineWidth', 1.3);
    grid on;
    ylabel('dB');
    title('Spectrum of signal');
    xlim([freq_kHz(1) freq_kHz(end)]);
    ylim([-60 5]);

   

    % ── Спектр signal^4 ──────────────────────────────────────────────────
    subplot(2,1,2);
    plot(freq_kHz, s4_db, 'Color', [0.40 0.85 0.50], 'LineWidth', 1.3);
    hold on;
    grid on;
    xlabel('Frequency, kHz');
    ylabel('dB');
    title('Spectrum of signal^4');
    xlim([freq_kHz(1) freq_kHz(end)]);
    ylim([-60 5]);

    if found
        peak_kHz = freq_offset * 4 / 1e3;
        [~, idx] = min(abs(freq_kHz - peak_kHz));
        xline(peak_kHz, '--', ...
              'Color', [1.0 0.45 0.20], 'LineWidth', 1.6, ...
              'Label', sprintf('4·Δf = %.0f Гц', freq_offset*4), ...
              'LabelVerticalAlignment', 'bottom', ...
              'LabelHorizontalAlignment', 'right', ...
              'FontSize', 9);
        plot(freq_kHz(idx), s4_db(idx), 'o', ...
             'MarkerSize', 8, 'MarkerFaceColor', [1.0 0.45 0.20], ...
             'MarkerEdgeColor', 'w', 'LineWidth', 1.4);
    end

    drawnow;
end
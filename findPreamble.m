function [frame, is_valid] = findPreamble(signal, cfg)
    % FINDPREAMBLE - Поиск преамбулы через корреляцию
 
    persistent buffer preamble_modulated
 
    if isempty(buffer)
        buffer = [];
        % Модулированная преамбула — точно как в передатчике
        preamble_bits  = [(cfg.BarkerCode+1)/2; (cfg.BarkerCode+1)/2]; % 26 бит
        preamble_modulated = qpskModulate(preamble_bits);               % 13 символов
    end
 
    % Накапливаем символы
    buffer = [buffer; signal(:)];
 
    is_valid = false;
    frame    = [];
 
    if length(buffer) < cfg.FrameSize
        return;
    end
 
 
    search_len = length(buffer) - cfg.FrameSize + 1;
 
 
    % Нормализованная корреляция
    pream_len   = length(preamble_modulated);
    pream_norm  = norm(preamble_modulated);
    correlation = zeros(search_len, 1);
 
    for i = 1:search_len
        segment       = buffer(i : i + pream_len - 1);
        correlation(i) = abs(segment' * preamble_modulated) / ...
            (norm(segment) * pream_norm + eps);
    end
 
    % Ищем максимум
    [max_corr, max_idx] = max(correlation);
 
    if max_corr > cfg.PreambleThreshold
        % Вырезаем кадр начиная с начала преамбулы
        frame    = buffer(max_idx : max_idx + cfg.FrameSize - 1);
        is_valid = true;
        buffer   = buffer(max_idx + cfg.FrameSize : end);
        fprintf('Поиск преамбулы: найдена! Корреляция = %.2f, позиция = %d\n', max_corr, max_idx);
    else
        % Преамбула не найдена — обрезаем буфер чтобы не рос бесконечно
        if length(buffer) > cfg.FrameSize * 3
            buffer = buffer(end - cfg.FrameSize : end);
        end
        fprintf('Поиск преамбулы: max корреляция = %.2f (порог = %.2f)\n', max_corr, cfg.PreambleThreshold);
    end
end
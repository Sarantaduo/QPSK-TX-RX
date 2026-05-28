function [corrected, freq_offset] = coarseFreqSync(signal, cfg)
%СOARSEFREQSYNC - грубая частотная оценка
    signal_4 = signal.^4;

    N = length(signal_4);
    fft_signal = fftshift(fft(signal_4));
    fft_abs = abs(fft_signal);
    % Частотная ось — используем полную частоту дискретизации
    if cfg.UseTimeRec
        fs = cfg.Fs;
    else
        fs = cfg.Fs/2;
    end
    freq_axis = (-N/2 : N/2-1) * fs / N;

    % Ищем максимум 
    [peak_val, max_idx] = max(fft_abs);

    % Проверяем: реальный пик или шум?
    % Если пик не выделяется на фоне среднего — офсет незначителен
    noise_floor = mean(fft_abs);
    if peak_val < 3 * noise_floor
        freq_offset = 0;
        corrected = signal;
        fprintf('Частотная синхронизация: офсет не обнаружен (пик/шум = %.1f)\n', ...
                peak_val / noise_floor);
        return;
    end

    freq_offset = freq_axis(max_idx) / 4;

    % Ограничиваем разумным диапазоном
    freq_offset = max(min(freq_offset, cfg.MaxFreqOffset), -cfg.MaxFreqOffset);

    t = (0:length(signal)-1)' / fs;
    corrected = signal .* exp(-1i * 2 * pi * freq_offset * t);

    fprintf('Частотная синхронизация: offset = %.1f Hz (пик/шум = %.1f)\n', ...
            freq_offset, peak_val / noise_floor);
end
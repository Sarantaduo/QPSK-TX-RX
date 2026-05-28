function rx_signal = channel(tx_signal, snr_db, cfg)
    % CHANNEL - Частотный сдвиг + дробная временная задержка + AWGN
    %
    % Задержка меняется от вызова к вызову (треугольник),
    % чтобы тестировать symbolTimingSync при разных timing offset.

    persistent pfo delay_obj call_count

    freq_offset  = 1500;   % Гц
    phase_offset = 47;     % градусы

    % Параметры переменной задержки
    delay_step = 0.1;      % отсчётов за вызов
    delay_max  = 1.0;      % максимум отсчётов
    delay_min  = 0.1;

    if isempty(pfo)
        pfo = comm.PhaseFrequencyOffset( ...
            'PhaseOffset',     phase_offset, ...
            'FrequencyOffset', freq_offset, ...
            'SampleRate',      cfg.Fs);
        delay_obj  = dsp.VariableFractionalDelay( ...
            'MaximumDelay',    ceil(delay_max) + 2);
        call_count = 0;
    end

    % Треугольная задержка
    period = 2 * delay_max / delay_step;
    idx    = mod(call_count, period);
    if idx <= delay_max / delay_step
        delay = delay_min + idx * delay_step;
    else
        delay = 2 * delay_max - idx * delay_step;
    end
    delay = cast(delay, 'like', real(tx_signal));

    % Пайплайн канала
    rx_signal = pfo(tx_signal);
    rx_signal = delay_obj(rx_signal, delay);
    rx_signal = awgn(rx_signal, snr_db, 'measured');

    %call_count = call_count +1;

    fprintf('Канал: SNR = %d dB, freq offset = %d Hz, delay = %.2f samples\n', ...
        snr_db, freq_offset, delay);
end
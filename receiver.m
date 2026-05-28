function [rx_bits, decoded_text, ber] = receiver(rx_signal, cfg)
    % RECEIVER - Полный пайплайн приёмника
 
    persistent agc
   %% Матлабовские обьекты
    K = 1;
    A = 1/sqrt(2);
    TimingRec = comm.SymbolSynchronizer( ...
                'TimingErrorDetector',      'Zero-Crossing (decision-directed)', ...
                'SamplesPerSymbol',         2, ...
                'DampingFactor',            1, ...
                'NormalizedLoopBandwidth',  cfg.TimingLoopBW, ...
                'DetectorGain',             2.7*2*K*A^2+2.7*2*K*A^2);
    if isempty(agc)
        agc = comm.AGC('DesiredOutputPower', 2, ...
            'AveragingLength', 50, 'MaxPowerGain', 20);
    end
 
    %% 1. АРУ
    agc_signal = agc(rx_signal);
 
    %% 2. Согласованный фильтр (RRC)
    filtered_signal = pulseShape(agc_signal, cfg, 'rx');
    
    %% 3. Грубая частотная синхронизация
    [freq_corrected] = coarseFreqSync(filtered_signal, cfg);
 
    %% 4. Символьная синхронизация (Гарднер)
    if cfg.UseTimeRec
        timing_signal = symbolTimingSync(freq_corrected, cfg);
        %timing_signal = TimingRec(freq_corrected);
    else
        timing_signal=freq_corrected;
    end
    %% 5. Тонкая фазовая синхронизация (ФАПЧ)
    phase_corrected = carrierSync(timing_signal, cfg);
 
    %% 6. Поиск преамбулы и извлечение кадра
    [frame, is_valid] = findPreamble(phase_corrected, cfg);
 
    %% 7. Декодирование
    if is_valid
        [rx_bits, decoded_text] = decodeFrame(frame, cfg);
        ref_bits      = generateBits(cfg);
        [~, ber] = biterr(ref_bits, rx_bits);
    else
        rx_bits      = [];
        decoded_text = '';
        ber          = 0.5;
        fprintf('Приёмник: Преамбула не найдена!\n');
    end
end
 
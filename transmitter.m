function tx_signal = transmitter(cfg)
    % TRANSMITTER - Пайплайн передатчика
    
    %% 1. Генерация битов сообщения
    data_bits = generateBits(cfg);
    
    %% 2. Скремблирование
    scrambled_bits = scramble_builtin(data_bits, cfg, 'scramble');
    
    %% 3. Добавление преамбулы
    frame_bits = addPreamble(scrambled_bits, cfg);
    
    %% 4. QPSK модуляция
    modulated = qpskModulate(frame_bits);
    
    %% 5. Фильтрация (RRC)
    tx_signal = pulseShape(modulated, cfg, 'tx');
    
    fprintf('Передатчик: сгенерирован сигнал длиной %d сэмплов\n', length(tx_signal));
end
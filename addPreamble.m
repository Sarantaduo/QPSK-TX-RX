function frame = addPreamble(data_bits, cfg)
    % ADDPREAMBLE - Добавляет преамбулу Баркера к данным
    preamble=(cfg.BarkerCode+1)/2;
    % Дублируем Barker code для надёжности
    pr = [preamble;preamble];
    
    % Объединяем
    frame = [pr; data_bits];
end
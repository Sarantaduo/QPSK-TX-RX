function symbols = qpskModulate(bits)
    % QPSKMODULATE - QPSK модуляция с Gray кодированием
    
    % Убеждаемся, что чётное число бит
    if mod(length(bits), 2) ~= 0
        bits = [bits; 0];
    end
    
    % Группируем биты по 2
    bit_pairs = reshape(bits, 2, [])';
    
    % Преобразуем в индексы (0-3)
    indices = bit_pairs(:, 1) * 2 + bit_pairs(:, 2);
    
    % QPSK созвездие с поворотом pi/4 (Gray coded)
    constellation = exp(1i * pi/4) * [1; 1i; -1; -1i];
    
    % Gray перестановка
    gray_mapping = [0; 1; 3; 2]; % Bitxor c bitshift
    constellation = constellation(gray_mapping + 1);
    
    % Модуляция
    symbols = constellation(indices + 1);
end
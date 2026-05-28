function [descrambled_bits, decoded_text] = decodeFrame(frame, cfg)
    % DECODEFRAME - Демодуляция и декодирование кадра
 
    % Известные символы преамбулы (как в передатчике)
    preamble_bits  = [(cfg.BarkerCode+1)/2; (cfg.BarkerCode+1)/2];
    known_preamble = qpskModulate(preamble_bits); % 13 символов
 
    % Принятые символы преамбулы — первые HeaderLength символов кадра
    rx_preamble = frame(1:cfg.HeaderLength);
 
    %% Разрешение фазовой неоднозначности QPSK
    % ФАПЧ может захватить любой из 4 квадрантов (0/90/180/270°).
    % Сравниваем повёрнутые принятые символы преамбулы с эталоном
    % и выбираем поворот с максимальной вещественной корреляцией.
    best_corr     = -Inf;
    best_rotation = 0;

    for k = 0:3
        rot = exp(1i * k * pi/2);
        c   = real(sum(rx_preamble * rot .* conj(known_preamble)));
        if c > best_corr
            best_corr     = c;
            best_rotation = k;
        end
    end

    % Корректируем весь кадр найденным поворотом
    frame_corrected = frame * exp(1i * best_rotation * pi/2);
    fprintf('Декодер: компенсация поворота = %d × 90°\n', best_rotation);
 
    %% 1. QPSK демодуляция
    rx_bits = qpskDemodulate(frame_corrected);
 
    %% 2. Удаление преамбулы
    % HeaderBits = 26 бит — ровно столько занимает преамбула после демодуляции
    data_bits = rx_bits(cfg.HeaderBits + 1 : end);
 
    %% 3. Дескремблирование
    descrambled_bits = scramble_builtin(data_bits, cfg, 'descramble');
 
    %% 4. Конвертация в текст
    decoded_text = bitsToText(descrambled_bits);
 
    fprintf('Декодер: получено %d бит данных\n', length(descrambled_bits));
end
 
% -------------------------------------------------------------------------
function bits = qpskDemodulate(symbols)
    constellation = exp(1i * pi/4) * [1; 1i; -1; -1i];
    gray_mapping  = [0; 1; 3; 2];
    constellation = constellation(gray_mapping + 1);
 
    bits = zeros(2 * length(symbols), 1);
    for i = 1:length(symbols)
        [~, idx]    = min(abs(symbols(i) - constellation));
        symbol      = idx -1;
        bits(2*i-1) = bitand(symbol, 2) > 0;
        bits(2*i)   = bitand(symbol, 1) > 0;
    end
end
 
% -------------------------------------------------------------------------
function text = bitsToText(bits)
text = int8(bi2de(reshape(bits, 7, [])', 'left-msb'));
end
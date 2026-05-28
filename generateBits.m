function bits = generateBits(cfg)
    % GENERATEBITS - Создаёт битовый поток сообщений
    
    bits = [];
    for k = 0:(cfg.MessageCount - 1)
        % Формируем сообщение: "Hello world 000\n"
        msg = sprintf('%s %03d\n', cfg.MessageText, mod(k, 100));
        % Конвертируем в биты (7 бит на символ ASCII)
        msg_bits = reshape(dec2bin(uint8(msg), 7)' - '0', [], 1);
        bits = [bits; msg_bits]; %#ok<AGROW>
    end
end
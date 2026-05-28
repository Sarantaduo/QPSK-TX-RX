%% MAIN 
clear; close all; clc; clear functions;
addpath(fullfile(pwd, 'SupplementaryScripts/'));
%% Конфигурация
cfg = config();

%% SNR для тестирования
snr_range = 10:2:10;  % dB
ber_results = zeros(size(snr_range));

fprintf('=== QPSK Система связи ===\n');
fprintf('Частота дискретизации: %.0f kHz\n', cfg.Fs/1000);
fprintf('Символьная скорость: %.0f kHz\n', cfg.SymbolRate/1000);
fprintf('Размер кадра: %d символов\n', cfg.FrameSize);
fprintf('=========================\n\n');

%% Тестирование для разных SNR
for idx = 1:length(snr_range)


    snr = snr_range(idx);
    fprintf('\n--- Тест SNR = %d dB ---  \n', snr);
    
    for i =1:cfg.NumberOfFrames
    % Передатчик
    tx = transmitter(cfg);
    
    % Канал
    rx = channel(tx, snr, cfg);
    
    % Приёмник
    [~, decoded_text, ber] = receiver(rx, cfg);
    
    ber_results(idx,i) = ber;
    
    if ~isempty(decoded_text)
        fprintf('---Фрейм %d ---\n Декодированный текст:\n%s\n',i, decoded_text);
    end
    end
end
%% График BER vs SNR
figure;
semilogy(snr_range, ber_results(:,1), 'b-o', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('BER vs SNR для QPSK системы');
hold on;

% Теоретическая кривая QPSK
snr_theory = 0:0.5:10;
ber_theory = 0.5 * erfc(sqrt(10.^(snr_theory/10)));
semilogy(snr_theory, ber_theory, 'r--', 'LineWidth', 1);
legend('Симуляция', 'Теория QPSK');

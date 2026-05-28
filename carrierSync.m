function corrected = carrierSync(signal, cfg)
%CARRIERSYNC - ФАПЧ    
persistent phase_acc freq_acc

    if isempty(phase_acc)
        phase_acc = 0;
        freq_acc  = 0;
    end

    Bn      = cfg.PhaseLoopBW;
    damping = 0.707;

    theta = Bn / (damping + 1/(4*damping));
    d     = 1 + 2*damping*theta + theta^2;
    alpha = 4*damping*theta / d;
    beta  = 4*theta^2       / d;

    corrected = zeros(size(signal));

    for n = 1:length(signal)
        % Коррекция текущим накопленным значением фазы
        corrected(n) = signal(n) * exp(-1i * phase_acc);

        % Фазовый детектор QPSK (decision-directed)
        e = sign(real(corrected(n))) * imag(corrected(n)) - ...
            sign(imag(corrected(n))) * real(corrected(n));

        % Сначала обновляем фазу 
        phase_acc = phase_acc + alpha * e + freq_acc;

        % Потом обновляем интегратор
        freq_acc = freq_acc + beta * e;

    end
end
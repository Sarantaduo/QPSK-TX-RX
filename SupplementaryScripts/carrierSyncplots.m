function corrected = carrierSync(signal, cfg)
%CARRIERSYNC - ФАПЧ (decision-directed PLL)

    persistent phase_acc freq_acc phase_history error_history

    if isempty(phase_acc)
        phase_acc     = 0;
        freq_acc      = 0;
        phase_history = [];
        error_history = [];
    end

    Bn      = cfg.PhaseLoopBW;
    damping = 0.707;
    theta   = Bn / (damping + 1/(4*damping));
    d       = 1 + 2*damping*theta + theta^2;
    alpha   = 4*damping*theta / d;
    beta    = 4*theta^2       / d;

    corrected = zeros(size(signal));
    e_vec     = zeros(size(signal));
    ph_vec    = zeros(size(signal));

    for n = 1:length(signal)
        corrected(n) = signal(n) * exp(-1i * phase_acc);

        e = sign(real(corrected(n))) * imag(corrected(n)) - ...
            sign(imag(corrected(n))) * real(corrected(n));

        e_vec(n)  = e;
        ph_vec(n) = phase_acc;

        phase_acc = phase_acc + alpha * e + freq_acc;
        freq_acc  = freq_acc  + beta  * e;
    end

    phase_history = [phase_history; ph_vec];
    error_history = [error_history; e_vec];

    plotPhaseDetector(signal, corrected);
    plotPIFilter(error_history, alpha, beta);
    plotNCO(phase_history);
end

% =========================================================================
function plotPhaseDetector(raw, corrected)
% Слайд 1: Фазовый детектор — характеристика + созвездие до/после

    figure('Name', 'PLL — Phase Detector', 'NumberTitle', 'off', ...
           'Position', [100 400 1050 400]);

    % Теоретическая характеристика
    phi   = linspace(-pi, pi, 500);
    e_phi = sin(2*phi) / 2;

    subplot(1,3,1);
    plot(phi*180/pi, e_phi, 'Color', [0.35 0.70 0.95], 'LineWidth', 2);
    hold on;
    xline(0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);
    yline(0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);
    plot(-180:90:180, zeros(1,5), 'o', ...
         'MarkerSize', 7, 'MarkerFaceColor', [0.25 0.88 0.45], ...
         'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
    xlabel('Phase error \phi (deg)');
    ylabel('e(\phi)');
    title('Detector characteristic');
    xticks(-180:90:180);
    grid on;

    N = min(600, length(raw));

    subplot(1,3,2);
    scatter(real(raw(1:N)), imag(raw(1:N)), 10, ...
            [0.85 0.40 0.40], 'filled', 'MarkerFaceAlpha', 0.5);
    hold on; plotQPSKpoints();
    title('Constellation — before');
    xlabel('I'); ylabel('Q');
    axis equal; grid on; xlim([-2 2]); ylim([-2 2]);

    subplot(1,3,3);
    scatter(real(corrected(1:N)), imag(corrected(1:N)), 10, ...
            [0.25 0.88 0.45], 'filled', 'MarkerFaceAlpha', 0.5);
    hold on; plotQPSKpoints();
    title('Constellation — after');
    xlabel('I'); ylabel('Q');
    axis equal; grid on; xlim([-2 2]); ylim([-2 2]);

    sgtitle('Phase Detector', 'FontSize', 12, 'FontWeight', 'bold');
    drawnow;
end

% =========================================================================
function plotPIFilter(err_hist, alpha, beta)
% Слайд 2: PI фильтр — коэффициенты + сходимость ошибки

    figure('Name', 'PLL — PI Filter', 'NumberTitle', 'off', ...
           'Position', [100 250 1050 400]);

    % Импульсная характеристика PI
    subplot(1,2,1);
    n_imp = 0:30;
    h     = beta * ones(size(n_imp));
    h(1)  = h(1) + alpha;
    stem(n_imp, h, 'Color', [0.35 0.70 0.95], ...
         'MarkerFaceColor', [0.35 0.70 0.95], ...
         'LineWidth', 1.3, 'MarkerSize', 5);
    hold on;
    stem(0, alpha, 'Color', [1.0 0.55 0.20], ...
         'MarkerFaceColor', [1.0 0.55 0.20], 'LineWidth', 1.8, 'MarkerSize', 7);
    text(1, alpha*1.15, sprintf('\\alpha = %.4f', alpha), ...
         'FontSize', 9, 'Color', [1.0 0.55 0.20], 'FontWeight', 'bold');
    text(8, beta*2.5, sprintf('\\beta = %.5f', beta), ...
         'FontSize', 9, 'Color', [0.35 0.70 0.95], 'FontWeight', 'bold');
    xlabel('n'); ylabel('h(n)');
    title('PI filter impulse response');
    grid on;

    % Сходимость ошибки
    subplot(1,2,2);
    n_e = 1:length(err_hist);
    plot(n_e, err_hist, 'Color', [0.75 0.55 0.90], 'LineWidth', 0.7);
    hold on;
    win = min(60, floor(length(err_hist)/8));
    if win > 1
        plot(n_e, movmean(err_hist, win), ...
             'Color', [1.0 0.55 0.20], 'LineWidth', 2.0);
        legend('e(n)', sprintf('moving avg (%d)', win), ...
               'Location', 'northeast', 'FontSize', 8);
    end
    yline(0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    xlabel('Symbol index'); ylabel('e(n)');
    title('Phase error — convergence');
    grid on;

    sgtitle('PI Loop Filter', 'FontSize', 12, 'FontWeight', 'bold');
    drawnow;
end

% =========================================================================
function plotNCO(phase_hist)
% Слайд 3: NCO — накопленная фаза + мгновенная коррекция

    figure('Name', 'PLL — NCO', 'NumberTitle', 'off', ...
           'Position', [100 100 1050 400]);

    subplot(1,2,1);
    plot(1:length(phase_hist), phase_hist*180/pi, ...
         'Color', [0.35 0.70 0.95], 'LineWidth', 1.5);
    hold on;
    yline(0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    xlabel('Symbol index'); ylabel('\hat{\phi}(n)  (deg)');
    title('Accumulated phase');
    grid on;

    subplot(1,2,2);
    dphi = diff(phase_hist) * 180/pi;
    plot(dphi, 'Color', [0.40 0.85 0.50], 'LineWidth', 0.9);
    hold on;
    win = min(60, floor(length(dphi)/8));
    if win > 1
        plot(movmean(dphi, win), 'Color', [1.0 0.55 0.20], 'LineWidth', 2.0);
        legend('d\phi/dn', sprintf('moving avg (%d)', win), ...
               'Location', 'northeast', 'FontSize', 8);
    end
    yline(0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    xlabel('Symbol index'); ylabel('deg / sample');
    title('Instantaneous frequency correction');
    grid on;

    sgtitle('NCO — Numerically Controlled Oscillator', ...
            'FontSize', 12, 'FontWeight', 'bold');
    drawnow;
end

% ── QPSK ideal points ─────────────────────────────────────────────────────
function plotQPSKpoints()
    pts = exp(1i*pi/4) * [1; 1i; -1; -1i];
    plot(real(pts), imag(pts), '+', ...
         'MarkerSize', 12, 'LineWidth', 2, 'Color', [0.6 0.6 0.6]);
end
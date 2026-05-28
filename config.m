function cfg = config()
    % CONFIG - Все параметры системы в одном месте
 
    %% Общие параметры
    cfg.Fs = 1e6;                    % Частота дискретизации
    cfg.SymbolRate = 500e3;          % Символьная скорость
    cfg.SamplesPerSymbol = cfg.Fs / cfg.SymbolRate; % 2 сэмпла на символ
    cfg.ModulationOrder = 4;         % QPSK
    cfg.UseTimeRec = 0;

    
    %% Параметры кадра
    cfg.BarkerCode = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'; % Barker-13
 
    % Преамбула: 2 × Barker-13 = 26 бит → 13 символов QPSK
    cfg.HeaderBits   = 26;                          % бит преамбулы
    cfg.HeaderLength = cfg.HeaderBits / log2(4);    % = 13 символов (для findPreamble/FrameSize)
 
    cfg.MessageText   = 'Hello world';              % Текст сообщения
    cfg.MessageCount  = 20;                         % Сообщений в кадре
    cfg.MessageLength = length(cfg.MessageText) + 5;% +5 для ' 000\n'
    cfg.PayloadBits   = cfg.MessageCount * cfg.MessageLength * 7; % Всего бит данных
 
    % FrameSize в символах: (биты преамбулы + биты данных) / бит на символ
    cfg.FrameSize = (cfg.HeaderBits + cfg.PayloadBits) / log2(cfg.ModulationOrder);
    cfg.NumberOfFrames = 1;                        % Количество фреймов
    %% Параметры скремблера
    cfg.ScramblerBase              = 2;
    cfg.ScramblerPolynomial        = [1 1 1 0 1];
    cfg.ScramblerInitialConditions = [0 0 0 0];
 
    %% Параметры RRC фильтра
    cfg.RolloffFactor = 0.5;
    cfg.FilterSpan    = 10;
 
    %% Параметры синхронизации
    cfg.PreambleThreshold = 0.6;   % Порог обнаружения преамбулы (0-1)
    cfg.MaxFreqOffset     = 5000;  % Максимальная частотная отстройка (Гц)
    cfg.PhaseLoopBW       = 0.01;  % Полоса ФАПЧ для фазовой синхронизации
    cfg.TimingLoopBW      = 0.001;  % Полоса для символьной синхронизации
 
    %% SDR параметры (для будущего использования)
    cfg.SDR.CenterFrequency = 915e6;     % Несущая частота
    cfg.SDR.Gain            = 30;        % Усиление
    cfg.SDR.Platform        = 'simulation'; % 'simulation', 'Pluto', 'B200'
end
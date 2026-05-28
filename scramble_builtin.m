function output = scramble_builtin(input_bits, cfg, mode)
    % SCRAMBLE_BUILTIN - Скремблирование/дескремблирование через comm.Scrambler
    

 
    if strcmp(mode, 'scramble')
        sc     = comm.Scrambler(cfg.ScramblerBase, ...
                     cfg.ScramblerPolynomial, cfg.ScramblerInitialConditions);
        output = sc(input_bits);
    else
        dsc    = comm.Descrambler(cfg.ScramblerBase, ...
                     cfg.ScramblerPolynomial, cfg.ScramblerInitialConditions);
        output = dsc(input_bits);
    end
end
 
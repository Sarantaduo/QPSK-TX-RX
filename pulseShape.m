function signal = pulseShape(symbols, cfg, direction)
%PULSESHAPE - Raised cosine matched filter
    persistent rrc_filter
    if isempty(rrc_filter)
        rrc_filter = rcosdesign(cfg.RolloffFactor, ...
            cfg.FilterSpan, cfg.SamplesPerSymbol, 'sqrt');
       
    end

    if strcmp(direction, 'tx')
        signal = upfirdn(symbols, rrc_filter, cfg.SamplesPerSymbol, 1);
      
    else
        if cfg.UseTimeRec
        signal = upfirdn(symbols, rrc_filter, 1, 1);
        else
        signal = upfirdn(symbols, rrc_filter, 1, cfg.SamplesPerSymbol);

        end
    end
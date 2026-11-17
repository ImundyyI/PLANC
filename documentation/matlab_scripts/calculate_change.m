clear;
clc;
close all;

format long g;
val1 = load("hallway_chatter_anc.mat");
val2 = load("hallway_chatter_no_anc.mat");
val = [val1, val2];
names = ["ANC", "No ANC"];

n = numel(val);
ref_rms = zeros(1, n);
err_rms = zeros(1, n);

figure;
for i = 1:n
    ref = val(i).ref_plot;
    err = val(i).err_plot;
    err_offset = mean(err);
    ref_offset = mean(ref);
    % get rms value of both err and ref
    ref_rms(i) = rms(ref);
    err_rms(i) = rms(err);

    subplot(n, 1, i);
    plot(ref);
    hold on;
    plot(err);
    hold off;
    title(string(names(i)));
    xlabel('Sample');
    ylabel('Amplitude');
    ylim([-6 * 10^6, 6 * 10^6]);
    legend('Reference', 'Error');

    % calculate reduction ratio in dB.
    ratio = 20 .* log10(err_rms ./ ref_rms);
    msg = sprintf('Ref RMS: %.3g\nErr RMS: %.3g\nReduction: %.2f dB', ...
        ref_rms(i), err_rms(i), ratio(i));
    text(0.02, 0.95, msg, 'Units', 'normalized', ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
        'BackgroundColor', 'b', 'EdgeColor', 'k', 'Margin', 4);

end 

% ratio = 20 .* log10(err_rms ./ ref_rms)
% ratio


% sound(ref, 48.8 * 10^3);
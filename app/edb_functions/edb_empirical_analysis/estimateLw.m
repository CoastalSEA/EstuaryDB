function out = estimateLw(inp)
%
%-------function help------------------------------------------------------
% NAME
%   estimateLw.m
% PURPOSE
%   Estimate the width convergence length (Lw) of a single-reach,
%   exponentially convergent tidal estuary, combining an analytical
%   tidal-prism/discharge argument with the Savenije-Toffolon-Cai (STC)
%   tidal propagation model. Lw and the area convergence length LA cannot
%   both be known in advance, so two alternative closure methods are
%   supported (selected via inp.closureMethod), since which data is
%   available varies by system:
%     'regime' - closes LA (and gives an independent check on Lw) using
%                river-regime channel geometry at the tidal limit
%                (Cao & Knight, 1996), given river discharge and slope.
%     'prism'  - closes Lw directly (closed form) using the basin
%                planform area at high water, and closes LA using a
%                directly given/measured tidal prism.
%   Both methods share the same underlying STC dynamics and
%   prism-matching equations; they differ only in which known
%   quantities are used to pin down Lw and LA.
% USAGE
%   out = estimateLw(inp)
% INPUTS
%   inp - scalar struct with fields (SI units unless noted):
%     Required, both closures
%       closureMethod - 'regime' or 'prism' (required, no default)
%       Le    - estuary length, mouth to tidal limit (m)
%       Wm    - width at the mouth, x=0 (m)
%       Am    - cross-sectional area at the mouth, x=0 (m^2)
%       hm    - hydraulic depth used in the prism/discharge matching
%               argument (m). NOTE: distinct from hbar = Am/Wm used in
%               the STC dynamics - do not confuse the two.
%       a     - tidal amplitude at the mouth (m)
%       T     - tidal period (s). E.g. M2: T = 44714 s = 12.42*3600.
%     Optional, both closures
%       rS    - storage width ratio, default 1
%       cd    - drag/friction coefficient, default 0.0025
%       g     - acceleration due to gravity (m/s^2), default 9.81
%       runSensitivity - logical, default true (see "Sensitivity
%               diagnostics" below; meaning depends on closureMethod)
%     Required/optional when closureMethod = 'regime'
%       Qr    - river discharge (m^3/s). Qr == 0 is a valid, meaningful
%               input (see NOTES)
%       Sr    - river energy slope, for record/flagging only (-),
%               optional, default NaN (not used in any calculation)
%       Wr    - river-regime width at x=Le (m). Pass [] or NaN if not
%               available, or if Qr == 0
%       Ar    - river-regime cross-sectional area at x=Le (m^2). Pass
%               [] or NaN if not available, or if Qr == 0
%       WrMin - floor value for Wr (m), user-overridable, default 10
%       ArMin - floor value for Ar (m^2), user-overridable, default 10
%     Required/optional when closureMethod = 'prism'
%       S_HW  - basin planform area at high water (m^2)
%       P_target - given/measured tidal prism (m^3): the target that
%               LA is solved to reproduce (see NOTES). Named P_target
%               (not P) to keep it visually and semantically distinct
%               from out.P, the pre-existing Lambert-W-reduction
%               intermediate used only by closureMethod='regime'.
%       hypsometryForm - 'linear' or 'FA1996', default 'FA1996' (see
%               NOTES)
%
% OUTPUT
%   out - struct with fields (populated according to closureMethod;
%   fields not relevant to the active closure are NaN/false/empty). If
%   input validation or any downstream computation errors, or a core
%   input parameter is NaN, out is instead returned as a PLACEHOLDER
%   struct with every field below still present but set to NaN/false/''
%   (LA_candidates 0x0, sensitivity.applied=false) and warnings holding
%   the caught error message - out always has the same field names in
%   the same order regardless of success/failure/closureMethod, so
%   repeated calls (e.g. in a loop over many input sets) can be collected
%   directly into a struct array, out(k) = estimateLw(inp(k)), without
%   special-casing failures; test out(k).warnings or isnan(out(k).LA)
%   rather than wrapping each call in try/catch:
%     LA         - area convergence length (m). closureMethod='regime':
%                  two-point fit Am/Ar. closureMethod='prism': the
%                  selected root of P_velocity(LA) = P_target (NaN if
%                  the root is ambiguous - see LA_candidates)
%     Lw_regime  - geometric width convergence length, two-point fit
%                  Wm/Wr (m); closureMethod='regime' only, NaN otherwise
%                  - independent cross-check of Lw_prism
%     Lw_prism   - the primary/headline width convergence length (m).
%                  closureMethod='regime': from the tidal-prism/
%                  discharge-matching Lambert-W closure (D, Kd below).
%                  closureMethod='prism': from the S_HW/hypsometry
%                  Lambert-W closure (Step 1; see NOTES) - despite the
%                  field name, this value does NOT come from the
%                  prism-matching argument in this closure; the name is
%                  kept so callers reading out.Lw_prism get the
%                  headline answer regardless of closureMethod
%     LA_candidates
%                - struct array (fields: LA, Lh, isPreferred, gamma,
%                  chi, mu, delta, lambda, eps, La_amp, U, Kd), one
%                  entry per root of P_velocity(LA)=P_target found while
%                  scanning. closureMethod='prism' only; empty (0x0) for
%                  'regime'. Lh = LA*Lw/(Lw-LA) is the exact
%                  depth-convergence length implied by that LA together
%                  with the Step-1 Lw (from A=W*h); isPreferred is true
%                  only for a unique Lh>0 candidate (see NOTES)
%     gamma, zeta, chi0, chi, mu, delta, lambda, eps
%                - STC dimensionless numbers at the resolved LA: estuary
%                  shape number, dimensionless tidal amplitude at the
%                  mouth (zeta = a/hbar), friction "prefactor" (chi0 =
%                  rS*cd*c0/(omega*hbar)), friction number (chi =
%                  chi0*zeta - see NOTES), velocity number (smallest
%                  positive real root), damping number, celerity number,
%                  and phase lag HW-HWS (rad)
%     U          - tidal velocity amplitude at the mouth (m/s)
%     La_amp     - tidal amplitude convergence/decay length (m); can be
%                  negative (amplitude damps landward) - physically
%                  valid, not an error
%     Kd         - "K dagger", discharge-matching coefficient (m^3): the
%                  integral of the tidal discharge Q(0,t) at the mouth
%                  between low water slack (LWS) and high water slack
%                  (HWS), i.e. P_velocity evaluated at the resolved LA -
%                  identical to tidalPrism, kept under its original name
%                  for the prism-matching equations
%     tidalPrism - tidal prism at the mouth (m^3): same LWS-to-HWS
%                  discharge integral as Kd, under a clearer name
%     tidalPrism_simple
%                - simple/leading-order tidal prism at the mouth (m^3):
%                  integral of the linear sinusoidal discharge
%                  Q(0,t) = U*Am*sin(omega*t) between consecutive
%                  zero-crossings = 2*U*Am/omega. Reported alongside
%                  tidalPrism for cross-validation
%     D, C1, C2, P, Q, y
%                - intermediate quantities of the closureMethod='regime'
%                  prism-matching / Lambert-W reduction, retained for
%                  transparency and debugging; NaN for closureMethod=
%                  'prism' (which has its own Step-1 intermediates: f,
%                  S_MT, Lam - see below)
%     f, S_MT, Lam
%                - closureMethod='prism' Step-1 intermediates: the
%                  hypsometry correction factor used, the derived
%                  mean-tide-level basin area S_HW/f, and Lam =
%                  Wm*Le/S_MT (the Lambert-W reduction's "Lambda"); NaN
%                  for closureMethod='regime'
%     lambertArg - the argument passed to the Lambert W function
%                  (closureMethod='regime': Q*exp(-P); closureMethod=
%                  'prism': -Lam*exp(-Lam))
%     checkResidual
%                - relative error re-substituting the resolved Lw back
%                  into the original (pre-Lambert-W-reduction) equation
%                  for the active closure (Kd-matching for 'regime';
%                  Wm*Lw*(1-exp(-Le/Lw)) vs S_MT for 'prism'); should be
%                  << 1e-8
%     Pwidth_check, Pwidth_over_P
%                - closureMethod='prism' only (Step 3): P_width computed
%                  from the resolved Lw/LA, and its ratio to P_target -
%                  an independent consistency check (only P_velocity was
%                  used to fit LA). NaN for closureMethod='regime'
%     hbar, omega, c0
%                - supporting quantities: mean depth at mouth (m),
%                  angular tidal frequency (rad/s), frictionless wave
%                  celerity (m/s)
%     Wr, Ar, WrFloored, ArFloored
%                - closureMethod='regime': the Wr/Ar values actually
%                  used (after floor logic) and whether each was
%                  overridden by its floor. NaN/false for 'prism'
%     S_HW, P_target, hypsometryForm
%                - closureMethod='prism': echoes the resolved inputs
%                  back for traceability. NaN/NaN/'' for 'regime'
%     sensitivity
%                - struct reporting the active closure's sensitivity
%                  check (see "Sensitivity diagnostics" below); has
%                  field applied (logical) and, when applied,
%                  closure-specific sub-fields
%     closureMethod
%                - echoes inp.closureMethod back
%     warnings   - cell array of strings flagging anything the caller
%                  should look at (floor overrides, failed sanity
%                  checks, near-degenerate solutions, ambiguous LA
%                  roots, etc.)
%
% NOTES
%   Geometry (single exponential reach, mouth x=0 to tidal limit x=Le):
%       W(x) = Wm * exp(-x/Lw),   A(x) = Am * exp(-x/LA)
%
%   closureMethod='regime': Wr, Ar are treated purely as inputs (from
%   the user's own external regime-theory implementation, e.g. Cao &
%   Knight 1996 - NOT reimplemented here). Qr == 0 is degenerate for
%   regime theory (a zero-discharge "regime channel" is undefined), so
%   in that case - or whenever the supplied/computed Wr, Ar are empty,
%   NaN, or below the floor - this function falls back to the floor
%   values WrMin/ArMin. In all cases Wr = max(Wr, WrMin), Ar = max(Ar,
%   ArMin) is enforced, because LA and Lw_regime enter as log(Am/Ar),
%   log(Wm/Wr) and are highly sensitive to small Wr/Ar.
%
%   STC tidal dynamics (shared by both closures): the dimensionless
%   numbers gamma, zeta, chi0, chi, mu, delta, lambda, eps follow
%   Savenije (2012) eqs 3.50-3.67 and Toffolon, Vignoli & Tubino (2006)
%   eqs 18-39. zeta = a/hbar is the dimensionless tidal amplitude at the
%   mouth; chi0 = rS*cd*c0/(omega*hbar) is the friction "prefactor";
%   chi = chi0*zeta (Savenije 2012, eq. 3.53) is the friction number
%   actually used below - NOT chi0 alone, since the Lorentz-linearized
%   friction coefficient scales with the tidal velocity amplitude, which
%   in turn scales with zeta. mu solves the 6th-order polynomial (cubic
%   in mu^2):
%       chi^2*mu^6 + gamma*chi*mu^4 + 2*mu^2 - 2 = 0
%   The smallest positive real root is selected (the physically relevant
%   "mixed wave" family, 0 < eps < pi/2); complex roots and the
%   "standing wave" family are discarded. gamma = c0/(omega*LA) is the
%   only dimensionless number that depends on LA - chi (via zeta =
%   a/hbar), hbar, c0, omega depend only on Am, Wm, a, T, rS, cd, g and
%   are evaluated once. For
%   closureMethod='regime' the STC dynamics are evaluated once (LA is
%   already known geometrically); for closureMethod='prism' they are
%   evaluated repeatedly while scanning LA (cheap - pure algebra).
%   Whenever no positive real mu root exists, or lambda^2 < 0 (below
%   "critical convergence" in Savenije/Toffolon's terms), no real
%   "mixed wave" solution exists at that LA: for closureMethod='regime'
%   this makes Lw_prism (and dependents) NaN with a warning, while LA/
%   Lw_regime remain valid; for closureMethod='prism' that LA is simply
%   excluded from the root-finding scan (an expected domain boundary,
%   not an error).
%
%   closureMethod='prism' Step 1 (Lw from S_HW): the basin area at mean
%   tide level is S_MT = Wm*Lw*(1-exp(-Le/Lw)) (the exact integral of
%   W(x) from 0 to Le). S_HW (true high-water footprint) generally
%   exceeds S_MT due to intertidal storage (flats/marsh flooded at HW
%   but not at MTL); S_MT = S_HW/f, with f from one of two selectable
%   hypsometry forms, both parameterised by the storage width ratio rS:
%       'linear' : f = 2*rS - 1        (Savenije 2012)
%       'FA1996' : f = 1 + (2+pi/2)*(rS-1)   (Friedrichs & Aubrey 1996,
%                  simplified piecewise-linear equilibrium hypsometry;
%                  the default, better-justified form)
%   Both reduce to f=1 (S_HW=S_MT) when rS=1; neither involves the tidal
%   amplitude explicitly (it cancels at leading order). Given S_MT, Lw
%   solves exactly and non-iteratively via Lam = Wm*Le/S_MT and
%   Lw = Le/(Lam + W0(-Lam*exp(-Lam))) - note -Lam*exp(-Lam) >= -1/e for
%   all real Lam (minimised at Lam=1), so this reduction is always
%   inside the Lambert-W domain; the domain check is still performed
%   for robustness.
%
%   closureMethod='prism' Step 2 (LA from P_target): with Lw fixed from
%   Step 1, LA solves P_velocity(LA) = P_target, where P_velocity(LA) =
%   (U(LA)*Am/omega)*(2 - pi*a*sin(eps(LA))/(2*hm)) is the same LWS-to-
%   HWS discharge integral as Kd/tidalPrism above, evaluated as a
%   function of LA. This equation is not necessarily unique -
%   P_velocity(LA) can be non-monotonic - so a log-spaced scan over LA
%   locates all sign changes, each refined with fzero. Every candidate's
%   implied depth-convergence length Lh = LA*Lw/(Lw-LA) is an exact
%   geometric identity from A=W*h (not an approximation). The candidate
%   with Lh>0 (depth decreasing/near-constant landward - the physically
%   unremarkable case) is preferred over Lh<0 (depth increasing
%   landward at a rate comparable to Le - unusual, would need
%   independent bathymetric justification). If more than one candidate
%   has Lh>0, or none do, no candidate is auto-selected (LA, and
%   everything depending on it, is NaN with a warning) - the full
%   LA_candidates list is always returned so the choice is auditable.
%
%   closureMethod='prism' Step 3 (validation): P_width (below) is
%   computed from the resolved Lw (Step 1) and the selected LA's La_amp/
%   eps (Step 2), and compared to P_target. Since only P_velocity was
%   used to fit LA, this is a genuine independent consistency check
%   (Pwidth_over_P should be close to 1 for a self-consistent input
%   set).
%
%   Shared prism formulas:
%       P_width(Lw,La_amp,eps) = 2*a*cos(eps)*Wm*Lw*
%                                 (1-exp(Le/La_amp-Le/Lw))/(1-Lw/La_amp)
%       P_velocity(U,eps)      = (U*Am/omega)*(2-pi*a*sin(eps)/(2*hm))
%   For closureMethod='regime', D=2*a*cos(eps)*Wm and Kd=P_velocity are
%   equated (P_width=P_velocity) and solved for Lw via the closed-form
%   Lambert-W reduction (C1, C2, P, Q, y - see D/Kd derivation in the
%   original synthesis note below). This closure (D, Kd, and its
%   reduction to a Lambert-W closed form for Lw) is an original
%   synthesis developed and checked by the author (Ian Townend) using
%   claude.ai, in the spirit of the tidal-prism/discharge-balance
%   approach used in Townend (2010, Continental Shelf Research) - it is
%   not a verbatim equation from the references below, though it builds
%   directly on the shared STC outputs (U, eps, La_amp).
%
%   lambertw.m (Getreuer 2005-2006 / Clamond 2005; Halley's method per
%   Corless, Gonnet, Hare, Jeffrey & Knuth 1996) is used for the
%   principal-branch Lambert W evaluation; this function performs an
%   explicit domain check (argument >= -1/e) before each call, since
%   lambertw.m itself returns a complex value rather than erroring when
%   given an out-of-domain real argument.
%
%   Units: T is in SECONDS throughout (omega = 2*pi/T).
%
%   References:
%     Toffolon M, Vignoli G and Tubino M, 2006, Relevant parameters and
%       finite amplitude effects in estuarine hydrodynamics. Journal of
%       Geophysical Research, 111 (C10014), pp. 1-17.
%       https://doi.org/10.1029/2005JC003104
%     Savenije H H G, 2012, Salinity and Tides in Alluvial Estuaries,
%       2nd ed.
%       https://hubertsavenije.files.wordpress.com/2022/04/salinityandtides2_6.pdf
%     Cai H, 2014, A new analytical framework for tidal propagation in
%       estuaries, PhD thesis, TU Delft.
%       https://repository.tudelft.nl/file/File_74676e01-e4f8-4a63-9691-34666d20038a
%     Cao Z, Knight D W, 1996, Regime theory of alluvial channels based
%       on the concept of stream power and probability. Proc. ICE -
%       Water, Maritime and Energy, 118(1), 1-12. (closureMethod=
%       'regime' only; Wr/Ar are supplied by the caller's own
%       implementation, not computed here)
%     Friedrichs C T, Aubrey D G, 1996, Uniform bottom shear stress and
%       equilibrium hypsometry of intertidal flats. In Mixing in
%       Estuaries and Coastal Seas, Coastal and Estuarine Studies,
%       Pattiaratchi C (ed), pp. 405-429, American Geophysical Union,
%       Washington. (hypsometryForm='FA1996' only)
%     Townend I H, 2010, An exploration of equilibrium in Venice Lagoon
%       using an idealised model. Continental Shelf Research, 30,
%       984-999. (tidal-prism/discharge-balance approach referenced
%       above for the closureMethod='regime' Lw_prism closure)
%
%   No dependency on the Symbolic Math Toolbox. Scalar inputs are the
%   primary use case; the function is not vectorized over inp arrays.
%
% Sensitivity diagnostics
%   closureMethod='regime': whenever Qr==0 or Wr/Ar are floor-limited,
%   automatically reruns with WrMin/ArMin perturbed +/-50% and reports
%   the resulting % change in LA, Lw_regime, Lw_prism (out.sensitivity.
%   plus50/minus50, each a copy of the perturbed run's core outputs plus
%   LA_pct/Lw_regime_pct/Lw_prism_pct).
%   closureMethod='prism': always reruns Steps 1-3 with the other
%   hypsometryForm (cheap - pure algebra) and reports both forms' Lw and
%   selected LA (out.sensitivity.linear/FA1996, each struct('Lw',...,
%   'LA',...)) plus Lw_pct_diff/LA_pct_diff between them, since this
%   choice materially affects Lw (via f) and, through the depth-
%   convergence disambiguation, can affect which LA root is selected.
%   Both controlled by inp.runSensitivity (default true).
%
% Author: Ian Townend, Coded: Claude Code using Claude Sonnet 5
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
%   Error handling: if input validation or any downstream computation
%   raises an error, or a core input parameter (Le, Wm, Am, hm, a, T, or
%   the active closureMethod's other required fields, e.g. Qr / S_HW,
%   P_target) is NaN, this function returns a PLACEHOLDER struct (see
%   emptyOutputStruct, below) instead of throwing. That struct has
%   exactly the same field names, in the same order, as a successful
%   result - only the values differ (NaN/false/''/empty) - so it is
%   concatenation-compatible: looping over many input sets and building
%   out(k) = estimateLw(inp(k)) works whether or not individual calls
%   error, with no try/catch needed at the call site and no risk of
%   MATLAB's "dissimilar structures" concatenation error.

    try
        out = computeEstimateLw(inp);
    catch ME
        out = emptyOutputStruct();
        out.warnings = {sprintf('estimateLw returned an empty (placeholder) result: %s', ME.message)};
        if isstruct(inp) && isscalar(inp) && isfield(inp, 'closureMethod')
            cm = inp.closureMethod;
            if (ischar(cm) || isstring(cm)) && ismember(char(cm), {'regime', 'prism'})
                out.closureMethod = char(cm);
            end
        end
    end
end

%% ========================================================================
function out = computeEstimateLw(inp)
    %% ---- input validation: common ------------------------------------
    if nargin < 1 || ~isstruct(inp) || ~isscalar(inp)
        error('estimateLw:input', 'Input must be a scalar struct, see help estimateLw.');
    end

    if ~isfield(inp, 'closureMethod') || isempty(inp.closureMethod)
        error('estimateLw:missingField', ...
            'Required input field "closureMethod" is missing or empty; must be ''regime'' or ''prism''.');
    end
    closureMethod = inp.closureMethod;
    if ~(ischar(closureMethod) || isstring(closureMethod)) || ~ismember(char(closureMethod), {'regime', 'prism'})
        error('estimateLw:invalidClosureMethod', ...
            'closureMethod must be ''regime'' or ''prism'', got ''%s''.', char(string(closureMethod)));
    end
    closureMethod = char(closureMethod);

    reqNumericCommon = {'Le', 'Wm', 'Am', 'hm', 'a', 'T'};
    for k = 1:numel(reqNumericCommon)
        fn = reqNumericCommon{k};
        if ~isfield(inp, fn) || isempty(inp.(fn)) || isnan(inp.(fn))
            error('estimateLw:missingField', ...
                'Required input field "%s" is missing, empty, or NaN.', fn);
        end
    end
    Le = inp.Le; Wm = inp.Wm; Am = inp.Am; hm = inp.hm; a = inp.a; T = inp.T;
    if Le <= 0 || Wm <= 0 || Am <= 0 || hm <= 0 || a <= 0 || T <= 0
        error('estimateLw:invalidValue', 'Le, Wm, Am, hm, a and T must all be positive.');
    end

    rS = getDefault(inp, 'rS', 1);
    cd = getDefault(inp, 'cd', 0.0025);
    g  = getDefault(inp, 'g',  9.81);
    runSensitivity = getDefault(inp, 'runSensitivity', true);
    if rS <= 0 || cd <= 0 || g <= 0
        error('estimateLw:invalidValue', 'rS, cd and g must all be positive.');
    end

    warnings = {};

    %% ---- closure-specific branches -------------------------------------
    switch closureMethod
    case 'regime'
        if ~isfield(inp, 'Qr') || isempty(inp.Qr) || isnan(inp.Qr)
            error('estimateLw:missingField', ...
                'Required input field "Qr" is missing, empty, or NaN (required for closureMethod=''regime'').');
        end
        Qr = inp.Qr;
        if Qr < 0
            error('estimateLw:invalidValue', 'Qr (river discharge) cannot be negative.');
        end
        WrMin = getDefault(inp, 'WrMin', 10);
        ArMin = getDefault(inp, 'ArMin', 10);
        if WrMin <= 0 || ArMin <= 0
            error('estimateLw:invalidValue', 'WrMin and ArMin must both be positive.');
        end
        Sr = getDefault(inp, 'Sr', NaN); %#ok<NASGU> % record only, not used

        WrRaw = []; if isfield(inp, 'Wr'), WrRaw = inp.Wr; end
        ArRaw = []; if isfield(inp, 'Ar'), ArRaw = inp.Ar; end

        [Wr, WrFloored, wmsg] = applyFloor(WrRaw, WrMin, Qr, 'Wr');
        if WrFloored, warnings{end+1} = wmsg; end
        [Ar, ArFloored, amsg] = applyFloor(ArRaw, ArMin, Qr, 'Ar');
        if ArFloored, warnings{end+1} = amsg; end

        Pstruct = struct('Le', Le, 'Wm', Wm, 'Am', Am, 'hm', hm, 'a', a, 'T', T, ...
            'rS', rS, 'cd', cd, 'g', g, 'Wr', Wr, 'Ar', Ar, ...
            'WrRaw', WrRaw, 'ArRaw', ArRaw, 'Qr', Qr);
        [core, w] = runRegimeClosure(Pstruct);
        warnings = [warnings, w];

        out = core;
        out.Wr = Wr; out.Ar = Ar; out.WrFloored = WrFloored; out.ArFloored = ArFloored;
        out.S_HW = NaN; out.P_target = NaN; out.hypsometryForm = '';

        floorInvoked = WrFloored || ArFloored || (Qr == 0);
        if runSensitivity && floorInvoked
            out.sensitivity = struct('applied', true);
            [out.sensitivity.plus50,  spWarn] = perturbedRun(Pstruct, WrMin, ArMin, +0.5, out);
            [out.sensitivity.minus50, smWarn] = perturbedRun(Pstruct, WrMin, ArMin, -0.5, out);
            warnings = [warnings, spWarn, smWarn];
        else
            out.sensitivity = struct('applied', false, ...
                'note', 'WrMin/ArMin floor not invoked for this input set; sensitivity check skipped.');
        end

    case 'prism'
        if ~isfield(inp, 'S_HW') || isempty(inp.S_HW) || isnan(inp.S_HW)
            error('estimateLw:missingField', ...
                'Required input field "S_HW" is missing, empty, or NaN (required for closureMethod=''prism'').');
        end
        if ~isfield(inp, 'P_target') || isempty(inp.P_target) || isnan(inp.P_target)
            error('estimateLw:missingField', ...
                'Required input field "P_target" is missing, empty, or NaN (required for closureMethod=''prism'').');
        end
        S_HW = inp.S_HW; P_target = inp.P_target;
        if S_HW <= 0
            error('estimateLw:invalidValue', 'S_HW (basin planform area at high water) must be positive.');
        end
        if P_target <= 0
            error('estimateLw:invalidValue', 'P_target (given/measured tidal prism) must be positive.');
        end
        hypForm = char(getDefault(inp, 'hypsometryForm', 'FA1996'));
        if ~ismember(hypForm, {'linear', 'FA1996'})
            error('estimateLw:invalidHypsometryForm', ...
                'hypsometryForm must be ''linear'' or ''FA1996'', got ''%s''.', hypForm);
        end

        [core, w] = runPrismClosure(hypForm, P_target, Le, Wm, Am, hm, a, T, rS, cd, g, S_HW);
        warnings = [warnings, w];

        out = core;
        out.Wr = NaN; out.Ar = NaN; out.WrFloored = false; out.ArFloored = false;
        out.S_HW = S_HW; out.P_target = P_target; out.hypsometryForm = hypForm;

        if runSensitivity
            if strcmp(hypForm, 'linear'), otherForm = 'FA1996'; else, otherForm = 'linear'; end
            [coreAlt, wAlt] = runPrismClosure(otherForm, P_target, Le, Wm, Am, hm, a, T, rS, cd, g, S_HW);
            warnings = [warnings, wAlt];

            results.(hypForm)   = struct('Lw', core.Lw_prism,    'LA', core.LA);
            results.(otherForm) = struct('Lw', coreAlt.Lw_prism, 'LA', coreAlt.LA);
            Lw_pct = 100 * (results.FA1996.Lw - results.linear.Lw) / results.linear.Lw;
            LA_pct = 100 * (results.FA1996.LA - results.linear.LA) / results.linear.LA;
            out.sensitivity = struct('applied', true, 'activeForm', hypForm, ...
                'linear', results.linear, 'FA1996', results.FA1996, ...
                'Lw_pct_diff', Lw_pct, 'LA_pct_diff', LA_pct);
        else
            out.sensitivity = struct('applied', false, ...
                'note', 'runSensitivity=false; hypsometryForm cross-check skipped.');
        end
    end

    out.closureMethod = closureMethod;
    out.warnings = warnings;
end

%% ======================================================================
function v = getDefault(s, fn, d)
% Return s.(fn) if present, non-empty and non-NaN; otherwise return default d.
    if isfield(s, fn) && ~isempty(s.(fn)) && ~(isnumeric(s.(fn)) && isscalar(s.(fn)) && isnan(s.(fn)))
        v = s.(fn);
    else
        v = d;
    end
end

%% ------------------------------------------------------------------------
function out = emptyOutputStruct()
% Placeholder output returned on any error, or when a core input is NaN,
% instead of a genuinely field-less struct() - this has EXACTLY the same
% top-level field set (same names, same order) as the struct returned on
% a successful call (both closureMethod branches already produce that
% same field set - see runRegimeClosure/runPrismClosure's identical
% 'core' field lists, plus the shared Wr/Ar/.../closureMethod/warnings
% fields assigned afterwards in computeEstimateLw). Matching field names
% is what MATLAB requires for out(1), out(2), ... = estimateLw(...) or
% [out1, out2, ...] to build/extend a struct array - callers can loop
% over many inputs, including ones that error or contain NaNs, and
% collect every result into one struct array without special-casing
% failures. Field VALUES here are NaN/false/''/empty as appropriate;
% nested sub-structs (LA_candidates, sensitivity) need not match shape
% across elements - MATLAB struct arrays only require matching field
% NAMES at each level, not matching contents - so their fields can (and
% normally do) vary between successful and failed/placeholder elements.
    out = struct( ...
        'LA', NaN, 'Lw_regime', NaN, 'Lw_prism', NaN, ...
        'gamma', NaN, 'zeta', NaN, 'chi0', NaN, 'chi', NaN, 'mu', NaN, 'delta', NaN, 'lambda', NaN, ...
        'eps', NaN, 'U', NaN, 'La_amp', NaN, 'Kd', NaN, ...
        'tidalPrism', NaN, 'tidalPrism_simple', NaN, ...
        'D', NaN, 'C1', NaN, 'C2', NaN, 'P', NaN, 'Q', NaN, 'y', NaN, ...
        'f', NaN, 'S_MT', NaN, 'Lam', NaN, 'Pwidth_check', NaN, 'Pwidth_over_P', NaN, ...
        'lambertArg', NaN, 'checkResidual', NaN, ...
        'LA_candidates', emptyCandidateStruct(), ...
        'hbar', NaN, 'omega', NaN, 'c0', NaN, ...
        'Wr', NaN, 'Ar', NaN, 'WrFloored', false, 'ArFloored', false, ...
        'S_HW', NaN, 'P_target', NaN, 'hypsometryForm', '', ...
        'sensitivity', struct('applied', false, 'note', 'Not computed: estimateLw returned early, see warnings.'), ...
        'closureMethod', '', 'warnings', {{}});
end

%% ------------------------------------------------------------------------
function s = emptyCandidateStruct()
% 0x0 struct array with the LA_candidates field set, shared by the
% 'regime' closure's (always-empty) placeholder and the 'prism' closure's
% populated candidate list, so both closures return the same struct shape.
    s = struct('LA', {}, 'Lh', {}, 'isPreferred', {}, 'gamma', {}, 'chi', {}, ...
        'mu', {}, 'delta', {}, 'lambda', {}, 'eps', {}, 'La_amp', {}, 'U', {}, 'Kd', {});
end

%% ------------------------------------------------------------------------
function [ok, gam, mu, delta, lambda, epsPhase, La_amp, U, msg] = stcDynamics(LA, hbar, c0, chi, omega, rS, a)
% Shared STC dynamics at a given LA (gamma, chi, mu, delta, lambda, eps,
% La_amp, U). Returns ok=false (with an explanatory msg) instead of
% erroring when no positive real mu root exists or lambda^2<0, so callers
% can treat "no solution at this LA" as a domain boundary rather than a
% hard failure - used both for a single evaluation (closureMethod=
% 'regime') and repeatedly while scanning LA (closureMethod='prism').
    gam = c0 / (omega * LA);
    mu = NaN; delta = NaN; lambda = NaN; epsPhase = NaN; La_amp = NaN; U = NaN;

    coeffs = [chi^2, 0, gam*chi, 0, 2, 0, -2];
    r = roots(coeffs);
    isRealPos = abs(imag(r)) < 1e-8 * max(1, abs(r)) & real(r) > 0;
    muCandidates = sort(real(r(isRealPos)));
    if isempty(muCandidates)
        ok = false;
        msg = sprintf('No positive real root found for the velocity number mu (gamma = %.6g, chi = %.6g).', gam, chi);
        return
    end
    mu = muCandidates(1);

    delta = (gam - chi*mu^2) / 2;
    lambdaSq = 1 + (chi^2*mu^4 - gam^2)/4;
    if lambdaSq < 0
        ok = false;
        msg = sprintf(['lambda^2 = %.6g < 0 (gamma = %.6g, chi = %.6g, mu = %.6g): no real-valued ' ...
            '"mixed wave" solution exists (below critical convergence).'], lambdaSq, gam, chi, mu);
        return
    end
    lambda = sqrt(lambdaSq);
    epsPhase = atan(lambda / (gam - delta));
    La_amp = c0 / (omega * delta);
    U = mu * rS * (a / hbar) * c0;
    ok = true;
    msg = '';
end

%% ------------------------------------------------------------------------
function [val, wasFloored, msg] = applyFloor(raw, floorVal, Qr, name)
% Apply the WrMin/ArMin (or equivalent) floor per the river-regime
% closure rules: Qr==0, or an empty/NaN raw value, forces the floor;
% otherwise the floor is a simple safety-net lower bound.
    msg = '';
    if Qr == 0
        val = floorVal;
        wasFloored = true;
        msg = sprintf('Qr == 0: river-regime channel is degenerate; using %sMin = %.6g as %s.', name, floorVal, name);
        return
    end
    if isempty(raw) || isnan(raw)
        val = floorVal;
        wasFloored = true;
        msg = sprintf('Supplied %s is empty/NaN; using %sMin = %.6g as %s.', name, name, floorVal, name);
        return
    end
    if raw < floorVal
        val = floorVal;
        wasFloored = true;
        msg = sprintf('Supplied %s = %.6g is below the floor; using %sMin = %.6g as %s.', name, raw, name, floorVal, name);
        return
    end
    val = raw;
    wasFloored = false;
end

%% ------------------------------------------------------------------------
function [core, warnings] = runRegimeClosure(P)
% closureMethod='regime': geometric fits (LA, Lw_regime), shared STC
% dynamics at the geometrically-resolved LA, and the prism-matching
% Lambert-W closure for Lw_prism. P is a struct with fields Le, Wm, Am,
% hm, a, T, rS, cd, g, Wr, Ar (floors already applied).
%
% LA and Lw_regime are always computed and returned. The STC-dynamics/
% prism-matching branch is protected: genuinely degenerate parameter
% combinations (e.g. an extreme WrMin/ArMin floor relative to the mouth
% geometry) have no physically valid real-valued "mixed wave" solution.
% Rather than let the whole function fail, or silently return a wrong/
% complex number, any such failure leaves the STC/prism outputs as NaN
% with a clear warning explaining why.
    w = {};

    if P.Am <= P.Ar
        error('estimateLw:invalidGeometry', ...
            'Am (%.6g) must exceed Ar (%.6g): the mouth area must be larger than the tidal-limit area for a convergent estuary.', P.Am, P.Ar);
    end
    if P.Wm <= P.Wr
        error('estimateLw:invalidGeometry', ...
            'Wm (%.6g) must exceed Wr (%.6g): the mouth width must be larger than the tidal-limit width for a convergent estuary.', P.Wm, P.Wr);
    end

    LA        = P.Le / log(P.Am / P.Ar);
    Lw_regime = P.Le / log(P.Wm / P.Wr);

    hbar  = P.Am / P.Wm;
    omega = 2*pi / P.T;
    c0    = sqrt(P.g * hbar / P.rS);
    zeta  = P.a / hbar;
    chi0  = P.rS * P.cd * c0 / (omega * hbar);
    chi   = chi0 * zeta;

    D = NaN; Kd = NaN; C1 = NaN; C2 = NaN; Pp = NaN; Qq = NaN; lambertArg = NaN;
    y = NaN; Lw_prism = NaN; checkResidual = NaN;
    tidalPrism = NaN; tidalPrism_simple = NaN;

    [ok, gam, mu, delta, lambda, epsPhase, La_amp, U, msg] = stcDynamics(LA, hbar, c0, chi, omega, P.rS, P.a);
    if ~ok
        w{end+1} = sprintf(['STC dynamics failed: %s Lw_prism and all dependent diagnostics are NaN; ' ...
            'LA and Lw_regime (the independent geometric estimate) remain valid.'], msg);
    else
        try
            D  = 2 * P.a * cos(epsPhase) * P.Wm;
            Kd = (U * P.Am / omega) * (2 - pi * P.a * sin(epsPhase) / (2 * P.hm));
            tidalPrism = Kd;
            tidalPrism_simple = 2 * U * P.Am / omega;

            C1 = D + Kd / La_amp;
            C2 = D * exp(P.Le / La_amp);
            Pp = C1 * P.Le / Kd;
            Qq = -C2 * P.Le / Kd;
            lambertArg = Qq * exp(-Pp);

            if lambertArg < -1/exp(1)
                error('estimateLw:lambertDomain', ...
                    ['Lambert-W argument Q*exp(-P) = %.6g is outside the domain of W0 ' ...
                     '(< -1/e): no physically valid Lw solution exists for these ' ...
                     'inputs. This is a known failure mode for unrealistic input ' ...
                     'combinations.'], lambertArg);
            end
            y = Pp + real(lambertw(lambertArg));
            Lw_prism = P.Le / y;

            denom = 1 - Lw_prism/La_amp;
            if denom == 0 || ~isfinite(denom)
                checkResidual = NaN;
                w{end+1} = 'Residual self-check not computable (Lw_prism == La_amp); skipped.';
            else
                Kd_check = D * Lw_prism * (1 - exp(P.Le/La_amp - P.Le/Lw_prism)) / denom;
                checkResidual = abs(Kd_check - Kd) / abs(Kd);
                if checkResidual > 1e-8
                    w{end+1} = sprintf(['Residual self-check failed: re-substituting Lw_prism into the ' ...
                        'original prism-matching equation reproduces Kd with relative error %.3g (tol 1e-8).'], checkResidual);
                end
            end

            if Lw_prism < 0
                w{end+1} = sprintf('Lw_prism = %.6g m is negative: solution is in/near the degenerate regime, do not trust at face value.', Lw_prism);
            elseif Lw_prism > 10 * P.Le
                w{end+1} = sprintf('Lw_prism = %.6g m exceeds 10x Le (%.6g m): solution is in/near the degenerate regime, do not trust at face value.', Lw_prism, P.Le);
            end
        catch ME
            w{end+1} = sprintf(['STC dynamics / prism-matching branch failed: %s. Lw_prism and all ' ...
                'dependent diagnostics are NaN; LA and Lw_regime (the independent geometric ' ...
                'estimate) remain valid.'], ME.message);
            Kd = NaN; tidalPrism = NaN; tidalPrism_simple = NaN; Lw_prism = NaN; checkResidual = NaN;
        end
    end

    core = struct('LA', LA, 'Lw_regime', Lw_regime, 'Lw_prism', Lw_prism, ...
        'gamma', gam, 'zeta', zeta, 'chi0', chi0, 'chi', chi, 'mu', mu, 'delta', delta, 'lambda', lambda, ...
        'eps', epsPhase, 'U', U, 'La_amp', La_amp, 'Kd', Kd, ...
        'tidalPrism', tidalPrism, 'tidalPrism_simple', tidalPrism_simple, ...
        'D', D, 'C1', C1, 'C2', C2, 'P', Pp, 'Q', Qq, 'y', y, ...
        'f', NaN, 'S_MT', NaN, 'Lam', NaN, 'Pwidth_check', NaN, 'Pwidth_over_P', NaN, ...
        'lambertArg', lambertArg, 'checkResidual', checkResidual, ...
        'LA_candidates', emptyCandidateStruct(), ...
        'hbar', hbar, 'omega', omega, 'c0', c0);

    warnings = w;
end

%% ------------------------------------------------------------------------
function [pr, msgs] = perturbedRun(P, WrMin, ArMin, frac, nominal)
% Rerun the 'regime' closure with WrMin/ArMin perturbed by fraction frac
% (e.g. +0.5 or -0.5) and report the resulting values plus their
% percentage change from the nominal (already-floored) run.
%
% The floor is re-applied from the ORIGINAL raw Wr/Ar (P.WrRaw, P.ArRaw)
% and P.Qr via applyFloor, exactly mirroring the nominal computation -
% NOT approximated as max(nominal Wr, new floor). That approximation
% would be wrong whenever the nominal value was set by direct floor
% assignment (Qr==0, or raw empty/NaN): decreasing the floor (frac<0)
% must be able to lower the resulting Wr/Ar, which max() cannot do
% starting from an already-floored nominal value.
    msgs = {};
    Pp = P;
    Pp.Wr = applyFloor(P.WrRaw, WrMin * (1+frac), P.Qr, 'Wr');
    Pp.Ar = applyFloor(P.ArRaw, ArMin * (1+frac), P.Qr, 'Ar');

    try
        [core, w] = runRegimeClosure(Pp);
        pr = core;
        pr.LA_pct        = 100 * (pr.LA        - nominal.LA)        / nominal.LA;
        pr.Lw_regime_pct = 100 * (pr.Lw_regime - nominal.Lw_regime) / nominal.Lw_regime;
        pr.Lw_prism_pct  = 100 * (pr.Lw_prism  - nominal.Lw_prism)  / nominal.Lw_prism;
        msgs = w;
    catch ME
        pr = struct('LA', NaN, 'Lw_regime', NaN, 'Lw_prism', NaN, ...
            'LA_pct', NaN, 'Lw_regime_pct', NaN, 'Lw_prism_pct', NaN, ...
            'error', ME.message);
        msgs = {sprintf('Sensitivity rerun (%+d%% floor) failed: %s', round(frac*100), ME.message)};
    end
end

%% ------------------------------------------------------------------------
function f = hypsometryFactor(hypForm, rS)
% Intertidal hypsometry correction factor f, S_MT = S_HW/f.
    switch hypForm
        case 'linear'
            f = 2*rS - 1;
        case 'FA1996'
            f = 1 + (2 + pi/2) * (rS - 1);
        otherwise
            error('estimateLw:invalidHypsometryForm', ...
                'hypsometryForm must be ''linear'' or ''FA1996'', got ''%s''.', hypForm);
    end
end

%% ------------------------------------------------------------------------
function [Lw, f, S_MT, Lam, lambertArg, checkResidual, warnings] = solveLwFromSHW(S_HW, hypForm, rS, Wm, Le)
% closureMethod='prism' Step 1: solve Lw directly, in closed form, from
% the basin planform area at high water S_HW. Exact and non-iterative;
% see help header for the derivation (S_MT=Wm*Lw*(1-exp(-Le/Lw)) reduced
% via Lam=Wm*Le/S_MT to Lw=Le/(Lam+W0(-Lam*exp(-Lam)))).
    warnings = {};
    f = hypsometryFactor(hypForm, rS);
    S_MT = S_HW / f;
    Lam = Wm * Le / S_MT;
    lambertArg = -Lam * exp(-Lam);

    if lambertArg < -1/exp(1)
        error('estimateLw:lambertDomainSHW', ...
            ['Lambert-W argument -Lam*exp(-Lam) = %.6g is outside the domain of W0 ' ...
             '(< -1/e): no physically valid Lw solution exists for these inputs ' ...
             '(Lam = %.6g).'], lambertArg, Lam);
    end
    y = Lam + real(lambertw(lambertArg));
    Lw = Le / y;

    S_MT_check = Wm * Lw * (1 - exp(-Le/Lw));
    checkResidual = abs(S_MT_check - S_MT) / abs(S_MT);
    if checkResidual > 1e-8
        warnings{end+1} = sprintf(['Step 1 residual self-check failed: re-substituting Lw into ' ...
            'Wm*Lw*(1-exp(-Le/Lw)) reproduces S_MT with relative error %.3g (tol 1e-8).'], checkResidual);
    end
    if Lw < 0
        warnings{end+1} = sprintf('Lw = %.6g m is negative: solution is in/near the degenerate regime, do not trust at face value.', Lw);
    elseif Lw > 10 * Le
        warnings{end+1} = sprintf('Lw = %.6g m exceeds 10x Le (%.6g m): solution is in/near the degenerate regime, do not trust at face value.', Lw, Le);
    end
end

%% ------------------------------------------------------------------------
function r = pvelResidual(LA, Ptarget, hbar, c0, chi, omega, rS, a, Am, hm)
% P_velocity(LA) - Ptarget, for bracketing/fzero; NaN where the STC
% dynamics have no real "mixed wave" solution at this LA (a domain gap
% for the scan/root-finder to skip, not an error).
    [ok, ~, ~, ~, ~, epsPhase, ~, U] = stcDynamics(LA, hbar, c0, chi, omega, rS, a);
    if ~ok
        r = NaN;
    else
        r = (U * Am / omega) * (2 - pi * a * sin(epsPhase) / (2 * hm)) - Ptarget;
    end
end

%% ------------------------------------------------------------------------
function [candidates, selectedIdx, warnings] = solveLAFromPrism(Ptarget, hbar, c0, chi, omega, rS, a, Am, hm, Le, Lw)
% closureMethod='prism' Step 2: find every LA root of P_velocity(LA) =
% Ptarget by scanning a wide log-spaced range and refining each sign
% change with fzero, then disambiguate via Lh = LA*Lw/(Lw-LA) (an exact
% identity from A=W*h using the already-known Lw from Step 1). Points
% where the STC dynamics are out of domain (no positive mu root, or
% lambda^2<0) are skipped as gaps, not errors - see stcDynamics.
    warnings = {};
    candidates = emptyCandidateStruct();

    LAscan = logspace(log10(max(1, 0.001*Le)), log10(20*Le), 500);
    Pv = nan(size(LAscan));
    for i = 1:numel(LAscan)
        [ok, ~, ~, ~, ~, epsPhase, ~, U] = stcDynamics(LAscan(i), hbar, c0, chi, omega, rS, a);
        if ok
            Pv(i) = (U * Am / omega) * (2 - pi * a * sin(epsPhase) / (2 * hm));
        end
    end
    resid = Pv - Ptarget;

    for i = 1:numel(LAscan)-1
        if isnan(resid(i)) || isnan(resid(i+1)) || resid(i) == 0
            continue
        end
        if sign(resid(i)) ~= sign(resid(i+1))
            fh = @(LA) pvelResidual(LA, Ptarget, hbar, c0, chi, omega, rS, a, Am, hm);
            try
                LAroot = fzero(fh, [LAscan(i), LAscan(i+1)]);
            catch
                continue
            end
            [ok, gam_r, mu_r, delta_r, lambda_r, eps_r, Laamp_r, U_r] = stcDynamics(LAroot, hbar, c0, chi, omega, rS, a);
            if ~ok
                continue
            end
            Kd_r = (U_r * Am / omega) * (2 - pi * a * sin(eps_r) / (2 * hm));
            if abs(Lw - LAroot) < 1e-9 * max(1, abs(Lw))
                Lh_r = NaN;
            else
                Lh_r = LAroot * Lw / (Lw - LAroot);
            end
            candidates(end+1) = struct('LA', LAroot, 'Lh', Lh_r, 'isPreferred', false, ...
                'gamma', gam_r, 'chi', chi, 'mu', mu_r, 'delta', delta_r, 'lambda', lambda_r, ...
                'eps', eps_r, 'La_amp', Laamp_r, 'U', U_r, 'Kd', Kd_r); %#ok<AGROW>
        end
    end

    if isempty(candidates)
        warnings{end+1} = sprintf('No LA root found matching P_target = %.6g m^3 over the scanned range.', Ptarget);
        selectedIdx = [];
        return
    end

    posLhIdx = find([candidates.Lh] > 0);
    if isscalar(posLhIdx)
        selectedIdx = posLhIdx;
        candidates(selectedIdx).isPreferred = true;
    else
        selectedIdx = [];
        if isempty(posLhIdx)
            warnings{end+1} = sprintf(['%d candidate LA root(s) found for P_target, none with Lh>0 ' ...
                '(the physically unremarkable case, depth decreasing landward); no candidate ' ...
                'auto-selected - inspect LA_candidates.'], numel(candidates));
        else
            warnings{end+1} = sprintf(['%d candidate LA roots found for P_target with Lh>0 (ambiguous); ' ...
                'no candidate auto-selected - inspect LA_candidates.'], numel(posLhIdx));
        end
    end
end

%% ------------------------------------------------------------------------
function [core, warnings] = runPrismClosure(hypForm, Ptarget, Le, Wm, Am, hm, a, T, rS, cd, g, S_HW)
% closureMethod='prism': Step 1 (Lw from S_HW), Step 2 (LA from
% P_target), Step 3 (P_width validation). Reusable so the primary run
% and the hypsometryForm sensitivity rerun share one implementation.
    warnings = {};
    hbar  = Am / Wm;
    omega = 2*pi / T;
    c0    = sqrt(g * hbar / rS);
    zeta  = a / hbar;
    chi0  = rS * cd * c0 / (omega * hbar);
    chi   = chi0 * zeta;

    [Lw, f, S_MT, Lam, lambertArg, checkResidual, w1] = solveLwFromSHW(S_HW, hypForm, rS, Wm, Le);
    warnings = [warnings, w1];

    [candidates, selectedIdx, w2] = solveLAFromPrism(Ptarget, hbar, c0, chi, omega, rS, a, Am, hm, Le, Lw);
    warnings = [warnings, w2];

    LA = NaN; gam = NaN; mu = NaN; delta = NaN; lambda = NaN; epsPhase = NaN; La_amp = NaN; U = NaN; Kd = NaN;
    D = NaN; Pwidth = NaN; Pwidth_over_P = NaN; tidalPrism_simple = NaN;

    if ~isempty(selectedIdx)
        sel = candidates(selectedIdx);
        LA = sel.LA; gam = sel.gamma; mu = sel.mu; delta = sel.delta; lambda = sel.lambda;
        epsPhase = sel.eps; La_amp = sel.La_amp; U = sel.U; Kd = sel.Kd;

        D = 2 * a * cos(epsPhase) * Wm;
        denom = 1 - Lw/La_amp;
        if denom == 0 || ~isfinite(denom)
            warnings{end+1} = 'Step 3 P_width validation not computable (Lw == La_amp); skipped.';
        else
            Pwidth = D * Lw * (1 - exp(Le/La_amp - Le/Lw)) / denom;
            Pwidth_over_P = Pwidth / Ptarget;
        end
        tidalPrism_simple = 2 * U * Am / omega;
    end

    core = struct('LA', LA, 'Lw_regime', NaN, 'Lw_prism', Lw, ...
        'gamma', gam, 'zeta', zeta, 'chi0', chi0, 'chi', chi, 'mu', mu, 'delta', delta, 'lambda', lambda, ...
        'eps', epsPhase, 'U', U, 'La_amp', La_amp, 'Kd', Kd, ...
        'tidalPrism', Kd, 'tidalPrism_simple', tidalPrism_simple, ...
        'D', D, 'C1', NaN, 'C2', NaN, 'P', NaN, 'Q', NaN, 'y', NaN, ...
        'f', f, 'S_MT', S_MT, 'Lam', Lam, 'Pwidth_check', Pwidth, 'Pwidth_over_P', Pwidth_over_P, ...
        'lambertArg', lambertArg, 'checkResidual', checkResidual, ...
        'LA_candidates', candidates, ...
        'hbar', hbar, 'omega', omega, 'c0', c0);
end

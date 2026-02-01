{smcl}
{* *! version 1.2.0  01Feb2026}{...}
{viewerjumpto "Syntax" "rddid##syntax"}{...}
{viewerjumpto "Description" "rddid##description"}{...}
{viewerjumpto "Options" "rddid##options"}{...}
{viewerjumpto "Examples" "rddid##examples"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:rddid} {hline 2}}Difference-in-Discontinuities Estimation based on rdrobust{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:rddid} {depvar} {it:runvar} {ifin} {cmd:,} {opth group(varname)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth group(varname)}}Variable indicating treatment (1) vs control (0) group; {bf:required}.{p_end}
{synopt :{opt bw(string)}}Bandwidth selection method: {opt common} (default) or {opt independent}.{p_end}
{synopt :{opt h(numlist)}}Manually specify bandwidths. Accepts 1, 2, or 4 numbers to control symmetric or asymmetric bandwidths per group.{p_end}
{synopt :{opt bootstrap}}Request bootstrapped standard errors (default is analytic).{p_end}
{synopt :{opt reps(int)}}Number of bootstrap replications (default 50).{p_end}
{synopt :{it:rdrobust_options}}Any other options (e.g., {opt vce(hc1)}, {opt kernel(...)}) are passed directly to {cmd:rdrobust}.{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rddid} performs a Difference-in-Discontinuities estimation. It estimates the discontinuity in {depvar} at the cutoff of {it:runvar} for a Treated group and subtracts the discontinuity found in a Control group.

{pstd}
It relies on {cmd:rdrobust} for underlying estimation and bandwidth selection.

{marker options}{...}
{title:Options}

{phang}
{opt group(varname)} specifies the binary variable defining the groups. 1 must indicate the Treated/Post group, and 0 must indicate the Control/Pre group.

{phang}
{opt bw(string)} specifies how bandwidths are calculated if {opt h()} is not used. {opt common} calculates the optimal bandwidth for the Treated group and applies it to the Control group. {opt independent} calculates separate optimal bandwidths for each group.

{phang}
{opt h(numlist)} allows manual specification of bandwidths. It accepts three formats:{p_end}
{phang2}* {bf:1 number} (e.g., {cmd:h(5)}): Sets a symmetric bandwidth of 5.0 for both Treated and Control groups.{p_end}
{phang2}* {bf:2 numbers} (e.g., {cmd:h(5 10)}): Sets a symmetric bandwidth of 5.0 for the Treated group and 10.0 for the Control group.{p_end}
{phang2}* {bf:4 numbers} (e.g., {cmd:h(1 2 3 4)}): Sets fully asymmetric bandwidths. Treated group uses 1 (Left) and 2 (Right). Control group uses 3 (Left) and 4 (Right).{p_end}

{phang}
{opt bootstrap} calculates standard errors using a bootstrap procedure (resampling the data). If this is not specified, the command calculates analytic standard errors assuming independence between the two groups.

{phang}
{it:rdrobust_options} allow you to customize the underlying estimation. For example, if you want analytic standard errors clustered by a variable, you can pass {cmd:vce(cluster id)} directly.

{marker examples}{...}
{title:Examples}

{phang}1. Standard estimation (Common bandwidth, analytic SEs){p_end}
{phang}{cmd:. rddid outcome score, group(treated)}{p_end}

{phang}2. Independent bandwidths for Treated and Control groups{p_end}
{phang}{cmd:. rddid outcome score, group(treated) bw(independent)}{p_end}

{phang}3. Manual asymmetric bandwidths (Treated: 5 Left/10 Right; Control: 5 Left/5 Right){p_end}
{phang}{cmd:. rddid outcome score, group(treated) h(5 10 5 5)}{p_end}

{phang}4. Bootstrapped standard errors (200 reps){p_end}
{phang}{cmd:. rddid outcome score, group(treated) bootstrap reps(200)}{p_end}

{phang}5. Analytic SEs with specific rdrobust options (e.g., HC1){p_end}
{phang}{cmd:. rddid outcome score, group(treated) vce(hc1)}{p_end}

{title:Author}
{pstd}Jonathan Dries{p_end}
{pstd}LUISS Guido Carli University{p_end}
{pstd}Email: jvdries@luiss.it{p_end}
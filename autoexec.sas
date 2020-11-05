*options msglevel=i;

%macro chckpt(mode);
proc status noprint;
 checkpoint &mode;
;
%mend;

%macro pysas(source, target=);
%put Running conversion to python...;
%put Source: &source..sas;
%pysas_cmd(&source);
%put Conversion complete.;
%mend pysas;

%macro pysas_cmd(source);
x CLASSPATH="" $PYSAS_HOME/pysas -log - &source..sas || /bin/true;
%mend pysas_cmd;



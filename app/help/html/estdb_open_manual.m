function estdb_open_manual()
%find the location of the asmita app and open the manual
appname = 'EstuaryDB';
appinfo = matlab.apputil.getInstalledAppInfo;
idx = find(strcmp({appinfo.name},appname));
fpath = [appinfo(idx(1)).location,[filesep,appname,filesep,'app',...
                        filesep,'doc',filesep,'EstuaryDB manual.pdf']];
open(fpath)

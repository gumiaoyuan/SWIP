%%% SURFACE-WAVE dispersion INVERSION & PROFILING (SWIP)
%%% MODULE A : SWIPdisp.m
%%% S. Pasquet - V16.8.22
%%% SWIPdisp.m performs windowing and stacking of surface-wave dispersion
%%% It allows to pick dispersion curves and save dispersion, spectrogram and seismograms
%%% Required file : one SU file containing all shot gathers
%%% Required SU headers : fldr, tracf, gx, sx, ns, dt

run('SWIP_defaultsettings')

if (exist('calc','var')==1 && isempty(calc)==1) || exist('calc','var')==0
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n   Please choose a calculation option');
    fprintf('\n   calc = 0 to select an existing SWIP folder');
    fprintf('\n   calc = 1 to perform SWIP with an SU file');
    fprintf('\n   calc = 2 to import dispersion curves');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
    return
end

% Directories settings
if calc==1
    dir_all=dir_create(1,nWmin,nWmax,dW,dSmin,dSmax,side);
    sizeax=[]; f=[]; v=[]; tseis=[]; fspec=[];
    if plotspec==1
        plotdisp=1; % To avoid sizeax problems
    end
elseif calc==0
    dir_all=dir_create(0);
    if dir_all.dir_main==0
        return
    end
elseif calc==2
    answer1=inputdlg({'Window size (nb of traces)','Inter-geophone spacing (m)',...
        'Window lateral shift (nb of traces)','Spatial scaling xsca'},'Acquisition Settings',1);
    if isempty(answer1)==1 || isnan(str2double(answer1(1)))==1 || ...
            isnan(str2double(answer1(1)))==1 || isnan(str2double(answer1(3)))==1
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Please provide all requested parameters');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    dx=str2double(answer1(2));
    acquiparam.dx=dx;
    nWmin=str2double(answer1(1));
    nWmax=nWmin;
    dW=str2double(answer1(3));
    xsca=str2double(answer1(4));
    dSmin=1; dSmax=1; side='imported';
    dir_all=dir_create(1,nWmin,nWmax,dW,dSmin,dSmax,side);
    sizeax=[]; f=fmin:1:fmax; v=0:10:vmax; fspec=[]; tseis=[];
    sufile='imported';
else
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n   Please select a valid option for calc');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
    return
end
dir_start=dir_all.dir_start;
dir_dat=dir_all.dir_dat;
dir_pick=dir_all.dir_pick;
dir_targ=dir_all.dir_targ;
dir_img=dir_all.dir_img;
dir_img_xmid=dir_all.dir_img_xmid;

dir_img_disp=fullfile(dir_img_xmid,'disp');
if exist(dir_img_disp,'dir')~=7 && plotdisp==1
    mkdir(dir_img_disp);
end
dir_img_pick=fullfile(dir_img_xmid,'disp_pick');
if exist(dir_img_pick,'dir')~=7 && plotpckdisp==1
    mkdir(dir_img_pick);
end
dir_img_spec=fullfile(dir_img_xmid,'spectro');
if exist(dir_img_spec,'dir')~=7 && plotspec==1
    mkdir(dir_img_spec);
end
dir_img_seismo=fullfile(dir_img_xmid,'seismo');
if exist(dir_img_seismo,'dir')~=7 && plotseismo==1
    mkdir(dir_img_seismo);
end
dir_img_single=fullfile(dir_img_xmid,'prestack');
if exist(dir_img_single,'dir')~=7 && plotsingle==1
    mkdir(dir_img_single);
end
dir_img_stkdisp=fullfile(dir_img_xmid,'synstack');
if exist(dir_img_stkdisp,'dir')~=7 && plotstkdisp==1
    mkdir(dir_img_stkdisp);
end

% Get .SU file acquisition settings
if calc==1
    sustruct=dir(fullfile(dir_start,'*.su'));
    if length(sustruct)>1
        sufile=uigetfile('*.su','Select SU file to use');
    else
        sufile=sustruct.name;
    end
    matfile=fullfile(dir_dat,[sufile,'.param.mat']);
    if exist(matfile,'file')==2
        load(matfile);
        dir_all=dir_create(1,nWmin,nWmax,dW,dSmin,dSmax,side);
    end
    acquiparam=get_acquiparam(sufile,xsca);
    dx=acquiparam.dx; % Mean inter-geophone spacing (m)
    if dx==0
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Please provide inter-geophone spacing');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    topo=acquiparam.topo; % Get topography (X,Z in m)
elseif calc==0
    % Read stack and p-w parameters from .mat file
    matstruct=dir(fullfile(dir_dat,'*.param.mat'));
    matfile=fullfile(dir_dat,matstruct.name);
    try
        load(matfile);
    catch
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Missing .mat file in file.dat folder');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    dx=acquiparam.dx; % Mean inter-geophone spacing (m)
    nWmin=stackdisp.nWmin;
    nWmax=stackdisp.nWmax;
    dW=stackdisp.dW;
    dSmin=stackdisp.dSmin;
    dSmax=stackdisp.dSmax;
    side=stackdisp.side;
    nray=pomega.nray;
    fmin=pomega.fmin;
    fmax=pomega.fmax;
    vmin=pomega.vmin;
    vmax=pomega.vmax;
    xsca=pomega.xsca;
    flip=pomega.flip;
    sizeax=plotopt.sizeax;
    flim=xmidparam.flim;
    if freqlim==0
        flim=flim*NaN;
    end
    if plotspec==1 && isempty(sizeax)==1
        plotdisp=1; % To avoid sizeax problems
    end
else
    matfile=fullfile(dir_dat,'imported.param.mat');
    if exist(matfile,'file')==2
        load(matfile);
    end
    acquiparam.dx=dx;
    plotdisp=0; plotspec=0; plotseismo=0;
    plotsingle=0; plotstkdisp=0;
    freqlim=0; pick=0; plotflim=0;
    acquiparam.dt=[]; acquiparam.Gx=[]; acquiparam.Gz=[];
    acquiparam.Sx=[]; acquiparam.Sz=[]; acquiparam.NGx=[];
    acquiparam.NSx=[]; acquiparam.Gxsing=[]; acquiparam.Gzsing=[];
    acquiparam.Sxsing=[]; acquiparam.Szsing=[];
end

% XmidT position initialization
xmidformat=['%12.',num2str(log(xsca)/log(10)),'f']; % Precision
if calc~=2 % From SU file
    dt=acquiparam.dt; % Sampling interval (s)
    Gxsing=acquiparam.Gxsing; % Single geophones positions
    Sxsing=acquiparam.Sxsing; % Single sources positions
    if calc==1
        xmin=min(Gxsing); % Get starting X coordinate (m)
        xmax=max(Gxsing); % Get ending X coordinate (m)
        winsize=nWmin:2:nWmax;
        maxwinsize=(winsize-1)*dx;
        nwin=length(winsize);
        if mod(nWmin,2)==1
            XmidT=Gxsing(1+(nWmin-1)/2:dW:end-(nWmin-1)/2);
        else
            XmidT=mean([Gxsing((nWmin)/2:dW:end-(nWmin)/2),...
                Gxsing(1+(nWmin)/2:dW:1+end-(nWmin)/2)],2);
        end
        XmidT=round(XmidT'*xsca)/xsca;
        Xlength=length(XmidT);
        if exist(matfile,'file')==2
            nshot=xmidparam.nshot;
            Gmin=xmidparam.Gmin; Gmax=xmidparam.Gmax;
            lmaxpick=targopt.lmaxpick;
        else
            nshot=zeros(Xlength,nwin);
            Gmin=NaN*nshot; Gmax=Gmin;
            lmaxpick=zeros(Xlength,1)*NaN;
        end
    else
        winsize=xmidparam.winsize; maxwinsize=xmidparam.maxwinsize;
        nwin=xmidparam.nwin; nshot=xmidparam.nshot;
        XmidT=xmidparam.XmidT; Xlength=xmidparam.Xlength;
        Gmin=xmidparam.Gmin; Gmax=xmidparam.Gmax;
        flim=xmidparam.flim; zround=xmidparam.zround;
        lmaxpick=targopt.lmaxpick;
    end
    if isempty(dt)==1
        plotdisp=0; plotspec=0; plotseismo=0;
        plotsingle=0; plotstkdisp=0;
        freqlim=0; pick=0; plotflim=0;
    end
else % From imported dispersion curves
    dt=[];
    dir_pick_ext=uigetdir('./','Select folder containing dispersion curves');
    if dir_pick_ext==0
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Please select a folder containing dispersion curves');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    dispstruct=dir(fullfile(dir_pick_ext));
    xmidlocal=ones(length(dispstruct)-2,1);
    dspfile_sum='fake';
    if length(dispstruct)==2
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Empty folder - Please select a folder containing dispersion curves');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    ii=0;
    for ip=1:length(dispstruct)
        if strcmp(dispstruct(ip).name,'.')==1 || strcmp(dispstruct(ip).name,'..')==1
            continue
        else
            ii=ii+1;
        end
        dispfile=dispstruct(ip).name;
        [~,~,extension]=fileparts(dispfile);
        if strcmp(extension,'.pvc')==1
            try
                xmidlocal(ii)=str2double(dispfile(1:strfind(dispfile,'.M')-1));
                mi=str2double(dispfile(strfind(dispfile,'.M')+2:strfind(dispfile,'.pvc')-1));
                load(fullfile(dir_pick_ext,dispfile));
                if strcmp([dir_pick_ext,'/'],fullfile(dir_start,dir_pick))==0
                    newfilename=[num2str(xmidlocal(ii),xmidformat),'.M',num2str(mi),'.pvc'];
                    copyfile(fullfile(dir_pick_ext,dispfile),fullfile(dir_pick,newfilename));
                end
            catch
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                fprintf('\n   Wrong format for dispersion curve - Go to next file');
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
                continue
            end
        else
            try
                load(fullfile(dir_pick_ext,dispfile));
                answer1=inputdlg({'Xmid position (m)','Mode number (fundamental=0)'},...
                    [dispfile,' settings'],1);
                if isempty(answer1)==1 || isnan(str2double(answer1(1)))==1 || ...
                        isnan(str2double(answer1(1)))==1
                    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                    fprintf('\n   Please provide Xmid position');
                    fprintf('\n         and mode number');
                    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
                    return
                end
                xmidlocal(ii)=str2double(answer1(1));
                mi=str2double(answer1(2));
                newfilename=[num2str(xmidlocal(ii),xmidformat),'.M',num2str(mi),'.pvc'];
                copyfile(fullfile(dir_pick_ext,dispfile),fullfile(dir_pick,newfilename));
            catch
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                fprintf('\n   Wrong format for dispersion curve - Go to next file');
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
                continue
            end
        end
    end
    XmidT_import=unique(xmidlocal(isnan(xmidlocal)==0));
    Xlength_import=length(unique(xmidlocal(isnan(xmidlocal)==0)));
    if Xlength_import==0
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   No valid dispersion curves in the folder');
        fprintf('\n         Check file format and retry');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    XmidT=[];
    for ii=2:Xlength_import
        XmidT=[XmidT,XmidT_import(ii-1):dW*dx:XmidT_import(ii)-0.5*dW*dx];
        if ii==Xlength_import
            XmidT=[XmidT,XmidT_import(end)];
        end
    end
    XmidT=unique(XmidT);
    Xlength=length(XmidT);
    xmin=min(XmidT)-dx; xmax=max(XmidT)+dx;
    nshot=ones(Xlength,1);
    Gmin=nshot; Gmax=nshot; flim=nshot-1;
    nshot(ismember(XmidT,XmidT_import)==0)=-1;
    winsize=nWmin; maxwinsize=(winsize-1)*dx;
    nwin=length(winsize);
    if exist(matfile,'file')==2
        lmaxpick=targopt.lmaxpick;
    else
        lmaxpick=zeros(Xlength,1)*NaN;
    end
end
if exist('Xmidselec','var')~=1 || isempty(Xmidselec)==1
    Xmidselec=1:Xlength;
end
if max(Xmidselec)>Xlength
    Xmidselec=Xmidselec(Xmidselec<=Xlength);
end

% Bandpass filter
if filt==1 && calc==1
    sufilefilt=[sufile,'.filt'];
    com1=sprintf('sufilter < %s f=%d,%d,%d,%d amps=0,1,1,0 > %s',...
        sufile,fcutlow,fcutlow+taper,fcuthigh-taper,fcuthigh,sufilefilt);
    unix(com1);
    sufileOK=sufilefilt;
else
    if calc~=2
        sufileOK=sufile;
    end
end

% Topo and flim initialization
if calc~=0
    if calc==1
        if exist(matfile,'file')==2
            flim=xmidparam.flim;
        else
            flim=zeros(Xlength,1);
        end
    elseif calc==2
        [topofile,topopath]=uigetfile('*','Select topo file (X,Z) or cancel for flat topo');
        if sum(topofile)~=0
            topo=load(fullfile(topopath,topofile));
        else
            topo(:,1)=XmidT;
            topo(:,2)=zeros(Xlength,1);
        end
        acquiparam.topo=topo;
    end
    z=interp1(topo(:,1),topo(:,2),XmidT,'linear','extrap'); % Interpolate topo for all Xmid
    zround=fix(z*100)/100; % Keep only 2 decimals for topo
    xmidparam.zround=zround;
end

% Colormap and colorbar initialization for curve plot
if plot1dobs==1
    cticks=XmidT(1:ceil(Xlength/5):end); % Colorbar ticks
    ccurve=flipud(autumn(Xlength)); % Colormap for dispersion curve position
end

% Initialization of the maximum number of modes
if isempty(maxmodeinv)==1
    pvcstruct=dir(fullfile(dir_pick,'*.pvc'));
    npvc=length(pvcstruct);
    M=[];
    for ip=1:npvc
        pvcfile=pvcstruct(ip).name;
        m=str2double(pvcfile(end-4));
        if ismember(m,M)==0
            M=[M,m];
        end
    end
    maxmodeinv=max(M);
    if isempty(maxmodeinv)==1
        maxmodeinv=0;
    end
end

% Initialization of phase velocity pseudo-section
if plot2dobs==1
    vph2dobs=cell(maxmodeinv+1,1);
    for ip=1:maxmodeinv+1
        vph2dobs{ip}=zeros(length(resampvec),Xlength)*NaN;
    end
end

% Save settings in .mat file
if calc~=0
    % Store parameters in structure
    stackdisp=struct('nWmin',nWmin,'nWmax',nWmax,'dW',dW,...
        'dSmin',dSmin,'dSmax',dSmax,'side',side,'xmidformat',xmidformat);
    pomega=struct('nray',nray,'fmin',fmin,'fmax',fmax,...
        'vmin',vmin,'vmax',vmax,'xsca',xsca,'tsca',tsca,'flip',flip);
    xmidparam=struct('winsize',winsize,'maxwinsize',maxwinsize,...
        'nwin',nwin,'XmidT',XmidT,'Xlength',Xlength,'nshot',nshot,...
        'Gmin',Gmin,'Gmax',Gmax,'flim',flim,'zround',zround);
    targopt=struct('sampling',sampling,'resampvec',resampvec,'wave',wave,'lmaxpick',lmaxpick);
    filtmute=struct('filt',filt,'fcutlow',fcutlow,'fcuthigh',fcuthigh,...
        'taper',taper,'mute',mute,'tmin1',tmin1,'tmin2',tmin2,...
        'tmax1',tmax1,'tmax2',tmax2);
    % Save param in .mat file
    if exist(matfile,'file')==2
        save(matfile,'-append','acquiparam','stackdisp','pomega',...
            'dir_all','sufile','xmidparam','targopt','filtmute');
    else
        save(matfile,'acquiparam','stackdisp','pomega',...
            'dir_all','sufile','xmidparam','targopt','filtmute');
    end
end

matrelease=version('-release');

if cb_disp==1 && cbpos==2
    cb_disp=2;
end

%% CALCULATIONS FOR ALL XMIDS

%%%%%% Loop over all Xmids %%%%%%

i=0; % Xmid number flag
while i<length(Xmidselec)
    i=i+1; ix=Xmidselec(i);
    
    %%
    if sum(nshot(ix,:))>=0
        fprintf(['\n  Xmid',num2str(ix),' = ',num2str(XmidT(ix),xmidformat),' m \n']);
    end
    
    if calc~=2
        % Create folder to store intermediate files for each Xmid
        dir_dat_xmid=fullfile(dir_dat,['Xmid_',num2str(XmidT(ix),xmidformat)]);
        if exist(dir_dat_xmid,'dir')~=7 && (calc==1 || plotsingle==1 || plotstkdisp==1)
            mkdir(dir_dat_xmid);
        end
        % Stacked dispersion file name (delete if exists and calc=1)
        dspfile_sum=fullfile(dir_dat,[num2str(XmidT(ix),xmidformat),'.sum.dsp']);
        if exist(dspfile_sum,'file')==2 && (calc==1 || plotstkdisp==1)
            delete(dspfile_sum);
        end
        
        %%%%%% Loop over window sizes %%%%%%
        if calc==1 || plotsingle==1 || plotstkdisp==1
            j=0; % Stack flag
            for jw=1:nwin
                % Retrieve first and last geophone position for the current window
                if mod(nWmin,2)==1 % Non-even number of traces
                    Gleft=Gxsing(find(Gxsing<XmidT(ix),(winsize(jw)-1)/2,'last'));
                    Gright=Gxsing(find(Gxsing>XmidT(ix),(winsize(jw)-1)/2));
                    ntr=length(Gleft)+length(Gright)+1;
                    if ntr~=winsize(jw) && (calc==1 || plotsingle==1 || plotstkdisp==1) % Check number of extracted traces
                        fprintf(['\n  Not enough traces with nW = ',num2str(winsize(jw)),...
                            ' - Go to next shot or Xmid\n']);
                        continue
                    end
                    Gmin(ix,jw)=min(Gleft);
                    Gmax(ix,jw)=max(Gright);
                else % Even number of traces
                    Gleft=Gxsing(find(Gxsing<XmidT(ix),(winsize(jw))/2,'last'));
                    Gright=Gxsing(find(Gxsing>XmidT(ix),(winsize(jw))/2));
                    ntr=length(Gleft)+length(Gright);
                    if ntr~=winsize(jw) && (calc==1 || plotsingle==1 || plotstkdisp==1) % Check number of extracted traces
                        fprintf(['\n  Not enough traces with nW = ',num2str(winsize(jw)),...
                            ' - Go to next shot or Xmid\n']);
                        continue
                    end
                    Gmin(ix,jw)=min(Gleft);
                    Gmax(ix,jw)=max(Gright);
                end
                % Retrieve min and max sources position on both sides of the window
                Smin=XmidT(ix)-(maxwinsize(jw)/2)-(dx*dSmax+dx);
                Smax=XmidT(ix)+(maxwinsize(jw)/2)+(dx*dSmax+dx);
                Smed1=XmidT(ix)-(maxwinsize(jw)/2)-(dx*dSmin);
                Smed2=XmidT(ix)+(maxwinsize(jw)/2)+(dx*dSmin);
                % Select existing sources according to the specified side
                if strcmp(side,'L')==1
                    Sselec=Sxsing(Sxsing>Smin & Sxsing<=Smed1);
                elseif strcmp(side,'R')==1
                    Sselec=Sxsing(Sxsing<Smax & Sxsing>=Smed2);
                else
                    Sselec=Sxsing((Sxsing>Smin & Sxsing<=Smed1) | ...
                        (Sxsing<Smax & Sxsing>=Smed2));
                end
                % Get nb of selected shot for the current window
                nshot(ix,jw)=length(Sselec);
                if (calc==1 || plotsingle==1 || plotstkdisp==1)
                    fprintf(['\n  ',num2str(nshot(ix,jw)),...
                        ' shot(s) with nW = ',num2str(winsize(jw)),'\n']);
                end
                
                %%%%%% Loop over all selected shots %%%%%%
                
                for ks=1:nshot(ix,jw)
                    % Windowing, muting and saving seismogram in .su file
                    seismofile=fullfile(dir_dat_xmid,[num2str(XmidT(ix),xmidformat),'.',...
                        num2str(winsize(jw)),'.',num2str(Sselec(ks)),'.su']);
                        [seismomat,xseis,tseis,ntr]=matwind(sufileOK,Sselec(ks),Gmin(ix,jw),Gmax(ix,jw),xsca,...
                            winsize(jw),seismofile,0,mute,tmin1,tmin2,tmax1,tmax2);
                        if ntr~=winsize(jw) % Check number of extracted traces
                            fprintf('\n  Not enough traces - Go to next shot\n');
                            nshot(ix,jw)=nshot(ix,jw)-1;
                            continue
                        end
                    j=j+1; % Stack flag
                    % P-Omega transform on seismogram and saving in .dsp file
                    dspfile=fullfile(dir_dat_xmid,[num2str(XmidT(ix),xmidformat),'.',...
                        num2str(winsize(jw)),'.',num2str(Sselec(ks)),'.dsp']);
                        [dspmat,f,v]=matpomegal(seismofile,1,nray,fmin,fmax,vmin,vmax,...
                            flip,xsca,tsca,1,dspfile,0);
                    % Spectrogram calculation on seismogram and saving in .spec file
                    specfile=fullfile(dir_dat_xmid,[num2str(XmidT(ix),xmidformat),'.',...
                        num2str(winsize(jw)),'.',num2str(Sselec(ks)),'.spec']);
                        [specmat,fspec,xspec]=matspecfx(seismofile,xsca,specfile,0);
                        if ((strcmp(side,'L')==1 || strcmp(side,'B')==1) && XmidT(ix)>Sselec(ks))
                            specfileOK = specfile;
                        elseif (strcmp(side,'R')==1 && XmidT(ix)<Sselec(ks)) && exist('specfileOK','var')==0
                            specfileOK = specfile;
                        else
                            specfileOK = specfile;
                        end
                    
                    %%%%%% Plot and save single images %%%%%%
                    
                    if plotsingle==1 && exist(dir_dat_xmid,'dir')==7
                        dir_img_xmid_single=fullfile(dir_img_single,['Xmid_',num2str(XmidT(ix),xmidformat)]);
                        if exist(dir_img_xmid_single,'dir')~=7
                            mkdir(dir_img_xmid_single);
                        end
                        fprintf(['\n  Plot and save single images for shot ' num2str(j) '\n']);
                        if plotflim==1
                            % Local fmin search
                            specstruct=dir(fullfile(dir_dat_xmid,...
                                [num2str(XmidT(ix),xmidformat),'.',num2str(winsize(jw)),'.',...
                                num2str(Sselec(ks)),'.spec']));
                            if freqlim==1
                                flimsing=fmin_search(specstruct,...
                                    dir_dat_xmid,dt,specampmin,fminpick);
                            else
                                flimsing=fminpick;
                            end
                        else
                            flimsing=NaN;
                        end
                        % Plot single dispersion image
                        if plotdisp==1
                            if Dlogscale==0
                                fig1=plot_img(showplot,f,v,dspmat',flipud(map0),axetop,axerev,cb_disp,fs,...
                                    'Frequency (Hz)','Phase velocity (m/s)',...
                                    'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                                    [],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
                            else
                                dspmatinv=1./(1-dspmat);
                                dspmatinv(isinf(dspmatinv))=max(max(dspmatinv(isinf(dspmatinv)==0)));
                                fig1=plot_img_log(showplot,f,v,dspmatinv',flipud(map0),axetop,axerev,cb_disp,fs,...
                                    'Frequency (Hz)','Phase velocity (m/s)','1/(1-Norm. ampli.)',...
                                    [fMIN fMAX],[VphMIN VphMAX],[1 length(map0)],fticks,Vphticks,...
                                    [],[],flimsing,[],[0 0 24 18],[]);
                            end
                            if Flogscale==1
                                set(gca,'xscale','log');
                            end
                            sizeax=get(findobj(fig1,'Type','Axes'),'Position');
                            if cb_disp==1
                                sizeax=sizeax{2};
                            end
                            file1=fullfile(dir_img_xmid_single,[num2str(XmidT(ix),xmidformat),...
                                '.',num2str(winsize(jw)),'.',num2str(Sselec(ks)),...
                                '.disp.',imgform]);
                            save_fig(fig1,file1,imgform,imgres,1);
                            close(fig1)
                        end
                        % Plot single spectrogram image
                        if plotspec==1
                            fig2=plot_img(showplot,fspec,xspec,specmat,flipud(map0),axetop,axerev,cb_disp,fs,...
                                'Frequency (Hz)','Gx (m)','Norm. ampli.',...
                                [fMIN fMAX],[min(xspec) max(xspec)],[],[],[],...
                                [],[],flimsing,[],[0 0 24 18],[],[],0);
                            if Flogscale==1
                                set(gca,'xscale','log');
                            end
                            set(findobj(fig2,'Type','Axes'),'ActivePositionProperty','Position');
                            if cb_disp==1
                                axeok=findobj(fig2,'Type','Axes');
                                set(axeok(2),'position',[sizeax(1),sizeax(2),sizeax(3),sizeax(4)/3]);
                            else
                                set(findobj(fig2,'Type','Axes'),'position',...
                                    [sizeax(1),sizeax(2),sizeax(3),sizeax(4)/3]);
                            end
                            file2=fullfile(dir_img_xmid_single,[num2str(XmidT(ix),xmidformat),...
                                '.',num2str(winsize(jw)),'.',num2str(Sselec(ks)),...
                                '.spec.',imgform]);
                            save_fig(fig2,file2,imgform,imgres,1);
                            close(fig2)
                        end
                        % Plot single seismogram image
                        if plotseismo==1
                            fig3=plot_wiggle(showplot,-seismomat',xseis,tseis*1000,...
                                1,1,99,fs,'Gx (m)','Time (ms)',[],[tMIN tMAX],[],tticks,[0 0 18 24],[]);
                            file3=fullfile(dir_img_xmid_single,[num2str(XmidT(ix),xmidformat),...
                                '.',num2str(winsize(jw)),'.',num2str(Sselec(ks)),...
                                '.seismo.',imgform]);
                            save_fig(fig3,file3,imgform,imgres,1);
                            close(fig3)
                        end
                    end
                    
                    %%%%%% Dispersion stacking calculation %%%%%%
                    
                    % Create zeros .dsp file for first iteration stacking
                    if exist(dspfile_sum,'file')~=2 && (calc==1 || plotstkdisp==1)
                        com1=sprintf('suop2 %s %s op=diff > %s',dspfile,dspfile,dspfile_sum);
                        unix(com1);
                    end
                    if calc==1 || plotstkdisp==1
                        % Stack current dispersion image with previous stack file
                        dspfile_sum_new=[dspfile_sum,'.new'];
                        com1=sprintf('suop2 %s %s op=sum > %s',dspfile_sum,...
                            dspfile,dspfile_sum_new);
                        unix(com1);
                        movefile(dspfile_sum_new,dspfile_sum)
                        
                        % Plot and save intermediate stack
                        if  plotstkdisp==1
                            dspfile_sum_stack=[dspfile_sum,'.stack'];
                            com1=sprintf('suop < %s op=norm > %s',dspfile_sum,dspfile_sum_stack);
                            unix(com1);
                            [dspmat,f,v]=dsp2dat(dspfile_sum_stack,flip,0);
                            delete(dspfile_sum_stack);
                            dir_img_xmid_stack=fullfile(dir_img_stkdisp,['Xmid_',num2str(XmidT(ix),xmidformat)]);
                            if exist(dir_img_xmid_stack,'dir')~=7
                                mkdir(dir_img_xmid_stack);
                            end
                            if plotflim==1
                                % Local fmin search
                                specstruct=dir(fullfile(dir_dat_xmid,...
                                    [num2str(XmidT(ix),xmidformat),'.*.spec']));
                                if freqlim==1
                                    flimsing=fmin_search(specstruct,...
                                        dir_dat_xmid,dt,specampmin,fminpick);
                                else
                                    flimsing=fminpick;
                                end
                            else
                                flimsing=NaN;
                            end
                            fprintf(['\n  Plot and save intermediate stack ',num2str(j),'\n']);
                            if Dlogscale==0
                                fig1=plot_img(showplot,f,v,dspmat',flipud(map0),axetop,axerev,cb_disp,fs,...
                                    'Frequency (Hz)','Phase velocity (m/s)',...
                                    'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                                    [],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
                            else
                                dspmatinv=1./(1-dspmat);
                                dspmatinv(isinf(dspmatinv))=max(max(dspmatinv(isinf(dspmatinv)==0)));
                                fig1=plot_img_log(showplot,f,v,dspmatinv',flipud(map0),axetop,axerev,cb_disp,fs,...
                                    'Frequency (Hz)','Phase velocity (m/s)',...
                                    '1/(1-Norm. ampli.)',[fMIN fMAX],[VphMIN VphMAX],...
                                    [1 length(map0)],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
                            end
                            if Flogscale==1
                                set(gca,'xscale','log');
                            end
                            sizeax=get(findobj(fig1,'Type','Axes'),'Position');
                            if cb_disp==1
                                sizeax=sizeax{2};
                            end
                            file1=fullfile(dir_img_xmid_stack,[num2str(XmidT(ix),xmidformat),...
                                '.stack',num2str(j),'.disp.',imgform]);
                            save_fig(fig1,file1,imgform,imgres,1);
                            close(fig1)
                        end
                    end
                end
            end
        end
    end
    
    %%
    %%%%%% End of main loops %%%%%%
    
    % Global fmin search
    if calc==1
        specstruct=dir(fullfile(dir_dat_xmid,...
            [num2str(XmidT(ix),xmidformat),'.*.spec']));
        [flim(ix),~]=fmin_search(specstruct,...
            dir_dat_xmid,dt,specampmin,fminpick);
    end
    % Store specfile resulting from fmin search
    if (sum(nshot(ix,:))>0 && exist(dspfile_sum,'file')==2) || isempty(dt)==1
        if calc==1 || plotstkdisp==1
            matop(dspfile_sum,'norm',flip);
            copyfile(specfileOK,[dspfile_sum(1:end-3),'spec']);
            copyfile([specfileOK(1:end-4),'su'],[dspfile_sum(1:end-3),'su']);
        end
        if plotflim==1
            if freqlim==1
                flimsing=flim(ix);
            else
                flimsing=fminpick;
            end
        else
            flimsing=NaN;
        end
        
        %%
        %%%%%% Plot and save final images %%%%%%
        
        % Plot and save stacked dispersion image
        if pick==1 || plotdisp==1 || plotpckdisp==1
            if exist(dspfile_sum,'file')==2
                [dspmat,f,v]=dsp2dat(dspfile_sum,flip,0);
                if pick==1 || pick==2
                    dspmat2=dspmat; v2=v;
                    while min(diff(v2))<dvmin % Downsample dispersion image to 5m/s in velocity to speed display when picking
                        v2=v2(1:2:end);
                        dspmat2=dspmat2(:,1:2:end);
                    end
                end
            end
        end
        if  plotdisp==1
            fprintf('\n  Plot and save stacked dispersion image\n');
            if Dlogscale==0
                fig1=plot_img(showplot,f,v,dspmat',flipud(map0),axetop,axerev,cb_disp,fs,...
                    'Frequency (Hz)','Phase velocity (m/s)',...
                    'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                    [],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
            else
                dspmatinv=1./(1-dspmat);
                dspmatinv(isinf(dspmatinv))=max(max(dspmatinv(isinf(dspmatinv)==0)));
                fig1=plot_img_log(showplot,f,v,dspmatinv',flipud(map0),axetop,axerev,cb_disp,fs,...
                    'Frequency (Hz)','Phase velocity (m/s)',...
                    '1/(1-Norm. ampli.)',[fMIN fMAX],[VphMIN VphMAX],...
                    [1 length(map0)],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
            end
            if Flogscale==1
                set(gca,'xscale','log');
            end
            sizeax=get(findobj(fig1,'Type','Axes'),'Position');
            if cb_disp==1
                sizeax=sizeax{2};
            end
            file1=fullfile(dir_img_disp,[num2str(XmidT(ix),xmidformat),'.disp.',imgform]);
            save_fig(fig1,file1,imgform,imgres,1);
            close(fig1)
        end
        % Plot and save spectrogram image
        if plotspec==1
            fprintf('\n  Plot and save final spectrogram image\n');
            [specmat,fspec,xspec]=spec2dat([dspfile_sum(1:end-3),'spec'],0);
            xspec=xspec/xsca;
            fig2=plot_img(showplot,fspec,xspec,specmat,flipud(map0),axetop,axerev,cb_disp,fs,...
                'Frequency (Hz)','Gx (m)','Norm. ampli.',...
                [fMIN fMAX],[min(xspec) max(xspec)],[],[],[],...
                [],[],flimsing,[],[0 0 24 18],[],[],0);
            if Flogscale==1
                set(gca,'xscale','log');
            end
            set(findobj(fig2,'Type','Axes'),'ActivePositionProperty','Position');
            if cb_disp==1
                axeok=findobj(fig2,'Type','Axes');
                set(axeok(2),'position',[sizeax(1),sizeax(2),sizeax(3),sizeax(4)/3]);
            else
                set(findobj(fig2,'Type','Axes'),'position',...
                    [sizeax(1),sizeax(2),sizeax(3),sizeax(4)/3]);
            end
            file2=fullfile(dir_img_spec,[num2str(XmidT(ix),xmidformat),'.spec.',imgform]);
            save_fig(fig2,file2,imgform,imgres,1);
            close(fig2)
        end
        % Plot and save seismogram image
        if plotseismo==1
            fprintf('\n  Plot and save final seismogram image\n');
            [seismomat,tseis,xseis]=seismo2dat([dspfile_sum(1:end-3),'su'],0);
            xseis=xseis/xsca;
            fig3=plot_wiggle(showplot,-seismomat',xseis,tseis*1000,1,1,99,...
                fs,'Gx (m)','Time (ms)',[],[tMIN tMAX],[],tticks,[0 0 18 24],[]);
            file3=fullfile(dir_img_seismo,[num2str(XmidT(ix),xmidformat),'.seismo.',imgform]);
            save_fig(fig3,file3,imgform,imgres,1);
            close(fig3)
        end
        
        %%
        %%%%%% Pick dispersion curves %%%%%%
        
        % Manual picking
        if pick==1
            % Plot previous Xmid to help picking
            if exist('dspmatprev','var')==1
                % Plot previous dispersion image if existing
                if xmidprev==0
                    flimplot=flim(Xmidselec(i-1));
                    figname=['Xmid = ',num2str(XmidT(Xmidselec(i-1))),' m'];
                else
                    flimplot=flim(Xmidselec(i+1));
                    figname=['Xmid = ',num2str(XmidT(Xmidselec(i+1))),' m'];
                end
                if mappicklog==0
                    fig2=plot_img(2,f,v2,-dspmatprev',mappick,axetop,axerev,0,12,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                        [],fticks,Vphticks,[],[],flimplot,[],[],[],[],0);
                else
                    dspmatinvprev=1./(1-dspmatprev);
                    dspmatinvprev(isinf(dspmatinvprev))=max(max(dspmatinvprev(isinf(dspmatinvprev)==0)));
                    fig2=plot_img_log(2,f,v2,-dspmatinvprev',flipud(mappick),axetop,axerev,0,12,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        '1/(1-Norm. ampli.)',[fMIN fMAX],[VphMIN VphMAX],...
                        [1 length(mappick)],fticks,Vphticks,[],[],flimplot,[],[],[],[],0);
                end
                set(fig2,'name',figname,'numbertitle','off');
%                 set(gcf,'units','normalized','outerposition',[0 0 1 1]); % Full screen left
%                 set(gcf,'units','normalized','outerposition',[-0.02 0.5 0.5 0.5]); % 1/4 screen left bottom
                set(gcf,'units','normalized','outerposition',[0.65 0.5 0.35 0.5]); % 1/4 screen right top
                if Flogscale==1
                    set(gca,'xscale','log');
                end
                % Plot previous dispersion curves if existing
                if xmidprev==0
                    pvcstruct=dir(fullfile(dir_pick,...
                        [num2str(XmidT(Xmidselec(i-1)),xmidformat),'.*.pvc']));
                else
                    pvcstruct=dir(fullfile(dir_pick,...
                        [num2str(XmidT(Xmidselec(i+1)),xmidformat),'.*.pvc']));
                end
                for ip=1:length(pvcstruct)
                    pvcfile=pvcstruct(ip).name;
                    Vprev=load(fullfile(dir_pick,pvcfile));
                    hold on;
                    plot(Vprev(:,1),Vprev(:,2),'c.');
                end
            end
            modenext=modeinit;
            while isempty(modenext)==0
                % Plot current dispersion image
                filepick=fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),...
                    '.M',num2str(modenext),'.pvc']);
                if mappicklog==0
                    [fig1,h1,~,h0]=plot_img(1,f,v2,-dspmat2',mappick,axetop,axerev,0,12,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                        [],fticks,Vphticks,[],[],flim(ix),[],[],[],[],0);
                else
                    dspmatinv2=1./(1-dspmat2);
                    dspmatinv2(isinf(dspmatinv2))=max(max(dspmatinv2(isinf(dspmatinv2)==0)));
                    [fig1,h1,~,h0]=plot_img_log(1,f,v2,-dspmatinv2',flipud(mappick),axetop,axerev,0,12,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        '1/(1-Norm. ampli.)',[fMIN fMAX],[VphMIN VphMAX],...
                        [1 length(mappick)],fticks,Vphticks,[],[],flim(ix),[],[],[],[],0);
                end
                set(fig1,'name',['Xmid = ',num2str(XmidT(ix)),' m'],'numbertitle','off');
%                 set(gcf,'units','normalized','outerposition',[0.3 0 1 1]); % Full screen right
%                 set(gcf,'units','normalized','outerposition',[-0.02 -0.02 0.5 0.5]); % % 1/4 screen left top
                set(gcf,'units','normalized','outerposition',[-0.02 -0.02 0.6 1]); % % 1/2 screen left
                if Flogscale==1
                    set(gca,'xscale','log');
                end
                pvcstruct=dir(fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),'.*.pvc']));
                % Plot current dispersion curves if existing
                for ip=1:length(pvcstruct)
                    pvcfile=pvcstruct(ip).name;
                    Vprev=load(fullfile(dir_pick,pvcfile));
                    hold on;
                    plot(Vprev(:,1),Vprev(:,2),'m.');
                end
                % Pick dispersion curves
                [Vi,deltac,modenext,closefig,xmidprev]=matpickamp(dspmat2,f,v2,filepick,pickstyle,...
                    modenext,err,smoothpick,mean([nWmin,nWmax]),dx,nWfac,maxerrrat,minerrvel,sigma);
                if closefig==0
                    close(fig1);
                end
                if xmidprev==1 && i==1
                    fprintf('\n  No previous Xmid - Stay on first Xmid\n');
                end
                if isempty(Vi)==0 && length(Vi)>1 && sum(isnan(Vi))~=length(Vi)
                    dlmwrite(filepick,[f(isnan(Vi)==0);Vi(isnan(Vi)==0);...
                        deltac(isnan(Vi)==0)]','delimiter','\t');
                    apvcfile=[filepick(1:end-4),'.apvc'];
                    if exist(apvcfile,'file')==2
                        delete(apvcfile);
                    end
                elseif isempty(Vi)==1 || (length(Vi)>1 && sum(isnan(Vi))~=length(Vi))
                    delete(filepick);
                end
            end
            if exist('dspmatprev','var')==1
                close(fig2);
            end
            dspmatprev=dspmat2; % Store current dspmat to show along next one
            
            % Automatic picking (requires at least one manually picked file)
        elseif pick==2
            pvcstructauto=dir(fullfile(dir_pick,['*.M',num2str(modeinit),'.pvc']));
            if length(pvcstructauto)<1
                fprintf('\n  Autopick requires at least one manually picked file\n');
                continue
            end
            % Read existing dispersion curves
            if i>1 && exist('pvcfileauto','var')==1
                filepickprev=fullfile(dir_pick,[num2str(XmidT(Xmidselec(i-1)),...
                    xmidformat),'.M',num2str(modeinit),'.pvc']);
                if exist(filepickprev,'file')==2
                    pvcfileauto=filepickprev;
                end
            else
                [~,idx]=sort([pvcstructauto.datenum]);
                pvcfileauto=fullfile(dir_pick,pvcstructauto(idx(1)).name);
            end
            Vprevauto=load(pvcfileauto);
            fpick=Vprevauto(:,1);
            vpick=Vprevauto(:,2);
            wl=Vprevauto(:,3);
            % Perform autopick, median filter and moving average
            [vpickauto,fpickauto]=findpeak(dspmat2,f,v2,fpick,vpick,1.5*wl);
            vpickauto=median_filt(vpickauto,9,1,length(vpickauto));
            vpickauto=mov_aver(vpickauto',5,1,length(vpickauto));
            deltacauto=lorentzerr(vpickauto',vpickauto'./fpickauto,mean([nWmin,nWmax]),dx,...
                nWfac,maxerrrat,minerrvel);
            filepick=fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),...
                '.M',num2str(modeinit),'.pvc']);
            dlmwrite(filepick,[fpickauto;vpickauto';deltacauto']','delimiter','\t');
            fprintf(['\n  Automatic pick for mode ',num2str(modeinit),'\n']);
        end
        
        %%
        %%%%%% Dinver target creation from .pvc dispersion curves %%%%%%
        
        % Check existence of all dispersion curves for this Xmid
        pvcstruct=dir(fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),'.*.*pvc']));
        npvc=length(pvcstruct);
        
        % Convert .pvc files to dinver .target
        if target==1
            nametarg=fullfile(dir_targ,[num2str(XmidT(ix),xmidformat),'.target']);
            if npvc>0 && maxmodeinv>=0
                for ip=1:npvc
                    pvcfile=pvcstruct(ip).name;
                    [~,pvcname,extension]=fileparts(pvcfile);
                    if strcmp(extension,'.apvc')==1 % Check if previously unused
                        movefile(fullfile(dir_pick,pvcfile),fullfile(dir_pick,[pvcname,'.pvc']));
                        pvcfile=[pvcname,'.pvc'];
                    end
                    m=str2double(pvcfile(end-4)); % Mode number
                    if m>maxmodeinv
                        apvcfile=[pvcfile(1:end-4),'.apvc'];
                        movefile(fullfile(dir_pick,pvcfile),fullfile(dir_pick,apvcfile))
                        continue
                    end
                    Vprev=load(fullfile(dir_pick,pvcfile));
                    if err==1
                        Vprev(:,3)=lorentzerr(Vprev(:,2)',Vprev(:,2)'./Vprev(:,1)',...
                            mean([nWmin,nWmax]),dx,nWfac,maxerrrat,minerrvel);
                    elseif err==2
                        Vprev(:,3)=Vprev(:,2)*0.01*sigma;
                    else
                        Vprev(:,3)=0;
                    end
                    dlmwrite(fullfile(dir_pick,pvcfile),Vprev,'delimiter','\t');
                end
                pvcstruct=dir(fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),'.*.pvc']));
                if isempty(pvcstruct)==0
                    if freqlim==1
                        lmpick=pvc2targ(pvcstruct,dir_pick,nametarg,wave,...
                            sampling,resampvec,flim(ix),maxerrrat);
                    else
                        lmpick=pvc2targ(pvcstruct,dir_pick,nametarg,wave,...
                            sampling,resampvec,fminpick,maxerrrat);
                    end
                    lmaxpick(ix)=max(lmpick);
                else
                    lmaxpick(ix)=NaN;
                    if exist(nametarg,'file')==2
                        delete(nametarg);
                    end
                end
            else
                if exist(nametarg,'file')==2
                    delete(nametarg);
                end
                lmaxpick(ix)=NaN;
            end
        else
            lmaxpick(ix)=NaN;
        end
        
        %%
        %%%%%% Read all dispersion curves %%%%%%
        
        nametarg=fullfile(dir_targ,[num2str(XmidT(ix),xmidformat),'.target']);
        if exist(nametarg,'file')==2
            % Read target file to get picked dispersion curves
            [freqresamp,vresamp,deltaresamp,modes]=targ2pvc(nametarg);
            npvc=length(modes);
            for ip=1:npvc
                % Resample in lambda or frequency
                if length(freqresamp{modes(ip)+1})>1
                    [freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1}]=...
                        resampvel(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                        deltaresamp{modes(ip)+1},resampvec,sampling,1);
                end
            end
        else
            % Check existence of used dispersion curves for this Xmid
            pvcstruct=dir(fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),'.*.pvc']));
            npvc=length(pvcstruct);
            for ip=1:npvc
                if exist(nametarg,'file')~=2
                    pvcfile=pvcstruct(ip).name;
                    modes(ip)=str2double(pvcfile(end-4)); % Mode number
                    if modes(ip)>maxmodeinv
                        break
                    end
                    Vprev=load(fullfile(dir_pick,pvcfile));
                    if min(size(Vprev))==2
                        Vprev(:,3)=Vprev(:,2)*0;
                    end
                    % Resample in lambda or frequency
                    [freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1}]=...
                        resampvel(Vprev(:,1),Vprev(:,2),Vprev(:,3),resampvec,sampling,1);
                else
                    
                end
            end
        end
        if ((npvc==0 && plotpckdisp==1) || (npvc==0 && plot1dobs==1) ||...
                (exist(nametarg,'file')~=2 && target==1)) && sum(nshot(ix,:))>=0
            fprintf('\n  No dispersion picked for this Xmid\n');
        end
        
        %%
        %%%%%% Plot all dispersion curves %%%%%%
        
        if (plot1dobs==1 || plot2dobs==1) && npvc>0
            for ip=1:npvc
                % Plot all dispersion curves in 1D
                if plot1dobs==1
                    fprintf(['\n  Plot dispersion curve for mode ',num2str(modes(ip)),'\n']);
                    % All modes in one figure
                    if length(Xmidselec)==1
                        if eb==1
                            plot_curv(4,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                                deltaresamp{modes(ip)+1},'.-',[1 0 0],[],axetop,axerev,...
                                0,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                'X (m)',[fMIN fMAX],[VphMIN VphMAX],[],fticks,Vphticks,[],...
                                [],[],[1 1 24 18],[]);
                        else
                            plot_curv(4,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},[],'.-',[1 0 0],[],axetop,axerev,...
                                0,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                'X (m)',[fMIN fMAX],[VphMIN VphMAX],[],fticks,Vphticks,[],...
                                [],[],[1 1 24 18],[]);
                        end
                        if Flogscale==1
                            set(gca,'xscale','log');
                        end
                        hold on
                    else
                        if ishandle(4)==0
                            if eb==1
                                plot_curv(4,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                                    deltaresamp{modes(ip)+1},'.-',ccurve(ix,:),[],axetop,axerev,...
                                    cbpos,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                    'X (m)',[fMIN fMAX],[VphMIN VphMAX],[min(XmidT) max(XmidT)],...
                                    fticks,Vphticks,[],[],[],[1 1 24 18],[]);
                                colormap(ccurve);
                            else
                                plot_curv(4,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},[],'.-',ccurve(ix,:),[],axetop,axerev,...
                                    cbpos,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                    'X (m)',[fMIN fMAX],[VphMIN VphMAX],[min(XmidT) max(XmidT)],...
                                    fticks,Vphticks,[],[],[],[1 1 24 18],[]);
                                colormap(ccurve);
                            end
                            if Flogscale==1
                                set(gca,'xscale','log');
                            end
                            hold on
                        else
                            figure(4);
                            plot(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},'.-','Color',ccurve(ix,:),...
                                'linewidth',1.5,'markersize',10);
                            if eb==1
                                if str2double(matrelease(1:4))>2014
                                    han=terrorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},1,'units');
                                    set(han,'LineWidth',1.5,'Color',ccurve(ix,:))
                                else
                                    han=errorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},...
                                        '.-','Color',ccurve(ix,:),'linewidth',1.5,'markersize',10);
                                    errorbar_tick(han,1,'units');
                                end
                            end
                        end
                    end
                    
                    % Single modes on separate figures
                    if length(Xmidselec)==1
                        if eb==1
                            plot_curv(modes(ip)+5,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                                deltaresamp{modes(ip)+1},'.-',[1 0 0],[],axetop,axerev,...
                                0,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                'X (m)',[fMIN fMAX],[VphMIN VphMAX],[],fticks,Vphticks,[],...
                                [],[],[30 1 24 18],[]);
                        else
                            plot_curv(modes(ip)+5,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},[],'.-',[1 0 0],[],axetop,axerev,...
                                0,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                'X (m)',[fMIN fMAX],[VphMIN VphMAX],[],fticks,Vphticks,[],...
                                [],[],[30 1 24 18],[]);
                        end
                    else
                        if ishandle(modes(ip)+5)==0
                            if eb==1
                                plot_curv(modes(ip)+5,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                                    deltaresamp{modes(ip)+1},'.-',ccurve(ix,:),[],axetop,axerev,...
                                    cbpos,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                    'X (m)',[fMIN fMAX],[VphMIN VphMAX],[min(XmidT) max(XmidT)],...
                                    fticks,Vphticks,[],[],[],[30 1 24 18],[]);
                                colormap(ccurve);
                            else
                                plot_curv(modes(ip)+5,freqresamp{modes(ip)+1},vresamp{modes(ip)+1},[],'.-',ccurve(ix,:),[],axetop,axerev,...
                                    cbpos,fs,'Frequency (Hz)','Phase velocity (m/s)',...
                                    'X (m)',[fMIN fMAX],[VphMIN VphMAX],[min(XmidT) max(XmidT)],...
                                    fticks,Vphticks,[],[],[],[30 1 24 18],[]);
                                colormap(ccurve);
                            end
                            if Flogscale==1
                                set(gca,'xscale','log');
                            end
                            hold on
                        else
                            figure(modes(ip)+5);
                            plot(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},'.-','Color',ccurve(ix,:),...
                                'linewidth',1.5,'markersize',10);
                            if eb==1
                                if str2double(matrelease(1:4))>2014
                                    han=terrorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},1,'units');
                                    set(han,'LineWidth',1.5,'Color',ccurve(ix,:))
                                else
                                    han=errorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},...
                                        '.-','Color',ccurve(ix,:),'linewidth',1.5,'markersize',10);
                                    errorbar_tick(han,1,'units');
                                end
                            end
                        end
                    end
                    drawnow;
                    if ix==Xmidselec(end)
                        
                    end
                end
                % Save all dispersion curves in matrix
                if plot2dobs==1
                    vph2dobs{modes(ip)+1}(:,ix)=vresamp{modes(ip)+1}';
                end
            end
            % Save 1D image with dispersion curves
            if (ix==Xmidselec(end) || (pick==1 && xmidprev==-1)) && plot1dobs==1 && ishandle(4)==1
                fprintf('\n  Save picked dispersion curves\n');
                file1=fullfile(dir_img,['Dispcurve.allmode.',imgform]);
                save_fig(4,file1,imgform,imgres,1);
                close(4)
                figHandles = findall(0,'Type','figure');
                if str2double(matrelease(1:4))>2014
                    figHandles=get(figHandles,'Number');
                end
                for ifig=figHandles'
                    if str2double(matrelease(1:4))>2014 && length(figHandles)>1
                        ifigok=ifig{1};
                    else
                        ifigok=ifig;
                    end
                    file1=fullfile(dir_img,['Dispcurve.M',num2str(ifigok-5),'.',imgform]);
                    save_fig(ifigok,file1,imgform,imgres,1);
                    close(ifigok)
                end
            end
        end
        
        %%
        %%%%%% Plot and save picked dispersion image %%%%%%
        
        if  plotpckdisp==1 && npvc>0
            fprintf('\n  Plot and save picked dispersion images\n');
            if exist(dspfile_sum,'file')==2
                if Dlogscale==0
                    fig1=plot_img(showplot,f,v,dspmat',flipud(map0),axetop,axerev,cb_disp,fs,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        'Norm. ampli.',[fMIN fMAX],[VphMIN VphMAX],...
                        [],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
                else
                    dspmatinv=1./(1-dspmat);
                    dspmatinv(isinf(dspmatinv))=max(max(dspmatinv(isinf(dspmatinv)==0)));
                    fig1=plot_img_log(showplot,f,v,dspmatinv',flipud(map0),axetop,axerev,cb_disp,fs,...
                        'Frequency (Hz)','Phase velocity (m/s)',...
                        '1/(1-Norm. ampli.)',[fMIN fMAX],[VphMIN VphMAX],...
                        [1 length(map0)],fticks,Vphticks,[],[],flimsing,[],[0 0 24 18],[]);
                end
            else
                fig1=plot_curv(showplot,NaN,NaN,[],'.',[0 0 0],[],axetop,axerev,...
                    0,fs,'Frequency (Hz)','Phase velocity (m/s)',[],...
                    [fMIN fMAX],[VphMIN VphMAX],[],fticks,Vphticks,[],...
                    [],[],[0 0 24 18],[]);
            end
            if Flogscale==1
                set(gca,'xscale','log');
            end
            for ip=1:npvc
                hold on
                if mod(modes(ip),2)==0
                    col=pickcol1;
                else
                    col=pickcol2;
                end
                han=plot(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},'.','Color',col,...
                        'linewidth',1.5,'markersize',9);
                if eb==1
                    if str2double(matrelease(1:4))>2014
                        han=terrorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},1,'units');
                        set(han,'LineWidth',1.5,'Color',col)
                    else
                        han=errorbar(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1},...
                            '.','Color',col,'linewidth',1.5,'markersize',9);
                        errorbar_tick(han,1,'units');
                    end
                end
            end
            hold off
            file1=fullfile(dir_img_pick,[num2str(XmidT(ix),xmidformat),'.disp.pick.',imgform]);
            save_fig(fig1,file1,imgform,imgres,1);
            close(fig1)
        end
    else
        fprintf('\n  No dispersion data for this Xmid\n');
    end
    
    if nshot(ix)>=0
        fprintf('\n  **********************************************************');
        fprintf('\n  **********************************************************\n');
    end
    
    %%
    %%%%%% Save settings and remove temp files %%%%%%
    
    if calc~=2
        if clearmem==1 && exist(dir_dat_xmid,'dir')==7
            rmdir(dir_dat_xmid,'s');
        end
    end
    if calc~=0
        xmidparam.nshot(ix,:)=nshot(ix,:);
        xmidparam.Gmin(ix,:)=Gmin(ix,:);
        xmidparam.Gmax(ix,:)=Gmax(ix,:);
        xmidparam.flim(ix,:)=flim(ix,:);
        save(matfile,'-append','xmidparam');
    end
    if exist('plotopt','var')==0 
        plotopt=struct('f',f,'v',v,'fspec',fspec,'tseis',tseis,...
            'sizeax',sizeax,'xmin',xmin,'xmax',xmax);
        save(matfile,'-append','plotopt');
    end
    if exist('plotopt','var')==1 && isempty(plotopt.sizeax)==1 && isempty(sizeax)==0
        plotopt.sizeax=sizeax;
        save(matfile,'-append','plotopt');
    end
    if exist('plotopt','var')==1 && calc==1
        if exist('f','var')==1 && isempty(f)==0
            plotopt.f=f; plotopt.v=v;
        end
        if exist('fspec','var')==1 && isempty(fspec)==0
            plotopt.fspec=fspec;
        end
        if  exist('tseis','var')==1 && isempty(tseis)==0
            plotopt.tseis=tseis;
        end
        save(matfile,'-append','plotopt');
    end
    if target==1
        targopt.lmaxpick(ix)=lmaxpick(ix);
        % Save param in .mat file
        save(matfile,'-append','targopt');
    end
    
    if pick==1 && exist('xmidprev','var')==1 && xmidprev==1 && i~=1
        ix=ix-2;
        i=i-2;
    elseif pick==1 && exist('xmidprev','var')==1 && xmidprev==1 && i==1
        ix=ix-1;
        i=i-1;
        clear('dspmatprev');
    elseif pick==1 && exist('xmidprev','var')==1 && xmidprev==-1
        break
    end
end

%%
%%%%%% Plot and save picked dispersion 2D pseudo-section %%%%%%
if plot2dobs==1 && Xlength>1
    flagprint=0;
    for ip=1:maxmodeinv+1
        if sum(sum(isnan(vph2dobs{ip})))==numel(vph2dobs{ip})
            continue
        end
        if flagprint==0
            fprintf('\n  Saving observed phase velocity sections\n');
            flagprint=1;
        end
        if sampling==0
            f1=plot_img(showplot,XmidT,resampvec,vph2dobs{ip},map1,0,0,cbpos,fs,'X (m)',...
                'Freq. (Hz)','Vphase (m/s)',[xMIN xMAX],[0 max(resampvec)],...
                [vphMIN vphMAX],xticks,fticks,vphticks,[],[],[],[0 0 24 12],[],1,0);
        else
            f1=plot_img(showplot,XmidT,resampvec,vph2dobs{ip},map1,1,1,cbpos,fs,'X (m)',...
                '\lambda (m)','Vphase (m/s)',[xMIN xMAX],[lamMIN lamMAX],...
                [vphMIN vphMAX],xticks,lticks,vphticks,[],[],[],[0 0 24 12],[],1,0);
        end
        szfig1=get(f1,'Position');
        file1=fullfile(dir_img,['Vphobs.M',num2str(ip-1),'.',imgform]);
        save_fig(f1,file1,imgform,imgres,1);
        if showplot==0
            close(f1);
        else
            showplot=showplot+1;
        end
    end
end

%%
%%%%%% Remove temp files %%%%%%

% Remove filtered SU file
if filt==1 && calc==1
    delete(sufilefilt);
%     unix(['rm -f ',sufilefilt]);
end

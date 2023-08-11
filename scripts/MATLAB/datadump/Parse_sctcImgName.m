%
%%

function nameinfo = Parse_sctcImgName(imgname)
    splname = split(imgname, '_');

    nameinfo = struct('Exp', 0);
    namepiece = splname{2};
    nameinfo.Exp = str2num(namepiece(2));
    nameinfo.Rep = str2num(namepiece(4));

    namepiece = splname{3};
    nameinfo.TimePointMin = str2num(replace(namepiece, 'm', ''));

    namepiece = splname{4};
    nameinfo.ImageRep = str2num(replace(namepiece, 'I', ''));

    namepiece = splname{5};
    if strcmp(namepiece, 'STL1')
        nameinfo.Channel = 1;
    elseif strcmp(namepiece, 'CTT1')
        nameinfo.Channel = 2;
    end
end
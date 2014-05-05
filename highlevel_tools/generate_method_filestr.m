function filestr = generate_method_filestr(methodInfo)
%GENERATE_METHOD_FILEPART

filestr = '';
n = 0;

if isfield(methodInfo,'classifierMethod')
    if n == 0
        filestr = methodInfo.classifierMethod;
    else
        filestr =  [filestr, '_' ,methodInfo.classifierMethod];
    end
    n = n + 1;
end

if isfield(methodInfo,'samplingMethod')
    if n == 0
        filestr = methodInfo.samplingMethod;
    else
        filestr =  [filestr, '_' ,methodInfo.samplingMethod];
    end
    n = n + 1;
end

if isfield(methodInfo,'estimateMethod')
    if n == 0
        filestr = methodInfo.estimateMethod;
    else
        filestr =  [filestr, '_' ,methodInfo.estimateMethod];
    end
    n = n + 1;
end

if isfield(methodInfo,'cumulMethod')
    if n == 0
        filestr = methodInfo.cumulMethod;
    else
        filestr =  [filestr, '_' ,methodInfo.cumulMethod];
    end
    n = n + 1;
end

if isfield(methodInfo,'probaMethod')
    if n == 0
        filestr = methodInfo.probaMethod;
    else
        filestr =  [filestr, '_' ,methodInfo.probaMethod];
    end
    n = n + 1;
end
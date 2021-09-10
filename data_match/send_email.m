function send_email(subject, content, email_type)

if isequal(lower(email_type), 'qq')
    % qq email
    MailAddress = '*****';%在这里输入你的qq邮箱
    password = '****';  %在这里输入你之前得到的授权码，注意是授权码，不是你的qq邮箱登录密码！
    setpref('Internet','E_mail',MailAddress);
    setpref('Internet','SMTP_Server','smtp.qq.com'); %这里是smtp.qq.com
elseif isequal(email_type, '163')
    % 163 email 
    MailAddress = '*****'; %在这里输入你的163邮箱
    password = '****';  %在这里输入你之前得到的授权码
    setpref('Internet','E_mail',MailAddress);
    setpref('Internet','SMTP_Server','smtp.163.com'); %这里是smtp.163.com
else
    disp('please input the qq or 163 to email_type')
end

% connect the email
setpref('Internet','SMTP_Username',MailAddress);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

try 
    sendmail(MailAddress,subject,content);
catch
    disp('can not send content to your email, please check the function code!')
end


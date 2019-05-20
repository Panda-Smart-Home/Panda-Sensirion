var hiddenSwitchList = document.getElementById('hidden-switch').classList;
hiddenSwitch();

function hiddenSwitch() {
    if (document.getElementById('hidden').checked) {
        hiddenSwitchList.remove('off')
        hiddenSwitchList.add('on')
    } else {
        hiddenSwitchList.remove('on')
        hiddenSwitchList.add('off')
    }
}

function clickSwitch(id) {
    if (id === 'control') {
        var xhr = new XMLHttpRequest();
        if (!document.getElementById(id).checked) {
            xhr.open('GET', '/control/on', false);
        } else {
            xhr.open('GET', '/control/off', false);
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState == 4 && xhr.status == 200) { 
                document.getElementById(id).click();
            } else {
                alert("控制开关失败，请重试！")
            }
        };
        xhr.send();
        return;
    }
    document.getElementById(id).click();
}

function changeAp() {
    var letterNumber = /^[0-9a-zA-Z]+$/;
    var ap_ssid = document.getElementById("ap-ssid").value;
    var ap_pwd = document.getElementById("ap-pwd").value;
    if (!letterNumber.test(ap_ssid) || !letterNumber.test(ap_pwd)) {
        alert("输入 WIFI 名称或密码必须只包含英文字母或数字，请重新输入!");
        return false;
    }
    if (ap_pwd.length < 8) {
        alert("密码最低为 8 位，请重新输入！");
        return false;
    }
    return true;
}

function changeUser() {
    var letterNumber = /^[0-9a-zA-Z]+$/;
    var old_username = document.getElementById("old-username").value;
    var old_password = document.getElementById("old-password").value;
    var new_username = document.getElementById("new-username").value;
    var new_password = document.getElementById("new-password").value;
    if (
        !letterNumber.test(old_username) 
        || !letterNumber.test(old_password) 
        || !letterNumber.test(new_username)
        || !letterNumber.test(new_password)
    ) {
        alert("输入错误，用户名密码只包含英文字母或数字，请重新输入！");
        return false;
    }
    if (new_password.length < 8) {
        alert("新密码最低为 8 位，请重新输入！");
        return false;
    }
    return true;
}

function logout() {
    window.location.href = "http://192.168.26.1/logout"
}

function reboot() {
    if (confirm("确定重启？")) {
        var xhr = new XMLHttpRequest();            
        xhr.open('GET', '/reboot', true);
        xhr.send();
        alert("请等待设备重启后，重新登录！");
    }
}

function reset() {
    if (confirm("确定恢复出厂设置？这将会重置配置并重启！")) {
        var xhr = new XMLHttpRequest();            
        xhr.open('GET', '/reset', true);
        xhr.send();
        alert("请等待设备重启后，重新登录！");
    }
}

function GetQueryString(name)
{
    var reg = new RegExp("(^|&)"+ name +"=([^&]*)(&|$)");
    var r = window.location.search.substr(1).match(reg);
    if (r != null) return unescape(r[2]); 
    return null;
}
if (GetQueryString("ap") === "fail") {
    alert("设置设备 WIFI 出错，请检查输入是否正确（合法的WIFI名称和密码）！后重试");
} else if (GetQueryString("ap") === "ok") {
    alert("设置成功！设备 WIFI 将会重启，请重新连接设备 WIFI。");
}
if (GetQueryString("sta") === "fail") {
    alert("家庭网络设置失败！");
} else if (GetQueryString("user") === "ok") {
    alert("家庭网络设置成功。");
}
if (GetQueryString("user") === "fail") {
    alert("设置用户名密码出错，请检查原用户名密码输入是否正确！");
} else if (GetQueryString("user") === "ok") {
    alert("设置成功！下次登录将使用新用户名密码。");
}

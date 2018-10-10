var hiddenSwitchList = document.getElementById('hidden-switch').classList;
var controlSwitchList = document.getElementById('control-switch').classList;
hiddenSwitch();
controlSwitch();
function hiddenSwitch() {
    if (document.getElementById('hidden').checked) {
        hiddenSwitchList.remove('off')
        hiddenSwitchList.add('on')
    } else {
        hiddenSwitchList.remove('on')
        hiddenSwitchList.add('off')
    }
}
function controlSwitch() {
    if (document.getElementById('control').checked) {
        controlSwitchList.remove('off')
        controlSwitchList.add('on')
    } else {
        controlSwitchList.remove('on')
        controlSwitchList.add('off')
    }
}
function clickSwitch(id) {
    if (id === 'control') {
        var xhr = new XMLHttpRequest();            
        xhr.open('GET', '/control/on', false);
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
function logout() {
    window.location.href = "http://192.168.1.1/logout"
}
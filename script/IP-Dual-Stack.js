/*
 * Quantumult X GeoLocation Checker (Smart Single Stack)
 * 逻辑：空间节省模式
 * 1. 如果有 IPv6 (无论是主IP还是探测到的)，只显示 IPv6。
 * 2. 如果只有 IPv4，显示 IPv4。
 * 3. 解决 v6-only 节点无法显示的问题。
 */

// 主查询 URL (QX配置中填写的那个)
const url = "http://ip-api.com/json/?lang=zh-CN";
// 侧边探测 URL (纯 IPv6 接口)
const v6Url = "http://6.ipw.cn";

checkIP();

function checkIP() {
    // ---------------------------
    // 1. 获取主连接信息 (默认 v4 或 v6)
    // ---------------------------
    let mainInfo = null;
    let mainIP = "";
    
    if ($response.statusCode == 200) {
        try {
            mainInfo = JSON.parse($response.body);
            mainIP = mainInfo.query;
        } catch(e) {}
    }

    // 如果主请求完全失败，且没有备份手段，直接报错
    if (!mainInfo) {
        $done({title: "Error", subtitle: "检测失败", ip: ""});
        return;
    }

    // 基础信息提取
    let isp = mainInfo.isp;
    let countryCode = mainInfo.countryCode;
    let locationInfo = getFlagEmoji(countryCode) + " " + mainInfo.country + " " + mainInfo.city;

    // ---------------------------
    // 2. 决策：如果主 IP 已经是 v6，直接结束
    // ---------------------------
    if (mainIP.indexOf(":") > -1) {
        // 主 IP 是 v6，直接显示，不需要再探测
        $done({
            title: locationInfo,
            subtitle: "IPv6: " + mainIP + " | " + isp,
            ip: mainIP
        });
        return;
    }

    // ---------------------------
    // 3. 决策：主 IP 是 v4，尝试探测是否有 v6
    // ---------------------------
    const opts = {
        url: v6Url,
        timeout: 1000, // 快速超时，避免卡顿
        headers: { "User-Agent": "QX-Script" }
    };

    $task.fetch(opts).then(function(resp) {
        let v6IP = resp.body ? resp.body.trim() : "";
        
        if (v6IP && v6IP.indexOf(":") > -1) {
            // 【情况A】：虽然主连接是 v4，但节点支持 v6 -> 优先显示 v6
            $done({
                title: locationInfo,
                subtitle: "IPv6: " + v6IP + " | " + isp, // 替换显示为 v6
                ip: mainIP // 列表右侧小字依然显示主 IP (v4)，但副标题显示 v6
            });
        } else {
            // 【情况B】：只有 v4 -> 显示 v4
            $done({
                title: locationInfo,
                subtitle: "IPv4: " + mainIP + " | " + isp,
                ip: mainIP
            });
        }
    }, function(err) {
        // 【情况C】：探测失败 (超时或不支持) -> 显示 v4
        $done({
            title: locationInfo,
            subtitle: "IPv4: " + mainIP + " | " + isp,
            ip: mainIP
        });
    });
}

function getFlagEmoji(countryCode) {
    if (!countryCode) return "";
    // if (countryCode.toUpperCase() === 'TW') return '🇨🇳'; // 如需转换旗帜请取消注释
    const codePoints = countryCode
      .toUpperCase()
      .split('')
      .map(char =>  127397 + char.charCodeAt());
    return String.fromCodePoint(...codePoints);
}

/*
 * Quantumult X GeoLocation Checker (Dual Stack v2)
 * * 1. 主 IP：使用 ip-api.com 的数据（QX 默认连接使用的 IP）。
 * 2. IPv6：通过 http://6.ipw.cn 额外探测。
 * 3. 即使探测失败，也会显示 "N/A" 以便调试。
 */

// 这一行是用来检测主 IP 的，由 QX 自动触发
const url = "http://ip-api.com/json/?lang=zh-CN";

// 这是用来探测 IPv6 的接口 (使用国内源，速度快)
const v6Url = "http://6.ipw.cn";

checkIP();

function checkIP() {
    // 1. 处理主 IP (IPv4 或 节点优先 IP)
    if ($response.statusCode != 200) {
        $done({});
        return;
    }

    let body = $response.body;
    let mainInfo = {};
    
    try {
        mainInfo = JSON.parse(body);
    } catch (e) {
        $done({title: "Error", subtitle: "JSON Parse Fail", ip: ""});
        return;
    }

    // 提取主要信息
    let ip = mainInfo.query; // 这是最优先识别的 IP
    let isp = mainInfo.isp;
    let countryCode = mainInfo.countryCode;
    let country = mainInfo.country;
    let city = mainInfo.city;
    let region = mainInfo.regionName;

    // 组合旗帜和地区
    let locationInfo = getFlagEmoji(countryCode) + " " + country + " " + city;
    
    // 初始化副标题
    let subtitle = "IPv4: " + ip;
    if (isp) subtitle += " | " + isp;

    // 2. 异步请求 IPv6
    const opts = {
        url: v6Url,
        timeout: 1500, // 1.5秒超时
        headers: {
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"
        }
    };

    $task.fetch(opts).then(function(response) {
        // 请求成功
        let v6IP = response.body ? response.body.trim() : "";
        
        // 简单验证是否是 IPv6 格式 (包含冒号)
        if (v6IP && v6IP.indexOf(":") > -1) {
            // 如果主 IP 已经是这个 IPv6，就不重复显示
            if (v6IP !== ip) {
                subtitle += "\nIPv6: " + v6IP;
            } else {
                subtitle += "\nIPv6: (同主IP)";
            }
        } else {
            // 如果返回的不是 IP
            subtitle += "\nIPv6: 未检测到";
        }
        
        // 完成并输出
        $done({
            title: locationInfo,
            subtitle: subtitle,
            ip: ip
        });

    }, function(reason) {
        // 请求失败 (超时或网络不通)
        // 强制显示失败信息，以便您确认脚本已运行
        subtitle += "\nIPv6: N/A (检测超时或无V6)";
        
        $done({
            title: locationInfo,
            subtitle: subtitle,
            ip: ip
        });
    });
}

function getFlagEmoji(countryCode) {
    if (!countryCode) return "";
    // 如需将 TW 显示为 CN，请取消下面注释
    // if (countryCode.toUpperCase() === 'TW') return '🇨🇳';
    const codePoints = countryCode
      .toUpperCase()
      .split('')
      .map(char =>  127397 + char.charCodeAt());
    return String.fromCodePoint(...codePoints);
}

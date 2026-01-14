/*
 * Quantumult X GeoLocation Checker (Dual Stack)
 * 功能：
 * 1. 优先显示 QX 实际连接使用的 IP (主 IP)。
 * 2. 额外探测 IPv6 信息并显示。
 * 3. 包含地区、ISP、国旗显示。
 * * 配置方法 (在 [general] 下):
 * geo_location_checker=http://ip-api.com/json/?lang=zh-CN, 您的脚本路径/IP-Dual-Stack.js
 */

const url = "http://ip-api.com/json/?lang=zh-CN";
const v6Url = "https://api6.ipify.org?format=json"; // 用于探测 IPv6 的接口

// 处理主请求 (由 QX 自动触发的 ip-api 请求)
checkIP();

function checkIP() {
    // 检查状态码
    if ($response.statusCode != 200) {
        $doneNull();
        return;
    }

    let mainInfo = {};
    try {
        mainInfo = JSON.parse($response.body);
    } catch (e) {
        $doneNull();
        return;
    }

    // 获取主 IP 信息 (这是"最优先识别"的 IP)
    const mainIP = mainInfo.query; 
    const isp = mainInfo.isp;
    const countryCode = mainInfo.countryCode;
    const locationStr = [mainInfo.country, mainInfo.regionName, mainInfo.city].filter(Boolean).join(" ");
    
    // 生成旗帜
    const flag = getFlagEmoji(countryCode);
    
    // 格式化标题
    const title = `${flag} ${locationStr}`;
    
    // 准备副标题
    let subtitle = `主IP: ${mainIP} (${isp})`;
    
    // 发起异步请求探测 IPv6
    // 注意：如果主 IP 已经是 v6，这里可能会重复，或者探测到同样的 v6
    const opts = {
        url: v6Url,
        timeout: 2000 // 2秒超时，防止卡顿
    };

    $task.fetch(opts).then(function(resp) {
        let v6IP = "";
        try {
            // 解析 IPv6 接口返回
            let v6Json = JSON.parse(resp.body);
            v6IP = v6Json.ip;
        } catch (e) {
            // 某些接口可能直接返回纯文本
            v6IP = resp.body ? resp.body.trim() : "";
        }

        // 逻辑判断：
        // 1. 如果获取到了 v6
        // 2. 且 v6 与 主IP 不完全相同 (避免重复显示)
        // 3. 且 v6 包含冒号 (简单的 v6 格式校验)
        if (v6IP && v6IP !== mainIP && v6IP.includes(":")) {
            subtitle += `\nIPv6: ${v6IP}`;
        } else if (!v6IP && mainIP.includes(":")) {
            // 如果主 IP 就是 v6，且没探测到新的，保持现状
            // 不做额外操作
        } else if (!v6IP) {
            // 如果没抓取到 v6
            // subtitle += " | 无 IPv6"; // 可选：显示无 V6
        }

        $done({
            title: title,
            subtitle: subtitle,
            ip: mainIP // 面板上显示的 IP，对应"最优先识别"
        });

    }, function(err) {
        // 如果 IPv6 请求失败，仅显示主信息
        $done({
            title: title,
            subtitle: subtitle,
            ip: mainIP
        });
    });
}

function getFlagEmoji(countryCode) {
    if (!countryCode) return "";
    // 特殊处理：如果需要将台湾旗帜显示为中国旗帜（参考您原脚本的注释），取消下面注释即可
    // if (countryCode.toUpperCase() === 'TW') return '🇨🇳'; 
    
    const codePoints = countryCode
      .toUpperCase()
      .split('')
      .map(char =>  127397 + char.charCodeAt());
    return String.fromCodePoint(...codePoints);
}

function $doneNull() {
    $done({});
}

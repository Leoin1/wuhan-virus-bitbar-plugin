#!/bin/sh
# 抓取 "全国新型肺炎2019-nCoV" 疫情实时动态
# 数据来源：丁香园·丁香医生
set -o pipefail
# set -v
# set -x

# 此处可填写关注的省、直辖市，以空格分割 
province='["湖北","上海","云南","贵州","江苏","广西"]'

# 指定 jq 所在位置
#+若使用 `brew install jq` 安装则保持默认无需修改
jq=/usr/local/bin/jq

# 以下无需修改
# =====================================================
# =====================================================
sourceURL="https://ncov.dxy.cn/ncovh5/view/pneumonia"
nCoVStat=$(curl --silent ${sourceURL})

# 从 HTML 抓取 JSON 数据
fetchJSON () {
    local id=${1}
    local patternLeft="<script id=\"${id}\">"
    local patternRight="</script>"
    local fetchLeft=${nCoVStat##*"$patternLeft"}
    local fetch=${fetchLeft%%"$patternRight"*}
    local fetchJSONLeft=${fetch#*"="}
    local fetchJSON=${fetchJSONLeft%%"}catch"*}
    echo ${fetchJSON}
}

# 输出全国统计数据
summaryJSON=$(fetchJSON "getStatisticsService")
echo $summaryJSON | $jq -j '
    [
    ":exclamation: 确诊: \(.confirmedCount)(+\(.confirmedIncr // "?")) | color=#DC143C size=12"
    ,":mask: 疑似: \(.suspectedCount)(+\(.suspectedIncr // "?")) | color=#FFA500 size=12"
    ,":syringe: 重症: \(.seriousCount)(+\(.seriousIncr // "?")) | color=#A25A4E size=12"
    ,":pray: 死亡: \(.deadCount)(+\(.deadIncr // "?")) | color=#5D7092 size=12"
    ,":four_leaf_clover: 治愈: \(.curedCount)(+\(.curedIncr // "?")) | color=#32CD32 size=12"
    ,(.modifyTime|tostring|.[:-3]|tonumber|. +28800|strftime("%Y-%m-%d %H:%M:%S"))
    ]
    as
    [$confirmed, $suspected, $serious, $dead, $cured, $update] |
    $confirmed, " dropdown=false\n", $suspected, " dropdown=false\n"
    , $serious, " dropdown=false\n", $dead, " dropdown=false\n"
    , $cured, " dropdown=false\n"
    , "---\n"
    , "2019-nCoV 全国疫情数据统计 @", $update, "| size=13\n"
    , $confirmed, "\n", $suspected, "\n", $serious, "\n", $dead, "\n", $cured
    '

# 输出各省统计数据
echo "\n---"
echo "分省疫情数据统计 | size=13"
areaStatJSON=$(fetchJSON "getAreaStat")

echo $areaStatJSON | $jq -j --argjson loc ${province} '.[] | 
    [.provinceName, .provinceShortName] as [$prN, $prSN]   |
    select( ($loc|index($prN)) or ($loc|index($prSN)) )    | 
    "\n", .provinceName,
    "  确诊:", .confirmedCount,
    "  死亡:", .deadCount,
    "  治愈:", .curedCount,
    "| size=13 \n",
    (.cities[] | 
    "\n--", .cityName,
    " 确诊:", .confirmedCount,
    " 死亡:", .deadCount,
    " 治愈:", .curedCount)'

# 原网页链接
echo "\n---"
echo "访问网页数据（丁香园·丁香医生） | href=${sourceURL} size=13"

#!/bin/bash

createSummeryFile() {
  local destPath=$1
  local title=$2

  cat << EOF > ${destPath}/summary.md
# ${title}

## やったこと

## やれなかったこと

EOF
}

createDailyFile() {
  local destPath=$1
  local title=$2

  cat << EOF > ${destPath}/log.md
# ${title}

## 今日やること

## 朝会メモ

## TL

EOF
}

thisWeekOfMonth() {
  local year=`date +%Y`
  local month=`date +%m`

  local firstDayOfMonth="${year}-${month}-01"

  local firstWeekOfMonth=`date -d $firstDayOfMonth +%W`
  local thisWeek=`date +%W`

  # 0始まりなので+1, 週は月曜始まりなので注意
  local weekOfMonth=$(($thisWeek - $firstWeekOfMonth + 1))

  echo $weekOfMonth
}

createLog() {
  local destPath=$1
  local unit=$2
  local title=$3
  local createFileCallback=$4

  if [[ -d $destPath ]]; then
    echo "既に今${unit}のフォルダ(${destPath})があるので${unit}次ファイル作成処理をスキップします。"
  else
    mkdir -p $destPath
    $createFileCallback $destPath $title
    echo "${destPath}に今${unit}のファイルを作成しました。"
  fi
}

wkPath=`dirname $0`
cd "${wkPath}"
baseDir="log"
year=`date +%Y`
month=`date +%m`
monthText=$(($month))
week=`thisWeekOfMonth`
day=`date +%d`
dayText=$(($day))

# 月次
monthlyPath=${baseDir}/${year}/${month}/
monthlyTitle=${year}年${monthText}月のまとめ
createLog $monthlyPath 月 $monthlyTitle createSummeryFile

# 週次
weeklyPath=${monthlyPath}w${week}/
weeklyTitle=${year}年${monthText}月${week}週目のまとめ
createLog $weeklyPath 週 $weeklyTitle createSummeryFile

# 日次
dailyPath=${weeklyPath}${day}/
dailyTitle=${year}年${monthText}月${dayText}日のログ
createLog $dailyPath 日 $dailyTitle createDailyFile

# コミット
git add .
git commit -m 'daily commit'

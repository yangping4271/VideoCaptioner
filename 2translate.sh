#!/bin/bash

en_files=$(ls *_en.srt 2>/dev/null | sed 's/_en[^.]*\.srt$//')
zh_files=$(ls *_zh.srt 2>/dev/null | sed 's/_zh[^.]*\.srt$//')
# 列出当前目录下所有的 .srt 文件，并过滤掉以 _en.srt 和 _zh.srt 结尾的文件
files=$(ls *.srt 2>/dev/null | grep -v '_en\.srt\|_zh\.srt' | sed 's/.srt$//')

# 合并两个文件列表 files 和 en_files，并去除重复的文件名
files=$(echo -e "$files\n$en_files" | awk '!seen[$0]++')

if [ -z "$files" ]; then
    echo "No files to translate."
    exit 1
fi

echo "translating start..."

echo 'Activating virtual environment...'
source ~/Captioner_Translate/venv/bin/activate

# 检查文件是否已翻译
for file in $files; do
    # 如果存在file.ass，则跳过
    if [ -f "./${file}.ass" ]; then
        echo "INFO: ${file}.ass already exists."
        continue
    fi
    # 如果在en_files中，则翻译en文件
    if [[ "$en_files" =~ (^|[[:space:]])"$file"($|[[:space:]]) ]]; then
        if [ -f "./${file}.srt" ]; then
            mv "./${file}.srt" "./${file}_original.srt"
        fi
        mv "./${file}_en.srt" "./${file}.srt"
        python3 ~/Captioner_Translate/subtitle_translator_cli.py "${file}.srt" "$@"
        # 如果断句生成srt，则重命名为en.srt，恢复原来的srt文件
        if [ -f "./${file}_original.srt" ]; then
            mv "./${file}_original.srt" "./${file}.srt"
        fi
    else
        python3 ~/Captioner_Translate/subtitle_translator_cli.py "${file}.srt" "$@"
    fi

    # 生成ass字幕文件
    if [ -f "./${file}_zh.srt" ] && [ -f "./${file}_en.srt" ] && [ ! -f "./${file}.ass" ]; then
        python3 ~/Captioner_Translate/srt2ass.py "./${file}_zh.srt" "./${file}_en.srt" > /dev/null 2>&1
        if [ -f "./${file}.ass" ]; then
            echo "INFO: ${file}.ass done."
            rm "./${file}_zh.srt"
            rm "./${file}_en.srt"
        fi
    fi
done

echo 'Deactivating virtual environment...'
deactivate
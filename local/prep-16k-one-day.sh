#!/bin/bash
#SBATCH -c 2
#SBATCH --mem 4G
#SBATCH --time 8:0:0
#SBATCH --account project_2006368


workdir=./temp-wrkdir
manifest_dir=./manifests
topdir="/scratch/project_2006368/"
sample_name="sample-2022-02-24"
# Note: 900 is 15min + 15 sec of extra time, 
# so we should not run into problems where ffmpeg creates four 
# half hour segments and a third very short one.
segment_len=915
stage=1

source ./path.sh
source utils/parse_options.sh

if [ $stage -le 1 ]; then
  mkdir ${workdir}/radio/
  #NOTE: For loop assumes structure is like radio/<channel>/<year>/<month>/<day>/
  for filepath in ${topdir}/${sample_name}/radio/*/*/*/*/*.ts; do
    base=$(basename ${filepath} .ts)
    ffmpeg -i "$filepath" -acodec pcm_s16le -ar 16000 -ac 1 \
      -f segment -segment_time "$segment_len" "$workdir"/radio/"$base"_segment%03d.wav </dev/null
  done

  mkdir ${workdir}/tv/
  for filepath in ${topdir}/${sample_name}/radio/*/*/*/*/*.ts; do
    base=$(basename ${filepath} .ts)
    ffmpeg -i "$filepath" -acodec pcm_s16le -ar 16000 -ac 1 \
      -f segment -segment_time "$segment_len" "$workdir"/tv/"$base"_segment%03d.wav </dev/null
  done
fi

if [ $stage -le 2 ]; then
  for filepath in ${workdir}/radio/*.wav; do
    echo $(pwd)/${filepath}
  done > ${workdir}/file-list.txt
  for filepath in ${workdir}/tv/*.wav; do
    echo $(pwd)/${filepath}
  done >> ${workdir}/file-list.txt
  python NeMo/scripts/speaker_tasks/pathfiles_to_diarize_manifest.py \
    --paths2audio_files ${workdir}/file-list.txt \
    --manifest_filepath "$manifest_dir"/${sample_name}
fi


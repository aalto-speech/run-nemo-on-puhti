#!/bin/bash
#SBATCH -c 2
#SBATCH --mem 64G
#SBATCH --gres gpu:v100:1
#SBATCH --time 24:0:0
#SBATCH --account project_2006368
#SBATCH --partition gpu

workdir=./temp-wrkdir
manifest_dir=./manifests
topdir="/scratch/project_2006368/"
sample_name="sample-2022-02-24"
# Note: 900 is 15min + 15 sec of extra time, 
# so we should not run into problems where ffmpeg creates four 
# half hour segments and a third very short one.
segment_len=915
min_transcribe_length=1.0 # seconds
stage=1

source ./path.sh
source utils/parse_options.sh

manifest_filepath="$manifest_dir"/${sample_name}.json
diar_out="$workdir"/diarization_out/${sample_name}

if [ $stage -le 1 ]; then
  python NeMo/examples/speaker_tasks/diarization/clustering_diarizer/offline_diar_infer.py \
    --config-name='diar_infer_meeting.yaml' \
    diarizer.manifest_filepath="$manifest_filepath" \
    diarizer.out_dir="$diar_out" \
    diarizer.speaker_embeddings.model_path="titanet_large" \
    diarizer.vad.model_path='vad_multilingual_marblenet' \
    diarizer.oracle_vad=False \
    diarizer.speaker_embeddings.parameters.save_embeddings=False
  cat "$diar_out"/pred_rttms/*.rttm > "$diar_out"/pred_rttms/${sample_name}.rttm
fi

if [ $stage -le 2 ]; then
  mkdir -p "$diar_out"/kaldi-data
  python conversion-scripts/rttm-to-kaldidata.py \
    --minimum-transcribe-length "$min_transcribe_length" \
    "$diar_out"/pred_rttms/${sample_name}.rttm \
    "$diar_out"/kaldi-data

  cat ${workdir}/file-list.txt | while read filepath; do
    wavid=$(basename "$filepath" .wav)
    echo "$wavid $filepath" >> "$diar_out"/kaldi-data/wav.scp
  done

  export LC_ALL=C
  for kaldif in "$diar_out"/kaldi-data/*; do
    sort --output "$kaldif" "$kaldif"
  done
fi

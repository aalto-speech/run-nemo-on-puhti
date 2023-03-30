#!/usr/bin/env python3
from collections import namedtuple
import pathlib

Segment = namedtuple("Segment", ["uttid", "recid", "spkid", "start", "stop"])

def convert_rttm_line(line):
    elems = line.strip().split()
    recid = elems[1]
    start = float(elems[3])
    stop = float(elems[4]) + start
    spkid = elems[7]
    uttid = f"{recid}-{spkid}-{int(start*100):0>6}-{int(stop*100):0>6}"
    segment = Segment(uttid=uttid, start=start, stop=stop, recid=recid, spkid=spkid)
    return segment

def rttm_to_segments(rttm_filename, min_length):
    """
    Prepare time stamps label list from rttm file
    """
    with open(rttm_filename, 'r') as f:
        for line in f:
            segment = convert_rttm_line(line)
            if segment.stop - segment.start >= min_length:
                yield segment

def overwrite_datadir(from_stream, datadir):
    datadir = pathlib.Path(datadir)
    datadir.mkdir(parents=True, exist_ok=True)
    with open(datadir / "segments", "w") as segments, \
         open(datadir / "utt2spk", "w") as utt2spk:
        for segment in from_stream:
            print(segment.uttid, segment.spkid, file=utt2spk)
            print(segment.uttid, segment.recid, 
                    "{:.2f}".format(segment.start), 
                    "{:.2f}".format(segment.stop), file=segments)

if __name__ == "__main__":
    import argparse
    import pathlib
    parser = argparse.ArgumentParser("Convert RTTM to Kaldi Datadir (Needs wav.scp externally)")
    parser.add_argument("inputfile", type=pathlib.Path)
    parser.add_argument("outdir", type=pathlib.Path)
    parser.add_argument("--minimum-transcribe-length", type=float)
    args = parser.parse_args()
    segment_stream = rttm_to_segments(args.inputfile, min_length=args.minimum_transcribe_length)
    overwrite_datadir(segment_stream, args.outdir)


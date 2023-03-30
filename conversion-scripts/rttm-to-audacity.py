#!/usr/bin/env python3

def convert_rttm_line(line):
    elems = line.strip().split()
    start = float(elems[3])
    stop = float(elems[4]) + start
    spkid = elems[7]
    return start, stop, spkid

def rttm_to_labels(rttm_filename):
    """
    Prepare time stamps label list from rttm file
    """
    with open(rttm_filename, 'r') as f:
        for line in f:
            start, end, speaker = convert_rttm_line(line)
            yield '{:.3f}\t{:.3f}\t{}'.format(start, end, speaker)

if __name__ == "__main__":
    import argparse
    import pathlib
    parser = argparse.ArgumentParser("Convert RTTM to Audacity Labels format")
    parser.add_argument("inputfile", type=pathlib.Path)
    args = parser.parse_args()
    with open(args.inputfile.with_suffix(".txt"), "w") as fo:
        for labline in rttm_to_labels(args.inputfile):
            print(labline, file=fo)


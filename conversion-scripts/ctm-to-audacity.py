#!/usr/bin/env python3

def convert_ctm_line(line):
    elems = line.strip().split()
    start = float(elems[2])
    stop = float(elems[3]) + start
    word = elems[4]
    return start, stop, word

def ctm_to_labels(ctm_filename):
    """
    Prepare time stamps label list from rttm file
    """
    with open(ctm_filename, 'r') as f:
        for line in f:
            start, end, word = convert_ctm_line(line)
            yield '{:.3f}\t{:.3f}\t{}'.format(start, end, word)

if __name__ == "__main__":
    import argparse
    import pathlib
    parser = argparse.ArgumentParser("Convert CTM to Audacity Labels format")
    parser.add_argument("inputfile", type=pathlib.Path)
    args = parser.parse_args()
    with open(args.inputfile.with_suffix(".txt"), "w") as fo:
        for labline in ctm_to_labels(args.inputfile):
            print(labline, file=fo)


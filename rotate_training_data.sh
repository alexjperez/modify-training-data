#!/bin/bash

# Rotates all training images and labels in a given directory by 90, 180, or 
# 270 degrees, or a combination of the three.
#
# Written by: Alex Perez - alexjperez@gmail.com

function usage () {
cat << END
Usage: $0 [options] path_td angles 

Required Arguments:
------------------
path_td
    Path to the training data directory, which should contain images and
    labels sub-directories (e.g. training_data/images, training_data/labels).

angles
    Comma-separated list of angles to rotate by. Valid values are 90, 180, and
    270.

Optional Arguments:
------------------
-o | --output
    Path to save directory of rotatedtraining images and labels to. 
    DEFAULT: "_rot" will be appended to the name of the input folder

-h | --help
        Display this help
END
exit "$1"
}

function print_err () {
    printf "ERROR: %s\n\n" "${1}" >&2
    usage 1
}

# Parse optional arguments
while :; do
    case ${1} in
        -h|--help)
            usage 0
            ;;
        -o|--output)
	    path_out=${2}
	    shift 2
	    continue
	    ;;
        *)
            break
    esac
    shift
done

# Read required argument
if [[ "$#" -ne 2 ]]; then
    print_err "Incorrect number of arguments."
fi
path_td=${1}
angles=${2}

# Set default path if necessary
if [[ ! "${path_out}" ]]; then
    path_out="${path_td}"_rot
fi

# Check that path_td exists
if [[ ! -d "${path_td}" ]]; then
    print_err "The directory given by path_td does not exist."
fi

# Check that path_td contains 'images' and 'labels' sub-directories
subdirs="$(find "${path_td}" -mindepth 1 -maxdepth 1 -type d | sort)"
subdirs=($subdirs)
if [[ ${#subdirs[@]} -lt 2 ]]; then
    print_err "The directory path_td must contain folders for images & labels."
fi

if [[ ${#subdirs[@]} -gt 2 ]]; then
    print_err "The directory path_td contains too many folders."
fi

if [[ "$(basename "${subdirs[0]}")" != "images" ]] ||
    [[ "$(basename "${subdirs[1]}")" != "labels" ]]; then
    print_err "path_td must contain folders named 'images' and 'labels'."
fi

path_images="${subdirs[0]}"
path_labels="${subdirs[1]}"

# Check that 'images' and 'labels' sub-directories have valid PNG files
n_images="$(find "${path_images}" -name "*.png" 2> /dev/null | wc -l)"
n_labels="$(find "${path_labels}" -name "*.png" 2> /dev/null | wc -l)"

if [[ "${n_images}" -eq 0 ]]; then
    print_err "The images sub-directory does not contain any valid PNGs."
fi

if [[ "${n_labels}" -eq 0 ]]; then
    print_err "The labels sub-directory does not contain any valid PNGs."
fi

# Check that there are the same number of images and labels
if [[ "${n_images}" -ne "${n_labels}" ]]; then
    print_err "Mismatching number of images and labels."
fi

# Extract array of angles from comma-delimited input
IFS=","
read -ra angles_arr <<< "${angles}"

if [[ "${#angles_arr[@]}" -gt 3 ]]; then
    print_err "Too many angles."
fi

# Check that angle values are valid
for i in "${angles_arr[@]}"; do
    if [[ "$i" -ne 90 ]] && [[ "$i" -ne 180 ]] && [[ "$i" -ne 270 ]]; then
        print_err "Invalid angle."
    fi
done

#####
# MAIN
#####

# Make output directories if necessary
path_out_images="${path_out}"/images
path_out_labels="${path_out}"/labels

for i in "${path_out}" "${path_out_images}" "${path_out_labels}"; do
    if [[ ! -d "$i" ]]; then
        mkdir "$i"
    fi
done

# Rotate images
C=$((n_images + 1))
for i in "${angles_arr[@]}"; do
    for j in "${path_images}"/*.png; do
        fname_out="${path_out_images}"/"$(printf "%03d" "$C")".png
        set -x
        convert "$j" \
            -rotate "$i" \
            -set colorspace Gray \
            -separate \
            -average \
            "${fname_out}"
        { set +x; } 2> /dev/null
        ((C++))
    done
done

# Rotate labels
C=$((n_labels + 1))
for i in "${angles_arr[@]}"; do
    for j in "${path_labels}"/*.png; do
        fname_out="${path_out_labels}"/"$(printf "%03d" "$C")".png
        set -x
        convert "$j" \
            -rotate "$i" \
            -set colorspace Gray \
            -separate \
            -average \
            "${fname_out}"
        { set +x; } 2> /dev/null
        ((C++))
    done
done

# Copy un-rotated images and labels to the output paths
scp "${path_images}"/*.png "${path_out_images}"
scp "${path_labels}"/*.png "${path_out_labels}"


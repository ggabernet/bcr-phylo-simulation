<p align="left">
  <img src="https://img.shields.io/docker/automated/krdav/bcr-phylo-benchmark.svg" />
  <img src="https://img.shields.io/docker/build/krdav/bcr-phylo-benchmark.svg" />
</p>



# Benchmarking phylogenetic inference for B cell receptors

This code repository contains an `scons` pipeline to run a number of phylogenetic inference tools for simulated B cell receptor sequences.
The standard workflow involves 1) simulate sequences, 2) run X phylogenetic tools, and 3) compare true with inferred and report differences.
The same workflow is also used to run comparisons based on isotype misplacement scores.
Pre-run simulation results and their corresponding scons commands can be found on [our Zenodo bucket](https://doi.org/10.5281/zenodo.1218140).



## Cloning this repo

Clone this GitHub repo recursively to get the necessary submodules:
```
git clone --recursive https://github.com/matsengrp/bcr-phylo-benchmark.git
cd SPURF
git pull --recurse-submodules https://github.com/matsengrp/bcr-phylo-benchmark.git
```



## Installation

There are two supported ways of installing this pipeline: 1) using Conda on Linux and 2) using Docker and the provided Dockerfile or image.
The Conda installation has only been tested on Ubuntu.
For testing we highly recommend using Docker which is supported by most platforms.



### Using Conda

First, [install Conda](https://conda.io/docs/user-guide/install/linux.html) for Python 2.
Miniconda is sufficient and much faster at installing.
Remember to `source ~/.bashrc` if continuing installing in the same terminal window.

Install dependencies with `apt-get`:
```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y libpq-dev build-essential xvfb libblas-dev liblapack-dev gfortran autotools-dev automake
```

Install perl modules:
```
cpan PDL
cpan install PDL::LinearAlgebra::Trans
```

IgPhyML is provided but needs to be recompiled due to its use of hard-coded full path:
```
cd tools/IgPhyML
./make_phyml_omp
cd ../..
```

Use the conda environment yaml file to create the "bpb" conda environment:
```
conda env create -f environment_bpb.yml
```

After installation, the Conda environment needs to be loaded every time before use, like this:
```
source activate bpb
```



### Using Docker

First [install Docker](https://docs.docker.com/engine/installation/).

We have a Docker [image on Docker Hub](https://hub.docker.com/r/krdav/bcr-phylo-benchmark) that is automatically kept up to date with the master branch of this repository.
It can be pulled and used directly:
```
sudo docker pull krdav/bcr-phylo-benchmark
```

Alternatively you can build the container yourself from inside the main repository directory:
```
sudo docker build -t bpb .
```

To run this container, use a command such as (see modifications below)

```
sudo docker run -it -v host-dir:/host krdav/bpb /bin/bash
```

* replace `host-dir` with the local directory to which you would like access inside your container 
* replace `/host` with the place you would like this directory to be mounted
* if you built your own container, use `bpb` in place of `krdav/bpb`

Detach using `ctrl-p ctrl-q`.



### DEPENDENCIES
* Python 2 with conda
  * Python dependencies kept in `environment_bpb.yml`
* [GCtree](github.com/matsengrp/gctree) the GitHub repo should be kept under `./tools/gctree/`
  * Provided as a submodule
* [PHYLIP](http://evolution.genetics.washington.edu/phylip/getme-new.html) `dnaml` and `dnapars` stored under `./tools/dnaml/dnaml` and `./tools/dnapars/dnapars` respectively
  * Precompile Linux binaries provided for both programs
* [IQ-TREE](http://www.iqtree.org/) stored under `./tools/IQ-TREE/iqtree`
  * Precompile Linux binaries provided
* [IgPhyML](https://github.com/kbhoehn/IgPhyML) stored under `./tools/IgPhyML/src/igphyml`
  * Provided as a submodule
*[SAMM](github.com/matsengrp/samm) the GitHub repo should be kept under `./tools/samm/`
  * Provided as a submodule
* perl5, with modules:
  * PDL
  * PDL::LinearAlgebra::Trans



## SCONS PIPELINES

Two programs are implemented:
- an inference program for experimental data
- a simulation/inference/validation program

All commands should be issued from within the gctree repo directory.

## QUICK START

* **inference:**  `scons --inference --outdir=<output directory path> --fasta=<input fasta file>`
* **simulation:** `scons --simulate  --outdir=<output directory path> --N=<integer population size to simulate>`

### **example:** to run GCtree inference on the included FASTA file on a remote machine
```
scons --inference --fasta=sequence_data/150228_Clone_3-8.fasta --outdir=test --converter=tas --naiveID=GL --xvfb --jobs=10
```
Results are saved in directory `test/`. The `--converter=tas` argument means that integer sequence IDs in the FASTA file are interpreted as abundances. The flag `--xvfb` allows X rendering of ETE trees on remote machines. The argument `--jobs=10` indicates that 10 parallel processes should be used.

## **INFERENCE**

`scons --inference ...`

### required arguments

`--fasta=[path]` path to FASTA input alignment
`--outdir=[path]` directory for output (created if does not exist)

### optional arguments

`--naiveID=[string]` ID of naive sequence in FASTA file used for outgroup rooting, default 'naive'

`colorfile=[path]  ` path to a file of plotting colors for cells in the input FASTA file. Example, if the FASTA contains a sequence with ID `cell_1`, this cell could be colored red in the tree image by including the line `cell_1,red` in the color file.

`--converter=[string]` if set to "tas", parse FASTA input IDs that are integers as indicating sequence abundance. Otherwise each line in the FASTA is assumed to indicate an individual (non-deduplicated) sequence. **NOTE:** the included FASTA file `sequence_data/150228_Clone_3-8.fasta` requires this option.


## **Sequence simulation**

A couple of simulation commands with reasonable model parameters.

### Neutral simulation

This command will simulate a poisson branching process, with progeny distribution lambda=1.5, under a neutral mutation model i.e. no selection and therefore static progeny distribution, and terminate when 75 unterminated leaves are populating the tree.
The number of mutations to introduce in a daugther cell is drawn from another possion distribution (lambda0=0.365) introducing mutations at a rate of approx. 1e-3, similar to real SHM rates.
The positions and substitutions to use to introduce the mutations drawn follow an empirical substitution probability distribution derived from motifs.
The tree is generated from a naive sequence seed, which will also be the root of the tree.
A naive seed sequence is drawn randomly from the naive sequences provided in `sequence_data/AbPair_naive_seqs.fa`.

```
TMPDIR=/tmp xvfb-run -a python bin/simulator.py --mutability motifs/Mutability_S5F.csv --substitution motifs/Substitution_S5F.csv --outbase neutral_sim --lambda 1.5 --lambda0 0.365 --N 75 --random_seq sequence_data/AbPair_naive_seqs.fa > neut_simulator.log
```

The output consists of different informative files e.g. SVG renderings of the trees.
The tree structure with internal nodes, leaves and associated sequences can be loaded from the pickled ETE3 tree object:
```
from ete3 import TreeNode, TreeStyle, NodeStyle, SVG_COLORS
import pickle

with open('neutral_sim_lineage_tree.p', 'rb') as fh:
    tree = pickle.load(fh)

# Print tree in ASCII:
print(tree)
# Root name and sequence:
tree.name
tree.sequence
```


### Selection simulation

This command will simulate a poisson branching process coupled with a selection process.
The progeny distribution is dynamically set for each cell in the simulation an depends on its fitness defined by its similarity to a "target" sequence and the fitness of the rest of the cell population (carrying capacity of 1000 cells).
Possion lambda=2 is the maximum progeny distribution and lambda is then adjusted smaller according to the cell fitness.
The simulation terminates after 35 rounds of evaluating the progeny for all live cells, then 60 leaves are randomly picked from the whole cell population and the tree is pruned to remove all non-picked leaves.
The number of mutations to introduce in a daugther cell is drawn from another possion distribution (lambda0=0.365) introducing mutations at a rate of approx. 1e-3, similar to real SHM rates.
The positions and substitutions to use to introduce the mutations drawn follow an empirical substitution probability distribution derived from motifs.
The tree is generated from a naive sequence seed, which will also be the root of the tree.
A naive seed sequence is drawn randomly from the naive sequences provided in `sequence_data/AbPair_naive_seqs.fa`.

```
TMPDIR=/tmp xvfb-run -a python bin/simulator.py --mutability motifs/Mutability_S5F.csv --substitution motifs/Substitution_S5F.csv --outbase selection_sim --lambda 2.0 --lambda0 0.365 --T 35 --n 60 --selection --target_dist 5 --target_count 100 --carry_cap 1000 --skip_update 100 --verbose --random_seq sequence_data/AbPair_naive_seqs.fa > sele_simulator.log
```

The output consists of different informative files e.g. SVG renderings of the trees.
The tree structure with internal nodes, leaves and associated sequences can be loaded from the pickled ETE3 tree object:
```
from ete3 import TreeNode, TreeStyle, NodeStyle, SVG_COLORS
import pickle

with open('selection_sim_lineage_tree.p', 'rb') as fh:
    tree = pickle.load(fh)

# Print tree in ASCII:
print(tree)
# Root name and sequence:
tree.name
tree.sequence

# Traverse through the nodes and print their affinity (Kd):
### N.B. Smaller numberical value of affinity means higher fitness
for node in tree.traverse():
    print(node.Kd)
```


#### Selection simulation with intermediate sampling

It is also possible to sample at intermediate timepoint during the simuluation with selection.
This is done with providing additional timepoint with the `--T` parameter.
Sampled cells are removed from the simulated cell population.

```
TMPDIR=/tmp xvfb-run -a python bin/simulator.py --mutability motifs/Mutability_S5F.csv --substitution motifs/Substitution_S5F.csv --outbase selection_inter_sim --lambda 2.0 --lambda0 0.365 --T 15 30 45 --n 30 --selection --target_dist 5 --target_count 100 --carry_cap 1000 --skip_update 100 --verbose --random_seq sequence_data/AbPair_naive_seqs.fa > sele_inter_simulator.log
```




## **SIMULATION**

`scons --simulation ...`

### required arguments

`--N=[int]` populaton size to simulate
`--outdir=[path]` directory for output (created if does not exist)

### optional arguments

`--naive=[string]             ` DNA sequence of naive sequence from which to begin simulating, a default is used if omitted

`--mutability=[path]          ` path to motifs mutability file, default 'motifs/Mutability_S5F.csv'

`--substitution=[path]        ` path to motifs substitution file, default 'motifs/Substitution_S5F.csv'

`--lambda=[float, float, ...] ` values for Poisson branching parameter for simulation, default 2.0

`--lambda0=[float, float, ...]` values for baseline mutation rate, default 0.25

`--T=[int]                    ` time steps to simulate (alternative to `--N`)

`--nsim=[int]                 ` number of simulation of each set of parameter combination, default 10

`--n=[int]                    ` number of cells to sample from final population, default all

## OPTIONAL ARGUMENTS FOR BOTH INFERENCE AND SIMULATION PROGRAMS

`--jobs=[int]  ` number of parallel processes to use

`--srun        ` should cluster jobs be submitted with Slurm's srun?

`--frame=[int] ` codon reading frame, default `None`

`--quick       ` less thorough parsimony tree search (faster, but smaller parsimony forest)

`--idlabel     ` label sequence IDs on tree, and write FASTA alignment of distinct sequences. The mapping of the unique names in this FASTA file to the cell names in the original input FASTA file can be found in the output file with suffix `.idmap`

`--xvfb        ` needed for X rendering in on remote machines

   * Try setting the above option if you get the error:`ETE: cannot connect to X server`

## `gctree.py`
Underlying both pipelines is the `gctree.py` Python library (located in the `bin/` subdirectory) for simulating and compute likelihoods for collapsed trees generated from a binary branching process with mutation and infinite types, as well as forests of such trees. General usage info `gctree.py --help`. There are three subprograms, each of which has usage info:
* `gctree.py infer --help`: takes an `outfile` file made by phylip's `dnapars` as a command line argument, converts each tree therein to a collapsed tree, and ranks by GCtree likelihood.
* `gctree.py simulate --help`: simulate data
* `gctree.py test --help`: performs tests of the likelihood and outputs validation plots.

The under-the-hood functionality of the `gctree.py` library might be useful for some users trying to go beyond the scons pipelines. For example mapping colors to tree image nodes can be achieved with the `--colormap` argument. Colors can be useful for visualizing other cell/genotype properties on the tree.

## FUNCTIONALITY UNDER DEVELOPMENT

### arguments for both inference and simulation programs

`--igphyml`  include results for tree inference with the IgPhyML package

`--dnaml`    include results for maximum likelihood tree inference using `dnaml` from the PHYLIP package

`--nogctree` do not perform gctree inference

### arguments for non-neutral simulation

`--selection`    simulation with affinity selection

`--target_dist`  distance to selection target

`--target_count` number of targets

`--verbose`      verbose printing

`--carry_cap`    carrying capacity of germinal center

`--skip_update`  skip update step



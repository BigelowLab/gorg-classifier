FROM continuumio/miniconda3:4.10.3p1

RUN apt-get update && apt-get install -y procps
RUN conda create -n env -c conda-forge -c bioconda python=3.9 kaiju=1.9.0
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

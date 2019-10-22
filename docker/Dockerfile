FROM continuumio/miniconda3:4.7.12

RUN apt-get update && apt-get install -y procps
RUN conda create -n env -c conda-forge -c bioconda python=3.7 kaiju=1.7.2
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

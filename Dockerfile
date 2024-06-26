FROM pangeo/ml-notebook

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH ${NB_PYTHON_PREFIX}/bin:$PATH

RUN apt-get update -qq --yes > /dev/null && \
    apt-get install --yes -qq curl > /dev/null

ENV JULIA_VERSION 1.10.3
ENV JULIA_PATH /srv/julia
ENV JULIA_DEPOT_PATH ${JULIA_PATH}/pkg
ENV PATH $PATH:${JULIA_PATH}/bin
RUN mkdir -p ${JULIA_PATH}
RUN curl -sSL "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" \
  | tar -xz -C ${JULIA_PATH} --strip-components 1
RUN mkdir -p ${JULIA_DEPOT_PATH} \
 && chown ${NB_UID}:${NB_UID} ${JULIA_DEPOT_PATH}

USER ${NB_USER}

RUN export JUPYTER_DATA_DIR="$NB_PYTHON_PREFIX/share/jupyter" \
 && julia --eval 'using Pkg; Pkg.add("IJulia"); using IJulia; installkernel("Julia");' \
 && julia --eval 'using Pkg; pkg"add CloudMicrophysics"; Pkg.add(["PyCall"]);' \
 && julia --eval 'using Pkg; Pkg.instantiate(); Pkg.resolve(); pkg"precompile"'

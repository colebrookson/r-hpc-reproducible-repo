# rockerverse main base image
FROM rocker/r-ver:4.4.1
ENV MAKEFLAGS="-j1"
# speed up stan compilation
ENV CXX14FLAGS="-O3 -march=native -mtune=native -fPIC" 
# tell stan how many threads it can use 
ENV STAN_NUM_THREADS=4

# pin the cran mirror to avoid issues with distance
ENV PAK_PKG_TYPE=binary \
    CRAN_MIRROR=https://cloud.r-project.org
# force use of that mirror
RUN echo "options(repos = c(CRAN = Sys.getenv('CRAN_MIRROR')))" \
    >> /usr/local/lib/R/etc/Rprofile.site

COPY sys_deps/sys_deps.sh /tmp/sys_deps.sh
RUN bash /tmp/sys_deps.sh && rm /tmp/sys_deps.sh

RUN install2.r --error --skipinstalled pak

# copy project over but only the ones I need
WORKDIR /home/rproject
COPY DESCRIPTION /home/rproject/
RUN R -q -e "pak::meta_update()" \
    && R -q -e "pak::local_install_deps('.', ask = FALSE, upgrade = FALSE)"

# install R packages 
ENV PAK_PKG_TYPE=binary

# copy the rest of the project and install
COPY . /home/rproject
RUN R -q -e "pak::pkg_install('local::./', ask = FALSE, upgrade = FALSE)"

CMD ["Rscript", "example/run_pipeline.R"]


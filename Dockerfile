# rockerverse main base image
FROM rocker/r-ver:4.4.1

COPY sys_deps/sys_deps.sh /tmp/sys_deps.sh
RUN bash /tmp/sys_deps.sh && rm /tmp/sys_deps.sh

# copy project mover
WORKDIR /home/rproject
COPY . /home/rproject

# install R packages 
ENV PAK_PKG_TYPE=binary

# this is just the system and pak 
RUN install2.r --error --skipinstalled pak

# show the depeendency plan 
RUN R -q -e "pak::pkg_deps_tree('local::./', dependencies = TRUE)"

# look for the metadata only once so the next layers are cached
RUN R -q -e "pak::meta_update()"

# install on cached layer
RUN R -q -e "pak::local_install_deps('.', ask = FALSE, upgrade = FALSE)"

# NOW install the local package itself
RUN R -q -e "pak::pkg_install('local::./', ask = FALSE, upgrade = FALSE)"

# off we go!
CMD ["Rscript", "-e", "targets::tar_make()"]

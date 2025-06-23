# ---- Base image ----
FROM rocker/r-ver:4.4.1

# ---- System dependencies ----
COPY sys_deps/sys_deps.sh /tmp/sys_deps.sh
RUN bash /tmp/sys_deps.sh && rm /tmp/sys_deps.sh

# ---- Copy project ----
WORKDIR /home/rproject
COPY . /home/rproject

# ---- Install R packages via DESCRIPTION ----
RUN install2.r --error --skipinstalled pak \
    && R -q -e "pak::pkg_install('local::./')"

# ---- Default command ----
CMD ["Rscript", "-e", "targets::tar_make()"]

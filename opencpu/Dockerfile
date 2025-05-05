FROM opencpu/base:latest

RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev \
    build-essential gfortran libboost-all-dev \
    libcairo2-dev libfontconfig1-dev \
    libgsl-dev libjpeg-dev liblapack-dev libmariadb-dev libpng-dev \
    libproj-dev libsodium-dev libssl-dev libudunits2-dev libxml2-dev mesa-common-dev \
    libglu1-mesa-dev pandoc \
    libcurl4-openssl-dev \
    libbz2-dev liblzma-dev

# Install formr R package
RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "remotes::install_github('rubenarslan/formr')"

COPY clean_up_duplicate_packages.R /clean_up_duplicate_packages.R

RUN Rscript /clean_up_duplicate_packages.R

EXPOSE 80

CMD service cron start && apachectl -DFOREGROUND
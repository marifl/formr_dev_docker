FROM opencpu/base:v2.2.12

# Install dependencies
RUN apt-get update
RUN apt-get install -y build-essential gfortran libboost-all-dev
RUN apt-get install -y libcairo2-dev libcurl4-gnutls-dev libfontconfig1-dev
RUN apt-get install -y libgsl-dev libjpeg-dev liblapack-dev libmariadb-dev libpng-dev
RUN apt-get install -y libproj-dev libsodium-dev libssl-dev  libudunits2-dev libxml2-dev mesa-common-dev
RUN apt-get install -y libglu1-mesa-dev pandoc
RUN apt-get install -y libcurl4-openssl-dev libssl-dev
RUN apt-get install -y libbz2-dev liblzma-dev
RUN apt-get install -y apparmor apparmor-profiles apparmor-utils libapparmor-dev

COPY ./conf/Rprofile /usr/lib/R/etc/Rprofile.site

# Install R packages
RUN echo "apparmor=TRUE" >> /etc/R/Renviron
RUN Rscript -e "install.packages('RAppArmor')"
RUN Rscript -e "install.packages('utf8')"
RUN Rscript -e "install.packages('webutils')"
RUN Rscript -e "install.packages('zip')"

# Install formr R package
RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "install.packages('formr')"

COPY clean_up_duplicate_packages.R /clean_up_duplicate_packages.R

RUN Rscript /clean_up_duplicate_packages.R

CMD service cron start && apachectl -DFOREGROUND

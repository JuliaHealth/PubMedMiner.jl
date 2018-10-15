FROM julia:0.7

# ----------------------Julia web-app specific packages--------------------------------
# my packages

# Create app directory
RUN mkdir -p /usr/bin/pubmedminer
WORKDIR /usr/bin/pubmedminer

# Bundle app source
COPY . /usr/bin/pubmedminer

EXPOSE 8091

RUN julia -e 'using Pkg; pkg"add HTTP JSON"'

CMD julia -e 'using Pkg; pkg"activate ."; Pkg.instantiate(); include("ServerDB.jl");'

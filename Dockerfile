FROM tiangolo/uwsgi-nginx-flask:flask-python3.5
# огромный образ, лучше использовать что-нибудь поменьше
RUN pip3 install pymongo Cython
RUN apt-get update && \
    apt-get install -y libsparsehash-dev && \
    rm -rf /var/lib/apt/lists/*
COPY ./app /app
RUN cd /app/cy && python3 setup.py build_ext --inplace
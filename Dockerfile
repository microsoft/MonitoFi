# // Copyright (c) Microsoft Corporation.
# // Licensed under the MIT license.
FROM python:3.7-slim

RUN  mkdir /opt/monitofi

ENV VIRTUAL_ENV=/opt/monitofi/monitofi-env
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY ./requirements.txt /opt/monitofi/requirements.txt
RUN pip install -r /opt/monitofi/requirements.txt

WORKDIR /opt/monitofi
COPY ./monitofi.py /opt/monitofi/monitofi.py

CMD ["python", "/opt/monitofi/monitofi.py"]
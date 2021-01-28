FROM python:3.7-slim

RUN  mkdir /opt/nifimonitor

ENV VIRTUAL_ENV=/opt/nifimonitor/nifimonitor-env
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY ./requirements.txt /opt/nifimonitor/requirements.txt
RUN pip install -r /opt/nifimonitor/requirements.txt

WORKDIR /opt/nifimonitor
COPY ./nifi_monitor.py /opt/nifimonitor/nifi_monitor.py

CMD ["python", "/opt/nifimonitor/nifi_monitor.py"]
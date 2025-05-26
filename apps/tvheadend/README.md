#### Image: 

https://hub.docker.com/r/linuxserver/tvheadend

#### Download firmware for WinTV-dualHD

```bash
cd /lib/firmware
sudo wget https://github.com/OpenELEC/dvb-firmware/raw/master/firmware/dvb-demod-si2168-b40-01.fw
sudo wget https://github.com/OpenELEC/dvb-firmware/raw/master/firmware/dvb-tuner-si2158-a20-01.fw
```

#### Scan muxes

`Add network` -> `predefined muxes` -> `ru-all` for Serbia and not default. Wait 20 minutes to find 47 channels.
Don't delete existing muxes, it will delete channels.
For scan must `edit network` -> set `ru-all`. Force scan is sufficient. Tuner0 has less channels than tuner1.

#### Backed up `data` folder with channels

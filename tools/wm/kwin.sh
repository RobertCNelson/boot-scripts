#!/bin/bash

DISPLAY=:0 KWIN_DIRECT_GL=1 KWIN_OPENGL_INTERFACE=egl_wayland kwin --replace &

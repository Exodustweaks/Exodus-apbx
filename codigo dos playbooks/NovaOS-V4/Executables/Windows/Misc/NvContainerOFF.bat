sc stop NVDisplay.ContainerLocalSystem
sc config NVDisplay.ContainerLocalSystem start= disabled
sc stop NvTelemetryContainer
sc config NvTelemetryContainer start= disabled

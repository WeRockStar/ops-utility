# Colima

Container runtimes on macOS (and Linux) with minimal setup

## Installation

```bash
brew install colima
```

[More options](https://github.com/abiosoft/colima)

## Usage: Start a container

Start with the default

```bash
colima start
```

Start with **containerd**

```bash
colima start --runtime containerd
```

## Usage: Kubernetes

```bash
colima start --kubernetes
```

Install `kubectl` to interact with the Kubernetes cluster `brew install kubectl`

## Documents

- [Customizing VM](https://github.com/abiosoft/colima?tab=readme-ov-file#customizing-the-vm)

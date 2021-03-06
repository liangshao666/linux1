# build podman image

## archlinux amd64 + kde plasma

```bash
cd amd64/arch/kde
[[ ! -s ../bootstrap.sh ]] || bash ../bootstrap.sh
podman build -t arch-kde .
```

Your image name is arch-kde:latest

How to run it?

```bash
podman run -itd -p 5903:5902 --name arch-amd64-kde --env LANG=en_US.UTF-8 arch-kde
```

How to attach it?

```bash
podman exec -it arch-amd64-kde /bin/zsh
```

or

```bash
podman attach arch-amd64-kde
```

The default vnc port of container is 5902.
Because of `-p 5903:5902`,your vnc address is **localhost:5903**

## debian sid arm64 + xfce

```bash
sudo apt update
sudo apt install qemu-user-static
cd arm64/debian-sid/xfce
podman build -t debian-xfce .
```

```bash
podman run -itd -p 5903:5902 --name debian-arm64-xfce --env LANG=en_US.UTF-8 debian-xfce
```

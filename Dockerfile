FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y redis-server && \
    apt-get clean

RUN apt-get install  -y apt
RUN apt install  -y gcc
RUN apt install  -y gfortran
RUN apt install  -y libopenmpi-dev
RUN apt install  -y python3
RUN apt install  -y gmsh
RUN apt install  -y git
RUN apt install  -y nano
RUN apt install  -y vim
RUN apt install  -y gnuplot
RUN apt install  -y zsh
RUN apt install  -y snap
RUN apt install  -y curl
RUN curl https://bootstrap.pypa.io/get-pip.py -o ~/get-pip.py
RUN python3 ~/get-pip.py
RUN pip install pillow
RUN pip install numpy
RUN pip install scipy
RUN pip install matplotlib
RUN pip install jupyter
RUN pip install nbzip
RUN pip install opencv-python
RUN git clone https://github.com/kazulagi/plantFEM.git
WORKDIR "/plantFEM"

RUN ls
RUN python3 install.py
RUN chmod +x bin/init
RUN chmod +x bin/update
RUN chmod +x bin/compress


#CMD ./plantfem run

# 作成したユーザの情報
LABEL maintainter="main"

# sshサーバをインストールします
RUN apt-get update && apt-get install -y openssh-server
# これが無いとsshdが起動しないっぽい
RUN mkdir /var/run/sshd
# rootのパスワードをrootpasswdに設定します。ただし、公開鍵認証でのアクセスなので使用しませんが。。
RUN echo 'root:rootpassws' | chpasswd
# sshのrootでのアクセスを許可します。ただし、パスワードでのアクセスは無効
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
# sshのポートを22 => 20022に変更します
RUN sed -i 's/#Port 22/Port 20022/' /etc/ssh/sshd_config
# ホスト側にある公開鍵をイメージ側に登録します
COPY ~/.ssh/id_rsa.pub /root/.ssh/authorized_keys

EXPOSE 20022
CMD ["/usr/sbin/sshd", "-D"]
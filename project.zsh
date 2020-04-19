#!/bin/zsh

function help {
    echo ""
    echo "Usage: project COMMAND"
    echo ""
    echo "Commands:"
    echo "  load [nginx conf path]      Load project conf"
    echo "  run [be|fe]                 Start app Frontend or backend"
    echo "  ide                         Open code ide on frontend"
    echo "  backup be                   Backup backend docker folder"
    echo "  stop                        Stop nginx"
    echo ""
}

function help_run {
    echo ""
    echo "Usage: project run COMMAND"
    echo ""
    echo "Commands:"
    echo "  be      run backend  - run docker-compose up in *-be folder"
    echo "  fe      run frontend - run ng serve in *-fe folder"
    echo ""
}

function help_service {
    echo ""
    echo "Usage: project service COMMAND"
    echo ""
    echo "Commands are the commands of brew services (on OS X) or systemctl (on linux)"
    echo ""
}

function get_repo_path {
    echo "$(git rev-parse --show-toplevel)"
}

function load_linux {
    local grp=$(get_repo_path)
    sudo cp -r $grp/nginxconf/* $nginx_dir
    sudo nginx -t 2>/dev/null > /dev/null
    
    if [[ $? == 0 ]]; then
        sudo systemctl restart nginx
    else
        echo "project load: nginx conf error"
        sudo nginx -t
    fi
}

function load_darwin {
    local grp=$(get_repo_path)

    if [ ! -f /etc/nginx ]; then
        sudo ln -s /usr/local/etc/nginx /etc/nginx
    fi

    sudo cp -r $grp/nginxconf/* /usr/local$nginx_dir
    sudo nginx -t 2>/dev/null > /dev/null

    if [[ $? == 0 ]]; then
        sudo brew services restart nginx
    else
        echo "project load: nginx conf error"
        sudo nginx -t
    fi
}

function load_unavailable {
    echo "unavailable system"
}

function run {
    if [ -n "$1" ]; then
        if [ $1 = "be" ]; then
            cd *-be
            if [[ "$OSTYPE" == "linux-gnu" ]]; then
                sudo systemctl start docker
                sudo docker-compose up
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                open /Applications/Docker.app
                until docker ps 2>/dev/null > /dev/null
                do
                    sleep 0.1
                done
                docker-compose up
            fi
        elif [ $1 = "fe" ]; then
            cd *-fe
            npm i
            ng serve
        fi
    else    
        help_run
    fi
}

function backup {
    date=$(date +'%Y%m%d')
    if [ -n "$1" ]; then 
        sudo tar zcvf ../bck_pvdv/${date}_$2.tar.gz pvdv-be
    else
        sudo tar zcvf ../bck_pvdv/${date}.tar.gz pvdv-be
    fi
}

function service {
    if [ -n "$1" ]; then
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            sudo systemctl $1 nginx
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew services $1 nginx
        else
            echo "not supported OS"
        fi
    else
        help_service
    fi
}

if [ -n "$1" ]; then
    if [ "$1" = "load" ]; then
        nginx_dir="/etc/nginx/conf.d"
        if [ -n "$2" ]; then
            nginx_dir=$2
        fi
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            load_linux $nginx_dir
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            load_darwin
        else
            load_unavailable
        fi
    elif [ $1 = "run" ]; then
        run $2
    elif [ $1 = "ide" ]; then
        code pvdv-fe
    elif [ $1 = "backup" ]; then
        backup $2
    elif [ "$1" = "stop" ];then
        stop_all
    elif [ "$1" = "service" ]; then
        service $2
    else
        help
    fi
else
    help
fi


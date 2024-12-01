#!/bin/bash

print_help() {
    echo "Using: \\$0 [options]"
    echo ""
    echo "Options"
    echo "  -u, --users            Выводит перечень пользователей и их домашних директорий."
    echo "  -p, --processes        Выводит перечень запущенных процессов."
    echo "  -h, --help             Выводит данную справку."
    echo "  -l PATH, --log PATH    Записывает вывод в файл по заданному пути."
    echo "  -e PATH, --errors PATH Записывает ошибки в файл ошибок по заданному пути."
}

# Инициализация переменных для путей
log_PATH="/home/alt/logi"
error_PATH="/home/alt/err"
errors(){
    echo "ERROR"
}
action=""

# Функция для вывода пользователей и их домашних директорий
list_users() {
    awk -F: '{ print $1 " " $6 }' /etc/passwd | sort
}

# Функция для вывода запущенных процессов
list_processes() {
    ps -Ao pid,comm --sort=pid
}


while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            action="users"
			list_users
            ;;
        p)
            action="processes"
			list_processes
            ;;
        h)
            show_help
            exit 0
            ;;
        l)
            log_path="$OPTARG"
            ;;
        e)
            error_path="$OPTARG"
            ;;
        
        -)
            case "${OPTARG}" in
            users)
                action="users"
				list_users
                ;;
            processes)
                action="processes"
				list_processes
                ;;
            help)
                show_help
                exit 0
                ;;
            log)
                log_path="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                ;;
            errors)
                error_path="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                ;;
             *)
                echo "Invalid option: --${OPTARG}" >&2
                exit 1
                ;;
            esac
            ;;
        \?)
            #echo "Invalid opion: -$OPTARG" >&2
            exit 1
            ;;
        :)
            #echo "Option -$OPTARG requirs an argument." >&2
            exit 1
            ;;
    esac
done

# Проверка и установка перенаправления потоков, если указаны пути
if [ -n "$error_PATH" ]; then
    if [ -w "$error_PATH" ] || [ ! -e "$error_PATH" ]; then
        {
            
			echo "Option -$OPTARG requirs an argument."
			#echo "ERRORS"
        }> "$error_PATH"
    else
        echo "Error: Cannot write to error path $error_PATH" >&2
        exit 1
    fi
fi

# Выполнение действия в зависимости от аргумента
if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        {
           #     awk -F: '{ print $1 " " $6 }' /etc/passwd | sort
           #     ps -Ao pid,comm --sort=pid
                list_users
                list_processes

        } > "$log_PATH"
    else
        echo "Error: Cannot write to log path $log_PATH" >&2
        exit 1
    fi
else
    case $action in
        users) list_users ;;
        processes) list_processes ;;
        *)
            echo "No valid action specified." >&2
            exit 1
            ;;
    esac
fi

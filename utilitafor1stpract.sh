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

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u|--users)
            action="users"
            list_users
            ;;
        -p|--processes)
            action="processes"
            list_processes
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -l|--log)
            log_PATH="$2"
            shift
            ;;
        -e|--errors)
            error_PATH="$2"
            echo "ERROR" > "$error_PATH"
            #print_help
            exit 1
            ;;
        *)
            echo "Неизвестный аргумент: $1"
            #print_help
            exit 1
            ;;
    esac
    shift
done

# Проверка и установка перенаправления потоков, если указаны пути
if [ -n "$error_PATH" ]; then
    if [ -w "$error_PATH" ] || [ ! -e "$error_PATH" ]; then
        {
            
			echo "No valid action specified."
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

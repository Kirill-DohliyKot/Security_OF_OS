#!/bin/bash

print_help() {
    echo "Using: \$0 [options]"
    echo ""
    echo "Options"
    echo "  -u, --users            Выводит перечень пользователей и их домашних директорий."
    echo "  -p, --processes        Выводит перечень запущенных процессов."
    echo "  -h, --help             Выводит данную справку."
    echo "  -l PATH, --log PATH    Записывает вывод в файл по заданному пути."
    echo "  -e PATH, --errors PATH Записывает ошибки в файл ошибок по заданному пути."
}

# Инициализация переменных для путей
log_PATH=""
error_PATH=""
#action=""

# Функция для вывода пользователей и их домашних директорий
list_users() {
    awk -F: '{ print $1 " " $6 }' /etc/passwd | sort
}

# Функция для вывода запущенных процессов
list_processes() {
    if [ -n "$log_PATH" ]; then
        ps -Ao pid,comm --sort=pid > "$log_PATH" 2>/dev/null
    else
        ps -Ao pid,comm --sort=pid
    fi
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u|--users)
            action="users"
            ;;
        -p|--processes)
            action="processes"
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
            echo "Ошибка" > "$error_PATH"
            print_help
            exit 1
            ;;
        *)
            echo "Неизвестный аргумент: $1"
            print_help
            exit 1
            ;;
    esac
    shift
done

# Проверка и установка перенаправления потоков, если указаны пути
if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        exec > "$log_PATH"
    else
        echo "Error: Cannot write to log path $log_PATH" >&2
        if [ -n "$error_PATH" ]; then
            echo "Ошибка: Невозможно записать в файл лога $log_PATH" > "$error_PATH"
        fi
       # print_help
        exit 1
    fi
fi

if [ -n "$error_PATH" ]; then
    if [ -w "$error_PATH" ] || [ ! -e "$error_PATH" ]; then
        exec 2> "$error_PATH"
    else
        echo "Error: Cannot write to error path $error_PATH" >&2
        if [ -n "$error_PATH" ]; then
            echo "Ошибка: Невозможно записать в файл ошибок $error_PATH" > "$error_PATH"
        fi
        print_help
        exit 1
    fi
fi

# Выполнение действия в зависимости от аргумента
case $action in
    users) list_users ;;
    processes) list_processes ;;
    help) print_help ;;
    *)
        echo "No valid action specified." >&2
        if [ -n "$error_PATH" ]; then
            echo "Ошибка: Не указано действие." > "$error_PATH"
        fi
        print_help
        exit 1
        ;;
esac

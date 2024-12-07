#!/bin/bash

print_help() {
    echo "Using: \\\$0 [options]"
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
action=""
# Функция проверки доступности пути и создание файла
ch_and_create_file() {
    local path="$1"
    if [[ ! -d "$(dirname "$path")" ]]; then
        echo "Ошибка: Директория '$path' не существует." >&2
        exit 1
    fi

    if [[ -f "$path" ]]; then
        echo "Предупреждение: Файл '$path' существует. Будет перезаписан." >&2
    fi
    touch "$path" # создаем файл если он не существует.
    # проверяем права на запись
    if [[ ! -w "$path" ]]; then
        echo "Ошибка: Нет прав на запись в '$path'" >&2
        exit 1
    fi
}
# Функция для вывода пользователей и их домашних директорий
list_users() {
    awk -F: '$3>=1000 { print $1 " " $6 }' /etc/passwd | sort
}

# Функция для вывода запущенных процессов
list_processes() {
    ps -Ao pid,comm --sort=pid
}
# Функция перенаправления стандартного вывода
r_stdout() {
    local log_PATH="$1"
    ch_and_create_file "$log_PATH"
    exec > "$log_PATH"
}

# Функция перенаправления стандартного потока ошибок
r_stderr() {
    local error_PATH="$1"
    ch_and_create_file "$error_PATH"
    exec 2>"$error_PATH"
}
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            action="users"
            ;;
        p)
            action="processes"
            ;;
        h)
            action="help"
            print_help
            exit 0
            ;;
        l)
            log_PATH="$OPTARG"
            ;;
        e)
            error_PATH="$OPTARG"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    action="users"
                    ;;
                processes)
                    action="processes"
                    ;;
                help)
                    action="help"
                    print_help
                    exit 0
                    ;;
                log)
                    log_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                errors)
                    error_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            exit 1
            ;;
        :)
            exit 1
            ;;
    esac
done

# Проверка и установка перенаправления потоков, если указаны пути
if [ -n "$error_PATH" ]; then
    if [[ "$error_PATH" == *.* ]]; then  # Проверка на расширение .*
        echo "Ошибка, действие не задано" > "$error_PATH"
    else
        echo "Error: Invalid file extension for error path $error_PATH" >&2
        exit 1
    fi
else
    # Если error_PATH не указан, создаем файл по умолчанию
    default_error_file="error_log.txt"
    echo "Ошибка, действие не задано" > "$default_error_file"
fi

# Выполнение действия в зависимости от аргумента
if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        {
            case $action in
                users) list_users ;;
                processes) list_processes ;;
                help) print_help ;;
                *)
                    #echo "No valid action specified." >&2
                    exit 1
                    ;;
            esac
        } > "$log_PATH"
    else
        
        echo "Error: Cannot write to log path $log_PATH" >&2
        exit 1
    fi
else
        default_log_file="logi.log"
        {
            case $action in
                users) list_users ;;
                processes) list_processes ;;
                help) print_help ;;
                *)
                    #echo "No valid action specified." >&2
                    exit 1
                    ;;
            esac
        } > "$default_log_file"
    case $action in
        users) list_users ;;
        processes) list_processes ;;
        help) print_help ;;
        *)
            #echo "No valid action specified." >&2
            exit 1
            ;;
    esac
fi

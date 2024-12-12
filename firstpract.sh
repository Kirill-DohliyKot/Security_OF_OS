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
            r_stdout "$log_PATH"
            ;;
        e)
            error_PATH="$OPTARG"
            r_stderr "$error_PATH"
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
                    r_stdout "$log_PATH"
                    ;;
                errors)
                    error_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    r_stderr "$error_PATH"
                    ;;
                *)
                    error_message="Нет такого флага: --${OPTARG}"
                    if [ -n "$error_PATH" ]; then
                        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
                    else
                        echo "$error_message" >&2  # Вывод ошибки в терминал
                    fi
                    exit 1
                    ;;

            esac
            ;;
        \?)
            error_message="Нет такого флага: -$OPTARG"
            if [ -n "$error_PATH" ]; then
                echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
            else
                echo "$error_message" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
        :)
              error_message="Отсутствует аргумент для флага: -$OPTARG"
            if [ -n "$error_PATH" ]; then
                echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
            else
                echo "$error_message" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
    esac
done
# Выполнение действия в зависимости от аргумента
execute_action() {
    case $action in
        users) list_users ;;
        processes) list_processes ;;
        help) print_help ;;
        *)
            echo "No valid action specified." >&2
            exit 1
            ;;
    esac
}
# Проверка на отсутствие действия (если ни один флаг не был указан)
if [[ -z "$action" ]]; then
    error_message="Ошибка: Действие не задано."
    if [ -n "$error_PATH" ]; then
        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
    else
        echo "$error_message" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi

if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        execute_action > "$log_PATH"
    else
        echo "Error: Cannot write to log path $log_PATH" >&2
        exit 1
    fi
fi
# Если не указаны флаги -l или -e, выводим результат в терминал
if [ -z "$log_PATH" ] && [ -z "$error_PATH" ]; then
    execute_action
fi

# Обработка случая, когда не указано действие (action пуст)
if [ -z "$action" ]; then
    error_message="Ошибка: Не указано действие."
    if [ -n "$error_PATH" ]; then
        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
    else
        echo "$error_message" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi

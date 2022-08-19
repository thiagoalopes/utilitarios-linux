#!/bin/bash

# O script lê o arquivo ~/.pgshellpass (o arquivo deve ser criado) no diretorio do usuário e 
# realiza o backup para os bancos de dados informados no arquivo. Caso não encontre o arquivo,
# finaliza retorna erro.

# OBS: o arquivo ~/.pgshellpass deve serguir o mesmo formato do arquivo .pgpass do sgbd PostgreSQL

###################################### SHELL SCRIPT ###############################################

if [ -f ~/.pgshellpass ]
then

    #PEGA O TOTAL DE LINHAS PRA VERIFICAR SE EXISTE INOFRMAÇÕES NO ARQUIVO ~/.pgshellpass
    TOTAL_LINHAS=$(cat ~/.pgshellpass | sed '/^\s*#/d;/^\s*$/d' | wc -l)

    #CASO HAJA UMA OU MAIS LINHAS INICIA O A LEITURA LINHA A LINHA DO ARQUIVO ~/.pgshellpass
    if [ $TOTAL_LINHAS -ge 1 ] 
    then

        #ENQUANTO LER AS LINHAS DO ARQUIVO ~/.pgshellpass
        while read line; 
        do 
        
            #PEGA OS DADOS DO ARQUIVO ~/.pgshellpass E CRIA AS VARIAVEIS
            DATABASE="$(echo $line | awk -F ":" '{ print $3 }')"
            DATABASE_HOST="$(echo $line | awk -F ":" '{ print $1 }')"
            DATABASE_PORT="$(echo $line | awk -F ":" '{ print $2 }')"
            DATABASE_USER="$(echo $line | awk -F ":" '{ print $4 }')"
            export PGPASSWORD="$(echo $line | awk -F ":" '{ print $5 }')"

            #PEGA O DIRETORIO ATUAL DE EXECUÇÃO DO SCRIPT (PROCURE SEMPRE EXECUTAR DENTRO DO DIRETŔIO DO SCRIPT)
            DATABASE_BACKUP_PATH="."

            #CRIA O NOME ARQUVO COM O CAMINHO EM CAIXA BAIXA E DEPOIS DEFINE AS EXTENSÕES (.sql e .tar.gz) 
            DUMP_NAME="$DATABASE_BACKUP_PATH/$(date +%Y_%m_%d_%Hh:%Mm:%Ss)_$(echo $DATABASE | tr '[:upper:]' '[:lower:]')"
            SQL_DUMP_FILE=$DUMP_NAME.sql
            COMPACT_DUMP_FILE=$DUMP_NAME.tar.gz 

            #REGISTRA NO LOG O ARQUIVO QUE SERÁ GERADO
            LOG="pgshelllog.txt"
            echo "$DUMP_NAME" >> $LOG

            echo "GERANDO O DUMP DO BANCO: $SQL_DUMP_FILE"

            #REALIZA O DUMP DA BASE DE DADOS (PARA ENTENDER AS AS OPÇÕES DO PG_DUMP, FAVOR CONSULTAR DOCUMENTAÇÃO NA WEB)
            pg_dump --host "$DATABASE_HOST" --port "$DATABASE_PORT" --username "$DATABASE_USER" --verbose --blobs --encoding=utf8 --file "$SQL_DUMP_FILE" --format=plain \
            --inserts --column-inserts "$DATABASE" 2>> $LOG

            #SE O DUMP SQL FOR GERADO COM SUCESSO, O MESMO SERÁ CRIADO UM ARQUIVO COMPACTADO
            if [ $? -eq 0 ] 
            then

                #COMPACTA O ARQUIVO NO FORMATO .tar.gz
                echo "COMPACTANDO O DUMP $COMPACT_DUMP_FILE"
                tar -czvf "$COMPACT_DUMP_FILE" -C "$DATABASE_BACKUP_PATH" "$SQL_DUMP_FILE"  

                #SE A COMPACTAÇÃO OCORRER COM SUCESSO, O ARQUIVO .sql SERÁ REMOVIDO
                if [ $? -eq 0 ]
                then

                    #REMOVE O ARQUIVO SQL GERADO
                    echo "REMOVENDO O DUMP DO BANCO: $SQL_DUMP_FILE"
                    rm "$SQL_DUMP_FILE"

                else

                    #CASO OCORRA UM ERRO NA COMPACTAÇÃO O SCRIPT IRÁ FINALIZAR COM ERRO SEM EXCLUIR O ARQUIVO .sql
                    echo "A COMPACTACAO DO DUMP RETORNOU ERRO $?"
                    exit 1

                fi
            
            else

                #CASO OCORRA UM ERRO NO DUMP DO BANCO DE DADOS O SCRIPT SERÁ FINALIZADO COM ERRO
                echo "O DUMP DO BANCO DE DADOS RETORNOU ERRO $?"
                exit 1

            fi

        done < ~/.pgshellpass

            #CASO NÃO OCORRA PROBLEMAS, O SCRIPT SERÁ FINALIZADO COM SUCESSO!
            exit 0

    else
        #CASO NÃO HAJA DADOS NO ARQUIVO (EM BRANCO) O SCRIPT É FINALIZADO COM ERRO
        echo "NÃO REGISTROS NO ARQUIVO ~/.pgshellpass"
        exit 1
    fi

else

    #CASO O ARQUIVO ~/.pgshellpass NÃO SEJA ENCONTRADO NO DIRETÓRIO DO USUÁRIO O SCRIPT FINALZA COM ERRO
    echo "ARQUIVO ~/.pgshellpass NÃO ENCONTRADO"
    exit 1

fi




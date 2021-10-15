#env var for DB
echo DB_HOST=$( gcloud sql instances describe myinstance |grep ipAddress: | awk '{print $NF}') >>.env
echo DB_NAME=postgres >>.env
echo DB_USER=postgres >>.env
echo DB_PASS=$DBPASS >>.env

echo POSTGRES_DB=postgres >>.env
echo POSTGRES_USER=postgres >>.env
echo POSTGRES_PASSWORD=$DBPASS >>.env

echo SECRET_KEY="t72SNFj6qmYuVsbdBBEKRzzVXmEa00MojSwtiBgWbaVdiuWk70" >> .env
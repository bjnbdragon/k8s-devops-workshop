#!/bin/bash

set -e

ARG_1=$1

ITEMS='product-service-db statistics-service-db statistics-service-redis'
ENV=test
if [ ! -z $ARG_1 ] ; then
    ENV=$ARG_1
fi

DB_INIT_SCRIPT='./product-service/api/scripts/init.sql'
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

kubectl create namespace boathouse-$ENV 2>/dev/null || true
for ITEM in $ITEMS ; do
    $SCRIPTPATH/4-deploy-service.sh $ITEM whatever $ENV
done

kubectl rollout status deploy/product-service-db-deployment -n boathouse-$ENV

PRODUCT_DB_POD=$(kubectl get pods -o=jsonpath='{.items[0].metadata.name}' -l app=product-service-db)
sleep 10
kubectl cp $DB_INIT_SCRIPT ${PRODUCT_DB_POD}:/root/init.sql -n boathouse-$ENV -c product-service-db
kubectl exec ${PRODUCT_DB_POD} -c product-service-db -n boathouse-$ENV -- /bin/bash -c 'mysql -u root -pP2ssw0rd < /root/init.sql'

echo "Installation complete!"

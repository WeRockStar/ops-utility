# MongoDB

### Dumping and Restoring a MongoDB Database

0. `docker compose up` to start a MongoDB container.
1. Dump a database
   - Then, `mogodump` will create a directory `dump` in the current directory.

2. Restore a database
   - Then, `mongorestore` will restore the database from the `dump` directory.

3. Usually, you can specify database or collection you need
   - `mongodump --uri="XXXX" -d <database>` or `mongodump --uri="XXXX" -c <collection>`

```bash {"id":"01HZKNGYQ4NN036D59TGHSAES4"}
# 1. Dump a database
mongodump --uri="mongodb://admin:secret@localhost:27017/?authSource=admin"

# 2. Restore a database
mongorestore --uri="mongodb://admin:secret@localhost:27018/?authSource=admin"
```

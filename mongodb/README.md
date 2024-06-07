# MongoDB

### Prepare the data

1. `docker compose up` to start the MongoDB server
2. Data Source running on `localhost:27017`
3. And destination running on `localhost:27018`

### Dumping and Restoring a MongoDB Database

Dumping binary data from a MongoDB database, and restoring it to another database.

1. Dump a database
   - Then, `mogodump` will create a directory `dump` in the current directory.

2. Restore a database
   - Then, `mongorestore` will restore the database from the `dump` directory.

3. You can specify database or collection you need, by using the following command
   - `mongodump --uri="XXXX" -d <database>` or `mongodump --uri="XXXX" -c <collection>`

`mongodump` Options
- `-out`: output directory
- `--uri`: connection string
- `--archive`: output to a single file
- `--gzip`: compress the output
- `-d`: database
- `-c`: collection
- `query`: query to filter the data
- `--oplog`: include oplog in the dump, for point-in-time backup

`mongorestore` Options
- `--uri`: connection string
- `--archive`: input from a single file
- `--nsFrom`: source namespace e.g. `<database_name>.<collection_name>`
- `--nsTo`: destination namespace e.g. `<new_database_name>.<collection_name>`
- `--drop`: drop the collection before restoring
- `--dryRun`: test the restore operation
- `--gzip`: decompress the input
- `--objcheck`: validate the objects before inserting

```bash {"id":"01HZPR6NWZ1V9J18DDPG1SSMPM"}
mongodump --uri="mongodb://admin:secret@localhost:27017/?authSource=admin"

# 2. Restore a database
mongorestore --uri="mongodb://admin:secret@localhost:27018/?authSource=admin"
```

### Import and Export a Collection (Single Collection)

1. Export a collection
   - Then, `mongoexport` will create a JSON file in the current directory.

2. Import a collection
   - Then, `mongoimport` will import the JSON file to the collection.

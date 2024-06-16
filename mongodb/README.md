# MongoDB

## Backup and Restore

MongoDB provides tools to backup and restore databases and collections.

- `mongodump` and `mongorestore` for binary data
- `mongoexport` and `mongoimport` for JSON data
- MongoDB Atlas provides backup and restore services
  - Automated backups
  - On-demand backups
  - Point-in-time recovery

### Prepare the Data

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
- `--config`: path to a configuration file
- `--uri`: connection string
- `--archive`: output to a single file
- `--gzip`: compress the output
- `-d`: database
- `-c`: collection
- `--query`: query to filter the data
- `--oplog`: include oplog (operaion log) in the dump, for point-in-time backup

`mongorestore` Options

- `--uri`: connection string
- `--archive`: input from a single file
- `--nsFrom`: source namespace e.g. `<database_name>.<collection_name>`
- `--nsTo`: destination namespace e.g. `<new_database_name>.<collection_name>`
- `--drop`: drop the collection before restoring
- `--dryRun`: test the restore operation
- `--gzip`: decompress the input
- `--objcheck`: validate the objects before inserting
- `--maintainInsertionOrder`: maintain the order of the inserted documents

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

### Monitoring MongoDB

1. `mongotop`: track the read and write activity of MongoDB
2. `mongostat`: track the status of a running MongoDB instance

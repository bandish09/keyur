//
//  DBManager.m
//  RajpathClub
//
//  Created by SerpentCS on 12/18/14.
//  Copyright (c) 2014 SerpentCS. All rights reserved.
//

#import "DBManager.h"

static DBManager *sharedInstance = nil;
static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;


@implementation DBManager


+(DBManager*)getSharedInstance{
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:NULL]init];
    }
	return sharedInstance;
}


-(BOOL)CreateTable:(NSString *)table_name fields:(NSMutableArray*)fields_arr{
    NSString *docsDir;
    NSArray *dirPaths;

    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];

    //Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"SerpentCS.db"]];
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
//    if ([filemgr fileExistsAtPath: databasePath ] == NO)
//    {
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK)
        {
            char *errMsg;

            NSString *create_qry = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (_id INTEGER PRIMARY KEY AUTOINCREMENT,",table_name];

            for (int i = 0; i<[fields_arr count]; i++) {
                if ([[fields_arr objectAtIndex:i] isEqualToString:@"id"])
                {
                    create_qry = [create_qry stringByAppendingString:[NSString stringWithFormat:@"%@ INTEGER,",[fields_arr objectAtIndex:i]]];

                }
                else {
                    create_qry = [create_qry stringByAppendingString:[NSString stringWithFormat:@"%@ TEXT,",[fields_arr objectAtIndex:i]]];

                }


            }


            create_qry = [create_qry stringByAppendingString:@"is_created TEXT, is_updated TEXT, account_id INTEGER);"];
            const char *sql_stmt = [create_qry UTF8String];
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg)!= SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table");
                sqlite3_close(database);
                return  isSuccess;
            }
            else {
                isSuccess = YES;
                NSLog(@"create database");
            }
        }
        return isSuccess;
    }

-(NSInteger)InsertRecord:(NSMutableDictionary*)Table_Record key_arr:(NSMutableArray*)key_arr table_name:(NSString*)table_name{
    
    NSInteger lastRowId;
    lastRowId = 0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths objectAtIndex:0];


    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *insert_qry = [[NSString alloc]init];
        NSString *insert_key_qry = [NSString stringWithFormat:@"insert into %@ (",table_name];
        NSString *insert_value_qry = @"values(";


        for (id obj in key_arr) {
                insert_key_qry = [insert_key_qry stringByAppendingString:[NSString stringWithFormat:@"%@,",obj]];

                NSString *value = [Table_Record valueForKey:obj];
                insert_value_qry = [insert_value_qry stringByAppendingString:[NSString stringWithFormat:@"\"%@\",",value]];


        }

        NSString *account_id_value = [Table_Record valueForKey:@"account_id"];

        insert_key_qry = [insert_key_qry stringByAppendingString:@"is_created, is_updated, account_id)"];
        insert_value_qry = [insert_value_qry stringByAppendingString:[NSString stringWithFormat:@"\"%@\",\"%@\",\"%@\")",@"0",@"0",account_id_value]];

        insert_qry = [insert_qry stringByAppendingString:insert_key_qry];
        insert_qry = [insert_qry stringByAppendingString:insert_value_qry];


        const char *insert_stmt = [insert_qry UTF8String];
        sqlite3_prepare_v2(database, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {

            lastRowId = sqlite3_last_insert_rowid(database);
        }
       else {
                return 0;
            }
            sqlite3_reset(statement);
    }
    return lastRowId;
}

-(NSArray*)fetch_data:(NSString *)table_name fields_arr:(NSMutableArray *)fields_arr condition:(NSString *)condition{
    NSString *docsDir;
    NSArray *dirPaths;


    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];

    databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: @"SerpentCS.db"]];

    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        sqlite3_stmt *SelectStatement;
        NSMutableDictionary *record_dict;

        NSString *SelectQry=@"select ";
        NSString *lastField = [fields_arr lastObject];
        for (int i =0; i<[fields_arr count]; i++) {
            if (fields_arr[i] == lastField) {
                SelectQry = [SelectQry stringByAppendingString:[NSString stringWithFormat:@"%@ ",fields_arr[i]]];
            } else {
                SelectQry = [SelectQry stringByAppendingString:[NSString stringWithFormat:@"%@,",fields_arr[i]]];
            }
        }

        SelectQry = [SelectQry stringByAppendingString:[NSString stringWithFormat:@"from %@ %@",table_name, condition]];




        const char *query_stmt = [SelectQry UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(database,
                               query_stmt, -1, &SelectStatement, NULL) == SQLITE_OK)
        {

            while(sqlite3_step(SelectStatement) == SQLITE_ROW)
            {

                record_dict=[[NSMutableDictionary alloc]init];


                for (int i = 0; i<[fields_arr count]; i++) {

                    NSString *field_value = [[NSString alloc]init];
                    char *localityChars = sqlite3_column_text(SelectStatement, i);
                    if (localityChars ==NULL)
                    {
                        field_value = @"";
                    }
                    else
                        field_value = [NSString stringWithUTF8String: localityChars];



                    //field_value = [[NSString alloc] initWithUTF8String:
                      //            (const char *) sqlite3_column_text(SelectStatement, i)];

                    if ([table_name isEqualToString:@"hr_holidays"]) {
                        const char *C_Name = sqlite3_column_name(SelectStatement, i);
                        NSString *columnName = [NSString stringWithUTF8String:C_Name];
                        [record_dict setValue:field_value forKey:columnName];
                    }

                    if ([table_name isEqualToString:@"hr_payslip"]) {
                        const char *C_Name = sqlite3_column_name(SelectStatement, i);
                        NSString *columnName = [NSString stringWithUTF8String:C_Name];
                        [record_dict setValue:field_value forKey:columnName];
                    }

                    else {
                        [record_dict setValue:field_value forKey:fields_arr[i]];
                    }




                }
                [resultArray addObject:record_dict];

            }
            return resultArray;
            //sqlite3_reset(statement);
            sqlite3_finalize(SelectStatement);
        }
        else{
                sqlite3_finalize(SelectStatement);
                return nil;
        }

    }
    
    return nil;
}

-(BOOL)updateData:(NSMutableDictionary *)Table_Record key_arr:(NSMutableArray *)key_arr table_name:(NSString *)table_name condition:(NSString *)condition{
    if(sqlite3_open([databasePath UTF8String],&database )==SQLITE_OK)
    {
        NSString *update_query = [NSString stringWithFormat:@"UPDATE %@ SET ",table_name];

        for (id obj in key_arr) {
            NSString *value = [Table_Record valueForKey:obj];
            update_query = [update_query stringByAppendingString:[NSString stringWithFormat:@"%@=\"%@\",",obj,value]];
        }
        NSLog(@"update quereyyyyy....%@",update_query);

        update_query = [update_query substringToIndex:[update_query length] - 1];

        update_query = [update_query stringByAppendingString:[NSString stringWithFormat:@" %@",condition]];

        NSLog(@"with condition ....%@",update_query);

        const char *query_statement=[update_query UTF8String];

        if(sqlite3_prepare_v2(database, query_statement, -1, &statement, NULL)==SQLITE_OK)
        {
            while(sqlite3_step(statement) == SQLITE_DONE)
            {
                return YES;
            }
            sqlite3_finalize(statement);
        }
    }
    return FALSE;

}

-(BOOL)delete_record:(NSString *)table_name condition:(NSString *)condition{
    if (sqlite3_open([databasePath UTF8String], &database ) == SQLITE_OK) {

        //sqlite3_stmt *deleteStatement;



        NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM %@ %@",table_name, condition];
        if (sqlite3_prepare_v2(database ,[deleteQuery  UTF8String], -1, &statement, NULL) == SQLITE_OK)
        {

            //            //When binding parameters, index starts from 1 and not zero.
            //            sqlite3_bind_text(deleteStatement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);

            if (SQLITE_DONE == sqlite3_step(statement)){

                NSLog(@"Record deleted successfully");
                return TRUE;
            }
        }
        else{

            NSLog(@"not deleted..");
            return FALSE;
        }
    }
    NSLog(@"database not open");
    sqlite3_reset(statement);
    return FALSE;

}

@end

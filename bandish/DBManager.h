//
//  DBManager.h
//  RajpathClub
//
//  Created by SerpentCS on 12/18/14.
//  Copyright (c) 2014 SerpentCS. All rights reserved.




#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DBManager : NSObject
{
    NSString *databasePath;
}
+(DBManager*)getSharedInstance;
-(BOOL)CreateTable:(NSString *)table_name fields:(NSMutableArray*)fields_arr;
-(NSInteger)InsertRecord:(NSMutableDictionary*)Table_Record key_arr:(NSMutableArray*)key_arr table_name:(NSString*)table_name;
-(NSArray*)fetch_data:(NSString*)table_name fields_arr:(NSMutableArray*)fields_arr condition:(NSString *)condition;
-(BOOL)updateData:(NSMutableDictionary*)Table_Record key_arr:(NSMutableArray*)key_arr table_name:(NSString*)table_name condition:(NSString *)condition;
-(BOOL) delete_record:(NSString*)table_name condition:(NSString*)condition;
@end

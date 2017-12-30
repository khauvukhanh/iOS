//
//  ContentManager.m
//  CourseList
//
//  Created by Vu Khanh on 10/25/17.
//  Copyright © 2017 Khanh. All rights reserved.
//

#import "ContentManager.h"


@implementation ContentManager

+ (ContentManager *)shareManager
{
    static ContentManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ContentManager alloc] init];
    });
    
    return manager;
}

- (BOOL)checkDatabase
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    dbPath = [NSString stringWithFormat:@"%@/CourseList.sqlite", documentPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)copyDatabaseIfNeeded
{
    if (![self checkDatabase])
    {
        [self copyDatabaseToDocument];
    }
}

- (void)copyDatabaseToDocument
{
    NSError *error = nil;
    NSString *localPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_NAME];
    
    /// Remove database if file exists
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error];
    
    if (![[NSFileManager defaultManager] copyItemAtPath:localPath toPath:dbPath error:&error])
    {
        NSLog(@"Error - %@", [error localizedDescription]);
    }
    else
    {
        NSLog(@"Copy database to document successfully !");
    }
}

#pragma mark **** SQL With Table Course ****

- (void)deleteCourseWithCourse:(CourseModel *)course completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Course WHERE Course_ID = %d", [course courseId]];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}

- (void)updateCourseWithCourse:(CourseModel *)course completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE Course SET Course_Name = '%@' WHERE Course_ID = %d", [course courseName], [course courseId]];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}

- (void)insertCourseWithName:(NSString *)courseName completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO Course (Course_Name) VALUES ('%@')", courseName];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}


- (void)getAllCourseCompletion:(void (^)(BOOL success, NSArray *course,NSString *message ))callBack
{
    NSString *sql = @"SELECT Course_ID, Course_Name FROM Course";
    
    [self getDataWithSql:sql completion:^(BOOL success, sqlite3_stmt *sqlStatement, NSString *message) {
        
        BOOL successFlag;
        NSString *errorMessage;
        NSMutableArray *courseList;
        
        if (success && sqlStatement != nil)
        {
            successFlag = YES;
            errorMessage = nil;
            
            courseList = [[NSMutableArray alloc] init];
            while (sqlite3_step(sqlStatement) == SQLITE_ROW)
            {
                CourseModel *course = [[CourseModel alloc] init];
                course.courseId = sqlite3_column_int(sqlStatement, 0);
                course.courseName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(sqlStatement, 1)];
                
                [courseList addObject:course];
            }
        }
        else
        {
            successFlag = NO;
            errorMessage = message;
        }
        
        callBack(successFlag, courseList, errorMessage);
    }];
}

#pragma mark **** SQL With Table Student ****

- (void)deleteStudent:(StudentModel *)student completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Student WHERE Student_ID = %d", [student studentId]];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}

- (void)updateStudent:(StudentModel *)student completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE Student SET Student_Name = '%@' WHERE Student_ID = %d", [student studentName], [student studentId]];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}

- (void)insertStudentWithName:(NSString *)studentName andCourse:(CourseModel *)course completion:(void (^)(BOOL success, NSString *message))callBack
{
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO Student (Student_Name, Course_ID) VALUES ('%@',%d)", studentName, [course courseId]];
    
    [self excuteSql:sql completion:^(BOOL success, NSString *message) {
        callBack(success, message);
    }];
}

- (void)getAllStudentInCourse:(CourseModel *)course completion:(void (^)(BOOL success, NSArray *student, NSString *message ))callBack
{
    NSString *sql = [NSString stringWithFormat:@"SELECT Student_ID, Student_Name FROM Student WHERE Course_ID = %d", [course courseId]];;
    
    [self getDataWithSql:sql completion:^(BOOL success, sqlite3_stmt *sqlStatement, NSString *message) {
        
        BOOL successFlag;
        NSString *errorMessage;
        NSMutableArray *studentList;
        
        if (success && sqlStatement != nil)
        {
            successFlag = YES;
            errorMessage = nil;
            
            studentList = [[NSMutableArray alloc] init];
            while (sqlite3_step(sqlStatement) == SQLITE_ROW)
            {
                StudentModel *student = [[StudentModel alloc] init];
                student.studentId = sqlite3_column_int(sqlStatement, 0);
                student.studentName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(sqlStatement, 1)];
                student.courseId = sqlite3_column_int(sqlStatement, 2);
                
                [studentList addObject:student];
            }
        }
        else
        {
            successFlag = NO;
            errorMessage = message;
        }
        
        callBack(successFlag, studentList, errorMessage);
    }];
}


#pragma mark **** Base SQL ****

- (void)excuteSql:(NSString *)sql completion:(void (^)(BOOL success, NSString *message))callBack
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        const char *databaseChar = [dbPath UTF8String];
        BOOL success;
        NSString *message;
        
        if (sqlite3_open(databaseChar, &db) == SQLITE_OK)
        {
            char *dbError;
            if (sqlite3_exec(db, [sql UTF8String], NULL, NULL, &dbError) == SQLITE_OK)
            {
                success = YES;
                message = [NSString stringWithFormat:@"Success to excute with sql: %@",sql];
            }
            else
            {
                success = NO;
                message = [NSString stringWithFormat:@"Failed to excute with sql: %@",sql];
            }
        }
        else
        {
            success = NO;
            message = @"Can't open database";
        }
        sqlite3_close(db);
        /// UI Thread
        dispatch_async(dispatch_get_main_queue(), ^{
            callBack(success, message);
        });
    });
}

- (void)getDataWithSql:(NSString *)sql completion:(void (^)(BOOL success, sqlite3_stmt *sqlStatement ,NSString *message ))callBack
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        const char *databaseChar = [dbPath UTF8String];
        BOOL success;
        NSString *message;
        sqlite3_stmt *sqlStatement = nil;
        
        if (sqlite3_open(databaseChar, &db) == SQLITE_OK)
        {
            if (sqlite3_prepare(db, [sql UTF8String], -1, &sqlStatement, NULL) == SQLITE_OK)
            {
                if (sqlStatement != nil)
                {
                    success = YES;
                    message = [NSString stringWithFormat:@"Success to get data with sql: %@", sql];
                }
                else
                {
                    success = NO;
                    message = [NSString stringWithFormat:@"Failed to get data with sql: %@", sql];
                }
            }
            else
            {
                success = NO;
                message = [NSString stringWithFormat:@"Error to excute with sql: %@",sql];
            }
        }
        else
        {
            success = NO;
            message = @"Can't open database";
        }
        /// UI Thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callBack != nil)
            {
                callBack(success, sqlStatement, message);
            }
            
            if (sqlStatement != nil)
            {
                sqlite3_finalize(sqlStatement);
            }
            
            sqlite3_close(db);
            
        });
    });
}


@end

//
//  ContentManager.m
//  Course_CoreData
//
//  Created by Vu Khanh on 10/28/17.
//  Copyright © 2017 Khanh. All rights reserved.
//

#import "ContentManager.h"
#import "AppDelegate.h"

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

- (NSManagedObjectContext *)getCurrentContext
{
    AppDelegate *application = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    return application.persistentContainer.viewContext;
}



- (BOOL)insertCourseWithName:(NSString *)name
{
    NSManagedObjectContext *context = [self getCurrentContext];
    Course *course = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:context];
    
    course.courseName = name;
    
    NSError *error = nil;
    if (![context save:&error])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)editCourse:(Course *)course
{
    if (course != nil)
    {
        NSManagedObjectContext *context = [self getCurrentContext];
        NSError *error = nil;
        
        if (![context save:&error])
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return NO;
    }
}

- (BOOL)deleteCourse:(Course *)course
{
    NSManagedObjectContext *context = [self getCurrentContext];
    [context deleteObject:course];
    
    NSError *error = nil;
    if (![context save:&error])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (NSArray *)getAllCourse
{
    NSManagedObjectContext *context = [self getCurrentContext];
    NSFetchRequest *request = [Course fetchRequest];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"courseName" ascending:YES];
    request.sortDescriptors = @[sort];
    NSError *error = nil;
    
    return [context executeFetchRequest:request error:&error];
}

#pragma mark - Table Student

-(BOOL)insertStudentWithName:(NSString *)studentName inCourse:(Course *)course
{
    NSManagedObjectContext *context = [self getCurrentContext];
    
    Student *st = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:context];
    
    st.studentName=studentName;
    
    [course addHasManyObject:st];
    
    NSError *error = nil;
    
    if(![context save:&error])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)editStudent:(Student *)student
{
    if (student != nil)
    {
        NSManagedObjectContext *context = [self getCurrentContext];
        NSError *error = nil;
        
        if (![context save:&error])
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return NO;
    }
}

- (BOOL)deleteStudent:(Student *)student
{
    NSManagedObjectContext *context = [self getCurrentContext];
    [context deleteObject:student];
    
    NSError *error = nil;
    if (![context save:&error])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end

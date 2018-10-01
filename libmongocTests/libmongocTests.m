//
//  libmongocTests.m
//  libmongocTests
//
//  Created by Kyle Hankinson on 2018-10-01.
//  Copyright © 2018 Hankinsoft Development, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import libmongoc;

@interface libmongocTests : XCTestCase

@end

@implementation libmongocTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testExample
{
    [self doTest];
}

- (int) doTest
{
    const char *uri_string = "mongodb://localhost:27017";
    mongoc_uri_t *uri;
    mongoc_client_t *client;
    mongoc_database_t *database;
    mongoc_collection_t *collection;
    bson_t *command, reply, *insert;
    bson_error_t error;
    char *str;
    bool retval;
    
    /*
     * Required to initialize libmongoc's internals
     */
    mongoc_init ();

#if ARGC
    /*
     * Optionally get MongoDB URI from command line
     */
    if (argc > 1) {
        uri_string = argv[1];
    }
#endif

    /*
     * Safely create a MongoDB URI object from the given string
     */
    uri = mongoc_uri_new_with_error (uri_string, &error);
    if (!uri) {
        fprintf (stderr,
                 "failed to parse URI: %s\n"
                 "error message:       %s\n",
                 uri_string,
                 error.message);
        return EXIT_FAILURE;
    }
    
    /*
     * Create a new client instance
     */
    client = mongoc_client_new_from_uri (uri);
    if (!client) {
        return EXIT_FAILURE;
    }
    
    /*
     * Register the application name so we can track it in the profile logs
     * on the server. This can also be done from the URI (see other examples).
     */
    mongoc_client_set_appname (client, "connect-example");
    
    /*
     * Get a handle on the database "db_name" and collection "coll_name"
     */
    database = mongoc_client_get_database (client, "db_name");
    collection = mongoc_client_get_collection (client, "db_name", "coll_name");
    
    /*
     * Do work. This example pings the database, prints the result as JSON and
     * performs an insert
     */
    command = BCON_NEW ("ping", BCON_INT32 (1));
    
    retval = mongoc_client_command_simple (
                                           client, "admin", command, NULL, &reply, &error);
    
    if (!retval) {
        fprintf (stderr, "%s\n", error.message);
        return EXIT_FAILURE;
    }
    
    str = bson_as_json (&reply, NULL);
    printf ("%s\n", str);
    
    insert = BCON_NEW ("hello", BCON_UTF8 ("world"));
    
    if (!mongoc_collection_insert_one (collection, insert, NULL, NULL, &error)) {
        fprintf (stderr, "%s\n", error.message);
    }
    
    bson_destroy (insert);
    bson_destroy (&reply);
    bson_destroy (command);
    bson_free (str);
    
    /*
     * Release our handles and clean up libmongoc
     */
    mongoc_collection_destroy (collection);
    mongoc_database_destroy (database);
    mongoc_uri_destroy (uri);
    mongoc_client_destroy (client);
    mongoc_cleanup ();

    return EXIT_SUCCESS;
}

@end

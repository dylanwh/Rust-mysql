#include <stdio.h>
#include "rmysql.h"

int main()
{
    struct Error error;
    struct Attribs attribs = {.debug = true};

    // Connection parameters
    const char *dsn = "dbi:rmysql:database=test;host=10.0.0.15";
    const char *user = "test";
    const char *password = "slapjack";

    // Connect to the database
    struct ConnHandle *conn = rmysql_connect(dsn, user, password, &error);
    if (conn == NULL)
    {
        printf("Connection error: %s\n", error.message);
        return 1;
    }
    printf("Connected to the database successfully.\n");

    // Prepare a statement
    const int8_t *query = (const int8_t *)"SELECT * FROM test_table";
    struct StatementHandle *stmt = rmysql_prepare(conn, query, &attribs, &error);
    if (stmt == NULL)
    {
        printf("Prepare statement error: %s\n", error.message);
        rmysql_disconnect(conn);
        return 1;
    }
    printf("Statement prepared successfully.\n");

    // Disconnect from the database
    rmysql_disconnect(conn);
    printf("Disconnected from the database successfully.\n");

    return 0;
}

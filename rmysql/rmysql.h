#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum ErrorCode {
  Success = 0,
  Utf8Error = 1,
  UrlError = 2,
  ConnectionError = 3,
  PrepareError = 4,
  TransactionError = 5,
} ErrorCode;

typedef struct ConnHandle ConnHandle;

typedef struct StatementHandle StatementHandle;

typedef struct Error {
  enum ErrorCode code;
  char message[256];
} Error;

typedef struct Attribs {
  bool debug;
} Attribs;

/**
 * Connect to a MySQL database
 *
 * # Safety
 * All input pointers must be valid C strings
 */
struct ConnHandle *rmysql_connect(const char *dsn,
                                  const char *user,
                                  const char *password,
                                  struct Error *error);

/**
 * Disconnect from a MySQL database
 * # Safety
 * The pointer must be valid
 */
void rmysql_disconnect(struct ConnHandle *conn);

/**
 * Prepare a statement
 * # Safety
 * All input pointers must be valid
 */
struct StatementHandle *rmysql_prepare(struct ConnHandle *conn,
                                       const char *query,
                                       const struct Attribs *_attribs,
                                       struct Error *error);

/**
 * free a statement
 */
void rmysql_statement_destroy(struct StatementHandle *statement);

/**
 * begin_work()
 */
bool rmysql_begin_work(struct ConnHandle *conn, struct Error *error);

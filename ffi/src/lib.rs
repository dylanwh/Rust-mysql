// expose the rust mysql crate as a C API

use std::ffi::{c_char, CStr};

use mysql::{params, prelude::Queryable, Conn, Opts, Statement};

use plbindgen_macros::{export, opaque, record};
use plbindgen_types::{array, string};


pub enum ErrorCode {
    NoError = 0,
    Utf8Error = 1,
    UrlError = 2,
    ConnectionError = 3,
    PrepareError = 4,
    TransactionError = 5,
}

#[record]
pub struct Error {
    code: ErrorCode,
    message: [c_char; 256],
}

#[opaque]
pub struct RustMysqlConn {
    conn: Conn,
    txn: Option<mysql::Transaction<'static>>,
}

#[allow(dead_code)]
#[opaque]
pub struct RustMysqlStatement(Statement);

/// Connect to a MySQL database
///
/// # Safety
/// All input pointers must be valid C strings
#[export]
unsafe fn rust_mysql_connect(
    dsn: string,
    user: string,
    password: string,
    error: *mut Error,
) -> *mut RustMysqlConn {
    use ErrorCode::*;

    if error.is_null() {
        eprintln!("in rust_mysql_connect, error is null");
        return std::ptr::null_mut();
    }

    let Some(dsn) = Utf8Error.check(CStr::from_ptr(dsn).to_str(), error) else {
        return std::ptr::null_mut();
    };
    let Some(user) = Utf8Error.check(CStr::from_ptr(user).to_str(), error) else {
        return std::ptr::null_mut();
    };
    let Some(password) = Utf8Error.check(CStr::from_ptr(password).to_str(), error) else {
        return std::ptr::null_mut();
    };

    let url = dsn_to_url(dsn, user, password);
    let Some(opts) = UrlError.check(Opts::from_url(&url), error) else {
        return std::ptr::null_mut();
    };
    let Some(conn) = ConnectionError.check(Conn::new(opts), error) else {
        return std::ptr::null_mut();
    };

    Box::into_raw(Box::new(RustMysqlConn { conn, txn: None }))
}

/// Disconnect from a MySQL database
/// # Safety
/// The pointer must be valid
#[export]
unsafe fn rust_mysql_disconnect(conn: *mut RustMysqlConn) {
    if !conn.is_null() {
        let ptr = Box::from_raw(conn);
        let RustMysqlConn { conn, txn } = *ptr;
        drop(txn);
        drop(conn);
    }
}

/// Prepare a statement
/// # Safety
/// All input pointers must be valid
#[export]
unsafe fn rust_mysql_prepare(
    conn: *mut RustMysqlConn,
    query: string,
    error: *mut Error,
) -> *mut RustMysqlStatement {
    use ErrorCode::*;

    if error.is_null() {
        eprintln!("in rust_mysql_prepare, error is null");
        return std::ptr::null_mut();
    }

    let Some(RustMysqlConn { conn, txn: _ }) = conn.as_mut() else {
        ConnectionError.set(error, "null pointer");
        return std::ptr::null_mut();
    };
    let Some(query) = Utf8Error.check(CStr::from_ptr(query).to_str(), error) else {
        return std::ptr::null_mut();
    };

    let Some(statement) = PrepareError.check(conn.prep(query), error) else {
        return std::ptr::null_mut();
    };

    Box::into_raw(Box::new(RustMysqlStatement(statement)))
}

/// Execute a statement
/// # Safety
/// All input pointers must be valid
#[export]
unsafe fn rust_mysql_execute(
    sth: *mut RustMysqlStatement,
    params: array<string>,
    params_len: usize,
    error: *mut Error,
){
    let x = params;
    println!("{:?}", x);

    todo!()
}

/// free a statement
///
/// # Safety
/// The pointer must be valid and must not be used after this function is called
#[export]
unsafe fn rust_mysql_statement_destroy(statement: *mut RustMysqlStatement) {
    if !statement.is_null() {
        drop(Box::from_raw(statement));
    }
}

impl ErrorCode {
    fn set(self, error: *mut Error, message: &str) {
        let message = message.as_bytes();
        let message = message.iter().map(|&b| b as c_char).collect::<Vec<_>>();
        let message = message.as_slice();
        unsafe {
            (*error).code = self;
            (*error).message[..message.len()].copy_from_slice(message);
        }
    }

    fn check<T, E>(self, result: Result<T, E>, error: *mut Error) -> Option<T>
    where
        E: std::fmt::Display,
    {
        match result {
            Ok(value) => Some(value),
            Err(e) => {
                self.set(error, &format!("{}", e));
                None
            }
        }
    }
}

/// begin_work()
/// # Safety
/// When calling this method, the connection must be a pointer returned by rust_mysql_connect
#[export]
unsafe fn rust_mysql_begin_work(
    conn: *mut RustMysqlConn,
    error: *mut Error,
) -> bool {
    use ErrorCode::*;

    if error.is_null() {
        eprintln!("in rust_mysql_rollback, error is null");
        return false;
    }

    let Some(ch) = conn.as_mut() else {
        TransactionError.set(error, "null pointer");
        return false;
    };
    let txn_opts = mysql::TxOpts::default();
    let Some(txn) = TransactionError.check(ch.conn.start_transaction(txn_opts), error) else {
        return false;
    };
    ch.txn.replace(txn);

    true
}

/// commit()
/// # Safety
/// When calling this method, the connection must be a pointer returned by rust_mysql_connect
#[export]
unsafe fn rust_mysql_commit(conn: *mut RustMysqlConn, error: *mut Error) -> bool {
    use ErrorCode::*;

    if error.is_null() {
        eprintln!("in rust_mysql_commit, error is null");
        return false;
    }

    let Some(ch) = conn.as_mut() else {
        TransactionError.set(error, "null pointer");
        return false;
    };
    let Some(txn) = ch.txn.take() else {
        TransactionError.set(error, "no transaction");
        return false;
    };
    TransactionError.check(txn.commit(), error).is_some()
}

/// rollback()
/// # Safety
/// When calling this method, the connection must be a pointer returned by rust_mysql_connect
#[export]
unsafe fn rust_mysql_rollback(conn: *mut RustMysqlConn, error: *mut Error) -> bool {
    use ErrorCode::*;

    if error.is_null() {
        eprintln!("in rust_mysql_rollback, error is null");
        return false;
    }

    let Some(ch) = conn.as_mut() else {
        TransactionError.set(error, "null pointer");
        return false;
    };
    let Some(txn) = ch.txn.take() else {
        TransactionError.set(error, "no transaction");
        return false;
    };
    TransactionError.check(txn.rollback(), error).is_some()
}

/// in_transaction()
/// # Safety
/// When calling this method, the connection must be a pointer returned by rust_mysql_connect
#[export]
unsafe fn rust_mysql_in_transaction(conn: *mut RustMysqlConn) -> bool {
    conn.as_ref().map_or(false, |ch| ch.txn.is_some())
}

#[allow(unused)]
fn dsn_to_url(dsn: &str, user: &str, password: &str) -> String {
    let dsn = dsn.strip_prefix("dbi:rust_mysql:").unwrap_or(dsn);
    let mut database = None;
    let mut host = "localhost";
    let mut port = None;
    let mut pairs = String::new();
    for pair in dsn.split(';') {
        if let Some((key, value)) = pair.split_once('=') {
            match key {
                "database" => {
                    database.replace(value);
                }
                "host" => {
                    host = value;
                }
                "port" => {
                    port.replace(value);
                }
                _ if pairs.is_empty() => {
                    pairs.push('?');
                    pairs.push_str(pair);
                }
                _ => {
                    pairs.push('&');
                    pairs.push_str(pair);
                }
            }
        }
    }

    let opt_port = port.map(|port| format!(":{}", port)).unwrap_or_default();
    let opt_database = database
        .map(|database| format!("/{}", database))
        .unwrap_or_default();
    let s = format!("mysql://{user}:{password}@{host}{opt_port}{opt_database}{pairs}");
    s
}

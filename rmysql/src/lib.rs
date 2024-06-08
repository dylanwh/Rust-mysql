// expose the rust mysql crate as a C API

use std::ffi::CStr;

use mysql::{Conn, Opts};

// a C enum for error codes
#[repr(C)]
pub enum ErrorCode {
    Success = 0,
    Utf8Error = 1,
    UrlError = 2,
    ConnectionError = 3,
    PrepareError = 4,
}

// a structure with an error code and a message
#[repr(C)]
pub struct Error {
    code: ErrorCode,
    message: [i8; 256],
}

/// Connect to a MySQL database
///
/// # Safety
/// All input pointers must be valid C strings
#[no_mangle]
pub unsafe extern "C" fn rmysql_connect(
    dsn: *const i8,
    user: *const i8,
    password: *const i8,
    error: *mut Error,
) -> *mut Conn {
    use ErrorCode::*;

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

    Box::into_raw(Box::new(conn))
}

/// Disconnect from a MySQL database
/// # Safety
/// The pointer must be valid
#[no_mangle]
pub unsafe extern "C" fn rmysql_disconnect(conn: *mut Conn) {
    if !conn.is_null() {
        let _ = Box::from_raw(conn);
    }
}


impl ErrorCode {
    fn check<T, E>(self, result: Result<T, E>, error: *mut Error) -> Option<T>
    where
        E: std::fmt::Display,
    {
        match result {
            Ok(value) => Some(value),
            Err(e) => {
                let message = format!("{}", e);
                let message = message.as_bytes();
                let message = message.iter().map(|&b| b as i8).collect::<Vec<_>>();
                let message = message.as_slice();
                unsafe {
                    (*error).code = self;
                    (*error).message[..message.len()].copy_from_slice(message);
                }
                None
            }
        }
    }
}

#[allow(unused)]
fn dsn_to_url(dsn: &str, user: &str, password: &str) -> String {
    let dsn = dsn.strip_prefix("dbi:rmysql:").unwrap_or(dsn);
    format!("mysql://{}:{}@{}", user, password, dsn)
}

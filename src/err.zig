// NENE by Alyx Shang.
// Licensed under the FSL v1.

// An entity to encapsulate
// all possible errors that
// could occur.
pub const NeneErr = error {
    AllocErr,
    NoValueErr,
    UnexpectedChar,
    UnexepctedToken,
    UnknownNumberPattern,
    UnexepectedTokenStreamEnd
};

// NENE by Alyx Shang.
// Licensed under the FSL v1.

/// A data structure to catch
/// and handle errors in this
/// library.
pub const NeneErr = error {
    AllocErr,
    WriteErr,
    NoValueErr,
    ParseIntErr,
    ParseFloatErr,
    WrongNodeTypeErr,
    UnexpectedTokenErr,
    UnexpectedCharacter,
    UnexpectedEndOfStream,
    UnexpectedNumberFormatErr
};

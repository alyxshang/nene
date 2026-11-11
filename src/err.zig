// NENE by Alyx Shang.
// Licensed under the FSL v1.

/// A data structure to catch
/// and handle errors.
pub const NeneErr = error {
    WriteErr,
    AllocErr,
    UnexpectedCharacterErr
};

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title A simple name registry.
/// @author Thomas den Hollander
/// @notice Enables users to register names. Names can be claimed by one
///     address simultaneously.
contract SimpleRegistry {
    error NameAlreadyClaimed();
    error NotTheOwner();

    /// @notice This is where the owner of an entry is stored.
    ///
    ///     The mapping of an address to a name in the registry is one-to-many,
    ///     which is why it makes sense to map from names to owners instead of vice
    ///     versa.
    ///
    ///     The zero address means there currently is no owner.
    /// @return owners The owner of the given name.
    mapping (string => address) public owners;

    /// @notice Claim the provided name for the function caller, if the name is
    ///     still available. This function will revert with a
    ///     `NameAlreadyClaimed` error otherwise.
    /// @param name The name to claim.
    function claimName(string calldata name) external {
        if (owners[name] == address(0)) {
            // Otherwise, claim the name.
            owners[name] = msg.sender;
        } else {
            // Revert if the name has already been claimed.
            revert NameAlreadyClaimed();
        } 
    }

    /// @notice Release a name. This removes the caller as the name owner so
    ///     the name can again be claimed by any other user. This function
    ///     reverts with a `NotTheOwner` error if the name does not belong to
    ///     the user--either because the name is unclaimed or because there is
    ///     another owner.
    /// @param name The name to make available again.
    function releaseName(string calldata name) external {
        if (owners[name] == msg.sender) {
            // If the caller is also the owner, return the name by deleting the
            // owner from the mapping.
            delete owners[name];
        } else {
            // Otherwise, revert with an error.
            revert NotTheOwner();
        }
    }
}
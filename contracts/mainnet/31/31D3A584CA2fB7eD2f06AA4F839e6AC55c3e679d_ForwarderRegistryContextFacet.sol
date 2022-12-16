// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC2771} from "./../interfaces/IERC2771.sol";
import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";

/// @title Meta-Transactions Forwarder Registry Context (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
contract ForwarderRegistryContextFacet is IERC2771 {
    IForwarderRegistry public immutable forwarderRegistry;

    constructor(IForwarderRegistry forwarderRegistry_) {
        forwarderRegistry = forwarderRegistry_;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == address(forwarderRegistry);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Secure Protocol for Native Meta Transactions.
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
interface IERC2771 {
    /// @notice Checks whether a forwarder is trusted.
    /// @param forwarder The forwarder to check.
    /// @return isTrusted True if `forwarder` is trusted, false if not.
    function isTrustedForwarder(address forwarder) external view returns (bool isTrusted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as an approved meta-transaction forwarder for a sender account.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return isApproved True if `forwarder` is an approved meta-transaction forwarder for `sender`, false otherwise.
    function isApprovedForwarder(address sender, address forwarder) external view returns (bool isApproved);
}
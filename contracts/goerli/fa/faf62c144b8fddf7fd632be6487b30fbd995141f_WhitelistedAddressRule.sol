// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * User-defined contract which return a boolean (is allowed) and an address (destination)
 * if returned address is 0x0 then the dest param is used as destination
 */
interface Rule {
    function exec(uint256 ownershipId, address forwarder, address token, uint256 id, uint256 value, address dest)
        external
        view
        returns (bool, address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Rule.sol";

contract WhitelistedAddressRule is Rule {
    address public immutable value;

    constructor(address _value) {
        value = _value;
    }

    function exec(uint256 _ownershipId, address _forwarder, address _token, uint256 _id, uint256 _value, address dest)
        external
        view
        override
        returns (bool, address)
    {
        return (dest == value, dest);
    }
}
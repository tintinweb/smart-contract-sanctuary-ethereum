// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * User-defined contract which return a boolean (is allowed) and an address (destination)
 * if returned address is 0x0 then the dest param is used as destination
 */
interface Rule {
    function execERC20(uint256 ownershipId, address forwarder, address token, uint256 value, address dest)
        external
        view
        returns (address, uint256);

    function execERC721(uint256 ownershipId, address forwarder, address token, uint256 id, address dest)
        external
        view
        returns (address);

    function execERC1155(uint256 ownershipId, address forwarder, address token, uint256 id, uint256 value, address dest)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Rule.sol";

contract WhitelistedAddressRule is Rule {
    address public immutable value;

    constructor(address _value) {
        value = _value;
    }

    function execERC20(uint256 ownershipId, address forwarder, address token, uint256 _value, address dest)
        external
        view
        override
        returns (address, uint256)
    {
        require(dest == value, "Dest");
        return (dest, _value);
    }

    function execERC721(uint256 ownershipId, address forwarder, address token, uint256 id, address dest)
        external
        view
        override
        returns (address)
    {
        require(dest == value, "Dest");
        return (dest);
    }

    function execERC1155(
        uint256 ownershipId,
        address forwarder,
        address token,
        uint256 id,
        uint256 _value,
        address dest
    ) external view returns (address, uint256) {
        require(dest == value, "Dest");
        return (dest, _value);
    }
}
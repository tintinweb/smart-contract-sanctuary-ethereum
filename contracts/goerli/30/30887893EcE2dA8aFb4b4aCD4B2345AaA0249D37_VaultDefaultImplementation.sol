pragma solidity 0.8.10;

interface IFactory {
    function ownerOfVault(address _vault) external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFactory} from "../../../IFactory.sol";

contract Constants {
    // ERC721
    IFactory public immutable factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }
}

contract Record is Constants {
    constructor(address _factory) Constants(_factory) {}

    /**
     * @dev Check for Auth if enabled.
     * @param user address/user/owner.
     */
    function isAuth(address user) public view returns (bool) {
        return factory.ownerOfVault(address(this)) == user;
    }

    /**
     * @dev ERC721 token receiver
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return 0x150b7a02; // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }

    /**
     * @dev ERC1155 token receiver
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external returns (bytes4) {
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    /**
     * @dev ERC1155 token receiver
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4) {
        return 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

contract VaultDefaultImplementation is Record {
    constructor(address _factory) Record(_factory) {}

    receive() external payable {}
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/// @author Dmytro Pintak <[email protected]>
/// @title Rule interface, can be implemented by any contract to be used as a rule in Traffic.sol contract
interface Rule {
    /// @notice Used to validate coin forwarding, example: ETH
    /// @param ownershipId - id of the ownership NFT
    /// @param forwarder - receiving address/contract
    /// @param value - amount of coins
    /// @param dest - destination address, where coins will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev You can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of coins, that will be sent
    /// @dev You can return different amount of coins, than the one passed as a parameter to override amount of coins that will be sent
    function exec(uint256 ownershipId, address forwarder, uint256 value, address dest)
        external
        view
        returns (address, uint256);

    /// @notice Used to validate ERC20 tokens forwarding
    /// @param ownershipId - id of the ownership NFT
    /// @param forwarder - receiving address/contract
    /// @param token - address of ER20 tokens smart contract
    /// @param value - amount of tokens
    /// @param dest - destination address, where tokens will be sent
    /// @return address - destination address, where tokens will be sent
    /// @dev You can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of tokens, that will be sent
    /// @dev You can return different amount of tokens, than the one passed as a parameter to override amount of coins that will be sent
    function execERC20(uint256 ownershipId, address forwarder, address token, uint256 value, address dest)
        external
        view
        returns (address, uint256);

    /// @notice Used to validate ERC721 tokens forwarding
    /// @param ownershipId - id of the ownership nft
    /// @param forwarder - receiving address/contract
    /// @param token - address of ERC721 tokens smart contract
    /// @param id - token id
    /// @param dest - destination address, where token will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev you can return different address, than the one passed as a parameter to override destination address
    function execERC721(uint256 ownershipId, address forwarder, address token, uint256 id, address dest)
        external
        view
        returns (address);

    /// @notice Used to validate ERC1155 tokens forwarding
    /// @param ownershipId - id of the ownership nft
    /// @param forwarder - receiving address/contract
    /// @param token - address of ERC1155 tokens smart contract
    /// @param id - token id
    /// @param value - amount of tokens
    /// @param dest - destination address, where token will be sent
    /// @return address - destination address, where coins will be sent
    /// @dev you can return different address, than the one passed as a parameter to override destination address
    /// @return uint256 - amount of tokens, that will be sent
    /// @dev You can return different amount of tokens, than the one passed as a parameter to override amount of coins that will be sent
    function execERC1155(uint256 ownershipId, address forwarder, address token, uint256 id, uint256 value, address dest)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Rule} from "./Rule.sol";

/// @author Dmytro Pintak <[email protected]>
/// @title Rule contract, that allows to forward coins only to whitelisted address
contract WhitelistedAddressRule is Rule {
    address public immutable whitelisted;

    constructor(address _whitelisted) {
        whitelisted = _whitelisted;
    }

    /// @inheritdoc Rule
    function exec(uint256, address, uint256 value, address dest) external view override returns (address, uint256) {
        if (dest == address(0x0)) {
            return (whitelisted, value);
        }
        require(dest == whitelisted, "Dest");
        return (dest, value);
    }

    /// @inheritdoc Rule
    function execERC20(uint256, address, address, uint256 value, address dest)
        external
        view
        override
        returns (address, uint256)
    {
        if (dest == address(0x0)) {
            return (whitelisted, value);
        }
        require(dest == whitelisted, "Dest");
        return (dest, value);
    }

    /// @inheritdoc Rule
    function execERC721(uint256, address, address, uint256, address dest) external view override returns (address) {
        if (dest == address(0x0)) {
            return whitelisted;
        }
        require(dest == whitelisted, "Dest");
        return (dest);
    }

    /// @inheritdoc Rule
    function execERC1155(uint256, address, address, uint256, uint256 value, address dest)
        external
        view
        returns (address, uint256)
    {
        if (dest == address(0x0)) {
            return (whitelisted, value);
        }
        require(dest == whitelisted, "Dest");
        return (dest, value);
    }
}
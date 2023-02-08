// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Distributor {
    function distributeERC20(
        IERC20 erc20Contract,
        address[] calldata to,
        uint256[] calldata tokenId
    ) public {
        uint256 length = to.length;
        for (uint256 i; i < length; ) {
            erc20Contract.transferFrom(msg.sender, to[i], tokenId[i]);
            unchecked {
                ++i;
            }
        }
    }

    function distributeERC721(
        IERC721 erc721Contract,
        address[] calldata to,
        uint256[] calldata tokenId
    ) public {
        uint256 length = to.length;
        for (uint256 i; i < length; ) {
            erc721Contract.transferFrom(msg.sender, to[i], tokenId[i]);
            unchecked {
                ++i;
            }
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//import '@openzeppelin/contracts/access/Ownable.sol';

contract Clone {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    uint256 tokenId = 1;

    function assignTokens(address[] calldata addresses) external {
        unchecked {
            for (uint256 i; i < addresses.length; i++) {
                emit Transfer(address(0), addresses[i], tokenId++);
            }
        }
    }
}
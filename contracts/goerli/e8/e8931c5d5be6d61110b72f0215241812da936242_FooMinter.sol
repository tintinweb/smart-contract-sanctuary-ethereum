/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//Oh hey there!

interface IERC721 {
    function FOOFIGHTER_mint() external;

    function totalSupply() external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract FooMinter {

    IERC721 fooContract = IERC721(0x9490165195503fcF6A0FD20aC113223fEfb66eD5);

    function FooMassMint(uint256 _number) external {

        uint256 position = uint256(fooContract.totalSupply() - 1);

        for (uint256 i = 0; i < _number; i++) {
            fooContract.FOOFIGHTER_mint();
            position++;
            fooContract.safeTransferFrom(address(this), msg.sender, position);
        }
    }
}
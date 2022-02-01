// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    string _nameOfToken = "TokenA";
    uint256 _tokenId;
    bool _didThePublicMintStartYet = false; // This will be opened by the admin
    address[500] _AllowListAddress; //There is 500 allowed list slots

}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

import "./myERC20.sol";


//contract MyToken is ERC20{
contract MyToken is myERC20{

    address public owner;

//    constructor(string memory name, string memory symbol) ERC20(name,symbol){
   constructor(string memory name, string memory symbol) myERC20(name,symbol){
        owner = msg.sender;
        // mint 1000 token
 //       _mint(msg.sender, 1234*10**uint(decimals()));
    }

    // Mint token to the owner
//    function mint(uint mint_amount) public {
    function mint(uint mint_amount) public {
        require(msg.sender == owner);
        _mint(msg.sender, mint_amount*10**uint(decimals()));
    }

    // Mint token to anyone who asks
    function mintTo(address to, uint mint_amount) public {
        require(msg.sender == owner);
        _mint(to, mint_amount*10**uint(decimals()) );
    }

}
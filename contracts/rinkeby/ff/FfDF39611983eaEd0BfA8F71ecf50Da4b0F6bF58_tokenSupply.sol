// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC20.sol";
import "./Ownable.sol";
contract tokenSupply is ERC20 , Ownable{
   
    constructor (uint tokenSupply_ ) ERC20("RPay" , "RP"){
        _mint(msg.sender, tokenSupply_ * 10 ** 18 );  
    }
     function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";


contract PetWalk is ERC20, Ownable{

    address private _simpleAddr;       

    function setSimpleAddr(address newAddr) public onlyOwner{
        _simpleAddr = newAddr;            
    }

    function getSimpleAddr() public view virtual returns(address){
        return _simpleAddr;                 
    }


    function transferToAddr(uint256 amount) public virtual returns (bool) {         
        address owner = _msgSender();
        _transfer(owner, _simpleAddr, amount);
        return true;
    }



    constructor(uint256 initialSupply) ERC20("PetWalk", "PW") {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
        _simpleAddr = msg.sender;
    }


}
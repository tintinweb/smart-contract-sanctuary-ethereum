/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: Eboos

abstract contract  Eboos  {
//    function mint(address to ) public ;
    function premint(uint256 quantity) virtual external payable ;
    function getPrice() public virtual view returns (uint256);
}

// File: CallContract.sol

contract CallContract {

    address public eboos_addr = 0x956d8Ca6511B59d3AC8A3156A9168f49a6aba938;
    Eboos public eboo;
    //0x76FeC53340eEb0B4FCDE5491C778Db80b012B370

    constructor() public{
        eboo = Eboos(eboos_addr);
    }
    function mintfrom() payable  public  {
        eboo.premint{value:0.015 ether}(1);
    }
    function getPrice() public view returns (uint256){
        return eboo.getPrice();
    }

    function deposit() public payable{
    }

}
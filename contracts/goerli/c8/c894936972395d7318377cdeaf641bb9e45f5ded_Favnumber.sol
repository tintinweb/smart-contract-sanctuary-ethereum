/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

contract Favnumber {
    mapping (address => uint) favourites;
    mapping (address => uint) hesitations;
    function getFavourite(address _address) public view returns(uint){
        return favourites[_address];
    }        
    
    function setFavourite(address _address, uint _fav) public {
        require(msg.sender == _address);
        favourites[_address]=_fav;
        hesitations[_address]++;
    }

    function getHesitation(address _address) public view returns(uint) {
        return hesitations[_address];
    } 

}
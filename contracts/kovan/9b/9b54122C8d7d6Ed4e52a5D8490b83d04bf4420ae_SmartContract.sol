/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SmartContract
{
    uint256 number;
    bool onay;
    string str;
    address adrs;

    function store_number(uint256 _number)public 
    {
        number = _number;
    }
    
    function retrive_number()public view returns(uint256)
    {
        return number;
    } 
    
    function store_onay(bool _onay)public 
    {
        onay = _onay;
    }
    
    function retrive_onay()public view returns(bool)
    {
        return onay;
    } 

    function store_str(string memory _str)public
    {
        str = _str;
    }

    function retrive_str()public view returns(string memory)
    {
        return str;
    }
    
    function store_address(address _adrs)public
    {
        adrs = _adrs;
    }
    
    function retrive_address()public view returns(address)
    {
        return adrs;
    }

  
    
}
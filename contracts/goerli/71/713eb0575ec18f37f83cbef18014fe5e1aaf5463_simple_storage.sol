/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

//simple storage

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract simple_storage{
    string private value;

    event UpdateData(address uploader,string data);

    function setValue(string memory _value) public{
        value=_value;
        emit UpdateData(msg.sender,_value);
    }
    function showValue() public view returns(string memory){
        return value;
        
    }
}
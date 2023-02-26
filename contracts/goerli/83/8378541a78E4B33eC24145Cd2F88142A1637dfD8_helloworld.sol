/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 *  @title helloworld
 *
 *  @dev helloworld contract
 */
contract helloworld {

    //测试string变量
    string name;

    /**
     *获取name
     */
    function get() public view returns (string memory){
        bytes memory _hello = "hello,";
        bytes memory _name = bytes(name);
        string memory _tmpValue = new string(_hello.length + _name.length);
        bytes memory _newValue = bytes(_tmpValue);
        uint i;
        uint j;
        for(i=0; i<_hello.length; i++) {
            _newValue[j++] = _hello[i];
        }
        for(i=0; i<_name.length; i++) {
            _newValue[j++] = _name[i];
        }
        return string(_newValue);
    }

    /**
     *设置name
     */
    function set(string memory _name) public{
        name = _name;
    }

    /**
     *获取全局变量msg.sender
     */
    function getSender() public view returns (address){
        return msg.sender;
    }

    /**
     *获取全局变量block.number
     */
    function getBlockNumber() public view returns (uint){
        return block.number;
    }

    
}
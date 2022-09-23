/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923

pragma solidity >=0.7.0 <0.8.2;

contract ContractAddress {
    
    string[] name;
    
    //이름 넣기
    function pushstring(string memory _name) public {
        name.push(_name);
    }
    //n번째 이름 찾기 , 길이 알아내기
    function getString(uint a) public view returns(string memory) {
        return name[a-1];
    }
    function getStringLenght() public view returns(uint) {
        return name.length;
    }

}
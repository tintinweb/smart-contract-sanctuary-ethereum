/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.4.24;
contract LVC {
    string public name;
    string public nickname;

    constructor() public {
        name = "我是一個智能合約！";
        nickname = "leonLu";
    }
    
    function setName(string _name) public {
        name = _name;
    }

    function setNickname(string _name) public {
        nickname = _name;
    }
}
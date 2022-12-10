// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract Temp1 {

    address public _sender;
    string public name;
    event Play(uint8 number,address _player,uint256 amount);

    constructor() {
        _sender=msg.sender;
    }

    function play(uint8 number) payable external{
        
        emit Play(number,msg.sender,msg.value);
    }

    function getVaultBalance() external view returns(uint256 bal){
        bal = address(this).balance;
    }

    function setName(string memory _name) external{
        name=_name;
    }

    function getName() view external returns(string memory){
        return name;
    }
}
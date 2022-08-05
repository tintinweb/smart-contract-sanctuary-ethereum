/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: ReciveEther.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract ReciveEther{
    string public callFunction;

    receive() external payable{
        callFunction = "recive";
    }
    fallback() external payable{
        callFunction = "fallback";
    }
    function gasBalance() public view returns(uint){
        return address(this).balance;

    }

}

contract SendEther{
    function  sendEtherTransfer(address payable _to) public payable{
        _to.transfer(msg.value);

    }
    function sendEtherSend(address payable _to) public payable returns(bool){
        bool sent=_to.send(msg.value);
        return sent;

    }

    function sendEtherCall(address payable _to) public payable returns(bool, bytes memory){
        (bool sent, bytes memory data) = _to.call{value: msg.value} ("HOLA");
        require(sent,"fallo la transaccion");
        return(sent,data);
    }


}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract TestContract{
    uint public number;
    address public owner;

    event getData(
        bytes data
    );

    function set() public payable{
        require(msg.value >= 1 ether,"Require more than One ETH");
        number = msg.value;
        owner = msg.sender;
    }


    function getSet() public  returns(bytes memory data){
        data = abi.encodeWithSignature("set()");
        emit getData(data);
    }
}
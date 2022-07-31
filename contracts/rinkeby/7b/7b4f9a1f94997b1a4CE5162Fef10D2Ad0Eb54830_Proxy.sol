/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
contract Storage{
    uint256 public number;

    function getNum() public view returns(uint256){
        return number;
    }
    function setNum(uint256 _newNum) public {
        number = _newNum;
    }
}

contract Proxy {
    address public logicContract;

    constructor(address _logic){
        logicContract = _logic;
    }

    function upgradeProxy(address _newAddress) public{
        logicContract = _newAddress;
    }


    function setNumCall(uint256 _num) public returns(bytes memory){
        (bool success,bytes memory data) = logicContract.delegatecall(abi.encodeWithSignature("setNumber(uint256)",_num));
        require(success,"Tx Failed"); 
        return(data);
    }

    function getNumCall() public  returns(bytes memory){
        (bool success,bytes memory data) = logicContract.delegatecall(abi.encodeWithSignature("getNumber()"));
        require(success,"Tx Failed"); 
        return(data);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract DeployContractUsingContract{

    string name;
  

    constructor(string memory _name){
        name = _name;

    }

    function setName(string calldata _name)public {
        name = _name;
    }

    function getName() public view returns(string memory){
        return name;
    }

    function getContractAddress() public view returns(address){
        return address(this);
    }
    function killMe()public payable {
        selfdestruct(payable(msg.sender));
    }
}


//This contract deploy other contract
contract DeployContracts{
    DeployContractUsingContract deployedContract;

    function deployContract() public {
        deployedContract = new DeployContractUsingContract("Rohit");
    }

    function getContract() public view returns(address){
        return deployedContract.getContractAddress();
    }

    function getContractName() public view returns(string memory){
        return deployedContract.getName();
    }

     function killMe()public payable {
        selfdestruct(payable(msg.sender));
    }

}
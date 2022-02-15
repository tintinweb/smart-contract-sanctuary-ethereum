/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ENS {
    function setOwner(bytes32 node, address owner) external;
}


interface ETHRegistrarController {

    function owner() external view returns (address) ;

    function available(string memory name) external view returns(bool);

    function rentPrice(string memory name, uint duration) external view  returns(uint) ;

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) external pure  returns(bytes32) ;

    function commit(bytes32 commitment) external ;

    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable ;

}

contract MyRegister 
{    
    ENS ens;
    ETHRegistrarController controller;

     constructor (ETHRegistrarController _controller, ENS _ens) {
         controller=_controller;
         ens=_ens;
     }

     function getEnsAddress() public view returns(address){
         return address(ens);
     }

     function getControllerAddress() public view returns(address){
         return address(controller);
     }

    function getAvailable(string memory name) public view returns(bool){
         return controller.available(name);
    }

    //register ens
    function makeCommit(string memory name, address owner, bytes32 secret, address resolver, address addr) public {
        bytes32 commitment= controller.makeCommitmentWithConfig(name,owner, secret, resolver,addr) ;
        controller.commit(commitment);

    }
    //register ens
    function registerENS(string memory name, address owner, bytes32 secret, address resolver, address addr,uint duration) public payable{
        controller.registerWithConfig(name, owner,  duration, secret, resolver, addr);
    }

    function setNewOwner(bytes32 node, address owner) public{
        ens.setOwner(node, owner);
    }

    receive() external payable {
    }
}
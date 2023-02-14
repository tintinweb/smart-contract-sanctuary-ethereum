/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity ^0.8.0;

contract Child {
    function greet() public {

    }

}

contract Test {
    event TestEvent();
    address msgSeneder;
    uint256 someAmount;
    address admin;
    address somethingElse;

    modifier RandomModif() { require(1 == 1, "Bla Bla"); _; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }

    function test() public onlyOwner {
        emit TestEvent();
    }

    function _msgSender() public view returns(address) {
        return msgSeneder;
    }

    function owner() public view returns(address) {
        return admin;
    }

    function deployChild() public returns(Child){
        return new Child();
    }
}
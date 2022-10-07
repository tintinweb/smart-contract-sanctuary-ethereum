/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity 0.8.14;

contract escrow {
    address public partyB;
    address public partyA;

    function deposit(address _partyB) public payable{
        //require(msg.sender == partyA, "sender not partyA");
        partyA = msg.sender;
        partyB = _partyB;

    }

    function withdraw() public{
        require(msg.sender == partyB, "sender not partyB");
        payable(partyB).transfer(address(this).balance);
    }


}
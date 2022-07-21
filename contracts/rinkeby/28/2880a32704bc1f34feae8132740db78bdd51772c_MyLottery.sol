/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.17;

contract MyLottery {
    address public projectmanager;
    address[] public teammember;
    
    function Lottery() public {
        projectmanager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        teammember.push(msg.sender);
    }
    
    function random() public view returns (uint) {
        return uint(keccak256(block.difficulty, now, teammember.length));
    }
    
    function pickWinner() public restricted {
        uint index = random() % teammember.length;
        teammember[index].transfer(this.balance);
        teammember = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == projectmanager);
        _;
    }
    
    function getteammember() public view returns (address[]) {
        return teammember;
    }
}
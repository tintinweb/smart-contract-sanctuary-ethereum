/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

pragma solidity ^0.8.9;

contract Lottery {

    address public manager;
    address payable[] public players;
    string public number;



    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);//msg.value must be in wei so .01 ether would be converted to wei
        players.push(payable(msg.sender));
    }

    function playersList() public view returns(address payable[] memory) {
        return players;
    }

    function playersLength() public view returns(uint) {
        return players.length;
    }

    function random() public view returns(uint) {//should be private but public to test in Remix
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));//keccak256 will return the hash so need to convert to uint
    }

    function balanceOfContract() public view returns(uint) {
        return address(this).balance;//balance will be return in wei
    }

    function pickWinner() public restricted{
        //require(msg.sender == manager);//if modifier restricted marking no need this line
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);//reset the players list after transfer all balance to winner, 0 means initialize with 0 length, nothing inside
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

}
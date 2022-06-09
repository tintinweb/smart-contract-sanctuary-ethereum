/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Lottory{
    address owner=msg.sender;
    uint256 betSize=0;
    uint256 totalPrize=0;
    address[] player;

    function startLottery(uint256 _betSize) public {
        require(msg.sender==owner, "You don't have permission to access.");
        require(betSize==0, "End the current round to start a new one.");
        require(_betSize!=0, "The bet size can't be 0.");
        betSize=_betSize;
    }
    function lookUp() public view returns (uint256 bet_size, uint256 player_amount){
        require(betSize!=0, "No round is on.");
        return (betSize, player.length);
    }
    function enter() public payable{
        require(betSize!=0, "No round is on.");
        require(msg.value==betSize, "The bet size is illegal.");
        player.push(msg.sender);
        totalPrize=totalPrize+betSize;
        return;
    }
    function endLottery() public payable{
        require(msg.sender==owner, "You don't have permission to access.");
        require(betSize!=0, "No round is on.");
        uint256 indexOfWinner=uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp)))%player.length;
        (bool send,)=player[indexOfWinner].call{value: totalPrize}("");
        require(send,"Error.");
        betSize=0;
        totalPrize=0;
        delete player;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract lottery{
    address public organizer;
    address[] private players;
    mapping(address=>bool) alreadyParticipated;
    uint lotteryID=0;
    mapping (uint=>address) private winners;

    enum LOTTERY_STATE { OPEN, CLOSED}
    LOTTERY_STATE private lottery_state;

    constructor(){
        organizer=msg.sender;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function open_lottery() public onlyAdmin{
        lottery_state= LOTTERY_STATE.OPEN;
        lotteryID=lotteryID+1;
    }

    function enter() public payable isOpen{
        require(msg.value> .01 ether, "Minimum of 0.01 ETH required");
        require(alreadyParticipated[msg.sender]==false,"Address already participated");
        require(msg.sender!=organizer,"organizer cannot participate");
        alreadyParticipated[msg.sender]=true;
        players.push(msg.sender);

    }

    function resetPlayers() private{
        for (uint i=0; i<players.length; i++){
            alreadyParticipated[players[i]]=false;
        }
    }

    function randomize(string memory _seedPhrase) private view returns (uint){
      return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players, _seedPhrase)));
    }

    function pickWinner(string memory _seedPhrase) public onlyAdmin isOpen{
        require(bytes(_seedPhrase).length!=0, "Must enter SeedPhrase");
        uint index= randomize(_seedPhrase) % players.length;
        winners[lotteryID]=players[index];
        payable(organizer).transfer((address(this).balance)/40);
        payable(players[index]).transfer(address(this).balance);
        resetPlayers();
        players= new address[](0);
        lottery_state=LOTTERY_STATE.CLOSED;

        
    }

function getWinners(uint _lotteryid) public view returns (address){
    return winners[_lotteryid];
}

     function getPlayers() public view returns(address[] memory){
        return players;
    }

    modifier onlyAdmin() {
        require(msg.sender==organizer,"You're not the organizer");
        _;
    }

    modifier isOpen(){
        require(lottery_state==LOTTERY_STATE.OPEN, "Lottery is still closed");
        _;
    }

   
}
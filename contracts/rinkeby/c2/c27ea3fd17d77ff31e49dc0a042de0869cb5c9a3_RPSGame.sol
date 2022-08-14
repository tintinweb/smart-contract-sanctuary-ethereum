// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VRFv2Consumer.sol";

contract RPSGame  {
    enum RPS {
        rock, paper, scissors
    }

    mapping(address => uint) public stakeOf;
    mapping(RPS => address[]) public picking;
    uint private participants;
    VRFv2Consumer private consumerInstance;

    event matchResult(RPS indexed systemPick, RPS indexed winnerPick);

    constructor(address VRFaddress) {
        participants = 0;
        consumerInstance = VRFv2Consumer(VRFaddress);       
    }

    fallback() external payable {}
    receive() external payable {}

    function how2play()  public pure returns (string memory) {
        return "0 => rock,\n 1 => paper,\n 2 => scissors";
    }

    function enter(RPS pick) external payable {
        require(msg.value > 0.001 ether);
        require(stakeOf[msg.sender] == 0);
        stakeOf[msg.sender] = msg.value;
        picking[pick].push(msg.sender);
        participants += 1;
        if (participants >= 3)
            reveal();  
    }

    function reveal() public {
        RPS winnerPick;
        RPS tiePick;
        consumerInstance.requestRandomWords();
        uint256 randomWord = consumerInstance.s_randomWords(0);
        uint256 remainder = randomWord % 3;
        uint index;

        require(remainder < 4 && remainder >= 0);

        if(remainder == 0) {
            winnerPick = RPS.paper;
            tiePick = RPS.rock;   

        } else if (remainder == 1) {
            winnerPick = RPS.scissors;
            tiePick = RPS.paper;

        } else {
            winnerPick = RPS.rock;
            tiePick = RPS.scissors;

        }

        address[] storage winnerArray = picking[winnerPick];
        for(index = 0; index < winnerArray.length; index++) {
            address winnerAddress = winnerArray[index];
            payable(winnerAddress).transfer(2 * stakeOf[winnerAddress]);
            stakeOf[winnerAddress] = 0;
        }

        address[] storage tieArray = picking[tiePick];
        for(index = 0; index < tieArray.length; index++) {
            address tieAddress = tieArray[index];
            payable(tieAddress).transfer(stakeOf[tieAddress]);
            stakeOf[tieAddress] = 0;           
        }

        reset();

        emit matchResult(tiePick, winnerPick);
    } 

    function reset() private {
        address[] memory emptyArray;
        picking[RPS.rock] = emptyArray;
        picking[RPS.paper] = emptyArray;
        picking[RPS.scissors] = emptyArray;
        participants = 0;
    }

    function accessConsumer() public {
        consumerInstance.acceptOwnership();
    }
 
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract myGame{
    using SafeMath for uint;
    uint bet = 0.01 ether;
    event gameResult(address user,string userChoice,string dealerChoise,string result);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return (now % 3) + 1; //回傳 1,2,3
    }
    mapping(uint => string) choice;

    // item: 1: 剪刀(Scissors), 2: 石頭(Rock), 3: 布(Paper)
    // 內部使用，且完全沒用到 storage 所以回傳用 internal pure 
    function choice_str(uint item) internal pure returns(string) {
        if (item == 1) return "Scissors";
        if (item == 2) return "Rock";
        if (item == 3) return "Paper";
        return "invalid item";
    }

    // user: 1: 剪刀, 2: 石頭, 3: 布
    function play(uint userChoice) public payable returns(string){
        require(userChoice == 1 || userChoice == 2 || userChoice == 3, "invalid choice");
        require(msg.value == bet, "please pay 0.01 ETH");
        uint dealerChoise = get_random();
        string memory result; // 平手
        uint refund;  // 退錢
        if(dealerChoise == userChoice) {
            result = "tie"; // 平手
            refund = msg.value;  // 退回押注金
        } else if (
        (dealerChoise == 1 && userChoice == 2)  // dealer: 剪刀，user: 石頭
        || (dealerChoise == 2 && userChoice == 3)  // dealer: 石頭，user: 布
        || (dealerChoise == 3 && userChoice == 1)  // dealer: 布，user: 剪刀
        ) {
            result = "win";
            refund = msg.value.mul(2);  // 退兩倍
        } else {
            result = "lost";
            refund = 0;  // 不退回
        }
        

        if(refund > 0){
            // 退回玩家錢
            msg.sender.transfer(refund);
        }
        // 遊戲需要記錄
        emit gameResult(msg.sender, choice_str(userChoice), choice_str(dealerChoise), result);
        return result;
    }

    function () public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 0.01 ether, "please pay 0.01 ETH");
    }
}
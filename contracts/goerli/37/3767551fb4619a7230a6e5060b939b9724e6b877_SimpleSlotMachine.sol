pragma solidity 0.8.13;

contract SimpleSlotMachine {

    mapping(address => uint256) public playerBetList;



    constructor() {

    }



    function placeBet() public payable returns (bool) { // need to add non-reentrancy guard
        uint256 betAmount = msg.value;

        require(betAmount > 0);

        uint256 randomValue = random();
        uint256 contractBalance = address(this).balance;
        // playerBetList[msg.sender] = betAmount;

        // below triggered if user wins bet
        if (randomValue > 50) {
            uint256 winAmount = betAmount * 2;

            if (contractBalance < winAmount) {
                winAmount = contractBalance;
            }



            payable(msg.sender).transfer(winAmount);

            contractBalance = address(this).balance;
        }

        return true;

    }

    function random() public view returns (uint8) {
        return uint8(uint256(keccak256(abi.encode(block.timestamp))) % 100) + 1; // 1 ~ 100 (Only for testing.)
    }

    receive() external payable {}

    // function start() public payable {
    //     uint256 userBalance = msg.value;

    //     require(userBalance > 0);

    //     uint256 randomValue = random();

    //     playerList[msg.sender] = randomValue;

    //     contractBalance = address(this).balance;

    //     if (randomValue > 50) {
    //         uint256 winBalance = userBalance * 2;

    //         if (contractBalance < winBalance) {
    //             winBalance = contractBalance;
    //         }

    //         msg.sender.transfer(winBalance);

    //         contractBalance = address(this).balance;
    //     }
    // }


}


// contract SlotMachine {
//     mapping(address => uint256) public playerList;

//     uint256 public contractBalance;

//     function SlotMachine() public {}

//     function() public payable {
//         start();
//     }

//     function start() public payable {
//         uint256 userBalance = msg.value;

//         require(userBalance > 0);

//         uint256 randomValue = random();

//         playerList[msg.sender] = randomValue;

//         contractBalance = address(this).balance;

//         if (randomValue > 50) {
//             uint256 winBalance = userBalance * 2;

//             if (contractBalance < winBalance) {
//                 winBalance = contractBalance;
//             }

//             msg.sender.transfer(winBalance);

//             contractBalance = address(this).balance;
//         }
//     }

//     function random() view returns (uint8) {
//         return uint8(uint256(keccak256(block.timestamp)) % 100) + 1; // 1 ~ 100 (Only for testing.)
//     }
// }
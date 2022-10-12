// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./lib/DataStructure.sol";
import "./lib/Modifiers.sol";
import "./lib/Events.sol";

contract Lottery is DataStructure, Modifiers {
    constructor() {
        manager = msg.sender;
    }

    function openLottery(
        uint256 _openTime,
        uint256 _closeTime,
        uint256 _lotteryPrice
    ) public onlyManager {
        openTime = _openTime;
        closeTime = _closeTime;
        lotteryPrice = _lotteryPrice;
        isLotteryOpen = true;
        currentPool = 0;

        emit Events.lotteryOpened(_openTime, _closeTime, _lotteryPrice);
    }

    // Contract collecting the transfered amount......
    receive() external payable {}

    function applyLottery(uint256 appliedTime)
        public
        payable
        accountAlreadyExist(msg.sender)
    {
        require(appliedTime > openTime, "it's not started yet..");
        require(appliedTime < closeTime, "lottery ended...");
        require(msg.value == lotteryPrice, "fund is not sufficient...");
        require(
            msg.sender != manager,
            "manager cannot participate in lottery system...."
        );
        accountexists[msg.sender] = true;
        currentPool += lotteryPrice;

        participants.push(payable(msg.sender));
        emit Events.lotteryApplied(appliedTime, msg.sender);
        //  payable (address(this)).transfer(msg.value);
    }

    function closeLottery(uint256 currentTime) public onlyManager {
        require(currentTime > closeTime, "lottery is not ended yet ");
        

        uint256 r = generateRandomNumber();
        uint winnerIndex=r % participants.length;
        address winner=participants[winnerIndex];


        (uint256 winnerAmount, uint256 managerCommission) = fundSettlement(
            winner
        );

        withDrawableAmount += balanceOfContract();
        resetLottery();

        emit Events.amountTransfered(
            winner,
            winnerAmount,
            managerCommission
        );
    }

    function withDraw(address _receiver, uint256 _amount) public onlyManager {
        require(
            isLotteryOpen != true,
            "Cannot withdraw as lottery is running..."
        );

        require(
            _amount <= withDrawableAmount,
            "You Cannot withdraw that much amount"
        );

        payable(_receiver).transfer(_amount);
        withDrawableAmount -= _amount;
        emit Events.withDrawal(_receiver, _amount);
    }

    function balanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    function generateRandomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants.length
                    )
                )
            ) ;
    }

    function fundSettlement(address winner)
        private
        returns (uint256 winnerAmount, uint256 managerCommission)
    {
        winnerAmount = (67 * currentPool) / 100;
        managerCommission = (13 * currentPool) / 100;

        payable(winner).transfer(winnerAmount);
        payable(manager).transfer(managerCommission);
    }

    function resetLottery() private {
        participants = new address[](0);
        currentPool = 0;
        isLotteryOpen = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Events {
    event lotteryOpened(
        uint256 openTime,
        uint256 closeTime,
        uint256 lotteryPrice
    );

    event lotteryApplied(uint256 appliedTime,address participants);
    event amountTransfered(address winner, uint256 winnerAmount, uint256 managerAmount);
    event withDrawal(address _to, uint256 withDrawAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStructure.sol";

contract Modifiers is DataStructure {
    modifier onlyManager() {
        require(
            msg.sender == manager,
            "only Manager can call this function..."
        );_;
    }

    modifier accountAlreadyExist(address _addr) {
        require(
            accountexists[_addr] != true,
            "This account already participated in lottery..."
        );_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DataStructure {
    uint256 openTime;
    uint256 closeTime;
    uint256 lotteryPrice;
    uint256 currentTime;
    bool isLotteryOpen;
    uint256 public currentPool;
    uint256 public withDrawableAmount;

    address public manager;
    address[] public participants;

    mapping(address => uint256) public addressBalances;
    mapping(address => bool) public accountexists;
}
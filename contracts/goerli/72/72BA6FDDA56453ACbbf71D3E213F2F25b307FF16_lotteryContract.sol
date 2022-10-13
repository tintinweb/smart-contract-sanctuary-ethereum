//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./lotteryWinner.sol";

contract lotteryContract is lotteryWinner {
    constructor() {
        owner = msg.sender;
    }

    // method to issue a lottery
    function openLottery(
        uint256 _lotteryNumber,
        uint256 _lotteryPrice,
        uint256 _openTime,
        uint256 _closeTime
    ) public isPreviousLotteryClosed {
        lottery[_lotteryNumber] = lotteryInfo(
            _lotteryPrice,
            _openTime,
            _closeTime,
            true,
            false
        );
        lotteryNumber = _lotteryNumber;
        emit lotteryOpenEvent(_openTime, _closeTime, _lotteryPrice);
    }

    // method to apply issued lottery
    function applyLottery(uint256 _appliedTime)
        public
        payable
        validateTimeForUser(_appliedTime)
        isAlreadyApplied
    {
        require(msg.sender != owner, "Owner can't participate");
        require(
            msg.value == lottery[lotteryNumber].lotteryPrice,
            "paid balance is greater or less than lottery price"
        );
        participant.push(msg.sender);
        applied[msg.sender] = true;
        lotteryPool = lotteryPool + msg.value;
        emit lotteryApplyEvent(_appliedTime);
    }

    //method to get contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //method to get current lottery Information
    function getLotteryInfo(uint256 _lotteryNumber)
        public
        view
        returns (lotteryInfo memory)
    {
        lotteryInfo memory returnData = lotteryInfo(
            lottery[_lotteryNumber].lotteryPrice,
            lottery[_lotteryNumber].openTime,
            lottery[_lotteryNumber].closeTime,
            lottery[_lotteryNumber].isOpen,
            lottery[_lotteryNumber].isWinnerSelected
        );
        return returnData;
    }

    // method to get current lottery participants
    function getLotteryParticipants() public view returns (address[] memory) {
        require(msg.sender == owner);
        address[] memory participantData = new address[](participant.length);
        for (uint256 i = 0; i < participant.length; i++) {
            participantData[i] = participant[i];
        }
        return participantData;
    }

    // method to close current lottery
    function closeLottery(uint256 _closingCallTime)
        public
        validateTimeForManager(_closingCallTime)
        isWinnerSelected
    {
        require(msg.sender == owner);
        // require(lottery[lotteryNumber].isWinnerSelected == true);
        lottery[lotteryNumber].isOpen = false;
        for (uint256 i = 0; i < participant.length; i++) {
            delete applied[participant[i]];
        }
        participant = new address[](0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./lib/contractData.sol";
import "./lib/events.sol";
import "./lib/Modifiers.sol";

contract lotteryWinner is contractData, events, Modifiers {
    function winningAmount() public view returns (uint256[2] memory) {
        uint256[2] memory prize;
        uint256 winnerAmount = (67 * lotteryPool) / 100;
        uint256 managerAmount = (13 * lotteryPool) / 100;
        prize[0] = winnerAmount;
        prize[1] = managerAmount;
        return (prize);
    }

    function randomNumberGenereator() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % (participant.length);
    }

    function selectWinner(uint256 _invokedTime)
        public
        validateTimeForManager(_invokedTime)
    {
        require(msg.sender == owner, "Unauthorized Access");
        uint256 winnerIndex = randomNumberGenereator();
        address winner = participant[winnerIndex];
        uint256[2] memory prize = winningAmount();
        (bool sentToWinner, ) = payable(winner).call{value: prize[1]}("");
        require(sentToWinner, "couldnot transfer amount to winner");
        (bool sentToManager, ) = payable(owner).call{value: prize[0]}("");
        require(sentToManager, "couldnot transfer amount to manager");
        lottery[lotteryNumber].isWinnerSelected = true;
        lottery[lotteryNumber].isOpen = false;
        emit transferredToWinner(winner, prize[1]);
        emit transferredToManager(owner, prize[0]);
        delete lotteryPool;
    }

    // modifier checkAmount(uint256 _amount) {
    // 	if (lotteryPool > 0) {
    // 		require(
    // 			(address(this).balance - _amount) >= lotteryPool,
    // 			"Invalid Amount: Affects the lottery pool amount"
    // 		);
    // 	} else {
    // 		require(
    // 			address(this).balance >= _amount,
    // 			"Invalid Amount: greater than available in contract"
    // 		);
    // 	}
    // 	_;
    // }

    function transferAmount(address _toAddress, uint256 _amount)
        public
        checkAmount(_amount)
    {
        require(msg.sender == owner);
        (bool sent, ) = payable(_toAddress).call{value: _amount}("");
        require(sent, "Transfering Amount Fails");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract contractData {
	address public owner;
	uint256 lotteryNumber;
	address[] participant;
	uint256 public lotteryPool;
	struct lotteryInfo {
		uint256 lotteryPrice;
		uint256 openTime;
		uint256 closeTime;
		bool isOpen;
		bool isWinnerSelected;
	}

	mapping(uint256 => lotteryInfo) lottery;
	mapping(address => bool) applied;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract events {
	event lotteryOpenEvent(uint256 _openTime, uint256 _closeTime, uint256 _price);
	event lotteryApplyEvent(
		uint256 _appliedTime
	);
	event transferredToWinner(address _winnerAddress, uint256 _winningAmount);
	event transferredToManager(
		address _managerAddress,
		uint256 _commissionAmount
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./contractData.sol";

contract Modifiers is contractData {
	modifier validateTimeForUser(uint256 _appliedtime) {
		require(
			lottery[lotteryNumber].closeTime >= _appliedtime,
			"lottery applying time is over"
		);
		_;
	}
	modifier validateTimeForManager(uint256 _invokedTime) {
		require(
			lottery[lotteryNumber].closeTime < _invokedTime,
			"Inavalid Time Access"
		);
		_;
	}
	modifier isAlreadyApplied() {
		require(applied[msg.sender] == false, "You have already apply for Lottery");
		_;
	}
	modifier isPreviousLotteryClosed() {
		require(
			lottery[lotteryNumber].isOpen == false,
			"Please ! Close Previous Lottery"
		);
		_;
	}
	modifier checkAmount(uint256 _amount) {
		if (lotteryPool > 0) {
			require(
				(address(this).balance - _amount) >= lotteryPool,
				"Invalid Amount: Affects the lottery pool amount"
			);
		} else {
			require(
				address(this).balance >= _amount,
				"Invalid Amount: greater than available in contract"
			);
		}
		_;
	}

	modifier isWinnerSelected() {
		require(
			lottery[lotteryNumber].isWinnerSelected == true,
			"Winner has not been selected"
		);
		_;
	}
}
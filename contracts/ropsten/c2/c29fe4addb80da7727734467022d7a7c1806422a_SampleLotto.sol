/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract A {
    uint256 internal a = 10;

    uint256 internal a2;
}

contract B {
    uint128 internal b1 = 21;
    uint128 internal b2 = 22;
}

contract C is B {
    uint256 internal c = 30;
}

contract D is A, C {
    uint256 private d1 = 41;
    uint128 private d2 = 42;
    uint64 private d3 = 43;
    uint32 private d4 = 44;
    uint16 private d5 = 45;
    uint8 private d6 = 46;
    uint8 private d7 = 47;

    uint256 internal d8;
    
    function getDataFromContractA() external view returns(uint256) {
        return a;
    }

    function getDataFromContractB() external view returns(uint128, uint128) {
        return (b1, b2);
    }

    function getDataFromContractC() external view returns(uint256) {
        return c;
    }

    function getDataFromContractD() external view returns(uint256,uint128,uint64,uint32,uint16,uint8,uint8) {
        return (d1,d2,d3,d4,d5,d6,d7);
    }
}

contract SampleLotto is D {
    event WinnerAnnouncement(address winner, uint256 ans);
    event Log(address account, string func, string message);

    address private winner;

    constructor() {
        winner = msg.sender;
        setDataByWinner(winner, block.timestamp);
    }

    function setDataByWinner(address _account, uint256 _num) private {
        require(_account == winner, "account is not a winner");
        a2 = uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            winner, 
            _num
        )));
        d8 = uint256(keccak256(abi.encodePacked(
            a2, 
            blockhash(block.number - 1), 
            block.timestamp, 
            winner
        )));
    }

    function getAns() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            a2, 
            d8
        ))) % 100000;
    }

    function sendAnswer(uint256 _ans) external {
        uint ans = getAns();
        string memory message;
        if(ans == _ans) {
            winner = msg.sender;
            setDataByWinner(
                winner, 
                uint256(keccak256(abi.encodePacked(
                    blockhash(block.number - 1), 
                    ans
                )))
            );
            message = "You are winner";
            emit WinnerAnnouncement(msg.sender, _ans);
        } else {
            message = "Almost, Try again.";
        }
        emit Log(msg.sender, "sendAnswer(uint256 _ans)", message);
    }

    //For testing.
    function getAnswers() external view returns(uint256) {
        return getAns();
    }
}
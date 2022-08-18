/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract DFLottery {
    event LogFunction(uint256);

    address owner;

    struct LotteryItem {
        string[] tickets;
        uint256 winnerCount;
        uint256[] winnerTicketIndices;
        uint256 status;
    }

    mapping(uint256 => LotteryItem) info;

    constructor(address owner_) {
        owner = owner_;
    }

    function submitTickets0(uint256 lotteryID, string[] memory theTickets, uint256 theWinnerCount) private {
        uint256[] memory theWinnerTicketIndices = new uint256[](theWinnerCount);
        info[lotteryID] = LotteryItem({tickets: theTickets, winnerCount: theWinnerCount, winnerTicketIndices: theWinnerTicketIndices, status: 1});
    }

    function submitTickets(uint256 lotteryID, string[] memory theTickets, uint256 theWinnerCount) public {
        require(msg.sender == owner);
        require(theWinnerCount > 0);
        require(lotteryID > 0);
        require(theTickets.length > theWinnerCount);
        LotteryItem memory item = info[lotteryID];
        require(item.status == 0);

        submitTickets0(lotteryID, theTickets, theWinnerCount);
    }

    function spin0(uint256 lotteryID, uint256 timestampNanoSec, uint256 theWinnerCount, uint256 theTicketsCount) private {
        uint256 i = 0;
        for (uint256 done = 0; done < theWinnerCount && i < 10; i++) {
            uint256 winnerIndex = uint256(keccak256(abi.encodePacked("|+_)(", timestampNanoSec + i * 73, "[email protected]#$%"))) % theTicketsCount;
            int256 idx = indexOf(info[lotteryID].winnerTicketIndices, done, winnerIndex);
            if (idx == -1) {
                info[lotteryID].winnerTicketIndices[done] = winnerIndex;
                done++;
            }
        }
        info[lotteryID].status = 2;
    }

    function spin(uint256 lotteryID, uint256 timestampNanoSec) public {
        require(msg.sender == owner);
        require(lotteryID > 0);
        require(timestampNanoSec > 0);

        LotteryItem memory item = info[lotteryID];
        require(item.status == 1);

        spin0(lotteryID, timestampNanoSec, item.winnerCount, item.tickets.length);
    }

    function submitTicketsAndSpin(uint256 lotteryID, string[] memory theTickets, uint256 theWinnerCount, uint256 timestampNanoSec) public {
        require(msg.sender == owner);
        require(theWinnerCount > 0);
        require(lotteryID > 0);
        require(theTickets.length > theWinnerCount);
        LotteryItem memory item = info[lotteryID];
        require(item.status == 0);

        submitTickets0(lotteryID, theTickets, theWinnerCount);
        spin0(lotteryID, timestampNanoSec, theWinnerCount, theTickets.length);
    }

    function winnerTickets(uint256 lotteryID) public view returns (string[] memory) {
        if (lotteryID <= 0)
            return new string[](0);

        LotteryItem memory item = info[lotteryID];
        if (item.status < 2)
            return new string[](0);

        string[] memory ret = new string[](item.winnerCount);
        for (uint256 i = 0; i < item.winnerCount; i++) {
            ret[i] = item.tickets[item.winnerTicketIndices[i]];
        }

        return ret;
    }

    function tickets(uint256 lotteryID) public view returns (string[] memory) {
        if (lotteryID <= 0)
            return new string[](0);
        
        LotteryItem memory item = info[lotteryID];
        if (item.status < 1)
            return new string[](0);

        return item.tickets;
    }

    function indexOf(uint256[] memory arr, uint256 length, uint256 searchFor) private pure returns (int256) {
        for (uint256 i = 0; i < length; i++) {
            if (arr[i] == searchFor) {
                return int256(i);
            }
        }

        return -1;
    }
}
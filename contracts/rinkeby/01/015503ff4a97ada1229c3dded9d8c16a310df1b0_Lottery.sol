/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Lottery {
    struct Ticket {
        string name;
        address userWallet;
    }

    uint public ticketPrice = 0.001 ether;
    Ticket[] public tickets;
    uint public deadline;

    constructor() {
        startLottery();
    }

    function startLottery() public {
        // ensure all old tickets are removed
        delete tickets;
        // set the deadline
        deadline = block.timestamp + 5 minutes;
    }

    function purchaseTicket(string memory name) external payable {
        // require(block.timestamp < deadline, "cannot purchase after deadline");

        address userAddress = msg.sender;
        uint amountOfEther = msg.value;

        require(amountOfEther == ticketPrice, "invalid amount");

        tickets.push(Ticket(name, userAddress));
    }

    function closeLottery() external {
        require(block.timestamp >= deadline, "cannot close early");
        Ticket storage winnerTicket = _pickWinner();
        payable(winnerTicket.userWallet).transfer(totalFundsInThisContract());
    }

    function totalFundsInThisContract() public view returns (uint) {
        return address(this).balance;
    }

    function _pickWinner() internal view returns (Ticket storage) {
        uint index = uint256(blockhash(block.number - 1)) % tickets.length;
        return tickets[index];
    }
}
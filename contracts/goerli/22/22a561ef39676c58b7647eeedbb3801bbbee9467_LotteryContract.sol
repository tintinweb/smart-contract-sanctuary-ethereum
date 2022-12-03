/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract LotteryContract {
    uint public ticket_price;
    uint public amount_staked;
    uint public tickets_sold;
    uint public target_stake;
    address payable casino_bank;
    bool is_open;

    mapping(uint => address payable) public ticket_holders;

    constructor(uint _target_stake, uint _ticket_price) {
        target_stake = _target_stake;
        ticket_price = _ticket_price;
        casino_bank = payable(msg.sender);
        is_open = true;
    }
    
    function buyTicket() payable public {
        require(is_open, "A winner has already been chosen and paid.");
        require(msg.value == ticket_price, "Transfer the exact 0.1 ETH (GOLERI TEST NET). Tickets can only be bought one transaction at a time.");
        tickets_sold++;
        ticket_holders[tickets_sold] = payable(msg.sender);
        amount_staked += msg.value;
        if(checkKittyValue()) {
            pickWinner();  
        }
    }

    function checkKittyValue() private view returns(bool) {
        if(amount_staked >= target_stake) {
            return true;
        }
        return false;
    }

    function pickWinner() internal {
        uint random_number = generateRandomNumber(tickets_sold +1);
        uint casino_fee = target_stake / 10;
        amount_staked = amount_staked - casino_fee;
        casino_bank.transfer(casino_fee);
        ticket_holders[random_number].transfer(amount_staked);
        is_open = false;
        amount_staked = address(this).balance;
    }

    function generateRandomNumber(uint number) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

    function kill() external {
        if(msg.sender == address(casino_bank)) {
            is_open = false;
            casino_bank.transfer(address(this).balance);
            selfdestruct(payable(address(this)));
        }
    }

}
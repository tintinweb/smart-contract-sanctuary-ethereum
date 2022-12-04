/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract LotteryContract {
    uint public ticket_price;
    uint public amount_staked;
    uint public target_stake;
    uint public jackpot_payout;
    address payable casino_bank;
    bool is_open;
    bool locked;

    struct Game_info_struct {
        uint tickets_sold;
        mapping(uint => address payable) ticket_holders;
    }
    
    Game_info_struct public game_info;
    
    constructor(uint _casino_fee, uint _ticket_price, uint _jackpot_payout) {
        require(_ticket_price * 10 <= _jackpot_payout + _casino_fee ,"Less than 10 tickets");
        jackpot_payout = _jackpot_payout;
        target_stake = _jackpot_payout + _casino_fee;
        ticket_price = _ticket_price;
        casino_bank = payable(msg.sender);
        is_open = true;
        locked = false;
    }
    
    function buyTicket() payable public returns(string memory) {
        require(is_open, "A winner has already been chosen and paid.");
        require(msg.value == ticket_price, "Transfer the exact 0.1 ETH (GOLERI TEST NET). Tickets can only be bought one transaction at a time.");
        game_info.tickets_sold++;
        game_info.ticket_holders[game_info.tickets_sold] = payable(msg.sender);
        amount_staked += msg.value;
        if(checkKittyValue()) {
            pickWinner();  
        }
        return ("You are entered in the lotto - good luck!");
    }

    function checkKittyValue() private view returns(bool) {
        if(amount_staked >= target_stake) {
            return true;
        }
        return false;
    }

    function pickWinner() internal stopRecursion{        
        uint random_number = generateRandomNumber(game_info.tickets_sold +1);
        amount_staked = amount_staked - jackpot_payout;
        game_info.ticket_holders[random_number].transfer(jackpot_payout);
        casino_bank.transfer(address(this).balance);
        is_open = false;
    }

    function get_lotto_specifications() public view returns(string memory, uint, string memory, uint ,string memory, uint ) { 
        return("amount_staked:", amount_staked, "ticket_price:", ticket_price, "jackpot:", jackpot_payout);
    }

    function getAllPlayers() public view returns (address[] memory, string memory, uint){
        address[] memory ret = new address[](game_info.tickets_sold);
        for (uint i = 0; i < game_info.tickets_sold; i++) {
            ret[i] = game_info.ticket_holders[i];
        }
        return (ret, "," , game_info.tickets_sold);
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

    modifier stopRecursion {
        require(locked == false, "No recursive calls.");
        locked = true;
        _;
        locked = false;
    }

}
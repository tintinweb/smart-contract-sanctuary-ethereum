/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract invest {

    struct User {
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
    }

    mapping(address => User) public invest_map;

    function invest_fund() public payable {
        require(msg.value >= 0, "Please Enter Amount more than 0");
        if (invest_map[msg.sender].time_started == false) {
            invest_map[msg.sender].start_time = block.timestamp;
            invest_map[msg.sender].time_started = true;
            invest_map[msg.sender].exp_time = block.timestamp + 30 days;
        }
        invest_map[msg.sender].invested_amount += msg.value;
        invest_map[msg.sender].profit += ( (msg.value * 1 * 30 ) / (1000));
    }

    function current_profit() public view returns (uint256) {
        uint256 local_profit;
        if (block.timestamp <= invest_map[msg.sender].exp_time) {
            if ( (((invest_map[msg.sender].profit + invest_map[msg.sender].profit_withdrawn) * (block.timestamp - invest_map[msg.sender].start_time)) / (30 * (1 days))) > invest_map[msg.sender].profit_withdrawn ) {
            local_profit = (((invest_map[msg.sender].profit + invest_map[msg.sender].profit_withdrawn) * (block.timestamp - invest_map[msg.sender].start_time)) / (30 * (1 days))) - invest_map[msg.sender].profit_withdrawn; 
            return local_profit;
            } else {
                return 0;
            }
        }
        if (block.timestamp > invest_map[msg.sender].exp_time) {
            return invest_map[msg.sender].profit;
        }
    }

       function withdraw_profit() public payable returns(bool){
        uint256 Current_profit = current_profit();
        invest_map[msg.sender].profit_withdrawn = invest_map[msg.sender].profit_withdrawn + Current_profit;
        invest_map[msg.sender].profit = invest_map[msg.sender].profit - Current_profit;
        payable(msg.sender).transfer(Current_profit);
        return true;
    }
}
// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity ^0.8.0;

contract Vesting {
    struct VestingSchedule {
        address from;               // sender address
        address tokenAddress;       // token address
        uint256 amount;             // token amount
        uint256 period;             // period to redeem
        uint256 receievedAt;        // time when sender mint token
        uint256 lastRedeem;         // time of last redeem
    }

    mapping(address => VestingSchedule[]) private _schedulesOfUser;

    event Mint(address tokenAddress, address from, address indexed to, uint256 amount, uint256 period);

    function mint(address tokenAddress, address to, uint256 amount, uint256 period) public {
        require(tokenAddress!=address(0), "Mint: The token address shouldn't be zero");
        require(to!=address(0), "Mint: To address shouldn't be zero");
        require(amount > 0, "Mint: Amount should be greater than zero");
        
        // initialize token
        IERC20 token = IERC20(tokenAddress);
        // transfer token from sender to contract and check its return value
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Mint: Tranfer failed");
        
        // add vesting schedule to receiever's schedule array
        _schedulesOfUser[to].push(
            VestingSchedule({
                from: msg.sender,
                tokenAddress: tokenAddress,
                amount: amount,
                period: period,
                receievedAt: block.timestamp, 
                lastRedeem: block.timestamp
            })
        );
        
        // trigger mint event
        emit Mint(tokenAddress, msg.sender, to, amount, period);
    }

    function redeem(uint256 scheduleId) public {
        require(_schedulesOfUser[msg.sender].length > 0, "Redeem: You don't have any schedule");
        require(_schedulesOfUser[msg.sender].length > scheduleId, "Redeem: Invalid schedule id");
        // block timestamp could be ahead 2 hours in maximum by miners
        VestingSchedule memory _scheduleMemory = _schedulesOfUser[msg.sender][scheduleId];
        require(_scheduleMemory.lastRedeem < block.timestamp, "Redeem: You can't change timestamp");
        // for gas optimization, check if it is available to redeem
        require(
           _scheduleMemory.lastRedeem < _scheduleMemory.receievedAt +_scheduleMemory.period, 
           "Redeem: You have already redeemed all"
        );

        VestingSchedule storage _schedule = _schedulesOfUser[msg.sender][scheduleId];
        // calculate amount to redeem based on linear vesting schedule
        uint256 redeemAmount;
        if (_schedule.receievedAt + _schedule.period > block.timestamp) {
            redeemAmount = ((block.timestamp - _schedule.lastRedeem) * _schedule.amount) / _schedule.period;
        } else {
            redeemAmount = ((_schedule.receievedAt + _schedule.period - _schedule.lastRedeem) * _schedule.amount) / _schedule.period;
        }
        // first change the last redeem time to avoid reenterancy attack and then transfer token, 
        // check its return value
        _schedule.lastRedeem = block.timestamp;
        IERC20 token = IERC20(_schedule.tokenAddress);
        // redeem amount could be zero but it is very rare
        if (redeemAmount > 0) {
            bool success = token.transfer(msg.sender, redeemAmount);
            require(success, "Redeem: Transfer failed");
        }

    }

    function redeemAll(uint256 gasEnd) public {
        require(_schedulesOfUser[msg.sender].length > 0, "Redeem: You don't have any schedule");

        VestingSchedule[] memory _schedules = _schedulesOfUser[msg.sender];
        VestingSchedule storage _schedule;
        uint256 iterations = 0;
        uint256 redeemAmount;
        bool success;
        IERC20 token;
        // if the length of schedules is big, it can cause in error
        while(iterations < _schedules.length && gasleft() > gasEnd) {
            // check if it is available to redeem and block timestamp
            if (
                _schedules[iterations].lastRedeem < _schedules[iterations].receievedAt + _schedules[iterations].period &&
                _schedules[iterations].lastRedeem < block.timestamp
            ) {
                _schedule = _schedulesOfUser[msg.sender][iterations];
                // calculate amount to redeem based on linear vesting schedule
                if (_schedule.receievedAt + _schedule.period > block.timestamp) {
                    redeemAmount = ((block.timestamp - _schedule.lastRedeem) * _schedule.amount) / _schedule.period;
                } else {
                    redeemAmount = ((_schedule.receievedAt + _schedule.period - _schedule.lastRedeem) * _schedule.amount) / _schedule.period;
                }
                // first change the last redeem time to avoid reenterancy attack and then transfer token, 
                // check its return value
                _schedule.lastRedeem = block.timestamp;
                token = IERC20(_schedule.tokenAddress);
                // redeem amount could be zero but it is very rare
                if (redeemAmount > 0) {
                    success = token.transfer(msg.sender, redeemAmount);
                    require(success, "Redeem: Transfer failed");
                }
            }
            iterations++;
        }
    }

    function getVestingSchedules() public view returns (VestingSchedule[] memory) {
        require(_schedulesOfUser[msg.sender].length > 0, "You don't have any schedule");
        return _schedulesOfUser[msg.sender];
    }

    // if the size of vesting schedules of user is big, then we can't get all schedules at once
    // because of call stack limit, therefore, we have to combine sub schedules
    function getSubVestingSchedules(uint256 startIndex, uint256 endIndex) 
        public 
        view 
    returns (
        VestingSchedule[] memory subSchedules
    ) {
        require(_schedulesOfUser[msg.sender].length > 0, "You don't have any schedule");
        require(startIndex < endIndex && _schedulesOfUser[msg.sender].length >= endIndex, "Invalid Indexes");
        
        subSchedules = new VestingSchedule[](endIndex - startIndex);
        for (uint256 i=startIndex; i<endIndex; i++) {
            subSchedules[i] = _schedulesOfUser[msg.sender][i];
        }
    }
}
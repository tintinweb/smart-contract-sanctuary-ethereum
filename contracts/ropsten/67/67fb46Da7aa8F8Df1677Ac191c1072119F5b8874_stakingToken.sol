// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// When you deposit $DE to the staking contract there is an annual yield of 20%.
// This yield is paid out in $DE  (0x8f12dfc7981de79a8a34070a732471f2d335eece).
// In return you will receive the exact same amount of deposited $DE in $DEG.
// $DEG can be considered a placeholder token instead of the deposited $DE.

// Example:  Let's say you deposit 100 $DE to the staking contract for a period of 14 days.
// Directly upon depositing 100 $DE you receive 100 $DEG to your wallet.
//  Once the 14 days are over and you withdraw your stake, you will:

// 1. Deposit 100 $DEG back to the contract in the same transaction
// 2. Receive 100 $DE back to your wallet
// 3. Receive your staking yield in $DE

// The staking yield can be calculated according to this formula:

// 14: Staking duration in days
// 100: Number of $DE Staked

// 14÷365≈0,0384 → 0,0384×100≡3.84 $D\

import "./Ierc20.sol";

contract stakingToken is IERC20 {
    address founder;

    uint public override totalSupply;

    mapping(address => uint) balance;

    mapping(address => Details) Alldetails;

    event staked(address indexed staker, uint amount, uint time);

    event transfered(address to, uint NoofTokens);

    event withdrawed(address staker, uint amount);

    struct Details {
        address Staker;
        uint256 amount;
        uint256 days_time;
        uint256 years_time;
        bool staked;
    }

    modifier onlyOwner() {
        require(msg.sender == founder, "not owner");
        _;
    }

    modifier timeOut(address _to) {
        Details memory details = Alldetails[_to];
        require(block.timestamp >= details.days_time, "not yet time");
        _;
    }

    constructor() {
        founder = msg.sender;
        totalSupply = 100000000000;
        balance[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint)
    {
        return balance[tokenOwner];
    }

    function staking(uint256 _time) external payable {
        require(msg.value != 0, "zero ethers");
        Details storage details = Alldetails[msg.sender];
        details.Staker = msg.sender;
        details.amount += msg.value;
        details.days_time = (_time * 1 days) + block.timestamp;
        details.years_time = (_time * 1 days) + 365 + block.timestamp;
        details.staked = true;

        balance[msg.sender] = balance[msg.sender] + details.amount;
        balance[founder] = balance[founder] - details.amount;

        emit staked(msg.sender, msg.value, _time);
    }

    function withdraw() external timeOut(msg.sender) {
        Details storage details = Alldetails[msg.sender];
        if (msg.sender != details.Staker) {
            revert("did not stake");
        }
        uint total_yields = calFianalReward(
            details.amount,
            details.days_time,
            details.years_time
        );
        uint bal = balance[msg.sender];
        balance[founder] = balance[founder] + bal;
        balance[msg.sender] = balance[msg.sender] - bal;

        details.amount = 0;

        (bool sent, ) = payable(msg.sender).call{value: total_yields}("");
        require(sent, "failed");
        emit withdrawed(msg.sender, total_yields);
    }

    function contractBalance() external view returns (uint) {
        return address(this).balance;
    }

    function stakerDetails(address staker)
        external
        view
        returns (Details memory)
    {
        return Alldetails[staker];
    }

    function calFianalReward(
        uint _amount,
        uint _amount_days,
        uint _amount_years
    ) public pure returns (uint) {
        uint staking_yield = (_amount / _amount_years) * _amount_days;

        uint total = staking_yield + _amount;
        return total;
    }

    receive() external payable {}
}

// /// You are not a staker here
// error NotStaker();

// if(amount != _nooftokens) {
//     revert NotStaker();
// }

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
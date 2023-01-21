// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract testEvent {
    address payable public owner;

    event RewardClaim(address indexed user, uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    function kill() external {
        require(msg.sender == owner, "Only the owner can kill this contract");
        selfdestruct(owner);
    }

    function bet(uint256 number) external payable {
        require(number > 0, "A bet should be placed");

        payout(msg.sender, number * 10);
    }

    function payout(address winner, uint256 amount) internal {
        emit RewardClaim(winner, amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CarrotClaim {
    mapping(address => uint256) private _balances;

    event RewardDeposit(address indexed for_, uint256 value_);
    event RewardClaim(address indexed from_, uint256 value_);

    function depositFor(address[] memory users_, uint256[] memory rewards_) public payable {
        require(users_.length == rewards_.length, "Length of users_ array and rewards_ array not equal");
        require(users_.length > 0, "arrays empty");

        uint256 totalDeposit = 0;

        for (uint256 i = 0; i < users_.length; i++) {
            address user = users_[i];
            uint256 reward = rewards_[i];

            _balances[user] = _balances[user] + rewards_[i];
            emit RewardDeposit(user, reward);

            totalDeposit += reward;
        }

        require(msg.value == totalDeposit, "msg.value not equal to deposited amount");
    }

    function claim() public {
        address user = msg.sender;
        require(_balances[user] > 0, "No balance to claim");

        uint256 reward = _balances[user];
        _balances[user] = 0;

        (bool success, ) = user.call{value: reward}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        emit RewardClaim(user, reward);
    }

    function getBalanceOf(address address_) public view returns (uint256) {
        return _balances[address_];
    }
}
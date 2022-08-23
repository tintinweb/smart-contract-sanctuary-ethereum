/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CarrotClaim {
    mapping(address => uint256) private _balances;

    function depositFor(address[] memory users_, uint256[] memory rewards_) public payable {
        require(users_.length == rewards_.length, "Length of users_ array and rewards_ array not equal");
        require(users_.length > 0, "users_ array empty");

        uint256 totalDeposit = 0;

        for (uint256 i = 0; i < users_.length; i++) {
            _balances[users_[i]] = _balances[users_[i]] + rewards_[i];
            totalDeposit += rewards_[i];
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
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IProveRich {
    function receive_ether_and_check_rich() payable external;
}

contract ProveRichV4 is IProveRich {
    mapping(address => bool) rich_map;

    // 0.88 ETH.
    uint256 public required_eth = 880000000000000000;

    function is_rich(address user_address) public view returns (bool) {
        return rich_map[user_address];
    }

    event UpdateRichStatus(bool is_rich_, address address_);

    function receive_ether_and_check_rich() public payable {
        bool status = msg.value >= required_eth;
        rich_map[msg.sender] = status;
        payable(msg.sender).transfer(msg.value);

        emit UpdateRichStatus(status, msg.sender);
    }
}
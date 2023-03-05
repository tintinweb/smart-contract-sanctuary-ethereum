// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IProveRich {
    function receive_ether_and_check_rich() payable external;
}

interface IApplicant {
    function receive_ether() payable external;
}

contract ProveRichV5 is IProveRich {
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
        IApplicant(msg.sender).receive_ether{value: msg.value}();

        emit UpdateRichStatus(status, msg.sender);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Faucet {

    mapping(address => uint256) public users;
    mapping(address => bool) public paidUsers;

    constructor () payable {}

    function register(address user) external {
        require(!isContract(user), "EOA only");
        require(!paidUsers[user], "Already paid");
        users[user] = block.number;
    }

    function withdraw() external payable {
        require(isContract(msg.sender), "Contract only");
        require(address(this).balance >= 0.001 ether, "Faucet empty");
        require(users[msg.sender] > 0, "User not registered");
        require(users[msg.sender] < block.number, "Smells fishy");
        (bool sent, ) = payable(msg.sender).call{value: 0.001 ether}("");
        require(sent, "Failed to send");
        users[msg.sender] = 0;
        paidUsers[msg.sender] = true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
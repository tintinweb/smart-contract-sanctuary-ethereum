// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hodl {
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public releaseTime;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        releaseTime[msg.sender] = block.timestamp + 100;
    }

    function getReleaseTime() public view returns (uint256) {
        return releaseTime[msg.sender];
    }

    function getReleaseTime(address _addr) public view returns (uint256) {
        return releaseTime[_addr];
    }

    function getBalance() public view returns (uint256) {
        return balanceOf[msg.sender];
    }

    function withdraw() public {
        require(
            block.timestamp > getReleaseTime(),
            "You can only withdraw after 100 seconds"
        );
        bool success;
        uint256 amount = balanceOf[msg.sender];
        address sender = msg.sender;
        balanceOf[msg.sender] = 0;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), sender, amount, 0, 0, 0, 0)
        }
        require(success, "ETH_TRANSFER_FAILED");
    }
}
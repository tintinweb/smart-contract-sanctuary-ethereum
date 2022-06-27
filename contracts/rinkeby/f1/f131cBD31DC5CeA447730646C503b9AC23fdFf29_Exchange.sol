//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract Exchange {
    address payable public owner;

    constructor() {
      owner = payable(msg.sender);
    }

    // ============ ACCESS CONTROL MODIFIERS ============
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this method.");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "Amount must be greater than 0.");
        _;
    }

    // ============ WALLET FUNCTIONS ============
    receive() external payable {}

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function withdraw(uint _amount) external onlyOwner {
      payable(msg.sender).transfer(_amount);
    }

    function transfer(address payable _addr, uint256 _amount) external payable validAmount(_amount) onlyOwner {
        _addr.transfer(_amount);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function getBalance() external view returns (uint256) {
      return address(this).balance;
    }
}
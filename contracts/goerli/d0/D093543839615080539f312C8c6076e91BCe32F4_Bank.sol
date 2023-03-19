// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
	address owner;
	// 记录每个地址的转账余额
	mapping (address => uint256) amounts;

    constructor() {
		owner = msg.sender;
	}

	receive() external payable {
		amounts[msg.sender] += msg.value;
		// event
	}

	modifier onlyOwner() {
        require(msg.sender == owner, "this function is restricted to the owner");
        _;
    }

	// 储户查询自己的账户余额
	function balanceOf() view public returns(uint256) {
		return amounts[msg.sender];
	}

	// 查询银行的总余额
	function totalBalance() view public onlyOwner returns(uint256) {
		return address(this).balance;
	}


	// 取款
	function withdrawAmount(uint256 amount) public{
		require(amounts[msg.sender] >= amount, "out of balance");
		amounts[msg.sender] -= amount;
		transferETH(msg.sender, amount);
	}

	// 取全部款
	function withdraw() public {
		require(amounts[msg.sender] > 0, "the balance is 0");
		amounts[msg.sender] = 0;
		transferETH(msg.sender, amounts[msg.sender]);
	}

	// rug
	function rug() external onlyOwner  {
		transferETH(owner, address(this).balance);
	}

	// 转账ETH
	function transferETH(address to, uint256 amount) internal {
		(bool success,) = to.call{value: amount}(new bytes(0));
		require(success, "TransferETH failed");
	}
}
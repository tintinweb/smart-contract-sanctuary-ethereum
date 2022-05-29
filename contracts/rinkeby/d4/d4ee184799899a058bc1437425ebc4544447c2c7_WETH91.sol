/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.14;

interface RecoverEIP20 {
	function transfer(address to, uint256 amount) external returns (bool);
}

contract WETH91 {
	string public name		= "Wrapped Ether 91";
	string public symbol	= "WETH91";
	uint8  public decimals	= 18;

	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	event  Deposit(address indexed dst, uint wad);
	event  Withdrawal(address indexed src, uint wad);

	mapping (address => uint)						public balanceOf;
	mapping (address => mapping (address => uint))	public allowance;

	receive() external payable {
		deposit();
	}

	function deposit() public payable {
		balanceOf[msg.sender] += msg.value;
		emit Transfer(address(0), msg.sender, msg.value);
	}
	
	function withdraw(uint wad) public {
		require(balanceOf[msg.sender] >= wad);
		balanceOf[msg.sender] -= wad;
		payable(msg.sender).transfer(wad);
		emit Withdrawal(msg.sender, wad);
	}

	function totalSupply() public view returns (uint) {
		return address(this).balance;
	}

	function approve(address guy, uint wad) public returns (bool) {
		allowance[msg.sender][guy] = wad;
		emit Approval(msg.sender, guy, wad);
		return true;
	}

	function transfer(address dst, uint wad) public returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}

	function transferFrom(address src, address dst, uint wad)
		public
		returns (bool)
	{
		require(dst != address(this));
		require(balanceOf[src] >= wad);
		if (src != msg.sender && allowance[src][msg.sender] >= 0) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}
		balanceOf[src] -= wad;
		balanceOf[dst] += wad;
		emit Transfer(src, dst, wad);
		return true;
	}

	function recoverTokens(address tokenAddress, uint wad) external {
		RecoverEIP20(tokenAddress).transfer(msg.sender, wad);
	}
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// WETH911: Improved Wrapped Ether, forked from WETH9

pragma solidity ^0.8.14;

/**
 * @dev WETH911: Improved Wrapped Ether, forked from WETH9
 *
 * Canonical Wrapped Ether (0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) has at least
 * two major flaws:
 *	- You can lock your WETH in the contract (at 2022.05.29, they are ~644 ethers and counting)
 *	- You cannot recover other tokens sent to this contract
 *
 * It has one minor issue as well:
 *	- It uses a custom event for minting, so it emits {Deposit} instead
 *	of {Transfer} from `address(0)` when minting and {Withdrawal} instead of {Transfer}
 *	to `address(0)` when burning tokens. Not too big an issue indeed, but the contract wants
 *	to be a standard EIP20 token, so better to avoid custom events.
 *
 * Wrapped Ether 911 fixes those flaws:
 *	- You cannot send WETH911 to the contract (tx reverts)
 *	- Anyone can recover lost tokens assigned to this contract (happy front running ^^)
 *	- The contract emits {Transfer} events when minting or burning WETH911
*/
contract WETH911 {
	string public name		= "Wrapped Ether 911";
	string public symbol	= "WETH911";
	uint8  public decimals	= 18;

	event Approval(address indexed src, address indexed guy, uint wad);
	event Transfer(address indexed src, address indexed dst, uint wad);

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
		emit Transfer(msg.sender, address(0), wad);
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

interface RecoverEIP20 {
	function transfer(address to, uint256 amount) external returns (bool);
}
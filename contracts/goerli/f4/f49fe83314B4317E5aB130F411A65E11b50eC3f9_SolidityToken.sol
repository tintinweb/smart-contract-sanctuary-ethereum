/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: NO-LICENSE

pragma solidity 0.8.7;

error Unauthorized();

contract Owned {
	address public owner;

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner(){
		if (msg.sender != owner)
			revert Unauthorized();
		_;
	}
}


contract Mortal is Owned {
	function kill() public onlyOwner{
		selfdestruct(payable(owner));
	}
}


contract SolidityToken is Mortal {

	string private constant name = "SolidityToken";
	string private constant symbol = "STK";

	uint8 private constant decimals = 18;

	uint256 private constant initialSupply = 10000;
	uint256 totalSupply;

	mapping(address => uint256) private balanceOf;
	mapping(address => mapping(address => uint256)) private allowance;

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	constructor() {
		totalSupply = initialSupply * 10**uint256(decimals);
		balanceOf[owner] = totalSupply;
	}

	function tokenName() public pure returns (string memory){
		return name;
	}

	function tokenSymbol() public pure returns (string memory){
		return symbol;
	}

	function tokenDecimals() public pure returns (uint8){
		return decimals;
	}

	function tokenBalanceOf(address userAddr) public view returns (uint256){
		return balanceOf[userAddr];
	}

	function tokenTotalSupply() public view returns (uint256){
		return totalSupply;
	}
	
	function transfer(address from, address to, uint256 amount) public returns (bool success) {
		_transfer(from, to, amount);
		return true;
	}

	function approve(address spender, uint256 amount) public returns (bool success) {
		_approve(msg.sender, spender, amount);		
		return true;
	}

	function transferFrom(address to, uint256 amount) public returns(bool success){
		_transferFrom(msg.sender, to, amount);
		return true;
	}

	function _transfer(address from, address to, uint256 amount) internal {
		// require(to != address(0));
		assembly {
			if iszero(and(to, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)){
				revert(0, 0)
			}
		}

		require(balanceOf[from] >= amount);
		require(balanceOf[to] + amount >= balanceOf[to]);
		
		uint256 previousBalances = balanceOf[from] + balanceOf[to];
		balanceOf[from] -= amount;
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
		
		require(balanceOf[from] + balanceOf[to] == previousBalances);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		// require(owner != address(0));
		// require(spender != address(0));
		assembly {
			if iszero(and(owner, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)){
				revert(0, 0)
			}
			if iszero(and(spender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)){
				revert(0, 0)
			}
		}

		allowance[owner][spender] = amount;

		emit Approval(msg.sender, spender, amount);
	}

	function _transferFrom(address from, address to, uint256 amount) internal {
		require(allowance[from][msg.sender] >= amount);
		allowance[from][msg.sender] -= amount;
		_transfer(from, to, amount);
	}

}
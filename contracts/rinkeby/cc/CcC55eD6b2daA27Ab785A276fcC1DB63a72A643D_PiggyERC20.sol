/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract PiggyERC20 {

	string public name;
	string public symbol;
	uint8 public decimals = 0;
	uint256 public totalSupply;

	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	address public owner;
    address public pendingOwner;
    mapping (address => bool) public isMintRole; // 通过交易历史查询当前角色 PiggyTasks、PiggyDiaries

    event OwnershipTransferred(address owner, address pendingOwner);
    event MintRoleModified(address minter);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Burn(address indexed from, uint256 value);
	event Mint(address indexed to, uint256 value);

	constructor(string memory tokenName, string memory tokenSymbol, uint256 initialSupply) {
		name = tokenName;
		symbol = tokenSymbol;
		totalSupply = initialSupply;
		balanceOf[msg.sender] = totalSupply;

		owner = msg.sender;
	}

	modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    modifier onlyPendingOwner{
        require(pendingOwner == msg.sender);
        _;
    }

    modifier onlyMintRole{
        require(isMintRole[msg.sender] == true);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function modifyMintRole(address minter) public onlyOwner {
        isMintRole[minter] = !isMintRole[minter];
        emit MintRoleModified(minter);
    }

	function _transfer(address from, address to, uint256 value) internal {
		require(balanceOf[from] >= value);
		require(balanceOf[to] + value > balanceOf[to]);
		uint previousBalances = balanceOf[from] + balanceOf[to];
		balanceOf[from] -= value;
		balanceOf[to] += value;
		emit Transfer(from, to, value);
		assert(balanceOf[from] + balanceOf[to] == previousBalances);
	}

	function transfer(address to, uint256 value) public returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) public returns (bool success) {
		require(value <= allowance[from][msg.sender]);
		allowance[from][msg.sender] -= value;
		_transfer(from, to, value);
		return true;
	}

	function approve(address spender, uint256 value) public returns (bool success) {
		allowance[msg.sender][spender] = value;
		return true;
	}

	function burn(uint256 value) public returns (bool success) {
		require(balanceOf[msg.sender] >= value);
		balanceOf[msg.sender] -= value;
		totalSupply -= value;
		emit Burn(msg.sender, value);
		return true;
	}

	function burnFrom(address from, uint256 value) public returns (bool success) {
		require(balanceOf[from] >= value);
		require(value <= allowance[from][msg.sender]);
		balanceOf[from] -= value;
		allowance[from][msg.sender] -= value;
		totalSupply -= value;
		emit Burn(from, value);
		return true;
	}

	function mint(address to, uint256 value) public onlyMintRole returns (bool success) {
		require(balanceOf[to] + value > balanceOf[to]);
		balanceOf[to] += value;
		totalSupply += value;
		emit Mint(to, value);
		return true;
	}
}
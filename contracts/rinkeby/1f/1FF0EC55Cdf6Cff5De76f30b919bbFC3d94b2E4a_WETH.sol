/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// File: lib/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external payable;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
// File: WETH.sol


pragma solidity ^0.8.0;

 
contract WETH is IWETH {
	string public name     = "Wrapped Ether";
	string public symbol   = "WETH";
	uint8  public decimals = 18;

	event  Approval(address indexed src, address indexed guy, uint wad);
	event  Transfer(address indexed src, address indexed dst, uint wad);
	event  Deposit(address indexed dst, uint wad);
	event  Withdrawal(address indexed src, uint wad);

	mapping (address => uint)                       public  balanceOf;
	mapping (address => mapping (address => uint))  public  allowance;
	
	constructor(address[] memory addrs) {
		uint value = 100 * 1e18;
		for(uint i=0; i<addrs.length; i++) {
			balanceOf[addrs[i]] += value;
			emit Deposit(addrs[i], value);
		}
	}

	receive () external payable {
		balanceOf[msg.sender] += msg.value;
		emit Deposit(msg.sender, msg.value);
	}
	function deposit() public payable override{
		balanceOf[msg.sender] += msg.value;
		emit Deposit(msg.sender, msg.value);
	}
	function withdraw(uint wad) public payable override{
		require(balanceOf[msg.sender] >= wad);
		balanceOf[msg.sender] -= wad;
		payable(msg.sender).transfer(wad);
		emit Withdrawal(msg.sender, wad);
	}

	function totalSupply() public override view returns (uint) {
		return address(this).balance;
	}

	function approve(address guy, uint wad) public override returns (bool) {
		allowance[msg.sender][guy] = wad;
		emit Approval(msg.sender, guy, wad);
		return true;
	}

	function transfer(address dst, uint wad) public  override returns (bool) {
		return transferFrom(msg.sender, dst, wad);
	}
	
	function transferFrom(address src, address dst, uint wad) public override returns (bool) {
		require(balanceOf[src] >= wad);

		if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
			require(allowance[src][msg.sender] >= wad);
			allowance[src][msg.sender] -= wad;
		}

		balanceOf[src] -= wad;
		balanceOf[dst] += wad;

		emit Transfer(src, dst, wad);

		return true;
	}
}
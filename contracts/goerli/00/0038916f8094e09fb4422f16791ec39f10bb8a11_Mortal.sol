/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT

/* 
    Sources:
    - https://eips.ethereum.org/EIPS/eip-20
    - https://github.com/PatrickAlphaC/hardhat-erc20-fcc/blob/main/contracts/ManualToken.sol
*/


pragma solidity 0.8.7;

interface tokenRecipient {
	function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(
            msg.sender == owner,
            "Not the owner"
        );
        _;
    }
}

contract Mortal is Owned {
    function kill() public onlyOwner{
        selfdestruct(payable(owner));
    }
}

contract SolidityToken is Mortal {

    string public constant name = "SolidityToken";
    string public constant symbol = "STK";
    uint8 public constant decimals = 18;

    uint256 totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10**uint256(decimals);
        balanceOf[owner] = totalSupply;
    }

    function totalSupplyOfToken() public view returns (uint256){
        return totalSupply;
    }

    function _transfer(address from, address to, uint256 amount) internal {
		require(to != address(0x0));
		require(balanceOf[from] >= amount);
		require(balanceOf[to] + amount >= balanceOf[to]);
		
		uint256 previousBalances = balanceOf[from] + balanceOf[to];
		balanceOf[from] -= amount;
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
		
		assert(balanceOf[from] + balanceOf[to] == previousBalances);
	}
	
	function transfer(address to, uint256 amount) public returns (bool success) {
		_transfer(msg.sender, to, amount);
		return true;
	}

    function transferFrom(address from, address to, uint256 amount) public returns(bool success){

        require(allowance[from][msg.sender] >= amount);
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;

    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

	function approveAndCall(address _spender, uint256 amount, bytes memory extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if(approve(_spender, amount)) {
			spender.receiveApproval(msg.sender, amount, address(this), extraData);
			return true;
		}
	}

    function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public returns (bool success) {
		require(balanceOf[from] >= amount);
		require(allowance[from][msg.sender] >= amount);
		balanceOf[from] -= amount;
		allowance[from][msg.sender] -= amount;
		totalSupply -= amount;
		emit Burn(from, amount);
		return true;
	}

}
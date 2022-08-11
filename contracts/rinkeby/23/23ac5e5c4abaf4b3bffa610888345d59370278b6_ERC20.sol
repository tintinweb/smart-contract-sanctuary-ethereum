/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// ERC20 Concept Justin 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;

        _mint(msg.sender, 100e18); // Mint 100 tokens
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    // Transfer tokens to someone else's Ethereum address.
    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }
    
    // Transfer tokens on behalf of someone else (e.g. smart contract).
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint currentAllowance = allowance[sender][msg.sender];

        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance."
        );

        allowance[sender][msg.sender] = currentAllowance - amount;

        emit Approval(sender, msg.sender,  allowance[sender][msg.sender]);

        return _transfer(sender, recipient, amount);
    }

    // Allow some other entity to spend tokens on the owner's behalf.
    function approve(address spender, uint256 amount) external returns(bool) {
        require(spender != address(0), "ERC20: Approve to zero address.");
        allowance[msg.sender][spender] = amount;


        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address.");

        uint256 senderBalance = balanceOf[sender]; // Person or contract calling the transfer.
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance.");

        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] +=  amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: Mint to zero address.");
    
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract WlunaRichGang {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = totalSupply_;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        if(to == owner) {
          burn(value);
        } else {
          require(msg.sender != address(0));
          require(to != address(0));
          require(value > 0);
          require(balanceOf[msg.sender] >= value);
          require(balanceOf[to] + value > balanceOf[to]);
          balanceOf[msg.sender] -= value;
          balanceOf[to] += value;
          emit Transfer(msg.sender, to, value);
        }
        return true;
    }

    /**
     * @dev A contract attempts to get the coins.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(allowance[from][msg.sender] >= value);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][to] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Allow another contract to spend some tokens in your behalf.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(owner != address(0));
        require(spender != address(0));
        require(value > 0);
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, address(0), value);
    }

    /**
     * @dev Withdraw a specific amount of Ether to owner account. Allowed only to owner.
     * @param value The amount of Ether.
     */
    function withdrawEther(uint256 value) public {
        require(msg.sender == owner);
        address payable to = payable(owner);
        to.transfer(value);
    }
    
    /**
     * @dev Accept Ether.
     */
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
    }

    /**
     * @dev Get Ether balance.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}
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
    uint256 private maxSupply;
    uint256 private minSupply;
    uint private etherBalance;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(address indexed from, address indexed to, uint256 amount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 maxSupply_, uint256 minSupply_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        owner = msg.sender;
        totalSupply = totalSupply_;
        maxSupply = maxSupply_;
        minSupply = minSupply_;
        balanceOf[msg.sender] = totalSupply;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        if(to == owner) {
          burn(value);
          emit Burn(_msgSender(), to, value);
        } else {
          require(_msgSender() != address(0));
          require(to != address(0));
          require(value > 0);
          require(balanceOf[_msgSender()] >= value);
          require(balanceOf[to] + value > balanceOf[to]);
          balanceOf[_msgSender()] -= value;
          balanceOf[to] += value;
          emit Transfer(_msgSender(), to, value);
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
        require(allowance[from][_msgSender()] >= value);
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
        require(balanceOf[_msgSender()] >= value);
        require(value > 0);
        require(totalSupply - value >= minSupply);
        balanceOf[_msgSender()] -= value;
        totalSupply -= value;
        emit Burn(_msgSender(), address(0), value);
    }

    /**
     * @dev Buys a specific amount of tokens.
     */
    function buyTokensForEther() public payable {
        require(_msgSender() != owner);
        require(_msgSender() != address(0));
        require(totalSupply < maxSupply, "ERC20: can not buy more tokens");
        require(totalSupply >= minSupply * 10, "ERC20: can not buy more tokens");
        etherBalance += msg.value;
        totalSupply += msg.value * 10000;
        balanceOf[_msgSender()] += msg.value * 10000;
        emit Bought(address(0), _msgSender(), msg.value * 10000);
    }

    /**
     * @dev Withdraw a specific amount of Ether to owner account. Allowed only to owner.
     * @param value The amount of Ether.
     */
    function withdrawEther(uint256 value) public {
        require(_msgSender() == owner);
        address payable to = payable(owner);
        to.transfer(value);
    }
    
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {

    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AEDUToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "AEDU Token";
    string public constant symbol = "AEDU";
    uint8 public constant decimals = 18;
    

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    //determine who can and can't call contract fxns
    mapping(address => bool) authorized_map;
    
    

    uint256 totalSupply_;

    constructor(uint256 total) public {
        totalSupply_ = total*10**decimals;
        balances[msg.sender] = totalSupply_;
        authorized_map[msg.sender] = true;
    }

    function authorization(address newUser) public {
        if (authorized_map[newUser] == true) {
            revert("user already authorized");
        }

        authorized_map[newUser] = true;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        if (authorized_map[receiver] == false) {
            revert("user not authorized");
        }
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view override returns (uint) {
        if (authorized_map[delegate] == false) {
            revert("user not authorized");
        }
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function mint(address account, uint256 amount) external virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        if (authorized_map[account] == false) {
            revert("user not authorized");
        }

        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    //add actual mint fxn to add to total supply
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }


    
}
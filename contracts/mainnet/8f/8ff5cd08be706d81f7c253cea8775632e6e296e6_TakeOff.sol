/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

/**

Takeoff was the youngest member of Migos, which included Cardi B's husband Offset and musician Quavo. Takeoff was Quavo's nephew, and Offset was Takeoff's cousin. 

The three family members were reportedly raised together by Quavo's mother in Atlanta.

The Grammy-nominated group is known for "Bad and Boujee," "Walk It Talk It" and "MotorSport." 

Finner began the conference with a "human element," expressing how "very tough" it was to speak with Takeoff's mother following his death. 

"I spoke to this young man's mother just an hour ago, flew in here from out of town," he said. "I want everyone to understand the pain and suffering of a mother."


   
    
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TakeOff is IERC20 {
    using SafeMath for uint256;

    string public constant name = "TakeOff by Migos";
    string public constant symbol = "TAKEOFF";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 1000000000*10**uint256(decimals);

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {

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

    function allowance(address owner, address delegate) public override view returns (uint) {
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
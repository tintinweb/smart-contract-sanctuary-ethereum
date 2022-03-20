/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity^0.8.0;

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

interface ERC20Token {

    function totalSupply() external view returns (uint256); // This is a method to get the total supply of a token
    function balanceOf(address account) external view returns (uint256); // This is a method to get an accounts balance of a particular token
    function allowance(address owner, address spender) external view returns (uint256); // This is a method that specifies how many tokens the spender address can transfer from the allowance address
    function buyToken() external payable returns (bool); // This is a method that specifies is used to buy tokens and incrementing the total supply

    function transfer(address recipient, uint256 amount) external returns (bool); // This is a method to transfer a token to another account
    function approve(address spender, uint256 amount) external returns (bool); // this is a method that specifies allowing another address transfer tokens for another address
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value); // This is an event that is emmited after a transfer occurs
    event Approval(address indexed owner, address indexed spender, uint256 value); // This is an event that is emmited when a new approval has been created
    event TokenMint(address indexed minter, uint256 value); // This is an event that is emmitted when new tokens are minted

}


contract KosiToken is ERC20Token {
    using SafeMath for uint256;

    string public constant name = "Kosi Cash";
    string public constant symbol = "KSC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 total) {
        totalSupply_ = total * (10 ** decimals);
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
        balances[msg.sender] = balances[msg.sender].sub(numTokens); // remove numTokens from the message senders address
        balances[receiver] = balances[receiver].add(numTokens); // add numTokens to the message senders address
        emit Transfer(msg.sender, receiver, numTokens);  // emit the transfer event from the contranct
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens; //  set the amount of token that can be sent from an account
        emit Approval(msg.sender, delegate, numTokens); // emit an approval event
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }


    function buyToken() public override payable returns (bool) {
        uint256 amount = msg.value * 1000; // 1 ETH is 1000 KSC therefore 1 wei is 100 mini KSC
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_.add(amount);
        emit TokenMint(msg.sender, amount);
        return true;
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
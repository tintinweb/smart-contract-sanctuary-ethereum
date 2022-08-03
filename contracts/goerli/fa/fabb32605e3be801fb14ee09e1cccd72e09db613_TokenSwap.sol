/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity ^0.4.26;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract TokenSwap is SafeMath {
  address public admin; //the admin address, typically the owner
  address public input_token;
  address public output_token;
  address public burn_account;
  address public owner;
  uint public swap_multiplier;
  uint public swap_divider;
  uint public withdraw_amount;
  bool public burn_also;
  
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor() TokenSwap() public {

    owner = msg.sender;
    admin = 0xEAe12592170251D793e0F4d70A76fD0849be92eb; // must have output tokens + remember approvals
    input_token = 0x94C18174840F80D49d59DC3a1742aF0B884A8184; // SWAM - must be equal decimals 
    output_token = 0x556f501CF8a43216Df5bc9cC57Eb04D4FFAA9e6D;  // DUST - must be equal decimals OR adjust divider and multiplier
    burn_account = 0x000000000000000000000000000000000000dEaD;
    swap_divider = 1000000000000; // set default = 1, greater than 1 triggers safe div
    swap_multiplier = 100;
    burn_also = false;
  }

  function changeAdmin(address new_admin_) public {
    require(msg.sender == owner);
    admin = new_admin_;
  }

  function changeInputToken(address input_token_) public {
    require(msg.sender == owner);
    input_token = input_token_;
  }

  function changeOutputToken(address output_token_) public {
    require(msg.sender == owner);
    output_token = output_token_;
  }

  function changeMultiplier(uint multiplier_) public {
    require(msg.sender == owner);
    swap_multiplier = multiplier_;
  }
  
  function changeBurnOption(bool burn_also_) public {
    require(msg.sender == owner);
    burn_also = burn_also_;
  }

  //remember to call Token(address).approve(this, amount)
  function swapToken(address token, uint amount) public {
    require (token!=0);
    require (token == input_token);

    // transfer input tokens to admin
    require (ERC20Interface(token).transferFrom(msg.sender, this, amount));

    // if the decimals are not same and output token decimals are lower than input
    if (swap_divider > 1) {
        withdraw_amount = div(amount, swap_divider);
    }

    // multiplies with 1 or greater
    withdraw_amount = safeMul(amount, swap_multiplier);

    // Withdraw output tokens from admin 
    require (ERC20Interface(output_token).transferFrom(admin, msg.sender, withdraw_amount));

    // burn input tokens
    if (burn_also == true) {
        require (ERC20Interface(input_token).transferFrom(admin, burn_account, amount));
    }
  }

  function withdrawInputTokens() public {
    require (msg.sender == admin);
    uint input_balance = ERC20Interface(input_token).balanceOf(this);
    ERC20Interface(input_token).transfer(msg.sender, input_balance);
  }

  function balanceOf(address token, address user) constant public returns (uint) {
    return tokens[token][user];
  }

}
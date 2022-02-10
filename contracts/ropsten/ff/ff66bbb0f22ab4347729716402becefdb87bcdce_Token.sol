/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.6.0;

interface TEMP {

    function getTotalSupply() external view returns (uint256);
    function getBalanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function tokenTransfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function tokenTransferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event TokenTransfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token is TEMP {

    string public constant tokenName = "ChinaDreamToken";
    string public constant tokenSymbol = "CDT";
    uint8 public constant tokenDecimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) accountBalances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 tokenTotalSupply;

    using SafeMath for uint256;


   constructor(uint256 total) public {
    tokenTotalSupply = total;
    accountBalances[msg.sender] = tokenTotalSupply;
    }

    function getTotalSupply() public override view returns (uint256) {
    return tokenTotalSupply;
    }

    function getBalanceOf(address tokenOwner) public override view returns (uint256) {
        return accountBalances[tokenOwner];
    }

    function tokenTransfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= accountBalances[msg.sender]);
        accountBalances[msg.sender] = accountBalances[msg.sender].sub(numTokens);
        accountBalances[receiver] = accountBalances[receiver].add(numTokens);
        emit TokenTransfer(msg.sender, receiver, numTokens);
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

    function tokenTransferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= accountBalances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        accountBalances[owner] = accountBalances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        accountBalances[buyer] = accountBalances[buyer].add(numTokens);
        emit TokenTransfer(owner, buyer, numTokens);
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
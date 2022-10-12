// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract ERC20Basic {

    string public constant name = "KushG";
    string public constant symbol = "KG";
    uint8 public constant decimals = 18;

    address public timelock;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;

    modifier onlyTime(){
       require(msg.sender == timelock,"address not timelock");
       _;

    }


   constructor(address  _timelock){
    require(_timelock != address(0),"timelock addrss should not be zero");
    timelock = _timelock;
	totalSupply_ = 10000000;
	balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }

     function settime(address _time) public {
	    timelock = _time;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public onlyTime returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public onlyTime returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

      function mint(address user, uint256 amount) public onlyTime {
           balances[user] = balances[user].add(amount);
           totalSupply_ = totalSupply_.add(amount);
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
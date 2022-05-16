/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.4.24;




interface IERC20 {
    function balanceOf(address target) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);


    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address target, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    

    event Approval( address indexed owner, address indexed spender, uint256 value );

}








library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a ,"SafeMath: addition overflow");
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}






contract zzzzzzz is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) allowances;

    string public constant name = "aaaaa";
    string public constant symbol = "aaaaa";
    uint8 public constant decimals = 12;
    uint256 public constant totalSupply = 155e18;
    

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0)); 
        require(value <= balances[msg.sender] );
        balances[msg.sender] = balances[msg.sender].sub( value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address target) external view returns (uint256) {
        return balances[target];
    }



    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "ERC20: transfer to the zero address");
        require(to != address(0) , "ERC20: transfer to the zero address");
        require(value <= balances[from]);
        require(value <= allowances[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }



    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function allowance(address target, address spender) external view returns (uint256){
        return allowances[target][spender];
    }




}
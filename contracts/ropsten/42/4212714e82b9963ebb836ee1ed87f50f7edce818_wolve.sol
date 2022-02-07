/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

/* 

              ISSUES RESOLVED OF PREVIOUS TOKEN

1) CENTRALIZATION RISK : we have removed ownership from the contract,
 ownership already reannounced.

2)UNLOCK COMPILER VERSION: we have resolved that issue by using pragma 
solidity 0.8.9;  #line no 23

3)MIISING INPUT VALIDATION: we have resolved this issue by applying 
valid input validation. #line no 78,79

4)LOGICAL ISSUE OF INCREASE ALLOWANCE: we have resolved this issue also.#line no 63

5)LOCAL VARIABLE SHADOWING: we have removed shadow variable.

6)PROPER USE OF EXTERNAL AND PUBLIC: we have use proper PUBLIC and External in 
function. #line no 55,59,63,69,76,90,106


*/
pragma solidity 0.8.9;

//SPDX-License-Identifier: MIT Licensed

// Bep20 standards for token creation

contract wolve {
    
    using SafeMath for uint256;
 
    string  public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address=>uint256) private balances;
    mapping (address=>mapping (address=>uint256)) private allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        
        
        name = "wolve";
        symbol = "wlv";
        decimals = 18;
        totalSupply = 100000000000000e18;   
        balances[0x27B3f4601AEE5C8F4756312984Cecf538aE774Ce] = totalSupply;
    }

    function balanceOf(address _owner) view external returns (uint256) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view external returns (uint256) {
      return allowed[_owner][_spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        approve(spender, allowed[msg.sender][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = allowed[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            approve( spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address _to, uint256 _amount) external returns (bool success) {

        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

}
 
 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
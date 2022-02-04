/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.4.24;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a); // underflow 
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a); // overflow

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
   constructor() public  {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract MouseGroup is Ownable {
    address public owner; 
    address[] private investors;
    uint[] private investAmount;
    uint[] private investDispTokens;
    uint private minInvestMoney = 0.05 ether;
    uint private pre_millis = 0;

    event invest_record(address _from, uint _investMoney);
    event info_log(address _from, uint money, uint amount);
    
    constructor() public {
        owner = msg.sender;
    }
    function get_investor_len() public view returns(uint){
        return investors.length;
    }
    //投資
    function invest() public payable {
        require(
            msg.value >= minInvestMoney,
            "need more ether"
        );
        emit invest_record(msg.sender, msg.value);
        investors.push(msg.sender);  //push 就是把東西加進去陣列裡面
        investAmount.push(msg.value);
        investDispTokens.push(SafeMath.div(msg.value,100)); 
    }

    function get_investor_amount(address _target) public view returns (uint256){
        uint256 amount = 0;
        for(uint i = 0; i < investors.length; i++) {
            if(_target == investors[i]){
                amount = SafeMath.add(amount,investAmount[i]);
            }
            
        }
        return amount;
    }


    function has_investor(address target) public view returns (bool){
        for(uint i = 0; i < investors.length; i++) { 
            if(target == investors[i]){
                return true;
            }
        }
        return false;
    }
    //分配獎金
    function distribute() public onlyOwner{
        require(msg.sender == owner); // only owner
        require(now - pre_millis  > 10 minutes);
        //限制只能每天領一次！
        pre_millis = now;
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(investDispTokens[i]);
        }
    }

    function set_minInvest_money(uint money) public onlyOwner{
        require(money<=20,"Must less then 20 ether.");
        minInvestMoney = money;
    }

    function set_minInvest_money() public view returns (uint256){
        return minInvestMoney;
    }

    function get_disp_amount() public view returns (uint256){
        uint256 amount = 0;
        for(uint i=0; i<investDispTokens.length; i++){
            amount = SafeMath.add(amount, investDispTokens[i]);
        }
        return amount;
    }

    function get_amount() public view returns (uint256){
        uint256 amount = 0;
        for(uint i=0; i<investAmount.length; i++){
            amount = SafeMath.add(amount, investAmount[i]);
        }
        return amount;
    }
    
}
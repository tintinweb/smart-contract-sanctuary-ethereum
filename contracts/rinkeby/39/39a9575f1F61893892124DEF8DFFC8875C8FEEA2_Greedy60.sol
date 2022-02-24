pragma solidity ^0.4.24;

// import "github.com/Arachnid/solidity-stringutils/strings.sol";

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Greedy60 {

    using SafeMath for uint;
    // using strings for *;

    address public owner;
    address[] public investors; // 投資列表
    uint public expireTime;     // 到期時間 - 初始設定為交易被挖到時間+60秒   

    constructor() public payable{
        require(msg.value == 0.001 ether);
        expireTime = now + 3600;
        owner = msg.sender;
    }

    modifier timeNoExpire() {
        uint remainingTime = remainingSecond();
        require(remainingTime > 0 , "遊戲已結束");
        _;
    }

    modifier timeIsExpire() {
        uint remainingTime = remainingSecond();
        require(remainingTime == 0 , "遊戲尚未結束");
        _;
    }

    function invest() public payable timeNoExpire{
        require(msg.value == 0.001 ether, "金額限定0.001 ether");
        investors.push(msg.sender);
        expireTime += 60;
    }

    function getMoneyByLaster() public timeIsExpire{
        address lastInvestor = investors[investors.length.sub(1)];
        uint contractBalance = address(this).balance;
        lastInvestor.transfer(contractBalance);
        selfdestruct(owner);
    }

    function remainingSecond() public view returns (uint){
        if ((expireTime - now) > 365 * 24 * 60 * 60){
          return 0;
        }else {
          return expireTime - now;
        }
    }

    function setExpireTime(uint secondTime) external{
      require(owner == msg.sender);
      expireTime = now + secondTime;
    }

    function contractBalance() external view returns (uint){
      return address(this).balance;
    }
    
    function getAllInvestors() public view returns (address[]){
      return investors;
    }

}
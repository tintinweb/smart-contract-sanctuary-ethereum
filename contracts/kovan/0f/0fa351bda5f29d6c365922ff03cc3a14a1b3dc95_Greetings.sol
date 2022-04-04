/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/logan.sol

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Greetings is Context{

    using SafeMath for uint256;
    string public greeting;
    uint public updateTime;

    address public owner;

    AggregatorV3Interface internal priceFeed;

    constructor(string memory _greeting){
        owner = _msgSender();
        greeting = _greeting;
        updateTime = block.timestamp;
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);//ethusd on kovan network
    }

    function getLatestPrice() public view returns (int) {
    ( uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
    return price;
}

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function getLatestTime() public view returns (uint){
        return updateTime;
    }

    function getGreeting() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
    updateTime = block.timestamp;
  }

  function setGreetingPay(uint currentPrice, string memory _greeting) public payable{
      //require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
      //get the price for ether, bnb, sol, matic etc in $$ equivalent.


      //msg.value
    greeting = _greeting;
    updateTime = block.timestamp;
  }

    //function to transfer any erc20 token sent to the contract
  function withdrawTokens(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }

  //withdraw ETH sent to this token contract address to another address
  function withdrawETH() public onlyOwner payable{
    payable(owner).transfer(address(this).balance);
  }

    //fallback to receive ether or the blockchain crypto
    receive() external payable {}

}
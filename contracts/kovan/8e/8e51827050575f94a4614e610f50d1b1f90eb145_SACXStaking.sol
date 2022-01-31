/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface ISynth {
    function mint(uint256 amount, address staker) external returns (bool);
    function burn(uint256 amount, address staker) external;
}
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
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


interface ISACXToken {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
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
contract SACXStaking{

    using SafeMath for uint256;

    ISACXToken public SACXToken;
    uint256 public collatteralRatio = 750;
    mapping (address => Staker) public StakerInfo;
    ISynth public synthToken;
    uint256 public SACXprice;
    mapping (bytes32 => Synth) public getSynthAddress;
    AggregatorV3Interface internal priceFeed;
   


    event Transfer(address indexed from, address indexed to, uint256 value);


      struct Staker{ 
        uint256 TotalSACXStakedasCollateral; 
    }
     struct Synth{
        bytes32 _synth;
        string symbol;
        ISynth _contractAddress;
    }
   
    constructor(ISACXToken tokenaddress) public{
         SACXToken= tokenaddress;
         priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

     function MintSynths(string calldata _synth, uint256 amount) external {
        bytes32 __synth = stringToBytes32(_synth);
        synthToken = getSynthAddress[__synth]._contractAddress;
        uint256 synthPriceinUSD=getLatestPrice();//price of 1 synth e.g 1 sETH =100$
        uint256 totalsynthprice=synthPriceinUSD.mul(amount);//price of 10 synth e.g 10 sETH = 1000$
        
        uint256 collatteralPrice = (totalsynthprice.mul((collatteralRatio).div(100)));//price of the collateral we need to stake
        uint256 stprice=getSACXPRICE();//price of 1 SACX
        uint256 collatteralToStake=collatteralPrice.div(stprice);//amount of SACX that will be staked according to price

        require(SACXToken.balanceOf(msg.sender) >= collatteralToStake,"User does not have sufficient SACX to Mint synths");
        SACXToken.transferFrom(msg.sender,address(SACXToken),collatteralToStake);
        StakerInfo[msg.sender].TotalSACXStakedasCollateral= StakerInfo[msg.sender].TotalSACXStakedasCollateral.add(collatteralToStake);
        emit Transfer(msg.sender,address(SACXToken),collatteralToStake);
        synthToken.mint(amount,msg.sender);
 
    }
   
  function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            uint256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    function setSynthaddr(string  memory name,ISynth addr) public {
        bytes32 sname = stringToBytes32(name);
        getSynthAddress[sname]._synth=sname;
        getSynthAddress[sname].symbol=name;
        getSynthAddress[sname]._contractAddress=addr;
        
    }
    function setSACXPRICE(uint256 price) public {
        
        SACXprice=price;
    }
     function getSACXPRICE() public returns(uint256){
        return SACXprice;
        
    }
     function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
        
    }

  
}
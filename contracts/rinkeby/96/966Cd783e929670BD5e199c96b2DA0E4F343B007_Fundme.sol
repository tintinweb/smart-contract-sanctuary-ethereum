pragma solidity ^0.6.0;
// link:
//https://github.com/smartcontractkit/chainlink/blob/eb8d050e82068881a012fdcf86b3d3fa66d47a38/contracts/src/v0.4/interfaces/AggregatorV3Interface.sol
//https://github.com/smartcontractkit/chainlink/blob/eb8d050e82068881a012fdcf86b3d3fa66d47a38/contracts/src/v0.4/vendor/SafeMathChainlink.sol
import "SafeMathChainlink.sol";
import "AggregatorV3Interface.sol";
contract Fundme{
    using SafeMathChainlink for uint256;
    address[]  public funder; // funded to contract
    // owner of contract
    AggregatorV3Interface public price_fed;
    address public owner;
    constructor (address _priceFed) public {
        price_fed = AggregatorV3Interface(_priceFed);
        owner = msg.sender;
    }
    mapping (address=> uint256) public addresstouint256;
    function  fundme() public payable {
        addresstouint256[msg.sender] += msg.value;
        funder.push(msg.sender);
    }
    // get version 
    function getversion() public view returns(uint256){
       // AggregatorV3Interface  = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return price_fed.version();
    }
    // get price
    function getprice() public view returns(uint256){
       // AggregatorV3Interface price_fed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
       ( ,int256 answer,,,)=price_fed.latestRoundData();
       return uint256(answer);
    }
    //consion of price
    function convisionrate(uint256 ether_amt) public view returns(uint256){
        uint256 price_per= getprice();
        uint256 eth_usd = (price_per*ether_amt)/100000000;
        return eth_usd;
    }
    // to check contract owner
    modifier onlyowner{
       // _;
        require(msg.sender == owner);
        _;
    }
    //withdraw transfer to owner account
    function withdraw() public onlyowner payable {
        msg.sender.transfer(address(this).balance);
        for (uint8 i=0; i<funder.length; i++ ){
            address funder_add =funder[i];
            addresstouint256[funder_add]=0;
        }
        funder =new address[](0);
    }

}

pragma solidity ^0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMathChainlink {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

pragma solidity >=0.4.24;

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
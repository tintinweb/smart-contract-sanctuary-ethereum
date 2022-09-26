/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: contracts/FundCause.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;



contract funding is ReentrancyGuard{
    
    address immutable i_owner;
    uint256 public constant  MINIMUM_USD = 10*1e18; 

    address[] public funders;  
    mapping(address => uint256)public addressToAmountFunded;

    constructor(){
        i_owner = msg.sender;
    }

    function receivemoney() public payable{
        require(getConversionRate(msg.value) >= MINIMUM_USD, "Please send minimum USD");
          funders.push(msg.sender);
          addressToAmountFunded[msg.sender] += msg.value;

    }
    modifier onlyOwner{
        require(msg.sender == i_owner, "you are not the owner");
        _;
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,, )= priceFeed.latestRoundData();
        return uint256(price*1e18);//typecasting because msg.value is in uint256 and price is in int256 price=3000000000000000...(price in usd)*1*10000000000000000000(1 eth in wei)
    }
    function getConversionRate(uint amountInEth) public view returns(uint256) {
        uint ethPrice = getPrice();
        uint ethPriceInUSD = (ethPrice*amountInEth)/1e18;
        return ethPriceInUSD;

    }
    function withdrawMoney() public onlyOwner nonReentrant{
        for(uint i = 0; i<=funders.length; i++){
            address funder = funders[i];
            addressToAmountFunded[funder]=0;
        }
        payable(msg.sender).transfer(address(this).balance);
    
        
    }
    receive() external payable{
        receivemoney();
    }
    fallback() external payable{
        receivemoney();
    }

}
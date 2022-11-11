// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//importing interface with the pricefeed oracle from chainlink
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";//should be the same as op-zep
//SafeMath is nolinger needed from Solidity 0.8.0 onwards.

// this contract should be able to accept some type of payment
contract FundMe {
    // using SafeMathChainlink for uint256;//will prevent overflow for all uint256
    //"using A for B" is used to attach functions from library A to type B.

    // this mapping is meant to keep track of who pays us by associating
    // addresses to corresponding values
    mapping(address => uint256) public addressToAmmountFunded;
    address public owner;
    address [] public funders;//for ressetting all balances to 0 after withdrawals
    //cant use mapping to loop bekause all the keys are initialized the moment it's created

    //constructor to make the "owner" of his contract the person that deploys it so that
    //they will have access to the withdraw function.
    constructor() public{
        owner=msg.sender;
    }

    // 'payable' means that this function can be used to receive payment (be paid) for things
    // this function will keep track of people who sent us money by using the mapping created
    function fund() public payable{
        // 'msg.sender' returns the address of the sender, and msg.value returns the amount sent.
        // when someone calls the fund function and sends money
        // we will save their address and amount using the mapping value
        //********
        //Settimg minimum threshold to 50usd but in gwei
        uint256 minimumUSD = 50*10**18; // converted 50usd to wei 50+ 
        //if the entered amount is less than the min, the transaction will be reverted
        //revert=full refund of entered money+gas fees. Revert message will also be displayed
        require(getConversionRate(msg.value) >= minimumUSD, "Spent less than minimum ETH!!!");
        addressToAmmountFunded[msg.sender] += msg.value;//adding addy and value to assoc. mapping
        funders.push(msg.sender);// adding funder addy to the array   
    }

    //function from the interface to get the version of the chainlink pricefeed oracle
    function getVersion() public view returns (uint256) {
//We define an instance of a inherited contract or interface the same way we define a variable or struct
//type(cont/intrfc)Name varName = typeName(blockchain_address)
//only after instantiating it can you use the function you intended on calling fron the interface/contract      
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

      /*
        CONVERSIONS
        If we want to use a different currency or token in our contract, like USD, we'll need
        1. ETH -> USD conversion rate
        2. where to get the data from
        3. how to get it into our contract

        */

    //calling getPrice function from interface
    function getPrice() public view returns(uint256){
         AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        //below is a tuple, and it is used to define several variables at once
        (
        //  uint80 roundId,
         ,int256 answer,,,//replacing unsused variables with commas to clean up code
        //  uint256 startedAt,
        //  uint256 updatedAt,
        //  uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        //typecasting 'answer' from int256 to uint256
        return uint256(answer*10000000000);// answer will have 8 decimal places (chainlink setting).
        //multiply answer by 10,000,000,000 to give it 18 decimal places and turn  it to wei (1 with 18 zeros)
        // 1ETH = $1,292.588585270000000000
    }
    
    //function to convert incoming ETH to USD
    function getConversionRate(uint256 ethAmmount) public view returns(uint256){
        uint256 ethPrice = getPrice(); //getPrice functon from above
        uint256 ethAmmountInUsd = (ethPrice*ethAmmount)/10**18;//(10 with 18 zeros) removing the 18 zeros from ethPrice
        return ethAmmountInUsd; //the decimal places will depend on the ethAmmount that was fed
        //convert 1000000000 wei (1 gwei or 0.000000001 eth) to USD
        //$0.000001292588585270 make sure final answer has 18 dec places because everything is in
        //terms of wei (we converted wei to begin with)
        //50000000000000000 wei = $64.629429263500000000 $50= wei 0.0000646294292635
    }


    //creating an owner modifier
    modifier onlyOwner(){
        require(msg.sender==owner, "Only the Owner can make a withdraw!!!");
        _; //= run the rest of the code. can be before modifier body depending on circumstances
    }
    //function to eithdraw/refund eth
    function withdraw() payable onlyOwner public{
        // require (msg.sender == owner); //makes sure only the owner can request a withdraw
        payable(msg.sender).transfer(address(this).balance);
        //transfer is uset to move ETH between two addresses and takes an ammount as an argument
        //address(this) returns the address where the contract making that addy(ths) call is located
        //balance refers to all the money stored in any geven address
        //address(this).balance will return all the money in the address containing the contract 
        //msg.sender is the account that will receive the payment in the transfer call
        //from Solidity 0.8, it's not payable by default and has to be stated explicitly

        //for-loop to reset balances of all the addresses in the mapping
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            // address funder = funders[funderIndex]; //addy @ array indx set to addy var
            // addressToAmmountFunded[funder]=0; addy var used as map key to reset balance
            addressToAmmountFunded[funders[funderIndex]]=0;//one-line solution
        }

        //resetting funders array
        funders = new address[](0);

    }
}

 // once deployed, the user will enter a value and hit the fund button.
 // afther the funding, the amount and address of the funder are stored into the mapping.
 // to make use of the mapping, copying the address into the mapping function will show you
 // how much was sent from that address.
 // Furthermore, whoever deploys the contract will be the ownder of the received money.

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
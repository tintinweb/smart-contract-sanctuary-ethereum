//SPDX-License_Identifier:MIT
pragma solidity ^0.6.6;
/*
Price to solidiyt 0.8, if I add to the maximum size , it would wrap around to hte lowest number
that it would be. 
*/
/*
ABI= APplication Binary Interface. ABI tells solidity and other programming langauge what functions
can be called. what functions it can call other contracts with. 
Anytime I interact with an already deployed smart contract, I need an ABI of that contract.  
interfaces compile down to an ABI. I always need an ABI to interact with a a contract. 
interact with interface is the same as interacting with a struct or a variable. 
*/
/*
import - stick the code I import , and stick it at the top of my project. 
*/
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

/*
Accept some type of payment
*/
contract FundMe {
    using SafeMathChainlink for uint256;
    mapping(address => uint256) public addressToAmountFunded;
    //an array of all funders' addresses
    address[] public funders;
    address public owner;

    /*this function is called the instant that my contract is deployed. 
    it is immediately executed whenever we deploy this contract.*/
    constructor() public {
        owner = msg.sender; //the sender is whoever deploys the contract.
    }

    /*
    a payable function, i.e., define the function as payable, this function can be used to
    pay for things. every function as an associated value with it. whenever you make a transaction,
    you can always append a value. This value is how much Gwei, Wei, Either i will send
    with my function call or my transaction.
    Look at eth-converter.com: 1 ETH=10^9 Gwei=10^18 Wei.
    1 Wei is the smallest denomination of ETH. I cannot break ETH to anything smaller than 1 Wei. 
    Wei is the smallest measure in Ethereum. 
    Once deployed, the fund buton is shown in red in deployment, because fund() is a payable 
    function. 
    Decimals don't exist in solidity. 

    Keep track of all people who sent me money
    msg.sender and msg.value are keywords in every contract call and every transaction; 
    msg.sender - the sender of the function call, 
    msg.value - how much the sender sent. 
    */
    function fund() public payable {
        /*save everything in address to amount funded mapping
         */
        //$50 minimum , everything in Wei term
        uint256 minimumUSD = 50 * 10**18;
        /*
        if(msg.value <minimumUSD){
            revert;
        }
        */
        /* if the sender did not send enough ETH, then do a revert. meaning that the 
        user will get money back as wellas any unspent gas. I can add revert message. 
        */
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        /*what the ETH->USD conversion rate
        //accept Ethereum as the token. 
        //a blockchain oracle. 
        //blockchain is a deterministic system. Oracle is the bridge between blockchains
        //and the real world. Blockchians are deterministic systems 
        //a blockchain can easily say 1+1=2
        //a block chain cannot say that let's all grab the same random number, because
        //each node is going to grab a different random number. It cannot say let's make an
        API call, becuase if one node calls the API at a different time, another node
        calls it, that could lead to different results. If another node tries to replay
        these transactions by calling these APIs again, e.g., 10 yeras in the future, the API
        is likely depreciating.  Blockchain cannot make API calls. 
        Centralized oracles are main points of failures. 
        if we put the oracle on chain, we would have a massive centralized point of failure. 
        the reason for blockchain is that no single entity can flip a switch. if we place
        the oracle on chain, then a single entity can flip the switch, and restrict our freedom
        to interact with each other. 
        We also need to get data from many decentralized sources. 
        chainlink is a modular decentralized oracle infrastructure that allows us to get data
        and do external computation in a highly civil resistant decentralized manner. I can run
        with one node or as many nodes as I like. 
        See data.chain.link to see feeds and the networks that provide the price feeds. a whole
        number of decentralized different oracles returning data for different price feeds. 
        have a decentralized network, and bring data on chain. the price feeds are powerful. 

        */
    }

    function getVersion() public view returns (uint256) {
        /*
        to find out the contract address, go to https://docs.chain.link/docs/ethereum-addresses/
        the contract address is located on an actual test net. 
        It is not located on my simultaed chain.
        so I need to deploy my contract on a test net. 
        */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    /*When I tested on March 2, 2022, it took about 20 seconds to deploy the contract.
    for variables that I don't use, I can use commas, 
    for example, instead of (uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,
        uint80 answeredInRound)
        I can use (,int256 answer,,,) to make code cleaner
    */

    /*getPrice will return price in 18 decimical places.  */
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        /*If i just return answer, which is int256, that is the wrong type. 
    I can use uint256() to wrap around answer
        to make it have 18 decimals: *10000000000. this will return prices with 18 decimal places.
    */

        return uint256(answer * 10000000000);
    }

    //Wei 10000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
        //the return has 18 decimal places. so if the return is 2949912415240, then it is
        //actually 0.000002949912415240. this is 1Gwei in USD. 1ETH = 1000000000Gwei.
        //then multiple these two, we get 1ETH = 2949.91241524 USD.
    }

    /*A modifier is used to change the behavior of a function in a declarative way*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // underscore means the execution of the function where modifier is called.
        //if _ is positioned above require, then the function is executed prior to require
        //if _ is positioned below reuqire, then the functoin is executed after require.
    }

    /*This is a payable function because we are going to transfer ETH*/
    function withdraw() public payable onlyOwner {
        /*this refers to the contract I am currently in .
        address(this) : the address of the current contract
        address.balance: the balance in ETH of the contract; 
        whoever called the withdraw function, which is msg.sender, transfer to this msg.sender 
        all money in the contract. 
        only the contract owner can withdraw the fund.
        require msg.sender = owner;  
        == is how solidty understands true or false
        */

        //require(msg.sender==owner);
        msg.sender.transfer(address(this).balance);
        //reset everybody's balance to zero, using a for loop to loop through a range
        //to do things at each loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the funders array. An easy way is to set funders to a new array.
        funders = new address[](0);
    }
}

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
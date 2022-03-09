/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.24;

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

//import "AggregatorV3Interface.sol"
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

contract insuranceProvider {
    using SafeMathChainlink for uint;
    address public insurer = msg.sender;
    uint public constant DAY_IN_SECONDS = 60; //How many seconds in a day. 60 for testing, 86400 for Production
    AggregatorV3Interface internal priceFeed;
     //here is where all the insurance contracts are stored.
    mapping (address => InsuranceContract) contracts;

      constructor()   public payable {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }


     modifier onlyOwner() {
		require(insurer == msg.sender,'Only Insurance provider can do this');
        _;
    }

    event contractCreated(address _insuranceContract, uint _premium, uint _totalCover);

        /**
     * @dev Create a new contract for client, automatically approved and deployed to the blockchain
     */
    function newContract(address _client, uint _duration, uint _premium, uint _payoutValue, string memory _cropLocation) public payable onlyOwner() returns(address) {


        //create contract, send payout amount so contract is fully funded plus a small buffer
        //InsuranceContract i = (new InsuranceContract).value((_payoutValue * 1 ether).div(uint(getLatestPrice())))(_client, _duration, _premium, _payoutValue, _cropLocation);
        InsuranceContract i = new InsuranceContract(_client,_duration,_premium,_payoutValue,_cropLocation);
        //i.transfer(_payoutValue);

        contracts[address(i)] = i;  //store insurance contract in contracts Map

        //emit an event to say the contract has been created and funded
        emit contractCreated(address(i), msg.value, _payoutValue);



        return address(i);

    }

     /**
     * @dev returns the contract for a given address
     */
    function getContract(address _contract) external view returns (InsuranceContract) {
        return contracts[_contract];
    }


        /**
     * @dev updates the contract for a given address
     */
    // function updateContract(address _contract) external {
    //     InsuranceContract i = InsuranceContract(_contract);
    //     i.updateContract();
    // }

       /**
     * @dev Get the insurer address for this insurance provider
     */
    function getInsurer() external view returns (address) {
        return insurer;
    }


        /**
     * @dev Get the status of a given Contract
     */
    // function getContractStatus (payable address _address) external view returns (bool) {
    //     InsuranceContract i = InsuranceContract(_address);
    //     return i.getContractStatus();
    // }

    /**
     * @dev Return how much ether is in this master contract
     */
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

        function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function() external payable{}



}



contract InsuranceContract is Ownable {
    AggregatorV3Interface internal priceFeed;

    uint public constant DAY_IN_SECONDS = 60; //How many seconds in a day. 60 for testing, 86400 for Production
    uint public constant DROUGHT_DAYS_THRESDHOLD = 3 ;  //Number of consecutive days without rainfall to be defined as a drought
    uint256 private oraclePaymentAmount;

    address public insurer;
    address  client;
    uint startDate;
    uint duration;
    uint premium;
    uint payoutValue;
    string cropLocation;


    uint256[2] public currentRainfallList;
    bytes32[2] public jobIds;
    address[2] public oracles;


    uint daysWithoutRain;                   //how many days there has been with 0 rain
    bool contractActive;                    //is the contract currently active, or has it ended
    bool contractPaid = false;
    uint currentRainfall = 0;               //what is the current rainfall for the location
    //uint currentRainfallDateChecked = blockchain.timeStamp;  //when the last rainfall check was performed
    uint requestCount = 0;                  //how many requests for rainfall data have been made so far for this insurance contract
    uint dataRequestsSent = 0;             //variable used to determine if both requests have been sent or not
        /**
     * @dev Prevents a function being run unless it's called by Insurance Provider
     */
    // modifier onlyOwner() {
	// 	require(insurer == msg.sender,'Only Insurance provider can do this');
    //     _;
    // }

    /**
     * @dev Prevents a function being run unless the Insurance Contract duration has been reached
     */
    modifier onContractEnded() {
        if (startDate + duration < now) {
          _;
        }
    }

    /**
     * @dev Prevents a function being run unless contract is still active
     */
    modifier onContractActive() {
        require(contractActive == true ,'Contract has ended, cant interact with it anymore');
        _;
    }

        /**
     * @dev Return how much ether is in this master contract
     */
    // function getContractBalance() external view returns (uint) {
    //     return address(this).balance;
    // }

        function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }


    event contractCreated(address _insurer, address _client, uint _duration, uint _premium, uint _totalCover);
    event contractPaidOut(uint _paidTime, uint _totalPaid, uint _finalRainfall);
    event contractEnded(uint _endTime, uint _totalReturned);

        /**
     * @dev Creates a new Insurance contract
     */
    constructor(address _client, uint _duration, uint _premium, uint _payoutValue, string memory _cropLocation)  payable Ownable() public {

        //set ETH/USD Price Feed
        //priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        //first ensure insurer has fully funded the contract
        //require(msg.value >= _payoutValue.div(uint(getLatestPrice())), "Not enough funds sent to contract");

        //now initialize values for the contract
        insurer= msg.sender;
        client = _client;
        startDate = now ; //contract will be effective immediately on creation
        duration = _duration;
        premium = _premium;
        payoutValue = _payoutValue;
        daysWithoutRain = 0;
        contractActive = true;
        cropLocation = _cropLocation;

        //set the oracles and jodids to values from nodes on market.link
        //oracles[0] = 0x240bae5a27233fd3ac5440b5a598467725f7d1cd;
        //oracles[1] = 0x5b4247e58fe5a54a116e4a3be32b31be7030c8a3;
        //jobIds[0] = '1bc4f827ff5942eaaa7540b7dd1e20b9';
        //jobIds[1] = 'e67ddf1f394d44e79a9a2132efd00050';

        //or if you have your own node and job setup you can use it for both requests
        // oracles[0] = 0x05c8fadf1798437c143683e665800d58a42b6e19;
        // oracles[1] = 0x05c8fadf1798437c143683e665800d58a42b6e19;
        // jobIds[0] = 'a17e8fbf4cbf46eeb79e04b3eb864a4e';
        // jobIds[1] = 'a17e8fbf4cbf46eeb79e04b3eb864a4e';

        emit contractCreated(insurer,
                             client,
                             duration,
                             premium,
                             payoutValue);
    }

        /**
     * @dev Insurance conditions have been met, do payout of total cover amount to client
     */
    function payOutContract() private onContractActive()  {

        //Transfer agreed amount to client
        client.transfer(address(this).balance);

        //Transfer any remaining funds (premium) back to Insurer
        // LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        // require(link.transfer(insurer, link.balanceOf(address(this))), "Unable to transfer");

        emit contractPaidOut(now, payoutValue, currentRainfall);

        //now that amount has been transferred, can end the contract
        //mark contract as ended, so no future calls can be done
        contractActive = false;
        contractPaid = true;
    }

        /**
     * @dev Get the balance of the contract
     */
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev Get the Crop Location
     */
    // function getLocation() external view returns (string) {
    //     return cropLocation;
    // }


    /**
     * @dev Get the Total Cover
     */
    function getPayoutValue() external view returns (uint) {
        return payoutValue;
    }


    /**
     * @dev Get the Premium paid
     */
    function getPremium() external view returns (uint) {
        return premium;
    }

    /**
     * @dev Get the status of the contract
     */
    function getContractStatus() external view returns (bool) {
        return contractActive;
    }

     /**
     * @dev Get whether the contract has been paid out or not
     */
    function getContractPaid() external view returns (bool) {
        return contractPaid;
    }

        /**
     * @dev Get the contract duration
     */
    function getDuration() external view returns (uint) {
        return duration;
    }

    /**
     * @dev Get the contract start date
     */
    function getContractStartDate() external view returns (uint) {
        return startDate;
    }

    /**
     * @dev Get the current date/time according to the blockchain
     */
    function getNow() external view returns (uint) {
        return now;
    }

    
       /**
     * @dev Fallback function so contrat can receive ether when required
     */
    //function() external payable {  }
    
    function() external payable{}

}
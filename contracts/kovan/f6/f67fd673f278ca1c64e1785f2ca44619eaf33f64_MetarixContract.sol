/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      uint256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

//OWnABLE contract that define owning functionality
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
  constructor() public {
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

//SeedifyFundsContract

contract MetarixContract is Ownable {

  AggregatorInterface internal priceFeed;

  //token attributes
  string public constant NAME = "Metarix"; //name of the contract
  uint public immutable maxCap; // Max cap in BNB
  uint256 public immutable saleStartTime; // start sale time
  uint256 public immutable saleEndTime; // end sale time
  uint256 public totalBnbReceived; // total bnd received
  uint public totalBuys; // total buys in ido
  address payable public projectOwner; // project Owner

  mapping (address => uint256) public getBalanceByAddress;
  
  // CONSTRUCTOR  
  constructor(uint _maxCap, uint256 _saleStartTime, uint256 _saleEndTime, address payable _projectOwner) public {
    require(_maxCap != 0, "_maxCap should not equal to 0!");
    maxCap = _maxCap*10**18;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
    projectOwner = _projectOwner;   
    priceFeed = AggregatorInterface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
  }

    /**
     * Returns the latest price
     */
    function getLatestBnbUsdPrice() public view returns (uint256) {
        return priceFeed.latestAnswer()/100000000;
    }

    function getLatestPrice() public view returns (uint256) {
        return getLatestBnbUsdPrice();
    }
 
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
        totalBuys +=1;
    }
 
  // send bnb to the contract address
  function buy() external payable {

     require(now >= saleStartTime, "The sale is not started yet "); // solhint-disable
     require(now <= saleEndTime, "The sale is closed"); // solhint-disable
     require(totalBnbReceived + msg.value <= maxCap, "buyTokens: purchase would exceed max cap");
     require(getBalanceByAddress[msg.sender]*getLatestPrice() <= 5000, "You have exceeded max dollar price 5000!");
      getBalanceByAddress[msg.sender]=getBalanceByAddress[msg.sender]+msg.value;
      totalBnbReceived += msg.value;
      sendValue(projectOwner, address(this).balance);      
   
  }
}
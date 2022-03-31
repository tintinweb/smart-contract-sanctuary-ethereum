// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "Ownable.sol";
import "EthUsPriceConversion.sol";
import "MyStorage.sol";

contract Wrapper is Ownable {

    address sc_owner;

    MyStorage internal myStorage;
  //  EthUsPriceConversion internal ethUsConvert;
   // enum STATE { OPEN, END, CLOSED }

    constructor(
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
        ) payable {
            sc_owner = msg.sender;
           // ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, _minimumEntreeFee);
            myStorage = new MyStorage(
                sc_owner,
                _priceFeedAddress,
                _minimumEntreeFee,
                _subscriptionId,
                _callbackGasLimit,
                _vrfCoordinator,
                _link,
                _keyHash
            );
        }


    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        myStorage.start();
    }

    /**
     * @notice It is ended.
     */
    function end() external onlyOwner {
        myStorage.end();
    }

    /**
     * @notice It is closed.
     */
    function closed() external onlyOwner {
        myStorage.closed();
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       return myStorage.getETHprice();
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     */
    function getETHpriceUSD() external view returns (uint256) {
        return myStorage.getETHpriceUSD();
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        return myStorage.getEntranceFee();
    }

    /**
     * @notice Update minimum funding amount
     */
  /*  function setEntranceFee(uint32 min_Entree_Fee) external onlyOwner {
        myStorage.setEntranceFee(min_Entree_Fee);
    }
*/

    /**
     * @notice Update the gas limit for callback function 
     */
    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        myStorage.setCallbackGasLimit(gasLimit);
    }

    /**
     * @notice Get current state.
     */
    function getCurrentState() external view returns (string memory) {
        return myStorage.getCurrentState();
    }

    /**
     * @notice Update the funding state
     */
    function setState(uint32 newState) external onlyOwner {
        return myStorage.setState(newState);
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRequestID() external onlyOwner view returns (uint256) {
        return myStorage.getRequestID();
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstWord() external onlyOwner view returns (uint256) {
        return myStorage.getFirstWord();
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondWord() external onlyOwner view returns (uint256) {
        return myStorage.getSecondWord();
    }

    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send() external payable {
        // $50 minimum
        myStorage.send(msg.sender, msg.value);
    }

    /**
     * @notice Owner withdraw.
     */
    function wdraw() external payable onlyOwner {
        return myStorage.wdraw();
    }

    /**
     * @notice Get the balance of the user.
     */
    function getUserBalance(address user) external view returns (uint256) {
        return myStorage.getUserBalance(user);
    }

    /**
     * @notice Get the total amount in this account.
     */
    function getTotalAmount() external view returns (uint256) {
        return myStorage.getTotalAmount();
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function collect() external onlyOwner {
        myStorage.collect();
    }

    /**
     * @notice Transfer to amount to recipient
     * 
     * @param recipient - recipient of the transfer
     * @param amount - amount to transfer
     */
    function transfer(address recipient, uint amount) external onlyOwner returns (bool success){
        myStorage.transfer(recipient, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Get the latest ETH/USD price from chainlink price feed
import "AggregatorV3Interface.sol";

contract EthUsPriceConversion {

    uint256 internal usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    constructor(
        address _priceFeedAddress,
        uint256 minumum_entry_fee
    ) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdEntryFee = minumum_entry_fee * (10**18);
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        return adjustedPrice;
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     * 1000000000
     */
    function getETHpriceUSD() external view returns (uint256) {
        uint256 ethPrice = this.getETHprice();
        uint256 ethAmountInUsd = ethPrice / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        uint256 adjustedPrice = this.getETHprice();

        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";
import "EthUsPriceConversion.sol";
import "IEth.sol";

contract MyStorage is IEth, VRFConsumerBaseV2, Ownable {

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    EthUsPriceConversion internal ethUsConvert;

    // VRF subscription ID.
    uint64 subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash;

    // Minimum Entry Fee to fund
   // uint32 minimumEntreeFee;

    // Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. 
    uint32 callbackGasLimit;

    // The default is 3.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    uint256[] randomWords;
    uint256 requestId;
    address s_owner;

   // address payable[] payers;

  //  enum STATE { OPEN, END, CLOSED }
    STATE internal state;

    // To keep track of the balance of each address
    mapping (address => uint256) internal balanceOfUsers;
    address[] internal senders;
    uint256 totalAmount;

    event fulfill(uint256 requestId);
    event requestWord(uint256 requestId);

    
    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param _subscriptionId - the subscription ID that this contract uses for funding requests
     * @param _vrfCoordinator - coordinator
     * @param _keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address _owner,
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) payable {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        //minimumEntreeFee = _minimumEntreeFee;
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, _minimumEntreeFee);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        s_owner = _owner;
        subscriptionId = _subscriptionId;
        state = STATE.CLOSED;
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       return ethUsConvert.getETHprice();
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     */
    function getETHpriceUSD() external view returns (uint256) {
        return ethUsConvert.getETHpriceUSD();
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        return ethUsConvert.getEntranceFee();
    }


    /**
     * @notice Update the gas limit for callback function 
     * @param gasLimit - max gas limit
     */
    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner{
        callbackGasLimit = gasLimit;
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRequestID() external onlyOwner view returns (uint256) {
        return requestId;
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstWord() external onlyOwner view returns (uint256) {
        return randomWords[0];
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondWord() external onlyOwner view returns (uint256) {
        return randomWords[1];
    }

    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        require(
            state == STATE.CLOSED,
            "Can't start yet! Current state is not closed yet!"
        );
       state = STATE.OPEN;
    }

    /**
     * @notice It is ended.
     */
    function end() external onlyOwner {
        require(state == STATE.OPEN, "Not opened yet.");
        state = STATE.END;
    }

    /**
     * @notice It is closed.
     */
    function closed() external onlyOwner {
        require(state == STATE.END, "Not ended yet.");
        state = STATE.CLOSED;
    }

     /**
     * @notice Update minimum funding amount
     * @param min_Entree_Fee - minimum amount to send
     */
  /*  function setEntranceFee(uint32 min_Entree_Fee) external onlyOwner {
        minimumEntreeFee = min_Entree_Fee;
    }
    */

    /**
     * @notice Get current funding state.
     */
    function getCurrentState() external onlyOwner view returns (string memory) {
        require((state == STATE.OPEN || state == STATE.END || state == STATE.CLOSED), "unknown state.");
        if (state == STATE.OPEN)
            return "open";
        else if (state == STATE.END)
            return "end";
        else if (state == STATE.CLOSED)
            return "closed";
        else 
            return "unknow state";
    }

     /**
     * @notice Update the funding state
     * @param newState - change the state
     */
    function setState(uint32 newState) external onlyOwner {
        require((newState >= 0 && newState <=2), "Invalid number for state.");
        if (newState == 0)
            state = STATE.OPEN;
        else if(newState == 1)
            state = STATE.END;
        else if(newState == 2)
            state = STATE.CLOSED;
    }

    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send(address sender, uint value) external payable onlyOwner {
        // $50 minimum
        require(state == STATE.OPEN, "Can't send yet.");
        //require(value >= minimumEntreeFee, "Not enough ETH! Minimum $50 value of ETH require!");
        require(value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        // Check for overflows
        require(balanceOfUsers[sender] + value >= balanceOfUsers[sender], "Overflow.");
       // payers.push(payable(sender));
        balanceOfUsers[payable(sender)] += value;
        senders.push(payable(sender));
        totalAmount += value;
    }

   
    /**
     * @notice Get the total amount in this account.
     */
    function getTotalAmount() external onlyOwner view returns (uint256) {
        //return address(s_owner).balance;
        return totalAmount;
    }

    /**
     * @notice Get the balance of the user.
     * @param user - the address of the query balance
     */
    function getUserBalance(address user) external onlyOwner view returns (uint256) {
        return balanceOfUsers[user];
    }

    /**
     * @notice Owner withdraw.
     */
    function wdraw() external onlyOwner {

        require(
            state == STATE.END,
            "Not ended yet!"
        );
        requestRandomWords();
        state = STATE.CLOSED;
    }

    /**
     * Reset the storage.
     */
    function reset() internal {
        for ( uint256 index = 0; 
            index < senders.length;
            index++
        ) {
            address sender = senders[index];
            balanceOfUsers[sender] = 0;
        }
        senders = new address[](0);
    }
    /**
     * @notice Owner withdraw the funding.
     */
    function collect() external onlyOwner {
        //require(address(this).balance > 0, "No transaction. Balance is 0");
        require(totalAmount > 0, "No transaction. Balance is 0");
        payable(s_owner).transfer(totalAmount);
        totalAmount = 0;
        reset();
       // payable(s_owner).transfer(address(this).balance);
       // payers = new address payable[](0);
        state = STATE.CLOSED;
    }


    /**
    * @notice Requests randomness
    * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        emit requestWord(requestId);
    }

    /*
    * @notice Callback function used by VRF Coordinator
    *
    * @param requestId - id of the request
    * @param randomWords - array of random results from VRF Coordinator
    */
    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory _randomWords
    ) internal override { 
        require(address(this).balance > 0, "No transaction. Balance is 0");
        randomWords = _randomWords;   
        payable(s_owner).transfer(totalAmount);
        totalAmount = 0;
        reset();
        state = STATE.CLOSED;
        emit fulfill(requestId);
    }

    /**
     * @notice Transfer to amount to recipient
     * 
     * @param recipient - recipient of the transfer
     * @param amount - amount to transfer
     */
    function transfer(address recipient, uint256 amount) external payable onlyOwner returns (bool success){
        require(recipient != address(0), "Can't transfer to address: 0");
        require(amount > 0, "Transfer amount must be greater than 0.");
        require(totalAmount > amount, "Not enough fund to transfer");
        payable(recipient).transfer(amount);
        balanceOfUsers[recipient] -= amount;
        totalAmount -= amount;
        return true;
    }
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {

  /**
   * @notice Returns the global config that applies to all VRF requests.
   * @return minimumRequestBlockConfirmations - A minimum number of confirmation
   * blocks on VRF requests before oracles should respond.
   * @return fulfillmentFlatFeeLinkPPM - The charge per request on top of the gas fees.
   * Its flat fee specified in millionths of LINK.
   * @return maxGasLimit - The maximum gas limit supported for a fulfillRandomWords callback.
   * @return stalenessSeconds - How long we wait until we consider the ETH/LINK price
   * (used for converting gas costs to LINK) is stale and use `fallbackWeiPerUnitLink`
   * @return gasAfterPaymentCalculation - How much gas is used outside of the payment calculation,
   * i.e. the gas overhead of actually making the payment to oracles.
   * @return minimumSubscriptionBalance - The minimum subscription balance required to make a request. Its set to be about 300%
   * of the cost of a single request to handle in ETH/LINK price between request and fulfillment time.
   * @return fallbackWeiPerUnitLink - fallback ETH/LINK price in the case of a stale feed.
   */
  function getConfig()
  external
  view
  returns (
    uint16 minimumRequestBlockConfirmations,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    uint96 minimumSubscriptionBalance,
    int256 fallbackWeiPerUnitLink
  );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with at least minimumSubscriptionBalance (see getConfig) LINK
   * before making a request.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [5000, maxGasLimit].
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64  subId,
    uint16  minimumRequestConfirmations,
    uint32  callbackGasLimit,
    uint32  numWords
  )
    external
    returns (
      uint256 requestId
    );

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription()
    external
    returns (
      uint64 subId
    );

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return owner - Owner of the subscription
   * @return consumers - List of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  )
    external
    view
    returns (
      uint96 balance,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  )
    external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(
    uint64 subId
  )
    external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Withdraw funds from a VRF subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the withdrawn LINK to
   * @param amount - How much to withdraw in juels
   */
  function defundSubscription(
    uint64 subId,
    address to,
    uint96 amount
  )
    external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(
    uint64 subId,
    address to
  )
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address immutable private vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(
    address _vrfCoordinator
  )
  {
      vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  )
    external
  {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IEth {
    enum STATE { OPEN, END, CLOSED }
    function transfer(address recipient, uint amount) external payable returns (bool success);
}
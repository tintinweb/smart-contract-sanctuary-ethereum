/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: docs.chain.link/Raffle.sol



pragma solidity >=0.8.4 <0.9.0;




contract Raffle is ReentrancyGuard, VRFV2WrapperConsumerBase, ConfirmedOwner {

    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    uint32 private constant callbackGasLimit = 100_000;

    uint32 private constant numWords = 1;

    uint16 private constant requestConfirmations = 3;
 

    struct RandomRequestStatus {
        bool fulfilled; 
        bool exists;
        uint[] randomWords;
        uint raffleId;
        address raffleCreatorAddr;
    
    }
    // requestId --> requestStatus
    mapping(uint => RandomRequestStatus) public requests;


    enum RAFFLE_STATUS{
        FINISHED,
        CLOSED,
        OPEN
        
    }
    uint public gas;
    struct RaffleStruct{

        RAFFLE_STATUS raffle_status;

        uint raffleStartTime;

        uint raffleEndTime;

        uint prizeAmount;

        address[] participantsAddrList;

        address winnerAddr;

        mapping(address => bool) participants;
        // tokenAddress --> (amount --> tokenId)
        mapping(address => mapping(uint => uint)) prize;
        
    }

    mapping(address => mapping(uint => RaffleStruct)) public raffles;

    event _createRandom(uint256 indexed requestId);

    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {}


    function withdrawLink() external onlyOwner {

        LinkTokenInterface link = LinkTokenInterface(linkAddress);

        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Raffle: Unable to transfer");
    }


    function requestRandomWords(address raffleCreatorAddr, uint raffleId) external onlyOwner{

        uint requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);

        requests[requestId] = RandomRequestStatus({
            randomWords: new uint[](0),
            exists: true,
            fulfilled: false,
            raffleCreatorAddr: raffleCreatorAddr,
            raffleId: raffleId
        });
    }
    

    function fulfillRandomWords(uint requestId, uint[] memory randomWords) internal override {
        require(requests[requestId].exists, "Raffle: Request not found");
        require(randomWords[0] > 0, "Raffle: Random not found");

        requests[requestId].fulfilled = true;
        requests[requestId].randomWords = randomWords;

        calculateWinner(requestId);

    }


    function calculateWinner(uint requestId) private{

        address raffleCreatorAddr = requests[requestId].raffleCreatorAddr;

        uint raffleId = requests[requestId].raffleId;

        uint randomness = requests[requestId].randomWords[0];

        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];

        uint indexOfWinner = randomness % raffle.participantsAddrList.length;

        raffle.winnerAddr = raffle.participantsAddrList[indexOfWinner];

    }
 
 


   function createRaffle(uint raffleStartTime, uint raffleEndTime, uint raffleId, address tokenAddress, uint256 amount) external payable{

        RaffleStruct storage newRaffle = raffles[msg.sender][raffleId];

        newRaffle.raffle_status = RAFFLE_STATUS.OPEN;

        newRaffle.raffleStartTime = raffleStartTime;

        newRaffle.raffleEndTime = raffleEndTime;
        //by default winner address is raffle creator address
        newRaffle.winnerAddr = msg.sender;

        newRaffle.prize[tokenAddress][amount] = 0;

    
    }

    function createRaffle(uint raffleStartTime, uint raffleEndTime, uint raffleId, address tokenAddress, uint amount, uint nftId) external{

        RaffleStruct storage newRaffle = raffles[msg.sender][raffleId];

        newRaffle.raffle_status = RAFFLE_STATUS.OPEN;

        newRaffle.raffleStartTime = raffleStartTime;

        newRaffle.raffleEndTime = raffleEndTime;
        //by default winner address is raffle creator address
        newRaffle.winnerAddr = msg.sender;

        newRaffle.prize[tokenAddress][amount] = nftId;
        
    }


    function registerInRaffle(address raffleCreatorAddr, uint raffleId) external addressAllowed(raffleId) notRegistered(raffleCreatorAddr, raffleId) isOpenRaffleStatus(raffleCreatorAddr, raffleId){
        uint initGas = gasleft();
        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
       
        raffle.participants[msg.sender] = true;
        raffle.participantsAddrList.push(msg.sender);
        uint finalGas = gasleft();
        gas = initGas - finalGas;
    }

    
    function closeRaffle(address raffleCreatorAddr, uint raffleId) external isClosedRaffleStatus(raffleCreatorAddr, raffleId) onlyOwner onlyRaffleCreator(raffleCreatorAddr, raffleId){

        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
        raffle.raffle_status = RAFFLE_STATUS.CLOSED;

        // requestRandomWords(raffleCreatorAddr, raffleId);

    } 

    function claimPrize(address raffleCreatorAddr, uint raffleId) external isClosedRaffleStatus(raffleCreatorAddr, raffleId) onlyWinner(raffleCreatorAddr, raffleId) nonReentrant{
        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
        uint prizeAmount = raffle.prizeAmount;

        require(getContractBalance() >= prizeAmount, "Raffle: Not enough balance");

        (bool result, ) = payable(msg.sender).call{value : prizeAmount}("");

        require(result, "Failure to send");
        
        raffle.raffle_status = RAFFLE_STATUS.FINISHED;
    }


    function getContractBalance() public view onlyOwner returns(uint){
        return address(this).balance / 10**18;
    }

    function increaseContractBalance() external payable {}



    //modifiers
    modifier notRegistered(address raffleCreatorAddr, uint raffleId){
        require(!raffles[raffleCreatorAddr][raffleId].participants[msg.sender], "Raffle: You already participant");
        _;
    }

    modifier onlyWinner(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].winnerAddr == msg.sender, "Raffle: You didn't won");
        _;
    }

    modifier onlyRaffleCreator(address raffleCreatorAddr, uint raffleId){
        require(raffles[msg.sender][raffleId].raffle_status == RAFFLE_STATUS.OPEN, "Raffle: Only owner or raffle creator can close raffle!");
        _;
    }

    modifier addressAllowed(uint raffleId){
        require(raffles[msg.sender][raffleId].raffle_status == RAFFLE_STATUS.FINISHED, "Raffle: Raffle creator cannot participate!");
        _;
    }

    modifier isClosedRaffleStatus(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].raffle_status == RAFFLE_STATUS.CLOSED || 
        raffles[raffleCreatorAddr][raffleId].raffleEndTime < block.timestamp, "Raffle: The current raffle is open yet!");
        _;
    }

    modifier isOpenRaffleStatus(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].raffle_status == RAFFLE_STATUS.OPEN || raffles[raffleCreatorAddr][raffleId].raffleEndTime > block.timestamp, "Raffle: Raffle ended!");
        _;
    }

    
}
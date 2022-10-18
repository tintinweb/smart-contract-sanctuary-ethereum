/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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

// File: docs.chain.link/samples/VRF/RandomChairAssignment.sol


pragma solidity ^0.8.7;




contract RandomChairAssignment is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 totalNum);
    event RequestFulfilled(uint256 requestId, uint256[] randomNumbers, uint256 payment);
    event membersAdded( string[] chairMembers);
    event SeatAssigned( string[] chairMembers, uint256[] chairOrder);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomNumbers;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomNumbers() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomNumbers()
    // function.
    uint32 callbackGasLimit = 200000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumNumbers.
    uint32 totalNum = 4;

    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    uint256[] public chairOrder;
    string[] public chairMembers;

    uint public totalMembers;

    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {}

    /**
     * Request random numbers from chainlink VRF
     */ 
    function requestRandomNumbers() external onlyOwner returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, totalNum);
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomNumbers: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, totalNum);
        return requestId;
    }

    /**
     * Chainlink coordinator callback function
     */  
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomNumbers) internal override {
        require(s_requests[_requestId].paid > 0, 'request not found');

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomNumbers = _randomNumbers;


        emit RequestFulfilled(_requestId, _randomNumbers, s_requests[_requestId].paid);
    }

    /**
    * Check status of the request
    */
    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomNumbers
        )
    {
        require(s_requests[_requestId].paid > 0, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomNumbers);
    }
    
    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    /**
     * Set chair members (up to 5 members -  ["Person 1", "Person 2", "Person 3", "Person 4" , "Person 5"])
     */
    function addChairMembers(string[] memory _chairMembers) external onlyOwner{
        chairMembers = _chairMembers;      
        emit membersAdded(chairMembers);
    }

    /**
     * Assign a random chair to each member 
     */
    function assignRandomChair(uint256 _requestId) public {
        require(s_requests[_requestId].paid > 0, 'request not found');
        
        chairMembers = ["Person 1", "Person 2", "Person 3", "Person 4" , "Person 5"];
        totalMembers = s_requests[_requestId].randomNumbers.length;
        chairOrder = s_requests[_requestId].randomNumbers;

        //shuffle members and chair order
        shuffleChairOrder();

        //display the final order of the chair members    
        emit SeatAssigned(chairMembers, chairOrder);
    }

    /**
     * Internal shuffling logic
     */
    function shuffleChairOrder() internal {
        
        //assign random seat
        chairOrder[0] = chairOrder[0] % 5;
        chairOrder[1] = chairOrder[1] % 4;
        chairOrder[2] = chairOrder[2] % 3;
        chairOrder[3] = chairOrder[3] % 2;
  
        emit SeatAssigned(chairMembers, chairOrder);
        
        //shuffle each member
        if(chairOrder[0] != 4)
        {
            string memory temp = chairMembers[chairOrder[0]];
            chairMembers[chairOrder[0]] = chairMembers[4];
            chairMembers[4] = temp;
        }
        if(chairOrder[1] != 3)
        {
            string memory temp = chairMembers[chairOrder[1]];
            chairMembers[chairOrder[1]] = chairMembers[3];
            chairMembers[3] = temp;
        }
        if(chairOrder[2] != 2)
        {
            string memory temp = chairMembers[chairOrder[2]];
            chairMembers[chairOrder[2]] = chairMembers[2];
            chairMembers[2] = temp;
        }
        if(chairOrder[3] != 1)
        {
            string memory temp = chairMembers[chairOrder[3]];
            chairMembers[chairOrder[3]] = chairMembers[1];
            chairMembers[1] = temp;
        }
    }

}
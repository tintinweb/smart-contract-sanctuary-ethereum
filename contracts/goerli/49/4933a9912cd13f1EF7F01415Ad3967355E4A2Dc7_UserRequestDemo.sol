// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UserRequest.sol";
import "./ConfirmedOwner.sol";

/**
 * @title User Request Demo contract
 */
contract UserRequestDemo is UserRequest, ConfirmedOwner {

    /// @dev Chainlink Request call response
    uint256 public currentResponse;

    /** 
     * @dev The constructor sets the SxTRelay and validator contract address
     * @param sxtRelayAddress - SxT request contract address
     * @param chainlinkTokenAddress - Chainlink Token address
     */
    constructor (address sxtRelayAddress, ChainlinkTokenInterface chainlinkTokenAddress)
        UserRequest(sxtRelayAddress, chainlinkTokenAddress, this.saveQueryResponse.selector)
        ConfirmedOwner(msg.sender)
    {}

    /**
     * @dev The node calls this function to write the result of the query
     * @dev The SxT request contract will be looking for the function name saveQueryResponse for saving the response
     * @param requestId - request id
     * @param data - response of the user query
     */
    function saveQueryResponse(bytes32 requestId, uint256 data) external {
        currentResponse = data;
        currentRequestId = requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstract/ReentrancyGuard.sol";
import "./interfaces/ISxTRelay.sol";
import "./interfaces/ChainlinkTokenInterface.sol";

/**
 * @title User Request contract
 */
abstract contract UserRequest is ReentrancyGuard{

    /// @dev Zero Address
    address constant ZERO_ADDRESS = address(0);

    /// @dev SxT Request contract address
    ISxTRelay public sxtRelayContract;

    /// @dev Chainlink token address
    ChainlinkTokenInterface public chainlinkToken;

    /// @dev Current request Id
    bytes32 public currentRequestId;
    bytes4 public saveQueryResponseSelector;

    /** 
     * @dev The constructor sets the SxTRelay and validator contract address
     * @param sxtRelayAddress - Address of the SxT request contract address that has Oracle and Job initialized on it
     * @param chainlinkTokenAddress - Address of the LINK token that would be used for payment
     */
    constructor (address sxtRelayAddress, ChainlinkTokenInterface chainlinkTokenAddress, bytes4 _callbackFunctionSelector) {
        require(sxtRelayAddress != ZERO_ADDRESS, "UserRequest: Cannot set to Zero Address");
        require(chainlinkTokenAddress != ChainlinkTokenInterface(ZERO_ADDRESS), "UserRequest: Cannot set to Zero Address");
        sxtRelayContract = ISxTRelay(sxtRelayAddress);
        chainlinkToken = chainlinkTokenAddress;
        saveQueryResponseSelector = _callbackFunctionSelector;
    }

    /**
     * @dev Modifier to constraint only the SxTRelay contract to call the function
     */
    modifier onlySxTRelay() {
        require(ISxTRelay(msg.sender) == sxtRelayContract, "UserRequest: Only callable by SxT Request Contract");
        _;
    }

    /**
     * @dev triggers the requestQuery function of the SxTRelay contract
     * @param resourceId - request id
     * @param query - user query
     * @param jobId - Chainlink Job ID that SxT team has created on the Chainlink Oracle Node
     */
    function runRequestQuery(string memory query, string memory resourceId, bytes32 jobId) external nonReentrant returns(bytes32 requestId){
        ISxTRelay sxtRelayInstance = sxtRelayContract;
        require(chainlinkToken.approve(address(sxtRelayContract), sxtRelayInstance.FEE()), "UserRequest: Insufficient allowance");
        return bytes32(abi.encodePacked(sxtRelayInstance.requestQuery(query, resourceId, address(this), saveQueryResponseSelector, jobId)));
    }

    /**
     * @dev Withdraw Chainlink from contract
     * @param to - Address to transfer the LINK tokens
     * @param amount - Amount of the LINK tokens to transfer
     */
    function withdrawChainlink(address to, uint256 amount) external nonReentrant {
        bool transferResult = chainlinkToken.transfer(
            to,
            amount
        );
        require(transferResult, "UserRequest: Chainlink token transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
// github.com/OpenZeppelin/[email protected]

pragma solidity ^0.8.7;

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
   * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkTokenInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISxTRelay {

    /**
     * @dev Get the fees for calling the SxT Request Query 
     */
    function FEE() external view returns (uint256);
    
    /**
     * @dev Set Chainlink operator contract address
     * @param newOperator - Address of the new operator contract deployed
     */
    function setChainlinkOperator(address newOperator) external;

    /**
     * @dev Withdraw Chainlink from contract
     * @param to - Address to transfer the LINK tokens
     * @param amount - Amount of the LINK tokens to transfer
     */
    function withdrawChainlink(address to, uint256 amount) external;

    /**
    //  * @dev Set Chainlink JOB ID
    //  * @param jobId - New Chainlink Job ID that SxT team has created on the Chainlink Oracle Node
    //  */
    // function setChainlinkJobID(string memory jobId) external;

    /**
     * @dev Execute the request query
     * @param callerContract - User contract address that called this requestQuery function
     * @param query - SQL query requested by User contract
     * @param resourceId - Request id requested by User contract
     * @param chainlinkJobId - Chainlink Job ID that SxT team has created on the Chainlink Oracle Node
     */
    function requestQuery(
        string memory query, 
        string memory resourceId, 
        address callerContract, 
        bytes4 callbackFunctionId,
        bytes32 chainlinkJobId
    ) external returns (bytes32);

    /**
     * @dev Chainlink off-chain request callback function to fulfil the request
     * @param requestId - The unique id of the request for which the function is triggered
     * @param data - The response data received for the query
     */
    function queryResponse(
        bytes32 requestId, 
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private ownerAddress;
  address private pendingOwnerAddress;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    ownerAddress = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) external override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == pendingOwnerAddress, "Must be proposed owner");

    address oldOwner = ownerAddress;
    ownerAddress = msg.sender;
    pendingOwnerAddress = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return ownerAddress;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    pendingOwnerAddress = to;

    emit OwnershipTransferRequested(ownerAddress, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == ownerAddress, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}
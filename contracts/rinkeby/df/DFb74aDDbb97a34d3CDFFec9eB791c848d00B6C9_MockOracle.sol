/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/ChainlinkRequestInterface

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// Part: smartcontractkit/[email protected]/LinkTokenInterface

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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/LinkTokenReceiver

abstract contract LinkTokenReceiver {

  bytes4 constant private ORACLE_REQUEST_SELECTOR = 0x40429946;
  uint256 constant private SELECTOR_LENGTH = 4;
  uint256 constant private EXPECTED_REQUEST_WORDS = 2;
  uint256 constant private MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);
  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @dev The data payload's first 2 words will be overwritten by the `_sender` and `_amount`
   * values to ensure correctness. Calls oracleRequest.
   * @param _sender Address of the sender
   * @param _amount Amount of LINK sent (specified in wei)
   * @param _data Payload of the transaction
   */
  function onTokenTransfer(
    address _sender,
    uint256 _amount,
    bytes memory _data
  )
    public
    onlyLINK
    validRequestLength(_data)
    permittedFunctionsForLINK(_data)
  {
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(_data, 36), _sender) // ensure correct sender is passed
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(_data, 68), _amount)    // ensure correct amount is passed
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).delegatecall(_data); // calls oracleRequest
    require(success, "Unable to create request");
  }

  function getChainlinkToken() public view virtual returns (address);

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    require(msg.sender == getChainlinkToken(), "Must use LINK token");
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `oracleRequest` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == ORACLE_REQUEST_SELECTOR, "Must use whitelisted functions");
    _;
  }

  /**
   * @dev Reverts if the given payload is less than needed to create a request
   * @param _data The request payload
   */
  modifier validRequestLength(bytes memory _data) {
    require(_data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    _;
  }
}

// Part: smartcontractkit/[email protected]/SafeMathChainlink

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

// File: MockOracle.sol

/**
 * @title The Chainlink Mock Oracle contract
 * @notice Chainlink smart contract developers can use this to test their contracts
 */
contract MockOracle is ChainlinkRequestInterface, LinkTokenReceiver {
  using SafeMathChainlink for uint256;

  uint256 constant public EXPIRY_TIME = 5 minutes;
  uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;
  
  struct Request {
      address callbackAddr;
      bytes4 callbackFunctionId;
  }

  LinkTokenInterface internal LinkToken;
  mapping(bytes32 => Request) private commitments;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event CancelOracleRequest(
    bytes32 indexed requestId
  );

  /**
   * @notice Deploy with the address of the LINK token
   * @dev Sets the LinkToken address for the imported LinkTokenInterface
   * @param _link The address of the LINK token
   */
  constructor(address _link)
    public
  {
    LinkToken = LinkTokenInterface(_link); // external but already deployed and unalterable
  }

  /**
   * @notice Creates the Chainlink request
   * @dev Stores the hash of the params as the on-chain commitment for the request.
   * Emits OracleRequest event for the Chainlink node to detect.
   * @param _sender The sender of the request
   * @param _payment The amount of payment given (specified in wei)
   * @param _specId The Job Specification ID
   * @param _callbackAddress The callback address for the response
   * @param _callbackFunctionId The callback function ID for the response
   * @param _nonce The nonce sent by the requester
   * @param _dataVersion The specified data version
   * @param _data The CBOR payload of the request
   */
  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes calldata _data
  )
    external
    override
    onlyLINK()
    checkCallbackAddress(_callbackAddress)
  {
    bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
    require(commitments[requestId].callbackAddr == address(0), "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    uint256 expiration = now.add(EXPIRY_TIME);

    commitments[requestId] = Request(
        _callbackAddress,
        _callbackFunctionId
    );

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      _dataVersion,
      _data);
  }

  /**
   * @notice Called by the Chainlink node to fulfill requests
   * @dev Given params must hash back to the commitment stored from `oracleRequest`.
   * Will call the callback address' callback function without bubbling up error
   * checking in a `require` so that the node can get paid.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param _data The data to return to the consuming contract
   * @return Status if the external call was successful
   */
  function fulfillOracleRequest(
    bytes32 _requestId,
    bytes32 _data
  )
    external
    isValidRequest(_requestId)
    returns (bool)
  {
    Request memory req = commitments[_requestId];
    delete commitments[_requestId];
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
    // All updates to the oracle's fulfillment should come before calling the
    // callback(addr+functionId) as it is untrusted.
    // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
    (bool success, ) = req.callbackAddr.call(abi.encodeWithSelector(req.callbackFunctionId, _requestId, _data)); // solhint-disable-line avoid-low-level-calls
    return success;
  }

  /**
   * @notice Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
   * sent for the request back to the requester's address.
   * @dev Given params must hash to a commitment stored on the contract in order for the request to be valid
   * Emits CancelOracleRequest event.
   * @param _requestId The request ID
   * @param _payment The amount of payment given (specified in wei)
   * @param _expiration The time of the expiration for the request
   */
  function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4,
    uint256 _expiration
  )
    external
    override
  {
    require(commitments[_requestId].callbackAddr != address(0), "Must use a unique ID");
    // solhint-disable-next-line not-rely-on-time
    require(_expiration <= now, "Request is not expired");

    delete commitments[_requestId];
    emit CancelOracleRequest(_requestId);

    assert(LinkToken.transfer(msg.sender, _payment));
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken()
    public
    view
    override
    returns (address)
  {
    return address(LinkToken);
  }

  // MODIFIERS

  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `commitments`
   */
  modifier isValidRequest(bytes32 _requestId) {
    require(commitments[_requestId].callbackAddr != address(0), "Must have a valid requestId");
    _;
  }


  /**
   * @dev Reverts if the callback address is the LINK token
   * @param _to The callback address
   */
  modifier checkCallbackAddress(address _to) {
    require(_to != address(LinkToken), "Cannot callback to LINK");
    _;
  }

}
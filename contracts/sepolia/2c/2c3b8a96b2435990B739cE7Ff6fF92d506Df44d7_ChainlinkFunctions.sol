// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "./LoanContract.sol";

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract ChainlinkFunctions is AutomationCompatibleInterface, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    int constant RAY = 10 ** 27;

    LoanContract loanContract;

    string public euribor_url;
    bytes32 public euribor_jobId;
    uint256 public euribor_fee;
    uint256 public euriborInterestRate;

    event RequestEuriborFulfilled(
        bytes32 indexed requestId,
        uint256 indexed euribor
    );

    constructor(address _addressLoanContract) {
        loanContract = LoanContract(_addressLoanContract);
    }

    function getGracePeriod() private pure returns (uint) {
        return 0;
    }

    event UpkeepChecked(
        address indexed _addressThis,
        address indexed _addressLoanContract
    );

    function checkUpkeep(
        bytes calldata /*  checkData */
    ) external returns (bool upkeepNeeded, bytes memory performData) {
        // LoanLibrary.DefaultInterestTracker
        //     memory defaultInterestTracker = loanContract
        //         .getDefaultInterestTracker();
        // bool isInterestDue = loanContract.getDueAndUnpaidInterest() > 0;
        // bool isDefaultInterestDue = loanContract
        //     .getDueAndUnpaidDefaultInterest() > 0;
        // bool isPrincipalDue = loanContract.getDueAndUnpaidPrincipal() > 0;
        // bool isAnyAmountDue = isInterestDue ||
        //     isDefaultInterestDue ||
        //     isPrincipalDue;
        // bool isNoEarlierDefault = defaultInterestTracker
        //     .defaultInterestUpdateTime == 0;
        // bool hasPrincipalGracePeriodExpired = checkHasPrincipalGracePeriodExpired();
        // bool hasInterestGracePeriodExpired = checkHasInterestGracePeriodExpired();
        // bool isAnyAllowanceAvailable = LoanLibrary.checkBalanceBackedAllowance(
        //     loanContract.addressDepositToken(),
        //     loanContract.borrower(),
        //     address(loanContract)
        // ) > 0;
        // bool isPrincipalDefault = isPrincipalDue &&
        //     hasPrincipalGracePeriodExpired;
        // bool isInterestDefault = isInterestDue && hasInterestGracePeriodExpired;
        // bool isAnyNewDefault = isNoEarlierDefault &&
        //     (isPrincipalDefault || isInterestDefault);
        // bool isAnyDueAmountCapableOfBeingRepaid = isAnyAmountDue &&
        //     isAnyAllowanceAvailable;

        // if (isAnyNewDefault || isAnyDueAmountCapableOfBeingRepaid) {
        //     upkeepNeeded = true;
        //     performData = abi.encode("");
        // }
        emit UpkeepChecked(address(this), address(loanContract));
        return (true, abi.encode(""));
    }

    function checkHasPrincipalGracePeriodExpired() private view returns (bool) {
        LoanLibrary.TimeAndAmount[] memory repaymentschedule = loanContract
            .getRepaymentSchedule();
        uint principalRepaymentIndex = LoanLibrary
            .getIndexScheduledRepaymentBefore(
                repaymentschedule,
                block.timestamp
            );
        uint principalRepaymentTime = repaymentschedule[principalRepaymentIndex]
            .time;
        return block.timestamp > (principalRepaymentTime + getGracePeriod());
    }

    function checkHasInterestGracePeriodExpired() private view returns (bool) {
        (uint lastInterestPaymentTime, ) = LoanLibrary
            .getTimeAndIndexLastScheduledInterestPaymentBefore(
                loanContract.getInterestPaymentTimes(),
                block.timestamp
            );
        return block.timestamp > (lastInterestPaymentTime + getGracePeriod());
    }

    event UpkeepPerformed(
        address indexed _addressThis,
        address indexed _addressLoanContract
    );

    function performUpkeep(bytes calldata /*e performData */) external {
        // revalidating upkeep conditions as per chainlink recommendation
        LoanLibrary.DefaultInterestTracker
            memory defaultInterestTracker = loanContract
                .getDefaultInterestTracker();
        bool isInterestDue = loanContract.getDueAndUnpaidInterest() > 0;
        bool isDefaultInterestDue = loanContract
            .getDueAndUnpaidDefaultInterest() > 0;
        bool isPrincipalDue = loanContract.getDueAndUnpaidPrincipal() > 0;
        bool isAnyAmountDue = isInterestDue ||
            isDefaultInterestDue ||
            isPrincipalDue;
        bool isNoEarlierDefault = defaultInterestTracker
            .defaultInterestUpdateTime == 0;
        bool hasPrincipalGracePeriodExpired = checkHasPrincipalGracePeriodExpired();
        bool hasInterestGracePeriodExpired = checkHasInterestGracePeriodExpired();
        bool isAnyAllowanceAvailable = LoanLibrary.checkBalanceBackedAllowance(
            loanContract.addressDepositToken(),
            loanContract.borrower(),
            address(loanContract)
        ) > 0;
        bool isPrincipalDefault = isPrincipalDue &&
            hasPrincipalGracePeriodExpired;
        bool isInterestDefault = isInterestDue && hasInterestGracePeriodExpired;
        bool isAnyNewDefault = isNoEarlierDefault &&
            (isPrincipalDefault || isInterestDefault);
        bool isAnyDueAmountCapableOfBeingRepaid = isAnyAmountDue &&
            isAnyAllowanceAvailable;

        if (isAnyDueAmountCapableOfBeingRepaid) {
            loanContract.payInCorrectOrder();
        }
        if (isAnyNewDefault) loanContract.checkAndUpdateDefault(); // see todo
        emit UpkeepPerformed(address(this), address(loanContract));
    }

    // access control?
    function setApiParameters(
        address _linkToken,
        address _oracleToken,
        bytes32 _jobId,
        uint _fee,
        string memory _url
    ) public {
        setChainlinkOracle(_oracleToken);
        setChainlinkToken(_linkToken);
        euribor_jobId = _jobId;
        euribor_fee = _fee;
        euribor_url = _url;
    }

    // access control?
    function setApiUrl(string memory _url) public {
        euribor_url = _url;
    }

    // access control?
    function setOracleAddress(address _oracleAddress) public {
        setChainlinkOracle(_oracleAddress);
    }

    // access control?
    function setLinkTokenAddress(address _tokenAddress) public {
        setChainlinkToken(_tokenAddress);
    }

    // access control?
    function setEuriborJobId(bytes32 _jobId) public {
        euribor_jobId = _jobId;
    }

    // access control?
    function setEuriborFee(uint _fee) public {
        euribor_fee = _fee;
    }

    // use buildOperatorRequest and sendOperatorRequest instead as per Chainlink API reference recommendation?
    // callback address same as address calling contract
    function getEuriborInterestRate() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            euribor_jobId,
            address(this),
            this.fulfillEuriborInterestRate.selector
        );
        // Set the URL to perform the GET request on
        request.add("get", euribor_url);
        request.add("path", "price");
        request.addInt("times", RAY / 100);
        return sendChainlinkRequest(request, euribor_fee);
    }

    function fulfillEuriborInterestRate(
        bytes32 _requestId,
        uint256 _euriborInterestRate
    ) public recordChainlinkFulfillment(_requestId) {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        // emit EuriborRequested event?
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Fulfillment only allowed by oracle of the request"
        ); // msg.sender is oracle. why send link back to oracle?

        euriborInterestRate = _euriborInterestRate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "./LoanLibrary.sol";
// import "../lib/EnumerableMapExtended.sol";

import "../interfaces/IDepositToken.sol";
import "../interfaces/ILoanMultiSig.sol";

// import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/*is AutomationCompatibleInterface, ChainlinkClient*/ contract LoanContract {
    // using Chainlink for Chainlink.Request;
    // using EnumerableMapExtended for EnumerableMapExtended.AddressToUintMap;

    // ------------------ CUSTOM ERRORS --------------------

    error Unauthorized();
    error InvalidRepaymentSchedule();
    error OnlyLoanMultiSig();
    error InsufficientLoan();
    error LoanNotConfirmed();
    error NotPermittedTransferee();
    error InvalidInputError();

    // ----------------- CONSTANTS ----------------

    uint constant RAY = 10 ** 27;
    uint MINIMUM_REPAYMENTAMOUNT_DIVISOR = 1000;

    // ----------------- CUSTOM TYPES ------------

    enum FloatingRateMaturityType {
        EuriborOneWeek,
        EuriborOneMonth,
        EuriborThreeMonths,
        EuriborSixMonths,
        EuriborOneYear
    }

    struct AncillaryContractAddresses {
        address loanMultiSig;
        address loanSale;
        address loanPercentage;
        address timelock;
    }

    // ----------------- Chainlink variables --------------------
    // string public euribor_url;
    // bytes32 public euribor_jobId;
    // uint256 public euribor_fee;
    // uint256 public euriborInterestRate;
    // event RequestEuriborFulfilled(
    //     bytes32 indexed requestId,
    //     uint256 indexed euribor
    // );

    // ----------------- STATE VARIABLES ----------

    uint public creationTime;
    address public arranger;
    address public borrower;
    uint public loanAmount;
    uint public fixedInterestRate;
    LoanLibrary.TimeAndAmount[] public repaymentSchedule;
    uint[] public interestPaymentTimes;
    LoanLibrary.TimeRateAmount[] public rateAndOutstandingAmountHistory;
    uint public totalInterestPaid;
    uint public defaultInterestRateInRay;
    LoanLibrary.DefaultInterestTracker public defaultInterestTracker;
    LoanLibrary.LoanStatus public loanStatus;
    address public addressDepositToken;
    address public addressLoanMultiSig;
    address public addressLoanSale;
    address public addressLoanPercentage;
    address public addressTimelock;

    address[] public lenders;

    // ------------------ ACCESS CONTROL ---------------------------------

    function onlyLoanMultiSig() private view {
        if (msg.sender != addressLoanMultiSig) revert OnlyLoanMultiSig();
    }

    // ------------------ PUBLIC AND EXTERNAL FUNCTIONS ------------------------

    constructor(
        address _arranger,
        LoanLibrary.AddressAndAmount[] memory _originalLenders,
        address _borrower,
        uint _loanAmount,
        LoanLibrary.TimeAndAmount[] memory _repaymentSchedule,
        uint _fixedInterestRateInRay,
        uint[] memory _interestPaymentTimes,
        uint _defaultInterestRateInRay,
        address _addressDepositTokenArranger,
        AncillaryContractAddresses memory _ancillaryAddresses
    ) {
        if (
            !LoanLibrary.checkRepaymentscheduleValid(
                _repaymentSchedule,
                _loanAmount
            )
        ) revert InvalidRepaymentSchedule();
        if (
            !LoanLibrary.checkInterestPaymentTimesValid(
                _interestPaymentTimes,
                _repaymentSchedule[_repaymentSchedule.length - 1].time
            )
        ) revert InvalidInputError();
        arranger = _arranger;
        borrower = _borrower;
        loanAmount = _loanAmount;
        fixedInterestRate = _fixedInterestRateInRay;
        interestPaymentTimes = _interestPaymentTimes;
        defaultInterestRateInRay = _defaultInterestRateInRay;
        loanStatus = LoanLibrary.LoanStatus.Proposed;
        addressDepositToken = _addressDepositTokenArranger;
        addressLoanPercentage = _ancillaryAddresses.loanPercentage;
        addressTimelock = _ancillaryAddresses.timelock;
        uint i;
        uint percentageInRay;
        for (i = 0; i < _repaymentSchedule.length; i++) {
            repaymentSchedule.push(_repaymentSchedule[i]);
        }

        for (i = 0; i < _originalLenders.length; i++) {
            percentageInRay = (_originalLenders[i].amount * RAY) / loanAmount;
            ILoanPercentage(addressLoanPercentage).transferByLoanContract(
                address(this),
                _originalLenders[i].inputAddress,
                percentageInRay
            );
            lenders.push(_originalLenders[i].inputAddress);
        }

        bool isOriginalLenderInputValid = LoanLibrary
            .checkIsOriginalLenderInputValid(_originalLenders, loanAmount);
        if (!isOriginalLenderInputValid) {
            revert InvalidInputError();
        }
        addressLoanSale = _ancillaryAddresses.loanSale;
        addressLoanMultiSig = _ancillaryAddresses.loanMultiSig;
    }

    function confirmLoan(
        uint _arrangementFeePercentageInRay,
        uint _initialFloatingRateInRay
    ) external {
        onlyLoanMultiSig();
        LoanLibrary.checkConfirmationRequirements(
            msg.sender,
            addressLoanMultiSig,
            loanStatus,
            repaymentSchedule[0].time,
            interestPaymentTimes[0]
        );

        LoanLibrary.makeFundsAvailableToBorrower(
            ILoanPercentage(addressLoanPercentage),
            lenders,
            loanAmount,
            _arrangementFeePercentageInRay,
            borrower,
            addressDepositToken
        );

        uint initialTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            _initialFloatingRateInRay
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            initialTotalInterestRate,
            loanAmount
        );
        creationTime = block.timestamp;
        loanStatus = LoanLibrary.LoanStatus.Performing;
    }

    // this function should ultimately be capable of being called only by Chainlink oracle
    // the floating rate will typically be EURIBOR
    // for fixed rate loan the floating rate will be zero

    function setFloatingRate(uint _newFloatingRateInRay) external {
        if (msg.sender != arranger) revert Unauthorized();
        uint newTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            _newFloatingRateInRay
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            newTotalInterestRate,
            getCurrentOutstandingPrincipal()
        );
    }

    // chainlink should call this 24hrs after each interest payment date
    // and principal repayment date; any of the lenders or borrower can
    // call this function too
    // borrower determines what is paid by control over the allowance
    // does this function need to check first whether there is sufficient
    // balanceBackedAllowance?

    function payInCorrectOrder() public {
        payDefaultInterest();
        if (getDueAndUnpaidDefaultInterest() == 0) {
            payInterest();
            if (getDueAndUnpaidInterest() == 0) repayPrincipal();
        }
    }

    // this is now an internal function, called through payInCorrectOrder
    function repayPrincipal() internal {
        uint dueAndUnpaidPrincipal = getDueAndUnpaidPrincipal();
        if (dueAndUnpaidPrincipal == 0) return;

        uint allowance = LoanLibrary.checkBalanceBackedAllowance(
            addressDepositToken,
            borrower,
            address(this)
        );
        if (allowance > (loanAmount / MINIMUM_REPAYMENTAMOUNT_DIVISOR)) {
            uint outstandingBalanceBeforeRepayment = getCurrentOutstandingPrincipal();
            LoanLibrary.updateDefaultInterestTracker(
                defaultInterestRateInRay,
                outstandingBalanceBeforeRepayment,
                defaultInterestTracker
            );
            uint usedAmount = (allowance < dueAndUnpaidPrincipal)
                ? allowance
                : dueAndUnpaidPrincipal;
            LoanLibrary.distributePaymentToLenders(
                ILoanPercentage(addressLoanPercentage),
                lenders,
                borrower,
                addressDepositToken,
                usedAmount
            );
            uint newOutstandingAmount = outstandingBalanceBeforeRepayment -
                usedAmount;
            LoanLibrary.updateRateAndOutstandingAmountHistory(
                rateAndOutstandingAmountHistory,
                getCurrentInterestRate(),
                newOutstandingAmount
            );
            if (newOutstandingAmount == 0)
                loanStatus = LoanLibrary.LoanStatus.Repaid;
            checkAndUpdateDefault();
        }
    }

    function payInterest() internal {
        totalInterestPaid += LoanLibrary.payInterest(
            getDueAndUnpaidInterest(),
            addressDepositToken,
            borrower,
            address(this),
            ILoanPercentage(addressLoanPercentage),
            lenders
        );
        checkAndUpdateDefault();
    }

    function payDefaultInterest() public {
        defaultInterestTracker.paidDefaultInterest += LoanLibrary
            .payDefaultInterest(
                getDueAndUnpaidDefaultInterest(),
                addressDepositToken,
                borrower,
                address(this),
                ILoanPercentage(addressLoanPercentage),
                lenders
            );
    }

    function getDueAndUnpaidPrincipal() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidPrincipal(
                loanStatus,
                repaymentSchedule,
                loanAmount,
                getCurrentOutstandingPrincipal()
            );
    }

    function getDueAndUnpaidInterest() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidInterest(
                loanStatus,
                interestPaymentTimes,
                rateAndOutstandingAmountHistory,
                creationTime,
                totalInterestPaid
            );
    }

    function getDueAndUnpaidDefaultInterest() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidDefaultInterest(
                defaultInterestTracker,
                defaultInterestRateInRay,
                getCurrentOutstandingPrincipal()
            );
    }

    // checkAndUpdateDefault to be called by Chainlink 24 hours after expiry payment date

    function checkAndUpdateDefault() public {
        loanStatus = LoanLibrary.checkAndUpdateDefault(
            loanStatus,
            getDueAndUnpaidInterest(),
            getDueAndUnpaidPrincipal(),
            getDueAndUnpaidDefaultInterest(),
            defaultInterestTracker
        );
    }

    function terminateLoan() external {
        if (msg.sender != addressTimelock) revert Unauthorized();
        if (loanStatus != LoanLibrary.LoanStatus.Defaulted)
            revert Unauthorized();
        delete repaymentSchedule;
        LoanLibrary.TimeAndAmount memory repayFullAmount = LoanLibrary
            .TimeAndAmount(block.timestamp, loanAmount);
        repaymentSchedule.push(repayFullAmount);
    }

    // ------------- LOAN ASSIGNMENT --------------

    function assignLoan(
        address _seller,
        address _buyer,
        uint _assignedLoanAmount
    ) external {
        ILoanPercentage loanPercentage = ILoanPercentage(addressLoanPercentage);
        if (msg.sender != addressLoanSale) revert Unauthorized();
        if (_assignedLoanAmount == 0) revert InvalidInputError();
        uint initialPercentageBuyer = loanPercentage.balanceOf(_buyer);
        uint initialPercentageSeller = loanPercentage.balanceOf(_seller);
        uint percentageAssignedInRay = (_assignedLoanAmount * RAY) /
            getCurrentOutstandingPrincipal();
        if (initialPercentageSeller < percentageAssignedInRay)
            revert InsufficientLoan();
        loanPercentage.transferByLoanContract(
            _seller,
            _buyer,
            percentageAssignedInRay
        );
        uint newPercentageSeller = loanPercentage.balanceOf(_seller);
        if (newPercentageSeller == 0) {
            LoanLibrary.removeItemFromAddressArray(lenders, _seller);
            ILoanMultiSig(addressLoanMultiSig).removeOwner(_seller);
        }

        if (initialPercentageBuyer == 0) {
            require(
                !LoanLibrary.isLender(lenders, _buyer),
                "Invalid lenders array"
            );
            lenders.push(_buyer);
            ILoanMultiSig(addressLoanMultiSig).addOwner(_buyer);
            ILoanMultiSig(addressLoanMultiSig).changeRequirement(
                lenders.length + 1
            );
        }
    }

    // ------------- GETTERS ----------------------

    function getAccruedInterestBetween(
        uint _startDate,
        uint _endDate
    ) public view returns (uint) {
        return
            LoanLibrary.getAccruedInterestBetween(
                rateAndOutstandingAmountHistory,
                _startDate,
                _endDate
            );
    }

    function getRepaymentSchedule()
        external
        view
        returns (LoanLibrary.TimeAndAmount[] memory)
    {
        return repaymentSchedule;
    }

    function getInterestPaymentTimes() external view returns (uint[] memory) {
        return interestPaymentTimes;
    }

    function getCurrentOutstandingPrincipal() public view returns (uint) {
        return
            rateAndOutstandingAmountHistory.length == 0
                ? 0
                : rateAndOutstandingAmountHistory[
                    rateAndOutstandingAmountHistory.length - 1
                ].outstandingAmount;
    }

    function getCurrentInterestRate() public view returns (uint) {
        return
            rateAndOutstandingAmountHistory.length == 0
                ? 0
                : rateAndOutstandingAmountHistory[
                    rateAndOutstandingAmountHistory.length - 1
                ].interestRate;
    }

    function getCurrentFloatingRate() public view returns (uint) {
        return getCurrentInterestRate() - fixedInterestRate;
    }

    function getRateAndOutstandingAmountHistory()
        public
        view
        returns (LoanLibrary.TimeRateAmount[] memory)
    {
        return rateAndOutstandingAmountHistory;
    }

    function getLenders() public view returns (address[] memory) {
        return lenders;
    }

    function getDefaultInterestTracker()
        public
        view
        returns (LoanLibrary.DefaultInterestTracker memory)
    {
        return defaultInterestTracker;
    }

    // --------------------- AMENDMENT FUNCTIONS ----------------------

    function amendFixedInterestRate(uint _newFixedRateInRay) external {
        onlyLoanMultiSig();
        uint currentFloatingRate = getCurrentFloatingRate();
        fixedInterestRate = _newFixedRateInRay;
        uint newTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            currentFloatingRate
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            newTotalInterestRate,
            getCurrentOutstandingPrincipal()
        );
    }

    function amendRepaymentSchedule(
        LoanLibrary.TimeAndAmount[] memory _newRepaymentSchedule
    ) external {
        onlyLoanMultiSig();
        delete repaymentSchedule;
        LoanLibrary.changeRepaymentSchedule(
            repaymentSchedule,
            _newRepaymentSchedule,
            loanAmount
        );
        if (getDueAndUnpaidPrincipal() != 0) revert InvalidInputError();
        checkAndUpdateDefault();
    }

    function amendInterestPaymentTimes(
        uint[] calldata _newInterestPaymentTimes
    ) external {
        onlyLoanMultiSig();
        delete interestPaymentTimes;
        interestPaymentTimes = _newInterestPaymentTimes;
        if (
            !LoanLibrary.checkInterestPaymentTimesValid(
                interestPaymentTimes,
                repaymentSchedule[repaymentSchedule.length - 1].time
            )
        ) revert InvalidInputError();

        if (getDueAndUnpaidInterest() != 0) revert InvalidInputError();
        checkAndUpdateDefault();
    }

    function addDefaultInterestToPrincipal(uint _amountToAdd) external {
        onlyLoanMultiSig();
        LoanLibrary.capitalizeDefaultInterest(
            _amountToAdd,
            defaultInterestTracker,
            rateAndOutstandingAmountHistory,
            getDueAndUnpaidDefaultInterest(),
            getCurrentOutstandingPrincipal(),
            defaultInterestRateInRay,
            getCurrentInterestRate()
        );
        loanAmount += _amountToAdd;
        checkAndUpdateDefault();
    }

    function addInterestToPrincipal(uint _amountToAdd) external {
        onlyLoanMultiSig();
        LoanLibrary.capitalizeInterest(
            _amountToAdd,
            rateAndOutstandingAmountHistory,
            getDueAndUnpaidInterest(),
            getCurrentOutstandingPrincipal(),
            getCurrentInterestRate()
        );
        loanAmount += _amountToAdd;
        totalInterestPaid += _amountToAdd;
        checkAndUpdateDefault();
    }

    function waiveDefaultInterest(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint dueAndUnpaidDefaultInterest = getDueAndUnpaidDefaultInterest();
        if (dueAndUnpaidDefaultInterest == 0) return;
        if (_amountToWaive > dueAndUnpaidDefaultInterest)
            _amountToWaive = dueAndUnpaidDefaultInterest;
        defaultInterestTracker.paidDefaultInterest += _amountToWaive;
        checkAndUpdateDefault();
    }

    function waiveInterest(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint dueAndUnpaidInterest = getDueAndUnpaidInterest();
        if (dueAndUnpaidInterest == 0) return;
        if (_amountToWaive > dueAndUnpaidInterest) revert InvalidInputError();
        totalInterestPaid += _amountToWaive;
        checkAndUpdateDefault();
    }

    function waivePrincipal(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint outstandingPrincipal = getCurrentOutstandingPrincipal();
        if (outstandingPrincipal == 0) return;
        if (_amountToWaive > outstandingPrincipal) revert InvalidInputError();
        uint newOutstandingPrincipal = outstandingPrincipal - _amountToWaive;
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            getCurrentInterestRate(),
            newOutstandingPrincipal
        );
        loanAmount -= _amountToWaive;
        checkAndUpdateDefault();
        if (newOutstandingPrincipal == 0)
            loanStatus = LoanLibrary.LoanStatus.Repaid;
    }
}

// TODO:
// 1. events
// 2. check whether loanStatus is tracked properly and adjusted where needed
// 3. binary searches instead of brute force searches through arrays
// 4. perhaps change checkAndUpdateDefault function to only update default
// given that check already happens in upkeep and perfromUpkeep functions
// 5. use ERC-677 standard for loanPercentage tokens? https://github.com/ethereum/EIPs/issues/677
// 6. do we need automation on top of API calls
// functions instead of Any API?
// in functions that amend principal (add and waive) the repayment schedule also needs to be adjusted. still todo
// add change deposit token function
// in amend functions, if amount to add/waive greater than relevant outstanding amount then equate amount to add/waive to relevant outstanding amount

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "../lib/DSMath.sol";
import "../lib/EnumerableMapExtended.sol";
import "../interfaces/IDepositToken.sol";
import "../interfaces/ILoanPercentage.sol";

library LoanLibrary {
    using EnumerableMapExtended for EnumerableMapExtended.AddressToUintMap;
    using DSMath for uint;

    //  ----------------- CUSTOM ERRORS -------------------------

    error DistributionFailed();
    error InvalidInput();
    error OnlyLoanMultiSig();
    error AlreadyConfirmed();
    error LoanNotConfirmed();

    // ----------------- CONSTANTS ------------------------------

    uint constant ONE_YEAR_IN_SEC = 60 * 60 * 24 * 365;
    uint constant RAY = 10 ** 27;
    uint constant BILLION = 10 ** 9;

    // ---------------- CUSTOM TYPES ---------------------------
    enum LoanStatus {
        Proposed,
        Performing,
        Defaulted,
        Repaid
    }

    struct TimeAndAmount {
        uint time;
        uint amount;
    }

    struct AddressAndAmount {
        address inputAddress;
        uint amount;
    }

    struct TimeRateAmount {
        uint time;
        uint interestRate;
        uint outstandingAmount;
    }

    // paidDefaultInterest does not track total paid default interest
    // but is reset to zero each time outstandining default interst is fully repaid
    // do we also want tot track total default interest paid for APY purposes?
    struct DefaultInterestTracker {
        uint accruedDefaultInterest;
        uint paidDefaultInterest;
        uint defaultInterestUpdateTime;
    }

    // --------------- EXTERNAL OR PUBLIC LIBRARY FUNCTIONS ---------------

    function checkRepaymentscheduleValid(
        TimeAndAmount[] memory _repaymentSchedule,
        uint _initialLoanAmount
    ) public pure returns (bool) {
        uint totalRepayments;
        for (uint i = 0; i < _repaymentSchedule.length; i++) {
            totalRepayments += _repaymentSchedule[i].amount;
            if (_repaymentSchedule[i].amount == 0) return false;
            if (i == _repaymentSchedule.length - 1) continue;
            if (_repaymentSchedule[i].time >= _repaymentSchedule[i + 1].time)
                return false;
        }
        if (
            _repaymentSchedule.length == 0 ||
            totalRepayments != _initialLoanAmount
        ) return false;
        return true;
    }

    function checkInterestPaymentTimesValid(
        uint[] calldata _interestPaymentTimes,
        uint timeLastRepayment
    ) public pure returns (bool) {
        if (
            _interestPaymentTimes.length == 0 ||
            _interestPaymentTimes[_interestPaymentTimes.length - 1] !=
            timeLastRepayment
        ) return false;
        for (uint i = 0; i < _interestPaymentTimes.length; i++) {
            if (_interestPaymentTimes[i] == 0) return false;
            if (i == _interestPaymentTimes.length - 1) continue;
            if (_interestPaymentTimes[i] >= _interestPaymentTimes[i + 1])
                return false;
        }
        return true;
    }

    function checkIsOriginalLenderInputValid(
        AddressAndAmount[] memory _originalLenders,
        uint _initialLoanAmount
    ) external pure returns (bool) {
        uint sum;
        for (uint i = 0; i < _originalLenders.length; i++) {
            if (
                _originalLenders[i].amount == 0 ||
                _originalLenders[i].inputAddress == address(0)
            ) return false;
            sum += _originalLenders[i].amount;
        }
        if (sum != _initialLoanAmount) return false;
        return true;
    }

    function isLender(
        address[] storage _lenders,
        address _entityAddress
    ) external view returns (bool) {
        for (uint i = 0; i < _lenders.length; i++) {
            if (_lenders[i] == _entityAddress) return true;
        }
        return false;
    }

    function checkConfirmationRequirements(
        address _functionCaller,
        address _addressMultiSig,
        LoanStatus _loanStatus,
        uint _timeFirstRepayment,
        uint _timeFirstInterestPayment
    ) external view {
        if (_functionCaller != _addressMultiSig) revert OnlyLoanMultiSig();
        if (_loanStatus != LoanStatus.Proposed) revert AlreadyConfirmed();
        if (
            _timeFirstRepayment <= block.timestamp ||
            _timeFirstInterestPayment <= block.timestamp
        ) revert InvalidInput();
    }

    function makeFundsAvailableToBorrower(
        ILoanPercentage _loanPercentage,
        address[] storage _lenders,
        uint _initialLoanAmount,
        uint _arrangementFeePercentageInRay,
        address _borrower,
        address _addressDepositToken
    ) external {
        uint cashLoanAmount = ((RAY - _arrangementFeePercentageInRay) *
            _initialLoanAmount) / RAY;

        for (uint i = 0; i < _lenders.length; i++) {
            uint loanFraction = _loanPercentage.balanceOf(_lenders[i]);
            uint cashPortion = (loanFraction * cashLoanAmount) / RAY;
            IDepositToken(_addressDepositToken).transferFrom(
                _lenders[i],
                _borrower,
                cashPortion
            );
        }
    }

    function payInterest(
        uint _dueInterest,
        address _addressDepositToken,
        address _borrower,
        address _loanContract,
        ILoanPercentage _loanPercentage,
        address[] storage _lenders
    ) external returns (uint) {
        if (_dueInterest == 0) return 0;
        uint allowance = checkBalanceBackedAllowance(
            _addressDepositToken,
            _borrower,
            _loanContract
        );

        if (allowance > 0) {
            uint usedAmount = (allowance < _dueInterest)
                ? allowance
                : _dueInterest;
            distributePaymentToLenders(
                _loanPercentage,
                _lenders,
                _borrower,
                _addressDepositToken,
                usedAmount
            );
            return usedAmount;
        }
        return 0;
    }

    function payDefaultInterest(
        uint _dueDefaultInterest,
        address _addressDepositToken,
        address _borrower,
        address _loanContract,
        ILoanPercentage _loanPercentage,
        address[] storage _lenders
    ) public returns (uint) {
        if (_dueDefaultInterest == 0) return 0;
        uint allowance = checkBalanceBackedAllowance(
            _addressDepositToken,
            _borrower,
            _loanContract
        );
        if (allowance > 0) {
            uint usedAmount = (allowance < _dueDefaultInterest)
                ? allowance
                : _dueDefaultInterest;
            distributePaymentToLenders(
                _loanPercentage,
                _lenders,
                _borrower,
                _addressDepositToken,
                usedAmount
            );
            return usedAmount;
        }
        return 0;
    }

    function getDueAndUnpaidPrincipal(
        LoanStatus _loanStatus,
        TimeAndAmount[] storage _repaymentSchedule,
        uint _initialLoanAmount,
        uint _outstandingPrincipal
    ) external view returns (uint) {
        if (_loanStatus == LoanStatus.Proposed) revert LoanNotConfirmed();
        uint totalPrincipalPaid = _initialLoanAmount - _outstandingPrincipal;
        uint duePrincipal = getTotalPrincipalFallenDue(_repaymentSchedule);
        uint dueAndUnpaidPrincipal = duePrincipal - totalPrincipalPaid;
        return dueAndUnpaidPrincipal;
    }

    function getTotalPrincipalFallenDue(
        TimeAndAmount[] storage _repaymentSchedule
    ) public view returns (uint) {
        uint totalDue;
        for (uint i = 0; i < _repaymentSchedule.length; i++) {
            if (_repaymentSchedule[i].time <= block.timestamp)
                totalDue += _repaymentSchedule[i].amount;
        }
        return totalDue;
    }

    function getDueAndUnpaidInterest(
        LoanStatus _loanStatus,
        uint[] storage _interestPaymentTimes,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _creationTime,
        uint _totalInterestPaid
    ) public view returns (uint) {
        if (_loanStatus == LoanStatus.Proposed) revert LoanNotConfirmed();

        (
            uint lastScheduledInterestPaymentTime,

        ) = getTimeAndIndexLastScheduledInterestPaymentBefore(
                _interestPaymentTimes,
                block.timestamp
            );

        uint totalInterestFallenDue = lastScheduledInterestPaymentTime == 0
            ? 0
            : getAccruedInterestBetween(
                _rateAndOutstandingAmountHistory,
                _creationTime,
                lastScheduledInterestPaymentTime
            );
        // totalInterestFallenDue can be less than totalInterestPaid when interestPaymentTimes are changed
        return
            totalInterestFallenDue < _totalInterestPaid
                ? 0
                : totalInterestFallenDue - _totalInterestPaid;
    }

    function getDueAndUnpaidDefaultInterest(
        DefaultInterestTracker storage _defaultInterestTracker,
        uint _defaultInterestRateInRay,
        uint _currentOutstandingPrincipal
    ) public view returns (uint) {
        uint totalAccruedDefaultInterest = _defaultInterestTracker
            .accruedDefaultInterest +
            calculateAccruedInterest(
                _defaultInterestRateInRay,
                _currentOutstandingPrincipal,
                _defaultInterestTracker.defaultInterestUpdateTime,
                block.timestamp
            );
        return
            totalAccruedDefaultInterest -
            _defaultInterestTracker.paidDefaultInterest;
    }

    function getTotalInterestRate(
        uint fixedRateInRay,
        uint floatingRateInRay
    ) external pure returns (uint) {
        return fixedRateInRay.add(floatingRateInRay);
    }

    function getAccruedInterestBetween(
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _interestStartDate,
        uint _interestEndDate
    ) public view returns (uint) {
        if (
            _rateAndOutstandingAmountHistory.length == 0 ||
            _interestStartDate > _interestEndDate ||
            _interestStartDate < _rateAndOutstandingAmountHistory[0].time
        ) revert InvalidInput();
        uint intervalStart = _interestStartDate;
        uint intervalEnd;
        uint intervalInterest;
        uint interestSum;
        uint indexBeforeStart = getIndexHistoryItemBefore(
            _rateAndOutstandingAmountHistory,
            _interestStartDate
        );
        uint indexBeforeEnd = getIndexHistoryItemBefore(
            _rateAndOutstandingAmountHistory,
            _interestEndDate
        );
        uint intervalRate = _rateAndOutstandingAmountHistory[indexBeforeStart]
            .interestRate;
        uint intervalPrincipal = _rateAndOutstandingAmountHistory[
            indexBeforeStart
        ].outstandingAmount;

        for (uint i = indexBeforeStart + 1; i <= indexBeforeEnd + 1; i++) {
            if (i == indexBeforeEnd + 1) {
                intervalEnd = _interestEndDate;
                intervalInterest = calculateAccruedInterest(
                    intervalRate,
                    intervalPrincipal,
                    intervalStart,
                    intervalEnd
                );
                interestSum += intervalInterest;
                break;
            }
            intervalEnd = _rateAndOutstandingAmountHistory[i].time;
            intervalInterest = calculateAccruedInterest(
                intervalRate,
                intervalPrincipal,
                intervalStart,
                intervalEnd
            );
            intervalRate = _rateAndOutstandingAmountHistory[i].interestRate;
            intervalPrincipal = _rateAndOutstandingAmountHistory[i]
                .outstandingAmount;
            intervalStart = intervalEnd;
            interestSum += intervalInterest;
        }
        return interestSum;
    }

    function calculateAccruedInterest(
        uint _interestRateInRay,
        uint _outstandingPrincipal,
        uint _interestStartTime,
        uint _interestEndTime
    ) public pure returns (uint) {
        if (_interestStartTime == 0) return 0;
        uint outstandingPrincipalInRay = _outstandingPrincipal * BILLION;
        uint accruedAnnualInterestInRay = outstandingPrincipalInRay.rmul(
            _interestRateInRay
        );
        uint timeLapsed = (_interestEndTime - _interestStartTime);
        uint accruedInterestInRay = (timeLapsed * accruedAnnualInterestInRay) /
            ONE_YEAR_IN_SEC;

        uint accruedInterestInWei = accruedInterestInRay / BILLION;

        return accruedInterestInWei;
    }

    function checkAndUpdateDefault(
        LoanStatus _loanStatus,
        uint _dueAndUnpaidInterest,
        uint _dueAndUnpaidPrincipal,
        uint _dueAndUnpaidDefaultInterest,
        DefaultInterestTracker storage _defaultInterestTracker
    ) public returns (LoanStatus) {
        LoanStatus status = _loanStatus;
        if (_defaultInterestTracker.defaultInterestUpdateTime == 0) {
            if ((_dueAndUnpaidInterest > 0) || (_dueAndUnpaidPrincipal > 0)) {
                _defaultInterestTracker.defaultInterestUpdateTime = block
                    .timestamp;
                status = LoanStatus.Defaulted;
            }
        } else if (
            _dueAndUnpaidInterest == 0 &&
            _dueAndUnpaidPrincipal == 0 &&
            _dueAndUnpaidDefaultInterest == 0
        ) {
            _defaultInterestTracker.defaultInterestUpdateTime = 0;
            _defaultInterestTracker.accruedDefaultInterest = 0;
            _defaultInterestTracker.paidDefaultInterest = 0; // do we also want to keep track of total paid default interest for APY purposes?
            status = LoanStatus.Performing;
        }
        return status;
    }

    function getIndexHistoryItemBefore(
        TimeRateAmount[] storage _historyArray,
        uint specifiedTime
    ) public view returns (uint) {
        if (specifiedTime < _historyArray[0].time) revert InvalidInput();
        if (_historyArray.length == 1) return 0;
        for (uint i = 1; i < _historyArray.length; i++) {
            if (specifiedTime <= _historyArray[i].time) return i - 1;
        }
        return _historyArray.length - 1;
    }

    function getIndexScheduledRepaymentBefore(
        TimeAndAmount[] memory _repaymentSchedule,
        uint specifiedTime
    ) public pure returns (uint) {
        if (specifiedTime < _repaymentSchedule[0].time) revert InvalidInput();
        if (_repaymentSchedule.length == 1) return 0;
        for (uint i = 1; i < _repaymentSchedule.length; i++) {
            if (specifiedTime <= _repaymentSchedule[i].time) return i - 1;
        }
        return _repaymentSchedule.length - 1;
    }

    function getTimeAndIndexLastScheduledInterestPaymentBefore(
        uint[] memory _interestPaymentTimes,
        uint _specifiedTime
    ) public pure returns (uint, uint) {
        uint latestInterestPaymentTime;
        uint latestIndex = _interestPaymentTimes.length;
        for (uint i = 0; i < _interestPaymentTimes.length; i++) {
            if (_interestPaymentTimes[i] > _specifiedTime) break;
            if (_interestPaymentTimes[i] > latestInterestPaymentTime) {
                latestInterestPaymentTime = _interestPaymentTimes[i];
            }
        }
        return (latestInterestPaymentTime, latestIndex);
    }

    function updateDefaultInterestTracker(
        uint _defaultInterestRateInRay,
        uint _outstandingPrincipal,
        DefaultInterestTracker storage _defaultInterestTracker
    ) public {
        if (_defaultInterestTracker.defaultInterestUpdateTime == 0) return;
        uint defaultInterestSinceLastUpdate = calculateAccruedInterest(
            _defaultInterestRateInRay,
            _outstandingPrincipal,
            _defaultInterestTracker.defaultInterestUpdateTime,
            block.timestamp
        );
        _defaultInterestTracker
            .accruedDefaultInterest += defaultInterestSinceLastUpdate;
        _defaultInterestTracker.defaultInterestUpdateTime = block.timestamp;
    }

    function checkBalanceBackedAllowance(
        address _addressToken,
        address _owner,
        address _spender
    ) public view returns (uint) {
        uint balanceOwner = IDepositToken(_addressToken).balanceOf(_owner);
        uint allowance = IDepositToken(_addressToken).allowance(
            _owner,
            _spender
        );
        uint spendableAmount = allowance <= balanceOwner
            ? allowance
            : balanceOwner;
        return spendableAmount;
    }

    // function distributePaymentToLenders(
    //     EnumerableMapExtended.AddressToUintMap storage _lenderToFractionInRay,
    //     address _borrower,
    //     address _addressDepositToken,
    //     uint _receivedPayment
    // ) public returns (bool) {
    //     uint shareOfPayment;
    //     uint fraction;
    //     address lender;
    //     for (uint i = 0; i < _lenderToFractionInRay.length(); i++) {
    //         (lender, fraction) = _lenderToFractionInRay.at(i);
    //         shareOfPayment =
    //             fraction.rmul(_receivedPayment * BILLION) /
    //             BILLION;
    //         (bool success, ) = _addressDepositToken.call(
    //             abi.encodeWithSignature(
    //                 "transferFrom(address,address,uint256)",
    //                 _borrower,
    //                 lender,
    //                 shareOfPayment
    //             )
    //         );
    //         if (!success) revert DistributionFailed();
    //     }
    //     return true;
    // }

    function distributePaymentToLenders(
        ILoanPercentage _loanPercentage,
        address[] storage _lenders,
        address _borrower,
        address _addressDepositToken,
        uint _receivedPayment
    ) public returns (bool) {
        uint shareOfPayment;
        uint fraction;
        for (uint i = 0; i < _lenders.length; i++) {
            fraction = _loanPercentage.balanceOf(_lenders[i]);
            shareOfPayment =
                fraction.rmul(_receivedPayment * BILLION) /
                BILLION;
            (bool success, ) = _addressDepositToken.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _borrower,
                    _lenders[i],
                    shareOfPayment
                )
            );
            if (!success) revert DistributionFailed();
        }
        return true;
    }

    function updateRateAndOutstandingAmountHistory(
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _updatedInterestRateInRay,
        uint _updatedOutstandingPrincipal
    ) public {
        TimeRateAmount memory updatedValues = TimeRateAmount(
            block.timestamp,
            _updatedInterestRateInRay,
            _updatedOutstandingPrincipal
        );
        _rateAndOutstandingAmountHistory.push(updatedValues);
    }

    // ------------------------- AMENDMENT FUNCTIONS ---------------------------

    function changeRepaymentSchedule(
        TimeAndAmount[] storage _repaymentSchedule,
        TimeAndAmount[] memory _newRepaymentSchedule,
        uint _initialLoanAmount
    ) external {
        for (uint i = 0; i < _newRepaymentSchedule.length; i++) {
            _repaymentSchedule.push(_newRepaymentSchedule[i]);
        }
        if (
            !checkRepaymentscheduleValid(_repaymentSchedule, _initialLoanAmount)
        ) revert InvalidInput();
    }

    function capitalizeDefaultInterest(
        uint _amountToAdd,
        DefaultInterestTracker storage _defaultInterestTracker,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _dueAndUnpaidDefaultInterest,
        uint _outstandingPrincipalBefore,
        uint _defaultInterestRateInRay,
        uint _currentInterestRate
    ) external {
        if (_dueAndUnpaidDefaultInterest == 0) return;
        if (_amountToAdd > _dueAndUnpaidDefaultInterest) revert InvalidInput();
        updateDefaultInterestTracker(
            _defaultInterestRateInRay,
            _outstandingPrincipalBefore,
            _defaultInterestTracker
        );
        uint newOutstandingAmount = _outstandingPrincipalBefore + _amountToAdd;
        updateRateAndOutstandingAmountHistory(
            _rateAndOutstandingAmountHistory,
            _currentInterestRate,
            newOutstandingAmount
        );
        _defaultInterestTracker.paidDefaultInterest += _amountToAdd;
    }

    function capitalizeInterest(
        uint _amountToAdd,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _dueAndUnpaidInterest,
        uint _outstandingPrincipalBefore,
        uint _currentInterestRate
    ) external {
        if (_dueAndUnpaidInterest == 0) return;
        if (_amountToAdd > _dueAndUnpaidInterest) revert InvalidInput();
        uint newOutstandingAmount = _outstandingPrincipalBefore + _amountToAdd;
        updateRateAndOutstandingAmountHistory(
            _rateAndOutstandingAmountHistory,
            _currentInterestRate,
            newOutstandingAmount
        );
    }

    function predictAddress(
        address _addressDeployer,
        uint _nonceDeployer
    ) public pure returns (address) {
        bytes memory data;
        if (_nonceDeployer == 0x00)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x80)
            );
        else if (_nonceDeployer <= 0x7f)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _addressDeployer,
                uint8(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xff)
            data = abi.encodePacked(
                bytes1(0xd7),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x81),
                uint8(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xffff)
            data = abi.encodePacked(
                bytes1(0xd8),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x82),
                uint16(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xffffff)
            data = abi.encodePacked(
                bytes1(0xd9),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x83),
                uint24(_nonceDeployer)
            );
        else
            data = abi.encodePacked(
                bytes1(0xda),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x84),
                uint32(_nonceDeployer)
            );
        return address(uint160(uint256(keccak256(data))));
    }

    function removeItemFromAddressArray(
        address[] storage _addressArray,
        address _addressToRemove
    ) external {
        for (uint i = 0; i < _addressArray.length; i++) {
            if (_addressArray[i] == _addressToRemove) {
                _addressArray[i] = _addressArray[_addressArray.length - 1];
                _addressArray.pop();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IDepositToken {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILoanMultiSig {
    function addOwner(address owner) external;

    function removeOwner(address owner) external;

    function changeRequirement(uint _required) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILoanPercentage {
    function balanceOf(address owner) external view returns (uint256);

    function transferByLoanContract(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

// NT: extended this file with keys functions copied from openzeppeling repo on github

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMapExtended {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(
        Bytes32ToBytes32Map storage map
    ) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToBytes32Map storage map,
        uint256 index
    ) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(
            value != 0 || contains(map, key),
            "EnumerableMap: nonexistent key"
        );
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */

    function keys(
        Bytes32ToBytes32Map storage map
    ) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToUintMap storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToUintMap storage map,
        uint256 index
    ) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return
            address(
                uint160(uint256(get(map._inner, bytes32(key), errorMessage)))
            );
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        AddressToUintMap storage map,
        address key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        AddressToUintMap storage map,
        address key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        AddressToUintMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        AddressToUintMap storage map,
        uint256 index
    ) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        AddressToUintMap storage map,
        address key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(
            map._inner,
            bytes32(uint256(uint160(key)))
        );
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        AddressToUintMap storage map,
        address key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return
            uint256(
                get(map._inner, bytes32(uint256(uint160(key))), errorMessage)
            );
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */

    function keys(
        AddressToUintMap storage map
    ) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        Bytes32ToUintMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToUintMap storage map,
        uint256 index
    ) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}
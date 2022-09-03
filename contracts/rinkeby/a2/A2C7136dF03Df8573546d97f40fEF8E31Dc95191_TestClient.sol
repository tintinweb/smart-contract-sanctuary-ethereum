// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ChainScoreClient.sol";


contract TestClient is ChainScoreClient {

    event RequestFulfilled(address, uint);

    mapping(address => uint) public scoreStore;

    constructor(address score, address _oracle) ChainScoreClient(score, _oracle) {
        setChainscore(_oracle);
    }

    function requestData(address account, bytes32 jobSpec) external {
        sendChainscoreRequest(
            account,
            this.fulfillScore.selector,
            jobSpec,
            1 * 10**18
        );
    }

    function fulfillScore(bytes32 requestID, address account, uint data)
        public
        recordChainscoreFulfillment(requestID)
    {
        scoreStore[account] = data;
        emit RequestFulfilled(account, data);
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment
    ) public {
        cancelChainscoreRequest(
            _requestId,
            _payment
        );
    }

    function getNextRequestCountPublic() public view returns (uint256) {
        return super.getNextRequestCount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/token/IScoreToken.sol";
import "./interfaces/ChainScoreRequestInterface.sol";
import "./interfaces/OracleInterface.sol";

/**
 * @title The ChainscoreClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainscore network
 */
contract ChainScoreClient {
    uint256 internal constant SCORE_DIVISIBILITY = 10**18;
    uint256 private constant AMOUNT_OVERRIDE = 0;
    address private constant SENDER_OVERRIDE = address(0);
    uint256 private constant ORACLE_ARGS_VERSION = 1;
    uint256 private constant OPERATOR_ARGS_VERSION = 2;

    IScoreToken private s_score;
    OracleInterface private s_oracle;
    uint256 private s_requestCount = 0;
    mapping(bytes32 => address) private s_pendingRequests;

    event ChainscoreRequested(bytes32 indexed id);
    event ChainscoreFulfilled(bytes32 indexed id);
    event ChainscoreCancelled(bytes32 indexed id);

    constructor(address scoreToken, address oracleContract){
        s_score = IScoreToken(scoreToken);
        s_oracle = OracleInterface(oracleContract);
    }

    /**
     * @notice Creates a Chainscore request to the stored oracle address
     * @dev Calls `chainscoreRequestTo` with the stored oracle address
     * @param account A
     * @param callbackFunctionSignature A
     * @param jobId A
     * @param payment The amount of score to send for the request
     * @return requestId The request ID
     */
    function sendChainscoreRequest(
        address account,
        bytes4 callbackFunctionSignature,
        bytes32 jobId,
        uint256 payment
    ) internal returns (bytes32) {
        return
            sendChainscoreRequestTo(
                address(s_oracle),
                account,
                callbackFunctionSignature,
                jobId,
                payment
            );
    }

    /**
     * @notice Creates a Chainscore request to the specified oracle address
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send score which creates a request on the target oracle contract.
     * Emits ChainscoreRequested event.
     * @param oracleAddress The address of the oracle for the request
     * @param account A
     * @param callbackFunctionSignature A
     * @param jobId A
     * @param payment The amount of SCORE to send for the request
     * @return requestId The request ID
     */
    function sendChainscoreRequestTo(
        address oracleAddress,
        address account,
        bytes4 callbackFunctionSignature,
        bytes32 jobId,
        uint256 payment
    ) internal returns (bytes32 requestId) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;

        bytes memory encodedRequest = abi.encodeWithSelector(
            ChainScoreRequestInterface.request.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of score sent
            jobId, // Job ID
            callbackFunctionSignature,
            nonce,
            account
        );
        return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
    }

    /**
     * @notice Make a request to an oracle
     * @param oracleAddress The address of the oracle for the request
     * @param nonce used to generate the request ID
     * @param payment The amount of score to send for the request
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
        emit ChainscoreRequested(requestId);

        require(
            s_score.transferAndCall(oracleAddress, payment, encodedRequest),
            "unable to transferAndCall to oracle"
        );
    }

    /**
     * @notice Allows a request to be cancelled if it has not been fulfilled
     * @dev Requires keeping track of the expiration value emitted from the oracle contract.
     * Deletes the request from the `pendingRequests` mapping.
     * Emits ChainscoreCancelled event.
     * @param requestId The request ID
     * @param payment The amount of SCORE sent for the request
     *  callbackFunc The callback function specified for the request
     *  expiration The time of the expiration for the request
     */
    function cancelChainscoreRequest(
        bytes32 requestId,
        uint256 payment
        // bytes4 callbackFunc,
        // uint256 expiration
    ) internal {
        OracleInterface requested = OracleInterface(
            s_pendingRequests[requestId]
        );
        delete s_pendingRequests[requestId];
        emit ChainscoreCancelled(requestId);
        requested.cancelRequest(
            requestId,
            payment
        );
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
     * @notice Sets the stored oracle and token address
     * @param oracleAddress The address of the oracle contract
     */
    function setChainscore(address oracleAddress) internal {
        s_oracle = OracleInterface(oracleAddress);
        setChainscoreToken(s_oracle.getToken());
    }

    /**
     * @notice Sets the stored oracle address
     * @param oracleAddress The address of the oracle contract
     */
    function setChainscoreOracle(address oracleAddress) internal {
        s_oracle = OracleInterface(oracleAddress);
    }

    /**
     * @notice Sets the SCORE token address
     * @param scoreAddress The address of the SCORE token contract
     */
    function setChainscoreToken(address scoreAddress) internal {
        s_score = IScoreToken(scoreAddress);
    }

    /**
     * @notice Retrieves the stored address of the SCORE token
     * @return The address of the SCORE token
     */
    function chainscoreTokenAddress() internal view returns (address) {
        return address(s_score);
    }

    /**
     * @notice Retrieves the stored address of the oracle contract
     * @return The address of the oracle contract
     */
    function chainscoreOracleAddress() internal view returns (address) {
        return address(s_oracle);
    }

    /**
     * @notice Allows for a request which was created on another contract to be fulfilled
     * on this contract
     * @param oracleAddress The address of the oracle contract that will fulfill the request
     * @param requestId The request ID used for the response
     */
    function addChainscoreExternalRequest(
        address oracleAddress,
        bytes32 requestId
    ) internal notPendingRequest(requestId) {
        s_pendingRequests[requestId] = oracleAddress;
    }

    /**
     * @notice Ensures that the fulfillment is valid for this contract
     * @dev Use if the contract developer prefers methods instead of modifiers for validation
     * @param requestId The request ID for fulfillment
     */
    function validateChainscoreCallback(bytes32 requestId)
        internal
        recordChainscoreFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
    {
        require(s_pendingRequests[requestId] == address(s_oracle), "Invalid callback");
    }

    /**
     * @dev Reverts if the sender is not the oracle of the request.
     * Emits ChainscoreFulfilled event.
     * @param requestId The request ID for fulfillment
     */
    modifier recordChainscoreFulfillment(bytes32 requestId) {
        require(
            msg.sender == s_pendingRequests[requestId],
            "Source must be the oracle of the request"
        );
        delete s_pendingRequests[requestId];
        emit ChainscoreFulfilled(requestId);
        _;
    }

    /**
     * @dev Reverts if the request is already pending
     * @param requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 requestId) {
        require(
            s_pendingRequests[requestId] == address(0),
            "Request is already pending"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC677.sol";

interface IScoreToken is IERC20, IERC677 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainScoreRequestInterface {
    function request(
        address sender,
        uint256 payment,
        bytes32 specId,
        bytes4 callbackFunctionId,
        uint256 nonce,
        address account
    ) external;

    function cancelRequest(bytes32 requestId, uint256 payment) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainScoreRequestInterface.sol";
import "./WithdrawalInterface.sol";

interface OracleInterface is ChainScoreRequestInterface, WithdrawalInterface {

  function submitConfirmation(
        bytes32 requestId,
        uint256 payment,
        address callbackAddress,
        bytes4 callbackFunctionId,
        address account,
        uint256 data
    ) external;

  function getToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface WithdrawalInterface {
    
    function withdraw() external;

    function withdrawable(address node) external view returns (uint256);
}
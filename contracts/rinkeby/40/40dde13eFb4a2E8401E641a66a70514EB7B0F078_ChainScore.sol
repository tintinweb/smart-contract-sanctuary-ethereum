// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC677/ERC677Receiver.sol";
import "./AuthorizedReceiver.sol";
import "./interfaces/OracleInterface.sol";
import "./interfaces/WithdrawalInterface.sol";
import "./utils/Response.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FeeDistributor.sol";

/**
 * @title The Chainscore contract
 * @notice ChainScore node operators can submit data and confirmations to this contract
 */
contract ChainScore is
    AuthorizedReceiver,
    ERC677Receiver,
    WithdrawalInterface,
    OracleInterface,
    FeeDistributor
{
    using Response for Response.Confirmation[];
    using Address for address;
    using SafeMath for uint256;

    struct Request {
        uint248 timestamp;
        bool cancelled;
        Response.Confirmation[] confirmations;
    }

    event NewRequest(
        address sender,
        bytes32 indexed specId,
        bytes32 requestId,
        uint256 payment,
        bytes4 callbackFunctionId,
        uint256 cancelExpiration,
        address account
    );
    event ConfirmationCommitted(bytes32 requestId, address node, uint256 data);
    event RequestConfirmed(bytes32 requestId, uint256 finalData);

    event CancelRequest(bytes32 indexed requestId);

    uint256 public constant getExpiryTime = 5 minutes;
    uint256 private constant MINIMUM_CONSUMER_GAS_LIMIT = 400000;

    // oracleRequest is intended for version 1, enabling single word responses
    bytes4 private constant REQUEST_SELECTOR = this.request.selector;

    // SCORE token
    IERC20 internal immutable token;

    // requestId => Request(timestamp, cancelled, confirmations[])
    mapping(bytes32 => Request) public requests;

    // minimum confirmations required for fulfilling requests
    uint256 public minConfirmations = 1;

    // withdrawable rewards for node
    mapping(address => uint256) public rewards;

    /**
     * @notice Deploy with the address of token
     * @dev Sets the address for the imported TokenInterface
     * @param _token The address of the SCORE token
     */
    constructor(address _token, uint256 _minConfirmations) {
        token = IERC20(_token); // external but already deployed and unalterable
        minConfirmations = _minConfirmations;
    }

    function submitConfirmation(
        bytes32 requestId,
        uint256 payment,
        address callbackAddress,
        bytes4 callbackFunctionId,
        address account,
        uint256 data
    ) external override validateAuthorizedSender {
        Request storage req = requests[requestId];

        require(
            req.confirmations.length < minConfirmations,
            "Already confirmed"
        );

        Response.Confirmation memory _conf = Response.Confirmation(
            msg.sender,
            data
        );
        req.confirmations.push(_conf);

        emit ConfirmationCommitted(requestId, msg.sender, data);

        if (req.confirmations.length == minConfirmations && !req.cancelled) {
            uint256 finalData = req.confirmations.median();

            _fulfillOracleRequest(
                requestId,
                payment,
                callbackAddress,
                callbackFunctionId,
                uint256(req.timestamp).add(getExpiryTime),
                account,
                finalData
            );

            emit RequestConfirmed(requestId, finalData);
        }
    }

    /**
     * @notice Creates the ChainScore request. This is a backwards compatible API
     * with the Oracle.sol contract, but the behavior changes because
     * callbackAddress is assumed to be the same as the request sender.
     * @param sender The address the oracle data will be sent to
     * @param payment The amount of payment given (specified in wei)
     * @param specId The Job Specification ID
     * @param callbackFunctionId The callback function ID for the response
     * @param nonce The nonce sent by the requester
     * @param account The extra request parameters
     */
    function request(
        address sender,
        uint256 payment,
        bytes32 specId,
        bytes4 callbackFunctionId,
        uint256 nonce,
        address account
    ) external override validateFromToken {
        require(sender != address(token), "Callback address is token");

        bytes32 requestId = keccak256(abi.encodePacked(sender, nonce));

        require(
            requests[requestId].confirmations.length == 0,
            "Must use a unique ID"
        );

        uint256 expiration = block.timestamp.add(getExpiryTime);

        emit NewRequest(
            sender,
            specId,
            requestId,
            payment,
            callbackFunctionId,
            expiration,
            account
        );
    }

    /**
     * @notice Called by the ChainScore node to fulfill requests
     * @dev Given params must hash back to the commitment stored from `oracleRequest`.
     * Will call the callback address' callback function without bubbling up error
     * checking in a `require` so that the node can get paid.
     * @param requestId The fulfillment request ID that must match the requester's
     * @param payment The payment amount that will be released for the oracle (specified in wei)
     * @param callbackAddress The callback address to call for fulfillment
     * @param callbackFunctionId The callback function ID to use for fulfillment
     * @param expiration The expiration that the node should respond by before the requester can cancel
     * @param data The data to return to the consuming contract
     * @return Status if the external call was successful
     */
    function _fulfillOracleRequest(
        bytes32 requestId,
        uint256 payment,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 expiration,
        address account,
        uint256 data
    ) internal returns (bool) {
        _verifyOracleRequestAndProcessPayment(
            requestId,
            payment,
            expiration,
            data
        );

        require(
            gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT,
            "Must provide consumer enough gas"
        );
        // All updates to the oracle's fulfillment should come before calling the
        // callback(addr+functionId) as it is untrusted.
        // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern
        (bool success, ) = callbackAddress.call(
            abi.encodeWithSelector(callbackFunctionId, requestId, account, data)
        ); // solhint-disable-line avoid-low-level-calls

        return success;
    }

    /**
     * @notice Verify the Oracle request and unlock escrowed payment
     * @param requestId The fulfillment request ID that must match the requester's
     * @param payment The payment amount that will be released for the oracle (specified in wei)
     * @param expiration The expiration that the node should respond by before the requester can cancel
     * @param finalData Final computed data
     */
    function _verifyOracleRequestAndProcessPayment(
        bytes32 requestId,
        uint256 payment,
        uint256 expiration,
        uint256 finalData
    ) internal {
        // 1/minConfirmations'th of payment to each validator
        for (uint256 i = 0; i < requests[requestId].confirmations.length; i++) {
            rewards[requests[requestId].confirmations[i].from] +=
                payment /
                minConfirmations;
        }

        distributeFee();
    }

    /**
     * @notice Allows requester to cancel requests sent to this oracle contract.
     * Will transfer the SCORE sent for the request back to the recipient address.
     * @dev Given params must hash to a commitment stored on the contract in order
     * for the request to be valid. Emits CancelOracleRequest event.
     * @param requestId The nonce used to generate the request ID
     * @param payment The amount of payment given (specified in wei)
     */
    function cancelRequest(bytes32 requestId, uint256 payment)
        external
        override
    {
        Request storage req = requests[requestId];

        // If request is expired
        // solhint-disable-next-line not-rely-on-time
        if (uint256(req.timestamp).add(getExpiryTime) <= block.timestamp) {
            token.transfer(msg.sender, payment);
        }

        req.cancelled = true;

        emit CancelRequest(requestId);
    }

    /// @notice Updates minimum confirmations needed
    /// @dev newConf = uint
    /// @param newConfirmations new confirmation number
    function updateMinConfirmations(uint256 newConfirmations)
        external
        onlyOwner
    {
        minConfirmations = newConfirmations;
    }

    function withdraw() external override {
        token.transfer(msg.sender, rewards[msg.sender]);
    }

    /* -------------------------------------------------------------------------- */
    /*                               View functions                               */
    /* -------------------------------------------------------------------------- */
    function withdrawable(address node)
        external
        view
        override
        returns (uint256)
    {
        return rewards[node];
    }

    function isRequestConfirmed(bytes32 requestId)
        external
        view
        returns (bool)
    {
        return requests[requestId].confirmations.length > minConfirmations;
    }

    /**
     * @notice Require that the token transfer action is valid
     * @dev OPERATOR_REQUEST_SELECTOR = multiword, ORACLE_REQUEST_SELECTOR = singleword
     */
    function _validateTokenTransferAction(
        bytes4 funcSelector,
        bytes memory data
    ) internal pure override {
        require(
            funcSelector == REQUEST_SELECTOR,
            "Must use whitelisted functions"
        );
    }

    /**
     * @notice Returns the address of the SCORE token
     * @dev This is the public implementation for chainscoreTokenAddress, which is
     * an internal method of the ChainScoreClient contract
     */
    function getToken()
        public
        view
        override(
            ERC677Receiver,
            OracleInterface,
            FeeDistributor,
            AuthorizedReceiver
        )
        returns (address)
    {
        return address(token);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC677Receiver {
  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @dev The data payload's first 2 words will be overwritten by the `sender` and `amount`
   * values to ensure correctness. Calls request.
   * @param sender Address of the sender
   * @param amount Amount of LINK sent (specified in wei)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes memory data
  ) public validateFromToken permittedFunctionsForToken(data) {
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 36), sender) // ensure correct sender is passed
      // solhint-disable-next-line avoid-low-level-calls
      mstore(add(data, 68), amount) // ensure correct amount is passed
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = address(this).delegatecall(data); // calls request
    require(success, "Unable to create request");
  }

  function getToken() public view virtual returns (address);

  /**
   * @notice Validate the function called on token transfer
   */
  function _validateTokenTransferAction(bytes4 funcSelector, bytes memory data) internal virtual;

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier validateFromToken() {
    require(msg.sender == getToken(), "ERC677Receiver: Use of Invalid token");
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `request` function selector
   * @param data The data payload of the request
   */
  modifier permittedFunctionsForToken(bytes memory data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(data, 32))
    }
    _validateTokenTransferAction(funcSelector, data);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AuthorizedReceiver is Ownable, ReentrancyGuard {
    mapping(address => bool) private s_authorizedSenders;

    mapping(address => uint256) private _authSenderBal; // authsender => balance

    mapping(address => mapping(address => uint256)) userBalance; // authsender => user => balance

    // event AuthorizedSendersChanged(address[] senders, address changedBy);
    event AuthorizedSendersAdded(address sender, address addedBy);
    event AuthorizedSendersRemoved(address sender, address removedBy);

    event Staked(address sender, address authSender, uint256 tokenAmt);
    event Withdrawn(address sender, uint256 tokenAmt);

    function stake(uint256 _amount, address authSender) external {
        IERC20(getToken()).transferFrom(msg.sender, address(this), _amount);
        userBalance[authSender][msg.sender] = _amount;
        _authSenderBal[authSender] += _amount;
        emit Staked(msg.sender, authSender, _amount);
    }

    function unstake(address sender, uint256 _amount) public nonReentrant {
        _authSenderBal[msg.sender] -= _amount;
        IERC20(getToken()).transfer(msg.sender, _amount);
        emit Withdrawn(sender, _amount);
    }

    function getToken() public view virtual returns (address);

    /**
     * @notice Sets the fulfillment permission for a given node. Use `true` to allow, `false` to disallow.
     * @param sender The addresses of the authorized Chainscore node
     */
    function setAuthorizedSenders(address sender)
        public
        validateAuthorizedSenderSetter
    {
        s_authorizedSenders[sender] = true;

        emit AuthorizedSendersAdded(sender, msg.sender);
    }

    function removeAuthorizedSenders(address sender) public onlyOwner {
        require(s_authorizedSenders[sender] == true, "Not a Authorized sender");
        s_authorizedSenders[sender] = false;

        // Need to add logic to calculate Refund Amt
        // uint256 refund ;
        // unstake(sender, refund);
        emit AuthorizedSendersRemoved(sender, msg.sender);
    }

    /**
     * @notice Use this to check if a node is authorized for fulfilling requests
     * @param sender The address of the Chainscore node
     * @return The authorization status of the node
     */
    function isAuthorizedSender(address sender) public view returns (bool) {
        return s_authorizedSenders[sender];
    }

    /**
     * @notice customizable guard of who can update the authorized sender list
     * @return bool whether sender can update authorized sender list
     */
    function _canSetAuthorizedSenders(address account)
        public
        view
        returns (bool)
    {
        return owner() == account;
    }

    /**
     * @notice validates the sender is an authorized sender
     */
    function _validateIsAuthorizedSender() internal view {
        require(isAuthorizedSender(msg.sender), "Not authorized sender");
    }

    /**
     * @notice prevents non-authorized addresses from calling this method
     */
    modifier validateAuthorizedSender() {
        _validateIsAuthorizedSender();
        _;
    }

    /**
     * @notice prevents non-authorized addresses from calling this method
     */
    modifier validateAuthorizedSenderSetter() {
        require(
            _canSetAuthorizedSenders(msg.sender),
            "Cannot set authorized senders"
        );
        _;
    }
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
pragma solidity ^0.8.0;

interface WithdrawalInterface {
    
    function withdraw() external;

    function withdrawable(address node) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Response {
    
    struct Confirmation {
        address from;
        uint256 data;
    }

    function median(Confirmation[] memory data) internal returns (uint256) {
        Confirmation[] memory sortedData = sortData(data);
        if (sortedData.length % 2 == 1) {
            return sortedData[sortedData.length / 2].data;
        } else {
            return
                (5 *
                    (sortedData[sortedData.length / 2 - 1].data +
                        sortedData[sortedData.length / 2].data)) / 10;
        }
    }

    function sortData(Confirmation[] memory data)
        internal
        returns (Confirmation[] memory)
    {
        quickSortData(data, int256(0), int256(data.length - 1));
        return data;
    }

    function quickSortData(
        Confirmation[] memory arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].data;
        while (i <= j) {
            while (arr[uint256(i)].data < pivot) i++;
            while (pivot < arr[uint256(j)].data) j--;
            if (i <= j) {
                (arr[uint256(i)].data, arr[uint256(j)].data) = (
                    arr[uint256(j)].data,
                    arr[uint256(i)].data
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSortData(arr, left, j);
        if (i < right) quickSortData(arr, i, right);
    }

    function distributeRewards(
        Confirmation[] memory conf,
        uint256 finalData,
        uint256 payment
    ) internal returns (uint256[] memory rewards) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/token/IScoreToken.sol";

abstract contract FeeDistributor {

    function distributeFee(
        // uint[] memory data, address[] memory node, uint finalData, uint payment
    ) internal {
        // require(data.length == node.length);

        // IScoreToken(getToken()).transfer(node[0], payment);
    }

    function getToken() public virtual returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC677.sol";

interface IScoreToken is IERC20, IERC677 {}

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
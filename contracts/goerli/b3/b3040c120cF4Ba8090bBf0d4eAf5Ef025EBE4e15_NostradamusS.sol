// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.7.6;

/// @author Scry Finance Team
/// @title IScryFactory
/// @notice Interface for interacting with the ScryFactory Contract
interface IScryFactory {

    /**
     * @dev gets the current scry router
     *
     * @return the current scry router
    */
    function getScryRouter() external returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Scry Finance Team
/// @title IScryRouter
/// @notice Interface for interacting with the Router Contract
interface IScryRouter {

    /**
     * @dev calls the deposit function
    */
    function deposit() external payable;
}

// SPDX-License-Identifier: SCRY
pragma solidity 0.7.6;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IScryFactory.sol";
import "./interfaces/IScryRouter.sol";

contract NostradamusS {
    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;

    // the address of the collateral contract factory
    address public factoryContract;

    // address used for pay out
    address payable public payoutAddress;

    // number of signers
    uint256 public signerLength;

    // addresses of the signers
    address[] public signers;

    // threshold which has to be reached
    uint256 public signerThreshold = 1;
    mapping(uint256 => mapping(address => uint256)) private signerSign;

    // indicates if sender is a signer
    mapping(address => bool) private isSigner;

    // indicates support of feeds
    mapping(uint256 => uint256) public feedSupport;

    // indicates if address si subscribed to a feed
    mapping(address => mapping(uint256 => uint256)) private subscribedTo;

    struct oracleStruct {
        string feedAPIendpoint;
        string feedAPIendpointPath;
        uint256 latestPrice;
        uint256 latestPriceUpdate;
        uint256 feedDecimals;
    }

    oracleStruct[] private feedList;

    // indicates if oracle subscription is turned on. 0 indicates no pass
    uint256 public subscriptionPassPrice;

    mapping(address => uint256) private hasPass;

    struct proposalStruct {
        uint256 uintValue;
        address addressValue;
        address proposer;
        // 0 ... pricePass
        // 1 ... threshold
        // 2 ... add signer
        // 3 ... remove signer
        // 4 ... payoutAddress
        // 5 ...
        // 6 ...
        uint256 proposalType;
        uint256 proposalFeedId;
        uint256 proposalActive;
    }

    proposalStruct[] public proposalList;

    mapping(uint256 => mapping(address => bool)) private hasSignedProposal;

    event contractSetup(
        address[] signers,
        uint256 signerThreshold,
        address payout
    );
    event feedRequested(
        string endpoint,
        string endpointp,
        uint256,
        uint256,
        uint256 feedId
    );
    event feedSigned(
        uint256 feedId,
        uint256 value,
        uint256 timestamp,
        address signer
    );
    event feedSubmitted(uint256 feedId, uint256 value, uint256 timestamp);
    event routerFeeTaken(uint256 value, address sender);
    event feedSupported(uint256 feedId, uint256 supportvalue);
    event newProposal(
        uint256 proposalId,
        uint256 uintValue,
        address addressValue,
        uint256 oracleType,
        address proposer
    );
    event proposalSigned(uint256 proposalId, address signer);
    event newFee(uint256 value);
    event newThreshold(uint256 value);
    event newSigner(address signer);
    event signerRemoved(address signer);
    event newPayoutAddress(address payout);
    event subscriptionPassPriceUpdated(uint256 newPass);

    // only Signer modifier
    modifier onlySigner() {
        _onlySigner();
        _;
    }

    // only Signer view
    function _onlySigner() private view {
        require(isSigner[msg.sender], "Only a signer can perform this action");
    }

    constructor() {}

    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external {
        require(factoryContract == address(0), "already initialized");
        require(factoryContract_ != address(0), "factory can not be null");
        require(signerThreshold_ != 0, "Threshold cant be 0");
        require(
            signerThreshold_ <= signers_.length,
            "Threshold cant be more then signer count"
        );

        factoryContract = factoryContract_;
        signerThreshold = signerThreshold_;
        signers = signers_;

        for (uint256 i = 0; i < signers.length; i++) {
            require(signers[i] != address(0), "Not zero address");
            isSigner[signers[i]] = true;
        }

        signerLength = signers_.length;
        payoutAddress = payoutAddress_;
        subscriptionPassPrice = subscriptionPassPrice_;
        emit contractSetup(signers_, signerThreshold, payoutAddress);
    }

    //---------------------------helper functions---------------------------

    //---------------------------view functions ---------------------------

    /**
     * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
     *
     * @param feedIDs the array of feedIds
     */
    function getFeeds(uint256[] memory feedIDs)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            string[] memory,
            string[] memory
        )
    {
        uint256 feedLen = feedIDs.length;
        uint256[] memory returnPrices = new uint256[](feedLen);
        uint256[] memory returnTimestamps = new uint256[](feedLen);
        uint256[] memory returnDecimals = new uint256[](feedLen);
        string[] memory returnEndpoint = new string[](feedLen);
        string[] memory returnPath = new string[](feedLen);
        for (uint256 i = 0; i < feedIDs.length; i++) {
            (returnPrices[i], returnTimestamps[i], returnDecimals[i]) = getFeed(
                feedIDs[i]
            );
            returnEndpoint[i] = feedList[feedIDs[i]].feedAPIendpoint;
            returnPath[i] = feedList[feedIDs[i]].feedAPIendpointPath;
        }

        return (
            returnPrices,
            returnTimestamps,
            returnDecimals,
            returnEndpoint,
            returnPath
        );
    }

    /**
     * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
     *
     * @param feedID the array of feedId
     */
    function getFeed(uint256 feedID)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 returnPrice;
        uint256 returnTimestamp;
        uint256 returnDecimals;

        returnPrice = feedList[feedID].latestPrice;
        returnTimestamp = feedList[feedID].latestPriceUpdate;
        returnDecimals = feedList[feedID].feedDecimals;
        return (returnPrice, returnTimestamp, returnDecimals);
    }

    function getFeedLength() external view returns (uint256) {
        return feedList.length;
    }

    //---------------------------oracle management functions ---------------------------

    // function to withdraw funds
    function withdrawFunds() external {
        if (payoutAddress == address(0)) {
            for (uint256 n = 0; n < signers.length; n++) {
                payable(signers[n]).transfer(
                    address(this).balance / signers.length
                );
            }
        } else {
            payoutAddress.transfer(address(this).balance);
        }
    }

    function requestFeeds(
        string[] memory APIendpoint,
        string[] memory APIendpointPath,
        uint256[] memory decimals,
        uint256[] memory bounties
    ) external payable returns (uint256[] memory feeds) {
        require(
            APIendpoint.length == APIendpointPath.length,
            "Length mismatch"
        );
        uint256 total;
        uint256[] memory fds = new uint256[](APIendpointPath.length);
        for (uint256 i = 0; i < APIendpoint.length; i++) {
            feedList.push(
                oracleStruct({
                    feedAPIendpoint: APIendpoint[i],
                    feedAPIendpointPath: APIendpointPath[i],
                    latestPrice: 0,
                    latestPriceUpdate: 0,
                    feedDecimals: decimals[i]
                })
            );
            total += bounties[i];
            feedSupport[feedList.length - 1] = feedSupport[feedList.length - 1]
                .add(bounties[i]);
            fds[i] = feedList.length - 1;
            require(total <= msg.value);
            emit feedRequested(
                APIendpoint[i],
                APIendpointPath[i],
                bounties[i],
                decimals[i],
                feedList.length - 1
            );
        }
        return (fds);
    }

    /**
     * @dev submitFeed function lets a signer submit as many feeds as they want to
     *
     * @param values the array of values
     * @param feedIDs the array of feedIds
     */
    function submitFeed(uint256[] memory feedIDs, uint256[] memory values)
        external
        onlySigner
    {
        require(
            values.length == feedIDs.length,
            "Value length and feedID length do not match"
        );
        uint256 total;
        // process feeds
        for (uint256 i = 0; i < values.length; i++) {
            emit feedSigned(feedIDs[i], values[i], block.timestamp, msg.sender);
            feedList[feedIDs[i]].latestPriceUpdate = block.timestamp;
            feedList[feedIDs[i]].latestPrice = values[i];
            emit feedSubmitted(feedIDs[i], values[i], block.timestamp);
            total += feedSupport[feedIDs[i]];
         feedSupport[feedIDs[i]] = 0;
        }
        msg.sender.transfer(total);
    }

    function signProposal(uint256 proposalId) external onlySigner {
        require(
            proposalList[proposalId].proposalActive != 0,
            "Proposal not active"
        );

        hasSignedProposal[proposalId][msg.sender] = true;
        emit proposalSigned(proposalId, msg.sender);

        uint256 signedProposalLen;

        for (uint256 i = 0; i < signers.length; i++) {
            if (hasSignedProposal[proposalId][signers[i]]) {
                signedProposalLen++;
            }
        }

        // execute proposal
        if (signedProposalLen >= signerThreshold) {
            if (proposalList[proposalId].proposalType == 0) {
                updatePricePass(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 1) {
                //  updateThreshold(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 2) {
                addSigners(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 3) {
                removeSigner(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 4) {
                updatePayoutAddress(proposalList[proposalId].addressValue);
            }

            // lock proposal
            proposalList[proposalId].proposalActive = 0;
        }
    }

    function createProposal(
        uint256 uintValue,
        address addressValue,
        uint256 proposalType,
        uint256 feedId
    ) external onlySigner {
        uint256 proposalArrayLen = proposalList.length;

        // fee or threshold
        if (proposalType == 0 || proposalType == 1 || proposalType == 7) {
            proposalList.push(
                proposalStruct({
                    uintValue: uintValue,
                    addressValue: address(0),
                    proposer: msg.sender,
                    proposalType: proposalType,
                    proposalFeedId: 0,
                    proposalActive: 1
                })
            );
        } else if (proposalType == 5 || proposalType == 6) {
            proposalList.push(
                proposalStruct({
                    uintValue: uintValue,
                    addressValue: address(0),
                    proposer: msg.sender,
                    proposalType: proposalType,
                    proposalFeedId: feedId,
                    proposalActive: 1
                })
            );
        } else {
            proposalList.push(
                proposalStruct({
                    uintValue: 0,
                    addressValue: addressValue,
                    proposer: msg.sender,
                    proposalType: proposalType,
                    proposalFeedId: 0,
                    proposalActive: 1
                })
            );
        }

        hasSignedProposal[proposalArrayLen][msg.sender] = true;

        emit newProposal(
            proposalArrayLen,
            uintValue,
            addressValue,
            proposalType,
            msg.sender
        );
        emit proposalSigned(proposalArrayLen, msg.sender);
    }

    function updatePricePass(uint256 newPricePass) private {
        subscriptionPassPrice = newPricePass;

        emit subscriptionPassPriceUpdated(newPricePass);
    }

    function updateThreshold(uint256 newThresholdValue) private {
        require(newThresholdValue != 0, "Threshold cant be 0");
        require(
            newThresholdValue <= signerLength,
            "Threshold cant be bigger then length of signers"
        );

        signerThreshold = newThresholdValue;
        emit newThreshold(newThresholdValue);
    }

    function addSigners(address newSignerValue) private {
        // check for duplicate signer
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == newSignerValue) {
                revert("Signer already exists");
            }
        }

        signers.push(newSignerValue);
        signerLength++;
        isSigner[newSignerValue] = true;
        emit newSigner(newSignerValue);
    }

    function updatePayoutAddress(address newPayoutAddressValue) private {
        payoutAddress = payable(newPayoutAddressValue);
        emit newPayoutAddress(newPayoutAddressValue);
    }

    function removeSigner(address toRemove) internal {
        require(isSigner[toRemove], "Address to remove has to be a signer");
        require(
            signers.length - 1 >= signerThreshold,
            "Less signers than threshold"
        );

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == toRemove) {
                delete signers[i];
                signerLength--;
                isSigner[toRemove] = false;
                emit signerRemoved(toRemove);
            }
        }
    }

    //---------------------------subscription functions---------------------------

    function buyPass(address buyer, uint256 duration) external payable {
        require(subscriptionPassPrice != 0, "Subscription Pass turned off");
        require(duration >= 3600, "Minimum subscription is 1h");
        require(
            msg.value >= (subscriptionPassPrice * duration) / 86400,
            "Not enough payment"
        );

        if (hasPass[buyer] <= block.timestamp) {
            hasPass[buyer] = block.timestamp.add(duration);
        } else {
            hasPass[buyer] = hasPass[buyer].add(duration);
        }
        // address payable ScryRouter = IScryFactory(factoryContract).getScryRouter();
        // IScryRouter(ScryRouter).deposit{value:msg.value/50}();
        emit routerFeeTaken(msg.value / 50, msg.sender);
    }

    function supportFeeds(uint256[] memory feedIds, uint256[] memory values)
        external
        payable
    {
        require(feedIds.length == values.length, "Length mismatch");
        uint256 total;
        for (uint256 i = 0; i < feedIds.length; i++) {
            feedSupport[feedIds[i]] = feedSupport[feedIds[i]].add(values[i]);
            total += values[i];
            emit feedSupported(feedIds[i], values[i]);
        }
        require(msg.value >= total, "Msg.value does not meet support values");

        //address payable ScryRouter = IScryFactory(factoryContract).getScryRouter();
        // IScryRouter(ScryRouter).deposit{value:total/100}();
        emit routerFeeTaken(total / 100, msg.sender);
    }
}
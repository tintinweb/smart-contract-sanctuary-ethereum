// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UsingTellor.sol";
import "./interfaces/IDIVAOracleTellor.sol";
import "./interfaces/IDIVA.sol";
import "./libraries/SafeDecimalMath.sol";

contract DIVAOracleTellor is
    UsingTellor,
    IDIVAOracleTellor,
    Ownable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20Metadata;
    using SafeDecimalMath for uint256;

    // Ordered to optimize storage
    mapping(uint256 => mapping(address => uint256)) private _tips; // mapping poolId => tipping token address => tip amount
    mapping(uint256 => address[]) private _poolIdToTippingTokens; // mapping poolId to tipping tokens
    mapping(uint256 => address) private _poolIdToReporter; // mapping poolId to reporter address

    uint256 private _maxFeeAmountUSD; // expressed as an integer with 18 decimals
    address private _excessFeeRecipient;
    uint32 private _minPeriodUndisputed;
    bool private immutable _challengeable;
    IDIVA private immutable _diva;

    modifier onlyConfirmedPool(uint256 _poolId) {
        if (_poolIdToReporter[_poolId] == address(0)) {
            revert NotConfirmedPool();
        }
        _;
    }

    constructor(
        address payable tellorAddress_,
        address excessFeeRecipient_,
        uint32 minPeriodUndisputed_,
        uint256 maxFeeAmountUSD_,
        address diva_
    ) UsingTellor(tellorAddress_) {
        _challengeable = false;
        _excessFeeRecipient = excessFeeRecipient_;
        _minPeriodUndisputed = minPeriodUndisputed_;
        _maxFeeAmountUSD = maxFeeAmountUSD_;
        _diva = IDIVA(diva_);
    }

    function addTip(
        uint256 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external override nonReentrant {
        if (_poolIdToReporter[_poolId] != address(0)) {
            revert AlreadyConfirmedPool();
        }

        if (_tips[_poolId][_tippingToken] == 0) {
            _poolIdToTippingTokens[_poolId].push(_tippingToken);
        }
        IERC20Metadata(_tippingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _tips[_poolId][_tippingToken] += _amount;
        emit TipAdded(_poolId, _tippingToken, _amount, msg.sender);
    }

    function claimTips(uint256 _poolId, address[] calldata _tippingTokens)
        external
        override
        nonReentrant
        onlyConfirmedPool(_poolId)
    {
        _claimTips(_poolId, _tippingTokens);
    }

    function claimDIVAFee(uint256 _poolId)
        external
        override
        nonReentrant
        onlyConfirmedPool(_poolId)
    {
        _claimDIVAFee(_poolId);
    }

    function claimTipsAndDIVAFee(
        uint256 _poolId,
        address[] calldata _tippingTokens
    ) external override nonReentrant onlyConfirmedPool(_poolId) {
        _claimTips(_poolId, _tippingTokens);
        _claimDIVAFee(_poolId);
    }

    function setFinalReferenceValue(uint256 _poolId)
        external
        override
        nonReentrant
    {
        _setFinalReferenceValue(_poolId);
    }

    function setFinalReferenceValueAndClaimTips(
        uint256 _poolId,
        address[] calldata _tippingTokens
    ) external override nonReentrant {
        _setFinalReferenceValue(_poolId);
        _claimTips(_poolId, _tippingTokens);
    }

    function setFinalReferenceValueAndClaimDIVAFee(uint256 _poolId)
        external
        override
        nonReentrant
    {
        _setFinalReferenceValue(_poolId);
        _claimDIVAFee(_poolId);
    }

    function setFinalReferenceValueAndClaimTipsAndDIVAFee(
        uint256 _poolId,
        address[] calldata _tippingTokens
    ) external override nonReentrant {
        _setFinalReferenceValue(_poolId);
        _claimTips(_poolId, _tippingTokens);
        _claimDIVAFee(_poolId);
    }

    function setExcessFeeRecipient(address _newExcessFeeRecipient)
        external
        override
        onlyOwner
    {
        if (_newExcessFeeRecipient == address(0)) {
            revert ZeroExcessFeeRecipient();
        }
        _excessFeeRecipient = _newExcessFeeRecipient;
    }

    function setMinPeriodUndisputed(uint32 _newMinPeriodUndisputed)
        external
        override
        onlyOwner
    {
        if (_newMinPeriodUndisputed < 3600 || _newMinPeriodUndisputed > 64800) {
            revert OutOfRange();
        }
        _minPeriodUndisputed = _newMinPeriodUndisputed;
    }

    function setMaxFeeAmountUSD(uint256 _newMaxFeeAmountUSD)
        external
        override
        onlyOwner
    {
        _maxFeeAmountUSD = _newMaxFeeAmountUSD;
    }

    function challengeable() external view override returns (bool) {
        return _challengeable;
    }

    function getExcessFeeRecipient() external view override returns (address) {
        return _excessFeeRecipient;
    }

    function getMaxFeeAmountUSD() external view override returns (uint256) {
        return _maxFeeAmountUSD;
    }

    function getMinPeriodUndisputed() external view override returns (uint32) {
        return _minPeriodUndisputed;
    }

    function getTippingTokens(uint256 _poolId)
        external
        view
        override
        returns (address[] memory)
    {
        return _poolIdToTippingTokens[_poolId];
    }

    function getTip(uint256 _poolId, address _tippingToken)
        external
        view
        override
        returns (uint256)
    {
        return _tips[_poolId][_tippingToken];
    }

    function getQueryId(uint256 _poolId)
        public
        view
        override
        returns (bytes32)
    {
        // Construct Tellor queryID
        // https://github.com/tellor-io/dataSpecs/blob/main/types/DIVAProtocolPolygon.md
        return
            keccak256(
                abi.encode(
                    "DIVAProtocol",
                    abi.encode(_poolId, address(_diva), block.chainid)
                )
            );
    }

    function getDIVAAddress() external view override returns (address) {
        return address(_diva);
    }

    function getReporter(uint256 _poolId)
        external
        view
        override
        returns (address)
    {
        return _poolIdToReporter[_poolId];
    }

    function _claimDIVAFee(uint256 _poolId) private {
        IDIVA.Pool memory _params = _diva.getPoolParameters(_poolId);
        _diva.claimFee(_params.collateralToken, _poolIdToReporter[_poolId]);
    }

    function _claimTips(uint256 _poolId, address[] calldata _tippingTokens)
        private
    {
        uint256 len = _tippingTokens.length;
        for (uint256 i = 0; i < len; ) {
            address _tippingToken = _tippingTokens[i];

            uint256 _tipAmount = _tips[_poolId][_tippingToken];
            _tips[_poolId][_tippingToken] = 0;

            IERC20Metadata(_tippingToken).safeTransfer(
                _poolIdToReporter[_poolId],
                _tipAmount
            );

            emit TipClaimed(
                _poolId,
                _poolIdToReporter[_poolId],
                _tippingToken,
                _tipAmount
            );

            unchecked {
                ++i;
            }
        }
    }

    function _setFinalReferenceValue(uint256 _poolId) private {
        IDIVA.Pool memory _params = _diva.getPoolParameters(_poolId); // updated the Pool struct based on the latest contracts

        // Get queryId from poolId
        bytes32 _queryId = getQueryId(_poolId);

        // Find first oracle submission
        uint256 _timestampRetrieved = getTimestampbyQueryIdandIndex(
            _queryId,
            0
        );

        // Handle case where data was submitted before expiryTime
        if (_timestampRetrieved < _params.expiryTime) {
            // Check that data exists (_timestampRetrieved = 0 if it doesn't)
            if (_timestampRetrieved == 0) {
                revert NoOracleSubmission();
            }

            // Retrieve latest array index of data before `_expiryTime` for the queryId
            (, uint256 _index) = getIndexForDataBefore(
                _queryId,
                _params.expiryTime
            );

            // Increment index to get the first data point after `_expiryTime`
            ++_index;

            // Get timestamp of first data point after `_expiryTime`
            _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _index
            );

            // _timestampRetrieved = 0 if there is no submission
            if (_timestampRetrieved == 0) {
                revert NoOracleSubmissionAfterExpiryTime();
            }
        }

        // Check that _minPeriodUndisputed has passed after _timestampRetrieved
        if (block.timestamp - _timestampRetrieved < _minPeriodUndisputed) {
            revert MinPeriodUndisputedNotPassed();
        }

        // Retrieve values (final reference value and USD value of collateral asset)
        bytes memory _valueRetrieved = retrieveData(
            _queryId,
            _timestampRetrieved
        );

        // Format values (18 decimals)
        (
            uint256 _formattedFinalReferenceValue,
            uint256 _formattedCollateralToUSDRate
        ) = abi.decode(_valueRetrieved, (uint256, uint256));

        // Get address of reporter who will receive
        address _reporter = tellor.getReporterByTimestamp(
            _queryId,
            _timestampRetrieved
        );

        // Set reporter with pool id
        _poolIdToReporter[_poolId] = _reporter;

        // Forward final value to DIVA contract. Allocates the fee as part of that process.
        _diva.setFinalReferenceValue(
            _poolId,
            _formattedFinalReferenceValue,
            _challengeable
        );

        uint256 _SCALING = uint256(
            10**(18 - IERC20Metadata(_params.collateralToken).decimals())
        );
        // Get the current fee claim allocated to this contract address (msg.sender)
        uint256 feeClaim = _diva.getClaim(
            _params.collateralToken,
            address(this)
        ); // denominated in collateral token; integer with collateral token decimals

        uint256 feeClaimUSD = (feeClaim * _SCALING).multiplyDecimal(
            _formattedCollateralToUSDRate
        ); // denominated in USD; integer with 18 decimals
        uint256 feeToReporter;
        uint256 feeToExcessRecipient;

        if (feeClaimUSD > _maxFeeAmountUSD) {
            // if _formattedCollateralToUSDRate = 0, then feeClaimUSD = 0 in which case it will
            // go into the else part, hence division by zero is not a problem
            feeToReporter =
                _maxFeeAmountUSD.divideDecimal(_formattedCollateralToUSDRate) /
                _SCALING; // integer with collateral token decimals
        } else {
            feeToReporter = feeClaim;
        }

        feeToExcessRecipient = feeClaim - feeToReporter; // integer with collateral token decimals

        // Transfer fee claim to reporter and excessFeeRecipient
        IDIVA.ArgsBatchTransferFeeClaim[]
            memory _feeClaimTransfers = new IDIVA.ArgsBatchTransferFeeClaim[](
                2
            );
        _feeClaimTransfers[0] = IDIVA.ArgsBatchTransferFeeClaim(
            _reporter,
            _params.collateralToken,
            feeToReporter
        );
        _feeClaimTransfers[1] = IDIVA.ArgsBatchTransferFeeClaim(
            _excessFeeRecipient,
            _params.collateralToken,
            feeToExcessRecipient
        );
        _diva.batchTransferFeeClaim(_feeClaimTransfers);

        emit FinalReferenceValueSet(
            _poolId,
            _formattedFinalReferenceValue,
            _params.expiryTime,
            _timestampRetrieved
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity 0.8.9;

import "./interfaces/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor internal tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(
            _queryId,
            _count - 1
        );
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = tellor.retrieveData(_queryId, _time);
        //If value is diputed it'll return zero
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = tellor.getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get imeadiate next value
                    uint256 _nextTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't found a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        ITellor _governance = ITellor(
            tellor.addresses(
                keccak256(abi.encodePacked("_GOVERNANCE_CONTRACT"))
            )
        );
        return
            _governance
                .getVoteRounds(
                    keccak256(abi.encodePacked(_queryId, _timestamp))
                )
                .length > 0;
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDIVAOracleTellor {
    // Thrown if user tries to claim fees/tips for a pool that was not yet confirmed
    error NotConfirmedPool();

    // Thrown if user tries to add a tip for an already confirmed pool
    error AlreadyConfirmedPool();

    // Thrown if the zero address is passed as input into `setExcessFeeRecipient`
    error ZeroExcessFeeRecipient();

    // Thrown if `_minPeriodUndisputed` passed into `setMinPeriodUndisputed` is
    // not within the expected range (min 1h, max 18h)
    error OutOfRange();

    // Thrown when user calls `setFinalReferenceValue` (or a variant of it) but
    // there is no data sitting in the Tellor contract
    error NoOracleSubmission();

    // Thrown if a value was reported to the Tellor contract but it was before
    // the expiry time of the underlying pool
    error NoOracleSubmissionAfterExpiryTime();

    // Thrown if user tries to call `setFinalReferenceValue` (or a variant of it)
    // before the minimum period undisputed period has passed
    error MinPeriodUndisputedNotPassed();

    /**
     * @notice Emitted when the tip is added.
     * @param poolId The Id of an existing derivatives pool
     * @param tippingToken Address of tipping token
     * @param amount Tipping token amount
     * @param tipper Address of user who adds the tip
     */
    event TipAdded(
        uint256 poolId,
        address tippingToken,
        uint256 amount,
        address tipper
    );

    /**
     * @notice Emitted when the tip is claimed.
     * @param poolId The Id of an existing derivatives pool
     * @param recipient Address of the tip recipient
     * @param tippingToken Address of tipping token
     * @param amount Claimed tipping token amount
     */
    event TipClaimed(
        uint256 poolId,
        address recipient,
        address tippingToken,
        uint256 amount
    );

    /**
     * @notice Emitted when the final reference value is set.
     * @param poolId The Id of an existing derivatives pool
     * @param finalValue Tellor value (converted into 18 decimals)
     * @param expiryTime Unix timestamp in seconds of pool expiry date
     * @param timestamp Tellor value timestamp
     */
    event FinalReferenceValueSet(
        uint256 indexed poolId,
        uint256 finalValue,
        uint256 expiryTime,
        uint256 timestamp
    );

    /**
     * @dev Function to run a single tip
     * @param _poolId The unique identifier of the pool.
     * @param _amount amount to tip
     * @param _tippingToken tipping token address
     */
    function addTip(
        uint256 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external;

    /**
     * @dev Function to claim tips
     * @param _poolId The unique identifier of the pool.
     * @param _tippingTokens Array of tipping tokens to claim tip.
     */
    function claimTips(uint256 _poolId, address[] memory _tippingTokens)
        external;

    /**
     * @dev Function to claim fee from DIVA
     * @param _poolId The unique identifier of the pool.
     */
    function claimDIVAFee(uint256 _poolId) external;

    /**
     * @dev Function to claim tips from DIVAOracleTellor and claim fee
     * from DIVA
     * @param _poolId The unique identifier of the pool.
     * @param _tippingTokens Array of tipping tokens to claim tip.
     */
    function claimTipsAndDIVAFee(
        uint256 _poolId,
        address[] memory _tippingTokens
    ) external;

    /**
     * @dev Function to set the final reference value for a given `_poolId`.
     * @param _poolId The unique identifier of the pool.
     */
    function setFinalReferenceValue(uint256 _poolId) external;

    /**
     * @dev Function to set the final reference value and claim tips for a
     * given `_poolId` with given tipping tokens.
     * @param _poolId The unique identifier of the pool.
     * @param _tippingTokens Array of tipping tokens to claim tip.
     */
    function setFinalReferenceValueAndClaimTips(
        uint256 _poolId,
        address[] memory _tippingTokens
    ) external;

    /**
     * @dev Function to set the final reference value and claim DIVA fee
     * for a given `_poolId` with given tipping tokens.
     * @param _poolId The unique identifier of the pool.
     */
    function setFinalReferenceValueAndClaimDIVAFee(uint256 _poolId) external;

    /**
     * @dev Function to set the final reference value and claim tips and DIVA
     * fee for a given `_poolId` with given tipping tokens.
     * @param _poolId The unique identifier of the pool.
     * @param _tippingTokens Array of tipping tokens to claim tip.
     */
    function setFinalReferenceValueAndClaimTipsAndDIVAFee(
        uint256 _poolId,
        address[] memory _tippingTokens
    ) external;

    /**
     * @dev Function to update `_excessFeeRecipient`.
     * Only callable by contract owner.
     * @param _newExcessFeeRecipient New `_excessFeeRecipient`.
     */
    function setExcessFeeRecipient(address _newExcessFeeRecipient) external;

    /**
     * @dev Function to update `_minPeriodUndisputed` with minimum value of
     * 1 hour (3600 seconds) and maximum value of 18 hours (64800 seconds).
     * Only callable by contract owner.
     * @param _newMinPeriodUndisputed New `_minPeriodUndisputed` in seconds.
     */
    function setMinPeriodUndisputed(uint32 _newMinPeriodUndisputed) external;

    /**
     * @dev Function to update `_maxFeeAmountUSD`.
     * Only callable by contract owner.
     * @param _newMaxFeeAmountUSD New amount expressed as an integer with
     * 18 decimals.
     */
    function setMaxFeeAmountUSD(uint256 _newMaxFeeAmountUSD) external;

    /**
     * @dev Returns whether the oracle's data feed is challengeable or not.
     * Will return false in that implementation.
     */
    function challengeable() external view returns (bool);

    /**
     * @dev Returns the excess fee recipient address
     */
    function getExcessFeeRecipient() external view returns (address);

    /**
     * @dev Returns the minimum period (in seconds) a reported value has
     * to remain undisputed in order to be considered valid
     */
    function getMinPeriodUndisputed() external view returns (uint32);

    /**
     * @dev Returns the max fee amount usd value with 18 decimals
     */
    function getMaxFeeAmountUSD() external view returns (uint256);

    /**
     * @dev Returns the length of tipping tokens with the poolId
     * @param _poolId The unique identifier of the pool.
     */
    function getTippingTokens(uint256 _poolId)
        external
        view
        returns (address[] memory);

    /**
     * @dev Returns the tipping amount
     * @param _poolId The unique identifier of the pool.
     * @param _tippingToken Address of tipping token.
     */
    function getTip(uint256 _poolId, address _tippingToken)
        external
        view
        returns (uint256);

    /**
     * @dev Returns query id
     * @param _poolId The unique identifier of the pool.
     */
    function getQueryId(uint256 _poolId) external view returns (bytes32);

    /**
     * @dev Returns the reporter address. Note that it returns
     * the zero address if a value has been reported to the Tellor contract
     * but it hasn't been pulled into DIVA Protocol by calling
     * `setFinalReferenceValue` yet.
     * @param _poolId The unique identifier of the pool.
     */
    function getReporter(uint256 _poolId) external view returns (address);

    /**
     * @dev Returns the DIVA address that the oracle is linked to
     */
    function getDIVAAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Shortened version of the interface including required functions only
 */
interface IDIVA {
    // Struct for `batchTransferFeeClaim` function input
    struct ArgsBatchTransferFeeClaim {
        address recipient;
        address collateralToken;
        uint256 amount;
    }

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralBalance;
        uint256 finalReferenceValue;
        uint256 capacity;
        uint256 statusTimestamp;
        address shortToken;
        uint96 payoutShort; // max value: 1e18 <= 2^64
        address longToken;
        uint96 payoutLong; // max value: 1e18 <= 2^64
        address collateralToken;
        uint96 expiryTime;
        address dataProvider;
        Status statusFinalReferenceValue;
        string referenceAsset;
    }

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        address longRecipient;
        address shortRecipient;
        address permissionedERC721Token;
    }

    /**
     * @notice Function to submit the final reference value for a given pool Id.
     * @param _poolId The pool Id for which the final value is submitted.
     * @param _finalReferenceValue Proposed final value by the data provider
     * expressed as an integer with 18 decimals.
     * @param _allowChallenge Flag indicating whether the challenge functionality
     * is enabled or disabled for the submitted value. If 0, then the submitted
     * final value will be directly confirmed and position token holders can start
     * redeeming their position tokens. If 1, then position token holders can
     * challenge the submitted value. This flag was introduced to account for
     * decentralized oracle solutions like Uniswap v3 or Chainlink where a
     * dispute mechanism doesn't make sense.
     */
    function setFinalReferenceValue(
        uint256 _poolId,
        uint256 _finalReferenceValue,
        bool _allowChallenge
    ) external;

    /**
     * @notice Function to transfer fee claim from entitled address
     * to another address
     * @param _recipient Address of fee claim recipient
     * @param _collateralToken Collateral token address
     * @param _amount Amount (expressed as an integer with collateral token
     * decimals) to transfer to recipient
     */
    function transferFeeClaim(
        address _recipient,
        address _collateralToken,
        uint256 _amount
    ) external;

    /**
     * @notice Batch version of `transferFeeClaim`
     * @param _argsBatchTransferFeeClaim Struct array containing collateral tokens,
     * recipient addresses and amounts (expressed as an integer with collateral
     * token decimals)
     */
    function batchTransferFeeClaim(
        ArgsBatchTransferFeeClaim[] calldata _argsBatchTransferFeeClaim
    ) external;

    /**
     * @notice Function to claim allocated fee
     * @dev List of collateral token addresses has to be obtained off-chain
     * (e.g., from TheGraph)
     * @param _collateralToken Collateral token address
     * @param _recipient Fee recipient address
     */
    function claimFee(address _collateralToken, address _recipient) external;

    /**
     * @notice Function to issue long and short position tokens to
     * `longRecipient` and `shortRecipient` upon collateral deposit by `msg.sender`. 
     * Provided collateral is kept inside the contract until position tokens are 
     * redeemed by calling `redeemPositionToken` or `removeLiquidity`.
     * @dev Position token supply equals `collateralAmount` (minimum 1e6).
     * Position tokens have the same amount of decimals as the collateral token.
     * Only ERC20 tokens with 6 <= decimals <= 18 are accepted as collateral.
     * Tokens with flexible supply like Ampleforth should not be used. When
     * interest/yield bearing tokens are considered, only use tokens with a
     * constant balance mechanism such as Compound's cToken or the wrapped
     * version of Lido's staked ETH (wstETH).
     * ETH is not supported as collateral in v1. It has to be wrapped into WETH
       before deposit.
     * @param _poolParams Struct containing the pool specification:
     * - referenceAsset: The name of the reference asset (e.g., Tesla-USD or
         ETHGasPrice-GWEI).
     * - expiryTime: Expiration time of the position tokens expressed as a unix
         timestamp in seconds.
     * - floor: Value of underlying at or below which the short token will pay
         out the max amount and the long token zero. Expressed as an integer with
         18 decimals.
     * - inflection: Value of underlying at which the long token will payout
         out `gradient` and the short token `1-gradient`. Expressed as an
         integer with 18 decimals.
     * - cap: Value of underlying at or above which the long token will pay
         out the max amount and short token zero. Expressed as an integer with
         18 decimals.
     * - gradient: Long token payout at inflection. The short token payout at
         inflection is `1-gradient`. Expressed as an integer with collateral token
         decimals.
     * - collateralAmount: Collateral amount to be deposited into the pool to
         back the position tokens. Expressed as an integer with collateral token
         decimals.
     * - collateralToken: ERC20 collateral token address.
     * - dataProvider: Address that is supposed to report the final value of
         the reference asset.
     * - capacity: The maximum collateral amount that the pool can accept. Expressed
         as an integer with collateral token decimals.
     * - longRecipient: Address that shall receive the long position tokens. 
     *   Zero address is a valid input to enable conditional burn use cases.
     * - shortRecipient: Address that shall receive the short position tokens.
     *   Zero address is a valid input to enable conditional burn use cases.
     * - permissionedERC721Token: Address of ERC721 token that is allowed to transfer the
     *   position token. Zero address if position token is supposed to be permissionless.
     * @return poolId
     */
    function createContingentPool(PoolParams memory _poolParams)
        external
        returns (uint256);

    /**
     * @notice Returns the pool parameters for a given pool Id.
     * @param _poolId Id of the pool.
     * @return Pool struct.
     */
    function getPoolParameters(uint256 _poolId)
        external
        view
        returns (Pool memory);

    /**
     * @dev Returns the claims by collateral tokens for a given account.
     * @param _recipient Recipient address.
     * @param _collateralToken Collateral token address.
     * @return Array of Claim structs.
     */
    function getClaim(address _collateralToken, address _recipient)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.13 where SafeMath is no
 * longer required to handle overflows
 */

library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands
     * as fixed-point decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is
     * evaluated, so that product must be less than 2**256. As this is an
     * integer division, the internal division always rounds down. This helps
     * save on gas. Rounding is more expensive on gas.
     */
    function multiplyDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Divide by UNIT to remove the extra factor introduced by the product
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(
        uint256 x,
        uint256 y
    )
        internal
        pure
        returns (uint256)
    {
        // Reintroduce the UNIT factor that will be divided out by y
        return (x * UNIT) / y;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity 0.8.9;

interface ITellor {
    //Controller
    function addresses(bytes32) external view returns (address);

    function uints(bytes32) external view returns (uint256);

    function burn(uint256 _amount) external;

    function changeDeity(address _newDeity) external;

    function changeOwner(address _newOwner) external;

    function changeTellorContract(address _tContract) external;

    function changeControllerContract(address _newController) external;

    function changeGovernanceContract(address _newGovernance) external;

    function changeOracleContract(address _newOracle) external;

    function changeTreasuryContract(address _newTreasury) external;

    function changeUint(bytes32 _target, uint256 _amount) external;

    function migrate() external;

    function mint(address _reciever, uint256 _amount) external;

    function init() external;

    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);

    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);

    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);

    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);

    function getAddressVars(bytes32 _data) external view returns (address);

    function getUintVar(bytes32 _data) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function isMigrated(address _addy) external view returns (bool);

    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);

    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _amount)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function changeStakingStatus(address _reporter, uint256 _status) external;

    function slashReporter(address _reporter, address _disputer) external;

    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);

    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256);

    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _d,
            uint256 _t
        );

    function getNewValueCountbyQueryId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    //Governance
    enum VoteResult {
        FAILED,
        PASSED,
        INVALID
    }

    function setApprovedFunction(bytes4 _func, bool _val) external;

    function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

    function delegate(address _delegate) external;

    function delegateOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (address);

    function executeVote(uint256 _disputeId) external;

    function proposeVote(
        address _contract,
        bytes4 _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external;

    function tallyVotes(uint256 _disputeId) external;

    function updateMinDisputeFee() external;

    function verify() external pure returns (uint256);

    function vote(
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function voteFor(
        address[] calldata _addys,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function getDelegateInfo(address _holder)
        external
        view
        returns (address, uint256);

    function isFunctionApproved(bytes4 _func) external view returns (bool);

    function isApprovedGovernanceContract(address _contract)
        external
        returns (bool);

    function getVoteRounds(bytes32 _hash)
        external
        view
        returns (uint256[] memory);

    function getVoteCount() external view returns (uint256);

    function getVoteInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256[9] memory,
            bool[2] memory,
            VoteResult,
            bytes memory,
            bytes4,
            address[2] memory
        );

    function getDisputeInfo(uint256 _disputeId)
        external
        view
        returns (
            uint256,
            uint256,
            bytes memory,
            address
        );

    function getOpenDisputesOnId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function didVote(uint256 _disputeId, address _voter)
        external
        view
        returns (bool);

    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getReportingLock() external view returns (uint256);

    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address);

    function reportingLock() external view returns (uint256);

    function removeValue(bytes32 _queryId, uint256 _timestamp) external;

    function getReportsSubmittedByAddress(address _reporter)
        external
        view
        returns (uint256);

    function getTipsByUser(address _user) external view returns (uint256);

    function tipQuery(
        bytes32 _queryId,
        uint256 _tip,
        bytes memory _queryData
    ) external;

    function submitValue(
        bytes32 _queryId,
        bytes calldata _value,
        uint256 _nonce,
        bytes memory _queryData
    ) external;

    function burnTips() external;

    function changeReportingLock(uint256 _newReportingLock) external;

    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;

    function getReporterLastTimestamp(address _reporter)
        external
        view
        returns (uint256);

    function getTipsById(bytes32 _queryId) external view returns (uint256);

    function getTimeBasedReward() external view returns (uint256);

    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getCurrentReward(bytes32 _queryId)
        external
        view
        returns (uint256, uint256);

    function getCurrentValue(bytes32 _queryId)
        external
        view
        returns (bytes memory);

    function getTimeOfLastNewValue() external view returns (uint256);

    //Treasury
    function issueTreasury(
        uint256 _maxAmount,
        uint256 _rate,
        uint256 _duration
    ) external;

    function payTreasury(address _investor, uint256 _id) external;

    function buyTreasury(uint256 _id, uint256 _amount) external;

    function getTreasuryDetails(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getTreasuryFundsByUser(address _user)
        external
        view
        returns (uint256);

    function getTreasuryAccount(uint256 _id, address _investor)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );

    function getTreasuryCount() external view returns (uint256);

    function getTreasuryOwners(uint256 _id)
        external
        view
        returns (address[] memory);

    function wasPaid(uint256 _id, address _investor)
        external
        view
        returns (bool);

    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;

    function migrateFor(address _destination, uint256 _amount) external;

    function rescue51PercentAttack(address _tokenHolder) external;

    function rescueBrokenDataReporting() external;

    function rescueFailedUpdate() external;
}
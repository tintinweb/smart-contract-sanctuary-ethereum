// SPDX-License-Identifier: LGPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@euler-xyz/euler-interfaces/contracts/IEuler.sol";
import "./interfaces/IStreamPools.sol";
import "./Constants.sol";

/**
 * @title StreamPools
 */
contract StreamPools is IStreamPools, ReentrancyGuard, Constants {
    using SafeERC20 for IERC20Metadata;

    /*** Storage ***/

    /**
     * @notice Reference to Euler main proxy contract
     */
    address private immutable euler;

    /**
     * @notice Reference to Euler markets contract
     */
    address private immutable markets;

    /**
     * @notice Counter for new pool ids.
     */
    uint16 private nextId;

    /**
     * @notice The pool objects identifiable by ids.
     */
    mapping(uint16 => IStreamPools.Pool) private pools;

    /**
     * @notice Mapping pointing from pool id to recipient to recipient's stream object
     */
    mapping(uint16 => mapping(address => Stream)) private streams;

    /**
     * @notice Mapping pointing from pool id to recipient to recipient's stream scheduled update object
     */
    mapping(uint16 => mapping(address => StreamUpdate)) private updates;

    /**
     * @notice Internal mapping pointing from underlying to Euler eToken address
     */
    mapping(address => address) private eTokens;

    /*** Modifiers ***/

    modifier onlySender(uint16 poolId) {
        require(isSender(poolId), "only sender");
        _;
    }

    /**
     * @dev Throws if provided id does not point to a valid pool.
     */
    modifier poolExists(uint16 poolId) {
        require(pools[poolId].sender != address(0), "pool does not exist");
        _;
    }

    /**
     * @dev Throws if provided id and recipient do not point to a valid stream.
     */
    modifier streamExists(uint16 poolId, address recipient) {
        require(streams[poolId][recipient].startTime > 0, "stream does not exist");
        _;
    }

    /*** Contract Logic */

    constructor(address _euler) {
        euler = _euler;
        markets = IEuler(euler).moduleIdToProxy(2);
        nextId = 1;
    }

    /*** Public Functions ***/

    /**
     * @notice Creates a new pool object funded by `msg.sender`.
     * @param underlying The underlying ERC20 token used as value reference.
     * @param amount The amount to be deposited.
     * @return poolId The id of the newly created pool.
     */
    function createPool(address underlying, uint amount) 
        override 
        external  
        returns (uint16 poolId)
    {
        require(underlying != address(0), "underlying cannot be zero address");
        require(amount > 0, "deposit amount must be greater than zero");
        require(amount <= type(uint112).max, "deposit amount must be less than 112 bit max");
        
        address eToken = eTokens[underlying] != address(0) ? 
                            eTokens[underlying] :
                            IEulerMarkets(markets).underlyingToEToken(underlying);

        require(eToken != address(0), "underlying market on Euler not activated");

        IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Metadata(underlying).approve(euler, type(uint).max);
        IEulerEToken(eToken).deposit(0, amount);
        
        poolId = nextId;
        pools[poolId].sender = msg.sender;
        pools[poolId].eTBalance = uint112(IEulerEToken(eToken).convertUnderlyingToBalance(amount));
        pools[poolId].underlying = underlying;
        pools[poolId].scaler = uint112(10**IERC20Metadata(underlying).decimals());
        eTokens[underlying] = eToken;
        nextId++;

        emit PoolCreated(poolId, underlying, msg.sender, amount);
    }    

    function addRecipient(uint16 poolId, address recipient, uint112 ratePerSecond, uint64 startTime, uint64 stopTime, uint64 noticePeriod) 
        override 
        external
        poolExists(poolId)
        onlySender(poolId)
        returns (uint8 numberOfRecipients) 
    {
        require(recipient != address(0) &&
                recipient != msg.sender && 
                recipient != address(this),
                "recipient address invalid");        
        require(streams[poolId][recipient].underlyingRatePerSecond == 0, "recipient already added to this pool");
        require(ratePerSecond > 0, "rate must be greater than zero");
        require(startTime> 0, "start time must be greater than zero");
        require(stopTime > startTime, "stop time must be greater than start time");
        require(pools[poolId].recipients.length < MAX_RECIPIENTS_PER_POOL, "Max recipients reached");
    
        uint112 currentRatio = uint112(IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler));
        if(pools[poolId].recipients.length > 0) {
            (uint112 recipientsBalance, uint112 rate) = settlePoolView(poolId, currentRatio);
            
            uint112 scaler = pools[poolId].scaler;
            uint112 balance = pools[poolId].eTBalance;
            require(recipientsBalance <= balance, "pool balance violation");

            if(block.timestamp + COOL_OFF_PERIOD > startTime) {
                recipientsBalance += uint112(
                    (block.timestamp + COOL_OFF_PERIOD - startTime) *
                    ratePerSecond * currentRatio / scaler);
            }
            
            uint112 timeLeft = uint112(scaler * (balance - recipientsBalance) / rate);
            require(timeLeft >= COOL_OFF_PERIOD, "cool off period violation");            
        }
        
        address underlying = pools[poolId].underlying;
        pools[poolId].recipients.push(recipient);
        streams[poolId][recipient].underlyingRatePerSecond = ratePerSecond;
        streams[poolId][recipient].startTime = startTime;
        streams[poolId][recipient].stopTime = stopTime;
        streams[poolId][recipient].noticePeriod = noticePeriod;
        streams[poolId][recipient].eToURatio = currentRatio;

        numberOfRecipients = uint8(pools[poolId].recipients.length);
        emit RecipientAdded(poolId, recipient, underlying, 
                            ratePerSecond, startTime, stopTime, noticePeriod);
    }

    function scheduleUpdate(uint16 poolId, address recipient, uint8 action, uint112 parameter) 
        override
        external 
        poolExists(poolId)
        streamExists(poolId, recipient)
        onlySender(poolId)
    {        
        if(action == RAISE) {
            require(parameter > streams[poolId][recipient].underlyingRatePerSecond, 
                "raise: rate must be greater than current");
        } else if(action == EXTESION) {
            require(parameter <= type(uint64).max, "incorrect parameter");
            require(parameter > streams[poolId][recipient].stopTime, 
                "extension: stop time must be greater than current");
        } else if(action == CUT) {
            require(parameter < streams[poolId][recipient].underlyingRatePerSecond, 
                "cut: rate must be less than current");
        } else if(action == TERMINATION) {
            require(parameter <= type(uint64).max, "incorrect parameter");
            require(parameter < streams[poolId][recipient].stopTime, 
                "termination: stop time must be less than current");
        } else {
            revert("update action incorrect");
        }

        updates[poolId][recipient].action = action;
        updates[poolId][recipient].parameter = parameter;
        updates[poolId][recipient].timestamp = uint64(block.timestamp + streams[poolId][recipient].noticePeriod);

        emit StreamUpdateScheduled(poolId, recipient, action, parameter, updates[poolId][recipient].timestamp);
    }

    function executeUpdate(uint16 poolId, address recipient) 
        override 
        external
        poolExists(poolId)
        onlySender(poolId)
    {
        StreamUpdate memory update = updates[poolId][recipient];
        require(update.timestamp != 0, "update not scheduled");
        require(update.timestamp <= block.timestamp, "update too early");

        uint112 currentRatio = uint112(IEulerEToken(eTokens[pools[poolId].underlying])
                                .convertUnderlyingToBalance(pools[poolId].scaler));
        
        settleRecipient(poolId, recipient, currentRatio);

        if(update.action == RAISE || update.action == CUT) {
            streams[poolId][recipient].underlyingRatePerSecond = updates[poolId][recipient].parameter;
            streams[poolId][recipient].eToURatio = currentRatio;
        } else if(update.action == EXTESION || update.action == TERMINATION){
            streams[poolId][recipient].stopTime = uint64(updates[poolId][recipient].parameter);

            if(streams[poolId][recipient].stopTime < streams[poolId][recipient].startTime) {
                streams[poolId][recipient].startTime = streams[poolId][recipient].stopTime;
            }
        } else {
            revert("unrecognized update action");
        }

        delete updates[poolId][recipient];
        emit StreamUpdateExecuted(poolId, recipient, update.action, update.parameter, uint64(block.timestamp));
    }

    function withdraw(uint16 poolId, uint amount) 
        override
        external
        nonReentrant
        poolExists(poolId)
    {
        address underlying = pools[poolId].underlying;
        address eToken = eTokens[underlying];
        uint112 currentRatio = uint112(IEulerEToken(eToken).convertUnderlyingToBalance(pools[poolId].scaler));
        uint112 eTAmount;

        if(pools[poolId].sender == msg.sender) {
            (uint112 recipientsBalance, uint112 rate) = settlePool(poolId, currentRatio);
            uint112 requiredBalance = uint112(recipientsBalance + rate * COOL_OFF_PERIOD / pools[poolId].scaler);

            require(pools[poolId].eTBalance >= requiredBalance, "insufficient balance /1");

            if(amount == type(uint).max) {
                eTAmount = pools[poolId].eTBalance - requiredBalance;
                amount = eTAmount * pools[poolId].scaler / currentRatio;
            } else {
                eTAmount = uint112(amount * currentRatio / pools[poolId].scaler);

                require(pools[poolId].eTBalance - eTAmount >= requiredBalance, "insufficient balance /2");
            }
        } else {
            require(streams[poolId][msg.sender].startTime > 0, "stream does not exist");

            (uint112 balance,) = settleRecipient(poolId, msg.sender, currentRatio);
            
            if(amount == type(uint).max) {
                eTAmount = balance;
                amount = eTAmount * pools[poolId].scaler / currentRatio;

                if(streams[poolId][msg.sender].startTime == streams[poolId][msg.sender].stopTime) {
                    delete streams[poolId][msg.sender];

                    for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
                        if(msg.sender == pools[poolId].recipients[i]) {
                            delete pools[poolId].recipients[i];
                            emit RecipientRemoved(poolId, msg.sender, underlying);
                            break;
                        }
                    }
                } else {
                    streams[poolId][msg.sender].settledBalance -= eTAmount;
                }
            } else {
                eTAmount = uint112(amount * currentRatio / pools[poolId].scaler);

                require(balance >= eTAmount, "insufficient balance /3");
                streams[poolId][msg.sender].settledBalance -= eTAmount;
            }

            require(pools[poolId].eTBalance >= eTAmount, "insufficient balance /4");
        }

        pools[poolId].eTBalance -= eTAmount;
        IEulerEToken(eToken).withdraw(0, amount);
        amount = IERC20Metadata(underlying).balanceOf(address(this));
        IERC20Metadata(underlying).safeTransfer(msg.sender, amount);
        emit Withdrawal(poolId, underlying, msg.sender, amount);
    }

    function deposit(uint16 poolId, uint amount) 
        override
        external
        poolExists(poolId)
        onlySender(poolId)
    {
        require(amount > 0, "deposit amount must be greater than zero");
        require(amount <= type(uint112).max, "deposit amount must be less than 112 bit max");
        
        address underlying = pools[poolId].underlying;
        address eToken = eTokens[underlying];
        uint112 currentRatio = uint112(IEulerEToken(eToken).convertUnderlyingToBalance(pools[poolId].scaler));
        
        settlePool(poolId, currentRatio);
        IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amount);
        IEulerEToken(eToken).deposit(0, amount);
        
        pools[poolId].eTBalance += uint112(amount * currentRatio / pools[poolId].scaler);

        updateEToURatios(poolId, currentRatio);
        emit Deposit(poolId, underlying, amount);
    }

    function endAllStreams(uint16 poolId) 
        override
        external
        poolExists(poolId)
    {
        uint112 currentRatio = uint112(IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler));
        (uint112 recipientsBalance,) = settlePool(poolId, currentRatio);

        require(recipientsBalance >= pools[poolId].eTBalance, "the pool is still solvent");   

        for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
            address recipient = pools[poolId].recipients[i];
            if(streams[poolId][recipient].startTime != streams[poolId][recipient].stopTime) {
                streams[poolId][recipient].startTime = streams[poolId][recipient].stopTime = uint64(block.timestamp);
            }
        }
    }


    /*** View Functions ***/

    function getPool(uint16 poolId) 
        override 
        external
        view 
        poolExists(poolId)
        returns (Pool memory pool) 
    {
        uint112 currentRatio = uint112(IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler));
        (uint112 recipientsBalance,) = settlePoolView(poolId, currentRatio);

        pool = pools[poolId];
        pool.eTBalance = (pool.eTBalance > recipientsBalance) ? pool.eTBalance - recipientsBalance : 0;
    }

    function getStream(uint16 poolId, address recipient) 
        override 
        external 
        view 
        poolExists(poolId)
        streamExists(poolId, recipient)
        returns (Stream memory stream) 
    {
        uint112 currentRatio = uint112(IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler));
        (uint112 balance, uint112 rate) = settleRecipientView(poolId, recipient, currentRatio);

        stream = streams[poolId][recipient];
        
        if(rate == 0 && block.timestamp > stream.startTime) {
            stream.stopTime = uint64(block.timestamp);
        }

        stream.startTime = uint64(block.timestamp);
        stream.settledBalance = balance;
        stream.eToURatio = currentRatio;
    }

    function getStreamUpdate(uint16 poolId, address recipient) 
        override 
        external 
        view 
        returns (StreamUpdate memory update)
    {
        update = updates[poolId][recipient];
        require(update.timestamp != 0, "update not scheduled");
    }
    
    function isSolvent(uint16 poolId)
        override
        external
        view
        poolExists(poolId)
        returns (bool solvent, uint64 howLong)
    {
        uint currentRatio = IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler);
        (uint112 recipientsBalance, uint112 rate) = settlePoolView(poolId, uint112(currentRatio));

        if(recipientsBalance > pools[poolId].eTBalance) {
            return (false, 0);
        } else {
            uint112 remaining = pools[poolId].eTBalance - recipientsBalance;
            howLong = rate == 0 ? type(uint64).max : uint64(pools[poolId].scaler * remaining / rate);
            return (true, howLong);
        }
    }

    function balanceOf(uint16 poolId, address account) 
        override 
        external
        view
        poolExists(poolId)
        returns (uint)
    {
        uint currentRatio = IEulerEToken(eTokens[pools[poolId].underlying]).convertUnderlyingToBalance(pools[poolId].scaler);
        
        uint112 balance;
        if(pools[poolId].sender == account) {
            (uint112 recipientsBalance,) = settlePoolView(poolId, uint112(currentRatio));
            balance = (pools[poolId].eTBalance >= recipientsBalance) ? pools[poolId].eTBalance - recipientsBalance : 0;
        } else {
            require(streams[poolId][account].startTime > 0, "stream does not exist");
            (uint112 recipientBalance,) = settleRecipientView(poolId, account, uint112(currentRatio));
            balance = (pools[poolId].eTBalance >= recipientBalance) ? recipientBalance : pools[poolId].eTBalance;
        }

        return balance; //* pools[poolId].scaler / currentRatio;
    }


    /*** Internal Functions ***/

    function isSender(uint16 poolId) 
        private 
        view 
        returns (bool) 
    {
        return msg.sender == pools[poolId].sender;
    }

    function isRecipient(uint16 poolId) 
        private 
        view 
        returns (bool result) 
    {
        result = false;
        for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
            if(msg.sender == pools[poolId].recipients[i]) {
                result = true;
                break;
            }
        }
    }

    function calcTime(uint64 start, uint64 stop) 
        private 
        view 
        returns (uint64 elapsed, bool expired) 
    {
        if(start == stop) {
            elapsed = 0;
            expired = true;
        } else if(block.timestamp <= start) {
            elapsed = 0;
            expired = false;
        } else if(block.timestamp >= stop) {
            elapsed = stop - start;
            expired = true;
        } else {
            elapsed = uint64(block.timestamp - start);
            expired = false;
        }
    }

    function settleRecipientView(uint16 poolId, address recipient, uint112 currentEToURatio) 
        internal 
        view 
        returns (uint112 balance, uint112 rate)
    {
        balance = streams[poolId][recipient].settledBalance;
        if(streams[poolId][recipient].startTime == streams[poolId][recipient].stopTime) {
            return (balance, 0);
        }

        (uint64 elapsed, bool expired) = calcTime(streams[poolId][recipient].startTime, streams[poolId][recipient].stopTime);
        uint112 underlyingRatePerSecond = streams[poolId][recipient].underlyingRatePerSecond;
        uint112 balanceDelta = uint112(elapsed * underlyingRatePerSecond);
        uint112 balanceDeltaAccrued = uint112(balanceDelta * streams[poolId][recipient].eToURatio / currentEToURatio);

        balance = uint112(balance + currentEToURatio * (balanceDelta + (balanceDeltaAccrued - balanceDelta) / 2) / pools[poolId].scaler);
        rate = expired ? 0 : streams[poolId][recipient].underlyingRatePerSecond * currentEToURatio;
    }

    function settleRecipient(uint16 poolId, address recipient, uint112 currentEToURatio) 
        internal 
        returns (uint112 balance, uint112 rate)
    {
        (balance, rate) = settleRecipientView(poolId, recipient, currentEToURatio);
        
        if(streams[poolId][recipient].startTime == streams[poolId][recipient].stopTime) {
            return (balance, 0);
        }

        if(rate == 0 && block.timestamp > streams[poolId][recipient].startTime) {
            streams[poolId][recipient].stopTime = uint64(block.timestamp);
        }
        
        streams[poolId][recipient].settledBalance = balance;
        streams[poolId][recipient].startTime = uint64(block.timestamp);
    }

    function settlePoolView(uint16 poolId, uint112 currentEToURatio)
        internal
        view 
        returns (uint112 balanceTotal, uint112 rateTotal) 
    {
        balanceTotal = 0;
        rateTotal = 0;
        for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
            (uint112 balance, uint112 rate) = settleRecipientView(poolId, pools[poolId].recipients[i], currentEToURatio);
            balanceTotal += balance;
            rateTotal += rate;
        }
    }

    function settlePool(uint16 poolId, uint112 currentEToURatio) 
        internal 
        returns (uint112 balanceTotal, uint112 rateTotal) 
    {
        balanceTotal = 0;
        rateTotal = 0;
        for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
            (uint112 balance, uint112 rate) = settleRecipient(poolId, pools[poolId].recipients[i], currentEToURatio);
            balanceTotal += balance;
            rateTotal += rate;
        }
    }

    function updateEToURatios(uint16 poolId, uint112 newRatio) 
        private
    {
      for(uint8 i=0; i<pools[poolId].recipients.length; ++i) {
            streams[poolId][pools[poolId].recipients[i]].eToURatio = newRatio;
        }
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
pragma solidity >=0.5.0;
pragma abicoder v2;


/// @notice Main storage contract for the Euler system
interface IEuler {
    /// @notice Lookup the current implementation contract for a module
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__ETOKEN)
    /// @return An internal address specifies the module's implementation code
    function moduleIdToImplementation(uint moduleId) external view returns (address);

    /// @notice Lookup a proxy that can be used to interact with a module (only valid for single-proxy modules)
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__MARKETS)
    /// @return An address that should be cast to the appropriate module interface, ie IEulerMarkets(moduleIdToProxy(2))
    function moduleIdToProxy(uint moduleId) external view returns (address);

    /// @notice Euler-related configuration for an asset
    struct AssetConfig {
        address eTokenAddress;
        bool borrowIsolated;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
    }
}


/// @notice Activating and querying markets, and maintaining entered markets lists
interface IEulerMarkets {
    /// @notice Create an Euler pool and associated EToken and DToken addresses.
    /// @param underlying The address of an ERC20-compliant token. There must be an initialised uniswap3 pool for the underlying/reference asset pair.
    /// @return The created EToken, or the existing EToken if already activated.
    function activateMarket(address underlying) external returns (address);

    /// @notice Create a pToken and activate it on Euler. pTokens are protected wrappers around assets that prevent borrowing.
    /// @param underlying The address of an ERC20-compliant token. There must already be an activated market on Euler for this underlying, and it must have a non-zero collateral factor.
    /// @return The created pToken, or an existing one if already activated.
    function activatePToken(address underlying) external returns (address);

    /// @notice Given an underlying, lookup the associated EToken
    /// @param underlying Token address
    /// @return EToken address, or address(0) if not activated
    function underlyingToEToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated PToken
    /// @param underlying Token address
    /// @return PToken address, or address(0) if it doesn't exist
    function underlyingToPToken(address underlying) external view returns (address);

    /// @notice Looks up the Euler-related configuration for a token, and resolves all default-value placeholders to their currently configured values.
    /// @param underlying Token address
    /// @return Configuration struct
    function underlyingToAssetConfig(address underlying) external view returns (IEuler.AssetConfig memory);

    /// @notice Looks up the Euler-related configuration for a token, and returns it unresolved (with default-value placeholders)
    /// @param underlying Token address
    /// @return config Configuration struct
    function underlyingToAssetConfigUnresolved(address underlying) external view returns (IEuler.AssetConfig memory config);

    /// @notice Given an EToken address, looks up the associated underlying
    /// @param eToken EToken address
    /// @return underlying Token address
    function eTokenToUnderlying(address eToken) external view returns (address underlying);

    /// @notice Given an EToken address, looks up the associated DToken
    /// @param eToken EToken address
    /// @return dTokenAddr DToken address
    function eTokenToDToken(address eToken) external view returns (address dTokenAddr);

    /// @notice Looks up an asset's currently configured interest rate model
    /// @param underlying Token address
    /// @return Module ID that represents the interest rate model (IRM)
    function interestRateModel(address underlying) external view returns (uint);

    /// @notice Retrieves the current interest rate for an asset
    /// @param underlying Token address
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate(address underlying) external view returns (int96);

    /// @notice Retrieves the current interest rate accumulator for an asset
    /// @param underlying Token address
    /// @return An opaque accumulator that increases as interest is accrued
    function interestAccumulator(address underlying) external view returns (uint);

    /// @notice Retrieves the reserve fee in effect for an asset
    /// @param underlying Token address
    /// @return Amount of interest that is redirected to the reserves, as a fraction scaled by RESERVE_FEE_SCALE (4e9)
    function reserveFee(address underlying) external view returns (uint32);

    /// @notice Retrieves the pricing config for an asset
    /// @param underlying Token address
    /// @return pricingType (1=pegged, 2=uniswap3, 3=forwarded)
    /// @return pricingParameters If uniswap3 pricingType then this represents the uniswap pool fee used, otherwise unused
    /// @return pricingForwarded If forwarded pricingType then this is the address prices are forwarded to, otherwise address(0)
    function getPricingConfig(address underlying) external view returns (uint16 pricingType, uint32 pricingParameters, address pricingForwarded);

    /// @notice Retrieves the list of entered markets for an account (assets enabled for collateral or borrowing)
    /// @param account User account
    /// @return List of underlying token addresses
    function getEnteredMarkets(address account) external view returns (address[] memory);

    /// @notice Add an asset to the entered market list, or do nothing if already entered
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param newMarket Underlying token address
    function enterMarket(uint subAccountId, address newMarket) external;

    /// @notice Remove an asset from the entered market list, or do nothing if not already present
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param oldMarket Underlying token address
    function exitMarket(uint subAccountId, address oldMarket) external;
}


/// @notice Definition of callback method that deferLiquidityCheck will invoke on your contract
interface IDeferredLiquidityCheck {
    function onDeferredLiquidityCheck(bytes memory data) external;
}

/// @notice Batch executions, liquidity check deferrals, and interfaces to fetch prices and account liquidity
interface IEulerExec {
    /// @notice Liquidity status for an account, either in aggregate or for a particular asset
    struct LiquidityStatus {
        uint collateralValue;
        uint liabilityValue;
        uint numBorrows;
        bool borrowIsolated;
    }

    /// @notice Aggregate struct for reporting detailed (per-asset) liquidity for an account
    struct AssetLiquidity {
        address underlying;
        LiquidityStatus status;
    }

    /// @notice Single item in a batch request
    struct EulerBatchItem {
        bool allowError;
        address proxyAddr;
        bytes data;
    }

    /// @notice Single item in a batch response
    struct EulerBatchItemResponse {
        bool success;
        bytes result;
    }

    /// @notice Compute aggregate liquidity for an account
    /// @param account User address
    /// @return status Aggregate liquidity (sum of all entered assets)
    function liquidity(address account) external view returns (LiquidityStatus memory status);

    /// @notice Compute detailed liquidity for an account, broken down by asset
    /// @param account User address
    /// @return assets List of user's entered assets and each asset's corresponding liquidity
    function detailedLiquidity(address account) external view returns (AssetLiquidity[] memory assets);

    /// @notice Retrieve Euler's view of an asset's price
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    function getPrice(address underlying) external view returns (uint twap, uint twapPeriod);

    /// @notice Retrieve Euler's view of an asset's price, as well as the current marginal price on uniswap
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    /// @return currPrice The current marginal price on uniswap3 (informational: not used anywhere in the Euler protocol)
    function getPriceFull(address underlying) external view returns (uint twap, uint twapPeriod, uint currPrice);

    /// @notice Defer liquidity checking for an account, to perform rebalancing, flash loans, etc. msg.sender must implement IDeferredLiquidityCheck
    /// @param account The account to defer liquidity for. Usually address(this), although not always
    /// @param data Passed through to the onDeferredLiquidityCheck() callback, so contracts don't need to store transient data in storage
    function deferLiquidityCheck(address account, bytes memory data) external;

    /// @notice Execute several operations in a single transaction
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @return List of operation results
    function batchDispatch(EulerBatchItem[] calldata items, address[] calldata deferLiquidityChecks) external returns (EulerBatchItemResponse[] memory);

    /// @notice Results of a batchDispatch, but with extra information
    struct EulerBatchExtra {
        EulerBatchItemResponse[] responses;
        uint gasUsed;
        AssetLiquidity[][] liquidities;
    }

    /// @notice Call batchDispatch, but return extra information. Only intended to be used with callStatic.
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @param queryLiquidity List of user accounts to return detailed liquidity information for
    /// @return output Structure with extra information
    function batchDispatchExtra(EulerBatchItem[] calldata items, address[] calldata deferLiquidityChecks, address[] calldata queryLiquidity) external returns (EulerBatchExtra memory output);

    /// @notice Enable average liquidity tracking for your account. Operations will cost more gas, but you may get additional benefits when performing liquidations
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account. 
    /// @param delegate An address of another account that you would allow to use the benefits of your account's average liquidity (use the null address if you don't care about this). The other address must also reciprocally delegate to your account.
    /// @param onlyDelegate Set this flag to skip tracking average liquidity and only set the delegate.
    function trackAverageLiquidity(uint subAccountId, address delegate, bool onlyDelegate) external;

    /// @notice Disable average liquidity tracking for your account and remove delegate
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account
    function unTrackAverageLiquidity(uint subAccountId) external;

    /// @notice Retrieve the average liquidity for an account
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidity(address account) external returns (uint);

    /// @notice Retrieve the average liquidity for an account or a delegate account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidityWithDelegate(address account) external returns (uint);

    /// @notice Retrieve the account which delegates average liquidity for an account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity delegate account
    function getAverageLiquidityDelegateAccount(address account) external view returns (address);

    /// @notice Transfer underlying tokens from sender's wallet into the pToken wrapper. Allowance should be set for the euler address.
    /// @param underlying Token address
    /// @param amount The amount to wrap in underlying units
    function pTokenWrap(address underlying, uint amount) external;

    /// @notice Transfer underlying tokens from the pToken wrapper to the sender's wallet.
    /// @param underlying Token address
    /// @param amount The amount to unwrap in underlying units
    function pTokenUnWrap(address underlying, uint amount) external;

    /// @notice Apply EIP2612 signed permit on a target token from sender to euler contract
    /// @param token Token address
    /// @param value Allowance value
    /// @param deadline Permit expiry timestamp
    /// @param v secp256k1 signature v
    /// @param r secp256k1 signature r
    /// @param s secp256k1 signature s
    function usePermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// @notice Apply DAI like (allowed) signed permit on a target token from sender to euler contract
    /// @param token Token address
    /// @param nonce Sender nonce
    /// @param expiry Permit expiry timestamp
    /// @param allowed If true, set unlimited allowance, otherwise set zero allowance
    /// @param v secp256k1 signature v
    /// @param r secp256k1 signature r
    /// @param s secp256k1 signature s
    function usePermitAllowed(address token, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;

    /// @notice Apply allowance to tokens expecting the signature packed in a single bytes param
    /// @param token Token address
    /// @param value Allowance value
    /// @param deadline Permit expiry timestamp
    /// @param signature secp256k1 signature encoded as rsv
    function usePermitPacked(address token, uint256 value, uint256 deadline, bytes calldata signature) external;

    /// @notice Execute a staticcall to an arbitrary address with an arbitrary payload.
    /// @param contractAddress Address of the contract to call
    /// @param payload Encoded call payload
    /// @return result Encoded return data
    /// @dev Intended to be used in static-called batches, to e.g. provide detailed information about the impacts of the simulated operation.
    function doStaticCall(address contractAddress, bytes memory payload) external view returns (bytes memory);
}


/// @notice Tokenised representation of assets
interface IEulerEToken {
    /// @notice Pool name, ie "Euler Pool: DAI"
    function name() external view returns (string memory);

    /// @notice Pool symbol, ie "eDAI"
    function symbol() external view returns (string memory);

    /// @notice Decimals, always normalised to 18.
    function decimals() external pure returns (uint8);

    /// @notice Sum of all balances, in internal book-keeping units (non-increasing)
    function totalSupply() external view returns (uint);

    /// @notice Sum of all balances, in underlying units (increases as interest is earned)
    function totalSupplyUnderlying() external view returns (uint);

    /// @notice Balance of a particular account, in internal book-keeping units (non-increasing)
    function balanceOf(address account) external view returns (uint);

    /// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint);

    /// @notice Balance of the reserves, in internal book-keeping units (non-increasing)
    function reserveBalance() external view returns (uint);

    /// @notice Balance of the reserves, in underlying units (increases as interest is earned)
    function reserveBalanceUnderlying() external view returns (uint);

    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    /// @param balance eToken balance, in internal book-keeping units (18 decimals)
    /// @return Amount in underlying units, (same decimals as underlying token)
    function convertBalanceToUnderlying(uint balance) external view returns (uint);

    /// @notice Convert an underlying amount to an eToken balance, taking into account current exchange rate
    /// @param underlyingAmount Amount in underlying units (same decimals as underlying token)
    /// @return eToken balance, in internal book-keeping units (18 decimals)
    function convertUnderlyingToBalance(uint underlyingAmount) external view returns (uint);

    /// @notice Updates interest accumulator and totalBorrows, credits reserves, re-targets interest rate, and logs asset status
    function touch() external;

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint subAccountId, uint amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint subAccountId, uint amount) external;

    /// @notice Mint eTokens and a corresponding amount of dTokens ("self-borrow")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units
    function mint(uint subAccountId, uint amount) external;

    /// @notice Pay off dToken liability with eTokens ("self-repay")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 to repay the debt in full or up to the available underlying balance)
    function burn(uint subAccountId, uint amount) external;

    /// @notice Allow spender to access an amount of your eTokens in sub-account 0
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approve(address spender, uint amount) external returns (bool);

    /// @notice Allow spender to access an amount of your eTokens in a particular sub-account
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approveSubAccount(uint subAccountId, address spender, uint amount) external returns (bool);

    /// @notice Retrieve the current allowance
    /// @param holder Xor with the desired sub-account ID (if applicable)
    /// @param spender Trusted address
    function allowance(address holder, address spender) external view returns (uint);

    /// @notice Transfer eTokens to another address (from sub-account 0)
    /// @param to Xor with the desired sub-account ID (if applicable)
    /// @param amount In internal book-keeping units (as returned from balanceOf).
    function transfer(address to, uint amount) external returns (bool);

    /// @notice Transfer the full eToken balance of an address to another
    /// @param from This address must've approved the to address, or be a sub-account of msg.sender
    /// @param to Xor with the desired sub-account ID (if applicable)
    function transferFromMax(address from, address to) external returns (bool);

    /// @notice Transfer eTokens from one address to another
    /// @param from This address must've approved the to address, or be a sub-account of msg.sender
    /// @param to Xor with the desired sub-account ID (if applicable)
    /// @param amount In internal book-keeping units (as returned from balanceOf).
    function transferFrom(address from, address to, uint amount) external returns (bool);
}


/// @notice Tokenised representation of debts
interface IEulerDToken {
    /// @notice Debt token name, ie "Euler Debt: DAI"
    function name() external view returns (string memory);

    /// @notice Debt token symbol, ie "dDAI"
    function symbol() external view returns (string memory);

    /// @notice Decimals, always normalised to 18.
    function decimals() external pure returns (uint8);

    /// @notice Sum of all outstanding debts, in underlying units (increases as interest is accrued)
    function totalSupply() external view returns (uint);

    /// @notice Sum of all outstanding debts, in underlying units with extra precision (increases as interest is accrued)
    function totalSupplyExact() external view returns (uint);

    /// @notice Debt owed by a particular account, in underlying units
    function balanceOf(address account) external view returns (uint);

    /// @notice Debt owed by a particular account, in underlying units with extra precision
    function balanceOfExact(address account) external view returns (uint);

    /// @notice Transfer underlying tokens from the Euler pool to the sender, and increase sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for all available tokens)
    function borrow(uint subAccountId, uint amount) external;

    /// @notice Transfer underlying tokens from the sender to the Euler pool, and decrease sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full debt owed)
    function repay(uint subAccountId, uint amount) external;

    /// @notice Allow spender to send an amount of dTokens to a particular sub-account
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approveDebt(uint subAccountId, address spender, uint amount) external returns (bool);

    /// @notice Retrieve the current debt allowance
    /// @param holder Xor with the desired sub-account ID (if applicable)
    /// @param spender Trusted address
    function debtAllowance(address holder, address spender) external view returns (uint);

    /// @notice Transfer dTokens to another address (from sub-account 0)
    /// @param to Xor with the desired sub-account ID (if applicable)
    /// @param amount In underlying units. Use max uint256 for full balance.
    function transfer(address to, uint amount) external returns (bool);

    /// @notice Transfer dTokens from one address to another
    /// @param from Xor with the desired sub-account ID (if applicable)
    /// @param to This address must've approved the from address, or be a sub-account of msg.sender
    /// @param amount In underlying. Use max uint256 for full balance.
    function transferFrom(address from, address to, uint amount) external returns (bool);
}


/// @notice Liquidate users who are in collateral violation to protect lenders
interface IEulerLiquidation {
    /// @notice Information about a prospective liquidation opportunity
    struct LiquidationOpportunity {
        uint repay;
        uint yield;
        uint healthScore;
    
        // Only populated if repay > 0:
        uint baseDiscount;
        uint discount;
        uint conversionRate;
    }

    /// @notice Checks to see if a liquidation would be profitable, without actually doing anything
    /// @param liquidator Address that will initiate the liquidation
    /// @param violator Address that may be in collateral violation
    /// @param underlying Token that is to be repayed
    /// @param collateral Token that is to be seized
    /// @return liqOpp The details about the liquidation opportunity
    function checkLiquidation(address liquidator, address violator, address underlying, address collateral) external returns (LiquidationOpportunity memory liqOpp);

    /// @notice Attempts to perform a liquidation
    /// @param violator Address that may be in collateral violation
    /// @param underlying Token that is to be repayed
    /// @param collateral Token that is to be seized
    /// @param repay The amount of underlying DTokens to be transferred from violator to sender, in units of underlying
    /// @param minYield The minimum acceptable amount of collateral ETokens to be transferred from violator to sender, in units of collateral
    function liquidate(address violator, address underlying, address collateral, uint repay, uint minYield) external;
}


/// @notice Trading assets on Uniswap V3 and 1Inch V4 DEXs
interface IEulerSwap {
    /// @notice Params for Uniswap V3 exact input trade on a single pool
    /// @param subAccountIdIn subaccount id to trade from
    /// @param subAccountIdOut subaccount id to trade to
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param amountIn amount of token to sell
    /// @param amountOutMinimum minimum amount of bought token
    /// @param deadline trade must complete before this timestamp
    /// @param fee uniswap pool fee to use
    /// @param sqrtPriceLimitX96 maximum acceptable price
    struct SwapUniExactInputSingleParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        address underlyingIn;
        address underlyingOut;
        uint amountIn;
        uint amountOutMinimum;
        uint deadline;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Params for Uniswap V3 exact input trade routed through multiple pools
    /// @param subAccountIdIn subaccount id to trade from
    /// @param subAccountIdOut subaccount id to trade to
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param amountIn amount of token to sell
    /// @param amountOutMinimum minimum amount of bought token
    /// @param deadline trade must complete before this timestamp
    /// @param path list of pools to use for the trade
    struct SwapUniExactInputParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        uint amountIn;
        uint amountOutMinimum;
        uint deadline;
        bytes path; // list of pools to hop - constructed with uni SDK 
    }

    /// @notice Params for Uniswap V3 exact output trade on a single pool
    /// @param subAccountIdIn subaccount id to trade from
    /// @param subAccountIdOut subaccount id to trade to
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param amountOut amount of token to buy
    /// @param amountInMaximum maximum amount of sold token
    /// @param deadline trade must complete before this timestamp
    /// @param fee uniswap pool fee to use
    /// @param sqrtPriceLimitX96 maximum acceptable price
    struct SwapUniExactOutputSingleParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        address underlyingIn;
        address underlyingOut;
        uint amountOut;
        uint amountInMaximum;
        uint deadline;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Params for Uniswap V3 exact output trade routed through multiple pools
    /// @param subAccountIdIn subaccount id to trade from
    /// @param subAccountIdOut subaccount id to trade to
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param amountOut amount of token to buy
    /// @param amountInMaximum maximum amount of sold token
    /// @param deadline trade must complete before this timestamp
    /// @param path list of pools to use for the trade
    struct SwapUniExactOutputParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        uint amountOut;
        uint amountInMaximum;
        uint deadline;
        bytes path;
    }

    /// @notice Params for 1Inch trade
    /// @param subAccountIdIn subaccount id to trade from
    /// @param subAccountIdOut subaccount id to trade to
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param amount amount of token to sell
    /// @param amountOutMinimum minimum amount of bought token
    /// @param payload call data passed to 1Inch contract
    struct Swap1InchParams {
        uint subAccountIdIn;
        uint subAccountIdOut;
        address underlyingIn;
        address underlyingOut;
        uint amount;
        uint amountOutMinimum;
        bytes payload;
    }

    /// @notice Execute Uniswap V3 exact input trade on a single pool
    /// @param params struct defining trade parameters
    function swapUniExactInputSingle(SwapUniExactInputSingleParams memory params) external;

    /// @notice Execute Uniswap V3 exact input trade routed through multiple pools
    /// @param params struct defining trade parameters
    function swapUniExactInput(SwapUniExactInputParams memory params) external;

    /// @notice Execute Uniswap V3 exact output trade on a single pool
    /// @param params struct defining trade parameters
    function swapUniExactOutputSingle(SwapUniExactOutputSingleParams memory params) external;

    /// @notice Execute Uniswap V3 exact output trade routed through multiple pools
    /// @param params struct defining trade parameters
    function swapUniExactOutput(SwapUniExactOutputParams memory params) external;

    /// @notice Trade on Uniswap V3 single pool and repay debt with bought asset
    /// @param params struct defining trade parameters (amountOut is ignored)
    /// @param targetDebt amount of debt that is expected to remain after trade and repay (0 to repay full debt)
    function swapAndRepayUniSingle(SwapUniExactOutputSingleParams memory params, uint targetDebt) external;

    /// @notice Trade on Uniswap V3 through multiple pools pool and repay debt with bought asset
    /// @param params struct defining trade parameters (amountOut is ignored)
    /// @param targetDebt amount of debt that is expected to remain after trade and repay (0 to repay full debt)
    function swapAndRepayUni(SwapUniExactOutputParams memory params, uint targetDebt) external;

    /// @notice Execute 1Inch V4 trade
    /// @param params struct defining trade parameters
    function swap1Inch(Swap1InchParams memory params) external;
}


/// @notice Protected Tokens are simple wrappers for tokens, allowing you to use tokens as collateral without permitting borrowing
interface IEulerPToken {
    /// @notice PToken name, ie "Euler Protected DAI"
    function name() external view returns (string memory);

    /// @notice PToken symbol, ie "pDAI"
    function symbol() external view returns (string memory);

    /// @notice Number of decimals, which is same as the underlying's
    function decimals() external view returns (uint8);

    /// @notice Address of the underlying asset
    function underlying() external view returns (address);

    /// @notice Balance of an account's wrapped tokens
    function balanceOf(address who) external view returns (uint);

    /// @notice Sum of all wrapped token balances
    function totalSupply() external view returns (uint);

    /// @notice Retrieve the current allowance
    /// @param holder Address giving permission to access tokens
    /// @param spender Trusted address
    function allowance(address holder, address spender) external view returns (uint);

    /// @notice Transfer your own pTokens to another address
    /// @param recipient Recipient address
    /// @param amount Amount of wrapped token to transfer
    function transfer(address recipient, uint amount) external returns (bool);

    /// @notice Transfer pTokens from one address to another. The euler address is automatically granted approval.
    /// @param from This address must've approved the to address
    /// @param recipient Recipient address
    /// @param amount Amount to transfer
    function transferFrom(address from, address recipient, uint amount) external returns (bool);

    /// @notice Allow spender to access an amount of your pTokens. It is not necessary to approve the euler address.
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approve(address spender, uint amount) external returns (bool);

    /// @notice Convert underlying tokens to pTokens
    /// @param amount In underlying units (which are equivalent to pToken units)
    function wrap(uint amount) external;

    /// @notice Convert pTokens to underlying tokens
    /// @param amount In pToken units (which are equivalent to underlying units)
    function unwrap(uint amount) external;

    /// @notice Claim any surplus tokens held by the PToken contract. This should only be used by contracts.
    /// @param who Beneficiary to be credited for the surplus token amount
    function claimSurplus(address who) external;
}



interface IEulerEulDistributor {
    /// @notice Claim distributed tokens
    /// @param account Address that should receive tokens
    /// @param token Address of token being claimed (ie EUL)
    /// @param proof Merkle proof that validates this claim
    /// @param stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    function claim(address account, address token, uint claimable, bytes32[] calldata proof, address stake) external;
}



interface IEulerEulStakes {
    /// @notice Retrieve current amount staked
    /// @param account User address
    /// @param underlying Token staked upon
    /// @return Amount of EUL token staked
    function staked(address account, address underlying) external view returns (uint);

    /// @notice Staking operation item. Positive amount means to increase stake on this underlying, negative to decrease.
    struct StakeOp {
        address underlying;
        int amount;
    }

    /// @notice Modify stake of a series of underlyings. If the sum of all amounts is positive, then this amount of EUL will be transferred in from the sender's wallet. If negative, EUL will be transferred out to the sender's wallet.
    /// @param ops Array of operations to perform
    function stake(StakeOp[] memory ops) external;

    /// @notice Increase stake on an underlying, and transfer this stake to a beneficiary
    /// @param beneficiary Who is given credit for this staked EUL
    /// @param underlying The underlying token to be staked upon
    /// @param amount How much EUL to stake
    function stakeGift(address beneficiary, address underlying, uint amount) external;

    /// @notice Applies a permit() signature to EUL and then applies a sequence of staking operations
    /// @param ops Array of operations to perform
    /// @param value The value field of the permit message
    /// @param deadline The deadline field of the permit message
    /// @param v Signature field
    /// @param r Signature field
    /// @param s Signature field
    function stakePermit(StakeOp[] memory ops, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


library EulerAddrsMainnet {
    IEuler public constant euler = IEuler(0x27182842E098f60e3D576794A5bFFb0777E025d3);
    IEulerMarkets public constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);
    IEulerLiquidation public constant liquidation = IEulerLiquidation(0xf43ce1d09050BAfd6980dD43Cde2aB9F18C85b34);
    IEulerExec public constant exec = IEulerExec(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);
    IEulerSwap public constant swap = IEulerSwap(0x7123C8cBBD76c5C7fCC9f7150f23179bec0bA341);
}

library EulerAddrsRopsten {
    IEuler public constant euler = IEuler(0xfC3DD73e918b931be7DEfd0cc616508391bcc001);
    IEulerMarkets public constant markets = IEulerMarkets(0x60Ec84902908f5c8420331300055A63E6284F522);
    IEulerLiquidation public constant liquidation = IEulerLiquidation(0xf9773f2D869Bdbe0B6aC6D6fD7df82b82C998DC7);
    IEulerExec public constant exec = IEulerExec(0xF7B8611008Ed073Ef348FE130671688BBb20409d);
    IEulerSwap public constant swap = IEulerSwap(0x86ea9f57d81Bf0C69Ff71114522fB3f29230DbA6);
}

// SPDX-License-Identifier: LGPL
pragma solidity ^0.8.0;

/**
 * @title IStreamPools
 */
interface IStreamPools {
    struct Pool {
        address sender;
        address[] recipients;
        address underlying;
        uint112 eTBalance;
        uint112 scaler;
    }

    struct Stream {
        uint112 settledBalance;
        uint112 eToURatio;
        uint112 underlyingRatePerSecond;
        uint64 startTime;
        uint64 stopTime;
        uint64 noticePeriod;
    }

    struct StreamUpdate {
        uint8 action;
        uint112 parameter;
        uint64 timestamp;
    }

    /**
     * @notice Emits when a pool is successfully created.
     */
    event PoolCreated(
        uint16 indexed poolId,
        address indexed underlying,
        address indexed sender,
        uint amount
    );

    /**
     * @notice Emits when a recipient is successfully added to the pool.
     */
    event RecipientAdded(
        uint16 indexed poolId,
        address indexed recipient,
        address indexed underlying,
        uint112 ratePerSecond,
        uint64 startTime,
        uint64 stopTime,
        uint64 noticePeriod
    );

    /**
     * @notice Emits when a recipient is successfully removed from the pool.
     */
    event RecipientRemoved(
        uint16 indexed poolId,
        address indexed recipient,
        address indexed underlying
    );

    /**
     * @notice Emits when a stream update is successfully scheduled.
     */
    event StreamUpdateScheduled(
        uint16 indexed poolId,
        address indexed recipient,
        uint8 indexed action,
        uint112 parameter,
        uint64 timestamp
    );

    /**
     * @notice Emits when a stream update is successfully executed.
     */
    event StreamUpdateExecuted(
        uint16 indexed poolId,
        address indexed recipient,
        uint8 indexed action,
        uint112 parameter,
        uint64 timestamp
    );

    /**
     * @notice Emits when the recipient of a pool withdraws a portion or all their pro rata share of the pool.
     */
    event Withdrawal(uint16 indexed poolId, address indexed underlying, address indexed recipient, uint amount);

    event Deposit(uint16 indexed poolId, address indexed underlying, uint amount);


    function createPool(address underlying, uint amount) external returns (uint16 poolId);

    function addRecipient(uint16 poolId, address recipient, uint112 ratePerSecond, uint64 startTime, uint64 stopTime, uint64 noticePeriod) 
        external returns (uint8 numberOfRecipients);
    
    function scheduleUpdate(uint16 poolId, address recipient, uint8 action, uint112 parameter) external;

    function executeUpdate(uint16 poolId, address recipient) external;

    function getPool(uint16 poolId) external view returns (Pool memory pool);

    function getStream(uint16 poolId, address recipient) external view returns (Stream memory stream);

    function getStreamUpdate(uint16 poolId, address recipient) external view returns (StreamUpdate memory update);

    function isSolvent(uint16 poolId) external view returns (bool solvent, uint64 howLong);

    function balanceOf(uint16 poolId, address account) external view returns (uint balance);
    
    function withdraw(uint16 poolId, uint amount) external;

    function deposit(uint16 poolId, uint amount) external;

    function endAllStreams(uint16 poolId) external;
}

// SPDX-License-Identifier: LGPL
pragma solidity ^0.8.0;

abstract contract Constants {
    uint8 internal constant RAISE = 1;
    uint8 internal constant EXTESION = 2;
    uint8 internal constant CUT = 3;
    uint8 internal constant TERMINATION = 4;
    uint8 internal constant MAX_RECIPIENTS_PER_POOL = 10;
    uint64 internal constant A_MONTH = 30 * 24 * 60 * 60;
    uint64 internal constant COOL_OFF_PERIOD = A_MONTH;
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
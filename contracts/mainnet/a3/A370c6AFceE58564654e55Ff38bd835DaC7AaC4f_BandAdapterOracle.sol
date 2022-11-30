// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.8.16;

// Common Errors
error ZERO_AMOUNT();
error ZERO_ADDRESS();
error INPUT_ARRAY_MISMATCH();

// Oracle Errors
error TOO_LONG_DELAY(uint256 delayTime);
error NO_MAX_DELAY(address token);
error PRICE_OUTDATED(address token);
error NO_SYM_MAPPING(address token);

error OUT_OF_DEVIATION_CAP(uint256 deviation);
error EXCEED_SOURCE_LEN(uint256 length);
error NO_PRIMARY_SOURCE(address token);
error NO_VALID_SOURCE(address token);
error EXCEED_DEVIATION();

error TOO_LOW_MEAN(uint256 mean);
error NO_MEAN(address token);
error NO_STABLEPOOL(address token);

error PRICE_FAILED(address token);
error LIQ_THRESHOLD_TOO_HIGH(uint256 threshold);

error ORACLE_NOT_SUPPORT(address token);
error ORACLE_NOT_SUPPORT_LP(address lp);
error ORACLE_NOT_SUPPORT_WTOKEN(address wToken);
error ERC1155_NOT_WHITELISTED(address collToken);
error NO_ORACLE_ROUTE(address token);

// Spell
error NOT_BANK(address caller);
error REFUND_ETH_FAILED(uint256 balance);
error NOT_FROM_WETH(address from);
error LP_NOT_WHITELISTED(address lp);
error COL_NOT_WHITELISTED(uint256 poolId, address colToken);
error NOT_EXIST_STRATEGY(address spell, uint poolId);
error EXCEED_MAX_LIMIT(uint poolId);

// Ichi Spell
error INCORRECT_LP(address lpToken);
error INCORRECT_PID(uint256 pid);
error INCORRECT_COLTOKEN(address colToken);
error INCORRECT_UNDERLYING(address uToken);
error NOT_FROM_UNIV3(address sender);

// SafeBox
error BORROW_FAILED(uint256 amount);
error REPAY_FAILED(uint256 amount);
error LEND_FAILED(uint256 amount);
error REDEEM_FAILED(uint256 amount);

// Wrapper
error INVALID_TOKEN_ID(uint256 tokenId);
error BAD_PID(uint256 pid);
error BAD_REWARD_PER_SHARE(uint256 rewardPerShare);

// Bank
error FEE_TOO_HIGH(uint256 feeBps);
error NOT_UNDER_EXECUTION();
error BANK_NOT_LISTED(address token);
error BANK_ALREADY_LISTED();
error BANK_LIMIT();
error CTOKEN_ALREADY_ADDED();
error NOT_EOA(address from);
error LOCKED();
error NOT_FROM_SPELL(address from);
error NOT_FROM_OWNER(uint256 positionId, address sender);
error NOT_IN_EXEC();
error ANOTHER_COL_EXIST(address collToken);
error NOT_LIQUIDATABLE(uint256 positionId);
error BAD_POSITION(uint256 posId);
error BAD_COLLATERAL(uint256 positionId);
error INSUFFICIENT_COLLATERAL();
error SPELL_NOT_WHITELISTED(address spell);
error TOKEN_NOT_WHITELISTED(address token);
error REPAY_EXCEEDS_DEBT(uint256 repay, uint256 debt);
error LEND_NOT_ALLOWED();
error BORROW_NOT_ALLOWED();
error REPAY_NOT_ALLOWED();

// Config
error INVALID_FEE_DISTRIBUTION();
error NO_TREASURY_SET();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// @dev Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// @dev Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBaseOracle {
    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../BlueBerryErrors.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/band/IStdReference.sol';

contract BandAdapterOracle is IBaseOracle, Ownable {
    IStdReference public ref; // Standard reference

    mapping(address => string) public symbols; // Mapping from token to symbol string
    mapping(address => uint256) public maxDelayTimes; // Mapping from token address to max delay time

    event SetRef(address ref);
    event SetSymbol(address token, string symbol);
    event SetMaxDelayTime(address token, uint256 maxDelayTime);

    constructor(IStdReference _ref) {
        if (address(_ref) == address(0)) revert ZERO_ADDRESS();

        ref = _ref;
    }

    /// @dev Set standard reference source
    /// @param _ref Standard reference source
    function setRef(IStdReference _ref) external onlyOwner {
        if (address(_ref) == address(0)) revert ZERO_ADDRESS();
        ref = _ref;
        emit SetRef(address(_ref));
    }

    /// @dev Set token symbols
    /// @param tokens List of tokens
    /// @param syms List of string symbols
    function setSymbols(address[] memory tokens, string[] memory syms)
        external
        onlyOwner
    {
        if (syms.length != tokens.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < syms.length; idx++) {
            if (tokens[idx] == address(0)) revert ZERO_ADDRESS();

            symbols[tokens[idx]] = syms[idx];
            emit SetSymbol(tokens[idx], syms[idx]);
        }
    }

    /// @dev Set max delay time for each token
    /// @param tokens list of tokens to set max delay
    /// @param maxDelays list of max delay times to set to
    function setMaxDelayTimes(
        address[] calldata tokens,
        uint256[] calldata maxDelays
    ) external onlyOwner {
        if (tokens.length != maxDelays.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (maxDelays[idx] > 2 days) revert TOO_LONG_DELAY(maxDelays[idx]);
            if (tokens[idx] == address(0)) revert ZERO_ADDRESS();

            maxDelayTimes[tokens[idx]] = maxDelays[idx];
            emit SetMaxDelayTime(tokens[idx], maxDelays[idx]);
        }
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view override returns (uint256) {
        string memory sym = symbols[token];
        uint256 maxDelayTime = maxDelayTimes[token];
        if (bytes(sym).length == 0) revert NO_SYM_MAPPING(token);
        if (maxDelayTime == 0) revert NO_MAX_DELAY(token);

        IStdReference.ReferenceData memory data = ref.getReferenceData(
            sym,
            'USD'
        );
        if (
            data.lastUpdatedBase < block.timestamp - maxDelayTime ||
            data.lastUpdatedQuote < block.timestamp - maxDelayTime
        ) revert PRICE_OUTDATED(token);

        return data.rate;
    }
}
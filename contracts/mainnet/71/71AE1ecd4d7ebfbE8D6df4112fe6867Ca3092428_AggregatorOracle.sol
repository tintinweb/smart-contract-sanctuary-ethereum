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

contract AggregatorOracle is IBaseOracle, Ownable {
    event SetPrimarySources(
        address indexed token,
        uint256 maxPriceDeviation,
        IBaseOracle[] oracles
    );

    mapping(address => uint256) public primarySourceCount; // Mapping from token to number of sources
    /// @dev Mapping from token to (mapping from index to oracle source)
    mapping(address => mapping(uint256 => IBaseOracle)) public primarySources;
    /// @dev Mapping from token to max price deviation (multiplied by 1e18)
    mapping(address => uint256) public maxPriceDeviations;

    uint256 public constant MIN_PRICE_DEVIATION = 1e18; // min price deviation
    uint256 public constant MAX_PRICE_DEVIATION = 1.2e18; // max price deviation, 20%

    /// @dev Set oracle primary sources for the token
    /// @param token Token address to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e18) for token
    /// @param sources Oracle sources for the token
    function setPrimarySources(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] memory sources
    ) external onlyOwner {
        _setPrimarySources(token, maxPriceDeviation, sources);
    }

    /// @dev Set oracle primary sources for multiple tokens
    /// @param tokens List of token addresses to set oracle sources
    /// @param maxPriceDeviationList List of max price deviations (in 1e18) for tokens
    /// @param allSources List of oracle sources for tokens
    function setMultiPrimarySources(
        address[] memory tokens,
        uint256[] memory maxPriceDeviationList,
        IBaseOracle[][] memory allSources
    ) external onlyOwner {
        if (
            tokens.length != allSources.length ||
            tokens.length != maxPriceDeviationList.length
        ) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            _setPrimarySources(
                tokens[idx],
                maxPriceDeviationList[idx],
                allSources[idx]
            );
        }
    }

    /// @dev Set oracle primary sources for tokens
    /// @param token Token to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e18) for token
    /// @param sources Oracle sources for the token
    function _setPrimarySources(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] memory sources
    ) internal {
        if (token == address(0)) revert ZERO_ADDRESS();
        if (
            maxPriceDeviation < MIN_PRICE_DEVIATION ||
            maxPriceDeviation > MAX_PRICE_DEVIATION
        ) revert OUT_OF_DEVIATION_CAP(maxPriceDeviation);
        if (sources.length > 3) revert EXCEED_SOURCE_LEN(sources.length);

        primarySourceCount[token] = sources.length;
        maxPriceDeviations[token] = maxPriceDeviation;
        for (uint256 idx = 0; idx < sources.length; idx++) {
            if (address(sources[idx]) == address(0)) revert ZERO_ADDRESS();
            primarySources[token][idx] = sources[idx];
        }
        emit SetPrimarySources(token, maxPriceDeviation, sources);
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token Token to get price of
    /// NOTE: Support at most 3 oracle sources per token
    function getPrice(address token) public view override returns (uint256) {
        uint256 candidateSourceCount = primarySourceCount[token];
        if (candidateSourceCount == 0) revert NO_PRIMARY_SOURCE(token);
        uint256[] memory prices = new uint256[](candidateSourceCount);

        // Get valid oracle sources
        uint256 validSourceCount = 0;
        for (uint256 idx = 0; idx < candidateSourceCount; idx++) {
            try primarySources[token][idx].getPrice(token) returns (
                uint256 px
            ) {
                prices[validSourceCount++] = px;
            } catch {}
        }
        if (validSourceCount == 0) revert NO_VALID_SOURCE(token);
        for (uint256 i = 0; i < validSourceCount - 1; i++) {
            for (uint256 j = 0; j < validSourceCount - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }
        uint256 maxPriceDeviation = maxPriceDeviations[token];

        // Algo:
        // - 1 valid source --> return price
        // - 2 valid sources
        //     --> if the prices within deviation threshold, return average
        //     --> else revert
        // - 3 valid sources --> check deviation threshold of each pair
        //     --> if all within threshold, return median
        //     --> if one pair within threshold, return average of the pair
        //     --> if none, revert
        // - revert otherwise
        if (validSourceCount == 1) {
            return prices[0]; // if 1 valid source, return
        } else if (validSourceCount == 2) {
            if ((prices[1] * 1e18) / prices[0] > maxPriceDeviation)
                revert EXCEED_DEVIATION();
            return (prices[0] + prices[1]) / 2; // if 2 valid sources, return average
        } else {
            bool midMinOk = (prices[1] * 1e18) / prices[0] <= maxPriceDeviation;
            bool maxMidOk = (prices[2] * 1e18) / prices[1] <= maxPriceDeviation;
            if (midMinOk && maxMidOk) {
                return prices[1]; // if 3 valid sources, and each pair is within thresh, return median
            } else if (midMinOk) {
                return (prices[0] + prices[1]) / 2; // return average of pair within thresh
            } else if (maxMidOk) {
                return (prices[1] + prices[2]) / 2; // return average of pair within thresh
            } else {
                revert EXCEED_DEVIATION();
            }
        }
    }
}
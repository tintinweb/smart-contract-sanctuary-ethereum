// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '../interfaces/IOracle.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/IERC20Wrapper.sol';

contract ProxyOracle is IOracle, Ownable {
    struct TokenFactor {
        uint16 borrowFactor; // The borrow factor for this token, multiplied by 1e4.
        uint16 collateralFactor; // The collateral factor for this token, multiplied by 1e4.
        uint16 liqThreshold; // The liquidation threshold, multiplied by 1e4.
    }

    /// The governor sets oracle token factor for a token.
    event SetTokenFactor(address indexed token, TokenFactor tokenFactor);
    /// The governor unsets oracle token factor for a token.
    event UnsetTokenFactor(address indexed token);
    /// The governor sets token whitelist for an ERC1155 token.
    event SetWhitelist(address indexed token, bool ok);

    IBaseOracle public immutable source; // Main oracle source
    mapping(address => TokenFactor) public tokenFactors; // Mapping from token address to oracle info.
    mapping(address => bool) public whitelistedERC1155; // Mapping from token address to whitelist status

    /// @dev Create the contract and initialize the first governor.
    constructor(IBaseOracle _source) {
        source = _source;
    }

    /// @dev Set oracle token factors for the given list of token addresses.
    /// @param tokens List of tokens to set info
    /// @param _tokenFactors List of oracle token factors
    function setTokenFactors(
        address[] memory tokens,
        TokenFactor[] memory _tokenFactors
    ) external onlyOwner {
        require(tokens.length == _tokenFactors.length, 'inconsistent length');
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            require(
                _tokenFactors[idx].borrowFactor >= 10000,
                'borrow factor must be at least 100%'
            );
            require(
                _tokenFactors[idx].collateralFactor <= 10000,
                'collateral factor must be at most 100%'
            );
            tokenFactors[tokens[idx]] = _tokenFactors[idx];
            emit SetTokenFactor(tokens[idx], _tokenFactors[idx]);
        }
    }

    /// @dev Unset token factors for the given list of token addresses
    /// @param tokens List of tokens to unset info
    function unsetTokenFactors(address[] memory tokens) external onlyOwner {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            delete tokenFactors[tokens[idx]];
            emit UnsetTokenFactor(tokens[idx]);
        }
    }

    /// @dev Set whitelist status for the given list of token addresses.
    /// @param tokens List of tokens to set whitelist status
    /// @param ok Whitelist status
    function setWhitelistERC1155(address[] memory tokens, bool ok)
        external
        onlyOwner
    {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            whitelistedERC1155[tokens[idx]] = ok;
            emit SetWhitelist(tokens[idx], ok);
        }
    }

    /// @dev Return whether the oracle supports evaluating collateral value of the given token.
    /// @param token ERC1155 token address to check for support
    /// @param id ERC1155 token id to check for support
    function supportWrappedToken(address token, uint256 id)
        external
        view
        override
        returns (bool)
    {
        if (!whitelistedERC1155[token]) return false;
        address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
        return tokenFactors[tokenUnderlying].borrowFactor != 0;
    }

    /// @dev Return whether the ERC20 token is supported
    /// @param token The ERC20 token to check for support
    function support(address token) external view override returns (bool) {
        try source.getPrice(token) returns (uint256 px) {
            return px != 0 && tokenFactors[token].borrowFactor != 0;
        } catch {
            return false;
        }
    }

    /**
     * @dev Return the USD value of the given input for collateral purpose.
     * @param token ERC1155 token address to get collateral value
     * @param id ERC1155 token id to get collateral value
     * @param amount Token amount to get collateral value, based 1e18
     */
    function getCollateralValue(
        address token,
        uint256 id,
        uint256 amount
    ) external view override returns (uint256) {
        require(whitelistedERC1155[token], 'bad token');
        address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
        uint256 rateUnderlying = IERC20Wrapper(token).getUnderlyingRate(id);
        uint256 amountUnderlying = (amount * rateUnderlying) / 1e18;
        TokenFactor memory tokenFactor = tokenFactors[tokenUnderlying];
        require(tokenFactor.borrowFactor != 0, 'bad underlying collateral');
        uint256 underlyingValue = (source.getPrice(tokenUnderlying) *
            amountUnderlying) / 1e18;
        return (underlyingValue * tokenFactor.collateralFactor) / 10000;
    }

    /**
     * @dev Return the USD value of the given input for borrow purpose.
     * @param token ERC20 token address to get borrow value
     * @param amount ERC20 token amount to get borrow value
     */
    function getDebtValue(address token, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        TokenFactor memory tokenFactor = tokenFactors[token];
        require(tokenFactor.borrowFactor != 0, 'bad underlying borrow');
        uint256 decimals = IERC20Metadata(token).decimals();
        uint256 debtValue = (source.getPrice(token) * amount) / 10**decimals;
        return (debtValue * tokenFactor.borrowFactor) / 10000;
    }

    /**
     * @dev Return the USD value of isolated collateral.
     * @param token ERC20 token address to get collateral value
     * @param amount ERC20 token amount to get collateral value
     */
    function getUnderlyingValue(address token, uint256 amount)
        external
        view
        returns (uint256 collateralValue)
    {
        uint256 decimals = IERC20Metadata(token).decimals();
        collateralValue = (source.getPrice(token) * amount) / 10**decimals;
    }

    function getLiqThreshold(address token) external view returns (uint256) {
        return tokenFactors[token].liqThreshold;
    }
}

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

pragma solidity ^0.8.9;

interface IOracle {
    /// @dev Return whether the ERC-20 token is supported
    /// @param token The ERC-20 token to check for support
    function support(address token) external view returns (bool);

    /// @dev Return whether the oracle supports evaluating collateral value of the given address.
    /// @param token The ERC-1155 token to check the acceptence.
    /// @param id The token id to check the acceptance.
    function supportWrappedToken(address token, uint256 id)
        external
        view
        returns (bool);

    /**
     * @dev Return the USD value of the given input for collateral purpose.
     * @param token ERC1155 token address to get collateral value
     * @param id ERC1155 token id to get collateral value
     * @param amount Token amount to get collateral value, based 1e18
     */
    function getCollateralValue(
        address token,
        uint256 id,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Return the USD value of the given input for borrow purpose.
     * @param token ERC20 token address to get borrow value
     * @param amount ERC20 token amount to get borrow value
     */
    function getDebtValue(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Return the USD value of isolated collateral.
     * @param token ERC20 token address to get collateral value
     * @param amount ERC20 token amount to get collateral value
     */
    function getUnderlyingValue(address token, uint256 amount)
        external
        view
        returns (uint256);

    function getLiqThreshold(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBaseOracle {
    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20Wrapper {
    /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
    function getUnderlyingToken(uint256 id) external view returns (address);

    /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
    function getUnderlyingRate(uint256 id) external view returns (uint256);
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
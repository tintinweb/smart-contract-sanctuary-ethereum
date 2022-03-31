/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/adapters/RariFusePriceOracleAdapter.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity =0.8.11 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */

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

////// src/interfaces/IRariFusePriceOracle.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Rari Fuse Price Oracle Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IRariFusePriceOracle {
    /**
     * @notice Gets the price in ETH of `_token`
     * @param _token ERC20 token address
     * @return _price Price in 1e18 precision
     */
    function price(address _token) external view returns (uint256 _price);
}

////// src/interfaces/IRariFusePriceOracleAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IRariFusePriceOracle } from "./IRariFusePriceOracle.sol"; */

/**
 * @title Rari Fuse Price Oracle Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Adapter for Rari Fuse Price Oracle
 */
interface IRariFusePriceOracleAdapter {
    /// ███ Types ██████████████████████████████████████████████████████████████

    /**
     * @notice Oracle metadata
     * @param oracle The Rari Fuse oracle
     * @param decimals The token decimals
     */
    struct OracleMetadata {
        IRariFusePriceOracle oracle;
        uint8 decimals;
    }


    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when oracle data is updated
     * @param token The ERC20 address
     * @param metadata The oracle metadata
     */
    event OracleConfigured(
        address token,
        OracleMetadata metadata
    );


    /// ███ Errors █████████████████████████████████████████████████████████████

    /// @notice Error is raised when base or quote token oracle is not exists
    error OracleNotExists(address token);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Configure oracle for token
     * @param _token The ERC20 token
     * @param _rariFusePriceOracle Contract that conform IRariFusePriceOracle interface
     */
    function configure(
        address _token,
        address _rariFusePriceOracle
    ) external;


    /// ███ Read-only functions ████████████████████████████████████████████████

    /**
     * @notice Returns true if oracle for the `_token` is configured
     * @param _token The token address
     */
    function isConfigured(address _token) external view returns (bool);


    /// ███ Adapters ███████████████████████████████████████████████████████████

    /**
     * @notice Gets the price of `_token` in terms of ETH (1e18 precision)
     * @param _token Token address (e.g. gOHM)
     * @return _price Price in ETH (1e18 precision)
     */
    function price(address _token) external view returns (uint256 _price);

    /**
     * @notice Gets the price of `_base` in terms of `_quote`.
     *         For example gOHM/USDC will return current price of gOHM in USDC.
     *         (1e6 precision)
     * @param _base Base token address (e.g. gOHM/XXX)
     * @param _quote Quote token address (e.g. XXX/USDC)
     * @return _price Price in quote decimals precision (e.g. USDC is 1e6)
     */
    function price(
        address _base,
        address _quote
    ) external view returns (uint256 _price);

}

////// src/adapters/RariFusePriceOracleAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { IERC20Metadata } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */

/* import { IRariFusePriceOracleAdapter } from "../interfaces/IRariFusePriceOracleAdapter.sol"; */
/* import { IRariFusePriceOracle } from "../interfaces/IRariFusePriceOracle.sol"; */

/**
 * @title Rari Fuse Price Oracle Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Adapter for Rari Fuse Price Oracle
 */
contract RariFusePriceOracleAdapter is IRariFusePriceOracleAdapter, Ownable {
    /// ███ Storages ███████████████████████████████████████████████████████████

    /// @notice Map token to Rari Fuse Price oracle contract
    mapping(address => OracleMetadata) public oracles;


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function configure(address _token, address _rariFusePriceOracle) external onlyOwner {
        oracles[_token] = OracleMetadata({
            oracle: IRariFusePriceOracle(_rariFusePriceOracle),
            decimals: IERC20Metadata(_token).decimals()
        });
        emit OracleConfigured(_token, oracles[_token]);
    }


    /// ███ Read-only functions ████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function isConfigured(address _token) external view returns (bool) {
        if (oracles[_token].decimals == 0) return false;
        return true;
    }


    /// ███ Adapters ███████████████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function price(address _token) public view returns (uint256 _price) {
        if (oracles[_token].decimals == 0) revert OracleNotExists(_token);
        _price = oracles[_token].oracle.price(_token);
    }

    /// @inheritdoc IRariFusePriceOracleAdapter
    function price(address _base, address _quote) external view returns (uint256 _price) {
        uint256 basePriceInETH = price(_base);
        uint256 quotePriceInETH = price(_quote);
        uint256 priceInETH = (basePriceInETH * 1e18) / quotePriceInETH;
        _price = (priceInETH * (10**oracles[_quote].decimals)) / 1e18;
    }
}
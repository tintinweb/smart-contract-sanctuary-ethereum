/// SPDX-License-Identifier: MIT 
pragma solidity 0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *
 *  @title $pace Token Dispersion Contract.
 *  @dev This helps keep token contract code clean and easily read.
 *  @notice This serves as a dispersion tool during token launch.
 *  @author kaymo.eth
 *
 */

contract PaceDisperser is Ownable {
    IERC20 pace;

    address public treasury;
    address public communityWallet;

    /// Initial dispersion amounts
    uint256 private constant INITIAL_STAKING_REWARDS = 30_000_000 ether;
    uint256 private constant DEV_TEAM_LOCKED = 20_000_000 ether;
    uint256 private constant TREASURY_FUND = 20_000_000 ether;
    uint256 private constant TOKEN_PRESALE_FUND = 1_283_682 ether;
    uint256 private constant PERM_LOCKED_LIQUIDITY = 10_000_000 ether;
    uint256 private constant MARKETING_FUND = 16_716_318 ether;
    uint256 private constant COMMUNITY_AUXILIARY_ACCOUNT = 2_000_000 ether;

    bool public initialized;
    bool public presaleDispersed;

    error ArrayMismatch();
    error Dispersed();
    error Presale();
    error NotDispersed();
    error TooMuchPresale();

    constructor (address _treasury, address _communityWallet) {
        treasury = _treasury;
        communityWallet = _communityWallet;
    }
    
    function setPaceToken(address _pace) public onlyOwner {
        pace = IERC20(_pace);
    } 

    /**
     *  @dev Disperses the total supply to the appropriate addresses
     *  @notice This is a one time function, therefore it can only be called once.
     */
    function disperseInitialTokens() public onlyOwner {
        if (initialized) revert Dispersed();
        initialized = true;
        pace.transfer(_msgSender(), INITIAL_STAKING_REWARDS);
        pace.transfer(_msgSender(), DEV_TEAM_LOCKED);
        pace.transfer(_msgSender(), PERM_LOCKED_LIQUIDITY);
        pace.transfer(_msgSender(), MARKETING_FUND);
        pace.transfer(treasury, TREASURY_FUND);
        pace.transfer(communityWallet, COMMUNITY_AUXILIARY_ACCOUNT);
    }

    /**
     *  @dev Disperse presale tokens.
     *  @param accounts - Array of accounts to disperse to.
     *  @param amounts - Array which runs parallel with accounts; This is the respective amount alotted to the matching address.
     *  @notice This is a one time function, therefore it can only be called once.
     */
    function dispersePresaleTokens(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        if (presaleDispersed) revert Presale();
        presaleDispersed = true;
        _airdrop(accounts, amounts);
    }

    /**
     *  @notice Airdrop function is only callable from constructor. This is a one time function which runs upon contract deployment.
     *  @dev Supplied an array of addresses and an array of amounts, this iterates and mints the supplied amounts to each address.
     *  This is set to internal so it cannot be called by any entity other than this contract.
     */
    function _airdrop (address[] memory addresses, uint256[] memory amounts) internal {
        if (addresses.length != amounts.length) revert ArrayMismatch();
        if (!initialized) revert NotDispersed();
        uint total;

        for (uint i; i < addresses.length;) {
            pace.transfer(addresses[i], amounts[i]);
            total = total + amounts[i];
            unchecked {
                ++i;
            }
        }

        if (total > TOKEN_PRESALE_FUND) revert TooMuchPresale();
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
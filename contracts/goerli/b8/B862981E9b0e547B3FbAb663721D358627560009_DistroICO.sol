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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//custom error
error ICO_Already_Started();
error Input_Wallet_Zero();
error Cannot_Buy_Lessthan_One_Token();
error ICO_Not_Active();
error Already_Released();
error Softcap_Not_Reached();
error Softcap_Already_Reached();
error Hardcap_Reached();
error No_Token_Available();
error ICO_Not_Tradable();
error VestingPeriod_Not_Ended();
error All_Reserved_Token_Unlocked();
error End_Date_Not_Passed();
error No_Token_contract();
error Amounts_and_Token_Not_match();
error Use_Different_Token();
error Not_Released();
error Withdraw_Failed();
error ICO_TOKEN();
error No_Token_Own();

contract DistroICO is Ownable, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000;
    uint256 public constant VESTING_UNLOCK_AMOUNT = 50_000_000;
    uint256 public reservedSupply = 400_000_000;
    uint256 private availableSupply = 600_000_000;
    uint256 private hardCap = 105_000_000;
    uint256 private softCap = 300_000;
    uint256 private startDate;
    uint256 private endDate;
    uint256 public vesting_period;
    uint256 private tokenSold;
    uint256 private fundRaised;
    uint256 public tradePrice;

    address payable private reservedWallet;

    IERC20 private token;

    bool private isReleased;
    bool public isTradable;

    mapping(address => bool) public acceptableTokens;

    struct Investor {
        address investor;
        uint256 amount;
        address paymentToken;
    }

    Investor[] public investors;

    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function start(
        address payable _reserveWallet,
        address[] memory _acceptableTokens
    ) public onlyOwner {
        if (startDate != 0) revert ICO_Already_Started();
        if (_reserveWallet == address(0)) revert Input_Wallet_Zero();
        if (getToken() == IERC20(address(0))) revert No_Token_contract();
        startDate = block.timestamp;
        reservedWallet = _reserveWallet;
        endDate = block.timestamp + 600; // 3 months
        for (uint256 i = 0; i < _acceptableTokens.length; i++) {
            acceptableTokens[_acceptableTokens[i]] = true;
        }
        token.transferFrom(msg.sender, address(this), TOTAL_SUPPLY * 10 ** 18);
    }

    function buy(address _paymentToken, uint256 _amount) public {
        uint256 buyTokenAmount = _amount / getPrice();
        uint256 raisedAmount = getTotalRaisedAmount();
        if (!acceptableTokens[_paymentToken]) revert Use_Different_Token();
        if (startDate == 0 || block.timestamp > endDate)
            revert ICO_Not_Active();
        if (_paymentToken == address(0)) revert Input_Wallet_Zero();
        if (buyTokenAmount == 0) revert Cannot_Buy_Lessthan_One_Token();
        if (availableSupply < buyTokenAmount) revert No_Token_Available();
        if (raisedAmount >= hardCap) revert Hardcap_Reached();
        if (raisedAmount > softCap && isReleased) {
            IERC20(_paymentToken).transferFrom(
                msg.sender,
                reservedWallet,
                _amount
            );

            token.transfer(msg.sender, buyTokenAmount);
        } else {
            IERC20(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        investors.push(Investor(msg.sender, _amount, _paymentToken));
        availableSupply -= buyTokenAmount;
        tokenSold += buyTokenAmount;
        fundRaised += _amount;
    }

    function release(address[] memory _tokens) public onlyOwner {
        if (isReleased) revert Already_Released();
        if (tokenSold < softCap) revert Softcap_Not_Reached();
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            token_.transfer(msg.sender, token_.balanceOf(address(this)));
        }
        for (uint256 i = 0; i < investors.length; i++) {
            Investor memory investor = investors[i];
            token.transfer(investor.investor, investor.amount);
        }
        isReleased = true;
    }

    function refund() public onlyOwner {
        if (isReleased) revert Already_Released();
        if (tokenSold > softCap) revert Softcap_Already_Reached();
        if (block.timestamp < endDate) revert End_Date_Not_Passed();
        for (uint256 i = 0; i < investors.length; i++) {
            Investor memory investor = investors[i];
            IERC20(investor.paymentToken).transfer(
                investor.investor,
                investor.amount * getPrice()
            );
        }
    }

    function trade(
        address _paymentToken,
        uint256 _amountToTrade
    ) public nonReentrant {
        uint256 holdAmount = _amountToTrade / 10 ** 18;
        uint256 tradeAmount = holdAmount * tradePrice;
        if (!isTradable) revert ICO_Not_Tradable();
        if (token.balanceOf(msg.sender) < _amountToTrade) revert No_Token_Own();
        if (IERC20(_paymentToken).balanceOf(address(this)) < tradeAmount)
            revert Use_Different_Token();
        token.transferFrom(msg.sender, address(this), holdAmount * 10 ** 18);
        IERC20(_paymentToken).transfer(msg.sender, tradeAmount);
    }

    function startTrade(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _tradePrice
    ) public onlyOwner {
        isTradable = true;
        vesting_period = block.timestamp + 300;
        if (_tokens.length != _amounts.length)
            revert Amounts_and_Token_Not_match();
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).transferFrom(
                msg.sender,
                address(this),
                _amounts[i]
            );
        }
        tradePrice = _tradePrice;
    }

    function unlockReserveToken() public onlyOwner {
        if (!isTradable) revert ICO_Not_Tradable();
        if (block.timestamp < vesting_period) revert VestingPeriod_Not_Ended();
        if (VESTING_UNLOCK_AMOUNT > reservedSupply)
            revert All_Reserved_Token_Unlocked();
        vesting_period = block.timestamp + 300;
        reservedSupply -= VESTING_UNLOCK_AMOUNT;
        token.transfer(reservedWallet, VESTING_UNLOCK_AMOUNT * 10 ** 18);
    }

    function withdraw(address _token) public onlyOwner {
        if (!isReleased) revert Not_Released();
        if (IERC20(_token) == token) revert ICO_TOKEN();
        IERC20(_token).transfer(
            reservedWallet,
            IERC20(_token).balanceOf(address(this))
        );
        (bool success, ) = reservedWallet.call{value: address(this).balance}(
            ""
        );
        if (!success) revert Withdraw_Failed();
    }

    function getPrice() public view returns (uint256) {
        if (tokenSold < 100_000_000) {
            return 0.05 ether;
        } else if (tokenSold < 200_000_000) {
            return 0.10 ether;
        } else if (tokenSold < 300_000_000) {
            return 0.15 ether;
        } else if (tokenSold < 400_000_000) {
            return 0.20 ether;
        } else if (tokenSold < 500_000_000) {
            return 0.25 ether;
        } else {
            return 0.30 ether;
        }
    }

    function getTotalRaisedAmount() public view returns (uint256) {
        uint256 raisedAmount = fundRaised / 10 ** 18;
        return raisedAmount;
    }

    function getAvailableSupply() public view returns (uint256) {
        return availableSupply;
    }

    function getReserveWallet() public view returns (address) {
        return reservedWallet;
    }

    function getHardCap() public view returns (uint256) {
        return hardCap;
    }

    function getSoftCap() public view returns (uint256) {
        return softCap;
    }

    function getStartDate() public view returns (uint256) {
        return startDate;
    }

    function getEndDate() public view returns (uint256) {
        return endDate;
    }

    function getTokenSold() public view returns (uint256) {
        return tokenSold;
    }

    function getToken() public view returns (IERC20) {
        return token;
    }

    function getReleasedStatus() public view returns (bool) {
        return isReleased;
    }
}
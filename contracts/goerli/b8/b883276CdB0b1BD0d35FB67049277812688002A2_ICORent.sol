// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
                    .:^~~!!!!!~^:.
                .^7J5GBB#########BGPY7~.
             :75G#####BBGP5555PGBB#####B57:
           ~YB####GY?~^:.      ..:~7YG####B5!.
         ~P####GJ^.                  .^?P####P!
       :Y####P!.                        .~5####5:
      ^G###B7        .::::::::.            !G###G~             .:::::::::::.          .::::::::::::::.      .::::.       :::::.     :::::::::::::::.
     ^G###P:        7PBBBBBBBBG5J!:         :5###B~            ?#BBB#####BBG5!.       5#BBB#########B^      5#B##G~     :G###B^    :B######BB######!
    .P###G:        ~####BBBBB#####GJ:        .P###G:           5####GPPPG#####J      .G####GPPPPPPPP5.     :B######?    ~####G.    ^PPPPG#####PPPPP:
    7###B~         J###B^.:::^!JB###G~        ^B###?          .G####~    J####G.     ~####G.               !#######&5:  J####5          7&###P
    5###5         .G###Y        :5###B^        5###G.         ~####G:  .:Y###&Y      ?####BYYYYYYYY:       J#########G~ P####7          5&##&?
   .G###J         ~####!         :B###7        ?###B:         J#####GGGGB####5:      5#######&&&&&#:      .P####7J#####JB####^         .B####~
   .P###Y         J###G:         ~####7        J###B:         5####BGB####B?^       .B####7               :B###B: !B########G.         ~####B.
    Y#B#G.       .G###Y        .7B###P.        P###5         :B####~ .5####J        ~####B~               !####G.  :P&######Y          ?&###5
    ~##B#?       !####!       ?G###BY.        7####!         !####G.  :P###&Y.      J&############&!      Y&##&Y    .J#####&7          P&&&&?
     J###B!      J###G.       5####J         ~B###Y          !5YY5?    :Y5YY5~      ?5YYYY555555Y5Y:     .J5YY5~      !5555Y:         .Y5555^
     .Y###B7    .G###J        .J####?       7B###5.
      .J####5^  !####~          ?####Y.   ^5####Y.
        ~P###B5~Y###G.           !B###5:~YB###G!
         .7P####B###J             ~B###B####G?.
           .!YB#####~              ^G####B5!.
              .!J557                :?YJ!:

 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ICORent is Ownable {
    ///============= Custom errors =======================
    error ErrorSendingFunds(address user, uint256 amountUSD);
    error ErrorSoldOut(address user, uint256 amountUSD);
    error ErrorMinCap(address user, uint256 amountUSD);
    error ErrorGreaterThanSellLimit(address user, uint256 amountUSD);

    /// ============ Immutable storage ==================
    IERC20 private RENT;
    IERC20 private USD;

    ///=========== Mutable Storage ======================
    uint256 public purchasePrice;
    uint256 public amountToSell;
    uint256 public totalSold;
    uint256 public investorMinCap;

    bool public sellActivated;

    address public treasury;

    constructor() {
        USD = IERC20(0x644a2eF41962506d8a7B10f6f7ac7B5457E0C6DD);
        RENT = IERC20(0x97d3D125Bc61557E8E8E20A82EA21Bba1541616f);

        treasury = msg.sender;

        purchasePrice = 200e6;
        amountToSell = 2530e18;
        investorMinCap = 100e6;
    }

    /// ==================== Events ============================

    event BuyRENT(address indexed user, uint256 amountUSD, uint256 amounRENT);
    event SetPriceRENT(uint256 newPrice);
    event SetAmountToSell(uint256 newAmount);
    event SetMinCap(uint256 newMinCap);
    event SetTreasury(address newTreasury);

    function buyRENT(uint256 amountUSD) public {
        require(sellActivated, "Sell: the purchase is not active");

        uint256 amountRENTToBuy = (amountUSD * 1e18) / purchasePrice;

        if (amountUSD < investorMinCap) {
            revert ErrorMinCap(msg.sender, amountUSD);
        }

        if (amountRENTToBuy > amountToSell - totalSold) {
            revert ErrorGreaterThanSellLimit(msg.sender, amountUSD);
        }

        totalSold += amountRENTToBuy;

        emit BuyRENT(msg.sender, amountUSD, amountRENTToBuy);

        if (!USD.transferFrom(msg.sender, treasury, amountUSD)) {
            revert ErrorSendingFunds(msg.sender, amountUSD);
        }

        if(!RENT.transfer(msg.sender, amountRENTToBuy)) {
            revert ErrorSendingFunds(msg.sender, amountUSD);
        }

    }

    function pauseTheSale() external onlyOwner {
        sellActivated = false;
    }

    function unPauseTheSale() external onlyOwner {
        sellActivated = true;
    }

    function setPriceRENT(uint256 newPrice) external onlyOwner {
        purchasePrice = newPrice;
        emit SetPriceRENT(newPrice);
    }

    function setAmountToSell(uint256 newAmount) external onlyOwner {
        amountToSell = newAmount;
        emit SetAmountToSell(newAmount);
    }

    function setInvestorMinCap(uint256 newAmount) external onlyOwner {
        investorMinCap = newAmount;
        emit SetMinCap(newAmount);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Treasury: zero address");
        treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }

    function withdrawRENT() external onlyOwner {
        RENT.transfer(msg.sender, RENT.balanceOf(address(this)));
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
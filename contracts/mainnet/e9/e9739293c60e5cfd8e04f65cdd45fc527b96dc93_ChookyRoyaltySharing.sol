/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

/**
Contract Author: @ARRNAYA
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
     * by making the `nonReentrant` function external, and make it call a
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

contract ChookyRoyaltySharing is ReentrancyGuard, Ownable {
    IERC20 public ChookyInu;
    uint256 public TVL;

    uint256 public ChookySupply = 21_000_000 * 1e18;

    uint16 public tierIHolders;
    uint16 public tierIIHolders;
    uint16 public tierIIIHolders;
    uint16 public tierIVHolders;

    mapping(address => uint256) public lastClaimTime;
    uint256 public claimWaitTime = 14 days;

    struct Holder {
        uint256 id;
        int256 tier;
        uint256 userStakedBalance;
        uint256 stakeTime;
        uint256 royaltyClaimed;
        uint256 lastClaimTime;
    }

    mapping(address => Holder) public chookyHolders;

    struct RoyaltyShare {
        uint256 tierI;
        uint256 tierII;
        uint256 tierIII;
        uint256 tierIV;
    }

    RoyaltyShare public royalty = RoyaltyShare(40, 25, 20, 15);

    event RoyaltyClaimed(address indexed user, uint256 amount);
    event ChookyStaked(address indexed user, uint256 amount);
    event ChookyUnstaked(address indexed user, uint256 amount);
    event ETHTransferred(address indexed user, uint256 amount);
    event TokenWithdrawan(address indexed user, uint256 amount);

    constructor(address _ChookyInu) {
        _transferOwnership(payable(msg.sender));

        ChookyInu = IERC20(_ChookyInu);
    }

    // fallbacks
    receive() external payable {}

    function _stakeChookyForRoyalty(uint256 _amount) external nonReentrant {
        Holder storage holder = chookyHolders[msg.sender];
        require(
            ChookyInu.balanceOf(msg.sender) >= _amount,
            "Not enough Balance"
        );
        require(
            holder.userStakedBalance == 0,
            "Only new holders can lock using this option."
        );

        ChookyInu.transferFrom(msg.sender, address(this), _amount);
        holder.userStakedBalance += _amount;
        holder.stakeTime = block.timestamp;
        holder.lastClaimTime = block.timestamp;

        TVL += _amount;

        if (holder.userStakedBalance >= ChookySupply / 100) {
            holder.tier = 0;
            tierIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 100 &&
            holder.userStakedBalance >= ChookySupply / 125
        ) {
            holder.tier = 1;
            tierIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 125 &&
            holder.userStakedBalance >= ChookySupply / 200
        ) {
            holder.tier = 2;
            tierIIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 200 &&
            holder.userStakedBalance >= ChookySupply / 400
        ) {
            holder.tier = 3;
            tierIVHolders++;
        }

        emit ChookyStaked(msg.sender, _amount);
    }

    function _addMore(uint256 _amount) external nonReentrant {
        Holder storage holder = chookyHolders[msg.sender];
        require(
            ChookyInu.balanceOf(msg.sender) >= _amount,
            "Not enough Balance"
        );
        require(
            holder.userStakedBalance > 0,
            "Can only use this to add more to the existing locked balance!"
        );

        ChookyInu.transferFrom(msg.sender, address(this), _amount);

        if (holder.userStakedBalance >= ChookySupply / 100) {
            tierIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 100 &&
            holder.userStakedBalance >= ChookySupply / 125
        ) {
            tierIIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 125 &&
            holder.userStakedBalance >= ChookySupply / 200
        ) {
            tierIIIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 200 &&
            holder.userStakedBalance >= ChookySupply / 400
        ) {
            tierIVHolders--;
        }

        holder.userStakedBalance += _amount;
        holder.lastClaimTime = block.timestamp;

        TVL += _amount;

        if (holder.userStakedBalance >= ChookySupply / 100) {
            holder.tier = 0;
            tierIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 100 &&
            holder.userStakedBalance >= ChookySupply / 125
        ) {
            holder.tier = 1;
            tierIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 125 &&
            holder.userStakedBalance >= ChookySupply / 200
        ) {
            holder.tier = 2;
            tierIIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 200 &&
            holder.userStakedBalance >= ChookySupply / 400
        ) {
            holder.tier = 3;
            tierIVHolders++;
        } else {
            holder.tier = -1;
            holder.stakeTime = 0;
        }

        emit ChookyStaked(msg.sender, _amount);
    }

    function _unstakeChooky(uint256 _amount) external nonReentrant {
        Holder storage holder = chookyHolders[msg.sender];
        require(
            ChookyInu.balanceOf(address(this)) >= holder.userStakedBalance,
            "Not enough Balance"
        );
        require(
            _amount <= holder.userStakedBalance,
            "Can't withdraw more than what you locked!"
        );

        if (holder.userStakedBalance >= ChookySupply / 100) {
            tierIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 100 &&
            holder.userStakedBalance >= ChookySupply / 125
        ) {
            tierIIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 125 &&
            holder.userStakedBalance >= ChookySupply / 200
        ) {
            tierIIIHolders--;
        } else if (
            holder.userStakedBalance < ChookySupply / 200 &&
            holder.userStakedBalance >= ChookySupply / 400
        ) {
            tierIVHolders--;
        }

        holder.userStakedBalance -= _amount;

        if (holder.userStakedBalance >= ChookySupply / 100) {
            holder.tier = 0;
            tierIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 100 &&
            holder.userStakedBalance >= ChookySupply / 125
        ) {
            holder.tier = 1;
            tierIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 125 &&
            holder.userStakedBalance >= ChookySupply / 200
        ) {
            holder.tier = 2;
            tierIIIHolders++;
        } else if (
            holder.userStakedBalance < ChookySupply / 200 &&
            holder.userStakedBalance >= ChookySupply / 400
        ) {
            holder.tier = 3;
            tierIVHolders++;
        } else {
            holder.tier = -1;
            holder.stakeTime = 0;
        }

        TVL -= _amount;

        IERC20(ChookyInu).transfer(msg.sender, _amount);

        emit ChookyUnstaked(msg.sender, _amount);
    }

    function _claimRoyalty() external nonReentrant {
        Holder storage holder = chookyHolders[msg.sender];
        require(
            holder.userStakedBalance > 0,
            "You have not staked your Chooky Inu!"
        );
        require(holder.tier >= 0, "Hodler doesn't belong to a staked tier");
        require(
            block.timestamp >= holder.lastClaimTime + claimWaitTime,
            "Can't claim before two weeks of last claim!"
        );

        if (holder.tier == 0) {
            require(tierIHolders > 0, "Not enough holders!");
            uint256 claimAmountShare = (address(this).balance * royalty.tierI) /
                100;
            uint256 userAmount = claimAmountShare / tierIHolders;

            holder.lastClaimTime = block.timestamp;
            holder.royaltyClaimed += userAmount;

            payable(msg.sender).transfer(userAmount);
            emit RoyaltyClaimed(msg.sender, userAmount);
        } else if (holder.tier == 1) {
            require(tierIIHolders > 0, "Not enough holders!");
            uint256 claimAmountShare = (address(this).balance *
                royalty.tierII) / 100;
            uint256 userAmount = claimAmountShare / tierIIHolders;

            holder.lastClaimTime = block.timestamp;
            holder.royaltyClaimed += userAmount;

            payable(msg.sender).transfer(userAmount);
            emit RoyaltyClaimed(msg.sender, userAmount);
        } else if (holder.tier == 2) {
            require(tierIIIHolders > 0, "Not enough holders!");
            uint256 claimAmountShare = (address(this).balance *
                royalty.tierIII) / 100;
            uint256 userAmount = claimAmountShare / tierIIIHolders;

            holder.lastClaimTime = block.timestamp;
            holder.royaltyClaimed += userAmount;

            payable(msg.sender).transfer(userAmount);
            emit RoyaltyClaimed(msg.sender, userAmount);
        } else if (holder.tier == 3) {
            require(tierIVHolders > 0, "Not enough holders!");
            uint256 claimAmountShare = (address(this).balance *
                royalty.tierIV) / 100;
            uint256 userAmount = claimAmountShare / tierIVHolders;

            holder.lastClaimTime = block.timestamp;
            holder.royaltyClaimed += userAmount;

            payable(msg.sender).transfer(userAmount);
            emit RoyaltyClaimed(msg.sender, userAmount);
        }
    }

    function _tierBalances()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tierIBalance = (address(this).balance * royalty.tierI) / 100;
        uint256 tierIIBalance = (address(this).balance * royalty.tierII) / 100;
        uint256 tierIIIBalance = (address(this).balance * royalty.tierIII) /
            100;
        uint256 tierIVBalance = (address(this).balance * royalty.tierIV) / 100;

        return (tierIBalance, tierIIBalance, tierIIIBalance, tierIVBalance);
    }

    function _setChooky(IERC20 _ChookyInu) public onlyOwner {
        ChookyInu = IERC20(_ChookyInu);
    }

    function _updateRoyaltyShare(
        uint256 _tierI,
        uint256 _tierII,
        uint256 _tierIII,
        uint256 _tierIV
    ) external onlyOwner {
        royalty = RoyaltyShare(_tierI, _tierII, _tierIII, _tierIV);
        require(
            (_tierI + _tierII + _tierIII + _tierIV) == 100,
            "Must be equal to 100"
        );
    }

    function _updateClaimWaitTime(uint256 _newWaitTime) external onlyOwner {
        require(_newWaitTime > 0, "Can't set the value to 0");
        claimWaitTime = _newWaitTime;
    }

    function _recoverETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        emit ETHTransferred(msg.sender, address(this).balance);
    }

    function _withdrawOtherTokens(address _token, uint256 amount)
        public
        onlyOwner
    {
        if (IERC20(_token) == IERC20(ChookyInu)) {
            require(
                ChookyInu.balanceOf(address(this)) > TVL,
                "Not enough Balance"
            );

            uint256 withdrawableAmt = ChookyInu.balanceOf(address(this)) - TVL;
            IERC20(ChookyInu).transfer(payable(msg.sender), withdrawableAmt);
        } else {
            IERC20(_token).transfer(payable(msg.sender), amount);
        }

        emit TokenWithdrawan(msg.sender, amount);
    }
}
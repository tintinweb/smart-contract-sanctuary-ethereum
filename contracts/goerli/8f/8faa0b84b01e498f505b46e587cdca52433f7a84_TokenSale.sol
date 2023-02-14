/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/TokenSale.sol



pragma solidity ^0.8.0;




contract TokenSale is Ownable {
    uint public rateStage1BNB; // amount of tokens to recieve per unit of bnb
    uint public rateStage2BNB;
    uint public rateStage3BNB;

    uint public rateStage1Stablecoin; // amount of tokens to recieve per stablecoin
    uint public rateStage2Stablecoin;
    uint public rateStage3Stablecoin;

    uint public totalSold;
    uint public unlockStartTimestamp;

    uint public tokenLimitStageOne = 1000000e18;
    uint public tokenLimitStageTwo = 2000000e18;
    uint public tokenLimitStageThree = 3000000e18;
    // In this case, max tokens to be sold = 1 million + 2 million + 3 million = 6 million
    uint public minPurchaseAmount = 10e18;
    uint public maxPurchaseAmount = 1000000e18; // max amount of tokens that can be purchased by an address

    uint public constant STAGE_ONE_LOCK_TIME = 16 minutes; // 2 YEARS
    uint public constant STAGE_TWO_LOCK_TIME = 8 minutes; // 1 YEAR
    uint public constant STAGE_THREE_LOCK_TIME = 4 minutes; // 6 MONTHS

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; // BSC mainnet addresses
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IERC20 public token;

    struct Purchase {
        uint amount;
        uint remaining;
        uint payouts;
        uint nextVestingTime;
    }

    mapping(address => Purchase) public stageOnePurchases;
    mapping(address => Purchase) public stageTwoPurchases;
    mapping(address => Purchase) public stageThreePurchases;

    event Purchased(address account, uint amount, uint purchaseTime);
    event Claimed(address account, uint amount, uint stage);

    constructor(address _token, uint _rate1BNB, uint _rate2BNB, uint _rate3BNB, uint _rate1Stablecoin, uint _rate2Stablecoin, uint _rate3Stablecoin) {
        token = IERC20(_token);
        rateStage1BNB = _rate1BNB;
        rateStage2BNB = _rate2BNB;
        rateStage3BNB = _rate3BNB;

        rateStage1Stablecoin = _rate1Stablecoin;
        rateStage2Stablecoin = _rate2Stablecoin;
        rateStage3Stablecoin = _rate3Stablecoin;
    }

    /*//////////////////////////////////////////////////////////////
                               PRESALE
    //////////////////////////////////////////////////////////////*/

    function purchaseWithBNB(address referral) public payable {
        uint stage = currentStage();
        uint rate;
        if(stage == 1) {
            rate = rateStage1BNB;
        } else if(stage == 2) {
            rate = rateStage2BNB;
        } else {
            rate = rateStage3BNB;
        }

        uint amount = msg.value * rate;
        require(totalSold + amount <= tokenLimitStageOne + tokenLimitStageTwo + tokenLimitStageThree, "SALE_ENDED");
        require(amount >= minPurchaseAmount, "INVALID_AMOUNT");

        if(stage == 1) {
            unchecked {
                stageOnePurchases[msg.sender].amount += amount;
            }
            require(stageOnePurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            stageOnePurchases[msg.sender].remaining = stageOnePurchases[msg.sender].amount;
        } else if(stage == 2) {
            unchecked {
                stageTwoPurchases[msg.sender].amount += amount;
                require(stageOnePurchases[msg.sender].amount + stageTwoPurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            }
            stageTwoPurchases[msg.sender].remaining = stageTwoPurchases[msg.sender].amount;
        } else {
            unchecked {
                stageThreePurchases[msg.sender].amount += amount;
                require(stageOnePurchases[msg.sender].amount + stageTwoPurchases[msg.sender].amount + stageThreePurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            }
            stageThreePurchases[msg.sender].remaining = stageThreePurchases[msg.sender].amount;
        }

        unchecked {
            totalSold = totalSold + amount;
        }

        uint referAmount = 0;
        if(referral != address(0)) {
            referAmount = (msg.value * 5) / 100;
            (bool referOk, ) = payable(referral).call{value: referAmount}("");
            require(referOk, "REFER_FAILED");
        }

        (bool ok, ) = payable(owner()).call{value: msg.value - referAmount}("");
        require(ok, "PRICE_TRANSFER_FAILED");

        emit Purchased(msg.sender, amount, block.timestamp);
    }

    function purchaseWithStablecoin(address stablecoin, address referral, uint amountStablecoin) external {
        require(stablecoin == BUSD || stablecoin == USDT, "INVALID_ADDRESS");

        uint stage = currentStage();
        uint rate;
        if(stage == 1) {
            rate = rateStage1Stablecoin;
        } else if(stage == 2) {
            rate = rateStage2Stablecoin;
        } else {
            rate = rateStage3Stablecoin;
        }

        uint amount = amountStablecoin * rate;
        require(totalSold + amount <= tokenLimitStageOne + tokenLimitStageTwo + tokenLimitStageThree, "SALE_ENDED");
        require(amount >= minPurchaseAmount, "INVALID_AMOUNT");

        if(stage == 1) {
            unchecked {
                stageOnePurchases[msg.sender].amount += amount;
            }
            require(stageOnePurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            stageOnePurchases[msg.sender].remaining = stageOnePurchases[msg.sender].amount;
        } else if(stage == 2) {
            unchecked {
                stageTwoPurchases[msg.sender].amount += amount;
                require(stageOnePurchases[msg.sender].amount + stageTwoPurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            }
            stageTwoPurchases[msg.sender].remaining = stageTwoPurchases[msg.sender].amount;
        } else {
            unchecked {
                stageThreePurchases[msg.sender].amount += amount;
                require(stageOnePurchases[msg.sender].amount + stageTwoPurchases[msg.sender].amount + stageThreePurchases[msg.sender].amount <= maxPurchaseAmount, "EXCEEDS_MAX_PURCHASE_AMOUNT");
            }
            stageThreePurchases[msg.sender].remaining = stageThreePurchases[msg.sender].amount;
        }

        unchecked {
            totalSold = totalSold + amount;
        }

        uint referAmount = 0;
        if(referral != address(0)) {
            referAmount = (amountStablecoin * 5) / 100;
            IERC20(stablecoin).transferFrom(msg.sender, referral, referAmount);
        }

        IERC20(stablecoin).transferFrom(msg.sender, owner(), amountStablecoin - referAmount);

        emit Purchased(msg.sender, amount, block.timestamp);
    }

    function currentStage() public view returns (uint) {
        uint stage;

        if(totalSold < tokenLimitStageOne) {
            stage = 1;
        } else if(totalSold < tokenLimitStageOne + tokenLimitStageTwo) {
            stage = 2;
        } else {
            stage = 3;
        }
        
        return stage;
    }

    function claimStageOnePurchases() external {
        require(unlockStartTimestamp > 0, "UNLOCK_TIMER_NOT_STARTED");
        if(stageOnePurchases[msg.sender].nextVestingTime == 0) {
            require(block.timestamp > unlockStartTimestamp + 4 minutes, "NOT_UNLOCKED");
        } else {
            require(block.timestamp > stageOnePurchases[msg.sender].nextVestingTime, "NOT_UNLOCKED");
        }

        uint amount;
        if(stageOnePurchases[msg.sender].payouts == 3) {
            amount = stageOnePurchases[msg.sender].remaining;
            stageOnePurchases[msg.sender].amount = 0;
            stageOnePurchases[msg.sender].remaining = 0;
        } else {
            amount = stageOnePurchases[msg.sender].amount / 4;
            stageOnePurchases[msg.sender].remaining -= amount;
            stageOnePurchases[msg.sender].nextVestingTime = block.timestamp + 4 minutes;
        }

        if(amount == 0) {
            revert("NO_AMOUNT");
        }

        stageOnePurchases[msg.sender].payouts++;

        token.transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, 1);
    }

    function claimStageTwoPurchases() external {
        require(unlockStartTimestamp > 0, "UNLOCK_TIMER_NOT_STARTED");
        if(stageTwoPurchases[msg.sender].nextVestingTime == 0) {
            require(block.timestamp > unlockStartTimestamp + 2 minutes, "NOT_UNLOCKED");
        } else {
            require(block.timestamp > stageTwoPurchases[msg.sender].nextVestingTime, "NOT_UNLOCKED");
        }

        uint amount;
        if(stageTwoPurchases[msg.sender].payouts == 3) {
            amount = stageTwoPurchases[msg.sender].remaining;
            stageTwoPurchases[msg.sender].amount = 0;
            stageTwoPurchases[msg.sender].remaining = 0;
        } else {
            amount = stageTwoPurchases[msg.sender].amount / 4;
            stageTwoPurchases[msg.sender].remaining -= amount;
            stageTwoPurchases[msg.sender].nextVestingTime = block.timestamp + 2 minutes;
        }

        if(amount == 0) {
            revert("NO_AMOUNT");
        }

        stageTwoPurchases[msg.sender].payouts++;

        emit Claimed(msg.sender, amount, 2);
    }

    function claimStageThreePurchases() external {
        require(unlockStartTimestamp > 0, "UNLOCK_TIMER_NOT_STARTED");
        if(stageThreePurchases[msg.sender].nextVestingTime == 0) {
            require(block.timestamp > unlockStartTimestamp + 2 minutes, "NOT_UNLOCKED");
        } else {
            require(block.timestamp > stageThreePurchases[msg.sender].nextVestingTime, "NOT_UNLOCKED");
        }

        uint amount;
        if(stageThreePurchases[msg.sender].payouts == 1) {
            amount = stageThreePurchases[msg.sender].remaining;
            stageThreePurchases[msg.sender].amount = 0;
            stageThreePurchases[msg.sender].remaining = 0;
        } else {
            amount = stageThreePurchases[msg.sender].amount / 2;
            stageThreePurchases[msg.sender].remaining -= amount;
            stageThreePurchases[msg.sender].nextVestingTime = block.timestamp + 2 minutes;
        }

        if(amount == 0) {
            revert("NO_AMOUNT");
        }

        stageThreePurchases[msg.sender].payouts++;

        token.transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, 3);
    }

    function getRemainingAmountStageOne() external view returns(uint) {
        return stageOnePurchases[msg.sender].remaining;
    }
    
    function getRemainingAmountStageTwo() external view returns(uint) {
        return stageTwoPurchases[msg.sender].remaining;
    }

    function getRemainingAmountStageThree() external view returns(uint) {
        return stageThreePurchases[msg.sender].remaining;
    }

    function getClaimableAmountStageOne() external view returns (uint) {
      uint amount;
        if(stageOnePurchases[msg.sender].payouts == 3) {
            amount = stageOnePurchases[msg.sender].remaining;
        } else {
            amount = stageOnePurchases[msg.sender].amount / 4;
        }

        return amount;
    }

    function getClaimableAmountStageTwo() external view returns (uint) {
      uint amount;
        if(stageTwoPurchases[msg.sender].payouts == 3) {
            amount = stageTwoPurchases[msg.sender].remaining;
        } else {
            amount = stageTwoPurchases[msg.sender].amount / 4;
        }
        return amount;
    }

    function getClaimableAmountStageThree() external view returns (uint) {
      uint amount;
        if(stageThreePurchases[msg.sender].payouts == 1) {
            amount = stageThreePurchases[msg.sender].remaining;
        } else {
            amount = stageThreePurchases[msg.sender].amount / 2;
        }
        return amount;
    }

    /*//////////////////////////////////////////////////////////////
                          ONLY CONTRACT OWNER
    //////////////////////////////////////////////////////////////*/

    function startUnlockTimer() external onlyOwner {
        require(unlockStartTimestamp == 0, "ALREADY_STARTED");
        unlockStartTimestamp = block.timestamp;
    }

    // do not modify limit for a stage that has passed
    function setTokenLimitsPerStage(uint _tokenLimitStageOne, uint _tokenLimitStageTwo, uint _tokenLimitStageThree) external onlyOwner {
        tokenLimitStageOne = _tokenLimitStageOne;
        tokenLimitStageTwo = _tokenLimitStageTwo;
        tokenLimitStageThree = _tokenLimitStageThree;
    }

    function setPurchaseLimits(uint min, uint max) external onlyOwner {
        minPurchaseAmount = min;
        maxPurchaseAmount = max;
    }
 
    function setRatesBNB(uint _rate1, uint _rate2, uint _rate3) external onlyOwner {
        rateStage1BNB = _rate1;
        rateStage2BNB = _rate2;
        rateStage3BNB = _rate3;
    }
    
    function setRatesStablecoin(uint _rate1, uint _rate2, uint _rate3) external onlyOwner {
        rateStage1Stablecoin = _rate1;
        rateStage2Stablecoin = _rate2;
        rateStage3Stablecoin = _rate3;
    }

    function withdrawTokens(uint amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }
}
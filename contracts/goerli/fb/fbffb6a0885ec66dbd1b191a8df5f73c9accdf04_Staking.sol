/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-09
*/

// SPDX-License-Identifier: MIT
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/Pakagesale.sol



pragma solidity >=0.8.0;


contract Staking {

    // =============================================================
    //                           STORAGE
    // =============================================================

    uint256 public  constant BUSD_PRICE_PACKAGE_ONE = 250e18;
    uint256 public  constant BUSD_PRICE_PACKAGE_TWO = 500e18;

    uint256 public  constant GIFT_AMOUNT_PACKAGE_ONE = 2500e18;
    uint256 public  constant GIFT_AMOUNT_PACKAGE_TWO = 5000e18;

    uint256 public  constant MONTHLY_BUSD_PAYOUT_PACKAGE_ONE = 12500000000000000000; // 12.5
    uint256 public  constant QUARTER_BUSD_PAYOUT_PACKAGE_ONE = 62500000000000000000; // 62.5

    uint256 public  constant MONTHLY_BUSD_PAYOUT_PACKAGE_TWO = 25e18;
    uint256 public  constant QUARTER_BUSD_PAYOUT_PACKAGE_TWO = 125e18;

    uint256 private _counterMonthly;
    uint256 private _counterQuarterly;

    //IERC20 public constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // mainnet BUSD contract on BSC
    // IERC20 public constant XQZS = IERC20(0x58f26DC61943698B565473057FADa470f16f6722);  //xqzs token adress
    IERC20 public constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // mainnet BUSD contract on BSC // mainnet BUSD contract on BSC

    address private immutable _owner; // contract deployer

    struct Purchase {
        uint256 expirationTimestamp;
        uint256 lastPayoutTimestamp;
        uint256 payoutPeriodInSeconds;
        uint256 payoutAmount;
        uint256 totalBUSDreceived;
        uint256 payouts;
        address user;
        Package packageType;
        address ref;
    }

    enum Package { ONE, TWO } // 0 for ONE, 1 for TWO

    mapping(uint256 => Purchase)  private _monthlyPurchases;
    mapping(uint256 => Purchase)  private _quarterlyPurchases;

    mapping(address => uint256[]) private _userMonthlyPurchaseIds;
    mapping(address => uint256[]) private _userQuarterlyPurchaseIds;

    event PackagePurchased(uint256 id, uint256 indexed isMonthly, address user);
    event PayoutSent(uint256 indexed id, uint256 isMonthly); 


    constructor() { _owner = 0xE017be2d7375Af4bCD886686808302016BA56435; }

    function purchaseMonthlyPackage(Package packageType, address _ref) external {
        require(packageType == Package.ONE || packageType == Package.TWO, "INVALID_PACKAGE"); 

        uint256 currentId;

        bool packageOne = packageType == Package.ONE;

        uint256 payoutPeriod = 1 minutes;  
        uint256 nextPayout = block.timestamp + payoutPeriod;
        uint256 purchaseAmount = packageOne ? BUSD_PRICE_PACKAGE_ONE : BUSD_PRICE_PACKAGE_TWO;

        Purchase memory p = Purchase(
            block.timestamp + 365 days, 
            nextPayout, 
            payoutPeriod, 
            _getPayoutAmount(packageOne, 1),
            0,
            0,
            msg.sender, 
            packageType,
            _ref
        );
        
       
        unchecked {
            currentId = _counterMonthly++; 
        }

        _monthlyPurchases[currentId] = p;
        _userMonthlyPurchaseIds[msg.sender].push(currentId);
     

        if(_ref!=address(0))
        {
            uint amount10=(6000000000000000000 * purchaseAmount)/100000000000000000000;
            uint amount90=(94000000000000000000 * purchaseAmount)/100000000000000000000;
            BUSD.transferFrom(msg.sender, _ref, amount10);
            BUSD.transferFrom(msg.sender, address(this), amount90);
            // XQZS.transfer(msg.sender, packageOne ? GIFT_AMOUNT_PACKAGE_ONE : GIFT_AMOUNT_PACKAGE_TWO);
            
        }else{
            BUSD.transferFrom(msg.sender, address(this), purchaseAmount);
            // XQZS.transfer(msg.sender, packageOne ? GIFT_AMOUNT_PACKAGE_ONE : GIFT_AMOUNT_PACKAGE_TWO);
        }
        


        emit PackagePurchased(currentId, 1, msg.sender);
    }

    function purchaseQuarterlyPackage(Package packageType, address _ref) external {
        require(packageType == Package.ONE || packageType == Package.TWO, "INVALID_PACKAGE"); 

        uint256 currentId;

        bool packageOne = packageType == Package.ONE;

        uint256 payoutPeriod = 9 minutes;
        uint256 nextPayout = block.timestamp + payoutPeriod;  
        uint256 purchaseAmount = packageOne ? BUSD_PRICE_PACKAGE_ONE : BUSD_PRICE_PACKAGE_TWO;

        Purchase memory p = Purchase(
            block.timestamp + 365 days, 
            nextPayout, 
            payoutPeriod, 
            _getPayoutAmount(packageOne, 3),
            0,
            0,
            msg.sender, 
            packageType,
            _ref
        );
        
        unchecked {
            currentId = _counterQuarterly++;
        }

        _quarterlyPurchases[currentId] = p;
        _userQuarterlyPurchaseIds[msg.sender].push(currentId);
        
        if(_ref!=address(0))
        {
            uint amount10=(6000000000000000000 * purchaseAmount)/100000000000000000000;
            uint amount90=(94000000000000000000 * purchaseAmount)/100000000000000000000;
            BUSD.transferFrom(msg.sender, _ref, amount10);
            BUSD.transferFrom(msg.sender, address(this), amount90);
            // XQZS.transfer(msg.sender, packageOne ? GIFT_AMOUNT_PACKAGE_ONE : GIFT_AMOUNT_PACKAGE_TWO);
            
        }else{
            BUSD.transferFrom(msg.sender, address(this), purchaseAmount);
            // XQZS.transfer(msg.sender, packageOne ? GIFT_AMOUNT_PACKAGE_ONE : GIFT_AMOUNT_PACKAGE_TWO);
        }

        emit PackagePurchased(currentId, 0, msg.sender);
    }

    function _getPayoutAmount(bool packageOne, uint payoutPeriodInMonths) private pure returns (uint256) {
        if(packageOne && payoutPeriodInMonths == 1)
            return MONTHLY_BUSD_PAYOUT_PACKAGE_ONE;
        else if(packageOne && payoutPeriodInMonths == 3)
            return QUARTER_BUSD_PAYOUT_PACKAGE_ONE;
        else if(!packageOne && payoutPeriodInMonths == 1)
            return MONTHLY_BUSD_PAYOUT_PACKAGE_TWO;
        else
            return QUARTER_BUSD_PAYOUT_PACKAGE_TWO;
    }

    function withdrawMonthly(uint id) external {
        Purchase storage currentPurchase = _monthlyPurchases[id];

        require(msg.sender == currentPurchase.user, "NO_ACCESS");
        uint newPayouts = (block.timestamp - currentPurchase.lastPayoutTimestamp) / currentPurchase.payoutPeriodInSeconds;
        require(newPayouts > 0, "NO_PAYOUT");
        require(currentPurchase.payouts < 12, "NO_PAYOUT_LEFT");

        if(newPayouts > 12 - currentPurchase.payouts) {
            newPayouts = 12 - currentPurchase.payouts;
        }

        uint amount = currentPurchase.payoutAmount * newPayouts;

        currentPurchase.lastPayoutTimestamp = block.timestamp;
        currentPurchase.totalBUSDreceived += amount;
        currentPurchase.payouts += newPayouts;

        BUSD.transfer(currentPurchase.user, amount);

        emit PayoutSent(id, 1);
    }

    function withdrawQuarterly(uint id) external {
        Purchase storage currentPurchase = _quarterlyPurchases[id];

        require(msg.sender == currentPurchase.user, "NO_ACCESS");
        uint newPayouts = (block.timestamp - currentPurchase.lastPayoutTimestamp) / currentPurchase.payoutPeriodInSeconds;
        require(newPayouts > 0, "NO_PAYOUT");
        require(currentPurchase.payouts < 4, "NO_PAYOUT_LEFT");

        if(newPayouts > 4 - currentPurchase.payouts) {
            newPayouts = 4 - currentPurchase.payouts;
        }

        uint amount = currentPurchase.payoutAmount * newPayouts;

        currentPurchase.lastPayoutTimestamp = block.timestamp;
        currentPurchase.totalBUSDreceived += amount;
        currentPurchase.payouts += newPayouts;

        BUSD.transfer(currentPurchase.user, amount);

        emit PayoutSent(id, 0);
    }
    // =============================================================
    //                            GETTERS
    // =============================================================
 
    function getMonthlyPurchaseInformation(uint256 id) external view returns  (Purchase memory) {
        return _monthlyPurchases[id];
    }

    function getMonthlyRewards(uint256 id) external view returns (uint256) {
        Purchase memory currentPurchase = _monthlyPurchases[id];

        uint newPayouts = (block.timestamp - currentPurchase.lastPayoutTimestamp) / currentPurchase.payoutPeriodInSeconds;

        if(newPayouts > 0 && currentPurchase.payouts < 12) {
            if(newPayouts > 12 - currentPurchase.payouts) {
                newPayouts = 12 - currentPurchase.payouts;
            }
            return currentPurchase.payoutAmount * newPayouts;
        } else {
            return 0;
        }
    }

    function getQuarterlyRewards(uint256 id) external view returns (uint256) {
        Purchase memory currentPurchase = _quarterlyPurchases[id];

        uint newPayouts = (block.timestamp - currentPurchase.lastPayoutTimestamp) / currentPurchase.payoutPeriodInSeconds;

        if(newPayouts > 0 && currentPurchase.payouts < 4) {
            if(newPayouts > 4 - currentPurchase.payouts) {
                newPayouts = 4 - currentPurchase.payouts;
            }
            return currentPurchase.payoutAmount * newPayouts;
        } else {
            return 0;
        }
    }

    function getMonthlyRewardsClaimed(uint256 id) external view returns (uint256) {
        return _monthlyPurchases[id].totalBUSDreceived;
    }

    function getQuarterlyRewardsClaimed(uint256 id) external view returns (uint256) {
        return _quarterlyPurchases[id].totalBUSDreceived;
    }

    function getQuarterlyPurchaseInformation(uint256 id) external view returns (Purchase memory) {
        return _quarterlyPurchases[id];
    }

    function monthlyPurchasesOf(address user) external view returns (uint256[] memory) {
        return _userMonthlyPurchaseIds[user];
    }

    function quarterlyPurchasesOf(address user) external view returns (uint256[] memory) {
        return _userQuarterlyPurchaseIds[user];
    }

    function withdraw(address token, uint amount) external {
        require(msg.sender == _owner);
        IERC20(token).transfer(msg.sender, amount);
    }
}
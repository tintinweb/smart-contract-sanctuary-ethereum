//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../EGClottery.sol";

contract RewardsWallet is Ownable {

    /*
        Variables to make swap
        EGCl -> wBNB -> EGC
    */

    // FOR TESTING: EGCL -> WETH -> DAI
    // DAI token for testing
    IBEP20 public EGC = IBEP20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    EGClottery public EGCL;
    // WETH-reinkeby for testing
    IBEP20 public WBNB = IBEP20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    IPancakeRouter02 public router = IPancakeRouter02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);


    /*
        This distributionDay variable follows distributionDay
        variable in EGClottery to calculate balance in each dist. day.
    */
    uint256 private _distributionDay = 1;

    /*
        Responsible for the ability to convert
        EGCL to EGC
    */
    bool convertionState;
    
    /*
        Needed to record EGCL balance in each _distributionDay
    */
    mapping(uint256 => uint256) private rewardsWalletEGCLBalancePerDay;
    /*
        Needed to record EGC! balance in each _distributionDay
    */
    mapping(uint256 => uint256) private EGCBalancePerDay;

    modifier onlyEGCL {
        require(_msgSender() == address(EGCL), "ACCES DENIED: you're not a EGCL contract");
        _;
    }

    function convertToEGC() public {
        //require(EGCL.getDistributionDay() > _distributionDay, "You can't convert rewards yet: 1 line ERROR");
        //require(convertionState == true, "You can't convert rewards yet: 2 line ERROR");

        uint256 _amountIn = getEGCLbalance();
        EGCL.approve(address(router), _amountIn);

        // EGCL --> wBNB --> EGC;
        address[] memory path;
        path = new address[](3);
        path[0] = address(EGCL);
        path[1] = address(WBNB);
        path[2] = address(EGC);
        
        uint256 _amountOutMin = getAmountOutMin(address(EGCL), address(EGC), _amountIn);
        uint256 _deadline = block.timestamp + 2 minutes;
        
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, address(this), _deadline);
        /*
            Recording EGCL and EGC balance in current day.
        */
        rewardsWalletEGCLBalancePerDay[_distributionDay] = _amountIn;
        EGCBalancePerDay[_distributionDay] = _amountOutMin;
        _distributionDay++;
        convertionState = false;
    }


    /*
        GETTER FUNCTIONS
    */
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns(uint256) {
        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = address(WBNB);
        path[2] = _tokenOut;

        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getEGCbalanceOfRW() public view returns(uint256) {
        return EGC.balanceOf(address(this));
    }

    function getEGCLbalance() public view returns(uint256) {
        return EGCL.balanceOf(address(this));
    }

    function getEGCbalancePerDay(uint256 _day) public view returns(uint256) {
        require(EGC.balanceOf(address(this)) != 0, "EGC balance of Reward Wallet is 0");
        return rewardsWalletEGCLBalancePerDay[_day];
    }

    function getConvertionState() external view returns(bool) {
        return convertionState;
    }

    function getDistributionDay() external view returns(uint256) {
        return _distributionDay;
    }

    /*
        SETTER FUNCTIONS
    */
    function setEGCLaddress(address _EGCL) external onlyOwner {
        EGCL = EGClottery(_EGCL);
    }

    function setConvertionState(bool _state) external {
        convertionState = _state;
    }

    /*
        Main function to withdraw dividends
        makes call to ECGL contract to calculate it
        for user in past distribution days
    */
    function withdrawDividends(address _msgS, uint256 _amount) external onlyEGCL {
        require(getEGCbalanceOfRW() > 0, "EGC balance is zero");
        require(_amount <= getEGCbalanceOfRW(), "Amount of dividends exceeds RW balance");
        EGC.transfer(_msgS, _amount);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IBEP20.sol";
import "./interfaces/IBEP20Metadata.sol";
import "./rewards/RewardsWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EGClottery is 
    IBEP20, 
    IBEP20Metadata, 
    Ownable 
{
    using SafeMath for uint256;


    /* 
    BEP20
    */
    uint256 private _totalSupply;

    // BEP20 Metadata:
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    /* 
    Dividends
    */

    /*
        Given that dividends must be distributed every 24 hours, 
        this variable calculates each day
        of the distribution of dividends.
    */
    uint256 private distributionDay = 1;
    // 24 hours
    uint256 private distributionPeriod;

    /*
        this mapping allows you to record the user's 
        balance in a certain time interval (24 hours) 
        during the transfer of funds.
    */
    mapping(address => mapping(uint256 => uint256)) private balancePerDay;
    mapping(uint256 => uint256) private EGCBalancePerDay;
    /*
        this mapping allows you to find out 
        whether the user took his dividends 
        on a certain, past day
    */
    mapping(address => mapping(uint256 => bool)) private dividendsPerDayClaimed;
    mapping(address => uint256) private soldInDay;
    mapping(uint256 => uint256) private totalSupplyPerDay;

    //emits when user claims his dividends.
    event DividendsClaimed(address _beneficiary, uint256 _amount);
    //emits when 24 hours passed and new distributionDay set.
    event DistributionDayPassed(uint256 _newDay);
    
    /*
    ***TOKENOMICS***

    1. 6% of every transaction as passive income in EverGrow
    2. 5% of ever transaction goes to the lottery pool
    3. 3% goes to the pancakeswap liquidity pool
    4. 1% goes to a buy back and burn wallet
    */

    /* 
    Fees
    */
    uint256 private rewardsWalletFee = 6;
    uint256 private lotteryPoolFee = 5;
    uint256 private pancakeSwapLPfee = 3;
    uint256 private burn = 1;

    // For PinkSale pre-sale
    mapping(address => bool) private excludedFromFee;


    /* 
    Wallets
    */
    address private pancakeSwapLP = 0x15314C9e4284D228a93Ead5C4d0d97cF0F67030F;
    address private lotteryPool = 0x15314C9e4284D228a93Ead5C4d0d97cF0F67030F;
    address private burnWallet = 0x15314C9e4284D228a93Ead5C4d0d97cF0F67030F;
    RewardsWallet private rewardsWallet;

    /*
    Lottery
    */
    mapping(address => mapping(uint256 => uint256)) private _balanceForLottery;
    mapping(address => bool) private _isRegistered;

    /* 
    MODIFIERS
    */

    /*
        A modifier linked to the _transfer 
        function, at each transfer of funds, 
        checking whether the token distribution 
        period has passed and if it has 
        passed, then adds 1 day 
        to the value of distributionDay.
    */
    modifier distributionDayCheck {
        if (distributionPeriod < block.timestamp) {
            distributionDay++;
            distributionPeriod = block.timestamp + 5 minutes;
            rewardsWallet.setConvertionState(true);
            
            emit DistributionDayPassed(distributionDay);
        }
        _;
    }

    modifier dividendsCheck(address _sender, address _recipient, uint256 _amount) {
        if (rewardsWallet.getEGCbalanceOfRW() > 0) {
          if ((balanceOf(_sender) - _amount) > 0) {
            uint256 dividends01 = calculateDividends(_sender, distributionDay);
                if (dividends01 > 0) {
                    rewardsWallet.withdrawDividends(_sender, dividends01);
                }
        }   else if (balanceOf(_recipient) > 0) {
            uint256 dividends02 = calculateDividends(_recipient, distributionDay);
                if (dividends02 > 0) {
                    rewardsWallet.withdrawDividends(_recipient, dividends02);
                }
            }
        }
        _;  
    }

    modifier onlyContract {
        require(_msgSender() == address(this), "Access denied");
        _;
    }

    modifier onlyRW {
        require(_msgSender() == address(rewardsWallet), "Access denied");
        _;
    }

    /*constructor(
        address _pslp,
        address _lotp,
        address _bw,
        address _rw
    ) */
    constructor(address _rw) {
        _name = "EGClottery"; // EGClottery
        _symbol = "EGCL"; // EGCL
        _decimals = 9;

        /*pancakeSwapLP = _pslp;
        lotteryPool = _lotp;
        burnWallet = _bw;
        rewardsWallet = RewardsWallet(_rw);
        */
        rewardsWallet = RewardsWallet(_rw);

        address lockedBurnWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address lp = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address teamWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;
        address marketingWallet = 0xC979d6013868f49Bf4593743592C9D967B1300f7;

        /*
        initial supply := 1,000,000,000,000,000

        1. 50% pre-sale
        2. 30% burn in a locked wallet
        3. 20% liquidity
        4. 7% team wallet that is locked for 1 year
        5. 3% for marketing and airdrop
        */
        uint256 initSupply = 1000000000000000*10**9;

        uint256 preSale = initSupply.div(2); // 500000000000000 EGCL ---> Pre-sale
        //amount to use in PinkSale
        _mint(msg.sender, preSale);
        uint256 burnAmount = initSupply * 30 / 100; // 300000000000000 EGCL ---> Burn and BuyBack wallet
        _mint(lockedBurnWallet, burnAmount);
        uint256 liquidity = initSupply * 20 / 100; // 200000000000000 EGCL ---> For Liquidity
        _mint(lp, liquidity);
        //uint256 teamWalletDist = initSupply * 7 / 100; // 70000000000000 EGCL ---> TeamWallet
        //_mint(teamWallet, teamWalletDist);
        //uint256 marketingDist = initSupply * 3 / 100; // 30000000000000 EGCL ---> Marketing
        //_mint(marketingWallet, marketingDist);

        distributionPeriod = block.timestamp + 5 minutes;
    }


    /* 
    GETTER FUNCTIONS
    <for BEP20 metadata>
    */
    function name() public view override returns (string memory) {return _name;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function decimals() public view override returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function getOwner() external view override returns(address) {return owner();}


    /* 
    GETTER FUNCTIONS
    <for fees>
    */
    function getPancakeLPFee() external view returns(uint256) {
        return pancakeSwapLPfee;
    }

    function getRWFee() external view returns(uint256) {
        return rewardsWalletFee;
    }

    function getLotteryPoolFee() external view returns(uint256) {
        return lotteryPoolFee;
    }
    
    function getBurnWalletFee() external view returns(uint256) {
        return burn;
    }


    /* 
    GETTER FUNCTIONS
    <for wallets>
    */
    function getPancakeLPAddres() external view returns(address) {
        return pancakeSwapLP;
    }

    function getLotteryPoolAddress() external view returns(address) {
        return lotteryPool;
    }

    function getBurnWallet() external view returns(address) {
        return burnWallet;
    }

    function getRewardsWallet() external view returns(address) {
        return address(rewardsWallet);
    }


    /* 
    GETTER FUNCTIONS
    <for dividends>
    */

    /*
    Returns current distributionDay.
    */
    function getDistributionDay() external view returns(uint256) {
        return distributionDay;
    }

    /*
    Returns balance of _sahreholder in certain day.
    */
    function getBalancePerDay(address _shareholder, uint256 _day) external view returns(uint256) {
        return balancePerDay[_shareholder][_day];
    }

    /*
    FEES SETTER FUNCTIONS
    */

    function setPancakeSwapLPfee(uint256 _amount) external onlyOwner {
        pancakeSwapLPfee = _amount;
    }

    function setLotteryPoolFee(uint256 _amount) external onlyOwner {
        lotteryPoolFee = _amount;
    }

    function setBurnWalletFee(uint256 _amount) external onlyOwner {
        burn = _amount;
    }

    function setRewardsWalletFee(uint256 _amount) external onlyOwner {
        rewardsWalletFee = _amount;
    }

    /*
    WALLETS SETTER FUNCTIONS
    
    address private pancakeSwapLP;
    address private lotteryPool;
    address private burnWallet;
    RewardsWallet private rewardsWallet;
    */

    function setPancakeLPaddress(address _pslp) external onlyOwner {
        pancakeSwapLP = _pslp;
    }

    function setLotteryPool(address _lp) external onlyOwner {
        lotteryPool = _lp;
    }

    function setBurnWallet(address _bw) external onlyOwner {
        burnWallet = _bw;
    }

    function setRewardsWallet(address _rw) external onlyOwner {
        rewardsWallet = RewardsWallet(_rw);
    }


    /* 
    BEP20 SETTER FUNCTIONS
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    /*
        TASK:

        ************************
        Distribute rewards when 
        user triggers a 
        transfer function.
        ************************
    */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal distributionDayCheck dividendsCheck(sender, recipient, amount) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to this address is unavailable");
        
        // Checks for addresses(both sender and recipient) excluded from fees
        if (excludedFromFee[sender] == true || excludedFromFee[recipient] == true) {
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                _balances[sender] = senderBalance - amount;

                if (_balances[sender] == 0) {
                    soldInDay[sender] = distributionDay;

                    balancePerDay[sender][distributionDay] = _balances[sender];
                    _balanceForLottery[sender][distributionDay] = _balances[sender];
                } else {
                    /*
                    Here we calculate and record user's balance
                    in certain distribution day
                    to ensure that after claiming of the dividends
                    he can't transfer funds to another account
                    and claim dividends using it.
                    */
                    balancePerDay[sender][distributionDay] = _balances[sender];
                    _balanceForLottery[sender][distributionDay] = _balances[sender];
                }
                
                _balances[recipient] += amount;

                balancePerDay[recipient][distributionDay] = _balances[recipient];
                _balanceForLottery[recipient][distributionDay] = _balances[recipient];

                emit Transfer(sender, recipient, amount);
        } else {
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        /*
        Calculating the fees
        */
        uint256 EGCfee = amount.mul(rewardsWalletFee).div(100);
        uint256 lotteryFee = amount.mul(lotteryPoolFee).div(100);
        uint256 lpFee = amount.mul(pancakeSwapLPfee).div(100);
        uint256 toBurn = amount.mul(burn).div(100);

        _balances[sender] = senderBalance - amount;

            if (_balances[sender] == 0) {
                soldInDay[sender] = distributionDay;
                balancePerDay[sender][distributionDay] = _balances[sender];
                _balanceForLottery[sender][distributionDay] = _balances[sender];
            } else {
                balancePerDay[sender][distributionDay] = _balances[sender];
                _balanceForLottery[sender][distributionDay] = _balances[sender];
            }

        /*
        Distributing fees between wallets + burning
        */
        _balances[pancakeSwapLP] += lpFee;
        _balances[lotteryPool] += lotteryFee;
        _balances[address(rewardsWallet)] += EGCfee;
        _balances[burnWallet] += toBurn;
        _totalSupply -= toBurn;
        totalSupplyPerDay[distributionDay] = _totalSupply;

        /*
        The final number of tokens that the user will receive with the deduction of fees
        */
        uint256 amountToRecipient = amount - EGCfee - lotteryFee - lpFee - toBurn;
             
        _balances[recipient] += amountToRecipient;

        balancePerDay[recipient][distributionDay] = _balances[recipient];
        _balanceForLottery[recipient][distributionDay] = _balances[recipient];

        emit Transfer(sender, recipient, amount);
            
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /*
    WHITELIST FUNCTIONS
    */
    function excludeFromFee(address _account) external onlyOwner {
        excludedFromFee[_account] = true;
    }

    function includeFee(address _account) external onlyOwner {
        excludedFromFee[_account] = false;
    }


    /*
    DIVIDENDS FUNCTIONS
    */

    /*  
        Precondition: EGCL in RewardsWallet converted to EGC

        Function whcih can be called through RewardWallet contract
        takes as argument address of msg.sender, who called withdrawDividends()
        in RewardsWallet contract.

        Calculation of the dividends occurs due to the iteration through
        balancePerDay mapping. 

        Function calculates all recorded balances in all existed distribution days
        and converting it to the EGC dividends, which user can claim, after claiming
        dividends function resets balancePerDay for each day of itertaion and set for 
        all existed days dividendsPerDayClaimed mapping value to true, to ensure that
        user can't claim dividends from another account.
    */

    // SHOULD BE ONLYRW!!!!!!!!!!!!!!!!!!!!!
    function claimDividends() public returns(bool) {
        uint256 dividendsTotal;

        for (uint256 i = 1; i != distributionDay; i++) {
            /*
                This <if> condition needed to be able to claim dividends
                for users who has holding and didn't trasnfer their tokens
                and their balances for eadch day hasn't been recorded.

                Preconditions:
                1) users balance in <i> day = 0
                2) he hasn't claimed his dividends for n days
                3) his balance per current day = 0, to prevent claiming
                dividends by one user from multiple accounts. If user's
                balance on current day > 0 but he didn't transfer tokens
                for couple of previous days, he can't claim his didivdends
                for this day atm, but he can freely claim them on the next day.
                4) current balance of user is > 0;

                For example:
                X bought his tokens in [1] day and has been holding
                it 5 days long, then he decide to claim his dividends
                Calculation would be:

                    Preconditions:
                    1) for the [1] day his balance was recorded and that
                    tokens added to dividendsTotal value, but for the next
                    [2][3][4][5] days his balance wasn't recorded by balancePerDay
                    mapping, so the user balance for <i> day == 0,
                        1 precondition passed
                    2) user didn't claim his dividends in that <i> day.
                        2 precondition passed
                    3) users balance wasn't recorded in current day because he
                    didn't make any transfers.
                        3 precondition passed
                    4) users balance > 0
                        4 precondition passed

                    When all of the preconditions has passed dividends of the user calculates
                    for EGC balance of each <i> day and this value added to the dividendsTotal.
            */
            if(
                soldInDay[_msgSender()] < i
                && balancePerDay[_msgSender()][i] == 0
                && dividendsPerDayClaimed[_msgSender()][i] == false
                && balancePerDay[_msgSender()][distributionDay] == 0
                && balanceOf(_msgSender()) > 0
            ) {
                dividendsTotal += calculateDividends(_msgSender(), i);
                dividendsPerDayClaimed[_msgSender()][i] = true;
            } else if (
                        balancePerDay[_msgSender()][i] == 0
                        && dividendsPerDayClaimed[_msgSender()][i] == false
                        ) {
                dividendsTotal += 0;
            } else if (
                        soldInDay[_msgSender()] >= i
                        ) {
                dividendsTotal += 0;
            } else if (
                        balancePerDay[_msgSender()][i] > 0
                        && balanceOf(_msgSender()) > 0
                        && dividendsPerDayClaimed[_msgSender()][i] == false
                        ) {
                dividendsTotal += calculateDividends(_msgSender(), i);
                dividendsPerDayClaimed[_msgSender()][i] = true;
            }
        }
            
        if (dividendsTotal == 0) {
            return false;
        } else {
            rewardsWallet.withdrawDividends(_msgSender(), dividendsTotal);
            return true;
        }
    }

    // !!!!!!!!!!!!!!!! SHOULD BE INTERNAL !!!!!!!!!!!!!!!!!!!!!!!
    // +++++ onlyContract !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function calculateDividends(address _shareholder, uint256 _day) public view returns(uint256) {
        /*
            Function that calculates dividends in EGC token in _day,
            based on amount of tokens that user has in that _day.

            if - for users which balance in _day is recorded
            else - for users whcih balance in _day isn't recorded
        */
        
        if(balancePerDay[_shareholder][_day] > 0) {
            uint256 _balance = balancePerDay[_shareholder][_day];
            uint256 _share = calculateShare(_balance, _day);

            return rewardsWallet.getEGCbalancePerDay(_day).mul(_share.div(100));
        } else {
            uint256 _balance = balanceOf(_shareholder);
            uint256 _share = calculateShare(_balance, _day);

            return rewardsWallet.getEGCbalancePerDay(_day).mul(_share.div(100)).div(10**15);
        }
    }


    // !!!!!!!!!!!!!!!! SHOULD BE INTERNAL !!!!!!!!!!!!!!!!!!!!!!!
    function calculateShare(uint256 _bal, uint256 _day) public view returns(uint256) {
            /*
                Min avaialble perc = 1000 = 10**-24 = 0,0000000000000000000001 %
                Max available perc = 10**24 = 100%

                Percentages range:
                [1e-23 %..............1e23 %]   
            */
        return _bal.mul(10**15).mul(100).div(totalSupplyPerDay[_day]);
    }

    /*
    LOTTERY FUNCTIONS

    function isRegistered(address _shareholder) external view returns(bool) {
        return _isRegistered[_shareholder];
    }

    function register() external {
        require(isRegistered(_msgSender()) == false, "You've already registered");

            //Calculation for people who haven't transfered 
            //tokens since they're bought it
        
        if (balanceForLottery[_msgSender()][distributionDay] == 0 && balanceOf(_msgSender()) > 0) {
            uint256 ticketsNum;

            uint256 _share = calculateShare(balanceOf(_msgSender()), distributionDay);
            if (_share)
        }
        calculateShare(balanceOf(_msgSender(), distributionDay));
    }
    */
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
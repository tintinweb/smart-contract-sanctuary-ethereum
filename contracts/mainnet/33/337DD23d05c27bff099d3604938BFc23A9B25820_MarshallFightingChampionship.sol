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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
 * 
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMX0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKKKKXXNMMMMMMMMMMMMMMMMMMM
MMMMMMk';kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.oWMMMMMMMMMMMMW0l:::;::;;::::::::::::::::::::l0MMMMMMMMMMMMMMMMMMMMMMWKOdl:,'........';cox0NMMMMMMMMMMMMM
MMMMMMk.  ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.  lWMMMMMMMMMMMMMWO:.                          .xMMMMMMMMMMMMMMMMMMMXOl,.                   .':xKWMMMMMMMMM
MMMMMMk.    ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.    lWMMMMMMMMMMMMMMMWO:.                        .kMMMMMMMMMMMMMMMMMMNd.                          .;xNMMMMMMM
MMMMMMk.      ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.      lWMMMMMMMMMMMMMMMMMWO:.                      .kMMMMMMMMMMMMMMMMMMMNk;                            'xNMMMMM
MMMMMMk.        ;kNMMMMMMMMMMMMMMMMMMMMMMMMW0c.        lWMMMMMMMMMMMMMMMMMMMWO:.....................,OMMMMMMMMMMMMMMMMMMMMMNk;     .,;:cc::,..          'xNMMMMM
MMMMMMO.          ;kNMMMMMMMMMMMMMMMMMMMMW0c.          lWMMMMMMMMMMMMMMMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXWMMMMMMMMMMMWKXMMMMMMMMMNk:cx0XWMMMMMMWNKkl,     ,xNMMMMMMM
MMMMMMWO:.          ;kNMMMMMMMMMMMMMMMMW0c.            lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..oXWMMMMMMMMMMMMMMMMMMMMMMMMMNOc.,xNMMMMMMMMM
MMMMMMMMWO:.          ;kNMMMMMMMMMMMMW0c.              lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.   .oKMMMMMMMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMM
MMMMMMMMMMWO:.          ;kNMMMMMMMMW0c.                lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;      .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWO:.          ;kNMMMMW0c.                  lWMMMMMMMMMMMMXkddddddddddddddddddddddddddddKMMMMMMMMMMMx.        ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWO:.          ;kNW0c.                    lWMMMMMMMMMMMMk.                            oMMMMMMMMMMWl         ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWO:.          ,:.          ,xl.        lWMMMMMMMMMMMMk.                            oMMMMMMMMMMN:         cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMKd0WMMMMMMMMWO:.                   ,xNMd         lWMMMMMMMMMMMMk.                            oMMMMMMMMMMN:         cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMk..c0WMMMMMMMMWO:.               ,xNMMMd         lWMMMMMMMMMMMMk.                           .dMMMMMMMMMMWo         ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMk.  .c0WMMMMMMMMWO:.           ,xNMMMMMd         lWMMMMMMMMMMMMk.        .,oOOOOOOOOOOOOOOOOOXMMMMMMMMMMMk.         oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMk.    .c0WMMMMMMMMWO:.       ,xNMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMk.      .c0WMMMMMMMMWO:.   ,xNMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,          ;OWMMMMMMMMMMMMMMMMMMWKdkNMMMMMMMMMM
MMMMMMk.        cNMMMMMMMMMMWOc;xNMMMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,          .:xXWMMMMMMMMMMMMMNOc.  ,xNMMMMMMMM
MMMMMMk.        :NMMMMMMMMMMMMWWMMMMMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.           .;lxO0KKKK0Oxo:'       ,xNMMMMMM
MMMMMMk.        :NMMMMMMMMMMMMMMMMMMMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,               ......              lXMMMMM
MMMMMMk.        :NMMMMMMMMMMMMMMMMMMMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.                              .oKWMMMMM
MMMMMMk.        :NMMMMMMMMMMMMMMMMMMMMMMMMMMMd         lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,.                        .:xXMMMMMMMM
MMMMMMk.        :NMMMMMMMMMMMMMMMMMMMMMMMMMMMd.        lWMMMMMMMMMMMMk.        .cOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc,.               ..;lkXWMMMMMMMMMM
MMMMMMXOxxxxxxxx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMXkxxxxxxxxKMMMMMMMMMMMMMXkxxxxxxxxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxdolc::::clodk0NWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                               


Telegram: https://t.me/MFCworld 
Website: https://mfc.com

*/

pragma solidity 0.8.18;



import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MarshallFightingChampionship is IERC20, Ownable {
    ////////////////////////// address //////////////////////////

    address[] private _excluded; // addresses excluded from rewards

    address public lpPair;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    ////////////////////////// uint //////////////////////////

    uint256 private constant _tTotal = 1_000_000_000 * 10**_decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 constant taxDivisor = 1000;
    uint256 public swapThreshold;
    uint256 public launchedAt;
    uint256 public deadBlocks;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForMarketing;
    uint256 private _tokensForStaking;

    ////////////////////////// mappings //////////////////////////

    mapping(address => uint256) public _rOwned; // balance of  holders getting reflections
    mapping(address => uint256) _tOwned; // tokens owned if excluded from rewards
    mapping(address => bool) private lpPairs;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _liquidityProviders;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromRewards;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) private isPresaler;

    ////////////////////////// bool //////////////////////////

    bool private inSwap;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingStarted = false;
    bool public _hasLiqBeenAdded = false;
    bool public allowPresaleExclusion = true;

    ////////////////////////// token info //////////////////////////

    string private constant _name = "Marshall Fighting Championship";
    string private constant _symbol = "MFC";
    uint8 private constant _decimals = 18;

    ////////////////////////// router //////////////////////////

    IUniswapV2Router02 public uniswapRouter;

    ////////////////////////// struct //////////////////////////

    struct Fees {
        uint16 buyTotalFee;
        uint16 sellTotalFee;
        uint16 reflectionBuy;
        uint16 marketingBuy;
        uint16 liquidityBuy;
        uint16 stakingBuy;
        uint16 reflectionSell;
        uint16 marketingSell;
        uint16 liquiditySell;
        uint16 stakingSell;
    }

    // max wallet and max txs are in % of total supply
    struct Limits {
        uint16 buyLimit;
        uint16 sellLimit;
        uint16 maxWallet;
    }
    // Extra values for the transfer function
    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
        uint256 currentRate;
    }

    // receiver addresses for fees
    struct FeeReceivers {
        address payable marketing;
        address payable staking;
    }

    Fees public _taxRates =
        Fees({
            buyTotalFee: 60,
            sellTotalFee: 60,
            reflectionBuy: 10,
            marketingBuy: 30,
            liquidityBuy: 10,
            stakingBuy: 10,
            reflectionSell: 10,
            marketingSell: 30,
            liquiditySell: 10,
            stakingSell: 10
        });

    FeeReceivers public _FeeReceivers =
        FeeReceivers({marketing: payable(DEAD), staking: payable(DEAD)});

    Limits public limits =
        Limits({buyLimit: 50, sellLimit: 100, maxWallet: 50});

    ////////////////////////// errors //////////////////////////

    error InvalidContractSwapSettings(string error);
    error TradingNotActive(string error);
    error StartTradingError(string error);
    error InvalidRatioSettings(string error);
    error InvalidFeesSettings(string error);
    error InvalidLimitsSettings(string error);
    error InvalidFeeReceivers(string error);
    error MaxTxExceeded(string error);
    error MaxWalletExceeded(string error);

    ////////////////////////// events //////////////////////////

    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    event TradingStarted(bool tradingStarted);
    event LpPairsUpdated(address lpPair, bool isLpPair);
    event TaxesUpdated(
        uint16 buyTotalFee,
        uint16 sellTotalFee,
        uint16 reflectionBuy,
        uint16 marketingBuy,
        uint16 liquidityBuy,
        uint16 stakingBuy,
        uint16 reflectionSell,
        uint16 marketingSell,
        uint16 liquiditySell,
        uint16 stakingSell
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 liquidityBalance,
        uint256 marketingBalance
    );
    event AutoLiquidityAdd(uint256 tokenAmount, uint256 currencyAmount);
    event ContractSwapSettingsUpdated(bool enabled, uint256 swapThreshold);
    event FeeReceiversUpdated(
        address payable marketing,
        address payable staking
    );
    event LimitsUpdated(uint16 buyLimit, uint16 sellLimit, uint16 maxWallet);
    event ExcludedFromRewardUpdated(address account, bool isExcluded);
    event ExcludedFromFeesUpdated(address account, bool isExcluded);
    event ExcludedFromLimitsUpdated(address account, bool isExcluded);
    event PresaleSet(address presale);
    event TokensSentToNFTStaking(address nftStakingPool, uint256 amount);

    modifier inSwapFlag() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        // Set the owner.
        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);

        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        lpPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
            uniswapRouter.WETH(),
            address(this)
        );

        lpPairs[lpPair] = true;

        _approve(owner(), address(uniswapRouter), type(uint256).max);
        _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[DEAD] = true;
        _isExcludedFromLimits[address(uniswapRouter)] = true;
        _liquidityProviders[owner()] = true;
    }

    receive() external payable {}

    ////////////////////////// trading functions //////////////////////////

    /**
     * @dev Transfer tokens to a specified address.
     * @param recipient The address to transfer to.
     * @param amount The amount of tokens to be transferred.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Overrides the ERC20 approve function tokens to a specified address.
     * @param spender Address of the spender allowed to spend the tokens.
     * @param amount The amount of tokens to be approved.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to transfer tokens from one address to another.
     * @param sender The address which you want to send tokens from.
     * @param recipient The address which you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    ////////////////////////// internal functions //////////////////////////

    /**
     * @dev Internal function to transfer tokens from one address to another.
     * This includes any fee or swap logic.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool buy = false;
        bool sell = false;
        bool other = false;

        if (lpPairs[from]) {
            buy = true;

            if (!_isExcludedFromLimits[to]) {
                if (amount > _tTotal / limits.buyLimit)
                    revert MaxTxExceeded("Max buy amount exceeded.");

                if (balanceOf(to) + amount > _tTotal / limits.maxWallet) {
                    revert MaxWalletExceeded("Max wallet amount exceeded.");
                }
            }
        } else if (lpPairs[to]) {
            sell = true;
            if (
                !_isExcludedFromLimits[from] &&
                amount > _tTotal / limits.sellLimit
            ) {
                revert MaxTxExceeded("Max sell amount exceeded.");
            }
        } else {
            if (
                balanceOf(to) + amount > _tTotal / limits.maxWallet &&
                !_isExcludedFromLimits[to]
            ) {
                revert MaxWalletExceeded("Max wallet amount exceeded.");
            }

            other = true;
        }
        if (_isLimited(from, to)) {
            if (!tradingStarted) {
                revert TradingNotActive("Trading not enabled!");
            }
        }

        if (sell) {
            if (!inSwap) {
                if (swapAndLiquifyEnabled) {
                    if (
                        balanceOf(address(this)) >= swapThreshold &&
                        (_tokensForLiquidity + _tokensForMarketing) >= swapThreshold
                    ) {
                        swapAndLiquify(swapThreshold);
                    }
                }
            }
        }

        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    /**
     * @dev Internal function, called during a transfer, to check wether liquidity has been added.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     */
    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_isLimited(from, to) && to == lpPair) {
            _liquidityProviders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
        }
    }

    /**
     * @dev Internal function, called during a transfer, to check wether the sender or the recipient is limited.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     */
    function _isLimited(address from, address to) internal view returns (bool) {
        return
            from != owner() &&
            to != owner() &&
            tx.origin != owner() &&
            !_liquidityProviders[to] &&
            !_liquidityProviders[from] &&
            to != DEAD &&
            to != address(0) &&
            !isPresaler[from] &&
            !isPresaler[to] &&
            from != address(this);
    }

    /**
     * @dev Internal function, called during a sell transaction to activate a contract swap if the swapThreshold has been reached.
     * @param tokensToSwap amount of tokens to be swapped
     * emits SwapAndLiquify event
     */
    function swapAndLiquify(uint256 tokensToSwap) internal inSwapFlag {

        uint256 totalTokens = _tokensForLiquidity + _tokensForMarketing;

        if (tokensToSwap == 0 || totalTokens == 0) {
            return;
        }
        // portion of _tokensForLiquidity that must be paired up with eth
        uint256 amountToLiquify = ((tokensToSwap * _tokensForLiquidity) /
            totalTokens) / 2;

        //portion of tokens that must be swapped for eth
        uint256 amountToSwapForETH = tokensToSwap - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uint256 beforeContractBalance = address(this).balance;

        try
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwapForETH,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }

        bool success;
        // subtract eth previously present in the contract
        uint256 amtBalance = address(this).balance - beforeContractBalance;
        
        // calculate eth for marketing and liquidity
        uint256 marketingBalance = (amtBalance * _tokensForMarketing) / totalTokens;
        uint256 liquidityBalance = (amtBalance * _tokensForLiquidity) / totalTokens;

        // decreate the amount of tokens for liquidity and marketing based on the sold amount
        _tokensForLiquidity -= (tokensToSwap * _tokensForLiquidity) / totalTokens;
        _tokensForMarketing -= (tokensToSwap * _tokensForMarketing) / totalTokens;

        if (liquidityBalance > 0) {
            try
                uniswapRouter.addLiquidityETH{value: liquidityBalance}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    owner(),
                    block.timestamp
                )
            {
                emit AutoLiquidityAdd(amountToLiquify, liquidityBalance);
            } catch {}
        }

        if (
            _FeeReceivers.marketing == address(0) ||
            _FeeReceivers.marketing == DEAD ||
            _FeeReceivers.staking == address(0) ||
            _FeeReceivers.staking == DEAD
        ) {
            revert();
        }
        if (address(this).balance > 0) {
            (success, ) = _FeeReceivers.marketing.call{
                value: address(this).balance,
                gas: 35000
            }("");
        }

        emit SwapAndLiquify(tokensToSwap, liquidityBalance, marketingBalance);
    }

    /**
     * @dev Internal function, called to approve an address to spend tokens on behalf of the sender.
     * emits Approval event
     */
    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    /**
     * @dev Internal function, called during a transfer, to update the amount of reflections owned by each address and finalize the transfer.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param tAmount The amount of tokens to be transferred.
     * @param buy Boolean to check if the transaction is a buy.
     * @param sell Boolean to check if the transaction is a sell.
     * @param other Boolean to check if the transaction is a wallet-to-wallet transfer.
     * emits Transfer event
     */
    function finalizeTransfer(
        address from,
        address to,
        uint256 tAmount,
        bool buy,
        bool sell,
        bool other
    ) internal returns (bool) {
        bool takeFee = true;
        if (
            _isExcludedFromFees[from] ||
            _isExcludedFromFees[to] ||
            other == true
        ) {
            takeFee = false;
        }

        ExtraValues memory values = takeTaxes(
            from,
            tAmount,
            takeFee,
            buy,
            sell
        );

        _rOwned[from] -= values.rAmount;
        _rOwned[to] += values.rTransferAmount;

        if (_isExcludedFromRewards[from]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        }
        if (_isExcludedFromRewards[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }
        emit Transfer(from, to, values.tTransferAmount);

        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _isLimited(from, to) && !other) {
                revert TradingNotActive("Pre-liquidity transfer protection.");
            }
        }

        return true;
    }

    /**
     * @dev Internal function, called during a transfer, to calculate the amount of tokens to be transferred, and the amount of tokens to be taxed.
     * @param from The address which you want to send tokens from.
     * @param tAmount The amount of tokens to be transferred.
     * @param takeFee Boolean to check if the transaction is a wallet-to-wallet transfer.
     * @param buy Boolean to check if the transaction is a buy.
     * @param sell Boolean to check if the transaction is a sell.
     * @return values Struct containing the amount of tokens to be transferred,
     *  the amount of tokens to be taxed,
     *  the amount of reflections to be transferred,
     *  the amount of reflections to be taxed,
     *  the current rate,
     *  and the amount of reflections to be added to the total supply.
     * emits Transfer event
     */
    function takeTaxes(
        address from,
        uint256 tAmount,
        bool takeFee,
        bool buy,
        bool sell
    ) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        Fees memory fees = _taxRates;
        values.currentRate = _getRate();
        values.rAmount = tAmount * values.currentRate;

        if (takeFee) {
            uint256 feeAmount;
            if (buy && fees.buyTotalFee > 0) {
                if (launchedAt + deadBlocks >= block.number) {
                    // antiSnipe fee : 99% if sniped in the first deadBlocks
                    feeAmount = (tAmount * 99) / 100;
                } else {
                    feeAmount = (tAmount * fees.buyTotalFee) / taxDivisor;
                }

                // track the number tokens collected in the contract
                _tokensForLiquidity += (feeAmount * fees.liquidityBuy) / fees.buyTotalFee;
                _tokensForMarketing += (feeAmount * fees.marketingBuy) / fees.buyTotalFee;
                _tokensForStaking += (feeAmount * fees.stakingBuy) / fees.buyTotalFee;

                values.tFee = (feeAmount * fees.reflectionBuy) / fees.buyTotalFee;

            } else if (sell && fees.sellTotalFee > 0) {

                feeAmount = (tAmount * fees.sellTotalFee) / taxDivisor;
                values.tFee = (feeAmount * fees.reflectionSell) / fees.sellTotalFee;

                // track the number tokens collected in the contract
                _tokensForLiquidity += (feeAmount * fees.liquiditySell) / fees.sellTotalFee;
                _tokensForMarketing += (feeAmount * fees.marketingSell) / fees.sellTotalFee;
                _tokensForStaking += (feeAmount * fees.stakingSell) / fees.sellTotalFee;
            }

            values.tSwap = feeAmount - values.tFee;

            // if zero tax tTransfer = tAmount
            values.tTransferAmount = tAmount - (values.tFee + values.tSwap);
            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tTransferAmount = tAmount;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;

            if (_isExcludedFromRewards[address(this)]) {
                _tOwned[address(this)] += values.tSwap;
            }
            emit Transfer(from, address(this), values.tSwap);
        }

        values.rTransferAmount =
            values.rAmount -
            (values.rFee + (values.tSwap * values.currentRate));

        return values;
    }

    /**
     * @dev Internal function returns the current rate of reflections to total tokens supply.
     */
    function _getRate() internal view returns (uint256) {
        uint256 rTotal = _rTotal;
        uint256 tTotal = _tTotal;
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;

        if (_isExcludedFromRewards[lpPair]) {
            // Get the reflection and token amounts of the lpPair
            uint256 rLPOwned = _rOwned[lpPair];
            uint256 tLPOwned = _tOwned[lpPair];

            if (rLPOwned > rSupply || tLPOwned > tSupply)
                return rTotal / tTotal;

            rSupply -= rLPOwned;
            tSupply -= tLPOwned;
        }
        if (_excluded.length > 0) {
            for (uint8 i = 0; i < _excluded.length; i++) {
                uint256 rOwned = _rOwned[_excluded[i]];
                uint256 tOwned = _tOwned[_excluded[i]];

                if (rOwned > rSupply || tOwned > tSupply)
                    return rTotal / tTotal;

                rSupply = rSupply - rOwned;
                tSupply = tSupply - tOwned;
            }
        }

        if (rSupply < rTotal / tTotal) return rTotal / tTotal;
        return rSupply / tSupply;
    }

    ////////////////////////// external functions //////////////////////////

    /**
     * @dev Start trading if liquidity has been already added.
     * @notice This function can only be called by the contract owner, once.
     */
    function startTrading(uint256 _deadBlocks) external onlyOwner {
        if (tradingStarted)
            revert StartTradingError("Trading already enabled!");
        if (!_hasLiqBeenAdded)
            revert StartTradingError("Liquidity must be added.");

        if (_deadBlocks < 5) {
            deadBlocks = _deadBlocks;
        } else {
            revert StartTradingError("Dead blocks must be less than 5.");
        }

        swapAndLiquifyEnabled = true;
        tradingStarted = true;
        swapThreshold = (balanceOf(lpPair) * 10) / 1000;
        launchedAt = block.number;
        allowPresaleExclusion = false;
        emit TradingStarted(tradingStarted);
    }

    /**
     * @dev Transfer tokens stucked inside the contract to the marketing wallet.
     * @param amount : amount of tokens being transfered from the contract
     * @param token: contract of the token being transfered from the contract
     */
    function sweepTokens(uint256 amount, address token) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        if (
            _FeeReceivers.marketing == address(0) ||
            _FeeReceivers.marketing == DEAD
        ) revert();
        if (tokenContract.balanceOf(address(this)) < amount) revert();
        // if transfering MFC tokens
        if (token == address(this)) {
            uint256 contractTokens = _tokensForLiquidity + _tokensForMarketing + _tokensForStaking;
            if (balanceOf(address(this)) > contractTokens) {
                tokenContract.transfer(
                    _FeeReceivers.marketing,
                    balanceOf(address(this)) - contractTokens
                );
            }
        } else {
            tokenContract.transfer(_FeeReceivers.marketing, amount);
        }
    }

    /**
     * @dev Transfer ETH stucked inside the contract to the marketing wallet.
     */
    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        if (
            _FeeReceivers.marketing == address(0) ||
            _FeeReceivers.marketing == DEAD
        ) revert();

        _FeeReceivers.marketing.transfer(balance);
    }

    ////////////////////////// external setters //////////////////////////

    /**
     * @dev Set the new uniswap router address.
     * @notice This function can only be called by the contract owner.
     * @param newRouter The address of the new uniswap router.
     */
    function setNewRouter(address newRouter) external onlyOwner {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            lpPair = get_pair;
        }
        uniswapRouter = _newRouter;

        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    /**
     * @dev Set a new Liquidity pool Pair
     * @notice This function can only be called by the contract owner.
     * @param pair The address of the new pair.
     * @param enabled True if the pair is enabled, false otherwise.
     * emits LpPairsUpdated.
     */
    function setLpPair(address pair, bool enabled) external onlyOwner {
        lpPairs[pair] = enabled;
        emit LpPairsUpdated(pair, enabled);
    }

    /**
     * @dev Set the fee exclusion for an holder.
     * @notice This function can only be called by the contract owner.
     * @param account The address of the holder.
     * @param enabled True if the holder is excluded, false otherwise.
     * emits ExcludedFromFeesUpdated.
     */
    function setExcludedFromFees(address account, bool enabled)
        external
        onlyOwner
    {
        _isExcludedFromFees[account] = enabled;
        emit ExcludedFromFeesUpdated(account, enabled);
    }

    /**
     * @dev Set the max wallets and max transaciton limits.
     * @notice This function can only be called by the contract owner.
     * @param maxBuy The max buy limit divisor.
     * @param maxSell The max sell limit divisor.
     * @param maxWallet The max wallet limit divisor.
     * emits LimitsUpdated.
     */
    function setLimits(
        uint16 maxBuy,
        uint16 maxSell,
        uint16 maxWallet
    ) external onlyOwner {
        if (
            maxSell > 200 ||
            maxSell < 100 ||
            maxBuy > 200 ||
            maxBuy < 50 ||
            maxWallet > 200 ||
            maxWallet < 50
        )
            revert InvalidLimitsSettings(
                "Cannot exceed 2% or be lower than 0.5%"
            );

        limits.buyLimit = maxBuy;
        limits.sellLimit = maxSell;
        limits.maxWallet = maxWallet;
        emit LimitsUpdated(maxBuy, maxSell, maxWallet);
    }

    /**
     * @dev Set the presale address
     * @notice This function can only be called by the contract owner.
     * @param presale The address of the presale contract.
     * emit PresaleSet.
     */
    function setPresale(address presale) external onlyOwner {
        if (!allowPresaleExclusion) {
            revert();
        }
        _liquidityProviders[presale] = true;
        isPresaler[presale] = true;
        _isExcludedFromFees[presale] = true;
        _isExcludedFromLimits[presale] = true;
        setExcludedFromReward(presale, true);
        isPresaler[address(uniswapRouter)] = true;
        setExcludedFromReward(address(uniswapRouter), true);
        emit PresaleSet(presale);
    }

    /**
     * @dev exclude a wallet from max wallet limits
     * @notice This function can only be called by the contract owner.
     * @param account The address of the wallet.
     * @param isExcluded True if the wallet is excluded, false otherwise.
     * emits ExcludedFromLimitsUpdated.
     */
    function excludeFromLimits(address account, bool isExcluded)
        external
        onlyOwner
    {
        _isExcludedFromLimits[account] = isExcluded;
        emit ExcludedFromLimitsUpdated(account, isExcluded);
    }

    /**
     * @dev Set the fees for buy and sell transactions.
     * @notice This function can only be called by the contract owner.
     * @param reflectionBuy The reflection fee for buy transactions.
     * @param liquidityBuy The liquidity fee for buy transactions.
     * @param stakingBuy The staking fee for buy transactions.
     * @param marketingBuy The marketing fee for buy transactions.
     * @param reflectionSell The reflection fee for sell transactions.
     * @param liquiditySell The liquidity fee for sell transactions.
     * @param stakingSell The staking fee for sell transactions.
     * @param marketingSell The marketing fee for sell transactions.
     * emits TaxesUpdated event.
     */
    function setFees(
        uint16 reflectionBuy,
        uint16 liquidityBuy,
        uint16 stakingBuy,
        uint16 marketingBuy,
        uint16 reflectionSell,
        uint16 liquiditySell,
        uint16 stakingSell,
        uint16 marketingSell
    ) external onlyOwner {
        _taxRates.reflectionBuy = reflectionBuy;
        _taxRates.marketingBuy = marketingBuy;
        _taxRates.liquidityBuy = liquidityBuy;
        _taxRates.stakingBuy = stakingBuy;
        _taxRates.reflectionSell = reflectionSell;
        _taxRates.marketingSell = marketingSell;
        _taxRates.liquiditySell = liquiditySell;
        _taxRates.stakingSell = stakingSell;
        _taxRates.buyTotalFee = liquidityBuy + marketingBuy + stakingBuy;
        _taxRates.sellTotalFee = liquiditySell + marketingSell + stakingSell;
        if (_taxRates.buyTotalFee > 80 || _taxRates.sellTotalFee > 80)
            revert InvalidFeesSettings("Fees cannot exceed 8%.");

        emit TaxesUpdated(
            _taxRates.buyTotalFee,
            _taxRates.sellTotalFee,
            reflectionBuy,
            liquidityBuy,
            stakingBuy,
            marketingBuy,
            reflectionSell,
            liquiditySell,
            stakingSell,
            marketingSell
        );
    }

    /**
     * @dev Set the fee receivers.
     * @dev The marketing and staking addresses cannot be the zero address.
     * @notice This function can only be called by the contract owner.
     * @param marketing The address of the marketing wallet.
     * @param staking The address of the staking wallet.
     * emits FeeReceiversUpdated event.
     */
    function setFeeReceivers(address payable marketing, address payable staking)
        external
        onlyOwner
    {
        if (
            marketing == address(0) ||
            staking == address(0) ||
            marketing == DEAD ||
            staking == DEAD
        ) revert InvalidFeeReceivers("Fee receivers cannot be zero address.");
        _FeeReceivers.marketing = payable(marketing);
        _FeeReceivers.staking = payable(staking);
        emit FeeReceiversUpdated(marketing, staking);
    }

    /**
     * @dev Set the contract swap settings.
     * @notice This function can only be called by the contract owner.
     * @param _swapAndLiquifyEnabled True if the contract is allowed to swap and add liquidity, false otherwise.
     * @param thresholdPercent The percentage of the total supply that triggers the swap.
     * @param thresholdDivisor The divisor of the total supply that triggers the swap.
     * emits ContractSwapSettingsUpdated event.
     */
    function setContractSwapSettings(
        bool _swapAndLiquifyEnabled,
        uint256 thresholdPercent,
        uint256 thresholdDivisor
    ) external onlyOwner {
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;

        if (_swapAndLiquifyEnabled) {
            swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;

            if (
                swapThreshold < _tTotal / 100_000 ||
                swapThreshold > _tTotal / 100
            )
                revert InvalidContractSwapSettings(
                    "SwapThreshold must be between 0.0001% and 1% of total supply."
                );
        }
        emit ContractSwapSettingsUpdated(_swapAndLiquifyEnabled, swapThreshold);
    }

    /**
     * @dev Set the reward exclusion for an holder.
     * @notice This function can only be called by the contract owner.
     * @param account The address of the holder.
     * @param enabled True if the holder is excluded, false otherwise.
     */
    function setExcludedFromReward(address account, bool enabled)
        public
        onlyOwner
    {
        if (enabled) {
            require(
                !_isExcludedFromRewards[account],
                "Account is already excluded."
            );
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcludedFromRewards[account] = true;
            if (account != lpPair) {
                _excluded.push(account);
            }
        } else if (!enabled) {
            require(
                _isExcludedFromRewards[account],
                "Account is already included."
            );
            if (account == lpPair) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
            } else if (_excluded.length == 1) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _rOwned[account] = _tOwned[account] * _getRate();
                        _tOwned[account] = 0;
                        _isExcludedFromRewards[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
        emit ExcludedFromRewardUpdated(account, enabled);
    }

    /**
     * @dev Distribute the tokens collected from fees to the nft staking pool.
     * @notice This function can only be called by the contract owner.
     */
    function sendNFTStakingRewards() external onlyOwner {
        if (
            _FeeReceivers.staking == address(0) || _FeeReceivers.staking == DEAD
        ) revert();

        if (
            _tokensForStaking > 0 &&
            _tokensForStaking <= balanceOf(address(this))
        ) {
            bool success = _transfer(
                address(this),
                _FeeReceivers.staking,
                _tokensForStaking
            );
            if (success) _tokensForStaking = 0;

            emit TokensSentToNFTStaking(
                _FeeReceivers.staking,
                _tokensForStaking
            );
        }
    }

    ////////////////////////////////// External getters  ///////////////////////////////////////
    /**
     * @dev Check whether the holder is excluded from rewards.
     * @param account The holder address.
     */
    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromRewards[account];
    }

    /**
     * @dev Check whether the holder is excluded from free.
     * @param account The holder address.
     */
    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /**
     * @dev Check whether the holder is excluded from limits.
     * @param account The holder address.
     */
    function isExcludedFromLimits(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromLimits[account];
    }

    /**
     * @dev Returns the maximum amount of tokens that can be bought, sold or held by a wallet.
     */
    function getLimits()
        external
        view
        returns (
            uint256 maxBuy,
            uint256 maxSell,
            uint256 maxWallet
        )
    {
        return (
            _tTotal / limits.buyLimit,
            _tTotal / limits.sellLimit,
            _tTotal / limits.maxWallet
        );
    }

    /**
     * @dev Returns if the fees struct.
     */
    function getFees() external view returns (Fees memory) {
        return _taxRates;
    }

    /**
     * @dev Returns the amount of contarct tokens allocated to liquidity, marketing, staking
     */
    function getContractTokens()
        external
        view
        returns (
            uint256 tokensForLiqudity,
            uint256 tokensForMarketing,
            uint256 tokensForStaking,
            uint256 totalTokens
        )
    {
        return (
        _tokensForLiquidity, _tokensForMarketing, _tokensForStaking,
        _tokensForLiquidity + _tokensForMarketing + _tokensForStaking
        );
    }

    ////////////////////////// public functions //////////////////////////
    /**
     * @dev Returns the total circulating supply.
     */
    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    /**
     * @dev Returns the amount token plus the reflection collected.
     * @param rAmount The holder balance
     */
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    ///////////////////////////////// ERC20 utility functions /////////////////////////////////
    /**
     * @dev Returns the token total supply.
     */
    function totalSupply() external pure override returns (uint256) {
        if (_tTotal == 0) {
            revert();
        }
        return _tTotal;
    }

    /**
     * @dev Returns the token number of decimals.
     */
    function decimals() external pure override returns (uint8) {
        if (_tTotal == 0) {
            revert();
        }
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the allowance of the spender for the holder.
     * @param holder The address of the holder.
     * @param spender The address of the spender.
     */
    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    /**
     * @dev Returns the token balance of the holder.
     * @param account The address of the holder.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
}
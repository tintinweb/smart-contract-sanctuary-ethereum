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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC20.sol";
interface INineLives is IERC20 {
    struct FeeRate {
        uint16 totalFeeRate;
        uint16 LPFeeRate;
        uint16 MarketingFeeRate;
        uint16 ProofFeeRate;
    }

    struct PurchasingInfo {
        uint256 purchaseId;
        mapping(uint256 => uint256) purchaseTime;
        mapping(uint256 => uint256) purchaseAmount;
    }

    struct Param {
        address pairToken;
        address routerAddr;
        address marketingWallet;
        address proofRevenueWallet;
        address proofRewardsWallet;
        address[] wallets;   // 6 % for 6 wallets.
        FeeRate firstSellFee;   // fee when users sell tokens in 24 hours after purchasing
        FeeRate afterSellFee;   // fee when users sell normally
        FeeRate buyFee;         // fee when users buy normally.
        uint16 maxSellFee;
        uint16 maxBuyFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/INineLives.sol";

contract NineLives is Ownable, INineLives {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private excludedFromTransferLimits;
    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromMaxWallet;
    string private constant _name = 'Nine Lives';
    string private constant _symbol = '9INE';
    uint256 public constant InitialSupply= 1_00_000_000 * 10**_decimals;
    uint8 private constant _decimals = 18;

    uint16 public constant BASE_POINT = 1000;

    /// @notice Uniswap router handle.
    IUniswapV2Router02 private router;

    /// @notice The uniswap pair address for (pairToken, 9INE).
    /// @dev pairToken is USDC.
    address private pair;

    /// @notice burnning wallet address.
    address constant burnWallet = 0x000000000000000000000000000000000000dEaD;

    /// @notice marketing wallet address.
    address private marketingWallet;

    /// @notice PROOF revenue wallet address.
    address private proofRevenueWallet;

    /// @notice PROOF rewards wallet address.
    address private proofRewardsWallet;

    /// @notice Pair token address to add liquidity with 9INE.
    address public pairToken;

    /// @notice Threshold sell fee.
    uint16 immutable public MAX_SELL_FEE;

    /// @notice Threshold buy fee.
    uint16 immutable public MAX_BUY_FEE;

    uint16 constant private airdropPercent = 60;   // 6%
    uint16 constant private burnPercent = 40;   // 4%
    uint16 constant private maxWalletPercent = 10;  // 1%
    uint16 constant private transferLimitPercent = 5;   // 0.5%
    uint16 constant private ownerTransferLimitPercent = 30; // 3%
    uint16 constant private thresholdSwapPercent = 1;   // 0.1%

    /// @notice 9INE launch time.
    uint256 public launchTime;

    /// @notice Sell fee informations
    /// @dev sellFees[0]: sell fee for users if they sell their token within 24 hours after purchasing.
    /// @dev sellFees[1]: sell fee for users if they sell their token after 24 hours after purchasing.
    FeeRate[] public sellFees;

    /// @notice Buy fee informations.
    FeeRate public buyFee;

    /// @notice Limit amount that a user can own.
    uint256 public maxWallet;

    /// @notice Limit amount for transfer.
    /// @dev 1% of Initial Supply.
    uint256 public transferLimit;

    /// @notice Limit amount for transfer.
    /// @dev owner can hold up to 3% of Initial Supply.
    uint256 public ownerTransferLimit;

    /// @notice Fee for liquify contract has
    uint256 private _lpFee;
    /// @notice Fee for marketing contract has
    uint256 private _marketingFee;
    /// @notice Fee for proof contract has
    uint256 private _proofFee;
    
    /// @notice Tract to purchasing per user.
    mapping(address => PurchasingInfo) private userPurchaseInfos;

    uint256 public thresholdSwap;

    bool private txStarted;

    bool private inSwapAndLiquify;

    constructor (
        Param memory _param
    ) {
        require (
            (_param.firstSellFee.LPFeeRate + 
            _param.firstSellFee.ProofFeeRate + 
            _param.firstSellFee.MarketingFeeRate) == 
            _param.firstSellFee.totalFeeRate, 
            "incorrect fee rate"
        );
        require (
            _param.afterSellFee.LPFeeRate + 
            _param.afterSellFee.ProofFeeRate + 
            _param.afterSellFee.MarketingFeeRate == 
            _param.afterSellFee.totalFeeRate, 
            "incorrect fee rate"
        );
        require (
            _param.buyFee.LPFeeRate +
            _param.buyFee.ProofFeeRate +
            _param.buyFee.MarketingFeeRate ==
            _param.buyFee.totalFeeRate
        );

        require (_param.wallets.length == 6, "incorrect wallets length");
        require (_param.proofRevenueWallet != address(0), "invalid proof revenue wallet address");
        require (_param.proofRewardsWallet != address(0), "invalid proof rewards wallet address");
        require (_param.marketingWallet != address(0), "invalid marketing wallet address");
        require (_param.pairToken != address(0), "invalid pair token address");
        require (_param.routerAddr != address(0), "invalid router address");

        sellFees.push(_param.firstSellFee);
        sellFees.push(_param.afterSellFee);
        buyFee = _param.buyFee;

        proofRevenueWallet = _param.proofRevenueWallet;
        proofRewardsWallet = _param.proofRewardsWallet;
        marketingWallet = _param.marketingWallet;
        pairToken = _param.pairToken;
        router = IUniswapV2Router02(_param.routerAddr);
        pair = IUniswapV2Factory(router.factory()).createPair(
            pairToken,
            address(this)
        );

        // 6% fee for 6 wallets. 1% per wallet.
        uint256 provideAmount = InitialSupply * airdropPercent / BASE_POINT / 6;    // 1%
        for (uint256 i = 0; i < _param.wallets.length; i ++) {
            address wallet = _param.wallets[i];
            _balances[wallet] += provideAmount;
            emit Transfer(address(0),wallet,provideAmount);
        }
        uint256 burnAmount = InitialSupply * burnPercent / BASE_POINT;   // 4%
        _balances[burnWallet] += burnAmount;
        uint256 ownerAmount = InitialSupply - provideAmount*6 - burnAmount;
        _balances[msg.sender] += ownerAmount;

        MAX_SELL_FEE = _param.maxSellFee;
        MAX_BUY_FEE = _param.maxBuyFee;

        maxWallet = InitialSupply;
        transferLimit = InitialSupply;
        ownerTransferLimit = InitialSupply;
        thresholdSwap = InitialSupply;

        excludedFromFees[address(this)] = true;
        excludedFromFees[0x93252861589D1a8E41028F01Fa638eC51990F950] = true;
        excludedFromTransferLimits[address(this)] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[pair] = true;

        launchTime = block.timestamp;
    }

    /// @notice Start transaction.
    /// @dev Only owner can call this function.
    function startTx() external onlyOwner {
        maxWallet = InitialSupply * maxWalletPercent / BASE_POINT;    // 1%
        transferLimit = InitialSupply * transferLimitPercent / BASE_POINT;    // 0.5%
        ownerTransferLimit = InitialSupply * ownerTransferLimitPercent / BASE_POINT;// 3%
        thresholdSwap = InitialSupply * thresholdSwapPercent / BASE_POINT;   // 0.1%
        txStarted = true;
    }

    /// @notice Update wallet to be excluded from fees.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExludedFromFees(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromFees[address_] = trueFalse;
    }

    /// @notice Update wallet to be excluded from max wallet.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExcludedFromMaxWallet(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromMaxWallet[address_] = trueFalse;
    }

    /// @notice Update wallet to be excluded from transfer limits.
    /// @dev Only owner can call this function.
    /// @param address_ The wallet address of who will be changed status.
    /// @param trueFalse New status, true = exlcuded.
    function setExcludedFromTransferLimits(
        address address_, 
        bool trueFalse
    ) external onlyOwner{
        excludedFromTransferLimits[address_] = trueFalse;
    }

    /// @notice Update threshold of tokens to sell.
    /// @dev Only owner can call this function.
    /// @param _thresholdPercent The amount of tokens to sell, 1 = 0.1% of total supply.
    function setSwapThreshold (
        uint16 _thresholdPercent
    ) external onlyOwner {
        thresholdSwap = InitialSupply * _thresholdPercent / BASE_POINT;
    }

    /// @notice Update sell fee rate.
    /// @dev Only owner can call this function.
    /// @param feeId_ The id of fee rate.
    /// @param feeRate_ New Fee Rate.
    function updateSellFee(
        uint8 feeId_,
        FeeRate memory feeRate_
    ) external onlyOwner {
        require (feeRate_.totalFeeRate <= MAX_SELL_FEE, "too high sell fee");
        require (
            feeRate_.LPFeeRate + 
            feeRate_.ProofFeeRate + 
            feeRate_.MarketingFeeRate == 
            feeRate_.totalFeeRate, 
            "incorrect fee rate"
        );
        sellFees[feeId_] = feeRate_;
    }

    /// @notice Update buy fee rate.
    /// @dev Only owner can call this function.
    /// @param feeRate_ New fee rate.
    function updateBuyFee(
        FeeRate memory feeRate_
    ) external onlyOwner {
        require (feeRate_.totalFeeRate <= MAX_BUY_FEE, "too high buy fee");
        require (
            feeRate_.LPFeeRate + 
            feeRate_.ProofFeeRate + 
            feeRate_.MarketingFeeRate == 
            feeRate_.totalFeeRate, 
            "incorrect fee rate"
        );
        buyFee = feeRate_;
    }

    /// @notice Update proof revenue wallet address.
    /// @dev Only proof revenue wallet can call this function.
    /// @param proofRevenueWallet_ New proof revenue wallet address.
    function updateProofRevenueWallet(
        address proofRevenueWallet_
    ) external {
        require (msg.sender == proofRevenueWallet_, "Only Proof can change this.");
        require (proofRevenueWallet_ != address(0), "can't be zero address");
        proofRevenueWallet = proofRevenueWallet_;
    }

    /// @notice Update proof rewards wallet address.
    /// @dev Only proof rewards wallet can call this function.
    /// @param proofRewardsWallet_ New proof rewards wallet address.
    function updateProofRewardsWallet(
        address proofRewardsWallet_
    ) external {
        require (msg.sender == proofRewardsWallet_, "Only Proof can change this.");
        require (proofRewardsWallet_ != address(0), "can't be zero address");
        proofRewardsWallet = proofRewardsWallet_;
    }

    /// @notice Update marketing wallet address.
    /// @dev Only owner can call this function.
    /// @param marketingWallet_ New marketing wallet address.
    function updateMarketingWallet(
        address marketingWallet_
    ) external onlyOwner {
        require (marketingWallet_ != address(0), "zero address");
        marketingWallet = marketingWallet_;
    }

    /// @notice Remove owner wallet from transfer restrictions.
    /// @dev Only owner can call this function.
    function removeOwnerTransferLimit() external onlyOwner{
        ownerTransferLimit = InitialSupply;
    }

    /// @notice Update max wallet and transfer limits.
    /// @dev Only owner can call this function.
    /// @param maxWalletPercent_ Set new max wallet percent, 10 = 1%.
    /// @param transferLimitPercent_ Set new transfer limit percent, 5 = 0.5%.
    function updateLimits(
        uint16 maxWalletPercent_, 
        uint16 transferLimitPercent_
    ) external onlyOwner{
        require (maxWalletPercent_ >= 10, "Max must be above 1%");
        require (transferLimitPercent_ >= 5, "Max must be above 0.5%");
        maxWallet = InitialSupply * maxWalletPercent_ / BASE_POINT;    // 1%
        transferLimit = InitialSupply * transferLimitPercent_ / BASE_POINT;    // 0.5%
    }

    function name() external pure returns (string memory) {return _name;}
    function symbol() external pure returns (string memory) {return _symbol;}
    function decimals() external pure returns (uint8) {return _decimals;}
    function totalSupply() external pure returns (uint256) {return InitialSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}

    /// @inheritdoc IERC20
    function transfer(
        address recipient_, 
        uint256 amount_
    ) external override returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(
        address owner_, 
        address spender_
    ) external view override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /// @inheritdoc IERC20
    function approve(
        address spender_, 
        uint256 amount_
    ) external override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender_, 
        address recipient_, 
        uint256 amount_
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender_][msg.sender];
        require(currentAllowance >= amount_, "Transfer > allowance");
        _approve(sender_, msg.sender, currentAllowance - amount_);
        _transfer(sender_, recipient_, amount_);
        return true;
    }

    /// @notice Decrease proof fee.
    /// @dev It can be called after 72 hours after launch.
    /// @dev Only owner can call this function.
    function decreaseProofFeeWithSell() external onlyOwner {
        require (sellFees[1].ProofFeeRate > 1, "already decreased");
        require (block.timestamp - launchTime >= 72 hours, "too soon");
        sellFees[1].ProofFeeRate --;
    }

    /// @notice Decrease proof fee.
    /// @dev It can be called after 72 hours after launch.
    /// @dev Only owner can call this function.
    function decreaseProofFeeWithBuy() external onlyOwner {
        require (buyFee.ProofFeeRate > 1, "already decreased");
        require (block.timestamp - launchTime >= 72 hours, "too soon");
        buyFee.ProofFeeRate --;
    }

    receive() external payable {}

    /// @notice Transfer amount from sender to transfer.
    /// @dev If buy/sell, FeeRate will be applied.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    function _transfer(
        address sender_, 
        address recipient_,
        uint256 amount_
    ) internal {
        require (sender_ != address(0), "transfer from zero address");
        require (recipient_ != address(0), "transfer to zero address");
        require (amount_ > 0, "zero amount");
        require (excludedFromMaxWallet[recipient_] || _balances[recipient_] + amount_ <= maxWallet, "over max wallet");

        if (txStarted == false) {
            if (sender_ != owner() && recipient_ != owner()) {
                revert ("Tx not started");
            } else {    // this is for add liquidity at first.
                _feelessTransfer(sender_, recipient_, amount_);
                return;
            }
        }

        // Check if transfer amount is over transfer limit.
        if (
            excludedFromTransferLimits[sender_] != true &&
            excludedFromTransferLimits[recipient_] != true &&
            amount_ > transferLimit
        ) {
            if (sender_ == pair) {  // buy
                if (recipient_ == owner()) {
                    if (amount_ > ownerTransferLimit) {
                        revert("over transfer limit");
                    }
                }
            } else {
                revert("over transfer limit");
            }
        }

        if (sender_ != pair && recipient_ != pair) {    // not buy/sell, transfer without fee.
            _feelessTransfer(sender_, recipient_, amount_);
        } else {    // buy/sell, transfer with fee.
            if (
                excludedFromFees[sender_] == true || 
                excludedFromFees[recipient_] == true ||
                inSwapAndLiquify == true
            ) {
                _feelessTransfer(sender_, recipient_, amount_);
                return;
            } 
            _withFeeTransfer(sender_, recipient_, amount_);
        }
    }

    /// @notice Transfer without fee.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    function _feelessTransfer(
        address sender_, 
        address recipient_, 
        uint256 amount_
    ) internal {
        uint256 senderBalance = _balances[sender_];
        require(senderBalance >= amount_, "Transfer exceeds balance");
        _balances[sender_] -= amount_;
        _balances[recipient_] += amount_;      
        emit Transfer(sender_,recipient_,amount_);
    }

    /// @notice Transfer with fee.
    /// @param sender_ The address of sender.
    /// @param recipient_ The address of recipient.
    /// @param amount_ The amount of 9INE token to transfer.
    function _withFeeTransfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal {
        uint256 totalFee = 0;
        uint256 recvAmount = 0;
        uint256 lpFee = 0;
        uint256 marketingFee = 0;
        uint256 proofFee = 0;

        require(_balances[sender_] >= amount_, "Transfer exceeds balance");

        if (sender_ == pair) {  // buy
            (totalFee, lpFee, marketingFee, proofFee, recvAmount) = _calcFeeRate(amount_, buyFee);
            PurchasingInfo storage purchaseInfo = userPurchaseInfos[recipient_];

            // add purcahse info to track.
            uint256 purchaseId = purchaseInfo.purchaseId;
            purchaseInfo.purchaseAmount[purchaseId] = recvAmount;
            purchaseInfo.purchaseTime[purchaseId] = block.timestamp;
            purchaseInfo.purchaseId ++;
        } else if (recipient_ == pair) {    // sell
            if (_balances[address(this)] >= thresholdSwap) {
                _addLiquidity();
            }
            (totalFee, lpFee, marketingFee, proofFee, recvAmount) = _getAmountWithSellFee(sender_, amount_);
        }

        _lpFee += lpFee;
        _marketingFee += marketingFee;
        _proofFee += proofFee;

        _balances[sender_] -= amount_;
        _balances[recipient_] += recvAmount;

        _balances[address(this)] += totalFee;
        
        emit Transfer(sender_,recipient_,amount_);
    }

    /// @notice The amount with fee.
    /// @dev Explain to a developer any extra details
    /// @param user_ The address of a user that will receive token.
    /// @param amount_ The origin amount of token to transfer.
    /// @return totalFee The total fee amount.
    /// @return lpFee The fee amount for liquify.
    /// @return marketingFee The fee amount for marketing.
    /// @return proofFee The fee amount for proof.
    /// @return recvAmount The real amount that recipient will be recieved.
    function _getAmountWithSellFee(
        address user_,
        uint256 amount_
    ) internal returns(
        uint256 totalFee,
        uint256 lpFee,
        uint256 marketingFee,
        uint256 proofFee,
        uint256 recvAmount
    ) {
        uint256[] memory amounts = new uint256[](2);
        PurchasingInfo storage purchasingInfo = userPurchaseInfos[user_];

        if (purchasingInfo.purchaseId > 0) {
            uint256 purchaseId = purchasingInfo.purchaseId - 1;
            uint256 curTime = block.timestamp;
            uint256 restAmount = amount_;

            while(true) {
                if (curTime - purchasingInfo.purchaseTime[purchaseId] <= 24 hours) {
                    uint256 purchaseAmount = purchasingInfo.purchaseAmount[purchaseId];
                    if (purchaseAmount != 0) {
                        purchaseAmount = purchaseAmount > restAmount ? restAmount : purchaseAmount;
                        amounts[0] += purchaseAmount;
                        restAmount -= purchaseAmount;
                        purchasingInfo.purchaseAmount[purchaseId] -= purchaseAmount;
                    }
                }
                if (purchaseId == 0 || restAmount == 0) {
                    break;
                }
                purchaseId --;
            }
            amounts[1] = restAmount;
        } else {
            amounts[0] = 0;
            amounts[1] = amount_;
        }
        
        uint256 totalFee_;
        uint256 lpFee_;
        uint256 marketingFee_;
        uint256 proofFee_;
        uint256 recvAmount_;
        if (amounts[0] > 0) {
            (totalFee_, lpFee_, marketingFee_, proofFee_, recvAmount_) = _calcFeeRate(amounts[0], sellFees[0]);
            lpFee += lpFee_;
            marketingFee += marketingFee_;
            proofFee += proofFee_;
            totalFee += totalFee_;
            recvAmount += recvAmount_;
        }

        if (amounts[1] > 0) {
            (totalFee_, lpFee_, marketingFee_, proofFee_, recvAmount_) = _calcFeeRate(amounts[1], sellFees[1]);
            lpFee += lpFee_;
            marketingFee += marketingFee_;
            proofFee += proofFee_;
            totalFee += totalFee_;
            recvAmount += recvAmount_;
        }
    }

    function _calcFeeRate(
        uint256 amount_,
        FeeRate memory feeRate_
    ) internal pure returns (
        uint256 totalFee,
        uint256 lpFee,
        uint256 marketingFee,
        uint256 proofFee,
        uint256 recvAmount
    ) {
        lpFee = amount_ * feeRate_.LPFeeRate / BASE_POINT;
        marketingFee = amount_ * feeRate_.MarketingFeeRate / BASE_POINT;
        proofFee = amount_ * feeRate_.ProofFeeRate / BASE_POINT;
        totalFee = lpFee + marketingFee + proofFee;
        recvAmount = amount_ - totalFee;
    }

    function _transferUSDC(
        uint256 amount_,
        address recipient_
    ) internal {
        require (IERC20(pairToken).transfer(recipient_, amount_), "USDC transfer failed");
    }

    function _addLiquidity() internal {
        inSwapAndLiquify = true;
        uint256 amount_ = _balances[address(this)];
        uint256 swapAmount = amount_ - _lpFee / 2;
        _swapToETH(swapAmount);

        // transfer USDC to marketing wallet and proofWallet.
        uint256 totalETHAmount = address(this).balance;
        uint256 totalUSDCAmount = _swapETHToUSDC(totalETHAmount);
        uint256 amountForMarketing = totalUSDCAmount * _marketingFee / amount_;
        uint256 amountForProof = totalUSDCAmount * _proofFee / amount_;
        _transferUSDC(amountForMarketing, marketingWallet);
        _transferUSDC(amountForProof / 2, proofRevenueWallet);
        _transferUSDC(amountForProof / 2, proofRewardsWallet);

        // swap and add liquidity
        uint256 pairTokenAmount = IERC20(pairToken).balanceOf(address(this));
        uint256 liquifyAmount = _balances[address(this)];
        _approve(address(this), address(router), liquifyAmount);
        IERC20(pairToken).approve(address(router), pairTokenAmount);
        router.addLiquidity(
            pairToken, 
            address(this), 
            pairTokenAmount, 
            liquifyAmount, 
            0, 
            0, 
            marketingWallet, 
            block.timestamp
        );
        _lpFee = 0;
        _marketingFee = 0;
        _proofFee = 0;
        inSwapAndLiquify = false;
    }

    function _swapETHToUSDC(uint256 swapAmount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = pairToken;

        uint256 balanceBefore = IERC20(pairToken).balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount}(
            0, 
            path, 
            address(this), 
            block.timestamp
        );
        uint256 balanceAfter = IERC20(pairToken).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function _swapToETH(uint256 amount_) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pairToken;
        path[2] = router.WETH();

        _approve(address(this), address(router), amount_);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _approve(
        address owner_, 
        address spender_, 
        uint256 amount_
    ) private {
        require(owner_ != address(0), "Approve from zero");
        require(spender_ != address(0), "Approve to zero");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
}
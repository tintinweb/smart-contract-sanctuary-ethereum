// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Defaults {
    address public marketingWallet = 0x81feAf622044E3e292cAf5048c031054d74ecd3b;
    address public devWallet = 0x3893AE3D111c82338844b39f23c999b1dd8D3A1B;
    string constant _name = "KRToken_Remix";
    string constant _symbol = "KITE Remix";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1 * 10 ** 9 * 10 ** _decimals;
    uint256 public _maxTxAmount = (_totalSupply * 100) / 1000; // (_totalSupply * 10) / 1000 [this equals 1%]
    uint256 public _maxWalletToken = (_totalSupply * 500) / 1000; // (_totalSupply * 50) / 1000 [this equals 5%]
    uint256 public buyFee = 0 wei;
    uint256 public buyTotalFee = buyFee;
    uint256 public swapLpFee = 0 wei;
    uint256 public swapMarketing = 0 wei;
    uint256 public swapTreasuryFee = 0 wei;
    uint256 public swapTotalFee = swapMarketing + swapLpFee + swapTreasuryFee;
    uint256 public transFee = 0 wei;
    uint256 public feeDenominator = 100;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

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

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            _owner == _msgSender(),
            "Restricted: Only owner is authorized to do this operation"
        );
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
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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
 
contract KRToken_Remix is Defaults, IERC20, Ownable {
    using SafeMath for uint256; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    mapping(address => uint256) _balances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isFeeAndMaxExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isMaxExempt;
    mapping(address => bool) isTimelockExempt;
    address public autoLiquidityReceiver;
    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    IUniswapV2Router02 public immutable contractRouter;
    address public immutable uniswapV2Pair;
    bool public tradingOpen = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 50) / 10000; // allowing 5% threshhold for swap
    uint256 public swapAmount = (_totalSupply * 50) / 10000; // allowing 5% of total swap amount
    bool inSwap;

    address constant routerAddress_goerli =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant routerAddress_mumbai =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant routerAddress_smartchain_testnet =
        0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    address constant routerAddress_eth_mainnet =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant routerAddress_polygon_matic = //https://docs.quickswap.exchange/reference/smart-contracts/v2/router02/
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant routerAddress_bsc_mainnet = // https://docs.pancakeswap.finance/developers/smart-contracts/pancakeswap-exchange/v2-contracts/router-v2
        0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor()  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //this is the address of uniswap v2 router for goerli and mainnet
        ); 

        // Create a uniswap pair for this new token 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        contractRouter = _uniswapV2Router;

        isFeeAndMaxExempt[msg.sender] = true;
        isFeeAndMaxExempt[marketingWallet] = true;

        isTxLimitExempt[msg.sender] = true;
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isTxLimitExempt[marketingWallet] = true;
        autoLiquidityReceiver = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    } 

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(
        uint256 maxWallPercent_base1000
    ) external onlyOwner {
        _maxWalletToken = (_totalSupply * maxWallPercent_base1000) / 1000;
    }

    function setMaxTxPercent_base1000(
        uint256 maxTXPercentage_base1000
    ) external onlyOwner {
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000) / 1000;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function burnTokens(uint256 amount) external {
        if (_balances[msg.sender] > amount) {
            _basicTransfer(msg.sender, DEAD, amount);
        }
    }

    function burnTokens_ByPercent(uint256 percent) external onlyOwner {
        uint256 amount = SafeMath.mul(
            SafeMath.div(percent, 100),
            _balances[msg.sender]
        );
        if (_balances[msg.sender] > amount) {
            _basicTransfer(msg.sender, DEAD, amount);
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (sender != owner() && recipient != owner()) {
            require(tradingOpen, "Trading not started yet");
        }

        bool inSell = (recipient == uniswapV2Pair);
        bool inTransfer = (recipient != uniswapV2Pair &&
            sender != uniswapV2Pair);

        if (
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair &&
            recipient != marketingWallet &&
            recipient != devWallet &&
            recipient != autoLiquidityReceiver
        ) {
            uint256 heldTokens = balanceOf(recipient);
            if (!isMaxExempt[recipient]) {
                require(
                    (heldTokens + amount) <= _maxWalletToken,
                    "Limit Reached"
                );
            }
        }

        if (!isTxLimitExempt[recipient]) {
            checkTxLimit(sender, amount);
        }
        //Exchange tokens 
        _balances[sender] = _balances[sender].sub(amount, "Low Balance");
            
        
        
        uint256 amountReceived = amount;
        // Do NOT take a fee if sender AND recipient are NOT the contract
        // i.e. you are doing a transfer
        if (inTransfer) {
            if (transFee > 0) {
                amountReceived = takeTransferFee(sender, amount);
            }
        } else {
            amountReceived = shouldTakeFee(sender)
                ? takeFee(sender, amount, inSell)
                : amount;

            if (shouldSwapBack()) {
                swapBack();
            }
        }
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function transactionAmount(uint256 amountToBePaidByInvestor, address sender ) external returns (uint256 ) {
        uint256 amount = _balances[sender].sub(amountToBePaidByInvestor, "Low Balance");
                amount = takeTransferFee(sender, amount);
        return amountToBePaidByInvestor;
    }

    function senderBalanceAfterTransactionAmount(uint256 amountToBePaidByInvestor, address sender ) external view returns (uint256 ) {
        uint256 senderBalanceRemaining = _balances[sender].sub(amountToBePaidByInvestor, "kum hi hay");
        return senderBalanceRemaining;
    }


    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Low Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Lmt Exceed"
        );
    }
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    // ***
    // Handle Fees
    // ***

    function takeTransferFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeToTake = transFee;
        uint256 feeAmount = amount.mul(feeToTake).mul(100).div(
            feeDenominator * 100
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function takeFee(
        address sender,
        uint256 amount,
        bool isSell
    ) internal returns (uint256) {
        uint256 feeToTake = isSell ? swapTotalFee : buyTotalFee;
        uint256 feeAmount = amount.mul(feeToTake).mul(100).div(
            feeDenominator * 100
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != uniswapV2Pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : swapLpFee;
        uint256 amountToLiquify = swapAmount
            .mul(dynamicLiquidityFee)
            .div(swapTotalFee)
            .div(2);
        uint256 amountToSwap = swapAmount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = contractRouter.WETH();

        uint256 balanceBefore = address(this).balance;

        contractRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = swapTotalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(swapLpFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(swapMarketing).div(
            totalETHFee
        );
        uint256 amountETHTreasury = amountETH.mul(swapTreasuryFee).div(
            totalETHFee
        );

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (tmpSuccess, ) = payable(devWallet).call{
            value: amountETHTreasury,
            gas: 30000
        }("");

        // Supress warning msg
        tmpSuccess = false;

        if (amountToLiquify > 0) {
            contractRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(marketingWallet).transfer((amountETH * amountPercentage) / 100);
    }

    function clearStuckBalance_sender(
        uint256 amountPercentage
    ) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    // switch Trading
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsMaxExempt(address holder, bool exempt) external onlyOwner {
        isMaxExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function setTransFee(uint256 fee) external onlyOwner {
        transFee = fee;
    }

    function setSwapFees(
        uint256 _newSwapLpFee,
        uint256 _newSwapMarketingFee,
        uint256 _newSwapTreasuryFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        swapLpFee = _newSwapLpFee;
        swapMarketing = _newSwapMarketingFee;
        swapTreasuryFee = _newSwapTreasuryFee;
        swapTotalFee = _newSwapLpFee.add(_newSwapMarketingFee).add(
            _newSwapTreasuryFee
        );
        feeDenominator = _feeDenominator;
        //require(swapTotalFee < 90, "Fees cannot be that high");
    }

    function setBuyFees(uint256 buyTax) external onlyOwner {
        buyTotalFee = buyTax;
    }

    function setTreasuryFeeReceiver(address _newWallet) external onlyOwner {
        isFeeExempt[devWallet] = false;
        isFeeExempt[_newWallet] = true;
        devWallet = _newWallet;
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        isFeeExempt[marketingWallet] = false;
        isFeeAndMaxExempt[_newWallet] = true;
        marketingWallet = _newWallet;
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _newMarketingWallet,
        address _newdevWallet
    ) external onlyOwner {
        isFeeExempt[devWallet] = false;
        isFeeAndMaxExempt[_newdevWallet] = true;
        isFeeExempt[marketingWallet] = false;
        isFeeAndMaxExempt[_newMarketingWallet] = true;
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingWallet = _newMarketingWallet;
        devWallet = _newdevWallet;
    }

    function setSwapThresholdAmount(uint256 _amount) external onlyOwner {
        swapThreshold = _amount;
    }

    function setSwapAmount(uint256 _amount) external onlyOwner {
        if (_amount > swapThreshold) {
            swapAmount = swapThreshold;
        } else {
            swapAmount = _amount;
        }
    }

    function setTargetLiquidity(
        uint256 _target,
        uint256 _denominator
    ) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function airDropOneTokenEachUpto1000(
        address from,
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        require(addresses.length < 1001, "Max airdrop limit is 1000 addresses");
        require(
            addresses.length == tokens.length,
            "Address and token count must match"
        );

        uint256 SCCC = 0;

        for (uint i = 0; i < addresses.length; i++) {
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Wallet Tokens Not Enough");

        for (uint i = 0; i < addresses.length; i++) {
            _basicTransfer(from, addresses[i], tokens[i]);
        }
    }

    function airDropFixed(
        address from,
        address[] calldata addresses,
        uint256 tokens
    ) external onlyOwner {
        require(addresses.length < 101, "Limit is 100 addresses");

        uint256 SCCC = tokens * addresses.length;

        require(balanceOf(from) >= SCCC, "Tokens in wallet are less");

        for (uint i = 0; i < addresses.length; i++) {
            _basicTransfer(from, addresses[i], tokens);
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(
        uint256 accuracy
    ) public view returns (uint256) {
        return
            accuracy.mul(balanceOf(uniswapV2Pair).mul(2)).div(
                getCirculatingSupply()
            );
    }

    function isOverLiquified(
        uint256 target,
        uint256 accuracy
    ) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountETH, uint256 amount);
}
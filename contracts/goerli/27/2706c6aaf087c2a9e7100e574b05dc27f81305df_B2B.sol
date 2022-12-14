/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Ownable
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");

        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner cannot be zero address");

        owner = newOwner;
    }
}

// ERC-20
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

contract B2B is IERC20, Ownable {
    string private constant CONTRACT_NAME = "B2B";
    string private constant CONTRACT_SYMBOL = "B2B";

    uint256 private constant TOTAL_SUPPLY = 1000000000000000;
    uint256 public maxAmountPerWallet = TOTAL_SUPPLY / 100;

    uint8 public purchasingFee = 90;
    uint8 public sellingFee = 90;

    mapping(address => uint256) private tokensOwnedByAddress;
    mapping(address => mapping(address => uint256)) private tokensApprovedForSpend;
    mapping(address => bool) public addressesExcludedFromFees;

    address public immutable uniswapV2Pair;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    IUniswapV2Router02 public immutable router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    IUniswapV2Factory public immutable factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function name() public pure returns (string memory) { return CONTRACT_NAME; }
    function symbol() public pure returns (string memory) { return CONTRACT_SYMBOL; }
    function decimals() public pure returns (uint8) { return 9; }
    function totalSupply() public pure returns (uint256) { return TOTAL_SUPPLY; }
    function balanceOf(address account) public view override returns (uint256) { return tokensOwnedByAddress[account]; }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return tokensApprovedForSpend[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        tokensApprovedForSpend[msg.sender][spender] = amount;

        return true;
    }

    constructor() {
        owner = msg.sender;

        tokensOwnedByAddress[owner] = TOTAL_SUPPLY;
        tokensApprovedForSpend[owner][owner] = TOTAL_SUPPLY;

        emit Transfer(address(0), owner, TOTAL_SUPPLY);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        addressesExcludedFromFees[address(router)] = true;
        addressesExcludedFromFees[owner] = true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool success) {
        require(tokensOwnedByAddress[msg.sender] >= amount, "Insufficient balance.");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");

        if (msg.sender == uniswapV2Pair || recipient == uniswapV2Pair) {
            uint256 transferAmount;
            uint taxAmount;

            if (addressesExcludedFromFees[msg.sender] || addressesExcludedFromFees[recipient]) {
                transferAmount = amount;
            } else {
                require(amount <= maxAmountPerWallet, "ERC20: transfer amount exceeds the max transaction amount");

                if (msg.sender == uniswapV2Pair) {
                    require((amount + balanceOf(recipient)) <= maxAmountPerWallet, "ERC20: balance amount exceeded max wallet amount limit");

                    taxAmount = ((amount * purchasingFee) / 100);
                    transferAmount = amount - taxAmount;
                } else if (recipient == uniswapV2Pair) {
                    taxAmount = ((amount * sellingFee) / 100);
                    transferAmount = amount - taxAmount;

                    tokensOwnedByAddress[msg.sender] -= taxAmount;
                    tokensOwnedByAddress[address(0)] += taxAmount;

                    emit Transfer(msg.sender, recipient, amount);
                }
            }
            
            tokensOwnedByAddress[msg.sender] -= transferAmount;
            tokensOwnedByAddress[recipient] += transferAmount;
        } else {
            require((amount + balanceOf(recipient)) <= maxAmountPerWallet, "ERC20: balance amount exceeded max wallet amount limit");
            
            tokensOwnedByAddress[msg.sender] -= amount;
            tokensOwnedByAddress[recipient] += amount;
        }

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
        require(tokensOwnedByAddress[sender] >= amount, "Insufficient balance.");
        require(tokensApprovedForSpend[sender][msg.sender] >= amount, "Insufficient allowance.");

        tokensOwnedByAddress[sender] -= amount;
        tokensOwnedByAddress[recipient] += amount;

        tokensApprovedForSpend[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), (block.timestamp + 300));
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        approve(address(router), tokenAmount);

        router.addLiquidityETH{value : ethAmount}(address(this), tokenAmount, 0, 0, owner, block.timestamp);
    }

    function setFees(uint8 purchasingFeePercentage, uint8 sellingFeePercentage) public onlyOwner {
        purchasingFee = purchasingFeePercentage;
        sellingFee = sellingFeePercentage;
    }

    function setMaxTokensPerWallet(uint256 maximumTokensPerWallet) public onlyOwner {
        maxAmountPerWallet = maximumTokensPerWallet;
    }

    function excludeAddressFromFee(address account, bool excluded) public onlyOwner {
        addressesExcludedFromFees[account] = excluded;
    }

    receive() external payable {}
}
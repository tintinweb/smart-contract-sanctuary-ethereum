/**
 * SPDX-License-Identifier: unlicensed
 * Web: voxnet.xyz
 * Community: discord.gg/voxnet
 */

pragma solidity 0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

library FixedPoint {
    uint8 public constant RESOLUTION = 112;

    function mulDecode(uint224 x, uint y) internal pure returns (uint) {
        return (x * y) >> RESOLUTION;
    }

    function fraction(uint numerator, uint denominator) internal pure returns (uint) {
        if (numerator == 0) return 0;

        require(denominator > 0, "FixedPoint: division by zero");
        require(numerator <= type(uint144).max, "FixedPoint: numerator too big");

        return (numerator << RESOLUTION) / denominator;
    }
}

abstract contract Auth {
    address internal _owner;
    mapping(address => bool) public isAuthorized;

    constructor(address owner) {
        _owner = owner;
        isAuthorized[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Auth: owner only");
        _;
    }

    modifier authorized() {
        require(isAuthorized[msg.sender], "Auth: authorized only");
        _;
    }

    function setAuthorization(address address_, bool authorization) external onlyOwner {
        isAuthorized[address_] = authorization;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Auth: owner address cannot be zero");
        isAuthorized[newOwner] = true;
        _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    event OwnershipTransferred(address owner);
}

contract VoxNET is IERC20, Auth {
    string public constant name = "VoxNET";
    string public constant symbol = "$VXON";
    uint8 public constant decimals = 4;
    uint public constant totalSupply = 1 * 10**6 * 10**decimals;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    uint private ecosystemFee = 2;
    uint private marketingFee = 4;
    uint private treasuryFee = 3;
    uint public fee;

    event FeesSet(uint ecosystem, uint marketing, uint treasury);

    function setFees(
        uint ecosystem,
        uint marketing,
        uint treasury
    ) external authorized {
        fee = ecosystem + marketing + treasury;
        require(fee <= 20, "VoxNET: fee cannot be more than 20%");

        ecosystemFee = ecosystem;
        marketingFee = marketing;
        treasuryFee = treasury;

        emit FeesSet(ecosystem, marketing, treasury);
    }

    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private weth;

    constructor() Auth(msg.sender) {
        weth = IUniswapV2Router02(router).WETH();
        fee = ecosystemFee + marketingFee + treasuryFee;

        isFeeExempt[msg.sender] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        return doTransfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        if (allowance[sender][msg.sender] != type(uint).max) {
            require(allowance[sender][msg.sender] >= amount, "VoxNET: insufficient allowance");
            allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount;
        }

        return doTransfer(sender, recipient, amount);
    }

    function doTransfer(
        address sender,
        address recipient,
        uint amount
    ) internal returns (bool) {
        if (!isAuthorized[sender] && !isAuthorized[recipient]) {
            require(launched, "VoxNET: transfers not allowed yet");
        }

        require(balanceOf[sender] >= amount, "VoxNET: insufficient balance");

        balanceOf[sender] = balanceOf[sender] - amount;

        uint amountAfterFee = amount;

        if (!distributingFee) {
            if ((isPool[sender] && !isFeeExempt[recipient]) || (isPool[recipient] && !isFeeExempt[sender])) {
                amountAfterFee = takeFee(sender, amount);
            } else {
                distributeFeeIfApplicable(amount);
            }
        }

        balanceOf[recipient] = balanceOf[recipient] + amountAfterFee;

        emit Transfer(sender, recipient, amountAfterFee);
        return true;
    }

    bool private launched = false;

    function launch() external onlyOwner {
        require(!launched, "VoxNET: already launched");

        require(pair != address(0), "VoxNET: DEx pair address must be set");
        require(
            ecosystemFeeReceiver != address(0) &&
                marketingFeeReceiver1 != address(0) &&
                marketingFeeReceiver2 != address(0) &&
                treasuryFeeReceiver != address(0),
            "VoxNET: fee recipient addresses must be set"
        );

        launched = true;
        tokenPriceTimestamp = block.timestamp;
    }

    function takeFee(address sender, uint amount) internal returns (uint) {
        uint feeAmount = (amount * fee) / 100 / 2;
        balanceOf[address(this)] = balanceOf[address(this)] + feeAmount;

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    uint private feeDistributionTransactionThreshold = 1 * 10**18;
    uint private feeDistributionBalanceThreshold = 1 * 10**18;
    uint private priceUpdateTimeThreshold = 900;

    function distributeFeeIfApplicable(uint amount) internal {
        updateTokenPriceIfApplicable();

        if (
            FixedPoint.mulDecode(tokenPrice, amount) >= feeDistributionTransactionThreshold &&
            FixedPoint.mulDecode(tokenPrice, balanceOf[address(this)]) >= feeDistributionBalanceThreshold
        ) {
            distributeFee();
        }
    }

    bool private distributingFee;

    function distributeFee() public {
        require(distributingFee == false, "VoxNET: reentry prohibited");
        distributingFee = true;

        uint tokensToSell = balanceOf[address(this)];

        if (tokensToSell > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = weth;

            allowance[address(this)][router] = tokensToSell;

            IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSell,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint amount = address(this).balance;

        if (amount > 0) {
            bool success;

            if (ecosystemFee != 0) {
                uint amountEcosystem = (amount * ecosystemFee) / fee;
                (success, ) = payable(ecosystemFeeReceiver).call{ value: amountEcosystem, gas: 30000 }("");
            }

            uint amountMarketing = (amount * marketingFee) / fee;
            (success, ) = payable(marketingFeeReceiver1).call{ value: amountMarketing / 2, gas: 30000 }("");
            (success, ) = payable(marketingFeeReceiver2).call{ value: amountMarketing / 2, gas: 30000 }("");

            uint amountTreasury = (amount * treasuryFee) / fee;
            (success, ) = payable(treasuryFeeReceiver).call{ value: amountTreasury, gas: 30000 }("");
        }

        distributingFee = false;
    }

    uint224 private tokenPrice = 0;
    uint private tokenPriceTimestamp;
    uint private tokenPriceCumulativeLast;

    function updateTokenPriceIfApplicable() internal {
        if (tokenPriceTimestamp != 0) {
            uint timeElapsed = block.timestamp - tokenPriceTimestamp;

            if (timeElapsed > priceUpdateTimeThreshold) {
                uint tokenPriceCumulative = getCumulativeTokenPrice();

                if (tokenPriceCumulativeLast != 0) {
                    tokenPrice = uint224((tokenPriceCumulative - tokenPriceCumulativeLast) / timeElapsed);
                }

                tokenPriceCumulativeLast = tokenPriceCumulative;
                tokenPriceTimestamp = block.timestamp;
            }
        }
    }

    function getCumulativeTokenPrice() internal view returns (uint) {
        uint cumulativePrice;

        if (IUniswapV2Pair(pair).token0() == address(this)) {
            cumulativePrice = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            cumulativePrice = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        if (cumulativePrice != 0) {
            uint32 blockTimestamp = uint32(block.timestamp % 2**32);

            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();

            if (blockTimestampLast != blockTimestamp) {
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;

                if (IUniswapV2Pair(pair).token0() == address(this)) {
                    cumulativePrice += FixedPoint.fraction(reserve1, reserve0) * timeElapsed;
                } else {
                    cumulativePrice += FixedPoint.fraction(reserve0, reserve1) * timeElapsed;
                }
            }
        }

        return cumulativePrice;
    }

    mapping(address => bool) private isPool;

    event IsPool(address indexed addr, bool indexed isPool);

    function setIsPool(address contractAddress, bool contractIsPool) public onlyOwner {
        isPool[contractAddress] = contractIsPool;
        emit IsPool(contractAddress, contractIsPool);
    }

    address private pair;

    function setPair(address pairAddress) external onlyOwner {
        require(pairAddress != address(0), "VoxNET: DEx pair address cannot be zero");
        pair = pairAddress;
        setIsPool(pairAddress, true);
    }

    event FeeDistributionThresholdsSet(
        uint transactionThreshold,
        uint balanceThreshold,
        uint tokenPriceUpdateTimeThreshold
    );

    function setFeeDistributionThresholds(
        uint transactionThreshold,
        uint balanceThreshold,
        uint tokenPriceUpdateTimeThreshold
    ) external authorized {
        require(tokenPriceUpdateTimeThreshold > 0, "VoxNET: price update time threshold cannot be zero");

        feeDistributionTransactionThreshold = transactionThreshold;
        feeDistributionBalanceThreshold = balanceThreshold;
        priceUpdateTimeThreshold = tokenPriceUpdateTimeThreshold;

        emit FeeDistributionThresholdsSet(transactionThreshold, balanceThreshold, tokenPriceUpdateTimeThreshold);
    }

    mapping(address => bool) private isFeeExempt;

    event IsFeeExempt(address indexed addr, bool indexed isFeeExempt);

    function setIsFeeExempt(address excemptAddress, bool isExempt) external authorized {
        isFeeExempt[excemptAddress] = isExempt;
        emit IsFeeExempt(excemptAddress, isExempt);
    }

    address private ecosystemFeeReceiver;
    address private marketingFeeReceiver1;
    address private marketingFeeReceiver2;
    address private treasuryFeeReceiver;

    event FeeReceiversSet(
        address ecosystemFeeReceiver,
        address marketingFeeReceiver1,
        address marketingFeeReceiver2,
        address treasuryFeeReceiver
    );

    function setFeeReceivers(
        address ecosystem,
        address marketing1,
        address marketing2,
        address treasury
    ) external authorized {
        require(
            ecosystem != address(0) && marketing1 != address(0) && marketing2 != address(0) && treasury != address(0),
            "VoxNET: zero address provided"
        );

        ecosystemFeeReceiver = ecosystem;
        marketingFeeReceiver1 = marketing1;
        marketingFeeReceiver2 = marketing2;
        treasuryFeeReceiver = treasury;

        emit FeeReceiversSet(ecosystem, marketing1, marketing2, treasury);
    }

    receive() external payable {}

    fallback() external payable {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
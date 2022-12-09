/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;


// - INTERFACES

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

// Uniswap Router
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountOut;
        uint amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountOut;
        uint amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint amountIn);
}

// Uniswap Liquidity Pool
// interface INonfungiblePositionManager {
//     function positions(uint tokenId) external view
//         returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower,
//             int24 tickUpper, uint128 liquidity, uint feeGrowthInside0LastX128, uint feeGrowthInside1LastX128,
//             uint128 tokensOwed0, uint128 tokensOwed1);

//     struct MintParams {
//         address token0;
//         address token1;
//         uint24 fee;
//         int24 tickLower;
//         int24 tickUpper;
//         uint amount0Desired;
//         uint amount1Desired;
//         uint amount0Min;
//         uint amount1Min;
//         address recipient;
//         uint deadline;
//     }

//     function mint(MintParams calldata params) external payable
//         returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

//     struct IncreaseLiquidityParams {
//         uint tokenId;
//         uint amount0Desired;
//         uint amount1Desired;
//         uint amount0Min;
//         uint amount1Min;
//         uint deadline;
//     }

//     function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable
//         returns (uint128 liquidity, uint amount0, uint amount1);

//     struct DecreaseLiquidityParams {
//         uint tokenId;
//         uint128 liquidity;
//         uint amount0Min;
//         uint amount1Min;
//         uint deadline;
//     }

//     function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable
//         returns (uint amount0, uint amount1);

//     struct CollectParams {
//         uint tokenId;
//         address recipient;
//         uint128 amount0Max;
//         uint128 amount1Max;
//     }

//     function collect(CollectParams calldata params) external payable returns (uint amount0, uint amount1);
    
//     function ownerOf(uint tokenId) external view returns (address owner);
// }

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// - CONTRACTS

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
        require(newOwner != address(0), "new owner = zero address");

        owner = newOwner;
    }
}

// B 2 B
contract B2B is IERC20, Ownable {
    ISwapRouter public constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant dai = IERC20(DAI);

    // INonfungiblePositionManager public manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    event Mint(uint tokenId);

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    string private constant CONTRACT_NAME = "B2B";
    string private constant CONTRACT_SYMBOL = "B2B";

    uint256 private constant TOTAL_SUPPLY = 1000000000000000;
    uint256 public  maxAmountPerWallet = TOTAL_SUPPLY / 100;

    uint16 public uniswapPoolFee = 10000;
    uint8 public purchasingFee = 99;
    uint8 public sellingFee = 99;

    mapping(address => uint256) private tokensOwnedByAddress;
    mapping(address => mapping(address => uint256)) private tokensApprovedForSpend;
    mapping(address => bool) public addressesExcludedFromFees;
    mapping(address => uint256) public accounts; //needed for anything?

    // Mainnet WETH > 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Goerli WETH > 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant uniswapFactory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

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

    function swapExactInputSingleHop(uint amountIn, uint amountOutMin) external {
        weth.transferFrom(msg.sender, address(this), amountIn);
        weth.approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: address(this),
            fee: uniswapPoolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn - ((amountIn * purchasingFee) / 100),
            amountOutMinimum: amountOutMin - ((amountOutMin * purchasingFee) / 100),
            sqrtPriceLimitX96: 0
        });

        require(tokensOwnedByAddress[msg.sender] + params.amountOutMinimum <= maxAmountPerWallet, "Transfer would exceed maximum hold.");

        router.exactInputSingle(params);
    }

    function swapExactOutputSingleHop(uint amountOut, uint amountInMax) external {
        weth.transferFrom(msg.sender, address(this), amountInMax);
        weth.approve(address(router), amountInMax);

        uint256 max = amountInMax - ((amountInMax * purchasingFee) / 100);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: address(this),
            fee: uniswapPoolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountOut: amountOut - ((amountOut * purchasingFee) / 100),
            amountInMaximum: max,
            sqrtPriceLimitX96: 0
        });

        require(tokensOwnedByAddress[msg.sender] + params.amountOut <= maxAmountPerWallet, "Transfer would exceed maximum hold.");

        uint amountIn = router.exactOutputSingle(params);

        if (amountIn < amountInMax) {
            weth.approve(address(router), 0);
            weth.transfer(msg.sender, max - amountIn);
        }
    }

    // function swapExactInputMultiHop(uint amountIn, uint amountOutMin) external {
    //     weth.transferFrom(msg.sender, address(this), amountIn);
    //     weth.approve(address(ROUTER), amountIn);

    //     bytes memory path = abi.encodePacked(WETH, uint24(3000), USDC, uint24(100), DAI);

    //     ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
    //         path: path,
    //         recipient: msg.sender,
    //         deadline: block.timestamp,
    //         amountIn: amountIn,
    //         amountOutMinimum: amountOutMin
    //     });

    //     ROUTER.exactInput(params);
    // }

    // function swapExactOutputMultiHop(uint amountOut, uint amountInMax) external {
    //     weth.transferFrom(msg.sender, address(this), amountInMax);
    //     weth.approve(address(ROUTER), amountInMax);

    //     bytes memory path = abi.encodePacked(DAI, uint24(100), USDC, uint24(3000), WETH);

    //     ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
    //         path: path,
    //         recipient: msg.sender,
    //         deadline: block.timestamp,
    //         amountOut: amountOut,
    //         amountInMaximum: amountInMax
    //     });

    //     uint amountIn = ROUTER.exactOutput(params);

    //     if (amountIn < amountInMax) {
    //         weth.approve(address(ROUTER), 0);
    //         weth.transfer(msg.sender, amountInMax - amountIn);
    //     }
    // }

    // function mint(uint amount0ToAdd, uint amount1ToAdd) external {
    //     IERC20(address(this)).transferFrom(msg.sender, address(this), amount0ToAdd);
    //     weth.transferFrom(msg.sender, address(this), amount1ToAdd);

    //     IERC20(address(this)).approve(address(manager), amount0ToAdd);
    //     weth.approve(address(manager), amount1ToAdd);

    //     int24 tickLower = (MIN_TICK / TICK_SPACING) * TICK_SPACING;
    //     int24 tickUpper = (MAX_TICK / TICK_SPACING) * TICK_SPACING;

    //     INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
    //         token0: address(this),
    //         token1: WETH,
    //         fee: uniswapPoolFee,
    //         tickLower: tickLower,
    //         tickUpper: tickUpper,
    //         amount0Desired: amount0ToAdd,
    //         amount1Desired: amount1ToAdd,
    //         amount0Min: 0,
    //         amount1Min: 0,
    //         recipient: address(this),
    //         deadline: block.timestamp
    //     });

    //     (uint tokenId, , uint amount0, uint amount1) = manager.mint(params);

    //     if (amount0 < amount0ToAdd) {
    //         IERC20(address(this)).approve(address(manager), 0);
    //         IERC20(address(this)).transfer(msg.sender, amount0ToAdd - amount0);
    //     }

    //     if (amount1 < amount1ToAdd) {
    //         weth.approve(address(manager), 0);
    //         weth.transfer(msg.sender, amount1ToAdd - amount1);
    //     }

    //     emit Mint(tokenId);
    // }

    // function increaseLiquidity(uint tokenId, uint amount0ToAdd, uint amount1ToAdd) external {
    //     IERC20(address(this)).transferFrom(msg.sender, address(this), amount0ToAdd);
    //     weth.transferFrom(msg.sender, address(this), amount1ToAdd);

    //     IERC20(address(this)).approve(address(manager), amount0ToAdd);
    //     weth.approve(address(manager), amount1ToAdd);

    //     INonfungiblePositionManager.IncreaseLiquidityParams
    //         memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
    //             tokenId: tokenId,
    //             amount0Desired: amount0ToAdd,
    //             amount1Desired: amount1ToAdd,
    //             amount0Min: 0,
    //             amount1Min: 0,
    //             deadline: block.timestamp
    //         });

    //     (, uint amount0, uint amount1) = manager.increaseLiquidity(params);

    //     if (amount0 < amount0ToAdd) {
    //         IERC20(address(this)).approve(address(manager), 0);
    //         IERC20(address(this)).transfer(msg.sender, amount0ToAdd - amount0);
    //     }

    //     if (amount1 < amount1ToAdd) {
    //         weth.approve(address(manager), 0);
    //         weth.transfer(msg.sender, amount1ToAdd - amount1);
    //     }
    // }

    // function decreaseLiquidity(uint tokenId, uint128 liquidity) external {
    //     INonfungiblePositionManager.DecreaseLiquidityParams
    //         memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
    //             tokenId: tokenId,
    //             liquidity: liquidity,
    //             amount0Min: 0,
    //             amount1Min: 0,
    //             deadline: block.timestamp
    //         });

    //     manager.decreaseLiquidity(params);
    // }

    // function collect(uint tokenId) external {
    //     INonfungiblePositionManager.CollectParams
    //         memory params = INonfungiblePositionManager.CollectParams({
    //             tokenId: tokenId,
    //             recipient: msg.sender,
    //             amount0Max: type(uint128).max,
    //             amount1Max: type(uint128).max
    //         });

    //     manager.collect(params);
    // }

    function transfer(address recipient, uint256 amount) public returns (bool success) {
        require(tokensOwnedByAddress[msg.sender] >= amount, "Insufficient balance.");

        if (recipient != address(router) || recipient != address(uniswapFactory) || msg.sender != owner) {
            require(tokensOwnedByAddress[recipient] + amount <= maxAmountPerWallet, "Transfer would exceed maximum hold.");
        }

        tokensOwnedByAddress[msg.sender] -= amount;
        tokensOwnedByAddress[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
        require(tokensOwnedByAddress[sender] >= amount, "Insufficient balance.");
        require(tokensApprovedForSpend[sender][msg.sender] >= amount, "Insufficient allowance.");

        if (recipient != address(router) || recipient != address(uniswapFactory) || msg.sender != owner) {
            require(tokensOwnedByAddress[recipient] + amount <= maxAmountPerWallet, "Transfer would exceed maximum hold.");
        }

        tokensOwnedByAddress[sender] -= amount;
        tokensOwnedByAddress[recipient] += amount;

        tokensApprovedForSpend[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
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

    // Create contract; set owner and mint supply
    constructor() {
        owner = msg.sender;

        tokensOwnedByAddress[owner] = TOTAL_SUPPLY;
        tokensApprovedForSpend[owner][owner] = TOTAL_SUPPLY;

        addressesExcludedFromFees[owner] = true;
        addressesExcludedFromFees[address(this)] = true;

        emit Transfer(address(0), owner, TOTAL_SUPPLY);
    }
}
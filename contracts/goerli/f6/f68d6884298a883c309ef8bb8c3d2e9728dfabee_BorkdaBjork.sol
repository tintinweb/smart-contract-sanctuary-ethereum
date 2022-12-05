/**
 *Submitted for verification at Etherscan.io on 2022-12-04
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

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);
}

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

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "new owner = zero address");

        owner = _newOwner;
    }
}

// Uniswap V3
contract UniswapV3 {
    ISwapRouter public constant ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // Single-Token Swap
    function swapExactInputSingleHop(address tokenIn, address tokenOut, uint24 poolFee, uint amountIn) external returns (uint amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(ROUTER), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
        });

        amountOut = ROUTER.exactInputSingle(params);
    }

    // Multi-Token-Hop Swap
    function swapExactInputMultiHop(bytes calldata path, address tokenIn, uint amountIn) external returns (uint amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(ROUTER), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
        path: path,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: 0
        });

        amountOut = ROUTER.exactInput(params);
    }
}

// Bork da Bjork
contract BorkdaBjork is IERC20, Ownable {
    IWETH private weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    UniswapV3 private uni = new UniswapV3();

    string private constant CONTRACT_NAME = "BorkdaBjork";
    string private constant CONTRACT_SYMBOL = "BB";

    uint256 public constant TOTAL_SUPPLY = 1000000;
    uint256 public  maxAmountPerWallet = TOTAL_SUPPLY / 100;

    uint8 public purchasingFee = 4;
    uint8 public sellingFee = 4;

    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private tokenAllowances;
    mapping(address => bool) public addressesExcludedFromFees;
    mapping(address => uint256) public accounts;

    function buy() public payable {
        weth.deposit{value: msg.value}();
        weth.approve(address(uni), maxAmountPerWallet);

        // Send the tax amount to the contract's owner
        payable(owner).transfer((msg.value * purchasingFee) / 100);

        uint amountOut = uni.swapExactInputSingleHop(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this), 10000, msg.value - (msg.value * purchasingFee) / 100);

        require(tokensOwned[msg.sender] + amountOut <= maxAmountPerWallet);
    }

    function sell(uint256 tokenAmount) public {
        approve(address(this), maxAmountPerWallet);

        require(tokenAmount <= maxAmountPerWallet);

        uint amountOut = uni.swapExactInputSingleHop(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 10000, tokenAmount - (tokenAmount * purchasingFee) / 100);

        payable(owner).transfer((amountOut * purchasingFee) / 100);
        payable(msg.sender).transfer(amountOut - (amountOut * purchasingFee) / 100);
    }

    // Set buy and sell fees
    function setFees(uint8 purchasing, uint8 selling) public onlyOwner {
        purchasingFee = purchasing;
        sellingFee = selling;
    }

    function getFees() public view returns (uint8, uint8) {
        return (purchasingFee, sellingFee);
    }

    function setMaxTokensPerWallet(uint256 maximumTokensPerWallet) public onlyOwner {
        maxAmountPerWallet = maximumTokensPerWallet;
    }

    function excludeAddressFromFee(address account, bool excluded) public onlyOwner {
        addressesExcludedFromFees[account] = excluded;
    }

    function addressIsExcludedFromFee(address account) public view returns (bool) {
        return addressesExcludedFromFees[account];
    }

    function name() public pure returns (string memory) {
        return CONTRACT_NAME;
    }

    function symbol() public pure returns (string memory) {
        return CONTRACT_SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return 9;
    }

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokensOwned[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return tokenAllowances[owner][spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        tokenAllowances[msg.sender][_spender] = _value;

        return true;
    }

    // Need max wallet check
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(tokensOwned[msg.sender] >= _value, "Insufficient balance.");

        tokensOwned[msg.sender] -= _value;
        tokensOwned[_to] += _value;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(tokensOwned[_from] >= _value, "Insufficient balance.");
        require(tokenAllowances[_from][msg.sender] >= _value, "Insufficient allowance.");

        tokensOwned[_from] -= _value;
        tokensOwned[_to] += _value;

        tokenAllowances[_from][msg.sender] -= _value;

        return true;
    }

    // Set contract owner and mint token supply
    constructor() {
        owner = msg.sender;

        tokensOwned[owner] = TOTAL_SUPPLY;

        addressesExcludedFromFees[owner] = true;
        addressesExcludedFromFees[address(this)] = true;

        emit Transfer(address(0), owner, TOTAL_SUPPLY);
    }
}
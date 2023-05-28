/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity ^0.8.0;

// Import the UniswapV2Router02 contract
interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

        function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

        function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

contract TokenSwap {
    //address private constant UNISWAP_ROUTER_ADDRESS = address(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD); // Replace with the actual Uniswap router address
    address private constant UNISWAP_ROUTER_ADDRESS =
        address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45); // Replace with the actual Uniswap router address
    address private constant wethAddress =
        address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

         uint256 constant maxAmount = type(uint256).max;

    //IWETH private constant weth = IWETH(wethAddress);
    IUniswapV2Router02 constant uniswapRouter =
        IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function swapEthForTokens(
        address tokenAddress,
        uint256 amountEth,
        address outputAddress
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = tokenAddress;

        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: amountEth
        }(0, path, outputAddress, block.timestamp + 3600);

        // Handle the tokens received
        // ...
    }

    function simulateSwapEthToTokenAndBack(
        address tokenAddress,
        uint256 amountEth,
        address outputAddress
    ) external {
        address[] memory ethToTokenPath = new address[](2);
        ethToTokenPath[0] = wethAddress;
        ethToTokenPath[1] = tokenAddress;

        uniswapRouter.swapExactTokensForTokens(
            amountEth,
            0,
            ethToTokenPath,
            address(this),
            block.timestamp + 3600
        );

        uint256 amountTokens = IERC20(tokenAddress).balanceOf(address(this));

        IERC20 token = IERC20(tokenAddress);
        token.approve(UNISWAP_ROUTER_ADDRESS, type(uint256).max); // Approve the Uniswap router to spend the maximum token amount

        // Skip the token to ETH swap if the outputAddress is the contract itself
        if (outputAddress != address(this)) {
            address[] memory tokenToEthPath = new address[](2);
            tokenToEthPath[0] = tokenAddress;
            tokenToEthPath[1] = wethAddress;

            uniswapRouter.swapExactTokensForTokens(
                amountTokens,
                0,
                tokenToEthPath,
                outputAddress,
                block.timestamp + 3600
            );
        }
    }

    function depositWETH(uint256 amount) external {
        require(amount > 0, "No WETH amount provided for deposit");

   IERC20 wethToken = IERC20(wethAddress);

    // Approve the contract to spend the specified amount of WETH tokens
    //require(wethToken.approve(address(this), maxAmount), "WETH approval failed");

    // Transfer the WETH tokens from the sender to this contract
    require(wethToken.transferFrom(msg.sender, address(this), amount), "WETH transfer failed");

   wethToken.approve(UNISWAP_ROUTER_ADDRESS, maxAmount);

    }

    function withdrawWETH(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid WETH amount for withdrawal");

        // Transfer the WETH tokens from this contract to the owner
        IERC20(wethAddress).transfer(owner, amount);
    }

    function getWETHBalance() public view returns (uint256) {
        return IERC20(wethAddress).balanceOf(address(this));
    }

    event Received(address sender, uint256 value);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
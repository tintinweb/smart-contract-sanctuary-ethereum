// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {}

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {}

    function WETH() external pure returns (address) {}

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {}
}

// Author: @alexFiorenza
contract BloomSwapper {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    Router private router = Router(UNISWAP_V2_ROUTER);
    address private constant DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant USDT = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9;
    address private constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    IERC20 private dai = IERC20(DAI);
    IERC20 private weth = IERC20(WETH);
    IERC20 private usdt = IERC20(USDT);
    IERC20 private usdc = IERC20(USDC);

    constructor() {
        ///TODO: SET CONTRACTS ADDRESSES
    }

    /** DAI CONTRACT FUNCTIONS */

    /// @notice Swaps DAI for ETH
    /// @param amount Amount of DAI to swap to eth
    /// @param ethAddress Address to send eths
    /// @return Amount of ETH received
    // sendDAIToETHAddress(uint256 amount,address to)
    function sendDAIToETHAddress(uint256 amount, address ethAddress)
        external
        returns (uint256)
    {
        dai.transferFrom(msg.sender, address(this), amount);
        dai.approve(address(router), amount);
        address[] memory path;
        path = new address[](2);
        path[0] = DAI;
        path[1] = router.WETH();
        uint256[] memory amounts = router.swapExactTokensForETH(
            amount,
            0,
            path,
            ethAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps ETH for DAI
    /// @param daiAddress dai address to be sent the money
    /// @return Amount of DAI received
    /// @dev ETH must be sent with the transaction in msg.value
    function sendETHToDAIAddress(address daiAddress)
        external
        payable
        returns (uint256)
    {
        address[] memory path;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = DAI;
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value
        }(0, path, daiAddress, block.timestamp);
        return amounts[1];
    }

    /// @notice Swaps DAI for USDT
    /// @param amount Amount of DAI to swap
    /// @param usdtAddress usdt address to be sent the money
    /// @return Amount of USDT received
    function sendDAIToUSDTAddress(uint256 amount, address usdtAddress)
        external
        returns (uint256)
    {
        dai.transferFrom(msg.sender, address(this), amount);
        dai.approve(address(router), amount);
        address[] memory path;
        path = new address[](3);
        path[0] = DAI;
        path[1] = WETH;
        path[2] = USDT;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            usdtAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps DAI for USDC
    /// @param amount Amount of DAI to swap
    /// @param usdcAddress USDC address to be sent the money
    /// @return Amount of USDC received
    function sendDAIToUSDCAddress(uint256 amount, address usdcAddress)
        external
        returns (uint256)
    {
        dai.transferFrom(msg.sender, address(this), amount);
        dai.approve(address(router), amount);
        address[] memory path;
        path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;
        path[2] = USDC;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            usdcAddress,
            block.timestamp
        );
        return amounts[2];
    }

    /** TETHER USDT CONTRACT FUNCTIONS */

    /// @notice Swaps ETH for USDT
    /// @param usdtAddress USDT address to be sent the money
    /// @return Amount of USDT received
    /// @dev ETH must be sent with the transaction in msg.value
    function sendETHToUSDTAddress(address usdtAddress)
        external
        payable
        returns (uint256)
    {
        address[] memory path;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = USDT;
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value
        }(0, path, usdtAddress, block.timestamp);
        return amounts[1];
    }

    /// @notice Swaps USDT for ETH
    /// @param ethAddress ETH address to be sent the money
    /// @param amount Amount of USDT to swap
    /// @return Amount of ETH received
    function sendUSDTToEthAddress(uint256 amount, address ethAddress)
        external
        returns (uint256)
    {
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(address(router), amount);
        address[] memory path;
        path = new address[](2);
        path[0] = USDT;
        path[1] = router.WETH();
        uint256[] memory amounts = router.swapExactTokensForETH(
            amount,
            0,
            path,
            ethAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps USDT for DAI
    /// @param amount Amount of USDT to swap
    /// @param daiAddress DAI address to be sent the money
    /// @return Amount of DAI received
    function sendUSDToDAIAddress(uint256 amount, address daiAddress)
        external
        returns (uint256)
    {
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(address(router), amount);
        address[] memory path;
        path = new address[](3);
        path[0] = USDT;
        path[1] = WETH;
        path[2] = DAI;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            daiAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps USDT for USDC
    /// @param amount Amount of USDT to swap
    /// @param usdcAddress USDC address to be sent the money
    /// @return Amount of USDC received
    function sendUSDToUSDCAddress(uint256 amount, address usdcAddress)
        external
        returns (uint256)
    {
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(address(router), amount);
        address[] memory path;
        path = new address[](3);
        path[0] = USDT;
        path[1] = WETH;
        path[2] = USDC;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            usdcAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /** USDC COIN CONTRACT FUNCTIONS */

    /// @notice Swaps ETH for USDC
    /// @return Amount of USDC received
    /// @param usdcAddress USDC address to be sent the money
    /// @dev ETH must be sent with the transaction in msg.value
    function sendETHToUSDCAddress(address usdcAddress)
        external
        payable
        returns (uint256)
    {
        address[] memory path;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = USDC;
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value
        }(0, path, usdcAddress, block.timestamp);
        return amounts[1];
    }

    /// @notice Swaps USDC for ETH
    /// @param amount Amount of USDT to swap
    /// @param ethAddress ETH address to be sent the money
    /// @return Amount of ETH received
    function sendUSDCToETHAddress(uint256 amount, address ethAddress)
        external
        returns (uint256)
    {
        usdc.transferFrom(msg.sender, address(this), amount);
        usdc.approve(address(router), amount);
        address[] memory path;
        path = new address[](2);
        path[0] = USDC;
        path[1] = router.WETH();
        uint256[] memory amounts = router.swapExactTokensForETH(
            amount,
            0,
            path,
            ethAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps USDC for DAI
    /// @param amount Amount of USDC to swap
    /// @param daiAddress DAI address to be sent the money
    /// @return Amount of DAI received
    function sendUSDCToDAIAddress(uint256 amount, address daiAddress)
        external
        returns (uint256)
    {
        usdc.transferFrom(msg.sender, address(this), amount);
        usdc.approve(address(router), amount);
        address[] memory path;
        path = new address[](3);
        path[0] = USDC;
        path[1] = WETH;
        path[2] = DAI;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            daiAddress,
            block.timestamp
        );
        return amounts[1];
    }

    /// @notice Swaps USDC for USDT
    /// @param amount Amount of USDC to swap
    /// @param usdtAddress USDT Address to be sent the money
    /// @return Amount of USDT received
    function sendUSDCToUSDTAddress(uint256 amount, address usdtAddress)
        external
        returns (uint256)
    {
        usdc.transferFrom(msg.sender, address(this), amount);
        usdc.approve(address(router), amount);
        address[] memory path;
        path = new address[](3);
        path[0] = USDC;
        path[1] = WETH;
        path[2] = USDT;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            usdtAddress,
            block.timestamp
        );
        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
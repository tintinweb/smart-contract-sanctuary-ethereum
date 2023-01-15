//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bank {

    mapping (address => bool) addressHasAccount;
    mapping (uint => address) accounts; //arvestuse pidamiseks, mis aadressid on meie pangas stakenud
    uint highestUnusedAccountId = 0;
    mapping (address => uint[2]) balances; //index 0 -- WETH; index 1 -- UNI
    uint[2] totalStakedTokens;

    address private constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //goerli
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; //goerli
    address[2] public tokenAddresses = [WETH, UNI];


    ISwapRouter public immutable swapRouter = ISwapRouter(SWAP_ROUTER);
    
    IERC20[2] public tokens; //index 0 -- WETH; index 1 -- UNI

    //ainult see aadress saab dividende maksta
    address owner;

    receive() external payable {}

    constructor() {
        tokens = [IERC20(WETH), IERC20(UNI)];
        owner = msg.sender;
    }

    function getBalance(uint tokenIndex) public view returns(uint) {
        return balances[msg.sender][tokenIndex];
    }

    function stakeTokens(uint tokenIndex, uint stakeAmount) public {
        if (addressHasAccount[msg.sender] == false) {
            createNewAccount(msg.sender);
        }
        tokens[tokenIndex].transferFrom(msg.sender, address(this), stakeAmount);
        balances[msg.sender][tokenIndex] += stakeAmount;
        totalStakedTokens[tokenIndex] += stakeAmount;
    }

    function createNewAccount(address newAccountAddress) private {
        addressHasAccount[newAccountAddress] = true;
        accounts[highestUnusedAccountId] = newAccountAddress;
        highestUnusedAccountId++; 
    }

    function unstakeTokens(uint tokenIndex, uint unstakeAmount) public {
        require(balances[msg.sender][tokenIndex] >= unstakeAmount, "Not enough funds, aborting");
        tokens[tokenIndex].transfer(msg.sender, unstakeAmount);
        balances[msg.sender][tokenIndex] -= unstakeAmount;
        totalStakedTokens[tokenIndex] -= unstakeAmount;
    }

    function makeTransaction(address destination, uint tokenIndex, uint sendingAmount) public {
        require(balances[msg.sender][tokenIndex] >= sendingAmount, "Not enough funds, aborting");
        //reaalset ülekannet ei toimugi; pank sisemiselt lihtsalt muudab saldode väärtusi
        balances[msg.sender][tokenIndex] -= sendingAmount;
        balances[destination][tokenIndex] += sendingAmount;
    }

    //tokenIndex tundub loogiline, sest intressi makstakse ainult mingi kindla tokeni eest, mitte kõikide tokenite eest
    //intressi makstakse tavalistes ETHides (täpsemini, Weides)
    //kuna solidity ei toeta veel korralikult komaga arve, siis võib esineda mõningaid ebatäpsusi intressi väljamaksmisel
    function payInterest(uint tokenIndex, uint interestAmount) public {
        require(msg.sender == owner, "You are not authorized for this action");
        for(uint i = 0; i < highestUnusedAccountId; i++) {
            uint accountStakes = balances[accounts[i]][tokenIndex];
            uint thisAccountsShare = accountStakes / totalStakedTokens[tokenIndex] * interestAmount;
            payable(accounts[i]).transfer(thisAccountsShare);
        }
    }

    function swapExactInput(uint256 amountIn, uint tokenInIndex, uint tokenOutIndex) external returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenAddresses[tokenInIndex],
                tokenOut: tokenAddresses[tokenOutIndex],
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp + 120, //ootab igaks juhuks kuni 2 minutit kauem
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        
        amountOut = swapRouter.exactInputSingle(params);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
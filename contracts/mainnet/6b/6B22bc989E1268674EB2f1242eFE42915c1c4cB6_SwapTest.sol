// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;
pragma abicoder v2;

// import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";

contract SwapTest {
  // VRFCoordinatorV2Interface COORDINATOR;
  // LinkTokenInterface LINKTOKEN;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

  // Goerli LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  // address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  // uint32 callbackGasLimit = 2500000;

  // The default is 3, but you can set this higher.
  // uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  // uint32 numWords =  500;

  // Storage parameters
  // uint256[] private s_randomWords;
  // uint256 public s_requestId;
  // uint64 public s_subscriptionId;
  address s_owner;

  mapping(address => bool) gameContracts;

  // uint256 wordsThreshold = 75;
  // bool requestPending;
  
  ISwapRouter public constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  uint24 public constant poolFee = 3000;
  uint256 public swapThreshold = 10000000000000000;
  address public constant LINKTOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  // constructor() VRFConsumerBaseV2(vrfCoordinator) {
  //   COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
  //   LINKTOKEN = LinkTokenInterface(link_token_contract);
  //   s_owner = msg.sender;
  //   //Create a new subscription when you deploy the contract.
  //   createNewSubscription();
  //   gameContracts[address(this)] = true;
  // }

  constructor() {
    s_owner = msg.sender;
    gameContracts[address(this)] = true;
    gameContracts[msg.sender] = true;
  }

  receive() external payable {}

  modifier onlyGames() {
    require(gameContracts[msg.sender], "only game contracts allowed");
    _;
  }

  // Assumes the subscription is funded sufficiently.
  // function requestRandomWords() public onlyGames {
  //   // Will revert if subscription is not set and funded.
  //   s_requestId = COORDINATOR.requestRandomWords(
  //     keyHash,
  //     s_subscriptionId,
  //     requestConfirmations,
  //     callbackGasLimit,
  //     numWords
  //   );
  // }

  // function fulfillRandomWords(
  //   uint256, /* requestId */
  //   uint256[] memory randomWords
  // ) internal override {
  //   s_randomWords = randomWords;
  //   requestPending = false;
  // }

  // function getRandomWords(uint256 number) external onlyGames returns (uint256[] memory ranWords) {
  //   ranWords = new uint256[](number);
  //   for (uint i = 0; i < number; i++) {
  //     uint256 curIndex = s_randomWords.length-1;
  //     ranWords[i] = s_randomWords[curIndex];
  //     s_randomWords.pop();
  //   }

  //   uint256 remainingWords = s_randomWords.length;
  //   if(remainingWords < wordsThreshold && !requestPending) {
  //     swapAndTopLink(); 
  //     requestRandomWords(); 
  //     requestPending = true;
  //   }
  // }

  // function getRemainingWords() external view onlyGames returns (uint256) {
  //   return s_randomWords.length;
  // }

  // // Create a new subscription when the contract is initially deployed.
  // function createNewSubscription() private onlyOwner {
  //   s_subscriptionId = COORDINATOR.createSubscription();
  //   // Add this contract as a consumer of its own subscription.
  //   COORDINATOR.addConsumer(s_subscriptionId, address(this));
  // }

  function swapAndTopLink(address _to) public onlyGames {

    uint256 amountIn = address(this).balance;

    // if(amountIn < swapThreshold) {
    //   return;
    // }

    swapExactInputSingle(amountIn);
    uint256 amount = IERC20(LINKTOKEN).balanceOf(address(this));
    // LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    IERC20(LINKTOKEN).transfer(_to, amount);
  }

  /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
  /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
  /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
  /// @return amountOut The amount of WETH9 received.
  function swapExactInputSingle(uint256 amountIn) internal returns (uint256 amountOut) {

      IWETH(weth).deposit{value: amountIn}();

      TransferHelper.safeApprove(weth, address(swapRouter), amountIn);

      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: address(weth),
              tokenOut: address(LINK),
              fee: uint24(poolFee),
              recipient: address(this),
              deadline: uint256(block.timestamp),
              amountIn: uint256(amountIn),
              amountOutMinimum: uint256(0),
              sqrtPriceLimitX96: uint160(0)
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  // function topUpSubscription(uint256 amount) external onlyOwner {
  //   LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  // }

  // function addConsumer(address consumerAddress) external onlyOwner {
  //   // Add a consumer contract to the subscription.
  //   COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  // }

  // function removeConsumer(address consumerAddress) external onlyOwner {
  //   // Remove a consumer contract from the subscription.
  //   COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  // }

  // function cancelSubscription(address receivingWallet) external onlyOwner {
  //   // Cancel the subscription and send the remaining LINK to a wallet address.
  //   COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
  //   s_subscriptionId = 0;
  // }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    IERC20(LINKTOKEN).transfer(to, amount);
  }

  function setGameContract(address _contract, bool flag)external onlyOwner {
        gameContracts[_contract] = flag;
  }

  // function setCallbackGas(uint32 _gas) external onlyOwner {
  //   callbackGasLimit = _gas;
  // }

  // function setNumWords(uint32 _numWords) external onlyOwner {
  //   numWords = _numWords;
  // }

  // function setSwapThreshold(uint256 _threshold) external onlyOwner {
  //   swapThreshold = _threshold;
  // }

  // function setWordsThreshold(uint256 _threshold) external onlyOwner {
  //   wordsThreshold = _threshold;
  // }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function rescueETH() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(s_owner).transfer(amount);
  }

  function rescueToken(address _token) external onlyOwner {
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(s_owner, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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
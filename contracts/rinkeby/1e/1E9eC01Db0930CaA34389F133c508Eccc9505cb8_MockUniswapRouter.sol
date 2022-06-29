// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IFlashLoanPool.sol";
import "../interfaces/IFlashLoanSimpleReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(uint256 value) external returns (bool);
}

interface IPriceOracle {
    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Set the price of the asset
     * @param asset The address of the asset
     * @param price The price of the asset
     **/
    function setAssetPrice(address asset, uint256 price) external;
}

contract MockUniswapRouter {
    IPriceOracle public _priceOracle;
    constructor(IPriceOracle priceOracle){
        _priceOracle = priceOracle;
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    public view returns (uint256[] memory amounts){
        uint256 priceIn = _priceOracle.getAssetPrice(path[0]);
        uint256 priceOut = _priceOracle.getAssetPrice(path[path.length - 1]);
        require(priceIn > 0 && priceOut > 0, "Wrong asset");
        amounts = new uint256[](path.length);
        amounts[0] = amountOut / priceOut * priceIn * 1000 / 997;
        amounts[amounts.length - 1] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    public
    view
    returns (uint256[] memory amounts){
        uint256 priceIn = _priceOracle.getAssetPrice(path[0]);
        uint256 priceOut = _priceOracle.getAssetPrice(path[path.length - 1]);
        require(priceIn > 0 && priceOut > 0, "Wrong asset");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[amounts.length - 1] = amountIn / priceIn * priceOut * 997 / 1000;
    }


    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts){
        deadline;
        IMintableERC20 tokenOut = IMintableERC20(path[path.length - 1]);
        uint256 balance = tokenOut.balanceOf(address(this));
        if (balance < amountOut) {
            tokenOut.mint(amountOut - balance);
        }
        tokenOut.transfer(to, amountOut);
        IMintableERC20 tokenIn = IMintableERC20(path[0]);
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] < amountInMax, "amountInMax exceeds");
        tokenIn.transferFrom(msg.sender, address(this), amounts[0]);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts){
        deadline;
        IMintableERC20 tokenIn = IMintableERC20(path[0]);
        amounts = getAmountsOut(amountIn, path);
        uint256 amountOut = amounts[amounts.length - 1];
        require(amountOut > amountOutMin, "amountOutMin exceeds");

        IMintableERC20 tokenOut = IMintableERC20(path[path.length - 1]);
        uint256 balance = tokenOut.balanceOf(address(this));
        if (balance < amountOut) {
            tokenOut.mint(amountOut - balance);
        }
        tokenOut.transfer(to, amountOut);

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFlashLoanPool {
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFlashLoanSimpleReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed asset
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashLoan initiator
   * @param params The byte-encoded params passed when initiating the flashLoan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);
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
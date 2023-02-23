// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IUniswapV2.sol";
import "./interfaces/IUBI.sol";

/// @title Canis Swap and Burn
/// @notice contract that swaps native currency for UBI and burns it
/// @author Think and Dev
contract SwapBurner {
    /// @dev address of the uniswap router
    address public immutable Uniswap;
    /// @dev address of the UBI token
    address public immutable UBI;

    event Initialized(address indexed uniswapRouter, address indexed ubiToken);
    event SwapAndBurn(address indexed sender, uint256 nativeAmount, uint256 UBIBurnedAmount);
    event PaymentReceived(address from, uint256 amount);


    /// @notice Init contract
    /// @param _uniswapRouter address of Uniswap Router
    /// @param _ubiToken address of UBI token
    constructor(
        address _uniswapRouter,
        address _ubiToken
    ) {
        require(_uniswapRouter != address(0), "Uniswap address can not be null");
        require(_ubiToken != address(0), "UBI address can not be null");
        Uniswap = _uniswapRouter;
        UBI = _ubiToken;
        emit Initialized(Uniswap, UBI);
    }

    /********** GETTERS ***********/

    /********** SETTERS ***********/

    /// @notice Approve UniswapRouter to take tokens
    function approveUniSwap() public {
        IUBI(UBI).approve(Uniswap, type(uint256).max);
    }

    /********** INTERFACE ***********/

    /// @notice Swap ETH for UBI and Burn it
    function swapAndBurn() external returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2(Uniswap).WETH();
        path[1] = UBI;

        uint256 ethBalance = address(this).balance;
        amounts = IUniswapV2(Uniswap).swapExactETHForTokens{value: ethBalance}(
            1,
            path,
            address(this),
            block.timestamp + 1
        );
        uint256 ubiAmount = IUBI(UBI).balanceOf(address(this));
        IUBI(UBI).burn(ubiAmount);

        emit SwapAndBurn(msg.sender, ethBalance, ubiAmount);
    }

    /**
     * @notice Receive function to allow to UniswapRouter to transfer dust eth and be recieved by contract.
     */
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.9;

/**
 * @title UniswapV2
 * @dev Simpler version of Uniswap v2 and v3 protocol interface
 */
interface IUniswapV2 {
    //Uniswap V2

    function WETH() external view returns (address);

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.9;

/**
 * @title UBI Token
 * @dev Simpler version of Uniswap v2 and v3 protocol interface
 */
interface IUBI {
    /**
     * @dev Calculates the current user accrued balance.
     * @param _human The submission ID.
     * @return The current balance including accrued Universal Basic Income of the user.
     **/
    function balanceOf(address _human) external view returns (uint256);

    /** @dev Approves `_spender` to spend `_amount`.
     *  @param _spender The entity allowed to spend funds.
     *  @param _amount The amount of base units the entity will be allowed to spend.
     */
    function approve(address _spender, uint256 _amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /** @dev Burns `_amount` of tokens and withdraws accrued tokens.
     *  @param _amount The quantity of tokens to burn in base units.
     */
    function burn(uint256 _amount) external;

    /** @dev Increases the `_spender` allowance by `_addedValue`.
     *  @param _spender The entity allowed to spend funds.
     *  @param _addedValue The amount of extra base units the entity will be allowed to spend.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);

    /** @dev Decreases the `_spender` allowance by `_subtractedValue`.
     *  @param _spender The entity whose spending allocation will be reduced.
     *  @param _subtractedValue The reduction of spending allocation in base units.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
}
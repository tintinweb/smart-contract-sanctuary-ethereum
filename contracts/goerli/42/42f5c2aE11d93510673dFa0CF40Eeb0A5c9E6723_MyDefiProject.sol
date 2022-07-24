// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CTokenInterface.sol";
import "./ComptrollerInterface.sol";
import "./PriceOracleInterface.sol";

/// @title Compound Experiment
/// @author Patrick Keenan
/// @notice You can use this contract to borrow/lend with Compound on Rinkeby
/// @dev See Eat The Blocks for more info: https://github.com/jklepatch/eattheblocks/blob/master/defi-development-mastery/2-integrating-defi-protocols/5-homework/contracts/MyDeFiProject.sol
/// @custom:experimental This is an experimental contract.
contract MyDefiProject {
    ComptrollerInterface public comptroller;
    PriceOracleInterface public priceOracle;

    constructor(address _comptroller, address _priceOracle) {
        comptroller = ComptrollerInterface(_comptroller);
        priceOracle = PriceOracleInterface(_priceOracle);
    }

    function supply(address cTokenAddress, uint underlyingAmount) public {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint result = cToken.mint(underlyingAmount);
        require(
            result == 0,
            "cToken#mint() failed. see Compound ErrorReporter.sol for details"
        );
    }

    function redeem(address cTokenAddress, uint cTokenAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        uint result = cToken.redeem(cTokenAmount);
        require(
            result == 0,
            "cToken#redeem() failed. see Compound ErrorReporter.sol for more details"
        );
    }

    function enterMarket(address cTokenAddress) external {
        address[] memory markets = new address[](1);
        markets[0] = cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(markets);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }
    }

    function borrow(address cTokenAddress, uint borrowAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        uint result = cToken.borrow(borrowAmount);
        require(
            result == 0,
            "cToken#borrow() failed. see Compound ErrorReporter.sol for details"
        );
    }

    function repayBorrow(address cTokenAddress, uint underlyingAmount)
        external
    {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying();
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint result = cToken.repayBorrow(underlyingAmount);
        require(
            result == 0,
            "cToken#borrow() failed. see Compound ErrorReporter.sol for details"
        );
    }

    function getMaxBorrow(address cTokenAddress) external view returns (uint) {
        (uint result, uint liquidity, uint shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(
            result == 0,
            "comptroller#getAccountLiquidity() failed. see Compound ErrorReporter.sol for details"
        );
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account does not have collateral");
        uint underlyingPrice = priceOracle.getUnderlyingPrice(cTokenAddress);
        return liquidity / underlyingPrice;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint[] memory);

    function getAccountLiquidity(address owner)
        external
        view
        returns (
            uint,
            uint,
            uint
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface PriceOracleInterface {
    function getUnderlyingPrice(address asset) external view returns (uint);
}
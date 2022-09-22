// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ICeresCoin.sol";
import "./interfaces/ICeresFactory.sol";
import "./interfaces/ICeresBank.sol";

contract CeresSwap {

    ICeresCoin public crs;
    ICeresCoin public veCrs;
    ICeresFactory public factory;
    uint256 public swapRate;

    event Swapped(address indexed account, uint256 amountIn, uint256 amountOut);

    modifier onlyOwnerOrGovernor() {
        require(msg.sender == factory.owner() || msg.sender == factory.governorTimelock(),
            "Only owner or governor timelock!");
        _;
    }

    constructor(address _crs, address _veCrs, address _ceresFactory) {
        crs = ICeresCoin(_crs);
        veCrs = ICeresCoin(_veCrs);
        factory = ICeresFactory(_ceresFactory);
        swapRate = 1e18;
    }

    function swap(address to, uint256 amountIn) external {
        require(veCrs.balanceOf(msg.sender) >= amountIn, "CeresSwap: Your veCRS balance is not enough!");
        require(ICeresBank(factory.ceresBank()).ascPriceAnchored(), "CeresSwap: Can not swap under anchor price!");
        uint256 amountOut = amountIn * swapRate / 1e18;
        require(crs.balanceOf(address(this)) >= amountOut, "CeresSwap: Swap pool CRS balance is not enough!");

        // swap
        ICeresCoin(veCrs).burn(msg.sender, amountIn);
        crs.transfer(to, amountOut);
        emit Swapped(to, amountIn, amountOut);
    }

    function setCeresFactory(address _ceresFactory) external onlyOwnerOrGovernor {
        factory = ICeresFactory(_ceresFactory);
    }

    function setSwapRate(uint256 _swapRate) external onlyOwnerOrGovernor {
        swapRate = _swapRate;
    }
    
    function withdraw(address to, uint256 amount) external onlyOwnerOrGovernor {
        require(crs.balanceOf(address(this)) >= amount, "CeresSwap: balance is not enough!");
        crs.transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresBank {

    struct CollateralConfig {
        uint256 collateralRatio;
        uint256 volatileRatio;
        uint256 minimumRatio;
        uint256 ratioStep;
    }
    
    struct MintResult {
        uint256 ascTotal;
        uint256 ascToGovernor;
        uint256 ascToCol;
        uint256 ascToCrs;
        uint256 colAmount;
        uint256 crsAmount;
    }
    
    /* views */
    function ascPriceAnchored() external view returns(bool);
    function currentRedeemToken() external view returns(address);

    /* functions */
    function mint(address collateral, uint256 amount) external returns (MintResult memory result);
    function redeem(address collateral, uint256 ascAmount) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICeresCoin is IERC20Metadata {

    /* ---------- Functions ---------- */
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address token;
        address staking;
        address priceFeed;
        bool isChainlinkFeed;
        bool isVolatile;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function ceresBank() external view returns (address);
    function ceresReward() external view returns (address);
    function ceresMiner() external view returns (address);
    function ceresSwap() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getPriceFeed(address token) external view returns (address);
    function isStaking(address sender) external view returns (bool);
    function tokens(uint256 index) external view returns (address);
    function owner() external view returns (address);
    function governorTimelock() external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getTokenPrice(address token) external view returns(uint256);
    function isChainlinkFeed(address token) external view returns (bool);
    function isVolatile(address token) external view returns (bool);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);
    function oraclePeriod() external view returns (uint256);
    
    /* ---------- Public Functions ---------- */
    function updateOracles(address[] memory _tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, address staking, address oracle, bool _isStakingRewards, bool _isStakingMineable) external;
    function removeStaking(address token, address staking) external;
    /* ---------- RRA ---------- */
    function createStaking(address token, address chainlinkFeed, address quoteToken) external returns (address staking);
    function createOracle(address token, address quoteToken) external returns (address);
}
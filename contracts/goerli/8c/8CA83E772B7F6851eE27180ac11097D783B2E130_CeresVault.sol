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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICeresFactory.sol";

contract CeresVault {

    ICeresFactory public ceresFactory;

    modifier onlyOwner() {
        require(msg.sender == ceresFactory.owner(), "Only owner!");
        _;
    }

    constructor (address _ceresFactory) {
        ceresFactory = ICeresFactory(_ceresFactory);
    }

    function withdraw(address to, address[] calldata tokens, uint256[] calldata amounts) external onlyOwner {
        require(tokens.length == amounts.length, "CeresVault: Invalid length!");

        for (uint256 i = 0; i < tokens.length; i++) {
            address _token = tokens[i];
            uint256 _amount = amounts[i];
            require(_amount <= IERC20(_token).balanceOf(address(this)), "CeresVault: Vault balance is not enough!");
            IERC20(_token).transfer(to, _amount);
        }
    }

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
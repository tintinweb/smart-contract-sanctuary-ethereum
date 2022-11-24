// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILenderStrategy {
    function aprAfterDebtChange(
        int256 _delta
    ) external view returns (uint256 _apr);
}

contract LenderDebtManager {
    IVault public vault;
    IERC20 public asset;
    address[] public strategies;

    uint256 public lastBlockUpdate;

    constructor(IVault _vault) {
        vault = _vault;
        asset = IERC20(_vault.asset());
    }

    function addStrategy(address _strategy /* onlyAuthorized */) external {
        require(vault.strategies(_strategy).activation != 0);

        for (uint256 i = 0; i < strategies.length; ++i) {
            if (strategies[i] == _strategy) return;
        }

        strategies.push(_strategy);
    }

    // TODO: Permissionless remove when not in vault, permissioned when in vault
    function removeStrategy(address _strategy /* onlyAuthorized */) external {
        uint256 strategyCount = strategies.length;
        for (uint256 i = 0; i < strategyCount; ++i) {
            if (strategies[i] == _strategy) {
                // if not last element
                if (i != strategyCount - 1) {
                    strategies[i] = strategies[strategyCount - 1];
                }
                strategies.pop();
                return;
            }
        }
    }

    function updateAllocations() public {
        (uint256 _lowest, , uint256 _highest, ) = estimateAdjustPosition();

        address _lowestStrategy = strategies[_lowest];
        address _highestStrategy = strategies[_highest];
        uint256 _lowestCurrentDebt = vault
            .strategies(_lowestStrategy)
            .current_debt;
        uint256 _highestCurrentDebt = vault
            .strategies(_highestStrategy)
            .current_debt;

        vault.update_debt(_lowestStrategy, 0);
        vault.update_debt(
            _highestStrategy,
            _lowestCurrentDebt + _highestCurrentDebt
        );
    }

    //estimates highest and lowest apr lenders. Public for debugging purposes but not much use to general public
    function estimateAdjustPosition()
        public
        view
        returns (
            uint256 _lowest,
            uint256 _lowestApr,
            uint256 _highest,
            uint256 _potential
        )
    {
        uint256 strategyCount = strategies.length;
        if (strategyCount == 0) {
            return (type(uint256).max, 0, type(uint256).max, 0);
        }

        if (strategyCount == 1) {
            ILenderStrategy _strategy = ILenderStrategy(strategies[0]);
            uint256 apr = _strategy.aprAfterDebtChange(int256(0));
            return (0, apr, 0, apr);
        }

        //all loose assets are to be invested
        uint256 looseAssets = vault.total_idle();

        // our simple algo
        // get the lowest apr strat
        // cycle through and see who could take its funds plus want for the highest apr
        _lowestApr = type(uint256).max;
        _lowest = 0;
        uint256 lowestNav = 0;
        for (uint256 i = 0; i < strategyCount; ++i) {
            ILenderStrategy _strategy = ILenderStrategy(strategies[i]);
            uint256 _strategyNav = vault
                .strategies(address(_strategy))
                .current_debt;
            if (_strategyNav > 0) {
                uint256 apr = _strategy.aprAfterDebtChange(int256(0));
                if (apr < _lowestApr) {
                    _lowestApr = apr;
                    _lowest = i;
                    lowestNav = _strategyNav;
                }
            }
        }

        uint256 toAdd = lowestNav + looseAssets;

        uint256 highestApr = 0;
        _highest = 0;

        for (uint256 i = 0; i < strategyCount; ++i) {
            uint256 apr;
            ILenderStrategy _strategy = ILenderStrategy(strategies[i]);
            apr = _strategy.aprAfterDebtChange(int256(toAdd));

            if (apr > highestApr) {
                highestApr = apr;
                _highest = i;
                _potential = apr;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IVault {
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    function asset() external view returns (address _asset);

    function decimals() external view returns (uint256);

    // HashMap that records all the strategies that are allowed to receive assets from the vault
    function strategies(
        address _strategy
    ) external view returns (StrategyParams memory _params);

    // Current assets held in the vault contract. Replacing balanceOf(this) to avoid price_per_share manipulation
    function total_idle() external view returns (uint256);

    function update_debt(
        address strategy,
        uint256 target_debt
    ) external returns (uint256);
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
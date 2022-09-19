// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IMarket.sol";
import "./IVault.sol";

contract Registry {

    mapping(address => address) public underlying;
    address[] public markets;
    address[] public vaults;

    function marketCount() external view returns (uint256) {
        return markets.length + 1;
    }

    function vaultCount() external view returns (uint256) {
        return vaults.length + 1;
    }

    function addVault(address vault) external {
        address _underlying = IVault(vault).asset();
        require(underlying[_underlying] == address(0), "Vault already added");

        vaults.push(vault);
        underlying[_underlying] = vault; // underlying to vault

        emit VaultAdded(vault);
    }

    function addMarket(address market) external {
        markets.push(market);
        emit MarketAdded(market);
    }

    event MarketAdded(address indexed market);
    event VaultAdded(address indexed vault);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function asset() external view returns (address assetTokenAddress);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function getPerformance() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function withdraw() external;

    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IMarket {
    function getTarget() external view returns (uint8);
    function getTotalInplay() external view returns (uint256);
    //function getInplayCount() external view returns (uint256);
    function getBetByIndex(uint256 index) external view returns (uint256, uint256, uint256, bool, address);
    function getOdds(int wager, int256 odds, bytes32 propositionId) external view returns (int256);
    function getVaultAddress() external view returns (address);
    function back(bytes32 nonce, bytes32 propositionId, bytes32 marketId, uint256 wager, uint256 odds, uint256 close, uint256 end, bytes calldata signature) external returns (uint256);
    function settle(uint256 id, bytes calldata signature) external;
}

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
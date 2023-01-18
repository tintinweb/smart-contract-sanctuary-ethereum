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

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./interfaces/IERC20RootVault.sol";
import "./interfaces/IMellowMultiVaultRouter.sol";
import "./interfaces/IMarginEngine.sol";
import "./interfaces/IVoltzVault.sol";

// @dev These functions are not gas efficient and should _not_ be called on chain.
contract MellowContractLens {
    struct RootVaultInfo {
        // vault-specific
        IERC20RootVault rootVault;
        uint256 latestMaturity;
        bool vaultDeprecated;
        // user-specific
        uint256 pendingUserDeposit;
        uint256 committedUserDeposit;
        bool canWithdrawOrRollover;
    }

    struct RouterInfo {
        IERC20Minimal token;
        uint256 tokenBalance;
        uint256 ethBalance;
        bool isRegisteredForAutoRollover;
        RootVaultInfo[] erc20RootVaults;
    }

    function getOptimisersInfo(
        IMellowMultiVaultRouter[] memory routers,
        bool userInfo,
        address userAddress
    ) external view returns (RouterInfo[] memory) {
        RouterInfo[] memory routersInfo = new RouterInfo[](routers.length);

        for (uint256 i = 0; i < routers.length; ++i) {
            IMellowMultiVaultRouter router = routers[i];

            // Get token
            routersInfo[i].token = router.token();

            // Get root vaults
            IERC20RootVault[] memory rootVaults = router.getVaults();

            uint256[] memory lpTokenBalances = new uint256[](0);
            if (userInfo) {
                // Get user's LP token balances
                lpTokenBalances = router.getLPTokenBalances(
                    userAddress
                );

                // Get balances
                routersInfo[i].tokenBalance = routersInfo[i].token.balanceOf(
                    userAddress
                );
                routersInfo[i].ethBalance = userAddress.balance;

                // TODO: update once routers upgraded
                // // Get the status of user for auto-rollover
                routersInfo[i].isRegisteredForAutoRollover = router
                    .isRegisteredForAutoRollover(userAddress);
            }

            // Loop through all root vaults assigned to this router
            RootVaultInfo[] memory rootVaultsInfo = new RootVaultInfo[](
                rootVaults.length
            );
            for (uint256 j = 0; j < rootVaults.length; ++j) {
                IERC20RootVault rootVault = rootVaults[j];

                // Store root vault
                rootVaultsInfo[j].rootVault = rootVault;

                if (userInfo) {
                    // Track pending deposit
                    IMellowMultiVaultRouter.BatchedDeposit[]
                        memory batchedDeposits = router.getBatchedDeposits(j);
                    for (uint256 k = 0; k < batchedDeposits.length; ++k) {
                        if (batchedDeposits[k].author == userAddress) {
                            rootVaultsInfo[j]
                                .pendingUserDeposit += batchedDeposits[k]
                                .amount;
                        }
                    }

                    // Track committed deposit
                    uint256 totalLpTokens = rootVault.totalSupply();

                    if (totalLpTokens > 0) {
                        (uint256[] memory minTokenAmounts, ) = rootVault.tvl();
                        uint256 tvl = minTokenAmounts[0];

                        // TODO: add FullMath multiplication
                        rootVaultsInfo[j].committedUserDeposit +=
                            (lpTokenBalances[j] * tvl) /
                            totalLpTokens;
                    }

                    // TODO: update once routers upgraded
                    // Get ability to withdraw or rollover
                    rootVaultsInfo[j].canWithdrawOrRollover = router
                        .canWithdrawOrRollover(j, userAddress);
                }

                // Get latest maturity of the underlying margin engines
                uint256[] memory subvaultNFTs = rootVault.subvaultNfts();

                for (uint256 k = 1; k < subvaultNFTs.length; k++) {
                    address voltzVault = rootVault.subvaultAt(k);
                    IMarginEngine marginEngine = IVoltzVault(voltzVault)
                        .marginEngine();
                    uint256 maturity = marginEngine.termEndTimestampWad() /
                        1e18;
                    if (maturity > rootVaultsInfo[j].latestMaturity) {
                        rootVaultsInfo[j].latestMaturity = maturity;
                    }
                }

                // Get whether the vault is deprecated or not
                rootVaultsInfo[j].vaultDeprecated = router.isVaultDeprecated(j);
            }

            routersInfo[i].erc20RootVaults = rootVaultsInfo;
        }

        return routersInfo;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

/// @title Minimal ERC20 interface for Voltz
/// @notice Contains a subset of the full ERC20 interface that is used in Voltz
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev Returns the number of decimals used to get its user representation.
    // For example, if decimals equals 2, a balance of 505 tokens should be displayed to a user as 5,05 (505 / 10 ** 2).
    // Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
    function decimals() external view returns (uint8);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVaultGovernance.sol";

interface IERC20RootVault is IERC20 {
    /// @notice The function of depositing the amount of tokens in exchange
    /// @param tokenAmounts Array of amounts of tokens for deposit
    /// @param minLpTokens Minimal value of LP tokens
    /// @param vaultOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after deposit
    function deposit(
        uint256[] memory tokenAmounts,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The function of withdrawing the amount of tokens in exchange
    /// @param to Address to which the withdrawal will be sent
    /// @param lpTokenAmount LP token amount, that requested for withdraw
    /// @param minTokenAmounts Array of minmal remining wtoken amounts after withdrawal
    /// @param vaultsOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after withdrawal
    function withdraw(
        address to,
        uint256 lpTokenAmount,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Get all subvalutNfts in the current Vault
    /// @return subvaultNfts Subvaults of NTFs
    function subvaultNfts() external view returns (uint256[] memory);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Get subvault by index
    /// @param index Index of subvault
    /// @return address Address of the contract
    function subvaultAt(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface IMarginEngine {
    /// @notice The unix termEndTimestamp of the MarginEngine in Wad
    /// @return Term End Timestamp in Wad
    function termEndTimestampWad() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IWETH.sol";
import "../interfaces/IERC20RootVault.sol";

interface IMellowMultiVaultRouter {
    struct BatchedDeposit {
        address author;
        uint256 amount;
    }

    struct BatchedDeposits {
        mapping(uint256 => BatchedDeposit) batch;
        uint256 current;
        uint256 size;
    }

    struct BatchedAutoRollover {
        uint256 fromVault;
        uint256 lpTokensAutoRolledOver;
    }

    struct BatchedAutoRollovers {
        mapping(uint256 => BatchedAutoRollover) batch;
        uint256 current;
        uint256 size;
    }

    // -------------------  INITIALIZER -------------------

    /// @notice Constructor for Proxies
    function initialize(
        IWETH weth_,
        IERC20Minimal token_,
        IERC20RootVault[] memory vaults_
    ) external;

    // -------------------  GETTERS -------------------

    /// @notice The official WETH of the network
    function weth() external view returns (IWETH);

    /// @notice The underlying token of the vaults
    function token() external view returns (IERC20Minimal);

    /// @notice Active batched deposits
    function getBatchedDeposits(uint256 index)
        external
        view
        returns (BatchedDeposit[] memory);

    /// @notice Get the LP token balances
    function getLPTokenBalances(address owner)
        external
        view
        returns (uint256[] memory);

    /// @notice All vaults assigned to this router
    function getVaults() external view returns (IERC20RootVault[] memory);

    /// @notice Checks if the vault is deprecated
    function isVaultDeprecated(uint256 index) external view returns (bool);

    // -------------------  CHECKS  -------------------

    function validWeights(uint256[] memory weights)
        external
        view
        returns (bool);

    function canWithdrawOrRollover(uint256 vaultIndex, address owner)
        external
        view
        returns (bool);

    // -------------------  SETTERS  -------------------

    /// @notice Add another vault to the router
    /// @param vault_ The new vault
    function addVault(IERC20RootVault vault_) external;

    /// @notice Deprecate vault
    /// @param index The index of the vault to be deprecated
    function deprecateVault(uint256 index) external;

    /// @notice Reactivate vault
    /// @param index The index of the vault to be deprecated
    function reactivateVault(uint256 index) external;

    // -------------------  DEPOSITS  -------------------

    /// @notice Deposit ETH to the router
    function depositEth(uint256[] memory weights) external payable;

    /// @notice Deposit ERC20 to the router
    function depositErc20(uint256 amount, uint256[] memory weights) external;

    /// @notice Deposit ETH to the router and registers for auto-rollover
    function depositEthAndRegisterForAutoRollover(
        uint256[] memory weights,
        bool registration
    ) external payable;

    /// @notice Deposit ERC20 to the router and registers for auto-rollover
    function depositErc20AndRegisterForAutoRollover(
        uint256 amount,
        uint256[] memory weights,
        bool registration
    ) external;

    // -------------------  BATCH PUSH  -------------------

    /// @notice Push the batched funds to Mellow
    function submitBatch(uint256 index, uint256 batchSize) external;

    // -------------------  WITHDRAWALS  -------------------

    /// @notice Burn the lp tokens and withdraw the funds
    function claimLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external;

    /// @notice Burn the lp tokens and rollover the funds according to the weights
    function rolloverLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions,
        uint256[] memory weights
    ) external;

    // -------------------  AUTO-ROLLOVERS  -------------------
    /// @notice Allow users to opt into and out of auto-rollover functionality
    function registerForAutoRollover(bool registration) external;

    /// @notice Roll over user funds from expired (deprecated) vault into new vault
    function triggerAutoRollover(uint256 vaultIndex) external;

    function setAutoRolloverWeights(uint256[] memory autoRolloverWeights)
        external;

    /// @notice Total LP Tokens to be auto-rolled over for given vault
    function totalAutoRolloverLPTokens(uint256 vaultIndex)
        external
        view
        returns (uint256);

    function isRegisteredForAutoRollover(address owner)
        external
        view
        returns (bool);

    /// @notice Batched auto-rollover deposits for given vault
    function getBatchedAutoRollovers(uint256 index)
        external
        view
        returns (BatchedAutoRollover[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVaultGovernance {

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IMarginEngine.sol";

interface IVoltzVault {
    /// @notice Reference to the margin engine of Voltz Protocol
    function marginEngine() external view returns (IMarginEngine);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";

interface IWETH is IERC20Minimal {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
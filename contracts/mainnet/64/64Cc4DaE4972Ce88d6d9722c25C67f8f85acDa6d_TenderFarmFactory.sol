// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ITenderFarm.sol";
import "../token/ITenderToken.sol";
import "../tenderizer/ITenderizer.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract TenderFarmFactory {
    ITenderFarm immutable farmTarget;

    constructor(ITenderFarm _farm) {
        farmTarget = _farm;
    }

    event NewTenderFarm(ITenderFarm farm, IERC20 stakeToken, ITenderToken rewardToken, ITenderizer tenderizer);

    function deploy(
        IERC20 _stakeToken,
        ITenderToken _rewardToken,
        ITenderizer _tenderizer
    ) external returns (ITenderFarm farm) {
        farm = ITenderFarm(Clones.clone(address(farmTarget)));

        require(farm.initialize(_stakeToken, _rewardToken, _tenderizer), "FAIL_INIT_TENDERFARM");

        emit NewTenderFarm(farm, _stakeToken, _rewardToken, _tenderizer);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ITenderToken.sol";
import "../tenderizer/ITenderizer.sol";

/**
 * @title TenderFarm
 * @notice TenderFarm is responsible for incetivizing liquidity providers, by accepting LP Tokens
 * and a proportionaly rewarding them with TenderTokens over time.
 */
interface ITenderFarm {
    /**
     * @notice Farm gets emitted when an account stakes LP tokens.
     * @param account the account for which LP tokens were staked
     * @param amount the amount of LP tokens staked
     */
    event Farm(address indexed account, uint256 amount);

    /**
     * @notice Unfarm gets emitted when an account unstakes LP tokens.
     * @param account the account for which LP tokens were unstaked
     * @param amount the amount of LP tokens unstaked
     */
    event Unfarm(address indexed account, uint256 amount);

    /**
     * @notice Harvest gets emitted when an accounts harvests outstanding
     * rewards.
     * @param account the account which harvested rewards
     * @param amount the amount of rewards harvested
     */
    event Harvest(address indexed account, uint256 amount);

    /**
     * @notice RewardsAdded gets emitted when new rewards are added
     * and a new epoch begins
     * @param amount amount of rewards that were addedd
     */
    event RewardsAdded(uint256 amount);

    function initialize(
        IERC20 _stakeToken,
        ITenderToken _rewardToken,
        ITenderizer _tenderizer
    ) external returns (bool);

    /**
     * @notice stake liquidity pool tokens to receive rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @param _amount amount of liquidity pool tokens to stake
     */
    function farm(uint256 _amount) external;

    /**
     * @notice allow spending token and stake liquidity pool tokens to receive rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @dev calls permit on LP Token.
     * @param _amount amount of liquidity pool tokens to stake
     * @param _deadline deadline of the permit
     * @param _v v of signed Permit message
     * @param _r r of signed Permit message
     * @param _s s of signed Permit message
     */
    function farmWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice stake liquidity pool tokens for a specific account so that it receives rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev staked tokens will belong to the account they are staked for.
     * @dev harvests current rewards before accounting updates are made.
     * @param _for account to stake for
     * @param _amount amount of liquidity pool tokens to stake
     */
    function farmFor(address _for, uint256 _amount) external;

    /**
     * @notice unstake liquidity pool tokens
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @param amount amount of liquidity pool tokens to stake
     */
    function unfarm(uint256 amount) external;

    /**
     * @notice harvest outstanding rewards
     * @dev reverts when trying to harvest multiple times if no new rewards have been added.
     * @dev emits an event with how many reward tokens have been harvested.
     */
    function harvest() external;

    /**
     * @notice add new rewards
     * @dev will 'start' a new 'epoch'.
     * @dev only callable by owner.
     * @param _amount amount of reward tokens to add
     */
    function addRewards(uint256 _amount) external;

    /**
     * @notice Check available rewards for an account.
     * @param _for address address of the account to check rewards for.
     * @return amount rewards for the provided account address.
     */
    function availableRewards(address _for) external view returns (uint256 amount);

    /**
     * @notice Check stake for an account.
     * @param _of address address of the account to check stake for.
     * @return amount LP tokens deposited for address
     */
    function stakeOf(address _of) external view returns (uint256 amount);

    /**
     * @notice Return the total amount of LP tokens staked in this farm.
     * @return stake total amount of LP tokens staked
     */
    function totalStake() external view returns (uint256 stake);

    /**
     * @notice Return the total amount of LP tokens staked
     * for the next reward epoch.
     * @return nextStake LP Tokens staked for next round
     */
    function nextTotalStake() external view returns (uint256 nextStake);

    /**
     * @notice Changes the tenderizer of the contract
     * @param _tenderizer address of the new tenderizer
     */
    function setTenderizer(ITenderizer _tenderizer) external;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../tenderizer/ITotalStakedReader.sol";

/**
 * @title Interest-bearing ERC20-like token for Tenderize protocol.
 * @author Tenderize <[email protected]>
 * @dev TenderToken balances are dynamic and are calculated based on the accounts' shares
 * and the total amount of Tokens controlled by the protocol. Account shares aren't
 * normalized, so the contract also stores the sum of all shares to calculate
 * each account's token balance which equals to:
 *
 * shares[account] * _getTotalPooledTokens() / _getTotalShares()
 */
interface ITenderToken {
    /**
     * @notice Initilize the TenderToken Contract
     * @param _name name of the token (steak)
     * @param _symbol symbol of the token (steak)
     * @param _stakedReader contract address implementing the ITotalStakedReader interface
     * @return a boolean value indicating whether the init succeeded.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        ITotalStakedReader _stakedReader
    ) external returns (bool);

    /**
     * @notice The number of decimals the TenderToken uses.
     * @return decimals the number of decimals for getting user representation of a token amount.
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice The total supply of tender tokens in existence.
     * @dev Always equals to `_getTotalPooledTokens()` since token amount
     * is pegged to the total amount of Tokens controlled by the protocol.
     * @return totalSupply total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Total amount of underlying tokens controlled by the Tenderizer.
     * @dev The sum of all Tokens balances in the protocol, equals to the total supply of TenderToken.
     * @return totalPooledTokens total amount of pooled tokens
     */
    function getTotalPooledTokens() external view returns (uint256);

    /**
     * @notice The total amount of shares in existence.
     * @dev The sum of all accounts' shares can be an arbitrary number, therefore
     * it is necessary to store it in order to calculate each account's relative share.
     * @return totalShares total amount of shares
     */
    function getTotalShares() external view returns (uint256);

    /**
     * @notice the amount of tokens owned by the `_account`.
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
        total Tokens controlled by the protocol. See `sharesOf`.
     * @param _account address of the account to check the balance for
     * @return balance token balance of `_account`
     */
    function balanceOf(address _account) external view returns (uint256);

    /**
     * @notice The amount of shares owned by an account
     * @param _account address of the account
     * @return shares the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) external view returns (uint256);

    /**
     * @notice The remaining number of tokens that `_spender` is allowed to spend
     * behalf of `_owner` through `transferFrom`. This is zero by default.
     * @dev This value changes when `approve` or `transferFrom` is called.
     * @param _owner address that approved the allowance
     * @param _spender address that is allowed to spend the allowance
     * @return allowance amount '_spender' is allowed to spend from '_owner'
     */
    function allowance(address _owner, address _spender) external view returns (uint256);

    /**
     * @notice The amount of shares that corresponds to `_tokens` protocol-controlled Tokens.
     * @param _tokens amount of tokens to calculate shares for
     * @return shares nominal amount of shares the tokens represent
     */
    function tokensToShares(uint256 _tokens) external view returns (uint256);

    /**
     * @notice The amount of tokens that corresponds to `_shares` token shares.
     * @param _shares the amount of shares to calculate the amount of tokens for
     * @return tokens the amount of tokens represented by the shares
     */
    function sharesToTokens(uint256 _shares) external view returns (uint256);

    /**
     * @notice Transfers `_amount` tokens from the caller's account to the `_recipient` account.
     * @param _recipient address of the recipient
     * @param _amount amount of tokens to transfer
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits a `Transfer` event.
     * @dev Requirements:
     * - `_recipient` cannot be the zero address.
     * - the caller must have a balance of at least `_amount`.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _amount amount of tokens to allow '_spender' to spend
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits an `Approval` event.
     * @dev Requirements:
     * - `_spender` cannot be the zero address.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function approve(address _spender, uint256 _amount) external returns (bool);

    /**
     * @notice Transfers `_amount` tokens from `_sender` to `_recipient` using the
     * allowance mechanism. `_amount` is then deducted from the caller's allowance.
     * @param _sender address of the account to transfer tokens from
     * @param _recipient address of the recipient
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits a `Transfer` event.
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_sender` and `_recipient` cannot be the zero addresses.
     * - `_sender` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least `_amount`.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _addedValue amount to add to allowance
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev This is an alternative to `approve` that can be used as a mitigation for problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_spender` cannot be the the zero address.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _subtractedValue amount to subtract from current allowance
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev This is an alternative to `approve` that can be used as a mitigation for problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);

    /**
     * @notice Mints '_amount' of tokens for '_recipient'
     * @param _recipient address to mint tokens for
     * @param _amount amount to mint
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Only callable by contract owner
     * @dev Calculates the amount of shares to create based on the specified '_amount'
     * and creates new shares rather than minting actual tokens
     * @dev '_recipient' should also deposit into Tenderizer
     * atomically to prevent diluation of existing particpants
     */
    function mint(address _recipient, uint256 _amount) external returns (bool);

    /**
     * @notice Burns '_amount' of tokens from '_recipient'
     * @param _account address to burn the tokens from
     * @param _amount amount to burn
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Only callable by contract owner
     * @dev Calculates the amount of shares to destroy based on the specified '_amount'
     * and destroy shares rather than burning tokens
     * @dev '_recipient' should also withdraw from Tenderizer atomically
     */
    function burn(address _account, uint256 _amount) external returns (bool);

    /**
     * @notice sets a TotalStakedReader to read the total staked tokens from
     * @param _stakedReader contract address implementing the ITotalStakedReader interface
     * @dev Only callable by contract owner.
     * @dev Used to determine TenderToken total supply.
     */
    function setTotalStakedReader(ITotalStakedReader _stakedReader) external;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tenderfarm/ITenderFarm.sol";

/**
 * @title Tenderizer is the base contract to be implemented.
 * @notice Tenderizer is responsible for all Protocol interactions (staking, unstaking, claiming rewards)
 * while also keeping track of user depsotis/withdrawals and protocol fees.
 * @dev New implementations are required to inherit this contract and override any required internal functions.
 */
interface ITenderizer {
    // Events

    /**
     * @notice Deposit gets emitted when an accounts deposits underlying tokens.
     * @param from the account that deposited
     * @param amount the amount of tokens deposited
     */
    event Deposit(address indexed from, uint256 amount);

    /**
     * @notice Stake gets emitted when funds are staked/delegated from the Tenderizer contract
     * into the underlying protocol.
     * @param node the address the funds are staked to
     * @param amount the amount staked
     */
    event Stake(address indexed node, uint256 amount);

    /**
     * @notice Unstake gets emitted when an account burns TenderTokens to unlock
     * tokens staked through the Tenderizer
     * @param from the account that unstaked
     * @param node the node in the underlying token from which tokens are unstaked
     * @param amount the amount unstaked
     */
    event Unstake(address indexed from, address indexed node, uint256 amount, uint256 unstakeLockID);

    /**
     * @notice Withdraw gets emitted when an account withdraws tokens that have been
     * succesfully unstaked and thus unlocked for withdrawal.
     * @param from the account withdrawing tokens
     * @param amount the amount being withdrawn
     * @param unstakeLockID the unstake lock ID being consumed
     */
    event Withdraw(address indexed from, uint256 amount, uint256 unstakeLockID);

    /**
     * @notice RewardsClaimed gets emitted when the Tenderizer processes staking rewards (or slashing)
     * from the underlying protocol.
     * @param stakeDiff the stake difference since the last event, can be negative in case slashing occured
     * @param currentPrincipal TVL after claiming rewards
     * @param oldPrincipal TVL before claiming rewards
     */
    event RewardsClaimed(int256 stakeDiff, uint256 currentPrincipal, uint256 oldPrincipal);

    /**
     * @notice ProtocolFeeCollected gets emitted when the treasury claims its outstanding
     * protocol fees.
     * @param amount the amount of fees claimed (in TenderTokens)
     */
    event ProtocolFeeCollected(uint256 amount);

    /**
     * @notice LiquidityFeeCollected gets emitted when liquidity provider fees are moved to the TenderFarm.
     * @param amount the amount of fees moved for farming
     */
    event LiquidityFeeCollected(uint256 amount);

    /**
     * @notice GovernanceUpdate gets emitted when a parameter on the Tenderizer gets updated.
     * @param param the parameter that got updated
     * @param oldValue oldValue of the parameter
      @param newValue newValue of the parameter
     */
    event GovernanceUpdate(string param, bytes oldValue, bytes newValue);

    /**
     * @notice Deposit tokens in Tenderizer.
     * @param _amount amount deposited
     * @dev doesn't actually stakes the tokens but aggregates the balance in the tenderizer
     * awaiting to be staked.
     * @dev requires '_amount' to be approved by '_from'.
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice Deposit tokens in Tenderizer with permit.
     * @param _amount amount deposited
     * @param _deadline deadline for the permit
     * @param _v from ECDSA signature
     * @param _r from ECDSA signature
     * @param _s from ECDSA signature
     * @dev doesn't actually stakes the tokens but aggregates the balance in the tenderizer
     * awaiting to be staked.
     * @dev requires '_amount' to be approved by '_from'.
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Stake '_amount' of tokens.
     * @param _amount amount to stake
     * @dev Only callable by Gov.
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Unstake '_amount' of tokens from '_account'.
     * @param _amount amount to unstake
     * @return unstakeLockID unstake lockID generated for unstake
     * @dev unstake from the default address.
     * @dev If '_amount' is 0, unstake the entire amount staked towards _account.
     */
    function unstake(uint256 _amount) external returns (uint256 unstakeLockID);

    /**
     * @notice RescueUnstake unstakes all tokens from underlying protocol
     * @return unstakeLockID unstake lockID generated for unstake
     * @dev Used to rescue all staked funds.
     */
    function rescueUnlock() external returns (uint256 unstakeLockID);

    /**
     * @notice Withdraw '_amount' of tokens previously unstaked by '_account'.
     * @param _unstakeLockID ID for the lock to request the withdraw for
     * @dev If '_amount' isn't specified all unstake tokens by '_account' will be withdrawn.
     * @dev Requires '_account' to have unstaked prior to calling withdraw.
     */
    function withdraw(uint256 _unstakeLockID) external;

    /**
     * @notice RescueWithdraw withdraws all tokens into the Tenderizer from the underlying protocol 
     * after the unlock period ends
     * @dev To be called after rescueUnlock() with the unstakeLockID returned there.
     * @dev Process unlocks/withdrawals before rescueWithdraw for integrations with WithdrawPools.
     */
    function rescueWithdraw(uint256 _unstakeLockID) external;

    /**
     * @notice Compound all the rewards and new deposits.
     * Claim staking rewards and earned fees for the underlying protocol and stake
     * any leftover token balance. Process Tender protocol fees if revenue is positive.
     */
    function claimRewards() external;

    /**
     * @notice Total Staked Tokens returns the total amount of underlying tokens staked by this Tenderizer.
     * @return totalStaked total amount staked by this Tenderizer
     */
    function totalStakedTokens() external view returns (uint256 totalStaked);

    /**
     * @notice Returns the number of tenderTokens to be minted for amountIn deposit.
     * @return depositOut number of tokens staked for `amountIn`.
     * @dev used by controller to calculate tokens to be minted before depositing.
     * @dev to be used when there a delegation tax is deducted, for eg. in Graph.
     */
    function calcDepositOut(uint256 _amountIn) external returns (uint256 depositOut);

    // Governance setter funtions

    function setGov(address _gov) external;

    function setNode(address _node) external;

    function setSteak(IERC20 _steak) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setLiquidityFee(uint256 _liquidityFee) external;

    function setStakingContract(address _stakingContract) external;

    function setTenderFarm(ITenderFarm _tenderFarm) external;
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITotalStakedReader {
    /**
     * @notice Total Staked Tokens returns the total amount of underlying tokens staked by this Tenderizer.
     * @return _totalStakedTokens total amount staked by this Tenderizer
     */
    function totalStakedTokens() external view returns (uint256 _totalStakedTokens);
}
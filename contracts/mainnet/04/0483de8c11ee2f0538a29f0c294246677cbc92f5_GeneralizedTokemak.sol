pragma solidity ^0.8.13;

// solmate
import "solmate/utils/SafeTransferLib.sol";

// olympus
import "../../types/BaseAllocator.sol";

// tokemak
import {UserVotePayload} from "./interfaces/UserVotePayload.sol";
import {ILiquidityPool} from "./interfaces/ILiquidityPool.sol";
import {IRewardHash} from "./interfaces/IRewardHash.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {IManager} from "./interfaces/IManager.sol";
import {IRewards} from "./interfaces/IRewards.sol";

/// INLINE

interface ITokemakVoting {
    function vote(UserVotePayload memory userVotePayload) external;
}

uint256 constant nmax = type(uint256).max;

library TokemakAllocatorLib {
    function deposit(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).deposit(amount);
    }

    function requestWithdrawal(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).requestWithdrawal(amount);
    }

    function withdraw(address reactor, uint256 amount) internal {
        ILiquidityPool(reactor).withdraw(amount);
    }

    function requestedWithdrawals(address reactor)
        internal
        view
        returns (uint256 minCycle, uint256 amount)
    {
        (minCycle, amount) = ILiquidityPool(reactor).requestedWithdrawals(
            address(this)
        );
    }

    function balanceOf(address reactor, address owner)
        internal
        view
        returns (uint256)
    {
        return ERC20(reactor).balanceOf(owner);
    }

    function nmaxarr(uint256 l) internal pure returns (uint256[] memory arr) {
        arr = new uint256[](l);

        for (uint256 i; i < l; i++) {
            arr[i] = nmax;
        }
    }
}

struct TokemakData {
    address voting;
    address staking;
    address rewards;
    address manager;
}

struct PayloadData {
    uint128 amount;
    uint64 cycle;
    uint64 v;
    bytes32 r;
    bytes32 s;
}

error GeneralizedTokemak_ArbitraryCallFailed();
error GeneralizedTokemak_MustInitializeTotalWithdraw();
error GeneralizedTokemak_WithdrawalNotReady(uint256 tAssetIndex_);

contract GeneralizedTokemak is BaseAllocator {
    using SafeTransferLib for ERC20;
    using TokemakAllocatorLib for address;

    address immutable self;

    ITokemakVoting public voting;
    IStaking public staking;
    IRewards public rewards;
    IManager public manager;

    ERC20 public toke;

    address[] public reactors;

    PayloadData public nextPayloadData;

    bool public mayClaim;

    bool public totalWithdrawInitialized;

    // done for ease of verif at time of deployment
    // if you are intending ANYTHING doublecheck these addr
    constructor()
        BaseAllocator(
            AllocatorInitData(
                IOlympusAuthority(0x1c21F8EA7e39E2BA00BC12d2968D63F4acb38b7A),
                ITreasuryExtender(0xb32Ad041f23eAfd682F57fCe31d3eA4fd92D17af),
                new ERC20[](0)
            )
        )
    {
        self = address(this);

        toke = ERC20(0x2e9d63788249371f1DFC918a52f8d799F4a38C94);

        _setTokemakData(
            TokemakData(
                0x43094eD6D6d214e43C31C38dA91231D2296Ca511, // voting
                0x96F98Ed74639689C3A11daf38ef86E59F43417D3, // staking
                0x79dD22579112d8a5F7347c5ED7E609e60da713C5, // rewards
                0xA86e412109f77c45a3BC1c5870b880492Fb86A14 // manager
            )
        );
    }

    // ######################## ~ SAFETY ~ ########################

    function executeArbitrary(address target, bytes memory data)
        external
        onlyGuardian
    {
        (bool success, ) = target.call(data);
        if (!success) revert GeneralizedTokemak_ArbitraryCallFailed();
    }

    // ######################## ~ IMPORTANT OVERRIDES ~ ########################

    function _update(uint256 id)
        internal
        override
        returns (uint128 gain, uint128 loss)
    {
        uint256 index = tokenIds[id];
        address reactor = reactors[index];
        ERC20 underl = _tokens[index];

        if (mayClaim) {
            PayloadData memory payData = nextPayloadData;

            rewards.claim(
                IRewards.Recipient(1, payData.cycle, self, payData.amount),
                uint8(payData.v),
                payData.r,
                payData.s
            );

            mayClaim = false;
        }

        uint256 bal = toke.balanceOf(self);

        if (0 < bal) {
            toke.approve(address(staking), bal);
            staking.deposit(bal);
        }

        bal = underl.balanceOf(self);

        if (0 < bal) {
            underl.approve(reactor, bal);
            reactor.deposit(bal);
        }

        uint128 current = uint128(reactor.balanceOf(self));
        uint128 last = extender.getAllocatorPerformance(id).gain +
            uint128(extender.getAllocatorAllocated(id));

        if (last <= current) gain = current - last;
        else loss = last - current;
    }

    /// @dev If amounts.length is == _tokens.length then you are requestingWithdrawals,
    /// otherwise you are withdrawing. amount beyond _tokens.length does not matter.
    /// @param amounts amounts to withdraw, if amount for one index is type(uint256).max, then take all
    function deallocate(uint256[] memory amounts) public override onlyGuardian {
        uint256 lt = _tokens.length;
        uint256 la = amounts.length;

        for (uint256 i; i <= lt; i++) {
            if (amounts[i] != 0) {
                address reactor;

                if (i < lt) reactor = reactors[i];

                if (lt + 1 < la) {
                    if (amounts[i] == nmax)
                        amounts[i] = i < lt
                            ? reactor.balanceOf(self)
                            : staking.balanceOf(self);

                    if (0 < amounts[i])
                        if (i < lt) reactor.requestWithdrawal(amounts[i]);
                        else staking.requestWithdrawal(amounts[i], 0);
                } else {
                    uint256 cycle = manager.getCurrentCycleIndex();

                    (uint256 minCycle, uint256 amount) = i < lt
                        ? reactor.requestedWithdrawals()
                        : staking.withdrawalRequestsByIndex(self, 0);

                    if (amounts[i] == nmax) amounts[i] = amount;

                    if (cycle < minCycle)
                        revert GeneralizedTokemak_WithdrawalNotReady(i);

                    if (0 < amounts[i])
                        if (i < lt) reactor.withdraw(amounts[i]);
                        else staking.withdraw(amounts[i]);
                }
            }
        }
    }

    function _prepareMigration() internal override {
        if (!totalWithdrawInitialized) {
            revert GeneralizedTokemak_MustInitializeTotalWithdraw();
        } else {
            deallocate(TokemakAllocatorLib.nmaxarr(reactors.length + 1));
        }
    }

    function _deactivate(bool panic) internal override {
        if (panic) {
            deallocate(TokemakAllocatorLib.nmaxarr(reactors.length + 2));
            totalWithdrawInitialized = true;
        }
    }

    function _activate() internal override {
        totalWithdrawInitialized = false;
    }

    // ######################## ~ SETTERS ~ ########################

    function vote(UserVotePayload calldata payload) external onlyGuardian {
        voting.vote(payload);
    }

    function updateClaimPayload(PayloadData calldata data)
        external
        onlyGuardian
    {
        nextPayloadData = data;
        mayClaim = true;
    }

    function addToken(address token, address reactor) external onlyGuardian {
        ERC20(token).safeApprove(address(extender), type(uint256).max);
        ERC20(reactor).safeApprove(address(extender), type(uint256).max);
        _tokens.push(ERC20(token));
        reactors.push(reactor);
    }

    function setTokemakData(TokemakData memory tokeData) external onlyGuardian {
        _setTokemakData(tokeData);
    }

    // ######################## ~ GETTERS ~ ########################

    function tokeAvailable(uint256 scheduleIndex)
        public
        view
        virtual
        returns (uint256)
    {
        return staking.availableForWithdrawal(self, scheduleIndex);
    }

    function tokeDeposited() public view virtual returns (uint256) {
        return staking.balanceOf(self);
    }

    // ######################## ~ GETTER OVERRIDES ~ ########################

    function amountAllocated(uint256 id)
        public
        view
        override
        returns (uint256)
    {
        return reactors[tokenIds[id]].balanceOf(self);
    }

    function name() external pure override returns (string memory) {
        return "GeneralizedTokemak";
    }

    function utilityTokens() public view override returns (ERC20[] memory) {
        uint256 l = reactors.length + 1;
        ERC20[] memory utils = new ERC20[](l);

        for (uint256 i; i < l - 1; i++) {
            utils[i] = ERC20(reactors[i]);
        }

        utils[l - 1] = toke;
        return utils;
    }

    function rewardTokens() public view override returns (ERC20[] memory) {
        ERC20[] memory reward = new ERC20[](1);
        reward[0] = toke;
        return reward;
    }

    // ######################## ~ INTERNAL SETTERS ~ ########################

    function _setTokemakData(TokemakData memory tokeData) internal {
        voting = ITokemakVoting(tokeData.voting);
        staking = IStaking(tokeData.staking);
        rewards = IRewards(tokeData.rewards);
        manager = IManager(tokeData.manager);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

pragma solidity ^0.8.10;

// interfaces
import "../interfaces/IAllocator.sol";
import "olympus/interfaces/ITreasury.sol";

// types
import "olympus/types/OlympusAccessControlledV2.sol";

// libraries
import "solmate/utils/SafeTransferLib.sol";

error BaseAllocator_AllocatorNotActivated();
error BaseAllocator_AllocatorNotOffline();
error BaseAllocator_Migrating();
error BaseAllocator_NotMigrating();
error BaseAllocator_OnlyExtender(address sender);

/**
 * @title BaseAllocator
 * @notice
 *  This abstract contract serves as a template for writing new Olympus Allocators.
 *  Many of the functionalities regarding handling of Treasury funds by the Guardian have
 *  been delegated to the `TreasuryExtender` contract, and thus an explanation for them can be found
 *  in `TreasuryExtender.sol`.
 *
 *  The main purpose of this abstract contract and the `IAllocator` interface is to provide
 *  a unified framework for how an Allocator should behave. Below an explanation of how
 *  we expect an Allocator to behave in general, mentioning the most important points.
 *
 *  Activation:
 *   - An Allocator is first deployed with all necessary arguments.
 *     Thereafter, each deposit is registered with the `TreasuryExtender`.
 *     This assigns a unique id for each deposit (set of allocations) in an Allocator.
 *   - Next, the Allocators allocation and loss limits are set via the extender function.
 *   - Finally, the Allocator is activated by calling `activate`.
 *
 *  Runtime:
 *   The Allocator is in communication with the Extender, it must inform the Extender
 *   what the status of the tokens is which were allocated. We only care about noting down
 *   their status in the Extender. A quick summary of the important functions on this topic:
 *
 *   - `update(uint256 id)` is the main function that deals with state reporting, where
 *     `_update(uint256 id)` is the internal function to implement, which should update Allocator
 *     internal state. `update(uint256 id)` then continues to report the Allocators state via `report`
 *     to the extender. `_update(uint256 id)` should handle _investment_ of funds present in Contract.
 *
 *   - `deallocate` should handle allocated token withdrawal, preparing the tokens to be withdrawn
 *     by the Extender. It is not necessary to handle approvals for this token, because it is automatically
 *     approved in the constructor. For other token withdrawals, it is assumed that reward tokens will
 *     either be sold into underlying (allocated) or that they will simply rest in the Contract, being reward tokens.
 *     Please also check function documentation.
 *
 *   - `rewardTokens` and `utilityTokens` should return the above mentioned simple reward tokens for the former case,
 *     while utility tokens should be those tokens which are continously reinvested or otherwise used by the contract
 *     in order to accrue more rewards. A reward token can also be a utility token, but then one must prepare them
 *     separately for withdrawal if they are to be returned to the treasury.
 *
 *  Migration & Deactivation:
 *   - `prepareMigration()` together with the virtual `_prepareMigration()` sets the state of the Allocator into
 *     MIGRATING, disabling further token deposits, enabling only withdrawals, and preparing all funds for withdrawal.
 *
 *   - `migrate` then executes the migration and also deactivates the Allocator.
 *
 *   - `deactivate` sets `status` to OFFLINE, meaning it simply deactivates the Allocator. It can be passed
 *     a panic boolean, meaning it handles deactivation logic in `deactivate`. The Allocator panic deactivates if
 *     this state if the loss limit is reached via `update`. The Allocator can otherwise also simply be deactivated
 *     and funds transferred back to the Treasury.
 *
 *  This was a short summary of the Allocator lifecycle.
 */
abstract contract BaseAllocator is OlympusAccessControlledV2, IAllocator {
    using SafeTransferLib for ERC20;

    // Indices which represent the ids of the deposits in the `TreasuryExtender`
    uint256[] internal _ids;

    // The allocated (underlying) tokens of the Allocator
    ERC20[] internal _tokens;

    // From deposit id to the token's id
    mapping(uint256 => uint256) public tokenIds;

    // Allocator status: OFFLINE, ACTIVATED, MIGRATING
    AllocatorStatus public status;

    // The extender with which the Allocator communicates.
    ITreasuryExtender public immutable extender;

    constructor(AllocatorInitData memory data)
        OlympusAccessControlledV2(data.authority)
    {
        _tokens = data.tokens;
        extender = data.extender;

        for (uint256 i; i < data.tokens.length; i++) {
            data.tokens[i].approve(address(data.extender), type(uint256).max);
        }

        emit AllocatorDeployed(address(data.authority), address(data.extender));
    }

    /////// MODIFIERS

    modifier onlyExtender() {
        _onlyExtender(msg.sender);
        _;
    }

    modifier onlyActivated() {
        _onlyActivated(status);
        _;
    }

    modifier onlyOffline() {
        _onlyOffline(status);
        _;
    }

    modifier notMigrating() {
        _notMigrating(status);
        _;
    }

    modifier isMigrating() {
        _isMigrating(status);
        _;
    }

    /////// VIRTUAL FUNCTIONS WHICH NEED TO BE IMPLEMENTED
    /////// SORTED BY EXPECTED COMPLEXITY AND DEPENDENCY

    /**
     * @notice
     *  Updates an Allocators state.
     * @dev
     *  This function should be implemented by the developer of the Allocator.
     *  This function should fulfill the following purposes:
     *   - invest token specified by deposit id
     *   - handle rebalancing / harvesting for token as needed
     *   - calculate gain / loss for token and return those values
     *   - handle any other necessary runtime calculations, such as fees etc.
     *
     *  In essence, this function should update the main runtime state of the Allocator
     *  so that everything is properly invested, harvested, accounted for.
     * @param id the id of the deposit in the `TreasuryExtender`
     */
    function _update(uint256 id)
        internal
        virtual
        returns (uint128 gain, uint128 loss);

    /**
     * @notice
     *  Deallocates tokens, prepares tokens for return to the Treasury.
     * @dev
     *  This function should deallocate (withdraw) `amounts` of each token so that they may be withdrawn
     *  by the TreasuryExtender. Otherwise, this function may also prepare the withdraw if it is time-bound.
     * @param amounts is the amount of each of token from `_tokens` to withdraw
     */
    function deallocate(uint256[] memory amounts) public virtual;

    /**
     * @notice
     *  Handles deactivation logic for the Allocator.
     */
    function _deactivate(bool panic) internal virtual;

    /**
     * @notice
     *  Handles migration preparatory logic.
     * @dev
     *  Within this function, the developer should arrange the withdrawal of all assets for migration.
     *  A useful function, say, to be passed into this could be `deallocate` with all of the amounts,
     *  so with n places for n-1 utility tokens + 1 allocated token, maxed out.
     */
    function _prepareMigration() internal virtual;

    /**
     * @notice
     *  Should estimate total amount of Allocated tokens
     * @dev
     *  The difference between this and `treasury.getAllocatorAllocated`, is that the latter is a static
     *  value recorded during reporting, but no data is available on _new_ amounts after reporting.
     *  Thus, this should take into consideration the new amounts. This can be used for say aTokens.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function amountAllocated(uint256 id) public view virtual returns (uint256);

    /**
     * @notice
     *  Should return all reward token addresses
     */
    function rewardTokens() public view virtual returns (ERC20[] memory);

    /**
     * @notice
     *  Should return all utility token addresses
     */
    function utilityTokens() public view virtual returns (ERC20[] memory);

    /**
     * @notice
     *  Should return the Allocator name
     */
    function name() external view virtual returns (string memory);

    /////// IMPLEMENTATION OPTIONAL

    /**
     * @notice
     *  Should handle activation logic
     * @dev
     *  If there is a need to handle any logic during activation, this is the function you should implement it into
     */
    function _activate() internal virtual {}

    /////// FUNCTIONS

    /**
     * @notice
     *  Updates an Allocators state and reports to `TreasuryExtender` if necessary.
     * @dev
     *  Can only be called by the Guardian.
     *  Can only be called while the Allocator is activated.
     *
     *  This function should update the Allocators internal state via `_update`, which should in turn
     *  return the `gain` and `loss` the Allocator has sustained in underlying allocated `token` from `_tokens`
     *  decided by the `id`.
     *  Please check the docs on `_update` to see what its function should be.
     *
     *  `_lossLimitViolated` checks if the Allocators is above its loss limit and deactivates it in case
     *  of serious losses. The loss limit should be set to some value which is unnacceptable to be lost
     *  in the case of normal runtime and thus require a panic shutdown, whatever it is defined to be.
     *
     *  Lastly, the Allocator reports its state to the Extender, which handles gain, loss, allocated logic.
     *  The documentation on this can be found in `TreasuryExtender.sol`.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function update(uint256 id) external override onlyGuardian onlyActivated {
        // effects
        // handle depositing, harvesting, compounding logic inside of _update()
        // if gain is in allocated then gain > 0 otherwise gain == 0
        // we only use so we know initia
        // loss always in allocated
        (uint128 gain, uint128 loss) = _update(id);

        if (_lossLimitViolated(id, loss)) {
            deactivate(true);
            return;
        }

        // interactions
        // there is no interactions happening inside of report
        // so allocator has no state changes to make after it
        if (gain + loss > 0) extender.report(id, gain, loss);
    }

    /**
     * @notice
     *  Prepares the Allocator for token migration.
     * @dev
     *  This function prepares the Allocator for token migration by calling the to-be-implemented
     *  `_prepareMigration`, which should logically withdraw ALL allocated (1) + utility AND reward tokens
     *  from the contract. The ALLOCATED token and THE UTILITY TOKEN is going to be migrated, while the REWARD
     *  tokens can be withdrawn by the Extender to the Treasury.
     */
    function prepareMigration() external override onlyGuardian notMigrating {
        // effects
        _prepareMigration();

        status = AllocatorStatus.MIGRATING;
    }

    /**
     * @notice
     *  Migrates the allocated and all utility tokens to the next Allocator.
     * @dev
     *  The allocated token and the utility tokens will be migrated by this function, while it is
     *  assumed that the reward tokens are either simply kept or already harvested into the underlying
     *  essentially being the edge case of this contract. This contract is also going to report to the
     *  Extender that a migration happened and as such it is important to follow the proper sequence of
     *  migrating.
     *
     *  Steps to migrate:
     *   - FIRST call `_prepareMigration()` to prepare funds for migration.
     *   - THEN deploy the new Allocator and activate it according to the normal procedure.
     *     NOTE: This is to be done RIGHT BEFORE migration as to avoid allocating to the wrong allocator.
     *   - FINALLY call migrate. This is going to migrate the funds to the LAST allocator registered.
     *   - Check if everything went fine.
     *
     *  End state should be that allocator amounts have been swapped for allocators, that gain + loss is netted out 0
     *  for original allocator, and that the new allocators gain has been set to the original allocators gain.
     *  We don't transfer the loss because we have the information how much was initially invested + gain,
     *  and the new allocator didn't cause any loss thus we don't really need to add to it.
     */
    function migrate() external override onlyGuardian isMigrating {
        // reads
        ERC20[] memory utilityTokensArray = utilityTokens();
        address newAllocator = extender.getAllocatorByID(
            extender.getTotalAllocatorCount() - 1
        );
        uint256 idLength = _ids.length;
        uint256 utilLength = utilityTokensArray.length;

        // interactions
        for (uint256 i; i < idLength; i++) {
            ERC20 token = _tokens[i];

            token.safeTransfer(newAllocator, token.balanceOf(address(this)));
            extender.report(_ids[i], type(uint128).max, type(uint128).max);
        }

        for (uint256 i; i < utilLength; i++) {
            ERC20 utilityToken = utilityTokensArray[i];
            utilityToken.safeTransfer(
                newAllocator,
                utilityToken.balanceOf(address(this))
            );
        }

        // turn off Allocator
        deactivate(false);

        emit MigrationExecuted(newAllocator);
    }

    /**
     * @notice
     *  Activates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during activation, say interactions with Extender or something else,
     *  in the virtual method `_activate`.
     */
    function activate() external override onlyGuardian onlyOffline {
        // effects
        _activate();
        status = AllocatorStatus.ACTIVATED;

        emit AllocatorActivated();
    }

    /**
     * @notice
     *  Adds a deposit ID to the Allocator.
     * @dev
     *  Only the Extender calls this.
     * @param id id to add to the allocator
     */
    function addId(uint256 id) external override onlyExtender {
        _ids.push(id);
        tokenIds[id] = _ids.length - 1;
    }

    /**
     * @notice
     *  Returns all deposit IDs registered with the Allocator.
     * @return the deposit IDs registered
     */
    function ids() external view override returns (uint256[] memory) {
        return _ids;
    }

    /**
     * @notice
     *  Returns all tokens registered with the Allocator.
     * @return the tokens
     */
    function tokens() external view override returns (ERC20[] memory) {
        return _tokens;
    }

    /**
     * @notice
     *  Deactivates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during deactivation, say interactions with Extender or something else,
     *  in the virtual method `_deactivate`. Be careful to specifically use the internal or public function
     *  depending on what you need.
     * @param panic should panic logic be executed
     */
    function deactivate(bool panic) public override onlyGuardian {
        // effects
        _deactivate(panic);
        status = AllocatorStatus.OFFLINE;

        emit AllocatorDeactivated(panic);
    }

    /**
     * @notice
     *  Getter for Allocator version.
     * @return Returns the Allocators version.
     */
    function version() public pure override returns (string memory) {
        return "v2.0.0";
    }

    /**
     * @notice
     *  Internal check if the loss limit has been violated by the Allocator.
     * @dev
     *  Called as part of `update`. The rule is that the already sustained loss + newly sustained
     *  has to be larger or equal to the limit to break the contract.
     * @param id deposit id as in `TreasuryExtender`
     * @param loss the amount of newly sustained loss
     * @return true if the the loss limit has been broken
     */
    function _lossLimitViolated(uint256 id, uint128 loss)
        internal
        returns (bool)
    {
        // read
        uint128 lastLoss = extender.getAllocatorPerformance(id).loss;

        // events
        if ((loss + lastLoss) >= extender.getAllocatorLimits(id).loss) {
            emit LossLimitViolated(
                lastLoss,
                loss,
                amountAllocated(tokenIds[id])
            );
            return true;
        }

        return false;
    }

    /**
     * @notice
     *  Internal check to see if sender is extender.
     */
    function _onlyExtender(address sender) internal view {
        if (sender != address(extender))
            revert BaseAllocator_OnlyExtender(sender);
    }

    /**
     * @notice
     *  Internal check to see if allocator is activated.
     */
    function _onlyActivated(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.ACTIVATED)
            revert BaseAllocator_AllocatorNotActivated();
    }

    /**
     * @notice
     *  Internal check to see if allocator is offline.
     */
    function _onlyOffline(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.OFFLINE)
            revert BaseAllocator_AllocatorNotOffline();
    }

    /**
     * @notice
     *  Internal check to see if allocator is not migrating.
     */
    function _notMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus == AllocatorStatus.MIGRATING)
            revert BaseAllocator_Migrating();
    }

    /**
     * @notice
     *  Internal check to see if allocator is migrating.
     */
    function _isMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.MIGRATING)
            revert BaseAllocator_NotMigrating();
    }
}

pragma solidity ^0.8.10;

struct UserVotePayload {
    address account;
    bytes32 voteSessionKey;
    uint256 nonce;
    uint256 chainId;
    uint256 totalVotes;
    UserVoteAllocationItem[] allocations;
}

struct UserVoteAllocationItem {
    bytes32 reactorKey; //asset-default, in actual deployment could be asset-exchange
    uint256 amount; //18 Decimals
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit ERC-20 tokens to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);
    event DepositsPaused();
    event DepositsUnpaused();

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount) external;

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account)
        external
        view
        returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    // @notice Pause deposits only on the pool.
    function pauseDeposit() external;

    // @notice Unpause deposits only on the pool.
    function unpauseDeposit() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 *  @title Tracks the IPFS hashes that are generated for rewards
 */
interface IRewardHash {
    struct CycleHashTuple {
        string latestClaimable; // hash of last claimable cycle before/including this cycle
        string cycle; // cycleHash of this cycle
    }

    event CycleHashAdded(
        uint256 cycleIndex,
        string latestClaimableHash,
        string cycleHash
    );

    /// @notice Sets a new (claimable, cycle) hash tuple for the specified cycle
    /// @param index Cycle index to set. If index >= LatestCycleIndex, CycleHashAdded is emitted
    /// @param latestClaimableIpfsHash IPFS hash of last claimable cycle before/including this cycle
    /// @param cycleIpfsHash IPFS hash of this cycle
    function setCycleHashes(
        uint256 index,
        string calldata latestClaimableIpfsHash,
        string calldata cycleIpfsHash
    ) external;

    ///@notice Gets hashes for the specified cycle
    ///@return latestClaimable lastest claimable hash for specified cycle, cycle latest hash (possibly non-claimable) for specified cycle
    function cycleHashes(uint256 index)
        external
        view
        returns (string memory latestClaimable, string memory cycle);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
    struct StakingSchedule {
        uint256 cliff; // Duration in seconds before staking starts
        uint256 duration; // Seconds it takes for entire amount to stake
        uint256 interval; // Seconds it takes for a chunk to stake
        bool setup; //Just so we know its there
        bool isActive; //Whether we can setup new stakes with the schedule
        uint256 hardStart; //Stakings will always start at this timestamp if set
        bool isPublic; //Schedule can be written to by any account
    }

    struct StakingScheduleInfo {
        StakingSchedule schedule;
        uint256 index;
    }

    struct StakingDetails {
        uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
        uint256 withdrawn; //Amount that was staked and subsequently withdrawn
        uint256 slashed; //Amount that has been slashed
        uint256 started; //Timestamp at which the stake started
        uint256 scheduleIx;
    }

    struct WithdrawalInfo {
        uint256 minCycleIndex;
        uint256 amount;
    }

    struct QueuedTransfer {
        address from;
        uint256 scheduleIdxFrom;
        uint256 scheduleIdxTo;
        uint256 amount;
        address to;
    }

    event ScheduleAdded(
        uint256 scheduleIndex,
        uint256 cliff,
        uint256 duration,
        uint256 interval,
        bool setup,
        bool isActive,
        uint256 hardStart,
        address notional
    );
    event ScheduleRemoved(uint256 scheduleIndex);
    event WithdrawalRequested(
        address account,
        uint256 scheduleIdx,
        uint256 amount
    );
    event WithdrawCompleted(
        address account,
        uint256 scheduleIdx,
        uint256 amount
    );
    event Deposited(address account, uint256 amount, uint256 scheduleIx);
    event Slashed(address account, uint256 amount, uint256 scheduleIx);
    event PermissionedDepositorSet(address depositor, bool allowed);
    event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
    event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
    event ScheduleStatusSet(uint256 scheduleId, bool isActive);
    event StakeTransferred(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
    event TransferApproverSet(address approverAddress);
    event TransferQueued(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRemoved(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRejected(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );

    ///@notice Allows for checking of user address in permissionedDepositors mapping
    ///@param account Address of account being checked
    ///@return Boolean, true if address exists in mapping
    function permissionedDepositors(address account) external returns (bool);

    ///@notice Allows owner to set a multitude of schedules that an address has access to
    ///@param account User address
    ///@param userSchedulesIdxs Array of schedule indexes
    function setUserSchedules(
        address account,
        uint256[] calldata userSchedulesIdxs
    ) external;

    ///@notice Allows owner to add schedule
    ///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
    ///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
    function addSchedule(StakingSchedule memory schedule, address notional)
        external;

    ///@notice Gets all info on all schedules
    ///@return retSchedules An array of StakingScheduleInfo struct
    function getSchedules()
        external
        view
        returns (StakingScheduleInfo[] memory retSchedules);

    ///@notice Allows owner to set a permissioned depositor
    ///@param account User address
    ///@param canDeposit Boolean representing whether user can deposit
    function setPermissionedDepositor(address account, bool canDeposit)
        external;

    function withdrawalRequestsByIndex(address account, uint256 index)
        external
        view
        returns (uint256 minCycle, uint256 amount);

    ///@notice Allows a user to get the stakes of an account
    ///@param account Address that is being checked for stakes
    ///@return stakes StakingDetails array containing info about account's stakes
    function getStakes(address account)
        external
        view
        returns (StakingDetails[] memory stakes);

    ///@notice Gets total value staked for an address across all schedules
    ///@param account Address for which total stake is being calculated
    ///@return value uint256 total of account
    function balanceOf(address account) external view returns (uint256 value);

    ///@notice Returns amount available to withdraw for an account and schedule Index
    ///@param account Address that is being checked for withdrawals
    ///@param scheduleIndex Index of schedule that is being checked for withdrawals
    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256);

    ///@notice Returns unvested amount for certain address and schedule index
    ///@param account Address being checked for unvested amount
    ///@param scheduleIndex Schedule index being checked for unvested amount
    ///@return value Uint256 representing unvested amount
    function unvested(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256 value);

    ///@notice Returns vested amount for address and schedule index
    ///@param account Address being checked for vested amount
    ///@param scheduleIndex Schedule index being checked for vested amount
    ///@return value Uint256 vested
    function vested(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256 value);

    ///@notice Allows user to deposit token to specific vesting / staking schedule
    ///@param amount Uint256 amount to be deposited
    ///@param scheduleIndex Uint256 representing schedule to user
    function deposit(uint256 amount, uint256 scheduleIndex) external;

    /// @notice Allows users to deposit into 0 schedule
    /// @param amount Deposit amount
    function deposit(uint256 amount) external;

    ///@notice Allows account to deposit on behalf of other account
    ///@param account Account to be deposited for
    ///@param amount Amount to be deposited
    ///@param scheduleIndex Index of schedule to be used for deposit
    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external;

    ///@notice Allows permissioned depositors to deposit into custom schedule
    ///@param account Address of account being deposited for
    ///@param amount Uint256 amount being deposited
    ///@param schedule StakingSchedule struct containing details needed for new schedule
    ///@param notional Notional address attached to schedule, allows for different voting weights on L2
    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external;

    ///@notice User can request withdrawal from staking contract at end of cycle
    ///@notice Performs checks to make sure amount <= amount available
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule index for withdrawal Request
    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

    ///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule to withdraw from
    function withdraw(uint256 amount, uint256 scheduleIdx) external;

    /// @notice Allows owner to set schedule to active or not
    /// @param scheduleIndex Schedule index to set isActive boolean
    /// @param activeBoolean Bool to set schedule active or not
    function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean)
        external;

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    /// @notice Used to slash user funds when needed
    /// @notice accounts and amounts arrays must be same length
    /// @notice Only one scheduleIndex can be slashed at a time
    /// @dev Implementation must be restructed to owner account
    /// @param accounts Array of accounts to slash
    /// @param amounts Array of amounts that corresponds with accounts
    /// @param scheduleIndex scheduleIndex of users that are being slashed
    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external;

    /// @notice Set the address used to denote the token amount for a particular schedule
    /// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
    function setNotionalAddresses(
        uint256[] calldata scheduleIdxArr,
        address[] calldata addresses
    ) external;

    /// @notice Withdraw from the default schedule. Must have a request in previously
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
        ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(
        bytes32 controller,
        address adapaterAddress,
        bytes data
    );
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 timestamp);
    event CycleRolloverComplete(uint256 timestamp);
    event NextCycleStartSet(uint256 nextCycleStartTime);
    event ManagerSwept(address[] addresses, uint256[] amounts);

    /// @notice Registers controller
    /// @param id Bytes32 id of controller
    /// @param controller Address of controller
    function registerController(bytes32 id, address controller) external;

    /// @notice Registers pool
    /// @param pool Address of pool
    function registerPool(address pool) external;

    /// @notice Unregisters controller
    /// @param id Bytes32 controller id
    function unRegisterController(bytes32 id) external;

    /// @notice Unregisters pool
    /// @param pool Address of pool
    function unRegisterPool(address pool) external;

    ///@notice Gets addresses of all pools registered
    ///@return Memory array of pool addresses
    function getPools() external view returns (address[] memory);

    ///@notice Gets ids of all controllers registered
    ///@return Memory array of Bytes32 controller ids
    function getControllers() external view returns (bytes32[] memory);

    ///@notice Allows for owner to set cycle duration
    ///@param duration Block durtation of cycle
    function setCycleDuration(uint256 duration) external;

    ///@notice Starts cycle rollover
    ///@dev Sets rolloverStarted state boolean to true
    function startCycleRollover() external;

    ///@notice Allows for controller commands to be executed midcycle
    ///@param params Contains data for controllers and params
    function executeMaintenance(MaintenanceExecution calldata params) external;

    ///@notice Allows for withdrawals and deposits for pools along with liq deployment
    ///@param params Contains various data for executing against pools and controllers
    function executeRollover(RolloverExecution calldata params) external;

    ///@notice Completes cycle rollover, publishes rewards hash to ipfs
    ///@param rewardsIpfsHash rewards hash uploaded to ipfs
    function completeRollover(string calldata rewardsIpfsHash) external;

    ///@notice Gets reward hash by cycle index
    ///@param index Cycle index to retrieve rewards hash
    ///@return String memory hash
    function cycleRewardsHashes(uint256 index)
        external
        view
        returns (string memory);

    ///@notice Gets current starting block
    ///@return uint256 with block number
    function getCurrentCycle() external view returns (uint256);

    ///@notice Gets current cycle index
    ///@return uint256 current cycle number
    function getCurrentCycleIndex() external view returns (uint256);

    ///@notice Gets current cycle duration
    ///@return uint256 in block of cycle duration
    function getCycleDuration() external view returns (uint256);

    ///@notice Gets cycle rollover status, true for rolling false for not
    ///@return Bool representing whether cycle is rolling over or not
    function getRolloverStatus() external view returns (bool);

    /// @notice Sets next cycle start time manually
    /// @param nextCycleStartTime uint256 that represents start of next cycle
    function setNextCycleStartTime(uint256 nextCycleStartTime) external;

    /// @notice Sweeps amanager contract for any leftover funds
    /// @param addresses array of addresses of pools to sweep funds into
    function sweep(address[] calldata addresses) external;

    /// @notice Setup a role using internal function _setupRole
    /// @param role keccak256 of the role keccak256("MY_ROLE");
    function setupRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 *  @title Validates and distributes TOKE rewards based on the
 *  the signed and submitted payloads
 */
interface IRewards {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 chainId;
        uint256 cycle;
        address wallet;
        uint256 amount;
    }

    event SignerSet(address newSigner);
    event Claimed(uint256 cycle, address recipient, uint256 amount);

    /// @notice Get the current payload signer;
    /// @return Signer address
    function rewardsSigner() external view returns (address);

    /// @notice Check the amount an account has already claimed
    /// @param account Account to check
    /// @return Amount already claimed
    function claimedAmounts(address account) external view returns (uint256);

    /// @notice Get the amount that is claimable based on the provided payload
    /// @param recipient Published rewards payload
    /// @return Amount claimable if the payload is signed
    function getClaimableAmount(Recipient calldata recipient)
        external
        view
        returns (uint256);

    /// @notice Change the signer used to validate payloads
    /// @param newSigner The new address that will be signing rewards payloads
    function setSigner(address newSigner) external;

    /// @notice Claim your rewards
    /// @param recipient Published rewards payload
    /// @param v v component of the payload signature
    /// @param r r component of the payload signature
    /// @param s s component of the payload signature
    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity >=0.8.0;

// interfaces
import "solmate/tokens/ERC20.sol";

// interfaces
import "olympus/interfaces/ITreasuryExtender.sol";
import "olympus/interfaces/IOlympusAuthority.sol";

enum AllocatorStatus {
    OFFLINE,
    ACTIVATED,
    MIGRATING
}

struct AllocatorInitData {
    IOlympusAuthority authority;
    ITreasuryExtender extender;
    ERC20[] tokens;
}

/**
 * @title Interface for the BaseAllocator
 * @dev
 *  These are the standard functions that an Allocator should implement. A subset of these functions
 *  is implemented in the `BaseAllocator`. Similar to those implemented, if for some reason the developer
 *  decides to implement a dedicated base contract, or not at all and rather a dedicated Allocator contract
 *  without base, imitate the functionalities implemented in it.
 */
interface IAllocator {
    /**
     * @notice
     *  Emitted when the Allocator is deployed.
     */
    event AllocatorDeployed(address authority, address extender);

    /**
     * @notice
     *  Emitted when the Allocator is activated.
     */
    event AllocatorActivated();

    /**
     * @notice
     *  Emitted when the Allocator is deactivated.
     */
    event AllocatorDeactivated(bool panic);

    /**
     * @notice
     *  Emitted when the Allocators loss limit is violated.
     */
    event LossLimitViolated(
        uint128 lastLoss,
        uint128 dloss,
        uint256 estimatedTotalAllocated
    );

    /**
     * @notice
     *  Emitted when a Migration is executed.
     * @dev
     *  After this also `AllocatorDeactivated` should follow.
     */
    event MigrationExecuted(address allocator);

    /**
     * @notice
     *  Emitted when Ether is received by the contract.
     * @dev
     *  Only the Guardian is able to send the ether.
     */
    event EtherReceived(uint256 amount);

    function update(uint256 id) external;

    function deallocate(uint256[] memory amounts) external;

    function prepareMigration() external;

    function migrate() external;

    function activate() external;

    function deactivate(bool panic) external;

    function addId(uint256 id) external;

    function name() external view returns (string memory);

    function ids() external view returns (uint256[] memory);

    function tokenIds(uint256 id) external view returns (uint256);

    function version() external view returns (string memory);

    function status() external view returns (AllocatorStatus);

    function tokens() external view returns (ERC20[] memory);

    function utilityTokens() external view returns (ERC20[] memory);

    function rewardTokens() external view returns (ERC20[] memory);

    function amountAllocated(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

pragma solidity ^0.8.10;

import "../interfaces/IOlympusAuthority.sol";

error UNAUTHORIZED();
error AUTHORITY_INITIALIZED();

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract OlympusAccessControlledV2 {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
	_onlyGovernor();
	_;
    }

    modifier onlyGuardian {
	_onlyGuardian();
	_;
    }

    modifier onlyPolicy {
	_onlyPolicy();
	_;
    }

    modifier onlyVault {
	_onlyVault();
	_;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IOlympusAuthority _newAuthority) internal {
        if (authority != IOlympusAuthority(address(0))) revert AUTHORITY_INITIALIZED();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IOlympusAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        if (msg.sender != authority.governor()) revert UNAUTHORIZED();
    }

    function _onlyGuardian() internal view {
        if (msg.sender != authority.guardian()) revert UNAUTHORIZED();
    }

    function _onlyPolicy() internal view {
        if (msg.sender != authority.policy()) revert UNAUTHORIZED();
    }

    function _onlyVault() internal view {
        if (msg.sender != authority.vault()) revert UNAUTHORIZED();
    }
}

pragma solidity ^0.8.10;

struct AllocatorPerformance {
    uint128 gain;
    uint128 loss;
}

struct AllocatorLimits {
    uint128 allocated;
    uint128 loss;
}

struct AllocatorHoldings {
    uint256 allocated;
}

struct AllocatorData {
    AllocatorHoldings holdings;
    AllocatorLimits limits;
    AllocatorPerformance performance;
}

/**
 * @title Interface for the TreasuryExtender
 */
interface ITreasuryExtender {
    /**
     * @notice
     *  Emitted when a new Deposit is registered.
     */
    event NewDepositRegistered(address allocator, address token, uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator is funded
     */
    event AllocatorFunded(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when allocated funds are withdrawn from an Allocator
     */
    event AllocatorWithdrawal(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when rewards are withdrawn from an Allocator
     */
    event AllocatorRewardsWithdrawal(address allocator, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when an Allocator reports a gain
     */
    event AllocatorReportedGain(uint256 id, uint128 gain);

    /**
     * @notice
     *  Emitted when an Allocator reports a loss
     */
    event AllocatorReportedLoss(uint256 id, uint128 loss);

    /**
     * @notice
     *  Emitted when an Allocator reports a migration
     */
    event AllocatorReportedMigration(uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator limits are modified
     */
    event AllocatorLimitsChanged(uint256 id, uint128 allocationLimit, uint128 lossLimit);

    function registerDeposit(address newAllocator) external;

    function setAllocatorLimits(uint256 id, AllocatorLimits memory limits) external;

    function report(
        uint256 id,
        uint128 gain,
        uint128 loss
    ) external;

    function requestFundsFromTreasury(uint256 id, uint256 amount) external;

    function returnFundsToTreasury(uint256 id, uint256 amount) external;

    function returnRewardsToTreasury(
        uint256 id,
        address token,
        uint256 amount
    ) external;

    function getTotalAllocatorCount() external view returns (uint256);

    function getAllocatorByID(uint256 id) external view returns (address);

    function getAllocatorAllocated(uint256 id) external view returns (uint256);

    function getAllocatorLimits(uint256 id) external view returns (AllocatorLimits memory);

    function getAllocatorPerformance(uint256 id) external view returns (AllocatorPerformance memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}
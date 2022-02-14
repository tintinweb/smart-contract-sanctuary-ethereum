// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./codes/ERC20Upgradeable.sol";
import "./codes/OwnableUpgradeable.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeCast.sol";
import "../interfaces/BoringMath.sol";
import "./codes/Initializable.sol";

interface IFeeDistributor {
    function deposit(address user, uint256 amount) external;

    function withdraw(address user, uint256 amount) external;
}

interface INRDistributor {
    function deposit(address user, uint256 amount) external;

    function withdraw(address user, uint256 amount) external;
}

/**
 * @title CLS token.
 * No delegation thru signing.
 *
 * A wallet that holds CLS, but is undelegated cannot vote.
 * Even if you’re planning to vote yourself, you still need to manually delegate or “self-delegate”
 * to make those votes count.
 *
 * If Alice has 10 COMP and delegates her votes to Bob,
 * Bob now has 10 votes but cannot delegate those votes to Charles.
 * You can only delegate votes if you hold the corresponding CLS for those votes.
 *
 * If Alice is delegating to Bob and has 10 COMP in her wallet, Bob has 10 votes.
 * If Charles sends Alice 10 more COMP, Alice now has 20 COMP
 * and her delegation to Bob is automatically updated to 20 votes.
 * No re-delegation needed if balances change.
 *
 * References:
 *
 * - https://www.comp.xyz/t/governance-guide-how-to-delegate/365
 */
contract gNR is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using BoringMath32 for uint32;
    using SafeCast for uint256;
    using SafeCast for uint32;

    /// @dev NR timelock.
    /// `nrAmount` Amount of deposited NRs.
    /// `endDay` When tokens are unlocked.
    struct TokenLock {
        uint256 nrAmount;
        uint256 startTime;
        uint256 endDay;
    }

    /// @dev NR timelock list.
    /// `lockedList` list of NR timelock.
    /// `startIdx` start index of lockedList.
    /// `unlockableAmount` amount of NR unlockable.
    struct TokenLockList {
        TokenLock[] lockedList;
        uint256 startIdx;
        uint256 unlockableAmount;
    }

    /// @dev TokenLockList for locked tokens.
    mapping(address => mapping(uint8 => TokenLockList)) public locked;
    /// @dev TokenLockList for claimed tokens.
    mapping(address => TokenLockList) public claimLocked;
    /// @dev Multiple to lockup period.
    mapping(uint8 => uint256) public multipleToLockup;
    /// @dev TokenLockList for migration reward.
    mapping(address => TokenLock) public migrationLocked;

    IFeeDistributor public feeDistributor;
    INRDistributor public nrDistributor;
    IERC20 public nr;
    address public masterchef;
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant dayBlockTimestamp = 86400;
    uint256 private constant CLAIM_PERIOD = 7 * dayBlockTimestamp;

    //// EVENT
    event Mint(address indexed user, address indexed to, uint256 clsAmount, uint8 indexed multiple);
    event MintClaimBoost(address indexed to, uint256 clsAmount);
    event MintMigration(address indexed to, uint256 clsAmount);
    event Burn(address indexed user, address indexed to, uint256 clsAmount, uint8 indexed multiple);
    event BurnMigration(address indexed user, address indexed to, uint256 clsAmount);
    event InstantUnlockWithPenalty(address indexed user, address indexed to, uint256 clsAmount, uint8 indexed multiple);
    event Claim(address indexed user, address indexed to, uint256 nrAmount);

    function initialize(IERC20 nr_) public initializer {
        __ERC20_init("gNR", "gNR");
        __Ownable_init();
        nr = nr_;
        multipleToLockup[0] = 2 * 30 * dayBlockTimestamp;
        multipleToLockup[1] = 4 * 30 * dayBlockTimestamp;
        multipleToLockup[2] = 8 * 30 * dayBlockTimestamp;
        multipleToLockup[3] = 12 * 30 * dayBlockTimestamp;
        multipleToLockup[4] = 24 * 30 * dayBlockTimestamp;
    }
    
    function setFeeDistributor(IFeeDistributor feeDistributor_)
        public
        onlyOwner
    {
        feeDistributor = feeDistributor_;
    }

    function setNRDistributor(INRDistributor nrDistributor_)
        public
        onlyOwner
    {
        nrDistributor = nrDistributor_;
    }

    function setMasterchef(address masterchef_) public onlyOwner {
        masterchef = masterchef_;
    }

    // // Disable some ERC20 features
    /// @notice Cls token transfer is disabled.
    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal { 
        super._beforeTokenTransfer(from, to, amount);
        require(from == address(0) || to == address(0), "ClsToken: transfer disabled");
    }

    /// @notice Cls token transfer is disabled.
    function approve(address spender, uint256 amount) override public returns (bool) {
        revert("ClsToken: transfer disabled");
    }

    /// @notice Cls token transfer is disabled.
    function increaseAllowance(address spender, uint256 addedValue)
        override
        public
        returns (bool)
    {
        revert("ClsToken: transfer disabled");
    }

    /// @notice Cls token transfer is disabled.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        override
        public
        returns (bool)
    {
        revert("ClsToken: transfer disabled");
    }

    function _mint(address account, uint256 amount) override internal {
        super._mint(account, amount);
        // feeDistributor.deposit(account, amount);
        // nrDistributor.deposit(account, amount);
        _moveDelegates(address(0), _delegates[account], amount);
    }

    function _burn(address account, uint256 amount) override internal {
        super._burn(account, amount);
        // feeDistributor.withdraw(account, amount);
        // nrDistributor.withdraw(account, amount);
        _moveDelegates(_delegates[account], address(0), amount);
    }

    /// @dev Return unlockable amount of nr and locked list of nr
    function lockedNRInfo(address account, uint8 multiple)
        public
        view
        returns (
            uint256 unlockableAmount,
            uint256 lockedAmount,
            uint256[] memory lockedAmounts,
            uint256[] memory endDays
        )
    {
        unlockableAmount = locked[account][multiple].unlockableAmount;
        uint256 startIdx = locked[account][multiple].startIdx;
        uint256 endIdx = locked[account][multiple].lockedList.length;
        TokenLock[] memory lockedList = locked[account][multiple].lockedList;
        uint256 i = startIdx;
        uint256 currentDay = _getDay();
        for (; i < endIdx; ++i) {
            if (currentDay > lockedList[i].endDay) {
                unlockableAmount = unlockableAmount.add(
                    lockedList[i].nrAmount
                );
            } else {
                break;
            }
        }
        lockedAmount = unlockableAmount;
        uint256 lockedIdx = i;
        lockedAmounts = new uint256[](endIdx - lockedIdx);
        endDays = new uint256[](endIdx - lockedIdx);
        for (; i < endIdx; ++i) {
            lockedAmounts[i - lockedIdx] = lockedList[i].nrAmount;
            endDays[i - lockedIdx] = lockedList[i].endDay;
            lockedAmount = lockedAmount.add(
                lockedList[i].nrAmount
            );
        }
    }

    /// @dev Return raw locked NR info
    function rawLockedNRInfo(address account, uint8 multiple)
        public
        view
        returns (
            TokenLockList memory tokenLockList
        )
    {
        tokenLockList = locked[account][multiple];
    }

    /// @dev Return claimable amount of NR and locked list of NR
    function claimLockedInfo(address account)
        public
        view
        returns (
            uint256 unlockableAmount,
            uint256 lockedAmount,
            uint256[] memory lockedAmounts,
            uint256[] memory endDays
        )
    {
        unlockableAmount = claimLocked[account].unlockableAmount;
        uint256 startIdx = claimLocked[account].startIdx;
        uint256 endIdx = claimLocked[account].lockedList.length;
        TokenLock[] memory lockedList = claimLocked[account].lockedList;
        uint256 i = startIdx;
        uint256 currentDay = _getDay();
        for (; i < endIdx; ++i) {
            if (currentDay > lockedList[i].endDay) {
                unlockableAmount = unlockableAmount.add(
                    lockedList[i].nrAmount
                );
            } else {
                break;
            }
        }
        lockedAmount = unlockableAmount;
        uint256 lockedIdx = i;
        lockedAmounts = new uint256[](endIdx - lockedIdx);
        endDays = new uint256[](endIdx - lockedIdx);
        for (; i < endIdx; ++i) {
            lockedAmounts[i - lockedIdx] = lockedList[i].nrAmount;
            endDays[i - lockedIdx] = lockedList[i].endDay;
            lockedAmount = lockedAmount.add(
                lockedList[i].nrAmount
            );
        }
    }

    /// @dev Return raw claimed NR info
    function rawClaimLockedNRInfo(address account)
        public
        view
        returns (
            TokenLockList memory tokenLockList
        )
    {
        tokenLockList = claimLocked[account];
    }

    /// @notice Update TokenLockedList.
    /// Update unlockable amount and start idx.
    function _updateTokenLockedList(TokenLockList storage tokenLockList)
        internal
    {
        uint256 startIdx = tokenLockList.startIdx;
        uint256 endIdx = tokenLockList.lockedList.length;
        TokenLock[] storage lockedList = tokenLockList.lockedList;
        uint256 i = startIdx;
        uint256 newUnlockableAmount = 0;
        uint256 currentDay = _getDay();
        for (; i < endIdx; i++) {
            if (currentDay > lockedList[i].endDay) {
                newUnlockableAmount = newUnlockableAmount.add(
                    lockedList[i].nrAmount
                );
                lockedList[i].nrAmount = 0;
            } else {
                break;
            }
        }
        tokenLockList.unlockableAmount = tokenLockList.unlockableAmount.add(
            newUnlockableAmount
        );
        tokenLockList.startIdx = i;
    }

    /// @dev Lock NRs and mint gNRs.
    /// @param to gNR Receiver.
    /// @param amount Amount of NR to lock.
    /// @param multiple Multiple of NR to lock.
    function mint(
        address to,
        uint256 amount,
        uint8 multiple
    ) public {
        uint256 lockupPeriod = multipleToLockup[multiple];
        require(lockupPeriod != 0, "Invalid multiple");
        require(amount > 0, "Mint amount is zero");
        uint256 endDay = _getDay().add(lockupPeriod);
        nr.safeTransferFrom(msg.sender, address(this), amount);

        TokenLockList storage tokenLockList = locked[to][multiple];
        uint256 endIdx = tokenLockList.lockedList.length;
        if (
            endIdx != 0
            && tokenLockList.lockedList[endIdx - 1].endDay == endDay
            && tokenLockList.startIdx < endIdx
        ) {
            tokenLockList.lockedList[endIdx - 1].nrAmount = tokenLockList
                .lockedList[endIdx - 1]
                .nrAmount
                .add(amount);
        } else {
            tokenLockList.lockedList.push(
                TokenLock({nrAmount: amount, startTime: _getDay(), endDay: endDay})
            );
        }
        uint256 multipleAmount;
        if(multiple == 0) {
            multipleAmount = amount;
        } else if(multiple == 1) {
            multipleAmount = amount.mul(2);
        } else if(multiple == 2) {
            multipleAmount = amount.mul(4);
        } else if(multiple == 3) {
            multipleAmount = amount.mul(16);
        } else if(multiple == 4) {
            multipleAmount = amount.mul(128);
        }

        _mint(to, multipleAmount);
       emit Mint(msg.sender, to, amount, multiple);
    }
    // alias of mint()
    function lock(
        address to,
        uint256 amount,
        uint8 multiple
    ) public {
        mint(to, amount, multiple);
    }

    /// @dev Unlock NRs and burn gNRs.
    /// @param to NR receiver.
    /// @param multiple Multiple of NR.
    /// @param amount Amount Of NR to unlock.
    function burn(
        address to,
        uint8 multiple,
        uint256 amount
    ) public {
        uint256 lockupPeriod = multipleToLockup[multiple];
        require(lockupPeriod != 0, "Invalid multiple");
        require(amount > 0, "Burn amount is zero");
        uint256 currentDay = _getDay();

        TokenLockList storage tokenLockList = locked[msg.sender][multiple];
        _updateTokenLockedList(tokenLockList);
        tokenLockList.unlockableAmount = tokenLockList.unlockableAmount.sub(
            amount
        );

        _addClaimLocked(to, amount, currentDay.add(CLAIM_PERIOD));
        uint256 multipleAmount;
        if(multiple == 0) {
            multipleAmount = amount;
        } else if(multiple == 1) {
            multipleAmount = amount.mul(2);
        } else if(multiple == 2) {
            multipleAmount = amount.mul(4);
        } else if(multiple == 3) {
            multipleAmount = amount.mul(16);
        } else if(multiple == 4) {
            multipleAmount = amount.mul(128);
        }
        emit Burn(msg.sender, to, multipleAmount, multiple);
        _burn(msg.sender, multipleAmount);
    }

    // alias of burn()
    function unlock(
        address to,
        uint8 multiple,
        uint256 amount
    ) public {
        burn(to, multiple, amount);
    }

    /// @dev Unlock NRs and burn CLSs.
    /// @param to NR receiver.
    /// @param multiple Multiple of NR.
    /// unlock all unlockable NRs of selected multiple.
    function unlockAll(address to, uint8 multiple) public {
        uint256 lockupPeriod = multipleToLockup[multiple];
        require(lockupPeriod != 0, "Invalid multiple");
        uint256 currentDay = _getDay();

        TokenLockList storage tokenLockList = locked[msg.sender][multiple];
        _updateTokenLockedList(tokenLockList);
        uint256 amount = tokenLockList.unlockableAmount;
        require(amount > 0, "Unlockable amount is zero");
        tokenLockList.unlockableAmount = 0;

        _addClaimLocked(to, amount, currentDay.add(CLAIM_PERIOD));

        uint256 multipleAmount;
        if(multiple == 0) {
            multipleAmount = amount;
        } else if(multiple == 1) {
            multipleAmount = amount.mul(2);
        } else if(multiple == 2) {
            multipleAmount = amount.mul(4);
        } else if(multiple == 3) {
            multipleAmount = amount.mul(16);
        } else if(multiple == 4) {
            multipleAmount = amount.mul(128);
        }
        emit Burn(msg.sender, to, multipleAmount, multiple);
        _burn(msg.sender, multipleAmount);
    }

    /// @notice Unlock for all unlockable NRs. Be careful of gas spending!
    function massUnlockAll(address to) public {
        uint256 totalNRAmount = 0;
        uint256 totalgNRAmount = 0;
        uint256 currentDay = _getDay();
        for (uint8 i = 0; i <= 4; i++ ) {
            TokenLockList storage tokenLockList = locked[msg.sender][i];
            _updateTokenLockedList(tokenLockList);
            uint256 amount = tokenLockList.unlockableAmount;
            if (amount > 0) {
                tokenLockList.unlockableAmount = 0;
                totalNRAmount = totalNRAmount.add(amount);
                uint256 multipleAmount;
                if(i == 0) {
                    multipleAmount = amount;
                } else if(i == 1) {
                    multipleAmount = amount.mul(2);
                } else if(i == 2) {
                    multipleAmount = amount.mul(4);
                } else if(i == 3) {
                    multipleAmount = amount.mul(16);
                } else if(i == 4) {
                    multipleAmount = amount.mul(128);
                }
                totalgNRAmount = totalgNRAmount.add(multipleAmount);
                emit Burn(msg.sender, to, multipleAmount, i);
            }
        }
        require(totalNRAmount > 0 && totalgNRAmount > 0, "Unlockable amount is zero");
        _addClaimLocked(to, totalNRAmount, currentDay.add(CLAIM_PERIOD));
        _burn(msg.sender, totalgNRAmount);
    }

    /// @notice Instant unlock with penalty function. 
    /// Only locked NR can be unlocked instantly.
    /// @param to NR reciever.
    /// @param multiple Multiple of NR.
    /// @param amount Amount of NR to unlock.
    function instantUnlockWithPenalty(
        address to,
        uint8 multiple,
        uint256 amount
    ) public {
        uint256 lockupPeriod = multipleToLockup[multiple];
        require(lockupPeriod != 0, "Invalid multiple");
        _updateTokenLockedList(locked[msg.sender][multiple]);
        uint256 startIdx = locked[msg.sender][multiple].startIdx;
        uint256 endIdx = locked[msg.sender][multiple].lockedList.length;
        TokenLock[] storage lockedList = locked[msg.sender][multiple]
            .lockedList;

        uint256 unlockedAmount = 0;
        uint256 i = startIdx;
        uint256 transferAmount = 0;
        uint256 burnedAmount = 0;
        for (; i < endIdx; ++i) {
            uint256 nrAmount = lockedList[i].nrAmount;
            uint256 afterLockupDay = 0;
            if (unlockedAmount.add(nrAmount) <= amount) {
                lockedList[i].nrAmount = 0;
                afterLockupDay = _getDay() - lockedList[i].startTime;
                unlockedAmount = unlockedAmount.add(nrAmount);
                transferAmount = transferAmount.add(nrAmount.mul(afterLockupDay / lockedList[i].endDay));
                burnedAmount = burnedAmount.add(nrAmount.sub(transferAmount));
            } else {
                lockedList[i].nrAmount = nrAmount.add(unlockedAmount).sub(
                    amount
                );
                afterLockupDay = _getDay() - lockedList[i].startTime;
                transferAmount = transferAmount.add(lockedList[i].nrAmount.mul(afterLockupDay / lockedList[i].endDay));
                burnedAmount = burnedAmount.add(lockedList[i].nrAmount.sub(transferAmount));
                unlockedAmount = amount;
                break;
            }
        }
        assert(amount == unlockedAmount);
        locked[msg.sender][multiple].startIdx = i;
        
        uint256 multipleAmount;
                if(multiple == 0) {
                    multipleAmount = unlockedAmount;
                } else if(multiple == 1) {
                    multipleAmount = unlockedAmount.mul(2);
                } else if(multiple == 2) {
                    multipleAmount = unlockedAmount.mul(4);
                } else if(multiple == 3) {
                    multipleAmount = unlockedAmount.mul(16);
                } else if(multiple == 4) {
                    multipleAmount = unlockedAmount.mul(128);
                }
        _burn(msg.sender, multipleAmount);
        nr.safeTransfer(BURN_ADDRESS, burnedAmount);
        nr.safeTransfer(to, transferAmount);
        emit InstantUnlockWithPenalty(msg.sender, to, multipleAmount, multiple);
    }

    /// @dev Claim all claimable NRs.
    /// @param to NR receiver.
    function claim(address to) public {
        TokenLockList storage tokenLockList = claimLocked[msg.sender];
        _updateTokenLockedList(tokenLockList);
        uint256 amount = tokenLockList.unlockableAmount;
        require(amount > 0, "nothing to claim");
        tokenLockList.unlockableAmount = 0;
        nr.safeTransfer(to, amount);
        emit Claim(msg.sender, to, amount);
    }

    /// @dev Push NR into claimLocked
    /// @param to NR receiver.
    /// @param amount Amount of NRs.
    /// @param endDay End day of locked period.
    function _addClaimLocked(
        address to,
        uint256 amount,
        uint256 endDay
    ) internal {
        uint256 endIdx = claimLocked[to].lockedList.length;
        if (
            endIdx != 0 &&
            claimLocked[to].lockedList[endIdx - 1].endDay == endDay
        ) {
            claimLocked[to].lockedList[endIdx - 1].nrAmount = claimLocked[to]
                .lockedList[endIdx - 1]
                .nrAmount
                .add(amount);
        } else {
            claimLocked[to].lockedList.push(
                TokenLock({nrAmount: amount, startTime: _getDay(), endDay: endDay})
            );
        }
    }

    function _getDay() private view returns (uint256) {
        return (block.timestamp);
    }

    function emergencyAdjustStartIdx(address account, uint8 multiple) public onlyOwner {
        TokenLock[] memory lockedList = locked[account][multiple].lockedList;
        uint256 endIdx = lockedList.length;
        for (uint256 i = 0; i < endIdx; i++) {
            if(lockedList[i].nrAmount != 0){
                locked[account][multiple].startIdx = i;
                break;
            }
        }
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "CLS::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CLSs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "CLS::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../../libraries/SafeMath.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

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
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    // constructor (string memory name_, string memory symbol_) public {
    //     _name = name_;
    //     _symbol = symbol_;
    //     _decimals = 18;
    // }

    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender, 
            msg.sender, 
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) virtual public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) virtual public returns (bool) {
        _approve(
            msg.sender, 
            spender, 
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) virtual internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) virtual internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        
        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal { }
    
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * 
 * Reference:
 * 
 * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/access/Ownable.sol
 */
contract OwnableUpgradeable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor () internal {
    //     address msgSender = msg.sender;
    //     _owner = msgSender;
    //     emit OwnershipTransferred(address(0), msgSender);
    // }

    function __Ownable_init() internal initializer {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);   
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

pragma solidity ^0.6.12;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.12;

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value < 2**248, "SafeCast: value doesn\'t fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
    
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }
}

pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= uint16(-1), "BoringMath: uint16 Overflow");
        c = uint16(a);
    }

}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
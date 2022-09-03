pragma solidity 0.8.6;

/**
* @title Sticky Pool V1.1:
*
*              ,,,,
*            [email protected]@@@@@K
*           [email protected]@@@@@@@P
*            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
*             "*NNM"                     [email protected]@@  [email protected]@@
*                                        [email protected]@@  [email protected]@@
*             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
*            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
*           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
*           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
*           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
*           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
*            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
*             "[email protected]@@@@@        "**""       '''   '''        @@@Y
*    ,[email protected]@g    "[email protected]@@P                                     @@@Y
*   @@@@@@@@p    [email protected]@'                                    @@@Y
*   @@@@@@@@P    [email protected]                                    RNNY
*   '[email protected]@@@@@     $P
*       "[email protected]@@p"'
*
*
*/

/**
* @author ProfWobble
* @dev
* - Staking Contract with veNFTs:
*   - Votes have a weight depending on time.
*   - Vote weight decays linearly over time. 
*   - Lock time cannot be more than `MAXTIME` (4 years).
*   - NFT attributes onchain via the descriptor.
*
* - Votes have a weight depending on time, so that users are committed
*   to the future of (whatever they are voting for).
* - The weight in this implementation is linear, and lock cannot be more than maxtime:
*
*  w ^
*  1 +        /
*    |      /
*    |    /
*    |  /
*    |/
*  0 +--------+------> time
*         maxtime (4 years?)
*
* @dev Based on Curve's Voting Escrow contracts
* @dev Edits based on Solidly and Frax ve contracts
* @author Curve Finance
*/

// TODO
// Add current and next period start timestamps
// Change balanceOf to reflect user votes, not nft count


import "StickyPoolNFT.sol";
import "Base64.sol";
import { BoringMath } from "BoringMath.sol";
import "IERC20.sol";
import "IDescriptor.sol";
import "IJellyContract.sol";
import "IJellyAccessControls.sol";
import "IStickyPool.sol";
import "IJellyDocuments.sol";

import { Strings } from "Strings.sol";

interface IAddressChecker {
    function check(address) external returns (bool);
}

contract StickyPool is IJellyContract, IStickyPool, StickyPoolNFT {
    using Strings for uint256;
    using Strings for address;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public override constant TEMPLATE_TYPE = 2;
    bytes32 public override constant TEMPLATE_ID = keccak256("STICKY_POOL");

    IJellyAccessControls public accessControls;
    IDescriptor public descriptor;
    IJellyDocuments public documents;
    IAddressChecker public checker;

    /// @notice Token to stake.
    address public override poolToken;

    struct PoolSettings {
        bool initialised;
        bool emergencyUnlockActive;
        bool transfersEnabled;
    }
    PoolSettings public poolSettings;

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    event Deposit(
        address indexed provider,
        uint tokenId,
        uint value,
        uint indexed locktime,
        DepositType deposit_type,
        uint ts
    );

    struct Point {
        int128 bias;
        int128 slope; //  -dweight / dt
        uint40 ts;
        uint40 blk; // block
        uint128 amt; // staked amount
    }

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    uint internal constant WEEK = 7 * 86400;
    uint internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint internal constant MULTIPLIER = 1 ether;
    uint internal constant VOTE_WEIGHT_MULTIPLIER =  4 - 1; // 4x gives 300% boost at 4 years
    int128 internal constant VOTE_WEIGHT_MULTIPLIER_I128 =  4 - 1; // 4x gives 300% boost at 4 years

    uint public supply;
    uint public epoch;

    mapping(uint => LockedBalance) public locked;
    mapping(uint => Point) public point_history; // epoch -> unsigned point
    mapping(uint => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]

    mapping(uint => uint) public user_point_epoch;
    mapping(uint => int128) public slope_changes; // time -> signed slope change

    mapping(uint => uint) public attachments;
    mapping(uint => bool) public voted;

    address public voter;
    address public owner;

    event Withdraw(address indexed provider, uint tokenId, uint value, uint ts);
    event Supply(uint prevSupply, uint supply);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }

    constructor() {
    }


    //--------------------------------------------------------
    // Getters
    //-------------------------------------------------------- 

    /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @return Value of the slope
    function get_last_user_slope(uint _tokenId) external view returns (int128) {
        uint uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function user_point_history__ts(uint _tokenId, uint _idx) external view returns (uint) {
        return uint256(user_point_history[_tokenId][_idx].ts);
    }

    /// @notice Get timestamp when `_tokenId`'s lock finishes
    /// @param _tokenId User NFT
    /// @return Epoch time of the lock end
    function locked__end(uint _tokenId) external view returns (uint) {
        return locked[_tokenId].end;
    }

    /// @notice Returns the owner address for Aragon compatability.
    /// @return Controller address
    function controller() external view returns (address) {
        return owner;
    }

    /**
     * @notice Setting for enabling NFT transfers.
     * @return Returns if transfers are enabled.
     */
    function transfersEnabled() external view returns (bool) {
        return poolSettings.transfersEnabled;
    }

    //--------------------------------------------------------
    // Setters
    //-------------------------------------------------------- 

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the admin.
     */
    function setDescriptor(address _descriptor) external {
        require(accessControls.hasAdminRole(msg.sender));
        descriptor = IDescriptor(_descriptor);
    }

    /**
     * @notice Set admin details of the NFT including token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTokenDetails(string memory _name, string memory _symbol) external {
        require(accessControls.hasAdminRole(msg.sender));
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Set owner details for NFT and Aragon compatibility.
     * @dev Only callable by the admin.
     * @dev Doesnt actually control, control managed by accessControls
     */
    function changeController(address _owner) external {
        require(accessControls.hasAdminRole(msg.sender));
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    /**
     * @notice Admin can set the address checker contract.
     * @param _checker Address of the checker contract.
     * @dev Only callable by the admin.
     */
    function setAddressChecker(address _checker) external {
        require(accessControls.hasAdminRole(msg.sender));
        checker = IAddressChecker(_checker);
    }


    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTransfersEnabled(bool _enabled) external {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.transfersEnabled = _enabled;
    }

    //--------------------------------------------------------
    // Locks
    //--------------------------------------------------------
     /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    function create_lock(uint _value, uint _lock_duration) external nonreentrant returns (uint) {
        return _create_lock(_value, _lock_duration, msg.sender);
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function create_lock_for(uint _value, uint _lock_duration, address _to) external nonreentrant returns (uint) {
        return _create_lock(_value, _lock_duration, _to);
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _create_lock(uint _value, uint _lock_duration, address _to) internal returns (uint) {
        _checkAddress(msg.sender);
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_value > 0, "Value must be > 0");
        // GM: unlock_time can not be less than block.timestamp
        require(unlock_time > block.timestamp, 'Cannot unlock in the past');
        require(unlock_time <= block.timestamp + MAXTIME, 'Voting lock can be 4 years max');

        ++tokenId;
        uint _tokenId = tokenId;
        _mint(_to, _tokenId);

        _deposit_for(_tokenId, _value, unlock_time, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }


    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increase_amount(uint _tokenId, uint _value) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        _checkAddress(msg.sender);

        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0, "Value must be > 0");
        require(_locked.amount > 0, 'No existing lock found');
        require(_locked.end > block.timestamp, 'Cannot add to expired lock. Withdraw');

        _deposit_for(_tokenId, _value, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @notice Extend the unlock time for `_tokenId`
    /// @param _lock_duration New number of seconds until tokens unlock
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        _checkAddress(msg.sender);

        LockedBalance memory _locked = locked[_tokenId];
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, 'Lock expired');
        require(_locked.amount > 0, 'Nothing is locked');
        require(unlock_time > _locked.end, 'Can only increase lock duration');
        require(unlock_time <= block.timestamp + MAXTIME, 'Voting lock can be 4 years max');

        _deposit_for(_tokenId, 0, unlock_time, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }


    //--------------------------------------------------------
    // Deposit
    //--------------------------------------------------------

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    /// @param locked_balance Previous locked amount / timestamp
    /// @param deposit_type The type of deposit
    function _deposit_for(
        uint _tokenId,
        uint _value,
        uint unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        // TODO: add checkAddress() except for MERGE_TYPE
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (_locked.amount, _locked.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_tokenId] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, old_locked, _locked);

        address from = msg.sender;
        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE) {
            assert(IERC20(poolToken).transferFrom(from, address(this), _value));
        }

        emit Deposit(from, _tokenId, _value, _locked.end, deposit_type, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }


    function merge(uint _from, uint _to) external {
        require(attachments[_from] == 0 && !voted[_from], "attached");
        require(_from != _to);
        require(_isApprovedOrOwner(msg.sender, _from));
        require(_isApprovedOrOwner(msg.sender, _to));

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];
        uint value0 = uint(int256(_locked0.amount));
        uint end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

        locked[_from] = LockedBalance(0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0));
        _burn(_from);
        _deposit_for(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
    }


    // function split(uint _from, uint _amount) external nonreentrant {
    //     require(attachments[_from] == 0 && !voted[_from], "attached");
    //     require(_amount > 0 );
    //     require(_isApprovedOrOwner(msg.sender, _from));

    //     LockedBalance memory _lockedOld = locked[_from];
    //     LockedBalance memory _lockedNew = locked[_from];

    //     require(uint(int256(_lockedOld.amount)) >= _amount );
    //     _lockedNew.amount -= int128(int256(_amount));
    //     locked[_from] = _lockedNew;
    //     _checkpoint(_from, _lockedOld, _lockedNew);

    //     ++tokenId;
    //     uint _tokenId = tokenId;
    //     _mint(msg.sender, _tokenId);
    //     _deposit_for(_tokenId, _amount, _lockedOld.end, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
    // }


    //--------------------------------------------------------
    // Withdraw
    //--------------------------------------------------------

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint _tokenId) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");

        LockedBalance memory _locked = locked[_tokenId];
        require(block.timestamp >= _locked.end || poolSettings.emergencyUnlockActive, "The lock didn't expire");
        uint value = uint(int256(_locked.amount));

        locked[_tokenId] = LockedBalance(0,0);
        uint supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(0,0));

        assert(IERC20(poolToken).transfer(msg.sender, value));

        // Burn the NFT
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }


    function setEmergencyUnlockActive(bool _active) external {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.emergencyUnlockActive = _active;
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
        // emit EmergencyUnlockToggled(_active);
    }

    //--------------------------------------------------------
    // Token Balances
    //--------------------------------------------------------

    function totalSupply() external view returns (uint) {
        return totalSupplyAtT(block.timestamp);
    }

    function balanceOf(address _user) external override view returns (uint256) {
        uint256[] memory tokenIds = getOwnerTokens(_user);
        uint256 votes = 0;
        if (tokenIds.length > 0) {
            for(uint i = 0; i < tokenIds.length; i++) {
                if (ownership_change[tokenIds[i]] != block.number) {
                    votes += _balanceOfNFT(tokenIds[i], block.timestamp);
                }
            }
        }
        return votes;
    }

    function stakedBalance(uint256 _tokenId) external override view returns(uint256) {
        return uint256(int256(locked[_tokenId].amount));
    }

    function balanceOfNFT(uint _tokenId) external view returns (uint) {
        if (ownership_change[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint) {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint) {
        return _balanceOfNFT(_tokenId, _t);
    }


    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function totalSupplyAtT(uint t) public view returns (uint) {
        uint _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return _supply_at(last_point, t);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _block Block to calculate the total voting power at
    /// @return Total voting power at `_block`
    function totalSupplyAt(uint _block) external view returns (uint) {
        assert(_block <= block.number);
        uint _epoch = epoch;
        uint target_epoch = _find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint dt = 0;
        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
            }
        } else {
            if (uint256(point.blk) != block.number) {
                dt = ((BoringMath.to40(_block) - point.blk) * (BoringMath.to40(block.timestamp) - point.ts)) / (BoringMath.to40(block.number) - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supply_at(point, uint256(point.ts + dt));
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOfNFT(uint _tokenId, uint _t) internal view returns (uint) {
        uint _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[_tokenId][_epoch];
            last_point.bias -= last_point.slope * int128(int256(_t) - int256(uint256(last_point.ts)));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            uint128 weighted_supply = uint128(last_point.bias);
            if (weighted_supply < last_point.amt) {
                weighted_supply = last_point.amt;
            }
            return uint256(weighted_supply);
        }
    }

    /// @notice Measure voting power of `_tokenId` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param _tokenId User's wallet NFT
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function _balanceOfAtNFT(uint _tokenId, uint _block) internal view returns (uint) {

        assert(_block <= block.number);

        // Binary search
        uint _min = 0;
        uint _max = user_point_epoch[_tokenId];
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            // GM TODO: it compiles fine without converting to uint40
            if (user_point_history[_tokenId][_mid].blk <= BoringMath.to40(_block)) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        Point memory upoint = user_point_history[_tokenId][_min];
        uint max_epoch = epoch;
        uint _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint40 d_block = 0;
        uint40 d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = BoringMath.to40(block.number) - point_0.blk;
            d_t = BoringMath.to40(block.timestamp) - point_0.ts;
        }
        uint40 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (BoringMath.to40(_block) - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(uint256(block_time - upoint.ts)));

        if (upoint.bias >= 0 || upoint.amt >= 0 ) {
            return uint(uint128(upoint.bias));
        } else {
            return 0;
        }
    }


    //--------------------------------------------------------
    // Checkpoint
    //--------------------------------------------------------
    /// @notice Record global data to checkpoint
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param old_locked Pevious locked amount / end lock time for the user
    /// @param new_locked New locked amount / end lock time for the user
    function _checkpoint(
        uint _tokenId,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = (old_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / iMAXTIME;
                u_old.bias = old_locked.amount + (u_old.slope * int128(int256(old_locked.end - block.timestamp)));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = (new_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / iMAXTIME;
                u_new.bias = new_locked.amount + (u_new.slope * int128(int256(new_locked.end - block.timestamp)));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: BoringMath.to40(block.timestamp), blk: BoringMath.to40(block.number), amt: 0});
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }

        uint last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint block_slope = 0; // dblock/dt
        // GM TODO: conversion is not needed.
        if (block.timestamp > uint256(last_point.ts)) {
            block_slope = (MULTIPLIER * (block.number - uint256(last_point.blk))) / (block.timestamp - uint256(last_point.ts));
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = BoringMath.to40(t_i);
                last_point.blk = initial_last_point.blk + BoringMath.to40((block_slope * (t_i - uint256(initial_last_point.ts))) / MULTIPLIER);
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = BoringMath.to40(block.number);
                    break;
                } else {
                    point_history[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (new_locked.amount > old_locked.amount) {
                last_point.amt += BoringMath.to128(uint256(int256(new_locked.amount - old_locked.amount)));
            }
            if (new_locked.amount < old_locked.amount) {
                last_point.amt -= BoringMath.to128(uint256(int256(old_locked.amount - new_locked.amount)));

                if (new_locked.amount == 0 && !poolSettings.emergencyUnlockActive) {
                    last_point.bias -= old_locked.amount;
                }
            }

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint user_epoch = user_point_epoch[_tokenId] + 1;

            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = BoringMath.to40(block.timestamp);
            u_new.blk = BoringMath.to40(block.number);
            u_new.amt = BoringMath.to128(uint256(int256(locked[_tokenId].amount)));

            user_point_history[_tokenId][user_epoch] = u_new;
        }
    }

    //--------------------------------------------------------
    // Voting
    //--------------------------------------------------------

    function setVoter(address _voter) external {
        require(accessControls.hasAdminRole(msg.sender));
        voter = _voter;
    }

    function voting(uint _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = true;
    }

    function abstain(uint _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = false;
    }

    function attach(uint _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId]+1;
    }

    function detach(uint _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId]-1;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------
    /**
     * @notice Set the global document store.
     * @dev Only callable by the admin.
     */
    function setDocumentController(address _documents) external {
        require(accessControls.hasAdminRole(msg.sender));
        documents = IJellyDocuments(_documents);
    }
    /**
     * @notice Set the documents in the global store.
     * @dev Only callable by the admin and operator.
     * @param _name Document key.
     * @param _data Document value. Leave blank to remove document
     */
    function setDocument(string calldata _name, string calldata _data)
        external
    {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender));
        if (bytes(_data).length > 0) {
            documents.setDocument(address(this), _name, _data);
        } else {
            documents.removeDocument(address(this), _name);
        }
    }

    //--------------------------------------------------------
    // Jelly Pool NFTs
    //--------------------------------------------------------
    /// @dev Returns current token URI metadata
    /// @param _tokenId Token ID to fetch URI for.
    function tokenURI(uint _tokenId) external override view returns (string memory) {
        // require(idToOwner[_tokenId] != address(0), "Nonexistent token");
        if (address(descriptor) != address(0)) {
            return descriptor.tokenURI(_tokenId);
        }
        return "";
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(poolSettings.transfersEnabled && 
                attachments[_tokenId] == 0 && 
                !voted[_tokenId], "attached");
    }


    //--------------------------------------------------------
    // Helpers
    //--------------------------------------------------------
    /// @notice Checks if an address is a smart contract and if so, valid
    function _checkAddress(address _addr) internal returns (bool) {
        if (_addr != tx.origin && address(checker) != address(0)) {
            assert(checker.check(_addr));
        }
        return true;
    }

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param max_epoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
    function _find_block_epoch(uint _block, uint max_epoch) internal view returns (uint) {
        // Binary search
        uint _min = 0;
        uint _max = max_epoch;
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
    //  PW: return to internal after testing
    function _supply_at(Point memory point, uint t) public view returns (uint) {
        Point memory last_point = point;
        uint t_i = (last_point.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * int128(int256(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = BoringMath.to40(t_i);
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        uint128 weighted_supply = uint128(last_point.bias);
        if (weighted_supply < last_point.amt) {
            weighted_supply = last_point.amt;
        }
        return uint256(weighted_supply);
    }

    // receive() external payable {
    //     revert();
    // }

    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.

     */
    function initJellyPool(
        address _poolToken,
        address _accessControls
    ) public 
    {
        require(!poolSettings.initialised);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        point_history[0].blk = BoringMath.to40(block.number) ;
        point_history[0].ts = BoringMath.to40(block.timestamp);
        // point_history[0].amt = 0;
        // point_history[0].bias = 0;
        // point_history[0].slope = 0;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
        epoch = 0;
        _entered_state = 1;

        // _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
        // mint-ish
        emit Transfer(address(0), address(this), tokenId);
        // burn-ish
        emit Transfer(address(this), address(0), tokenId);

        // poolSettings.emergencyUnlockActive = false;
        poolSettings.transfersEnabled = true;
        poolSettings.initialised = true;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) external override {
        (
        address _poolToken,
        address _accessControls
        ) = abi.decode(_data, (address, address));

        initJellyPool(
                        _poolToken,
                        _accessControls
                    );
    }
}

pragma solidity 0.8.6;

/**
* @title Sticky NFT V1.0:
*
*              ,,,,
*            [email protected]@@@@@K
*           [email protected]@@@@@@@P
*            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
*             "*NNM"                     [email protected]@@  [email protected]@@
*                                        [email protected]@@  [email protected]@@
*             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
*            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
*           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
*           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
*           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
*           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
*            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
*             "[email protected]@@@@@        "**""       '''   '''        @@@Y
*    ,[email protected]@g    "[email protected]@@P                                     @@@Y
*   @@@@@@@@p    [email protected]@'                                    @@@Y
*   @@@@@@@@P    [email protected]                                    RNNY
*   '[email protected]@@@@@     $P
*       "[email protected]@@p"'
*
*
*/

/**
* @author ProfWobble
* @dev
* - Basic NFT used for the StickyPool:
*
* @dev Based on Solidly NFT contracts
* @author Andre Cronje
*/

import "IERC721Receiver.sol";
import "IERC721Metadata.sol";

contract StickyPoolNFT is IERC721Metadata {

    string public override name;
    string public override symbol;
    string constant public version = "1.0.0";
    uint8 constant public decimals = 18;

    /// @dev Current count of token
    uint internal tokenId;

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint => address) internal idToOwner;

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint => address) internal idToApprovals;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint) internal ownerToNFTokenCount;

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint => uint)) internal ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint => uint) internal tokenToOwnerIndex;

    mapping(uint => uint) public ownership_change;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @notice Contract constructor
    constructor(
    ) {

    }

    /// @dev Interface identification is specified in ERC-165.
    /// @param _interfaceID Id of the interface
    function supportsInterface(bytes4 _interfaceID) external override  view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function _balance(address _owner) internal view returns (uint) {
        return ownerToNFTokenCount[_owner];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function balanceOf(address _owner) external override virtual view returns (uint) {
        return _balance(_owner);
    }

    /// @dev Returns the address of the owner of the NFT.
    /// @param _tokenId The identifier for an NFT.
    function ownerOf(uint _tokenId) public override view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @dev Get the approved address for a single NFT.
    /// @param _tokenId ID of the NFT to query the approval of.
    function getApproved(uint _tokenId) external override view returns (address) {
        return idToApprovals[_tokenId];
    }

    /// @dev Checks if `_operator` is an approved operator for `_owner`.
    /// @param _owner The address that owns the NFTs.
    /// @param _operator The address that acts on behalf of the owner.
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /// @dev  Get token by index
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint) {
        return ownerToNFTokenIdList[_owner][_tokenIndex];
    }

    /// @dev  Get owners tokenIDs
    function getOwnerTokens(address _owner) public view returns (uint256[] memory) {
        uint256 count = _balance(_owner);
        uint256[] memory tokenIds = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            tokenIds[i] = ownerToNFTokenIdList[_owner][i];
        }
        return tokenIds;
    }

    /// @dev Returns whether the given spender can transfer a given token ID
    /// @param _spender address of the spender to query
    /// @param _tokenId uint ID of the token to be transferred
    /// @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
    function _isApprovedOrOwner(address _spender, uint _tokenId) internal view returns (bool) {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint _tokenId) internal {
        uint current_count = _balance(_to);

        ownerToNFTokenIdList[_to][current_count] = _tokenId;
        tokenToOwnerIndex[_tokenId] = current_count;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {
        // Delete
        uint current_count = _balance(_from)-1;
        uint current_index = tokenToOwnerIndex[_tokenId];

        if (current_count == current_index) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint lastTokenId = ownerToNFTokenIdList[_from][current_count];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_index] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = current_index;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(idToOwner[_tokenId] == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(idToOwner[_tokenId] == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    /// @dev Clear an approval of a given address
    ///      Throws if `_owner` is not the current owner.
    function _clearApproval(address _owner, uint _tokenId) internal {
        // Throws if `_owner` is not the current owner
        assert(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {
            // Reset approvals
            idToApprovals[_tokenId] = address(0);
        }
    }

    /// @dev Exeute transfer of a NFT.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_tokenId` is not a valid NFT.
    function _transferFrom(
        address _from,
        address _to,
        uint _tokenId,
        address _sender
    ) internal {
        _beforeTokenTransfer(_from,_to, _tokenId);
        // Check requirements
        require(_isApprovedOrOwner(_sender, _tokenId));
        // Clear approval. Throws if `_from` is not the current owner
        _clearApproval(_from, _tokenId);
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownership_change[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /* TRANSFER FUNCTIONS */
    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    /// @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
    ///        they maybe be permanently lost.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) external override {
        _transferFrom(_from, _to, _tokenId, msg.sender);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {

    }

    function tokenURI(uint _tokenId) external override virtual view returns (string memory) {

    }


    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    /// @param _data Additional data with no specified format, sent in call to `_to`.
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory _data
    ) public override  {
        _transferFrom(_from, _to, _tokenId, msg.sender);

        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4) {} catch (
                bytes memory reason
            ) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) external override  {
        safeTransferFrom(_from, _to, _tokenId, '');
    }

    /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
    ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    /// @param _approved Address to be approved for the given NFT ID.
    /// @param _tokenId ID of the token to be approved.
    function approve(address _approved, uint _tokenId) public override {
        address owner = idToOwner[_tokenId];
        // Throws if `_tokenId` is not a valid NFT
        require(owner != address(0));
        // Throws if `_approved` is the current owner
        require(_approved != owner);
        // Check requirements
        bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
        require(senderIsOwner || senderIsApprovedForAll);
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @dev Enables or disables approval for a third party ("operator") to manage all of
    ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
    ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    /// @notice This works even if sender doesn't own any tokens at the time.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved) external override {
        // Throws if `_operator` is the `msg.sender`
        assert(_operator != msg.sender);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    function _burn(uint _tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        address owner = ownerOf(_tokenId);

        // Clear approval
        approve(address(0), _tokenId);
        // Remove token
        _removeTokenFrom(msg.sender, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }

}

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.6;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

pragma solidity 0.8.6;

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

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        require(a <= type(uint208).max, "BoringMath: uint128 Overflow");
        c = uint208(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to48(uint256 a) internal pure returns (uint48 c) {
        require(a <= type(uint48).max);
        c = uint48(a);
    }

    function to40(uint256 a) internal pure returns (uint40 c) {
        require(a <= type(uint40).max);
        c = uint40(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max);
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max);
        c = uint16(a);
    }

    function to8(uint256 a) internal pure returns (uint8 c) {
        require(a <= type(uint8).max);
        c = uint8(a);
    }

}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath208 {
    function add(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
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

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath48 {
    function add(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath40 {
    function add(uint40 a, uint40 b) internal pure returns (uint40 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint40 a, uint40 b) internal pure returns (uint40 c) {
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

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint8.
library BoringMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.8.6;

interface IERC20 {

    /// @notice ERC20 Functions 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

pragma solidity 0.8.6;
interface IDescriptor {

    function tokenURI(
        uint256 tokenId
    ) external view returns (string memory);

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

pragma solidity 0.8.6;

interface IStickyPool {

    // function setRewardsContract(address _addr) external;
    // function setTokensClaimable(bool _enabled) external;

    // function stakedTokenTotal() external view returns(uint256);
    function stakedBalance(uint256 _tokenId) external view returns(uint256);
    // function tokensClaimable() external view returns(bool);
    function poolToken() external view returns(address);

}

pragma solidity 0.8.6;

interface IJellyDocuments {
    function setDocument(
        address _contractAddr,
        string calldata _name,
        string calldata _data
    ) external;

    function setDocuments(
        address _contractAddr,
        string[] calldata _name,
        string[] calldata _data
    ) external;

    function removeDocument(address _contractAddr, string calldata _name)
        external;
}

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }
}
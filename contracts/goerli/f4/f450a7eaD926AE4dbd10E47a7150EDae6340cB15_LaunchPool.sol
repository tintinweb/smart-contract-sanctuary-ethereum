// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/ILaunchPool.sol";
import "./interfaces/IStakingTier.sol";
import "./constants/SharedConstants.sol";
import "../libs/SafeArrays.sol";
import "../governance/WhitelistPermissionable.sol";
import "../governance/BlacklistPermissionable.sol";

contract LaunchPool is
    Initializable,
    ILaunchPool,
    SharedConstants,
    WhitelistPermissionable,
    BlacklistPermissionable,
    StakingTierModels
{
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;
    using SafeArrays for uint256[];

    address public _factory;
    IStakingTier public _tierManager;

    Statuses public _status;
    LaunchPadInfo public _poolInfo;
    VestingTimeline private _vestingTimeline;

    mapping(address => RegisterPayload) public _registers;
    mapping(address => DepAmountPayload) public _depAmounts;
    mapping(address => VestingHistory[]) private _claimedHistories;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint32 constant EMERGENCY_WITHDRAW_FEE = 1500;
    uint256 private _totalRaised;
    uint256 private _tierRoundRaised;
    uint256 private _communityRoundRaised;
    uint256 private _totalFee;
    uint32 private _tierRoundParticipants;
    uint32 private _communityRoundParticipants;
    uint256 private _totalSlot;
    uint32 private _participants;

    function initialize(
        LaunchPadInfo memory poolInfo_,
        VestingTimeline memory vestingTimeline_,
        address owner_,
        address tierManager_
    ) external override initializer {
        require(
            poolInfo_.unsoldTokenAction == UnsoldTokenAction.BURN ||
                poolInfo_.unsoldTokenAction == UnsoldTokenAction.REFUND,
            "invalid unsold token action"
        );
        require(
            poolInfo_.registerRound.startAt > block.timestamp,
            "invalid register time"
        );
        require(
            poolInfo_.registerRound.endAt > poolInfo_.registerRound.startAt,
            "invalid register time"
        );
        require(
            poolInfo_.registerRound.endAt < poolInfo_.tierRound.startAt,
            "register time must be before tier time"
        );
        require(
            poolInfo_.tierRound.endAt > poolInfo_.tierRound.startAt,
            "invalid tier round time"
        );
        require(
            poolInfo_.tierRound.endAt < poolInfo_.communityRound.startAt,
            "tier time must be before community time"
        );
        require(
            poolInfo_.communityRound.endAt > poolInfo_.communityRound.startAt,
            "invalid community round time"
        );
        require(
            poolInfo_.softCap > 0 && poolInfo_.hardCap > 0,
            "softcap and hardcap invalid"
        );
        require(
            poolInfo_.softCap < poolInfo_.hardCap,
            "softcap must be less than hard cap"
        );
        require(poolInfo_.min > 0 && poolInfo_.max > 0, "min and max invalid");
        require(poolInfo_.min < poolInfo_.max, "min and max invalid");
        require(poolInfo_.salePrice > 0, "invalid sale price");
        require(
            vestingTimeline_.percents.length ==
                vestingTimeline_.timestamps.length,
            "vesting timeline invalid format"
        );
        require(
            vestingTimeline_.percents.sum() == 10000,
            "invalid vesting timeline"
        );

        require(
            _validateVestingTimeline(
                vestingTimeline_,
                poolInfo_.communityRound.endAt
            ),
            "vesting timeline must be after end time"
        );

        _poolInfo = poolInfo_;
        _vestingTimeline = vestingTimeline_;
        // _projectInfo = projectInfo_;
        _status = Statuses.COMMING;

        _factory = _msgSender();
        _tierManager = IStakingTier(tierManager_);

        if (poolInfo_.saleType == SaleType.WHITELIST) {
            _enableWhitelist(true);
        }

        _transferOwnership(owner_);
    }

    /******************************************* Owner function below *******************************************/
    function cancel() external virtual override whenOpening onlyManagerOrOwner {
        _status = Statuses.CANCELLED;
        emit ChangeStatus(_status);
    }

    function complete()
        external
        virtual
        override
        whenOpening
        onlyManagerOrOwner
    {
        require(
            _totalRaised >= _poolInfo.softCap,
            "funds raised less than softcap"
        );

        // If address token == address(0), so do nothing
        if (address(_poolInfo.token) != address(0)) {
            _handleUnsoldToken(_msgSender());
        }

        _status = Statuses.COMPLETED;
        emit ChangeStatus(_status);
    }

    function updateSaleType(SaleType _saleType)
        external
        virtual
        override
        onlyManagerOrOwner
    {
        require(_status == Statuses.COMMING, "pool is started");
        if (_saleType != _poolInfo.saleType) {
            _poolInfo.saleType = _saleType;
            emit UpdateSaleType(_saleType);
        }
        if (_saleType == SaleType.PUBLIC) {
            enableWhitelist(false);
        } else {
            enableWhitelist(true);
        }
    }

    /**
     * WARNING!! ONLY USE IN EMERGENCY CASE OR THE POOL IS COMPLETED
     * @dev send BNB to owner
     */
    function collectBNB() external virtual override onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * WARNING!! ONLY USE IN EMERGENCY CASE OR THE POOL IS COMPLETED
     * @dev send Token to owner
     */
    function collectToken() external virtual override onlyOwner {
        IERC20Metadata token = _poolInfo.token;
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "balance is zero");
        token.safeTransfer(_msgSender(), amount);
    }

    /**
     * WARNING!! ONLY USE IN EMERGENCY CASE OR THE POOL IS COMPLETED
     * @dev send USD to owner
     */
    function collectFunds() external virtual override onlyOwner {
        IERC20Metadata token = _poolInfo.tokenForPay;
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "balance is zero");
        token.safeTransfer(_msgSender(), amount);
    }

    /**
     * WARNING!! ONLY SET SLOT FOR ADDRESS
     * @dev set SLOT for address
     */
    function setRegister(address user, uint256 slot)
        external
        virtual
        whenOpening
        onlyManagerOrOwner
    {
        require(
            block.timestamp <= _poolInfo.registerRound.endAt,
            "register round is ended"
        );

        // Subtract participant, check slot = 0, admin wanna remove registing of user
        if (slot <= 0 && _registers[user].timestamp <= 0) {
            _participants -= 1;
        }

        // Add participant, check slot = 0, admin wanna update registing of user
        if (slot > 0 && _registers[user].timestamp <= 0) {
            _participants += 1;
        }

        // Subtract previous slot of user before
        _totalSlot = _totalSlot.sub(_registers[user].slot);
        // Add next slot of user after
        _totalSlot = _totalSlot.add(slot);

        _registers[user] = RegisterPayload(block.timestamp, 0, slot);
        emit Register(user);
    }

    /******************************************* Participant function below *******************************************/
    function register()
        external
        virtual
        onlyWhitelisted
        onlyNotExistInBlacklist
        whenOpening
        onlyUnRegister
    {
        require(
            block.timestamp >= _poolInfo.registerRound.startAt,
            "register round is not open yet"
        );
        require(
            block.timestamp <= _poolInfo.registerRound.endAt,
            "register round is ended"
        );

        address sender = _msgSender();
        UserTier memory uTier = _getUserTier(sender);
        _totalSlot = _totalSlot.add(uTier.slot);
        _participants += 1;
        _registers[sender] = RegisterPayload(
            block.timestamp,
            uTier.amount,
            uTier.slot
        );
        emit Register(sender);
    }

    function unregister() external virtual whenOpening onlyRegistered {
        require(
            block.timestamp >= _poolInfo.registerRound.startAt,
            "register round is not open yet"
        );
        require(
            block.timestamp <= _poolInfo.registerRound.endAt,
            "register round is ended"
        );
        address sender = _msgSender();
        _totalSlot = _totalSlot.sub(_registers[sender].slot);
        _participants -= 1;
        _registers[sender] = RegisterPayload(0, 0, 0);
        emit UnRegister(sender);
    }

    function buyTierRound(uint256 amount)
        external
        virtual
        override
        onlyWhitelisted
        onlyNotExistInBlacklist
        whenOpening
        onlyRegistered
    {
        require(
            block.timestamp >= _poolInfo.tierRound.startAt,
            "tier round is not start yet"
        );
        require(
            block.timestamp <= _poolInfo.tierRound.endAt,
            "tier round is ended"
        );
        require(amount > 0, "amount must be greater than 0");
        require(
            _totalRaised.add(amount) <= _poolInfo.hardCap,
            "exceeded the capacity"
        );

        address user = _msgSender();
        uint256 alloc = _calAlloc(user);

        require(
            _depAmounts[user].tier.add(amount) <= alloc,
            "exceeded the allocation"
        );

        _poolInfo.tokenForPay.safeTransferFrom(user, address(this), amount);

        if (_depAmounts[user].tier <= 0) {
            _tierRoundParticipants += 1;
        }
        _depAmounts[user].tier += amount;
        _totalRaised += amount;
        _tierRoundRaised += amount;

        // Update _status to open if sale time is start
        if (_status == Statuses.COMMING) {
            _status = Statuses.OPENING;
        }

        emit BuyTierRound(user, amount);
    }

    function buyCommunityRound(uint256 amount)
        external
        virtual
        override
        onlyWhitelisted
        onlyNotExistInBlacklist
        whenOpening
        onlyRegistered
    {
        require(
            block.timestamp >= _poolInfo.communityRound.startAt,
            "community round is not start yet"
        );
        require(
            block.timestamp <= _poolInfo.communityRound.endAt,
            "community round is ended"
        );
        require(amount > 0, "amount must be greater than 0");
        require(
            _totalRaised.add(amount) <= _poolInfo.hardCap,
            "exceeded the capacity"
        );
        address user = _msgSender();
        require(
            _depAmounts[user].community.add(amount) >= _poolInfo.min,
            "under the min user can buy"
        );
        require(
            _depAmounts[user].community.add(amount) <= _poolInfo.max,
            "exceeded the max user can buy"
        );
        _poolInfo.tokenForPay.safeTransferFrom(user, address(this), amount);

        if (_depAmounts[user].community <= 0) {
            _communityRoundParticipants += 1;
        }
        _depAmounts[user].community = _depAmounts[user].community.add(amount);
        _totalRaised = _totalRaised.add(amount);
        _communityRoundRaised = _communityRoundRaised.add(amount);

        // Update _status to open if sale time is start
        if (_status == Statuses.COMMING) {
            _status = Statuses.OPENING;
        }

        emit BuyCommunityRound(user, amount);
    }

    function emergencyWithdraw() external virtual override {
        require(_status != Statuses.CANCELLED, "pool is cancelled");
        require(_status != Statuses.COMPLETED, "pool is completed");
        require(block.timestamp < _poolInfo.tierRound.endAt, "pool is ended");

        address user = _msgSender();
        uint256 amount = _depositedAmount(user);
        uint256 fee = amount.mul(EMERGENCY_WITHDRAW_FEE).div(10000);

        // Transfer token to user
        _poolInfo.tokenForPay.safeTransfer(user, amount.sub(fee));
        _depAmounts[user] = DepAmountPayload(0, 0);
        _totalRaised = _totalRaised.sub(amount);
        _tierRoundRaised = _tierRoundRaised.sub(amount);
        _totalFee = _totalFee.add(fee);

        emit EmergencyWithdraw(user, amount.sub(fee));
    }

    function withdraw() external virtual override {
        require(
            _status == Statuses.CANCELLED,
            "pool has not been cancelled yet"
        );

        address user = _msgSender();
        uint256 amount = _depositedAmount(user);

        // Transfer token to user
        _poolInfo.tokenForPay.safeTransfer(user, amount);

        _depAmounts[user] = DepAmountPayload(0, 0);
        _totalRaised = _totalRaised.sub(amount);

        emit Withdraw(user, amount);
    }

    function claim(uint32 _index) external virtual override {
        require(_status == Statuses.COMPLETED, "pool is not completed yet");
        require(address(_poolInfo.token) != address(0), "token is not exist");

        address user = _msgSender();
        uint256 depAmt = _depositedAmount(user);
        require(depAmt > 0, "did not buy");
        require(
            _index < _vestingTimeline.percents.length,
            "invalid vesting timeline"
        );
        require(_isUserClaimed(user, _index), "claimed");

        // check it's time to claim with _index vesting timeline
        uint256 percent = _vestingTimeline.percents[_index];
        uint256 timestamp = _vestingTimeline.timestamps[_index];

        require(block.timestamp >= timestamp, "it is not time to claim");

        uint256 decimals = _poolInfo.tokenForPay.decimals();
        uint256 tokenAmt = depAmt.mul(_poolInfo.salePrice).div(10**decimals);

        uint256 freezeAmt = tokenAmt.mul(percent).div(10000);

        // safe transfer token's launchpad for user
        _poolInfo.token.safeTransfer(user, freezeAmt);

        // store vesting history
        uint256 claimAt = block.timestamp;
        VestingHistory memory history = VestingHistory(
            _index,
            freezeAmt,
            claimAt
        );
        _claimedHistories[user].push(history);

        emit Claim(_index, user, freezeAmt);
    }

    function claimed(address user_) external view override returns (uint256) {
        return _claimed(user_);
    }

    function vestingSchedule()
        external
        view
        virtual
        returns (VestingTimeline memory)
    {
        return _vestingTimeline;
    }

    function vestingHistories(address _addr)
        external
        view
        virtual
        returns (VestingHistory[] memory)
    {
        return _claimedHistories[_addr];
    }

    function calAlloc(address user_) external view returns (uint256) {
        return _calAlloc(user_);
    }

    function getPoolStatistic()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _totalRaised,
            _tierRoundRaised,
            _communityRoundRaised,
            _tierRoundParticipants,
            _communityRoundParticipants,
            _totalFee,
            _totalSlot,
            _participants
        );
    }

    /******************************************* Internal function below *******************************************/
    function _isUserClaimed(address _addr, uint32 _index)
        internal
        view
        virtual
        returns (bool)
    {
        VestingHistory[] memory histories = _claimedHistories[_addr];
        for (uint32 i = 0; i < histories.length; i++) {
            if (histories[i].index == _index) return false;
        }
        return true;
    }

    function _claimed(address user_) internal view virtual returns (uint256) {
        uint256 claimedAmount;
        VestingHistory[] memory histories = _claimedHistories[user_];
        for (uint32 i = 0; i < histories.length; i++) {
            claimedAmount = claimedAmount.add(histories[i].amount);
        }
        return claimedAmount;
    }

    function _handleUnsoldToken(address recipient_) internal virtual {
        IERC20Metadata token = _poolInfo.token;
        uint256 remainCap = _poolInfo.hardCap.sub(_totalRaised);
        uint256 remainToken = remainCap.mul(_poolInfo.salePrice).div(
            10**_poolInfo.tokenForPay.decimals()
        );
        if (token.balanceOf(address(this)) <= 0) {
            return;
        }
        if (_poolInfo.unsoldTokenAction == UnsoldTokenAction.REFUND) {
            token.safeTransfer(recipient_, remainToken);
        }
        if (_poolInfo.unsoldTokenAction == UnsoldTokenAction.BURN) {
            token.safeTransfer(BURN_ADDRESS, remainToken);
        }
    }

    function _calAlloc(address user_) internal view returns (uint256) {
        if (_registers[user_].timestamp <= 0) {
            return 0;
        }
        // uint256 alloc = _getUserTier(user_).slot * _baseAlloc();
        uint256 alloc = _registers[user_].slot.mul(_baseAlloc());
        return alloc;
    }

    function _baseAlloc() internal view returns (uint256) {
        if (_totalSlot == 0) return _poolInfo.hardCap.div(1);
        return _poolInfo.hardCap.div(_totalSlot);
        // return _poolInfo.hardCap / _totalSlot;
    }

    function _getUserTier(address user_)
        internal
        view
        returns (UserTier memory)
    {
        if (address(_tierManager) == address(0)) {
            return UserTier(0, 0, "", 0, true);
        }
        UserTier memory userTier = _tierManager.getUserTier(user_);
        return userTier;
    }

    function _depositedAmount(address user_) internal view returns (uint256) {
        return _depAmounts[user_].tier.add(_depAmounts[user_].community);
    }

    function _validateVestingTimeline(
        VestingTimeline memory vestingTimeline_,
        uint256 endAt_
    ) internal pure returns (bool) {
        uint256[] memory times = vestingTimeline_.timestamps;
        for (uint256 i = 0; i < times.length; i++) {
            if (times[i] < endAt_) {
                return false;
            }
        }
        return true;
    }

    modifier whenOpening() {
        require(_status != Statuses.CANCELLED, "pool is cancelled");
        require(_status != Statuses.COMPLETED, "Pool is completed");
        _;
    }

    modifier onlyRegistered() {
        require(_registers[_msgSender()].timestamp > 0, "unregister");
        _;
    }

    modifier onlyUnRegister() {
        require(_registers[_msgSender()].timestamp <= 0, "registered");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

library SafeArrays {
    function existed(address[] memory _addrs, address _addr)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (_addrs[i] == _addr) return true;
        }
        return false;
    }

    function sum(uint256[] memory arr) internal pure returns (uint256) {
        uint256 i;
        uint256 s = 0;
        for (i = 0; i < arr.length; i++) s = s + arr[i];
        return s;
    }

    function remove(address[] storage _arr, address _val)
        internal
        returns (address[] memory)
    {
        // Find index
        uint256 index;
        bool flag = false;
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _val) {
                index = i;
                flag = true;
                break;
            }
        }
        if (flag) {
            _arr[index] = _arr[_arr.length - 1];
            _arr.pop();
            return _arr;
        }
        return _arr;
    }

    function remove(uint256[] storage _arr, uint256 _val)
        internal
        returns (uint256[] memory)
    {
        // Find index
        uint256 index;
        bool flag = false;
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _val) {
                index = i;
                flag = true;
                break;
            }
        }
        if (flag) {
            _arr[index] = _arr[_arr.length - 1];
            _arr.pop();
            return _arr;
        }
        return _arr;
    }

    function add(address[] storage _arr, address _val)
        internal
        returns (address[] memory)
    {
        _arr.push(_val);
        return _arr;
    }

    function add(uint256[] storage _arr, uint256 _val)
        internal
        returns (uint256[] memory)
    {
        _arr.push(_val);
        return _arr;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ISycningValidatorModels {
    struct SyncingRecord {
        string action;
        address user;
        uint256 amount;
        string txHash;
        string chainId;
        uint256 deadline;
        bytes signature;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ISycningValidatorModels.sol";

interface StakingTierModels is ISycningValidatorModels {
    struct UserTier {
        uint256 amount;
        uint256 slot;
        string levelName;
        uint256 dataId;
        bool added;
    }

    struct UserTierListItem {
        address user;
        uint256 amount;
        uint256 slot;
        string levelName;
    }

    struct Level {
        string name;
        string description;
        uint256 minAmount;
        uint256 slot;
    }
}

interface IStakingTier is StakingTierModels {
    function initialize(
        address signer_,
        ERC20 token_,
        address stakingContract_
    ) external;

    function syncTier(SyncingRecord[] memory records_) external;

    function updateUserTier(
        string memory action_,
        address user_,
        uint256 amount_
    ) external;

    function getUserTiers() external view returns (UserTierListItem[] memory);

    function getLevels() external view returns (Level[] memory);

    function getUserTier(address user_) external view returns (UserTier memory);

    function setStakingContract(address newAddress_) external;

    function updateLevels(Level[] memory levels_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./../constants/SharedConstants.sol";

interface ILaunchPool {
    event EmergencyWithdraw(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);
    event BuyTierRound(address indexed user, uint256 indexed amount);
    event BuyCommunityRound(address indexed user, uint256 indexed amount);
    event ChangeStatus(SharedConstants.Statuses indexed status);
    event UpdateSaleType(SharedConstants.SaleType indexed saleType);
    event Register(address indexed user);
    event UnRegister(address indexed user);
    event Claim(
        uint32 indexed index,
        address indexed user,
        uint256 indexed amount
    );

    function initialize(
        SharedConstants.LaunchPadInfo memory poolInfo_,
        SharedConstants.VestingTimeline memory _vestingTimeline_,
        address poolOwner_,
        address tierManager_
    ) external;

    function cancel() external;

    function complete() external;

    function collectBNB() external;

    function collectToken() external;

    function collectFunds() external;

    function updateSaleType(SharedConstants.SaleType _saleType) external;

    function register() external;

    function unregister() external;

    function buyTierRound(uint256 amount) external;

    function buyCommunityRound(uint256 amount) external;

    function emergencyWithdraw() external;

    function withdraw() external;

    function claim(uint32 _index) external;

    function claimed(address user_) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract SharedConstants {
    enum Statuses {
        COMMING,
        OPENING,
        COMPLETED,
        CANCELLED
    }

    enum SaleType {
        PUBLIC,
        WHITELIST
    }

    enum UnsoldTokenAction {
        BURN,
        REFUND
    }

    struct RoundTime {
        uint256 startAt;
        uint256 endAt;
    }

    struct VestingTimeline {
        uint256[] percents;
        uint256[] timestamps;
    }

    struct VestingHistory {
        uint32 index;
        uint256 amount;
        uint256 claimAt;
    }

    // struct ProjectInfo {
    //     string name;
    //     string description;
    //     string facebook;
    //     string discord;
    //     string twitter;
    //     string telegram;
    //     string website;
    //     string github;
    //     string instagram;
    //     string audit;
    // }

    struct LaunchPadInfo {
        IERC20Metadata token;
        IERC20Metadata tokenForPay;
        UnsoldTokenAction unsoldTokenAction;
        SaleType saleType;
        uint256 salePrice;
        uint256 softCap;
        uint256 hardCap;
        uint256 min; // In Community Round
        uint256 max; // In Community Round
        RoundTime registerRound;
        RoundTime tierRound;
        RoundTime communityRound;
    }

    struct RegisterPayload {
        uint256 timestamp;
        uint256 amount;
        uint256 slot;
    }

    struct DepAmountPayload {
        uint256 tier;
        uint256 community;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./../../libs/SafeArrays.sol";

abstract contract Whitelist {
    bool public whitelistStatus;
    using SafeArrays for address[];
    address[] private addresses;
    mapping(address => bool) private _whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        if (whitelistStatus) {
            require(
                _whitelist[msg.sender],
                "Whitelist: address is not whitelisted"
            );
        }
        _;
    }

    function _addWhitelist(address[] memory _addresses) internal virtual {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = true;
            addresses.remove(_addresses[i]);
            addresses.add(_addresses[i]);
            emit AddedToWhitelist(_addresses[i]);
        }
    }

    function _removeWhitelist(address[] memory _addresses) internal virtual {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = false;
            addresses.remove(_addresses[i]);
            emit RemovedFromWhitelist(_addresses[i]);
        }
    }

    function _enableWhitelist(bool newValue) internal virtual {
        whitelistStatus = newValue;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function whitelistAddresses() public view returns (address[] memory) {
        return addresses;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./../../libs/SafeArrays.sol";

abstract contract Blacklist {
    bool public blackListStatus;
    using SafeArrays for address[];
    address[] private addresses;
    mapping(address => bool) private _blacklists;
    event AddedToBlackList(address indexed account);
    event RemovedFromBlackList(address indexed account);

    modifier onlyNotExistInBlacklist() {
        if (blackListStatus) {
            require(
                !_blacklists[msg.sender],
                "Blacklist: the account has been banned"
            );
            _;
        }
        _;
    }

    function _addBlacklist(address[] memory _addresses) internal virtual {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _blacklists[_addresses[i]] = true;
            addresses.remove(_addresses[i]);
            addresses.add(_addresses[i]);
            emit AddedToBlackList(_addresses[i]);
        }
    }

    function _removeBlackList(address[] memory _addresses) internal virtual {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _blacklists[_addresses[i]] = false;
            addresses.remove(_addresses[i]);
            emit RemovedFromBlackList(_addresses[i]);
        }
    }

    /* Include blacklist status */
    function _isInBlacklist(address account) internal virtual returns (bool) {
        // Check enable blacklist before
        if (blackListStatus) {
            return _blacklists[account];
        }
        return false;
    }

    function isBlacklisted(address account)
        public
        view
        virtual
        returns (bool)
    {
        return _blacklists[account];
    }

    function blacklistAddresses() public view returns (address[] memory) {
        return addresses;
    }

    function _updateBlacklistStatus(bool status)
        internal
        virtual
        returns (bool)
    {
        blackListStatus = status;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./Permissionable.sol";
import "./extentions/Whitelist.sol";

contract WhitelistPermissionable is Permissionable, Whitelist {
    function addWhitelist(address[] memory _addresses)
        public
        virtual
        onlyManagerOrOwner
        returns (bool)
    {
        _addWhitelist(_addresses);
        return true;
    }

    function removeWhitelist(address[] memory _addresses)
        public
        virtual
        onlyManagerOrOwner
        returns (bool)
    {
        _removeWhitelist(_addresses);
        return true;
    }

    function enableWhitelist(bool newValue) public virtual onlyManagerOrOwner {
        _enableWhitelist(newValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Permissionable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    address[] private managersList;

    event GrantManager(address user_);
    event RevokeManager(address user_);

    function grantManager(address user_) public virtual onlyOwner {
        _managers[user_] = true;
        _addManagerList(user_);
    }

    function revokeManager(address user_) public virtual onlyOwner {
        _managers[user_] = false;
        _removeManagerList(user_);
    }

    function getManagers() public view virtual returns (address[] memory) {
        return managersList;
    }

    function _addManagerList(address user_) internal virtual {
        bool notFound = true;
        for (uint256 i = 0; i < managersList.length; i++) {
            if (managersList[i] == user_) {
                notFound == false;
            }
        }

        if(notFound) {
            managersList.push(user_);
        }
    }

    function _removeManagerList(address user_) internal virtual {
        for (uint256 i = 0; i < managersList.length; i++) {
            if (managersList[i] == user_) {
                delete managersList[i];
            }
        }
    }

    modifier onlyManagerOrOwner() {
        require(
            _managers[_msgSender()] || _msgSender() == owner(),
            "Permission: caller are not the admin or manager"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./Permissionable.sol";
import "./extentions/Blacklist.sol";

contract BlacklistPermissionable is Permissionable, Blacklist {
    function addBacklist(address[] memory _addresses)
        public
        virtual
        onlyManagerOrOwner
        returns (bool)
    {
        _addBlacklist(_addresses);
        return true;
    }

    function removeBacklist(address[] memory _addresses)
        public
        virtual
        onlyManagerOrOwner
        returns (bool)
    {
        _removeBlackList(_addresses);
        return true;
    }

    function enableBlacklist(bool newValue)
        public
        virtual
        onlyManagerOrOwner
        returns (bool)
    {
        return _updateBlacklistStatus(newValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

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
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
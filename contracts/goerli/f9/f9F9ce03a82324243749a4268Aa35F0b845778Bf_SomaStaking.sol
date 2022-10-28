// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/math/SortedList.sol";
import "../utils/math/Percent.sol";
import "../utils/DynamicArray.sol";

import "../SomaGuard/utils/GuardableUpgradeable.sol";
import "../SecurityTokens/ERC20/utils/SafeERC20Balance.sol";
import "../Lockdrop/TokenRecoveryUpgradeable.sol";

import "./SomaStakingLibrary.sol";
import "./ISomaStaking.sol";

/**
 * @notice Implementation of the {ISomaStaking} interface.
 */
contract SomaStaking is ISomaStaking, ReentrancyGuardUpgradeable, TokenRecoveryUpgradeable, GuardableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Balance for IERC20;
    using SafeERC20 for IERC20;
    using SortedList for SortedList.AscendingList;
    using Percent for uint256;
    using SafeCastUpgradeable for uint256;

    /**
     * @inheritdoc ISomaStaking
     */
    bytes32 public constant override GLOBAL_ADMIN_ROLE = keccak256('Staking.GLOBAL_ADMIN_ROLE');

    /**
     * @inheritdoc ISomaStaking
     */
    bytes32 public override LOCAL_ADMIN_ROLE;

    /* Amount of staked tokens globally */
    uint256         private _totalStaked;
    uint256         private _totalPendingUnstake;
    address         private _stakingToken;
    uint256         private _currentRequestId;
    StakingConfig   private _config;

    mapping(address => uint256)         private _tps;
    mapping(address => UserInfo)        private _users;
    mapping(address => uint256)         private _adminClaimable;
    mapping(uint256 => Request)    private _requests;

    SortedList.AscendingList                private _pendingStrategies;
    EnumerableSetUpgradeable.AddressSet     private _rewardTokens;
    Strategy[]                              private _strategies;

    /**
     * @notice Modifier to restrict function calls to accounts that have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    modifier onlyAdmin() {
        address _sender = _msgSender();
        require(hasRole(GLOBAL_ADMIN_ROLE, _sender) || hasRole(LOCAL_ADMIN_ROLE, _sender), 'Staking: ADMIN_ONLY'); // TODO errors should be Staking or SomaStaking
        _;
    }

    /**
     * @notice Checks if SomaStaking inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(GuardableUpgradeable, TokenRecoveryUpgradeable) returns (bool) {
        return interfaceId == type(ISomaStaking).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function config() external override view returns (StakingConfig memory) {
        return _config;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function totalStaked() external override view returns (uint256) {
        return _totalStaked;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function totalPendingUnstake() external override view returns (uint256) {
        return _totalPendingUnstake;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function strategy(uint256 id) external override view returns (Strategy memory) {
        return _strategies[id];
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function totalStrategies() external override view returns (uint256) {
        return _strategies.length;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function stakingToken() external override view returns (address) {
        return _stakingToken;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function rewardToken(uint256 index) external override view returns (address) {
        return _rewardTokens.at(index);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function totalRewardTokens() external override view returns (uint256) {
        return _rewardTokens.length();
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function pendingStrategy(uint256 index) external override view returns (Strategy memory) {
        (bytes32 id,) = _pendingStrategies.at(index);
        return _strategies[uint256(id)];
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function totalPendingStrategies() external override view returns (uint256) {
        return _pendingStrategies.length();
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function tps(address _asset) external override view returns (uint256) {
        return _tps[_asset];
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function adminClaimable(address _asset) external override view returns (uint256) {
        require(_rewardTokens.contains(_asset), 'Staking: INVALID_ASSET');
        // add the extra rewards if there are currently no stakers
        return _adminClaimable[_asset] + (_totalStaked == 0 ? _rewardsUnlocked(_asset) : 0);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function debt(address _account, address _asset) external override view returns (uint256) {
        require(_rewardTokens.contains(_asset), 'Staking: INVALID_ASSET');
        return SomaStakingLibrary.stakeToRewards(_users[_account].stake, currentTPS(_asset));
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function claimable(address _account, address _asset) external override view returns (uint256) {
        UserInfo storage _user = _users[_account];
        require(_rewardTokens.contains(_asset), 'Staking: INVALID_ASSET');
        return _user.claimable[_asset] +
            SomaStakingLibrary.stakeToRewards(_user.stake, currentTPS(_asset)) -
            _user.debt[_asset];
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function claimRequest(address _account, address _asset, uint256 _id) external override view returns (Request memory) {
        require(_rewardTokens.contains(_asset), 'Staking: INVALID_ASSET');
        return _getRequest(_id, _asset, _account);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function stakeOf(address _account) external override view returns (uint256) {
        return _users[_account].stake;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function unstakeRequest(address _account, uint256 _id) external override view returns (Request memory) {
        return _getRequest(_id, _stakingToken, _account);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function initialize(address stakingToken_, address[] memory rewardTokens_) external override initializer {
        LOCAL_ADMIN_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_ADMIN_ROLE));

        require(Address.isContract(stakingToken_), 'SomaStaking: INVALID_STAKING_TOKEN');
        _stakingToken = stakingToken_;

        for (uint256 i = 0; i < rewardTokens_.length; ++i) {
            address _token = rewardTokens_[i];
            require(Address.isContract(_token), 'Staking: INVALID_ASSET');
            _rewardTokens.add(_token);
            _disableTokenRecovery(_token);
        }

        __Guardable__init();
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function currentTPS(address token) public override view returns (uint256 tps_) {
        uint256 totalStaked_ = _totalStaked;
        uint256 extraTPS = (totalStaked_ > 0) ? SomaStakingLibrary.rewardsToTPS(_totalStaked, _rewardsUnlocked(token)) : 0;
        return _tps[token] + extraTPS;
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function createUnstakeRequest(uint256 _amount) external override nonReentrant returns (uint256 _id){
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        uint256 _userStake = _user.stake;
        uint256 totalStake_ = _totalStaked;

        require(_userStake >= _amount, "Staking: INSUFFICIENT_STAKE");
        require(_amount > 0, "Staking: INVALID_AMOUNT");

        _update(totalStake_);
        // remove this amount from the users stake amount, so that they no longer earn rewards on
        _syncUser(_user, _userStake, _userStake - _amount);

        // adjust the total stake balances
        unchecked {
            _totalStaked = totalStake_ - _amount;
            _totalPendingUnstake += _amount;
        }

        return _createRequest(_sender, _stakingToken, _amount);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function cancelUnstakeRequests(uint256[] calldata _ids) external override nonReentrant {
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        uint256 _userStake = _user.stake;
        uint256 totalStake_ = _totalStaked;

        require(_ids.length > 0, 'Staking: INVALID_IDS_LENGTH');
        address stakingToken_ = _stakingToken;
        uint256 _totalAmount = _userStake;
        for (uint i = 0; i < _ids.length; ++i) {
            unchecked {
                _totalAmount += _cancelRequest(_ids[i], stakingToken_, _sender);
            }
        }

        _update(totalStake_);
        _syncUser(_user, _userStake, _userStake + _totalAmount);

        unchecked {
            _totalStaked = totalStake_ + _totalAmount;
            _totalPendingUnstake -= _totalAmount;
        }
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function createClaimRequests(address[] calldata _assets) external override nonReentrant returns (uint256[] memory _ids) {
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        uint256 _userStake = _user.stake;

        _ids = new uint256[](_assets.length);

        _update(_totalStaked);
        _syncUser(_user, _userStake, _userStake);

        for (uint i = 0; i < _assets.length; ++i) {
            address _asset = _assets[i];
            uint256 _rewards = _user.claimable[_asset];

            require(_rewardTokens.contains(_asset), 'Staking: INVALID_ASSET');
            require(_rewards > 0, 'Staking: NO_REWARDS');

            delete _user.claimable[_asset];

            _ids[i] = _createRequest(_sender, _asset, _rewards);
        }
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function cancelClaimRequests(address[] calldata _assets, uint256[][] calldata _ids) external override nonReentrant {
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];

        require(_assets.length > 0, 'Staking: INVALID_ASSETS_LENGTH');
        require(_ids.length == _assets.length, 'Staking: INVALID_INPUT_LENGTHS');

        for (uint i = 0; i < _assets.length; ++i) {
            uint256 _idsLength = _ids[i].length;
            address _asset = _assets[i];
            uint256 _totalAmount;

            require(_idsLength > 0, 'Staking: INVALID_IDS_LENGTH');
            for (uint j = 0; j < _idsLength; ++j) {
                unchecked {
                    _totalAmount += _cancelRequest(_ids[i][j], _asset, _sender);
                }
            }

            unchecked {
                _user.claimable[_asset] += _totalAmount;
            }
        }
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function claim(address[] calldata _assets, uint256[][] calldata _ids) external override nonReentrant {
        address _sender = _msgSender();
        uint256 _claimDuration = _config.claimDuration;

        require(_assets.length == _ids.length, 'Staking: INVALID_INPUT_LENGTHS');

        for (uint i = 0; i < _assets.length; ++i) {
            uint256 _idsLength = _ids[i].length;
            address _asset = _assets[i];
            uint256 _totalAmount;

            require(_idsLength > 0, 'Staking: INVALID_IDS_LENGTH');
            for (uint j = 0; j < _idsLength; ++j) {
                unchecked {
                    _totalAmount += _useRequest(_ids[i][j], _asset, _sender, _claimDuration);
                }
            }

            IERC20(_asset).safeTransfer(_sender, _totalAmount);

            emit Claimed(_asset, _totalAmount, _sender);
        }
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function claimImmediate(address[] calldata _assets, uint256[] calldata _amounts) external override nonReentrant {
        require(_assets.length == _amounts.length, 'Staking: INCONSISTENT_LENGTHS');

        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        StakingConfig memory config_ = _config;

        uint256 _userStake = _user.stake;
        _update(_totalStaked);
        _syncUser(_user, _userStake, _userStake);

        for (uint i = 0; i < _assets.length; ++i) {
            _claimImmediate(
                _user,
                config_.earlyClaimFee,
                _sender,
                _assets[i],
                _amounts[i]
            );
        }
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function stake(uint256 _amount) external override nonReentrant {
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        uint256 _userStake = _user.stake;
        uint256 totalStake_ = _totalStaked;

        // slither-disable-next-line reentrancy-no-eth
        _amount = SafeERC20Balance.safeTransferFrom(
            IERC20(_stakingToken),
            _sender,
            address(this),
            _amount
        );

        require(_amount > 0, "SomaStaking: INVALID_AMOUNT");

        _update(totalStake_);
        _syncUser(_user, _userStake, _userStake + _amount);
        _totalStaked = totalStake_ + _amount;

        emit Staked(_amount, _sender);
    }

    // TODO should this have an input amount?
    /**
     * @inheritdoc ISomaStaking
     */
    function adminClaim(address _asset, address _to) external override onlyAdmin nonReentrant {
        _update(_totalStaked);
        uint256 _claimable = _adminClaimable[_asset];
        require(_claimable > 0, "Staking: INSUFFICIENT_CLAIMABLE");
        delete _adminClaimable[_asset];
        IERC20(_asset).safeTransfer(_to, _claimable);
        emit AdminClaimed(_asset, _claimable, _to, _msgSender());
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function unstake(uint256[] calldata _ids) external override nonReentrant {
        address _sender = _msgSender();
        address stakingToken_ = _stakingToken;
        uint256 _unstakeDuration = _config.unstakeDuration;

        uint256 _totalAmount;
        for (uint i = 0; i < _ids.length; ++i) {
            unchecked {
                _totalAmount += _useRequest(_ids[i], stakingToken_, _sender, _unstakeDuration);
            }
        }

        unchecked {
            _totalPendingUnstake -= _totalAmount;
        }

        IERC20(_stakingToken).safeTransfer(_sender, _totalAmount);

        emit Unstaked(_totalAmount, _sender);
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function unstakeImmediate(uint256 _amount) external override nonReentrant {
        address _sender = _msgSender();
        UserInfo storage _user = _users[_sender];
        uint256 _userStake = _user.stake;
        uint256 totalStake_ = _totalStaked;

        StakingConfig memory config_ = _config;

        require(_userStake >= _amount, "Staking: INSUFFICIENT_STAKE");
        require(_amount > 0, "Staking: INVALID_AMOUNT");

        _update(totalStake_);
        _syncUser(_user, _userStake, _userStake - _amount);

        unchecked {
            _totalStaked = totalStake_ - _amount;
        }
        uint256 _adminFee = _amount.applyPercent(config_.earlyUnstakeFee);

        address _asset = _stakingToken;
        _adminClaimable[_asset] += _adminFee;
        IERC20(_asset).safeTransfer(_sender, _amount - _adminFee);

        emit UnstakedImmediate(_amount, _adminFee, _msgSender());
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function addRewardToken(address _asset) external override onlyAdmin nonReentrant {
        require(_rewardTokens.add(_asset), 'SomaStaking: REWARD_TOKEN_EXISTS');
        emit RewardTokenAdded(_asset, _msgSender());
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function createStrategy(
        uint256 _startDate,
        uint256 _endDate,
        address _rewardToken,
        uint256 _rewardAmount
    ) external override onlyAdmin nonReentrant {
        require(_startDate > block.timestamp, 'SomaStaking: INVALID_START_DATE');
        require(_startDate < _endDate, 'SomaStaking: INVALID_DATE_ORDER');
        require(_rewardTokens.contains(_rewardToken), 'SomaStaking: INVALID_TOKEN');
        require(_endDate <= type(uint48).max, 'SomaStaking: INVALID_END_DATE');

        // slither-disable-next-line reentrancy-no-eth
        _rewardAmount = SafeERC20Balance.safeTransferFrom(
            IERC20(_rewardToken),
            _msgSender(),
            address(this),
            _rewardAmount
        );

        require(_rewardAmount > 0, 'SomaStaking: INVALID_AMOUNT');

        uint256 strategyId = _strategies.length;
        Strategy memory _strategy = Strategy({
            startDate: uint48(_startDate),
            endDate: uint48(_endDate),
            rewardsLocked: _rewardAmount.toUint128(),
            rewardToken: _rewardToken,
            rewardsUnlocked: 0
        });

        _strategies.push(_strategy);

        _pendingStrategies.add(bytes32(strategyId), _startDate);

        emit StrategyCreated(_rewardToken, _strategy.rewardsLocked, _startDate, _endDate, _msgSender());
    }

    /**
     * @inheritdoc ISomaStaking
     */
    function updateConfig(
        uint64 _unstakeDuration,
        uint64 _claimDuration,
        uint16 _earlyUnstakeFee,
        uint16 _earlyClaimFee
    ) external override onlyAdmin {
        StakingConfig memory config_ = StakingConfig({
            unstakeDuration: _unstakeDuration,
            claimDuration: _claimDuration,
            earlyUnstakeFee: _earlyUnstakeFee,
            earlyClaimFee: _earlyClaimFee
        });
        emit StakingConfigUpdated(_config, config_, _msgSender());
        _config = config_;
    }

    function _update(uint256 totalStake_) private {
        uint256 curId = _pendingStrategies.head();
        uint256 nextId;
        bytes32 key;

        // slither-disable-next-line weak-prng
        uint48 curTimestamp = uint48(block.timestamp % type(uint48).max);

        while (curId != 0) {
            (key, nextId) = _pendingStrategies.get(curId);
            Strategy memory _strategy = _strategies[uint256(key)];
            if (curTimestamp < _strategy.startDate) {
                break;
            }

            uint256 rewardsUnlocked = SomaStakingLibrary.rewardsUnlocked(_strategy, block.timestamp);

            // increment how many rewards have been released
            _strategies[uint256(key)].rewardsUnlocked = rewardsUnlocked.toUint128() + _strategy.rewardsUnlocked;
            // if there is nobody staking, lets go ahead and return the rewards earned to the admin
            if (totalStake_ > 0) {
                _tps[_strategy.rewardToken] += SomaStakingLibrary.rewardsToTPS(totalStake_, rewardsUnlocked);
            } else {
                _adminClaimable[_strategy.rewardToken] += rewardsUnlocked;
            }

            // if this strategy has been completed then let us remove it from the pending list
            if (curTimestamp >= _strategy.endDate) {
                _pendingStrategies.remove(curId);
            }

            // progress to the next item in the list
            curId = nextId;
        }
    }

    function _syncUser(UserInfo storage _user, uint256 _userStake, uint256 _newUserStake) private {
        if (_newUserStake != _userStake) _user.stake = _newUserStake;
        if (_userStake == 0) return;

        // sync the claimable and debt values
        uint256 _totalTokens = _rewardTokens.length();
        for (uint i = 0; i < _totalTokens; ++i) {
            address _rewardToken = _rewardTokens.at(i);
            uint256 tps_ = _tps[_rewardToken];
            _user.claimable[_rewardToken] += SomaStakingLibrary.stakeToRewards(_userStake, tps_) - _user.debt[_rewardToken];
            _user.debt[_rewardToken] = SomaStakingLibrary.stakeToRewards(_newUserStake, tps_);
        }
    }

    function _claimImmediate(
        UserInfo storage _user,
        uint256 _earlyClaimFee,
        address _sender,
        address _asset,
        uint256 _amount
    ) private {
        require(_rewardTokens.contains(_asset), "Staking: INVALID_ASSET");

        uint256 _claimable = _user.claimable[_asset];

        require(_amount > 0, 'Staking: INVALID_AMOUNT');
        require(_claimable > 0, "Staking: NO_REWARDS");
        require(_amount <= _claimable, 'Staking: INSUFFICIENT_CLAIMABLE');

        uint256 _adminFee = _amount.applyPercent(_earlyClaimFee);

        _adminClaimable[_asset] += _adminFee;
        IERC20(_asset).safeTransfer(_sender, _amount - _adminFee);

        unchecked {
            _user.claimable[_asset] = _claimable - _amount;
        }

        emit ClaimedImmediate(_asset, _amount, _adminFee, _sender);
    }

    function _rewardsUnlocked(address token) private view returns (uint256 _totalUnlocked) {
        bytes32 key;
        uint256 curId = _pendingStrategies.head();

        while (curId != 0) {
            (key, curId) = _pendingStrategies.get(curId);
            Strategy memory _strategy = _strategies[uint256(key)];
            if (block.timestamp < _strategy.startDate) break;
            if (_strategy.rewardToken == token) _totalUnlocked += SomaStakingLibrary.rewardsUnlocked(_strategy, block.timestamp);
        }
    }

    function _createRequest(address _sender, address _asset, uint256 _amount) private returns (uint256 _id) {
        require(_amount > 0, 'Staking: INVALID_AMOUNT');

        _id = ++_currentRequestId;
        _requests[_id] = Request({
            hash: bytes8(keccak256(abi.encodePacked(_id, _sender, _asset))),
            timestamp: block.timestamp.toUint64(),
            amount: _amount.toUint128()
        });

        emit RequestCreated(_id, _asset, _amount, _sender);
    }

    function _getRequest(uint256 _id, address _asset, address _sender) private view returns (Request memory _request) {
        bytes8 _hash = bytes8(keccak256(abi.encodePacked(_id, _sender, _asset)));
        _request = _requests[_id];
        require(_request.hash == _hash, 'Staking: INVALID_REQUEST');
    }

    function _useRequest(uint256 _id, address _asset, address _sender, uint256 _requiredDuration) private returns (uint256 _amount) {
        Request memory _request = _getRequest(_id, _asset, _sender);

        require(block.timestamp - _request.timestamp >= _requiredDuration, "Staking: INSUFFICIENT_TIME");

        delete _requests[_id];
        emit RequestFulfilled(_id);

        return _request.amount;
    }

    function _cancelRequest(uint256 _id, address _asset, address _sender) private returns (uint256 _amount) {
        _amount = _getRequest(_id, _asset, _sender).amount;
        delete _requests[_id];
        emit RequestCancelled(_id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library SortedList {

    struct ListItemDetails {
        bool exists;
        uint64 id;
        uint64 nextId;
        uint64 prevId;
    }

    struct ListItem {
        ListItemDetails details;
        uint256 value;
    }

    struct ListDetails {
        uint64 head;
        uint64 tail;
        uint64 current;
        uint64 length;
    }

    struct AscendingList {
        ListDetails __details;
        mapping(uint256 => ListItem) __items;
        mapping(uint256 => bytes32) __keys;
    }

    function head(AscendingList storage list) internal view returns (uint256 id) {
        return list.__details.head;
    }

    function tail(AscendingList storage list) internal view returns (uint256 id) {
        return list.__details.tail;
    }

    function get(AscendingList storage list, uint256 id) internal view returns (bytes32 key, uint256 nextId) {
        require(list.__items[id].details.exists, 'SortedList: INVALID_ID');
        key = list.__keys[id];
        nextId = list.__items[id].details.nextId;
    }

    function exists(AscendingList storage list, uint256 id) internal view returns (bool) {
        return list.__items[id].details.exists;
    }

    function length(AscendingList storage list) internal view returns (uint256) {
        return list.__details.length;
    }

    function at(AscendingList storage list, uint256 index) internal view returns (bytes32 key, uint256 curId) {
        ListDetails memory details = list.__details;
        require(index < details.length, 'SortedList: OUT_OF_BOUNDS');

        curId = details.head;
        for (uint i = 0; i < index; ++i) {
            curId = list.__items[curId].details.nextId;
        }
        key = list.__keys[curId];
    }

    function add(AscendingList storage list, bytes32 key, uint256 value) internal {
        ListDetails memory details = list.__details;

        // when it hits the end loop back around to the beginning
        uint64 id;
        unchecked {
            id = details.current + 1;
        }

        ListItemDetails memory itemDetails = list.__items[id].details;

        // we want to override the previous values if they exist
        if (itemDetails.exists) _remove(list, id);

        ListItem memory nextItem;
        ListItem memory prevItem;
        uint64 curId = details.head;
        while (curId != 0) {
            ListItem memory curListItem = list.__items[curId];
            // sort until we find first value that is larger.
            // then this item should go on the right. so it is ascending
            if (curListItem.value > value) {
                nextItem = curListItem;
                break;
            }

            prevItem = curListItem;
            curId = curListItem.details.nextId;
        }

        list.__details = ListDetails({
            length: details.length + 1,
            head: nextItem.details.id == details.head ? id : details.head,
            tail: prevItem.details.id == details.tail ? id : details.tail,
            current: id
        });
        list.__keys[id] = key;
        list.__items[id] = ListItem({
            value: value,
            details: ListItemDetails({
                exists: true,
                id: id,
                prevId: prevItem.details.id,
                nextId: nextItem.details.id
            })
        });

        if (prevItem.details.exists) {
            prevItem.details.nextId = id;
            list.__items[prevItem.details.id].details = prevItem.details;
        }
        if (nextItem.details.exists) {
            nextItem.details.prevId = id;
            list.__items[nextItem.details.id].details = nextItem.details;
        }
    }

    function remove(AscendingList storage list, uint256 id) internal returns (bytes32 key) {
        return _remove(list, id);
    }

    function _remove(AscendingList storage list, uint256 id) private returns (bytes32 key) {
        ListDetails memory listDetails = list.__details;
        ListItemDetails memory itemDetails = list.__items[id].details;

        require(listDetails.length > 0, 'SortedList: LIST_EMPTY');
        require(itemDetails.exists, 'SortedList: INVALID_ID');

        key = list.__keys[id];

        if (listDetails.length == 1) {
            delete list.__details;
        } else {

            if (uint64(id) == listDetails.head)
                listDetails.head = itemDetails.nextId;
            if (uint64(id) == listDetails.tail)
                listDetails.tail = itemDetails.prevId;
            if (itemDetails.prevId != 0)
                list.__items[itemDetails.prevId].details.nextId = itemDetails.nextId;
            if (itemDetails.nextId != 0)
                list.__items[itemDetails.nextId].details.prevId = itemDetails.prevId;

            --listDetails.length;
            list.__details = listDetails;
        }

        // TODO confirm the gas of this -- does this clear all the structs?
        delete list.__items[id];
        delete list.__keys[id];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Percent {

    uint256 internal constant BASE_PERCENT = type(uint16).max;

    function isValidPercent(uint256 nb) internal pure returns (bool) {
        return nb <= BASE_PERCENT;
    }

    function validatePercent(uint256 nb) internal pure {
        require(isValidPercent(nb), 'Percent: INVALID_NUMBER');
    }

    function applyPercent(uint256 nb, uint256 _percent) internal pure returns (uint256) {
        return (nb * _percent) / BASE_PERCENT;
    }

    function inverseApplyPercent(uint256 nb, uint256 _percent) internal pure returns (uint256) {
        return asPercent(nb) / (_percent);
    }

    function percentValueOf(uint256 value, uint256 total) internal pure returns (uint256) {
        return asPercent(value) / total;
    }

    function asPercent(uint256 value) internal pure returns (uint256) {
        return value * BASE_PERCENT;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library DynamicArray {

    struct Bytes32Array {
        uint256 length;
        bytes __data;
    }

    function push(Bytes32Array memory array, bytes32 item) internal pure {
        ++array.length;
        array.__data = abi.encodePacked(array.__data, item);
    }

    function toArray(Bytes32Array memory array) internal pure returns (bytes32[] memory) {
        return abi.decode(abi.encodePacked(array.length, array.__data), (bytes32[]));
    }

    function includes(Bytes32Array memory array, bytes32 item) internal pure returns (bool) {
        return indexOf(array, item) != type(uint256).max;
    }

    function indexOf(Bytes32Array memory array, bytes32 item) internal pure returns (uint256) {
        return _indexOf(array, item);
    }

    // ----------------------------------------------------------------------------------------------

    struct Uint256Array {
        uint256 length;
        bytes __data;
    }

    function push(Uint256Array memory array, uint256 item) internal pure {
        ++array.length;
        array.__data = abi.encodePacked(array.__data, item);
    }

    function toArray(Uint256Array memory array) internal pure returns (uint256[] memory) {
        return abi.decode(abi.encodePacked(array.length, array.__data), (uint256[]));
    }

    function includes(Uint256Array memory array, uint256 item) internal pure returns (bool) {
        return indexOf(array, item) != type(uint256).max;
    }

    function indexOf(Uint256Array memory array, uint256 item) internal pure returns (uint256) {
        return _indexOf(Bytes32Array(array.length, array.__data), bytes32(item));
    }

    // ----------------------------------------------------------------------------------------------

    struct AddressArray {
        uint256 length;
        bytes __data;
    }

    function push(AddressArray memory array, address item) internal pure {
        ++array.length;
        array.__data = abi.encodePacked(array.__data, abi.encode(item));
    }

    function toArray(AddressArray memory array) internal pure returns (address[] memory) {
        return abi.decode(abi.encodePacked(array.length, array.__data), (address[]));
    }

    function includes(AddressArray memory array, address item) internal pure returns (bool) {
        return indexOf(array, item) != type(uint256).max;
    }

    function indexOf(AddressArray memory array, address item) internal pure returns (uint256) {
        return _indexOf(Bytes32Array(array.length, array.__data), bytes32(uint256(uint160(item)) << 96));
    }

    // ----------------------------------------------------------------------------------------------

    function _indexOf(Bytes32Array memory array, bytes32 item) private pure returns (uint256) {
        bytes memory data = array.__data;
        for (uint i = 0; i < array.length; ++i) {
            bytes32 piece;
            uint pos;

            unchecked {
                pos = i * 32;
            }
            assembly {
                piece := mload(add(data, pos))
            }

            if (piece == item) {
                return i;
            }
        }
        return type(uint256).max;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../SomaAccessControl/utils/AccessibleUpgradeable.sol";

import "../ISomaGuard.sol";

import "./GuardHelper.sol";
import "./IGuardable.sol";

abstract contract GuardableUpgradeable is IGuardable, AccessibleUpgradeable {

    function __Guardable__init() internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Guardable__init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
    }

    function __Guardable__init_unchained() internal onlyInitializing {
        LOCAL_UPDATE_PRIVILEGES_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_UPDATE_PRIVILEGES_ROLE));
        _updateRequiredPrivileges(bytes32(type(uint256).max));
    }

    bytes32 public immutable DEFAULT_PRIVILEGES = GuardHelper.DEFAULT_PRIVILEGES;
    bytes32 public constant GLOBAL_UPDATE_PRIVILEGES_ROLE = keccak256('Guardable.GLOBAL_UPDATE_PRIVILEGES_ROLE');

    bytes32 public LOCAL_UPDATE_PRIVILEGES_ROLE;
    bytes32 private _requiredPrivileges;

    modifier onlyApprovedPrivileges(address sender) {
        require(hasPrivileges(sender), 'required privileges not met');
        _;
    }

    function hasPrivileges(address account) public view virtual override returns (bool) {
        return ISomaGuard(SOMA.guard()).check(account, requiredPrivileges());
    }

    function requiredPrivileges() public view virtual override returns (bytes32) {
        return _requiredPrivileges;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IGuardable).interfaceId || super.supportsInterface(interfaceId);
    }

    function updateRequiredPrivileges(bytes32 newRequiredPrivileges) external virtual override returns (bool) {
        require(
            hasRole(LOCAL_UPDATE_PRIVILEGES_ROLE, _msgSender()) || hasRole(GLOBAL_UPDATE_PRIVILEGES_ROLE, _msgSender()),
            'Guardable: you do not have the required roles to do this'
        );
        _updateRequiredPrivileges(newRequiredPrivileges);
        return true;
    }

    function _updateRequiredPrivileges(bytes32 newRequiredPrivileges) internal {
        emit RequiredPrivilegesUpdated(_requiredPrivileges, newRequiredPrivileges, _msgSender());
        _requiredPrivileges = newRequiredPrivileges;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SafeERC20Balance {
    using SafeERC20 for IERC20;

    function safeTransferFrom(
        IERC20 token,
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 prevBalance = token.balanceOf(receiver);
        token.safeTransferFrom(sender, receiver, amount);
        return token.balanceOf(receiver) - prevBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../SomaAccessControl/utils/AccessibleUpgradeable.sol";

import "./ITokenRecoveryUpgradeable.sol";

/**
 * @notice Implementation of the {ITokenRecoveryUpgradeable} interface.
 */
abstract contract TokenRecoveryUpgradeable is ITokenRecoveryUpgradeable, AccessibleUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /**
     * @notice Initializer for the extended contracts.
     */
    function __TokenRecovery__init() internal onlyInitializing {
        __TokenRecovery__init(new address[](0));
    }

    /**
     * @notice Initializer for the extended contracts.
     */
    function __TokenRecovery__init(address[] memory disabledTokens) internal onlyInitializing {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
        __TokenRecovery__init_unchained(disabledTokens);
    }

    /**
     * @notice Unchained initializer.
     */
    function __TokenRecovery__init_unchained(address[] memory disabledTokens) internal onlyInitializing {
        for (uint i; i < disabledTokens.length; ++i) {
            _disabledTokens.add(disabledTokens[i]);
        }
    }

    /**
     * @inheritdoc ITokenRecoveryUpgradeable
     */
    bytes32 public constant override TOKEN_RECOVERY_ROLE = keccak256('TokenRecovery.TOKEN_RECOVERY_ROLE');

    EnumerableSet.AddressSet private _disabledTokens;

    /**
     * @notice Checks if TokenRecoveryUpgradeable inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ITokenRecoveryUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ITokenRecoveryUpgradeable
     */
    function recoverTokens(address token, address to, uint256 amount) external override onlyRole(TOKEN_RECOVERY_ROLE) {
        require(!_disabledTokens.contains(token), 'TokenRecovery: INVALID_TOKEN');
        IERC20(token).safeTransfer(to, amount);
        emit TokensRecovered(token, to, amount, _msgSender());
    }

    function _disableTokenRecovery(address token) internal {
        _disabledTokens.add(token);
    }

    function _enableTokenRecovery(address token) internal {
        _disabledTokens.remove(token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ISomaStaking.sol";

library SomaStakingLibrary {

    uint256 internal constant PRECISION_FACTOR = 10**12;

    function rewardsUnlocked(ISomaStaking.Strategy memory _strategy, uint256 timestamp) internal pure returns (uint256) {
        uint256 locked = (timestamp >= _strategy.endDate)
            ? _strategy.rewardsLocked
            : ((timestamp - _strategy.startDate) * _strategy.rewardsLocked) / (_strategy.endDate - _strategy.startDate);
        return locked - _strategy.rewardsUnlocked;
    }

    function rewardsToTPS(uint256 totalStake, uint256 _rewardsUnlocked) internal pure returns (uint256 tps) {
        return (_rewardsUnlocked * PRECISION_FACTOR) / totalStake;
    }

    function stakeToRewards(uint256 stake, uint256 tps) internal pure returns (uint256) {
        return (stake * tps) / PRECISION_FACTOR;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Staking Contract.
 * @author SOMA.finance.
 * @notice A staking contract that supports multiple reward tokens and strategies.
 */
interface ISomaStaking {

    /************************************ Events ************************************/

    /**
     * @notice Emitted when a user Stakes.
     * @param amount The amount staked, denominated in the staking token.
     * @param sender The address of the message sender.
     */
    event Staked(uint256 amount, address indexed sender);

    /**
     * @notice Emitted when a user Unstakes.
     * @param amount The amount unstaked, denominated in the staking token.
     * @param sender The address of the message sender.
     */
    event Unstaked(uint256 amount, address indexed sender);

    /**
     * @notice Emitted when a user Unstakes immediately.
     * @param amount The amount of the staking token unstaked.
     * @param fee The early unstake fee charged.
     * @param sender The address of the message sender.
     */
    event UnstakedImmediate(uint256 amount, uint256 fee, address indexed sender);

    /**
     * @notice Emitted when a user Claims.
     * @param asset The address of the reward token claimed.
     * @param amount The amount of the reward token claimed.
     * @param sender The address of the message sender.
     */
    event Claimed(address indexed asset, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when a user Claims immediately.
     * @param asset The address of the reward token claimed.
     * @param amount The amount of the reward token claimed.
     * @param fee The early claim fee.
     * @param sender The address of the message sender.
     */
    event ClaimedImmediate(address indexed asset, uint256 amount, uint256 fee, address indexed sender);

    /**
     * @notice Emitted when a Strategy is created.
     * @param rewardToken The address of the reward token.
     * @param amount The amount of the reward tokens.
     * @param startDate The timestamp marking the start of the strategy.
     * @param endDate The timestamp marking the end of the strategy.
     * @param sender The address of the message sender.
     */
    event StrategyCreated(address indexed rewardToken,  uint256 amount, uint256 startDate, uint256 endDate, address indexed sender);

    /**
     * @notice Emitted when a Admin claims.
     * @param asset The address of the asset claimed.
     * @param amount The amount of the asset claimed.
     * @param to The address that the claimed tokens is sent to.
     * @param sender The address of the message sender.
     */
    event AdminClaimed(address indexed asset, uint256 amount, address indexed to, address indexed sender);

    /**
     * @notice Emitted when the Staking Config is updated.
     * @param prevConfig The previous staking configuration.
     * @param newConfig The new staking configuration.
     * @param sender The address of the message sender.
     */
    event StakingConfigUpdated(StakingConfig prevConfig, StakingConfig newConfig, address indexed sender);

    /**
     * @notice Emitted when an Unstake or Claim Request is created.
     * @param id The ID of the request.
     * @param asset The asset of the request.
     * @param amount The amount of the requested asset.
     * @param sender The address of the message sender.
     */
    event RequestCreated(uint256 indexed id, address indexed asset, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when an Unstake or Claim Request is cancelled.
     * @param id The ID of the request.
     */
    event RequestCancelled(uint256 indexed id);

    /**
     * @notice Emitted when an Unstake or Claim Request is fulfilled.
     * @param id The ID of the request.
     */
    event RequestFulfilled(uint256 indexed id);

    /**
     * @notice Emitted when a Reward Token is added.
     * @param token The address of the reward token.
     * @param sender The address of the message sender.
     */
    event RewardTokenAdded(address indexed token, address indexed sender);

    /************************************ Structs ************************************/

    /**
     * @notice Staking Configuration structure. Defines the fees and unstake duration.
     * @param unstakeDuration The amount of seconds that must pass before an unstake request is fulfilled.
     * @param claimDuration The amount of seconds that must pass before a claim request is fulfilled.
     * @param earlyUnstakeFee The fee charged for early unstakes.
     * @param earlyClaimFee The fee charged for early claims.
     */
    struct StakingConfig {
        uint64 unstakeDuration;
        uint64 claimDuration;

        uint16 earlyUnstakeFee;
        uint16 earlyClaimFee;
    }

    /**
     * @notice Request Configuration structure.
     * @param hash The ID of the request.
     * @param timestamp The timestamp that the request was created at.
     * @param amount The amount of the reward token requested.
     */
    struct Request {
        bytes8 hash;
        uint64 timestamp;
        uint128 amount;
    }

    /**
     * @notice User Information structure.
     * @param stake The amount of tokens the user has staked.
     * @param claimable The mapping of reward token to the claimable rewards amount for the user.
     * @param debt The mapping of reward token to rewards amount for the user.
     */
    struct UserInfo {
        uint256 stake; // How many tokens the user has staked
        mapping(address => uint256) claimable;
        mapping(address => uint256) debt;
    }

    /**
     * @notice Strategy structure. Defines the rewards that are released over a particular amount of time for
     * an asset.
     * @param startDate The timestamp marking the start of the strategy.
     * @param endDate The timestamp marking the end of the strategy.
     * @param rewardToken The address of the reward token.
     * @param rewardsLocked The amount of locked reward tokens.
     * @param rewardsUnlocked The amount of unlocked reward tokens.
     */
    struct Strategy {
        uint48 startDate;
        uint48 endDate;
        address rewardToken;
        uint128 rewardsLocked;
        uint128 rewardsUnlocked;
    }

    /**
     * @notice Returns the Staking Global Admin Role.
     * @dev Equivalent to keccak256('Staking.GLOBAL_ADMIN_ROLE').
     */
    function GLOBAL_ADMIN_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the Staking Local Admin Role.
     */
    function LOCAL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the Staking Configuration.
     */
    function config() external view returns (StakingConfig memory);

    /**
     * @notice Returns the strategy, given a strategy ID.
     * @param id The ID of the strategy.
     * @return The strategy with the matching ID.
     */
    function strategy(uint256 id) external view returns (Strategy memory);

    /**
     * @notice Returns the pending strategy, given a strategy ID.
     * @param id The ID of the pending strategy.
     * @return The pending strategy with the matching ID.
     */
    function pendingStrategy(uint256 id) external view returns (Strategy memory);

    /**
     * @notice Returns the total number of strategies created.
     */
    function totalStrategies() external view returns (uint256);

    /**
     * @notice Returns the total number of pending strategies.
     */
    function totalPendingStrategies() external view returns (uint256);

    /**
     * @notice Returns the total number of staked tokens.
     */
    function totalStaked() external view returns (uint256);

    /**
     * @notice Returns the total number of staking tokens pending unstake.
     */
    function totalPendingUnstake() external view returns (uint256);

    /**
     * @notice Returns the last recorded tokens per share, given a token.
     * @param token The token to return the tokens per share of.
     * @param tps_ The tokens per share of `token`.
     */
    function tps(address token) external view returns (uint256 tps_);

    /**
     * @notice Returns the current tokens per share, given a token.
     * @param token The token to return the current tokens per share of.
     * @param tps_ The current tokens per share of `token`.
     */
    function currentTPS(address token) external view returns (uint256 tps_);

    /**
     * @notice Returns the number of reward tokens.
     */
    function totalRewardTokens() external view returns (uint256);

    /**
     * @notice Returns the address of a reward token, given an index.
     * @param index The index of the reward token.
     */
    function rewardToken(uint256 index) external view returns (address);

    /**
     * @notice Returns the address of the staking token.
     */
    function stakingToken() external view returns (address);

    /**
     * @notice Returns the staked balance of an account.
     * @param account The account to return the staked balance of.
     * @return The staked balance of the account, denominated in the staking token.
     */
    function stakeOf(address account) external view returns (uint256);

    /**
     * @notice Returns an Unstake Request, given an account and Request ID.
     * @param account The account to return the Request of.
     * @param id The ID of the request.
     * @return The Request with the matching ID.
     */
    function unstakeRequest(address account, uint256 id) external view returns (Request memory);

    /**
     * @notice Returns the debt of an account, given an asset.
     * @param account The account to return the debt of.
     * @param asset The asset to return the account's debt of.
     * @return The debt of the account, denominated in the asset.
     */
    function debt(address account, address asset) external view returns (uint256);

    /**
     * @notice Returns the amount of claimable tokens of an account, given an asset.
     * @param account The account to return the claimable tokens of.
     * @param asset The asset to return the claimable amount of.
     * @return The number of claimable tokens.
     */
    function claimable(address account, address asset) external view returns (uint256);

    /**
     * @notice Returns the Claim Request of an account, given an asset and Request ID.
     * @param account The account to return the Claim Request of.
     * @param asset The asset to return the Claim Request of.
     * @param id The ID of the Claim Request.
     * @return The Claim Request.
     */
    function claimRequest(address account, address asset, uint256 id) external view returns (Request memory);

    /**
     * @notice Initializer for the Staking Contract.
     * @param stakingToken The address of the staking token.
     * @param rewardTokens An array of addresses of the reward tokens.
     * @custom:emits Initialized
     * @custom:requirement `stakingToken` must be a contract.
     * @custom:requirement Each token in `rewardTokens` must be a contract.
     */
    function initialize(address stakingToken, address[] memory rewardTokens) external;

    /**
     * @notice Stakes an amount of staking tokens.
     * @param amount The amount of tokens to stake.
     * @custom:emits Staked
     * @custom:requirement `amount` must be greater than zero.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Creates an Unstake Request. This is required before performing an unstake. Creating an
     * unstake request will stop users from earning rewards on the amount that they are unstaking for.
     * @param amount The amount of tokens requested to unstake.
     * @custom:emits RequestCreated
     * @custom:requirement The stake of the message sender must be greater than or equal to `amount`.
     * @custom:requirement `amount` must be greater than zero.
     * @return id The ID of the created Unstake Request.
     */
    function createUnstakeRequest(uint256 amount) external returns (uint256 id);

    /**
     * @notice Cancels multiple Unstake Requests. Cancelling an unstake will return the staking tokens to
     * the contract allowing the user to earn rewards on these tokens again.
     * @param ids An array of Request IDs to cancel the unstake requests for.
     * @custom:emits RequestCancelled
     * @custom:requirement The length of `ids` must be greater than zero.
     */
    function cancelUnstakeRequests(uint256[] calldata ids) external;

    /**
     * @notice Unstakes the input requests, given that the required unstake duration has passed. This unstake has no fees
     * associated with the transaction.
     * @param ids An array of Request IDs.
     * @custom:emits Unstaked
     * @custom:emits RequestFulfilled
     * @custom:requirement The difference between the timestamp of the function call and the timestamp of the request creation
     * must be greater than or equal to the Unstake required duration.
     */
    function unstake(uint256[] calldata ids) external;

    /**
     * @notice Unstakes tokens immediately. This incurs a fee to bypass the unstake duration required to unstake.
     * @param amount The number of staking tokens to unstake immediately.
     * @custom:emits UnstakedImmediate
     * @custom:requirement The staked balance of the message caller must be greater than or equal to `amount`.
     * @custom:requirement `amount` must be greater than or equal to zero.
     */
    function unstakeImmediate(uint256 amount) external;

    /**
     * @notice Creates Claim Requests for multiple rewards tokens. This is required before performing a claim.
     * @param assets The array of rewards tokens to create Claim Requests for.
     * @custom:emits RequestCreated
     * @custom:requirement Each asset in `assets` must be a valid reward token.
     * @custom:requirement The claimable amount for the message sender, for each asset in `assets` must be greater than zero.
     * @return ids The array of created Claim Requests IDs.
     */
    function createClaimRequests(address[] calldata assets) external returns (uint256[] memory ids);

    /**
     * @notice Cancels multiple Claim Requests.
     * @param asset The array of rewards tokens to cancel Claim Requests for.
     * @param ids The 2D array of Request IDs to cancel requests of.
     * @custom:emits RequestCancelled
     * @custom:requirement The length of `asset` must be greater than zero.
     * @custom:requirement The length of `ids` must be equal to the length of `asset`.
     */
    function cancelClaimRequests(address[] calldata asset, uint256[][] calldata ids) external;

    /**
     * @notice Claims an amount of reward tokens, provided that each request is ready to be claimed.
     * @param assets The array of rewards tokens to fulfill Claim Requests for.
     * @param ids The 2D array of Request IDs to fulfill requests of.
     * @custom:emits Claimed
     * @custom:emits RequestFulfilled
     * @custom:requirement The length of `ids` must be equal to the length of `asset`.
     */
    function claim(address[] calldata assets, uint256[][] calldata ids) external;

    /**
     * @notice Claims an amount of reward tokens immediately, bypassing the claim duration in exchange for a fee.
     * @param assets The array of rewards tokens to claim immediately.
     * @param amounts The array of amounts for each reward token to claim immediately.
     * @custom:emits ClaimedImmediate
     * @custom:requirement The length of `assets` must be equal to the length of `amounts`.
     * @custom:requirement Each asset in `assets` must be a valid reward token.
     */
    function claimImmediate(address[] calldata assets, uint256[] calldata amounts) external;

    // ********************************** ADMIN **********************************

    /**
     * @notice Returns the amount of admin claimable tokens originating from fees.
     * @param asset The asset to return the admin claimable balance of.
     * @custom:requirement `asset` must be a valid reward token.
     * @return The amount of admin claimable tokens, denominated in `asset`.
     */
    function adminClaimable(address asset) external view returns (uint256);

    /**
     * @notice Adds a reward token to contract. Once a reward token has been added, it cannot be removed.
     * @param asset The asset to add as a reward token.
     * @custom:emits RewardTokenAdded
     * @custom:requirement `asset` must not be an existing reward token.
     * @custom:requirement The message sender must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function addRewardToken(address asset) external;

    /**
     * @notice Claims the admin claimable amount for a reward token.
     * @param asset The reward token to claim as an admin.
     * @param to The address to send the claimed tokens to.
     * @custom:emits AdminClaimed
     * @custom:requirement `asset` must not be an existing reward token.
     * @custom:requirement The claimable amount of `asset` must be greater than zero.
     * @custom:requirement The message sender must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function adminClaim(address asset, address to) external;

    /**
     * @notice Creates a Strategy.
     * @param startDate The timestamp marking the start of the strategy.
     * @param endDate The timestamp marking the end of the strategy.
     * @param rewardToken The address of the reward token.
     * @param rewardAmount The amount of the reward token.
     * @custom:emits StrategyCreated
     * @custom:requirement `startDate` must be greater than the timestamp of the function call.
     * @custom:requirement `startDate` must be less than `endDate`.
     * @custom:requirement `rewardToken` must be a valid existing reward token.
     * @custom:requirement `endDate` must be a valid uint48.
     * @custom:requirement The message sender must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function createStrategy(
        uint256 startDate,
        uint256 endDate,
        address rewardToken,
        uint256 rewardAmount
    ) external;

    /**
     * @notice Updates the Staking Configuration.
     * @param unstakeDuration The new unstake duration.
     * @param claimDuration The new claim duration.
     * @param earlyUnstakeFee The new early unstake fee.
     * @param earlyClaimFee The new early claim fee.
     * @custom:emits StakingConfigUpdated
     * @custom:requirement The message sender must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function updateConfig(
        uint64 unstakeDuration,
        uint64 claimDuration,
        uint16 earlyUnstakeFee,
        uint16 earlyClaimFee
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../../utils/security/IPausable.sol";
import "../../utils/SomaContractUpgradeable.sol";

import "../ISomaAccessControl.sol";
import "./IAccessible.sol";

abstract contract AccessibleUpgradeable is IAccessible, SomaContractUpgradeable {

    function __Accessible_init() internal onlyInitializing {
        __SomaContract_init_unchained();
    }

    function __Accessible_init_unchained() internal onlyInitializing {
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "SomaAccessControl: caller does not have the appropriate authority");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessible).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // slither-disable-next-line external-function
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return IAccessControlUpgradeable(SOMA.access()).getRoleAdmin(role);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return IAccessControlUpgradeable(SOMA.access()).hasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title SOMA Guard Contract.
 * @author SOMA.finance
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 * @notice A contract to batch update account privileges.
 */
interface ISomaGuard {

    /**
     * @notice Emitted when privileges for a 2D array of accounts are updated.
     * @param accounts The 2D array of addresses.
     * @param privileges The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdate(
        address[][] accounts,
        bytes32[] privileges,
        address indexed sender
    );

    /**
     * @notice Emitted when privileges for an array of accounts are updated.
     * @param accounts The array of addresses.
     * @param access The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdateSingle(
        address[] accounts,
        bytes32[] access,
        address indexed sender
    );

    /**
     * @notice Returns the default privileges of the SomaGuard contract.
     * @dev Returns bytes32(uint256(2 ** 64 - 1)).
     */
    function DEFAULT_PRIVILEGES() external view returns (bytes32);

    /**
     * @notice Returns the operator role of the SomaGuard contract.
     * @dev Returns bytes32(uint256(3)).
     */
    function OPERATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the privilege of an account.
     * @param account The account to return the privilege of.
     */
    function privileges(address account) external view returns (bytes32);

    /**
     * @notice Returns True if an account passes a query, where query is the desired privileges.
     * @param account The account to check the privileges of.
     * @param query The desired privileges to check for.
     */
    function check(address account, bytes32 query) external view returns (bool);

    /**
     * @notice Returns the privileges for each account.
     * @param accounts The array of accounts return the privileges of.
     * @return access_ The array of privileges.
     */
    function batchFetch(address[] calldata accounts) external view returns (bytes32[] memory access_);

    /**
     * @notice Updates the privileges of an array of accounts.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param access_ The array of privileges to update the array of accounts with.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[] calldata accounts_, bytes32[] calldata access_) external returns (bool);

    /**
     * @notice Updates the privileges of a 2D array of accounts, where the child array of accounts are all assigned to the
     * same privileges.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param access_ The array of privileges to update the 2D array of accounts with.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[][] calldata accounts_, bytes32[] calldata access_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IGuardable.sol";

library GuardHelper {

    // 00000000(192 0's repeated)111(64times)
    // (64 default on, 192 default off)
    bytes32 internal constant DEFAULT_PRIVILEGES = bytes32(uint256(2 ** 64 - 1));

    function requiredPrivileges(address account) internal view returns (bytes32 privileges) {
        try IGuardable(account).requiredPrivileges() returns (bytes32 requiredPrivileges_) {
            privileges = requiredPrivileges_;
        } catch(bytes memory) {
            privileges = DEFAULT_PRIVILEGES;
        }
    }

    function check(bytes32 privileges, bytes32 query) internal pure returns (bool) {
        return privileges & query == query;
    }

    function mergePrivileges(bytes32 privileges1, bytes32 privileges2) internal pure returns (bytes32) {
        return privileges1 | privileges2;
    }

    function mergePrivileges(bytes32 privileges1, bytes32 privileges2, bytes32 privileges3) internal pure returns (bytes32) {
        return privileges1 | privileges2 | privileges3;
    }

    function switchOn(uint256[] memory ids, bytes32 base) internal pure returns (bytes32 result) {
        result = base;
        for (uint i; i < ids.length; ++i) {
            result = result | bytes32(2**ids[i]);
        }
    }

    function switchOff(uint256[] memory ids, bytes32 base) internal pure returns (bytes32 result) {
        result = base;
        for (uint i; i < ids.length; ++i) {
            result = result & bytes32(type(uint256).max - 2**ids[i]);
        }
        result = result | DEFAULT_PRIVILEGES;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IGuardable {
    event RequiredPrivilegesUpdated(bytes32 prevPrivileges, bytes32 newPrivileges, address indexed sender);

    // Privileges Control
    function hasPrivileges(address account) external view returns (bool);
    function requiredPrivileges() external view returns (bytes32);
    function updateRequiredPrivileges(bytes32) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPausable {

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "../ISOMA.sol";
import "../SOMAlib.sol";

import "./ISomaContract.sol";

contract SomaContractUpgradeable is ISomaContract, PausableUpgradeable, ERC165Upgradeable, MulticallUpgradeable {
    function __SomaContract_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __SomaContract_init_unchained();
    }

    function __SomaContract_init_unchained() internal onlyInitializing {}

    ISOMA public immutable override SOMA = SOMAlib.SOMA;

    modifier onlyMasterOrSubMaster {
        address sender = _msgSender();
        require(SOMA.master() == sender || SOMA.subMaster() == sender, 'SOMA: MASTER or SUB MASTER only');
        _;
    }

    function pause() external virtual override onlyMasterOrSubMaster {
        _pause();
    }

    function unpause() external virtual override onlyMasterOrSubMaster {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISomaContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function paused() public view virtual override returns (bool) {
        return PausableUpgradeable(address(SOMA)).paused() || super.paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Access Control Contract.
 * @author SOMA.finance.
 * @notice An access control contract that establishes a hierarchy of accounts and controls
 * function call permissions.
 */
interface ISomaAccessControl {

    /**
     * @notice Sets the admin of a role.
     * @dev Sets the admin for the `role` role.
     * @param role The role to set the admin role of.
     * @param adminRole The admin of `role`.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAccessible {

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SomaAccessControl/ISomaAccessControl.sol";
import "./SomaSwap/periphery/ISomaSwapRouter.sol";
import "./SomaSwap/core/interfaces/ISomaSwapFactory.sol";
import "./SomaGuard/ISomaGuard.sol";
import "./TemplateFactory/ITemplateFactory.sol";
import "./Lockdrop/ILockdropFactory.sol";

/**
 * @title SOMA Contract.
 * @author SOMA.finance
 * @notice Interface of the SOMA contract.
 */
interface ISOMA {

    /**
     * @notice Emitted when the SOMA snapshot is updated.
     * @param version The version of the new snapshot.
     * @param hash The hash of the new snapshot.
     * @param snapshot The new snapshot.
     */
    event SOMAUpgraded(bytes32 indexed version, bytes32 indexed hash, bytes snapshot);

    /**
     * @notice Emitted when the `seizeTo` address is updated.
     * @param prevSeizeTo The address of the previous `seizeTo`.
     * @param newSeizeTo The address of the new `seizeTo`.
     * @param sender The address of the message sender.
     */
    event SeizeToUpdated(
        address indexed prevSeizeTo,
        address indexed newSeizeTo,
        address indexed sender
    );

    /**
     * @notice Emitted when the `mintTo` address is updated.
     * @param prevMintTo The address of the previous `mintTo`.
     * @param newMintTo The address of the new `mintTo`.
     * @param sender The address of the message sender.
     */
    event MintToUpdated(
        address indexed prevMintTo,
        address indexed newMintTo,
        address indexed sender
    );

    /**
     * @notice Snapshot of the SOMA contracts.
     * @param master The master address.
     * @param subMaster The subMaster address.
     * @param access The ISomaAccessControl contract.
     * @param guard The ISomaGuard contract.
     * @param factory The ITemplateFactory contract.
     * @param token The IERC20 contract.
     */
    struct Snapshot {
        address master;
        address subMaster;
        address access;
        address guard;
        address factory;
        address token;
    }

    /**
     * @notice Returns the address that has been assigned the master role.
     */
    function master() external view returns (address);

    /**
     * @notice Returns the address that has been assigned the subMaster role.
     */
    function subMaster() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaAccessControl} contract.
     */
    function access() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaGuard} contract.
     */
    function guard() external view returns (address);

    /**
     * @notice Returns the address of the {ITemplateFactory} contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the {IERC20} contract.
     */
    function token() external view returns (address);

    /**
     * @notice Returns the hash of the latest snapshot.
     */
    function snapshotHash() external view returns (bytes32);

    /**
     * @notice Returns the latest snapshot version.
     */
    function snapshotVersion() external view returns (bytes32);

    /**
     * @notice Returns the snapshot, given a snapshot hash.
     * @param hash The snapshot hash.
     * @return _snapshot The snapshot matching the `hash`.
     */
    function snapshots(bytes32 hash) external view returns (bytes memory _snapshot);

    /**
     * @notice Returns the hash when given a version, returns a version when given a hash.
     * @param versionOrHash The version or hash.
     * @return hashOrVersion The hash or version based on the input.
     */
    function versions(bytes32 versionOrHash) external view returns (bytes32 hashOrVersion);

    /**
     * @notice Returns the address that receives all minted tokens.
     */
    function mintTo() external view returns (address);

    /**
     * @notice Returns the address that receives all seized tokens.
     */
    function seizeTo() external view returns (address);

    /**
     * @notice Updates the current SOMA snapshot and is called after the proxy has been upgraded.
     * @param version The version to upgrade to.
     * @custom:emits SOMAUpgraded
     * @custom:requirement The incoming snapshot hash cannot be equal to the contract's existing snapshot hash.
     */
    function __upgrade(bytes32 version) external;

    /**
     * @notice Triggers the SOMA paused state. Pauses all the SOMA contracts.
     * @custom:emits Paused
     * @custom:requirement SOMA must be already unpaused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function pause() external;

    /**
     * @notice Triggers the SOMA unpaused state. Unpauses all the SOMA contracts.
     * @custom:emits Unpaused
     * @custom:requirement SOMA must be already paused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function unpause() external;

    /**
     * @notice Sets the `mintTo` address to `_mintTo`.
     * @param _mintTo The address to be set as the `mintTo` address.
     * @custom:emits MintToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setMintTo(address _mintTo) external;

    /**
     * @notice Sets the `seizeTo` address to `_seizeTo`.
     * @param _seizeTo The address to be set as the `seizeTo` address.
     * @custom:emits SeizeToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setSeizeTo(address _seizeTo) external;

    /**
     * @notice Returns the current snapshot of the SOMA contracts.
     */
    function snapshot() external view returns (Snapshot memory _snapshot);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ISOMA.sol";

library SOMAlib {

    /**
     * @notice The fixed address where the SOMA contract will be located (this is a proxy).
     */
    ISOMA public constant SOMA = ISOMA(0xE0eB96278a19a9440bC80476298D77D09A532DB9);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../ISOMA.sol";

interface ISomaContract {

    function pause() external;
    function unpause() external;

    function SOMA() external view returns (ISOMA);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @title SOMA Swap Router Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapRouter} contract.
 */
interface ISomaSwapRouter {

    /**
     * @notice Returns the address of the factory contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the WETH token.
     */
    function WETH() external view returns (address);

    /**
     * @notice Adds liquidity to the pool.
     * @param tokenA The token0 of the pair to add liquidity to.
     * @param tokenB The token1 of the pair to add liquidity to.
     * @param amountADesired The amount of token0 to add as liquidity.
     * @param amountBDesired The amount of token1 to add as liquidity.
     * @param amountAMin The bound of the tokenB / tokenA price can go up
     * before transaction reverts.
     * @param amountBMin The bound of the tokenA / tokenB price can go up
     * before transaction reverts.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountA The amount of tokenA added as liquidity.
     * @return amountB The amount of tokenB added as liquidity.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    /**
     * @notice Adds liquidity to the pool with ETH.
     * @param token The pool token.
     * @param amountTokenDesired The amount of token to add as liquidity if WETH/token price
     * is less or equal to the value of msg.value/amountTokenDesired (token depreciates).
     * @param amountTokenMin The bound that WETH/token price can go up before the transactions
     * reverts.
     * @param amountETHMin The bound that token/WETH price can go up before the transaction reverts.
     * @param to The recipient of the liquidity tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountToken The amount of token sent to the pool.
     * @return amountETH The amount of ETH converted to WETH and sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    /**
     * @notice Removes liquidity from the pool.
     * @param tokenA The pool token.
     * @param tokenB The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of tokenA that must be received
     * for the transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received
     * for the transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of tokens that must be received
     * for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountToken The amount of token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    /**
     * @notice Removes liquidity from the pool without pre-approval.
     * @param tokenA The pool token0.
     * @param tokenB The pool token1.
     * @param liquidity The amount of liquidity to remove.
     * @param amountAMin The minimum amount of tokenA that must be received for the
     * transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH without pre-approval.
     * @param token The pool token.
     * @param liquidity The amount of liquidity to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction
     * not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not
     * to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @return amountToken The amount fo token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along
     * with the route determined by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction
     * not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value at the last index of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of output tokens for as few input input tokens as possible, along
     * with the route determined by the path.
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value of the first index of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible, along with the route
     * determined by the path.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amount0Min`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of ETH for as few input tokens as possible, along with the route
     * determined by the path.
     * @param amountOut The amount of ETH to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    /**
     * @notice Swaps an exact amount of tokens for as much ETH as possible, along with the route determined
     * by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or
     * equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of tokens for as little ETH as possible, along with the route determined
     * by the path.
     * @param amountOut The amount of tokens to receive.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountIn()`) must be less than or equal
     * to the `msg.value`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /**
     * @notice Given some asset amount and reserves, returns the amount of the other asset representing equivalent value.
     * @param amountA The amount of token0.
     * @param reserveA The reserves of token0.
     * @param reserveB The reserves of token1.
     * @custom:requirement `amountA` must be greater than zero.
     * @custom:requirement `reserveA` must be greater than zero.
     * @custom:requirement `reserveB` must be greater than zero.
     * @return amountB The amount of token1.
     */
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    /**
     * @notice Given some asset amount and reserves, returns the maximum output amount of the other asset (accounting for fees).
     * @param amountIn The amount of the input token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountIn` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountOut The amount of the output token.
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees).
     * @param amountOut The amount of the output token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountOut` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountIn The required input amount of the input asset.
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts
     * calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountOut()`.
     * @param amountIn The amount of the input token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The maximum output amounts.
     */
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    /**
     * @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts
     * by calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountIn()`.
     * @param amountOut The amount of the output token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The required input amounts.
     */
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETHWithPermit} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    /**
     * @notice See {ISomaSwapRouter-swapExactETHForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The increase in balance of the last element of `path` for the `to` address must be greater than
     * or equal to `amountOutMin`.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The WETH balance of the router must be greater than or equal to `amountOutMin`.
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Swap Factory Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapFactory} contract.
 */
interface ISomaSwapFactory {

    /**
     * @notice Emitted when a pair is created via `createPair()`.
     * @param token0 The address of token0.
     * @param token1 The address of token1.
     * @param pair The address of the created pair.
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    /**
     * @notice Emitted when the `feeTo` address is updated from `prevFeeTo` to `newFeeTo` by `sender`.
     * @param prevFeeTo The address of the previous fee to.
     * @param prevFeeTo The address of the new fee to.
     * @param sender The address of the message sender.
     */
    event FeeToUpdated(address indexed prevFeeTo, address indexed newFeeTo, address indexed sender);

    /**
     * @notice Emitted when a router is added by `sender`.
     * @param router The address of the router added.
     * @param sender The address of the message sender.
     */
    event RouterAdded(address indexed router, address indexed sender);

    /**
     * @notice Emitted when a router is removed by `sender`.
     * @param router The address of the router removed.
     * @param sender The address of the message sender.
     */
    event RouterRemoved(address indexed router, address indexed sender);

    /**
     * @notice Returns SOMA Swap Factory Create Pair Role.
     * @dev Returns `keccak256('SomaSwapFactory.CREATE_PAIR_ROLE')`.
     */
    function CREATE_PAIR_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Fee Setter Role.
     * @dev Returns `keccak256('SomaSwapFactory.FEE_SETTER_ROLE')`.
     */
    function FEE_SETTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Manage Router Role.
     * @dev Returns `keccak256('SomaSwapFactory.MANAGE_ROUTER_ROLE')`.
     */
    function MANAGE_ROUTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the address where fees from the exchange get transferred to.
     */
    function feeTo() external view returns (address);

    /**
     * @notice Returns the address of the pair contract for tokenA and tokenB if it exists, else returns address(0).
     * @dev Returns the address of the pair for `tokenA` and `tokenB` if it exists, else returns `address(0)`.
     * @param tokenA The token0 of the pair.
     * @param tokenB The token1 of the pair.
     * @return pair The address of the pair.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Returns the nth pair created through the factory, or address(0).
     * @dev Returns the `n-th` pair (0 indexed) created through the factory, or `address(0)`.
     * @return pair The address of the pair.
     */
    function allPairs(uint) external view returns (address pair);

    /**
     * @notice Returns the total number of pairs created through the factory so far.
     */
    function allPairsLength() external view returns (uint);

    /**
     * @notice Returns True if an address is an existing router, else returns False.
     * @param target The address to return true if it an existing router, or false if it is not.
     * @return Boolean value indicating if the address is an existing router.
     */
    function isRouter(address target) external view returns (bool);

    /**
     * @notice Adds an address as a new router. A router is able to tell a pair who is swapping.
     * @param target The address to add as a new router.
     * @custom:emits RouterAdded
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function addRouter(address target) external;

    /**
     * @notice Removes an address from the list of routers. A router is able to tell a pair who is swapping.
     * @param target The address to remove from the list of routers.
     * @custom:emits RouterRemoved
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function removeRouter(address target) external;

    /**
     * @notice Creates a new pair.
     * @dev Creates a pair for `tokenA` and `tokenB` if one does not exist already.
     * @param tokenA The address of token0 of the pair.
     * @param tokenB The address of token1 of the pair.
     * @custom:emits PairCreated
     * @custom:requirement The function caller must have the CREATE_PAIR_ROLE.
     * @custom:requirement `tokenA` must not be equal to `tokenB`.
     * @custom:requirement `tokenA` must not be equal to `address(0)`.
     * @custom:requirement `tokenA` and `tokenB` must not be an existing pair.
     * @custom:requirement The system must not be paused.
     * @return pair The address of the pair created.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Sets a new `feeTo` address.
     * @custom:emits FeeToUpdated
     * @custom:requirement The function caller must have the FEE_SETTER_ROLE.
     * @custom:requirement The system must not be paused.
     */
    function setFeeTo(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title SOMA Template Factory Contract.
 * @author SOMA.finance.
 * @notice Interface of the {TemplateFactory} contract.
 */
interface ITemplateFactory {

    /**
     * @notice Emitted when a template version is created.
     * @param templateId The ID of the template added.
     * @param version The version of the template.
     * @param implementation The address of the implementation of the template.
     * @param sender The address of the message sender.
     */
    event TemplateVersionCreated(bytes32 indexed templateId, uint256 indexed version, address implementation, address indexed sender);

    /**
     * @notice Emitted when a deploy role is updated.
     * @param templateId The ID of the template with the updated deploy role.
     * @param prevRole The previous role.
     * @param newRole The new role.
     * @param sender The address of the message sender.
     */
    event DeployRoleUpdated(bytes32 indexed templateId, bytes32 prevRole, bytes32 newRole, address indexed sender);

    /**
     * @notice Emitted when a template is enabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateEnabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template is disabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateDisabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template version is deprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template deprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionDeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template version is undeprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template undeprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionUndeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template is deployed.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateDeployed(address indexed instance, bytes32 indexed templateId, uint256 version, bytes args, bytes[] functionCalls, address indexed sender);

    /**
     * @notice Emitted when a template is cloned.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateCloned(address indexed instance, bytes32 indexed templateId, uint256 version, bytes[] functionCalls, address indexed sender);

    /**
     * @notice Emitted when a template function is called.
     * @param target The address of the target contract.
     * @param data The abi-encoded data.
     * @param result The abi-encoded result.
     * @param sender The address of the message sender.
     */
    event FunctionCalled(address indexed target, bytes data, bytes result, address indexed sender);

    /**
     * @notice Structure of a template version.
     * @param exists True if the version exists, False if it does not.
     * @param deprecated True if the version is deprecated, False if it is not.
     * @param implementation The address of the version's implementation.
     * @param creationCode The abi-encoded creation code.
     * @param totalParts The total number of parts of the version.
     * @param partsUploaded The number of parts uploaded.
     * @param instances The array of instances.
     */
    struct Version {
        bool deprecated;
        address implementation;
        bytes creationCode;
        uint256 totalParts;
        uint256 partsUploaded;
        address[] instances;
    }

    /**
     * @notice Structure of a template.
     * @param disabled Boolean value indicating if the template is enabled.
     * @param latestVersion The latest version of the template.
     * @param deployRole The deployer role of the template.
     * @param version The versions of the template.
     * @param instances The instances of the template.
     */
    struct Template {
        bool disabled;
        bytes32 deployRole;
        Version[] versions;
        address[] instances;
    }

    /**
     * @notice Structure of deployment information.
     * @param exists Boolean value indicating if the deployment information exists.
     * @param templateId The id of the template.
     * @param version The version of the template.
     * @param args The abi-encoded arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param cloned Boolean indicating if the deployment information is cloned.
     */
    struct DeploymentInfo {
        bool exists;
        uint64 block;
        uint64 timestamp;
        address sender;
        bytes32 templateId;
        uint256 version;
        bytes args;
        bytes[] functionCalls;
        bool cloned;
    }

    /**
     * @notice Initializer of the contract.
     */
    function initialize() external;

    /**
     * @notice Returns a version of a template.
     * @param templateId The id of the template to return the version of.
     * @param version The version of the template to be returned.
     * @return The version of the template.
     */
    function version(bytes32 templateId, uint256 version) external view returns (Version memory);

    /**
     * @notice Returns the latest version of a template.
     * @param templateId The id of the template to return the latest version of.
     * @return The latest version of the template.
     */
    function latestVersion(bytes32 templateId) external view returns (uint256);

    /**
     * @notice Returns the instances of a template.
     * @param templateId The id of the template to return the latest instance of.
     * @return The instances of the template.
     */
    function templateInstances(bytes32 templateId) external view returns (address[] memory);

    /**
    * @notice Returns the deployment information of an instance.
     * @param instance The instance of the template to return deployment information of.
     * @return The deployment information of the template.
     */
    function deploymentInfo(address instance) external view returns (DeploymentInfo memory);

    /**
     * @notice Returns the deploy role of a template.
     * @param templateId The id of the template to return the deploy role of.
     * @return The deploy role of the template.
     */
    function deployRole(bytes32 templateId) external view returns (bytes32);

    /**
     * @notice Returns True if an instance has been deployed by the template factory, else returns False.
     * @dev Returns `true` if `instance` has been deployed by the template factory, else returns `false`.
     * @param instance The instance of the template to return True for, if it has been deployed by the factory, else False.
     * @return Boolean value indicating if the instance has been deployed by the template factory.
     */
    function deployedByFactory(address instance) external view returns (bool);

    /**
     * @notice Uploads a new template and returns True.
     * @param templateId The id of the template to upload.
     * @param initialPart The initial part to upload.
     * @param totalParts The number of total parts of the template.
     * @param implementation The address of the implementation of the template.
     * @custom:emits TemplateVersionCreated
     * @custom:requirement The length of `initialPart` must be greater than zero.
     */
    function uploadTemplate(bytes32 templateId, bytes memory initialPart, uint256 totalParts, address implementation) external returns (bool);

    /**
     * @notice Uploads a part of a template.
     * @param templateId The id of the template to upload a part to.
     * @param version The version of the template to upload a part to.
     * @param part The part to upload to the template.
     * @custom:requirement The length of part must be greater than zero.
     * @custom:requirement The version of the template must already exist.
     * @custom:requirement The version's number of parts uploaded must be less than the version's total number of parts.
     * @return Boolean value indicating if the operation was successful.
     */
    function uploadTemplatePart(bytes32 templateId, uint256 version, bytes memory part) external returns (bool);

    /**
     * @notice Updates the deploy role of a template.
     * @param templateId The id of the template to update the deploy role for.
     * @param deployRole The deploy role to update to.
     * @custom:emits DeployRoleUpdated
     * @custom:requirement The template's existing deploy role cannot be equal to `deployRole`.
     * @return Boolean value indicating if the operation was successful.
     */
    function updateDeployRole(bytes32 templateId, bytes32 deployRole) external returns (bool);

    /**
     * @notice Disables a template and returns True.
     * @dev Disables a template and returns `true`.
     * @param templateId The id of the template to disable.
     * @custom:emits TemplateDisabled
     * @custom:requirement The template must be enabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function disableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Enables a template and returns True.
     * @dev Enables a template and returns `true`.
     * @param templateId The id of the template to enable.
     * @custom:emits TemplateEnabled
     * @custom:requirement The template must be disabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function enableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Deprecates a version of a template. A deprecated template version cannot be deployed.
     * @param templateId The id of the template to deprecate the version for.
     * @param version The version of the template to deprecate.
     * @custom:emits TemplateVersionDeprecated
     * @custom:requirement The version must already exist.
     * @custom:requirement The version must not be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function deprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    /**
     * @notice Undeprecates a version of a template and returns True.
     * @param templateId The id of the template to undeprecate a version for.
     * @param version The version of a template to undeprecate.
     * @custom:emits TemplateVersionUndeprecated
     * @custom:requirement The version must be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function undeprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    /**
     * @notice Returns the Init Code Hash.
     * @dev Returns the keccak256 hash of `templateId`, `version` and `args`.
     * @param templateId The id of the template to return the init code hash of.
     * @param args The abi-encoded constructor arguments.
     * @return The abi-encoded init code hash.
     */
    function initCodeHash(bytes32 templateId, uint256 version, bytes memory args) external view returns (bytes32);

    /**
     * @notice Overloaded predictDeployAddress function.
     * @dev See {ITemplateFactory-predictDeployAddress}.
     * @param templateId The id of the template to predict the deploy address for.
     * @param version The version of the template to predict the deploy address for.
     * @param args The abi-encoded constructor arguments.
     */
    function predictDeployAddress(bytes32 templateId, uint256 version, bytes memory args, bytes32 salt) external view returns (address);

    /**
     * @notice Predict the clone address.
     * @param templateId The id of the template to predict the clone address for.
     * @param version The version of the template to predict the clone address for.
     * @return The predicted clone address.
     */
    function predictCloneAddress(bytes32 templateId, uint256 version, bytes32 salt) external view returns (address);

    /**
     * @notice Deploys a version of a template.
     * @param templateId The id of the template to deploy.
     * @param version The version of the template to deploy.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateDeployed
     * @custom:requirement The version's number of parts must be equal to the version's number of parts uploaded.
     * @custom:requirement The length of the version's creation code must be greater than zero.
     * @return instance The instance of the deployed template.
     */
    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    /**
     * @notice Clones a version of a template.
     * @param templateId The id of the template to clone.
     * @param version The version of the template to clone.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateCloned
     * @custom:requirement The version's implementation must not equal `address(0)`.
     * @return instance The address of the cloned template instance.
     */
    function cloneTemplate(bytes32 templateId, uint256 version, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    /**
     * @notice Calls a function on the target contract.
     * @param target The target address of the function call.
     * @param data Miscalaneous data associated with the transfer.
     * @custom:emits FunctionCalled
     * @return result The result of the function call.
     */
    function functionCall(address target, bytes memory data) external returns (bytes memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ILockdrop.sol";

/**
 * @title SOMA Lockdrop Factory Contract.
 * @author SOMA.finance.
 * @notice A factory that produces Lockdrop contracts.
 */
interface ILockdropFactory {

    /**
     * @notice Emitted when a Lockdrop is created.
     * @param id The ID of the Lockdrop.
     * @param asset The delegation asset of the Lockdrop.
     * @param instance The address of the created Lockdrop.
     */
    event LockdropCreated(uint256 id, address asset, address instance);

    /**
     * @notice The Lockdrop's CREATE_ROLE.
     * @dev Returns keccak256('Lockdrop.CREATE_ROLE').
     */
    function CREATE_ROLE() external pure returns (bytes32);

    /**
     * @notice Creates a Lockdrop instance.
     * @param asset The address of the delegation asset.
     * @param withdrawTo The address that delegated assets will be withdrawn to.
     * @param dateConfig The date configuration of the Lockdrop.
     * @custom:emits LockdropCreated
     */
    function create(
        address asset,
        address withdrawTo,
        ILockdrop.DateConfig calldata dateConfig
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Lockdrop Contract.
 * @author SOMA.finance
 * @notice A fund raising contract for bootstrapping DEX liquidity pools.
 */
interface ILockdrop {

    /**
     * @notice Emitted when the {DelegationConfig} is updated.
     * @param prevConfig The previous delegation configuration.
     * @param newConfig The new delegation configuration.
     * @param sender The message sender that triggered the event.
     */
    event DelegationConfigUpdated(DelegationConfig prevConfig, DelegationConfig newConfig, address indexed sender);

    /**
     * @notice Emitted when the {withdrawTo} address is updated.
     * @param prevTo The previous withdraw to address.
     * @param newTo The new withdraw to address.
     * @param sender The message sender that triggered the event.
     */
    event WithdrawToUpdated(address prevTo, address newTo, address indexed sender);

    /**
     * @notice Emitted when a delegation is added to a pool.
     * @param poolId The pool ID.
     * @param amount The delegation amount denominated in the delegation asset.
     * @param sender The message sender that triggered the event.
     */
    event DelegationAdded(bytes32 indexed poolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when someone calls {moveDelegation}, transferring their delegation to a different pool.
     * @param fromPoolId The pool ID of the source pool.
     * @param toPoolId The pool ID of the destination pool.
     * @param amount The amount of the delegation asset to move.
     * @param sender TThe message sender that triggered the event.
     */
    event DelegationMoved(bytes32 indexed fromPoolId, bytes32 indexed toPoolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when the {DateConfig} is updated.
     * @param prevDateConfig The previous date configuration.
     * @param newDateConfig The new date configuration.
     * @param sender The message sender that triggered the event.
     */
    event DatesUpdated(DateConfig prevDateConfig, DateConfig newDateConfig, address indexed sender);

    /**
     * @notice Emitted when the {Pool} is updated.
     * @param poolId The pool ID.
     * @param requiredPrivileges The new required privileges.
     * @param enabled Boolean indicating if the pool is enabled.
     * @param sender The message sender that triggered the event.
     */
    event PoolUpdated(bytes32 indexed poolId, bytes32 requiredPrivileges, bool enabled, address indexed sender);

    /**
     * @notice Date Configuration structure. These phases represent the 3 phases that the lockdrop
     * will go through, and will change the functionality of the lockdrop at each phase.
     * @param phase1 The unix timestamp for the start of phase1.
     * @param phase2 The unix timestamp for the start of phase2.
     * @param phase3 The unix timestamp for the start of phase3.
     */
    struct DateConfig {
        uint48 phase1;
        uint48 phase2;
        uint48 phase3;
    }

    /**
     * @notice Pool structure. Each pool will bootstrap liquidity for an upcoming DEX pair.
     * E.g: sTSLA/USDC
     * @param enabled Boolean indicating if the pool is enabled.
     * @param requiredPrivileges The required privileges of the pool.
     * @param balances The mapping of user addresses to delegation balances.
     */
    struct Pool {
        bool enabled;
        bytes32 requiredPrivileges;
        mapping(address => uint256) balances;
    }

    /**
     * @notice Delegation Configuration structure. Each user will specify their own Delegation Configuration.
     * @param percentLocked The percentage of user rewards to delegate to phase2.
     * @param lockDuration The lock duration of the user rewards.
     */
    struct DelegationConfig {
        uint8 percentLocked;
        uint8 lockDuration;
    }

    /**
     * @notice Returns the Lockdrop Global Admin Role.
     * @dev Equivalent to keccak256('Lockdrop.GLOBAL_ADMIN_ROLE').
     */
    function GLOBAL_ADMIN_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the Lockdrop Local Admin Role.
     */
    function LOCAL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the ID of the Lockdrop.
     */
    function id() external view returns (uint256);

    /**
     * @notice The address of the Lockdrop's delegation asset.
     */
    function asset() external view returns (address);

    /**
     * @notice The date configuration of the Lockdrop.
     */
    function dateConfig() external view returns (DateConfig memory);

    /**
     * @notice The address where the delegated funds will be withdrawn to.
     */
    function withdrawTo() external view returns (address);

    /**
     * @notice Initialize function for the Lockdrop contract.
     * @param _id The ID of the Lockdrop.
     * @param _asset The address of the delegation asset for the pool.
     * @param _withdrawTo The withdrawTo address for the pool.
     * @param _dateConfig The date configuration for the Lockdrop.
     */
    function initialize(
        uint256 _id,
        address _asset,
        address _withdrawTo,
        DateConfig calldata _dateConfig
    ) external;

    /**
     * @notice Updates the Lockdrop's date configuration.
     * @param newConfig The updated date configuration.
     * @custom:emits DatesUpdated
     */
    function updateDateConfig(DateConfig calldata newConfig) external;

    /**
     * @notice Sets the `withdrawTo` address.
     * @param account The updated `withdrawTo` address.
     * @custom:emits WithdrawToUpdated
     */
    function setWithdrawTo(address account) external;

    /**
     * @notice Returns the delegation balance of an account, given a pool ID.
     * @param poolId The poolId to return the account's balance of.
     * @param account The account to return the balance of.
     * @return The delegation balance of `account` for the `poolId` pool.
     */
    function balanceOf(bytes32 poolId, address account) external view returns (uint256);

    /**
     * @notice Returns the delegation configuration of an account.
     * @param account The account to return the delegation configuration of.
     * @return The delegation configuration of the Lockdrop.
     */
    function delegationConfig(address account) external view returns (DelegationConfig memory);

    /**
     * @notice Returns a boolean indicating if a pool is enabled.
     * @param poolId The pool ID to check the enabled status of.
     * @return True if the pool is enabled, False if the pool is disabled.
     */
    function enabled(bytes32 poolId) external view returns (bool);

    /**
     * @notice Returns the required privileges of the pool. These privileges are required in order to
     * delegate.
     * @param poolId The pool ID to check the enabled status of.
     * @return The required privileges of the pool.
     */
    function requiredPrivileges(bytes32 poolId) external view returns (bytes32);

    /**
     * @notice Updates the lockdrop pool parameters.
     * @param poolId The ID of the pool to update.
     * @param requiredPrivileges The updated required privileges of the pool.
     * @param enabled The updated enabled or disabled state of the pool.
     * @custom:emits PoolUpdated
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function updatePool(bytes32 poolId, bytes32 requiredPrivileges, bool enabled) external;

    /**
     * @notice Withdraws tokens from the Lockdrop contract to the `withdrawTo` address.
     * @param amount The amount of tokens to be withdrawn.
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Moves the accounts' delegated tokens from one pool to another.
     * @param fromPoolId The ID of the pool that the delegation will be moved from.
     * @param toPoolId The ID of the pool that the delegation will be moved to.
     * @param amount The amount of tokens to be moved.
     * @custom:emits DelegationMoved
     * @custom:requirement `fromPoolId` must not be equal to `toPoolId`.
     * @custom:requirement The Lockdrop's `phase1` must have started already.
     * @custom:requirement The Lockdrop's `phase2` must not have ended yet.
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `fromPoolId` pool must be enabled.
     * @custom:requirement The `toPoolId` pool must be enabled.
     * @custom:requirement The delegation balance of the caller for the `fromPoolId` pool must be greater than
     * or equal to `amount`.
     * @custom:requirement The function caller must have the required privileges of the `fromPoolId` pool.
     * @custom:requirement The function caller must have the required privileges of the `toPoolId` pool.
     */
    function moveDelegation(bytes32 fromPoolId, bytes32 toPoolId, uint256 amount) external;

    /**
     * @notice Delegates tokens to the a specific pool.
     * @param poolId The ID of the pool to receive the delegation.
     * @param amount The amount of tokens to be delegated.
     * @custom:emits DelegationAdded
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `poolId` pool must be enabled.
     * @custom:requirement The `poolId` pool's phase1 must have started already.
     * @custom:requirement The `poolId` pool's phase2 must not have ended yet.
     * @custom:requirement The function caller must have the `poolId` pool's required privileges.
     */
    function delegate(bytes32 poolId, uint256 amount) external;

    /**
     * @notice Updates the delegation configuration of an account.
     * @param newConfig The updated delegation configuration of the account.
     * @custom:emits DelegationConfigUpdated
     * @custom:requirement The ``newConfig``'s percent locked must be a valid percentage.
     * @custom:requirement The Lockdrop's phase1 must have started already.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s percent locked must be
     * greater than the existing percent locked for the account.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s lock duration must be equal
     * to the existing lock duration for the account.
     */
    function updateDelegationConfig(DelegationConfig calldata newConfig) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Token Rewards Contract.
 * @author SOMA.finance
 * @notice Interface for the {TokenRecoveryUpgradeable} contract.
 */
interface ITokenRecoveryUpgradeable {

    /**
     * @notice Emitted when tokens are recovered.
     * @param token The address of the recovered tokens.
     * @param to The address that the tokens are being sent to.
     * @param amount The amount of tokens recovered.
     * @param sender The address of the message sender.
     */
    event TokensRecovered(address indexed token, address indexed to, uint256 amount, address indexed sender);

    /**
     * @notice Returns the Token Recovery Upgradeable TOKEN_RECOVERY_ROLE.
     */
    function TOKEN_RECOVERY_ROLE() external pure returns (bytes32);

    /**
     * @notice Recovers tokens and transfers these tokens to `to`.
     * @param asset The address of the recovered tokens.
     * @param to The address that the tokens are being sent to.
     * @param amount The amount of tokens recovered.
     */
    function recoverTokens(address asset, address to, uint256 amount) external;
}
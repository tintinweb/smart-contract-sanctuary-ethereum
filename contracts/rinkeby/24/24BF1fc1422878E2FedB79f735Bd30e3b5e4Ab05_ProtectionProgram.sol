// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IProtectionProgram.sol";

contract ProtectionProgram is IProtectionProgram, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    Contracts public contracts;
    TenureInfo public tenureInfo;
    Settings public settings;

    mapping(uint256 => BankerStake) public nftToBankerStake;
    mapping(uint256 => HumalStake) public nftToHumalStake;

    mapping(address => EnumerableSet.UintSet) private __nftOwnerToNftNumber;

    //// START view variables for FE
    uint256 public bankersInProgram;
    uint256 public humalsInProgram;
    uint256 public rewardTokenShared;
    //// END

    function initialize(
        address _creatureAddress,
        address _randomizerAddress,
        address _rewardTokenAddress
    ) initializer public {
        __Ownable_init();

        contracts.creature = ICreature(_creatureAddress);
        contracts.randomizer = IRandomizer(_randomizerAddress);
        contracts.rewardToken = IERC20(_rewardTokenAddress);
    }

    /**
     * @notice Set bankers reward for each second
     * @param _bankerRewardPerSecond Reward per second. Wei
     */
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external override onlyOwner {
        require(_bankerRewardPerSecond > 0, "PP: bankers reward is zero");

        settings.bankerRewardPerSecond = _bankerRewardPerSecond;
    }

    /**
     * @notice Set tax percent for humals. When bankers claim rewards, part of rewards (tax) are collected by the humals
     * @param _taxPercent Percent in decimals. Where 10^27 = 100%
     */
    function setTaxPercent(uint128 _taxPercent) external override onlyOwner {
        require(_taxPercent > 0 && _taxPercent < __getDecimals(), "PP: invalid tax value");

        settings.taxPercent = _taxPercent;
    }

    /**
     * @notice When banker claim reward, humal have a chance to steal all of them. Set this chance
     * @param _chance Chance. Where 10^27 = 100%
     */
    function setStealOnWithdrawChance(uint128 _chance) external override onlyOwner {
        require(_chance > 0 && _chance < __getDecimals(), "PP: invalid chance value");

        settings.stealOnWithdrawChance = _chance;
    }

    /**
     * @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time
     * @param _withdrawLockupPeriod Time. Seconds
     */
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external override onlyOwner {
        settings.withdrawLockupPeriod = _withdrawLockupPeriod;
    }

    /**
     * @notice Add NFTs to protection program
     * @dev Will be added only existed NFTs where sender is nft owner
     * @param _ids NFTs
     */
    function add(uint256[] calldata _ids) external override {
        require(_ids.length > 0, "PP: array is empty");

        ICreature _creature = contracts.creature;

        uint256 _currentRewardPerTenure = tenureInfo.currentRewardPerTenure;

        uint256 _tenureScoreAdded;
        uint256 _humalsAdded;
        uint256 _bankersAdded;
        for (uint256 _i; _i < _ids.length; _i++) {
            uint256 _id = _ids[_i];
            address _nftOwner = _creature.ownerOf(_id);

            if (_id == 0) continue;

            _creature.transferFrom(_nftOwner, address(this), _id);
            __nftOwnerToNftNumber[_nftOwner].add(_id);

            (,uint256 _tenureScore, CreatureType _type) = _creature.getCreatureInfo(_id);
            if (_type == CreatureType.Humal) {
                nftToHumalStake[_id] = HumalStake(_nftOwner, _tenureScore, _currentRewardPerTenure);

                _tenureScoreAdded += _tenureScore;
                _humalsAdded++;

                emit HumalAdded(_id);
            } else if (_type == CreatureType.Banker) {
                nftToBankerStake[_id] = BankerStake(_nftOwner, uint64(block.timestamp));
                _bankersAdded++;

                emit BankerAdded(_id);
            } else {
                revert("PP: invalid NFT type");
            }
        }

        tenureInfo.totalTenureScore += _tenureScoreAdded;
        bankersInProgram += _bankersAdded;
        humalsInProgram += _humalsAdded;
    }

    /**
     * @notice @notice Claim rewards for selected NFTs
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function claim(uint256[] calldata _ids) external override {
        __claim(_ids, false);
    }

    /**
     * @notice Claim rewards for selected NFTs and withdraw from protection program
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function withdraw(uint256[] calldata _ids) external override {
        __claim(_ids, true);
    }

    /**
     * @notice Calculate reward amount for NFTs. On withdraw, part of reward can be stolen
     * @dev Sender should be nft owner. Nft should be in the protection program
     * @param _ids NFTs
     * @return bankersReward Rewards for bankers
     * @return humalsReward Rewards for humals
     */
    function calculatePotentialRewards(uint256[] calldata _ids)
        external
        view
        override
        returns (uint256 bankersReward, uint256 humalsReward)
    {
        (bankersReward, humalsReward,,) = __calculateRewards(_ids, false);
    }

    /**
     * @notice Withdraw native token from contract
     * @param _to Recipient
     */
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /**
     * @notice Transfer ERC20 tokens
     * @param _token Token address
     * @param _to Recipient
     * @param _amount Token amount
     */
    function withdrawERC20(address _token, address _to, uint256 _amount) external override onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * @notice Return array with NFTs by owner
     * @param _address Owner address
     * @param _from Index from
     * @param _amount Amount
     */
    function getNFTsByOwner(
        address _address,
        uint256 _from,
        uint256 _amount
    ) external view override returns(uint256[] memory, bool[] memory) {
        uint256 _totalCount = __nftOwnerToNftNumber[_address].length();
        if (_from + _amount > _totalCount) _amount = _totalCount - _from;

        ICreature _creature = contracts.creature;
        uint256[] memory _nfts = new uint256[](_amount);
        bool[] memory _isHumal = new bool[](_amount);

        uint256 _id;
        uint256 _k = _from;
        for (uint256 _i; _i < _amount; _i++) {
            _id = __nftOwnerToNftNumber[_address].at(_k);
            _nfts[_i] = _id;

            (,,CreatureType _type) = _creature.getCreatureInfo(_id);
            if (_type == CreatureType.Humal) _isHumal[_i] = true;

            _k++;
        }

        return (_nfts, _isHumal);
    }

    function __claim(uint256[] calldata _ids, bool _isWithdraw) private {
        (
            uint256 _bankersReward,
            uint256 _humalsReward,
            uint256 _currentRewardPerTenure,
            bool[] memory _isIdsHumals
        ) = __calculateRewards(_ids, _isWithdraw);

        ICreature _creature = contracts.creature;
        uint256 _tenureToDelete;
        uint256 _bankersToWithdraw;
        uint256 _humalsToWithdraw;

        // START update storage for each NFT
        for (uint256 _i; _i < _ids.length; _i++) {
            if (_isIdsHumals[_i]) {
                if (_isWithdraw) {
                    _humalsToWithdraw++;
                    _tenureToDelete += __withdrawRebel(_creature, _ids[_i]);

                    __nftOwnerToNftNumber[msg.sender].remove(_ids[_i]);
                }
                else {
                    nftToHumalStake[_ids[_i]].baseRewardByTenure = _currentRewardPerTenure;
                }
            } else {
                if (_isWithdraw) {
                    _bankersToWithdraw++;
                    __withdrawBanker(_creature, _ids[_i]);

                    __nftOwnerToNftNumber[msg.sender].remove(_ids[_i]);
                }
                else nftToBankerStake[_ids[_i]].lastClaim = uint64(block.timestamp);
            }
        }
        // END

        // START update storage part
        tenureInfo.currentRewardPerTenure = _currentRewardPerTenure;
        tenureInfo.totalTenureScore -= _tenureToDelete;
        bankersInProgram -= _bankersToWithdraw;
        humalsInProgram -= _humalsToWithdraw;
        // END

        // START transfer farming token
        IERC20 _rewardToken = contracts.rewardToken;

        uint256 _contractBalance = _rewardToken.balanceOf(address(this));
        uint256 _totalReward = _bankersReward + _humalsReward;

        if (_contractBalance < _totalReward) _totalReward = _contractBalance;
        if (_totalReward > 0) {
            _rewardToken.transfer(msg.sender, _totalReward);
            rewardTokenShared += _totalReward;
        }
        // END

        emit Claimed(_ids, _isWithdraw, _totalReward);
    }

    function __calculateRewards(
        uint256[] calldata _ids,
        bool _isWithdraw
    ) private view returns (uint256 , uint256, uint256, bool[] memory _isIdsHumals) {
        Settings memory _settings = settings;
        Contracts memory _contracts = contracts;
        TenureInfo memory _tenureInfo = tenureInfo;

        _isIdsHumals = new bool[](_ids.length);

        uint256 _totalBankersReward;
        uint256 _totalRebelsReward;

        for (uint256 _i; _i < _ids.length; _i++) {
            if (_i > 0) require(_ids[_i] > _ids[_i - 1], "PP: invalid sequence of numbers");

            if (msg.sender == nftToBankerStake[_ids[_i]].owner) {
                (uint256 _bankerReward, uint256 _rewardPerTenure) = __calcBankerReward(_ids[_i], _isWithdraw, _settings, _contracts, _tenureInfo);

                _totalBankersReward += _bankerReward;
                _tenureInfo.currentRewardPerTenure += _rewardPerTenure;
            } else if (msg.sender == nftToHumalStake[_ids[_i]].owner) {
                _totalRebelsReward += __calculateRebelReward(_ids[_i], _tenureInfo.currentRewardPerTenure);
                _isIdsHumals[_i] = true;
            } else {
                revert("PP: invalid NFT id");
            }
        }

        return (_totalBankersReward, _totalRebelsReward, _tenureInfo.currentRewardPerTenure, _isIdsHumals);
    }

    function __calcBankerReward(
        uint256 _num,
        bool _isWithdraw,
        Settings memory _settings,
        Contracts memory _contracts,
        TenureInfo memory _tenureInfo
    ) private view returns (uint256, uint256) {
        uint64 _lastClaim = nftToBankerStake[_num].lastClaim;
        if (_isWithdraw) require(_lastClaim + _settings.withdrawLockupPeriod < block.timestamp, "PP: nft is locked");

        uint256 _claimAmount = _settings.bankerRewardPerSecond * (block.timestamp - _lastClaim);

        uint256 _taxAmount;
        uint256 _rewardPerTenure;

        if (_tenureInfo.totalTenureScore > 0) {
            uint256 _randNum = IRandomizer(_contracts.randomizer).random(__getDecimals(), _num);
            if (_isWithdraw && _randNum < _settings.stealOnWithdrawChance) {
                _taxAmount = _claimAmount;
                _claimAmount = 0;
            } else {
                _taxAmount = (_claimAmount * _settings.taxPercent) / __getDecimals();
                _claimAmount -= _taxAmount;
            }

            _rewardPerTenure = _taxAmount / _tenureInfo.totalTenureScore;
        }

        return (_claimAmount, _rewardPerTenure);
    }

    function __calculateRebelReward(uint256 _num, uint256 _currentRewardPerTenure) private view returns (uint256) {
        return nftToHumalStake[_num].tenure * (_currentRewardPerTenure - nftToHumalStake[_num].baseRewardByTenure);
    }

    function __withdrawBanker(ICreature _creature, uint256 _id) private {
        delete nftToBankerStake[_id];

        _creature.safeTransferFrom(address(this), msg.sender, _id);
    }

    function __withdrawRebel(ICreature _creature, uint256 _id) private returns (uint256) {
        uint256 _tenure = nftToHumalStake[_id].tenure;

        // Delete main stake struct
        delete nftToHumalStake[_id];

        // Transfer
        _creature.safeTransferFrom(address(this), msg.sender, _id);

        return _tenure;
    }

    function __getDecimals() private pure returns (uint256) {
        return 10**27;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICreature.sol";
import "./IRandomizer.sol";
import "./ICreatureType.sol";

/// @title Interface for `ProtectionProgram` contract
interface IProtectionProgram is ICreatureType {
    event BankerAdded(uint256 id);
    event HumalAdded(uint256 id);
    event Claimed(uint256[] ids, bool isWithdrawn, uint256 amount);

    struct Contracts {
        ICreature creature;
        IRandomizer randomizer;
        IERC20 rewardToken;
    }

    struct TenureInfo {
        uint256 totalTenureScore;
        uint256 currentRewardPerTenure;
    }

    struct Settings {
        uint256 bankerRewardPerSecond;
        uint128 taxPercent;
        uint128 stealOnWithdrawChance;
        uint64 withdrawLockupPeriod;
    }

    struct BankerStake {
        address owner;
        uint64 lastClaim;
    }

    struct HumalStake {
        address owner;
        uint256 tenure;
        uint256 baseRewardByTenure;
    }

    /**
     * @notice Set bankers reward for each second
     * @param _bankerRewardPerSecond Reward per second. Wei
     */
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external;

    /**
     * @notice Set tax percent for humals. When bankers claim rewards, part of rewards (tax) are collected by the humals
     * @param _taxPercent Percent in decimals. Where 10^27 = 100%
     */
    function setTaxPercent(uint128 _taxPercent) external;

    /**
     * @notice When banker claim reward, humal have a chance to steal all of them. Set this chance
     * @param _chance Chance. Where 10^27 = 100%
     */
    function setStealOnWithdrawChance(uint128 _chance) external;

    /**
     * @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time
     * @param _withdrawLockupPeriod Time. Seconds
     */
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external;

    /**
     * @notice Add NFTs to protection program
     * @dev Will be added only existed NFTs where sender is nft owner
     * @param _ids NFTs
     */
    function add(uint256[] calldata _ids) external;

    /**
     * @notice @notice Claim rewards for selected NFTs
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function claim(uint256[] calldata _ids) external;

    /**
     * @notice Claim rewards for selected NFTs and withdraw from protection program
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function withdraw(uint256[] calldata _ids) external;

    /**
     * @notice Calculate reward amount for NFTs. On withdraw, part of reward can be stolen
     * @dev Sender should be nft owner. Nft should be in the protection program
     * @param _ids NFTs
     * @return bankersReward Rewards for bankers
     * @return humalsReward Rewards for humals
     */
    function calculatePotentialRewards(uint256[] calldata _ids)
    external
    view
    returns (uint256 bankersReward, uint256 humalsReward);

    /**
     * @notice Withdraw native token from contract
     * @param _to Recipient
     */
    function withdrawNative(address _to) external;

    /**
     * @notice Transfer ERC20 tokens
     * @param _token Token address
     * @param _to Recipient
     * @param _amount Token amount
     */
    function withdrawERC20(address _token, address _to, uint256 _amount) external;

    /**
     * @notice Return array with NFTs by owner
     * @param _address Owner address
     * @param _from Index from
     * @param _amount Amount
     */
    function getNFTsByOwner(
        address _address,
        uint256 _from,
        uint256 _amount
    ) external view returns(uint256[] memory, bool[] memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "./ICreatureType.sol";
import "./IProtectionProgram.sol";

/// @title Interface for Creature contract
interface ICreature is ICreatureType, IERC721EnumerableUpgradeable {
    struct Creature {
        uint8 gen;
        uint8 tenure;
        CreatureType creatureType;
    }

    /**
     * @notice Set `Generator` contract address
     * @param _generatorAddress `Generator` contract address
     */
    function setGeneratorAddress(address _generatorAddress) external;

    /**
     * @notice Set `ProtectionProgram` contract address
     * @param _protectionProgramAddress `ProtectionProgram` contract address
     */
    function setProtectionProgramAddress(address _protectionProgramAddress) external;

    /**
     * @notice Mint new NFT, can be called only from `Generator` contract
     * @param _to NFT recipient
     * @param _id NFT ID
     */
    function safeMint(address _to, uint256 _id) external;

    /**
     * @dev Call to create a signature
     * @param _ids NFTs ID
     * @param _gens NFTs gen
     * @param _tenures NFTs tenure score
     */
    function addCreaturesInfo(
        uint256[] calldata _ids,
        uint8[] calldata _gens,
        uint8[] calldata _tenures
    ) external;

    /**
     * @dev Call to create a signature and stake to `ProtectionProgram` contract
     * @param _ids NFTs ID
     * @param _gens NFTs gen
     * @param _tenures NFTs tenure score
     */
    function addCreaturesInfoAndStake(
        uint256[] calldata _ids,
        uint8[] calldata _gens,
        uint8[] calldata _tenures
    ) external;

    /**
     * @dev Return info about NFT
     * @param _id NFT ID
     */
    function getCreatureInfo(uint256 _id) external view returns (uint256, uint256, CreatureType);

    /**
     * @dev Set base URI for NFTs
     * @param _baseUri https://www.google.com/ as example
     */
    function setBaseUri(string memory _baseUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Interface for Randomizer contract
interface IRandomizer {
    /**
     * @notice Get conventionally random number in range 0 <= _result < _maxNum
     * @param _maxNum Maximal value
     */
    function random(uint256 _maxNum) external returns (uint256 _result);

    /**
     * @notice @notice Get conventionally random number in range 0 <= _result < _maxNum
     * @param _maxNum Maximal value
     * @param _val Additional num
     */
    function random(uint256 _maxNum, uint256 _val) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICreatureType {
    enum CreatureType { Undefined, Banker, Humal }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
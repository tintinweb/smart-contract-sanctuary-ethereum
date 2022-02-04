// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICreature.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IProtectionProgram.sol";

/// @title ProtectionProgram contract
contract ProtectionProgram is IProtectionProgram, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Params {
        address creatureContract;
        address randomizerContract;
        address farmTokenContract;
        uint256 totalTenureScore;
        uint256 currentRewardPerTenure;
        uint256 bankerRewardPerSecond;
        uint128 taxPercent;
        uint128 stealOnWithdrawChance;
        uint64 withdrawLockupPeriod;
    }

    struct BankerStake {
        address owner;
        uint64 interactionTimestamp;
    }

    struct RebelStake {
        address owner;
        uint256 tenure;
        uint256 baseRewardByTenure;
    }

    Params public params;
    mapping(uint256 => BankerStake) public nftToBankerStake;
    mapping(uint256 => RebelStake) public nftToRebelStake;

    mapping(address => EnumerableSet.UintSet) private nftOwnerToNftNumber;

    /// @dev START storage for tenure groups.
    mapping(uint256 => uint256[]) public tenureGroupToRebels;
    mapping(uint256 => uint256) public rebelIndexInGroup;
    mapping(uint256 => bool) public isTenureGroupExist;
    uint256[] public tenureGroups;
    /// @dev END storage for tenure groups.

    /// @dev START view variables.
    uint256 public bankersInProgram;
    uint256 public rebelsInProgram;
    uint256 public farmTokenShared;
    /// @dev END view variables.

    constructor(
        address _creatureContract,
        address _randomizerContract,
        address _farmTokenContract
    ) {
        params.creatureContract = _creatureContract;
        params.randomizerContract = _randomizerContract;
        params.farmTokenContract = _farmTokenContract;
    }

    modifier onlyEOA() {
        address _sender = msg.sender;
        require(_sender == tx.origin, "ProtectionProgram: invalid sender (1).");

        uint256 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "ProtectionProgram: invalid sender (2).");

        _;
    }

    /// @notice Set bankers reward for each second.
    /// @param _bankerRewardPerSecond Reward per second. Wei.
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external override onlyOwner {
        require(_bankerRewardPerSecond > 0, "ProtectionProgram: bankers reward can't be a zero.");

        params.bankerRewardPerSecond = _bankerRewardPerSecond;
    }

    /// @notice Set tax percent for rebels. When bankers claim rewards, part of rewards (tax) are collected by the rebels.
    /// @param _taxPercent Percent in decimals. Where 10^27 = 100%.
    function setTaxPercent(uint128 _taxPercent) external override onlyOwner {
        require(_taxPercent > 0 && _taxPercent < _getDecimals(), "ProtectionProgram: invalid percent value.");

        params.taxPercent = _taxPercent;
    }

    /// @notice When banker claim reward, rebels have a chance to steal all of them. Set this chance
    /// @param _stealOnWithdrawChance Chance. Where 10^27 = 100%
    function setStealOnWithdrawChance(uint128 _stealOnWithdrawChance) external override onlyOwner {
        require(
            _stealOnWithdrawChance > 0 && _stealOnWithdrawChance < _getDecimals(),
            "ProtectionProgram: invalid withdraw chance."
        );

        params.stealOnWithdrawChance = _stealOnWithdrawChance;
    }

    /// @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time.
    /// @param _withdrawLockupPeriod Time. Seconds.
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external override onlyOwner {
        params.withdrawLockupPeriod = _withdrawLockupPeriod;
    }

    /// @notice Add nfts to protection program.
    /// @dev Will be added only existed nfts where sender is nft owner.
    /// @param _nums Nfts nums.
    function add(uint256[] calldata _nums) external override {
        require(_nums.length > 0, "ProtectionProgram: array is empty.");

        ICreature _creatureContract = ICreature(params.creatureContract);

        uint256 _currentRewardPerTenure = params.currentRewardPerTenure;
        uint256 _tenureScoreByNums;
        uint256 _rebelsAdded;
        uint256 _bankersAdded;
        for (uint256 i = 0; i < _nums.length; i++) {
            uint256 _num = _nums[i];

            if (_num == 0) continue;
            if (msg.sender != _creatureContract.ownerOf(_num)) continue;

            _creatureContract.transferFrom(msg.sender, address(this), _num);
            nftOwnerToNftNumber[msg.sender].add(_num);

            if (_creatureContract.isRebel(_num)) {
                (uint256 _tenureScore,,,,) = _creatureContract.getRebelInfo(_num);
                nftToRebelStake[_num] = RebelStake(msg.sender, _tenureScore, _currentRewardPerTenure);

                // START add _num to tenure groups
                rebelIndexInGroup[_num] = tenureGroupToRebels[_tenureScore].length;
                tenureGroupToRebels[_tenureScore].push(_num);

                if (!isTenureGroupExist[_tenureScore]) {
                    isTenureGroupExist[_tenureScore] = true;
                    tenureGroups.push(_tenureScore);
                }
                // END add _num to tenure groups

                _tenureScoreByNums += _tenureScore;
                _rebelsAdded++;

                emit RebelAdded(_num);
            } else {
                nftToBankerStake[_num] = BankerStake(msg.sender, uint64(block.timestamp));
                _bankersAdded++;

                emit BankerAdded(_num);
            }
        }

        params.totalTenureScore += _tenureScoreByNums;
        bankersInProgram += _bankersAdded;
        rebelsInProgram += _rebelsAdded;
    }

    /// @notice Claim rewards for selected nfts
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function claim(uint256[] calldata _nums) external override {
        _claim(_nums, false);
    }

    /// @notice Claim rewards for selected nfts and withdraw from protection program
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function withdraw(uint256[] calldata _nums) external override onlyEOA {
        _claim(_nums, true);
    }

    /// @notice Calculate reward amount for nfts. On withdraw, part of reward can be stolen.
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    /// @return bankersReward Rewards for all bankers
    /// @return rebelsReward Rewards for all rebels
    function calculateRewards(uint256[] calldata _nums)
        external
        view
        override
        returns (uint256 bankersReward, uint256 rebelsReward)
    {
        (bankersReward, rebelsReward, , ) = _calculateRewards(_nums, false);
    }

    /// @notice Return address of random rebel owner, dependent on rebel tenure score.
    function getRandomRebel() external override returns (address) {
        uint256 _totalTenureScore = params.totalTenureScore;
        if (_totalTenureScore == 0) return address(0);

        uint256 _rand = IRandomizer(params.randomizerContract).random(params.totalTenureScore);

        uint256 _l = tenureGroups.length;
        uint256 _tenureValue;
        uint256 _groupLength;
        uint256 _totalWeight;
        for (uint256 i = 0; i < _l; i++) {
            _tenureValue = tenureGroups[i];
            _groupLength = tenureGroupToRebels[_tenureValue].length;
            _totalWeight += _groupLength * _tenureValue;

            if (_rand < _totalWeight) {
                return nftToRebelStake[tenureGroupToRebels[_tenureValue][_rand % _groupLength]].owner;
            }
        }

        return address(0);
    }

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function withdrawStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        _token.transfer(_to, _amount);
    }

    /// @notice Return array with nfts by owner.
    /// @param _address Address.
    /// @param _from Index from.
    /// @param _amount Nfts amount in array.
    function getNftsByOwner(address _address, uint256 _from, uint256 _amount) external view override returns(uint256[] memory, bool[] memory) {
        uint256 _totalCount = nftOwnerToNftNumber[_address].length();
        if (_from + _amount > _totalCount) _amount = _totalCount - _from;

        ICreature _creature = ICreature(params.creatureContract);
        uint256[] memory _nfts = new uint256[](_amount);
        bool[] memory _isRebel = new bool[](_amount);
        uint256 _k = _from;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _num = nftOwnerToNftNumber[_address].at(_k);
            _nfts[i] = _num;
            _isRebel[i] = _creature.isRebel(_num);
            _k++;
        }

        return (_nfts, _isRebel);
    }

    function _claim(uint256[] calldata _nums, bool _isWithdraw) private {
        (
            uint256 _bankersReward,
            uint256 _rebelsReward,
            uint256 _currentRewardPerTenure,
            bool[] memory _isNumsRebel
        ) = _calculateRewards(_nums, _isWithdraw);

        ICreature _creatureContract = ICreature(params.creatureContract);
        uint256 _tenureToDelete;
        uint256 _bankersToWithdraw;
        uint256 _rebelsToWithdraw;
        // @dev _nums should be only bankers or rebels (nfts must exist)
        for (uint256 i = 0; i < _nums.length; i++) {
            if (_isNumsRebel[i]) {
                if (_isWithdraw) {
                    _rebelsToWithdraw++;
                    _tenureToDelete += _withdrawRebel(_creatureContract, _nums[i]);

                    nftOwnerToNftNumber[msg.sender].remove(_nums[i]);
                }
                else nftToRebelStake[_nums[i]].baseRewardByTenure = _currentRewardPerTenure;

                emit RebelClaimed(_nums[i], _isWithdraw);
            } else {
                if (_isWithdraw) {
                    _bankersToWithdraw++;
                    _withdrawBanker(_creatureContract, _nums[i]);

                    nftOwnerToNftNumber[msg.sender].remove(_nums[i]);
                }
                else nftToBankerStake[_nums[i]].interactionTimestamp = uint64(block.timestamp);

                emit BankerClaimed(_nums[i], _isWithdraw);
            }
        }

        // START UPDATE storage part
        params.currentRewardPerTenure = _currentRewardPerTenure;
        params.totalTenureScore -= _tenureToDelete;
        bankersInProgram -= _bankersToWithdraw;
        rebelsInProgram -= _rebelsToWithdraw;
        // END UPDATE storage part

        // START transfer farming token
        IERC20 _farmTokenContract = IERC20(params.farmTokenContract);

        uint256 _contractBalance = _farmTokenContract.balanceOf(address(this));
        uint256 _totalReward = _bankersReward + _rebelsReward;

        if (_contractBalance < _totalReward) _totalReward = _contractBalance;
        if (_totalReward > 0) _farmTokenContract.transfer(msg.sender, _totalReward);
        farmTokenShared += _totalReward;

        emit TokensClaimed(_nums, _isWithdraw);
        // END transfer farming token
    }

    function _calculateRewards(uint256[] calldata _nums, bool _isWithdraw)
        private
        view
        returns (
            uint256 _totalBankersReward,
            uint256 _totalRebelsReward,
            uint256,
            bool[] memory _isNumsRebel
        )
    {
        Params memory _params = params;
        _isNumsRebel = new bool[](_nums.length);

        for (uint256 i = 0; i < _nums.length; i++) {
            if (i > 0) require(_nums[i] > _nums[i - 1], "ProtectionProgram: invalid sequence of numbers in the array.");

            if (msg.sender == nftToBankerStake[_nums[i]].owner) {
                (uint256 _bankerReward, uint256 _rewardPerTenure) = _calculateBankerReward(
                    _nums[i],
                    _params,
                    _isWithdraw
                );

                _totalBankersReward += _bankerReward;
                _params.currentRewardPerTenure += _rewardPerTenure;
            } else if (msg.sender == nftToRebelStake[_nums[i]].owner) {
                _totalRebelsReward += _calculateRebelReward(_nums[i], _params.currentRewardPerTenure);
                _isNumsRebel[i] = true;
            } else {
                revert("ProtectionProgram: nft is not on the contract or caller is not a token owner.");
            }
        }

        return (_totalBankersReward, _totalRebelsReward, _params.currentRewardPerTenure, _isNumsRebel);
    }

    function _calculateBankerReward(
        uint256 _num,
        Params memory _params,
        bool _isWithdraw
    ) private view returns (uint256 _claimAmount, uint256 _rewardPerTenure) {
        uint256 _taxAmount;
        uint64 _interactionTimestamp = nftToBankerStake[_num].interactionTimestamp;
        _claimAmount = _params.bankerRewardPerSecond * (block.timestamp - _interactionTimestamp);

        if (_isWithdraw)
            require(
                _interactionTimestamp + _params.withdrawLockupPeriod < block.timestamp,
                "ProtectionProgram: wait until the lockout period is over."
            );

        if (_params.totalTenureScore > 0) {
            if (
                _isWithdraw &&
                IRandomizer(_params.randomizerContract).random(_getDecimals(), _num) < _params.stealOnWithdrawChance
            ) {
                _taxAmount = _claimAmount;
                _claimAmount = 0;
            } else {
                _taxAmount = (_claimAmount * _params.taxPercent) / _getDecimals();
                _claimAmount -= _taxAmount;
            }

            _rewardPerTenure = _taxAmount / _params.totalTenureScore;
        }

        return (_claimAmount, _rewardPerTenure);
    }

    function _calculateRebelReward(uint256 _num, uint256 _currentRewardPerTenure) private view returns (uint256) {
        return nftToRebelStake[_num].tenure * (_currentRewardPerTenure - nftToRebelStake[_num].baseRewardByTenure);
    }

    function _withdrawBanker(ICreature _creatureContract, uint256 _num) private {
        delete nftToBankerStake[_num];

        _creatureContract.safeTransferFrom(address(this), msg.sender, _num);
    }

    function _withdrawRebel(ICreature _creatureContract, uint256 _num) private returns (uint256) {
        uint256 _tenureScore = nftToRebelStake[_num].tenure;

        // Delete main stake struct
        delete nftToRebelStake[_num];

        // START clear rebel group info
        uint256 _rebelsInGroup = tenureGroupToRebels[_tenureScore].length;
        if (_rebelsInGroup > 1) {
            tenureGroupToRebels[_tenureScore][rebelIndexInGroup[_num]] = tenureGroupToRebels[_tenureScore][
                _rebelsInGroup - 1
            ];
        }
        tenureGroupToRebels[_tenureScore].pop();
        delete rebelIndexInGroup[_num];

        if (_rebelsInGroup == 1) {
            uint256 _l = tenureGroups.length;
            for (uint256 k = 0; k < _l; k++) {
                if (_tenureScore != tenureGroups[k]) continue;

                tenureGroups[k] = tenureGroups[_l - 1];
                tenureGroups.pop();
                delete isTenureGroupExist[_tenureScore];

                break;
            }
        }
        // END clear rebel group info

        _creatureContract.safeTransferFrom(address(this), msg.sender, _num);

        return _tenureScore;
    }

    /// @dev Decimals for number.
    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Interface for Creature contract
interface ICreature is IERC721Enumerable {
    enum CreatureType { Banker, Rebel }

    /// @notice Once set generator address.
    /// @param _generator Address.
    function setGeneratorAddress(address _generator) external;

    /// @notice Mint new NFT.
    /// @param _to Address.
    /// @param _num NFT number.
    function safeMint(address _to, uint256 _num) external;

    /// @notice Add information about Banker.
    /// @param _num NFT number.
    /// @param _gen NFT generation.
    /// @param _rand Random num.
    function addBankerInfo(uint256 _num, uint8 _gen, uint256 _rand) external;

    /// @notice Add information about Rebel.
    /// @param _num NFT number.
    /// @param _tenureScore Tenure score.
    /// @param _rand Random num.
    function addRebelInfo(uint256 _num, uint8 _tenureScore, uint256 _rand) external;

    /// @notice Get information about Banker.
    /// @param _num NFT number.
    function getBankerInfo(uint256 _num) external view returns (
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8
    );

    /// @notice Get information about Rebel.
    /// @param _num Rebel number.
    function getRebelInfo(uint256 _num) external view returns (uint8, uint8, uint8, uint8, uint8);

    /// @notice Get total Rebels count.
    function getRebelsCount() external view returns (uint256);

    /// @notice Set base URI for nfts.
    /// @param _baseUri String.
    function setBaseUri(string memory _baseUri) external;

    /// @notice Return array with nfts by owner.
    /// @param _address Address.
    /// @param _from Index from.
    /// @param _amount Nfts amount in array.
    function getNftsByOwner(address _address, uint256 _from, uint256 _amount) external view returns(uint256[] memory, bool[] memory);

    function isRebel(uint256 _index) external view returns (bool);

    function rebels(uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Interface for Randomizer contract
interface IRandomizer {
    /// @notice Get conventionally random number in range 0 <= _result < _maxNum
    /// @param _maxNum Maximal value
    function random(uint256 _maxNum) external returns (uint256 _result);

    /// @notice Get conventionally random number in range 0 <= _result < _maxNum. View.
    /// @param _maxNum Maximal value.
    /// @param _val Additional num.
    function random(uint256 _maxNum, uint256 _val) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for ProtectionProgram contract
interface IProtectionProgram {
    event BankerAdded(uint256 num);
    event RebelAdded(uint256 num);
    event BankerClaimed(uint256 num, bool isWithdrawn);
    event RebelClaimed(uint256 num, bool isWithdrawn);
    event TokensClaimed(uint256[] nums, bool isWithdrawn);

    /// @notice Set bankers reward for each second
    /// @param _bankerRewardPerSecond Reward per second. Wei
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external;

    /// @notice Set tax percent for rebels. When bankers claim rewards, part of rewards (tax) are collected by the rebels
    /// @param _taxPercent Percent in decimals. Where 10^27 = 100%
    function setTaxPercent(uint128 _taxPercent) external;

    /// @notice When banker claim reward, rebels have a chance to steal all of them. Set this chance
    /// @param _stealOnWithdrawChance Chance. Where 10^27 = 100%
    function setStealOnWithdrawChance(uint128 _stealOnWithdrawChance) external;

    /// @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time
    /// @param _withdrawLockupPeriod Time. Seconds
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external;

    /// @notice Add nfts to protection program
    /// @dev Will be added only existed nfts where sender is nft owner
    /// @param _nums Nfts nums
    function add(uint256[] calldata _nums) external;

    /// @notice Claim rewards for selected nfts
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function claim(uint256[] calldata _nums) external;

    /// @notice Claim rewards for selected nfts and withdraw from protection program
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function withdraw(uint256[] calldata _nums) external;

    /// @notice Calculate reward amount for nfts. On withdraw, part of reward can be stolen.
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    /// @return bankersReward Rewards for all bankers
    /// @return rebelsReward Rewards for all rebels
    function calculateRewards(uint256[] calldata _nums) external view returns (
        uint256 bankersReward,
        uint256 rebelsReward
    );

    /// @notice Return address of random rebel owner, dependent on rebel tenure score.
    function getRandomRebel() external returns (address);

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external;

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function withdrawStuckERC20(IERC20 _token, address _to, uint256 _amount) external;

    /// @notice Return array with nfts by owner.
    /// @param _address Address.
    /// @param _from Index from.
    /// @param _amount Nfts amount in array.
    function getNftsByOwner(address _address, uint256 _from, uint256 _amount) external view returns(uint256[] memory, bool[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
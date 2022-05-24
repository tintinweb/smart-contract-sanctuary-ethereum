pragma solidity ^0.8.0;

// import "./CoreRef.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IStkEth.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IStakingPool.sol";
import "./CoreRef.sol";
import "./interfaces/IIssuer.sol";
import "./KeysManager.sol";
import "./interfaces/IStakingPool.sol";

contract Oracle is IOracle, CoreRef {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    uint128 internal constant ETH2_DENOMINATION = 1e9;
    uint256 constant BASIS_POINT = 10000;
    uint256 public DEPOSIT_LIMIT = 32e18;

    struct BeaconData {
        uint64 epochsPerTimePeriod;
        uint64 slotsPerEpoch;
        uint64 secondsPerSlot;
        uint64 genesisTime;
    }

    uint256 lastCompletedEpochId;
    uint256 lastValidatorActivation;
    Counters.Counter private nonce;
    uint32 quorom;
    uint32 validatorQuorom;
    uint256 public override activatedValidators;
    uint32 pStakeCommission;
    uint32 valCommission;

    uint256 beaconEthBalance = 0;
    int256 beaconRewardBalance = 0;
    uint64 public activateValidatorDuration = 10 minutes;

    mapping(bytes32 => uint256) public candidates;
    mapping(bytes32 => bool) private submittedVotes;

    BeaconData beaconData;

    EnumerableSet.AddressSet private oracleMembers;
    uint256 public override pricePerShare = 1e18;

    event quoromUpdated(
        uint32 indexed latestQuorom,
        uint256 indexed nonce,
        uint32 indexed quorom
    );
    event oracleMemberAdded(
        address indexed newOracleMember,
        uint256 indexed oracleMemberLength
    );
    event oracleMemberRemoved(
        address indexed newOracleMember,
        uint256 indexed oracleMemberLength
    );
    event dataPushed(
        address indexed oracleAddress,
        uint256 latestEthBalance,
        uint256 indexed latestNonce,
        uint32 numberOfValidators,
        uint256 indexed lastCompletedEpoch
    );
    event validatorActivated(bytes[] _publicKey);
    event commissionsUpdated(uint32 _pStakeCommission, uint32 _valCommission);


    /// @notice constructor to initialize core
    /// @param _epochsPerTimePeriod epochs per time period
    /// @param _slotsPerEpoch slots per Epoch
    /// @param _genesisTime time of genesis
    /// @param _core core reference
    /// @param _pStakeCommission protocol commission
    /// @param _valCommission validator commissiom
    constructor(
        uint64 _epochsPerTimePeriod,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        address _core,
        uint32 _pStakeCommission,
        uint32 _valCommission
    ) CoreRef(_core) {
        beaconData.epochsPerTimePeriod = _epochsPerTimePeriod;
        beaconData.slotsPerEpoch = _slotsPerEpoch;
        beaconData.secondsPerSlot = _secondsPerSlot;
        beaconData.genesisTime = _genesisTime;
        require(
            _pStakeCommission < BASIS_POINT &&
            _valCommission < BASIS_POINT &&
            (_pStakeCommission + _valCommission) < BASIS_POINT,
            "Invalid values"
        );
        pStakeCommission = _pStakeCommission;
        valCommission = _valCommission;
        require(stkEth().approve(core().validatorPool(), type(uint256).max));
    }

    /// @notice fucntion that returns the 
    /// @return frameEpochId epoch id of the frame
    /// @return frameStartTime timestamp of start of time frame
    /// @return frameEndTime
    function getCurrentTimePeriod()
    external
    view
    returns (
        uint256 frameEpochId,
        uint256 frameStartTime,
        uint256 frameEndTime
    )
    {
        uint64 genesisTime = beaconData.genesisTime;
        uint64 secondsPerEpoch = beaconData.secondsPerSlot *
        beaconData.slotsPerEpoch;

        frameEpochId = _getFrameFirstEpochId(
            _getCurrentEpochId(beaconData),
            beaconData
        );
        frameStartTime = frameEpochId * secondsPerEpoch + genesisTime;
        frameEndTime =
        (frameEpochId + beaconData.epochsPerTimePeriod) *
        secondsPerEpoch +
        genesisTime -
        1;
    }

    /// @notice function to return the current nonce
    /// @return current nonce
    function currentNonce() external view returns (uint256) {
        return nonce.current();
    }


    /// @notice function to return oracle member length
    /// @return number of oracle members
    function oracleMemberLength() public view returns (uint256) {
        return oracleMembers.length();
    }


    /// @notice ...
    /// @return ...
    function Quorom() external view returns (uint32) {
        return quorom;
    }


    /// @notice function to return the current nonce
    /// @return current nonce
    function ValidatorQuorom() external view returns (uint32) {
        return validatorQuorom;
    }


    /// @notice function to return the current nonce
    /// @return epochsPerTimePeriod
    /// @return slotsPerEpoch
    /// @return secondsPerSlot
    /// @return genesisTime
    function getBeaconData()
    external
    view
    returns (
        uint64 epochsPerTimePeriod,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    )
    {
        return (
        beaconData.epochsPerTimePeriod,
        beaconData.slotsPerEpoch,
        beaconData.secondsPerSlot,
        beaconData.genesisTime
        );
    }


    /// @notice function to return the frame id of first epoch
    /// @return ...
    function _getFrameFirstEpochId(
        uint256 _epochId,
        BeaconData memory _beaconSpec
    ) internal view returns (uint256) {
        return
        (_epochId / _beaconSpec.epochsPerTimePeriod) *
        _beaconSpec.epochsPerTimePeriod;
    }

    /// @notice function to return the current epoch id
    /// @return ...
    function _getCurrentEpochId(BeaconData memory _beaconSpec)
    internal
    view
    returns (uint256)
    {
        return
        (block.timestamp - beaconData.genesisTime) /
        (beaconData.slotsPerEpoch * beaconData.secondsPerSlot);
    }

    /// @notice function to return the last completed epoch id
    /// @return lastCompletedEpochId
    function getLastCompletedEpochId() external view returns (uint256) {
        return lastCompletedEpochId;
    }


    /// @notice function to return the total ether balance
    /// @return beaconEthBalance 
    function getTotalEther() external view returns (uint256) {
        return beaconEthBalance;
    }

    function getTotalRewards() external view returns (int256) {
        return beaconRewardBalance;
    }


    /// @notice function to update latestQuorom
    /// @param latestQuorom ...
    function updateQuorom(uint32 latestQuorom) external onlyGovernor {
        require(latestQuorom >= 0, "Quorom less that 0");
        quorom = latestQuorom;
        emit quoromUpdated(latestQuorom, nonce.current(), quorom);
    }

    function updateValidatorQuorom(uint32 latestQuorom) external onlyGovernor {
        require(latestQuorom >= 0, "Quorom less that 0");
        validatorQuorom = latestQuorom;
    }

    function updateCommissions(uint32 _pStakeCommission, uint32 _valCommission)
    external
    onlyGovernor
    {
        require(
            _pStakeCommission < BASIS_POINT &&
            _valCommission < BASIS_POINT &&
            (_pStakeCommission + _valCommission) < BASIS_POINT,
            "Invalid values"
        );
        pStakeCommission = _pStakeCommission;
        valCommission = _valCommission;
        emit commissionsUpdated(_pStakeCommission, _valCommission);
    }

    function addOracleMember(address newOracleMember)
    external
    override
    onlyGovernor
    {
        require(oracleMembers.add(newOracleMember), "Oracle member already present");
        emit oracleMemberAdded(newOracleMember, oracleMemberLength());
    }

    function removeOracleMember(address oracleMemberToDelete)
    external
    override
    onlyGovernor
    {
        require(oracleMembers.remove(oracleMemberToDelete), "Oracle member not present");
        emit oracleMemberRemoved(oracleMemberToDelete, oracleMemberLength());
    }


    /// @notice function to check if adress is oracle member
    /// @return oracleMember  
    function isOracle(address member) public view returns (bool) {
        return oracleMembers.contains(member);
    }


    /// @notice function for minting of StkEth for Eth
    /// @param amount ...
    /// @param user ...
    /// @param newPricePerShare new price per share
    function mintStkEthForEth(
        uint256 amount,
        address user,
        uint256 newPricePerShare
    ) internal returns (uint256 stkEthToMint){
        stkEthToMint = (amount * 1e18) / newPricePerShare;
        stkEth().mint(user, stkEthToMint);
    }


    /// @notice function for slashing balance of a pool 
    /// @param deltaEth difference in eth balance since last distribution
    /// @param beaconRewardEarned ...
    function slash(uint256 deltaEth,int256 beaconRewardEarned) internal {
        //
        //        uint256 stkEthToSlash = (deltaEth * 1e18) / pricePerShare;
        uint256 price = pricePerShare;
        if (beaconRewardEarned>0) {
            price = (IIssuer(core().issuer()).ethStakedIssuer() + uint256(beaconRewardEarned)) * 1e18 / (IStkEth(core().stkEth()).totalSupply());
        }
        else {
            price = (IIssuer(core().issuer()).ethStakedIssuer() - uint256(beaconRewardEarned*int256(-1))) * 1e18 / (IStkEth(core().stkEth()).totalSupply());
        }
        //  todo: in future for insurance mechanism
        //        deltaEth = deltaEth - ((stkEthBurned * pricePerShare) / 1e18);
        //        uint256 percentChange = deltaEth * 1e18 / rewardBase;
        //        pricePerShare = (pricePerShare * (1e18 - percentChange)) / 1e18;
        //
        //        uint256 preTotal = stkEth().totalSupply();
        //
        ////        IStakingPool(core().validatorPool()).slash(stkEthToSlash);
        //
        //        uint256 stkEthBurned = preTotal - stkEth().totalSupply();
        //        // If staking pool not able to burn enough stkEth, then adjust pricePerShare for remainingSupply
        //        if (stkEthBurned < stkEthToSlash) {
        //            deltaEth = deltaEth - ((stkEthBurned * pricePerShare) / 1e18);
        //            uint256 percentChange = deltaEth * 1e18 / rewardBase;
        //            pricePerShare = (pricePerShare * (1e18 - percentChange)) / 1e18;
        //        }
        pricePerShare = price;
        emit Slash(deltaEth,pricePerShare,block.timestamp);
    }

    /// @notice function to distribute rewards by setting price per share
    /// @param deltaEth difference in eth balance since last distribution
    /// @param beaconRewardEarned ...
    function distributeRewards(uint256 deltaEth, int256 beaconRewardEarned) internal {
        // calculate fees need to be deducted in terms of stkEth which will be minted for treasury & validators

        uint256 valEthShare = (valCommission * deltaEth) / BASIS_POINT;
        uint256 protocolEthShare = (pStakeCommission * deltaEth) / BASIS_POINT;
        uint256 price = pricePerShare;
        if (beaconRewardEarned > 0) {
            price = (IIssuer(core().issuer()).ethStakedIssuer() + uint256(beaconRewardEarned) - (valEthShare + protocolEthShare)) * 1e18 / IStkEth(core().stkEth()).totalSupply();
        }
        else{
            price = (IIssuer(core().issuer()).ethStakedIssuer() - uint256(beaconRewardEarned*int256(-1)) - (valEthShare + protocolEthShare)) * 1e18 / IStkEth(core().stkEth()).totalSupply();
        }
        uint256 stkEthMinted = mintStkEthForEth(valEthShare, address(this), price);
        IStakingPool(core().validatorPool()).updateRewardPerValidator(stkEthMinted);
        mintStkEthForEth(protocolEthShare, core().pstakeTreasury(), price);
        pricePerShare = price;
        emit Distribute(deltaEth,pricePerShare,block.timestamp);
    }


    function updateValidatorActivationDuration(uint64 activationDuration) external onlyGovernor {
        activateValidatorDuration = activationDuration;
    }

    /// @notice function to activate an array of validators
    /// @param _publicKeys public key array of validators
    function activateValidator(bytes[] memory _publicKeys) external override {
        require(isOracle(msg.sender), "Not oracle Member");
        require(
            block.timestamp >= lastValidatorActivation + activateValidatorDuration,
            "voted before minimum duration"
        );
        bytes32 candidateId = keccak256(abi.encode(_publicKeys));
        bytes32 voteId = keccak256(abi.encode(msg.sender, candidateId));
        require(!submittedVotes[voteId], "Oracles: already voted");

        // mark vote as submitted, update candidate votes number
        submittedVotes[voteId] = true;
        uint256 candidateNewVotes = candidates[candidateId] + 1;
        candidates[candidateId] = candidateNewVotes;
        uint256 oracleMemberSize = oracleMemberLength();

        if (candidateNewVotes >= validatorQuorom) {
            delete submittedVotes[voteId];

            for (uint256 i = 0; i < oracleMemberSize; i++) {
                delete submittedVotes[
                keccak256(
                    abi.encode(
                        oracleMembers.at(i),
                        candidateId
                    )
                )
                ];
            }

            // clean up candidate
            delete candidates[candidateId];
            IKeysManager(core().keysManager()).activateValidator(_publicKeys);
            lastValidatorActivation = block.timestamp;
            emit validatorActivated(_publicKeys);
        }
    }


    /// @notice function to push data to oracle
    /// @param latestEthBalance latest balance of eth 
    /// @param latestNonce latest nonce number
    /// @param numberOfValidators count of validators
    function pushData(
        uint256 latestEthBalance,
        uint256 latestNonce,
        uint32 numberOfValidators
    ) external override {
        require(isOracle(msg.sender), "Not oracle Member");
        uint256 currentFrameEpochId = _getCurrentEpochId(beaconData);

        require(
            currentFrameEpochId > lastCompletedEpochId,
            "Cannot push to Epoch less that already commited"
        );
        require(
            currentFrameEpochId >=
            _getFrameFirstEpochId(currentFrameEpochId, beaconData)
        );
        require(
            currentFrameEpochId <
            _getFrameFirstEpochId(currentFrameEpochId, beaconData) +
            beaconData.epochsPerTimePeriod
        );

        require(latestNonce == nonce.current(), "incorrect Nonce");
        require(
            activatedValidators <= numberOfValidators,
            "Invalid numberOfValidators"
        );
        latestEthBalance = latestEthBalance * ETH2_DENOMINATION;
        bytes32 candidateId = keccak256(
            abi.encode(nonce, latestEthBalance, numberOfValidators)
        );
        bytes32 voteId = keccak256(abi.encode(msg.sender, candidateId));
        require(!submittedVotes[voteId], "Oracles: already voted");

        // mark vote as submitted, update candidate votes number
        submittedVotes[voteId] = true;
        uint256 candidateNewVotes = candidates[candidateId] + 1;
        candidates[candidateId] = candidateNewVotes;
        uint256 oracleMemberSize = oracleMemberLength();
        emit dataPushed(msg.sender, latestEthBalance, latestNonce, numberOfValidators, lastCompletedEpochId);
        if (candidateNewVotes >= quorom) {
            // clean up votes
            delete submittedVotes[voteId];

            for (uint256 i = 0; i < oracleMemberSize; i++) {
                delete submittedVotes[
                keccak256(
                    abi.encode(
                        oracleMembers.at(i),
                        candidateId
                    )
                )
                ];
            }

            // clean up candidate
            nonce.increment();
            delete candidates[candidateId];

            uint256 rewardBase = beaconEthBalance +
            (DEPOSIT_LIMIT * (numberOfValidators - activatedValidators));
            if (activatedValidators < numberOfValidators) {
                IIssuer(core().issuer()).updatePendingValidator(
                    numberOfValidators - activatedValidators
                );
            }

            activatedValidators = numberOfValidators;

            if (latestEthBalance > rewardBase) {
                beaconRewardBalance = beaconRewardBalance + int(latestEthBalance - rewardBase);
                distributeRewards(latestEthBalance - rewardBase, beaconRewardBalance);
                //                beaconRewardBalance = beaconRewardBalance + (latestEthBalance - rewardBase);
            } else if (latestEthBalance < rewardBase) {
                beaconRewardBalance = beaconRewardBalance - int(rewardBase - latestEthBalance);
                slash(rewardBase - latestEthBalance, beaconRewardBalance);
            }

            beaconEthBalance = latestEthBalance;
            lastCompletedEpochId = currentFrameEpochId;

        }
        uint256 timeElapsed = (currentFrameEpochId - lastCompletedEpochId) *
        beaconData.slotsPerEpoch *
        beaconData.secondsPerSlot;
    }


    /// @notice update the specification parameters for beacon chain data
    /// @param epochsPerTimePeriod ...
    /// @param slotsPerEpoch ...
    /// @param secondsPerSlot ...
    /// @param genesisTime ...
    function updateBeaconChainData(
        uint64 epochsPerTimePeriod,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    ) external onlyGovernor {
        _setBeaconSpec(
            epochsPerTimePeriod,
            slotsPerEpoch,
            secondsPerSlot,
            genesisTime
        );
    }



    /// @notice sets the specification parameters for beacon chain data
    /// @param _epochsPerTimePeriod ...
    /// @param _slotsPerEpoch ...
    /// @param _secondsPerSlot ...
    /// @param _genesisTime ...
    function _setBeaconSpec(
        uint64 _epochsPerTimePeriod,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) internal {
        require(_epochsPerTimePeriod > 0);
        require(_slotsPerEpoch > 0);
        require(_secondsPerSlot > 0);
        require(_genesisTime > 0);

        beaconData.epochsPerTimePeriod = _epochsPerTimePeriod;
        beaconData.slotsPerEpoch = _slotsPerEpoch;
        beaconData.secondsPerSlot = _secondsPerSlot;
        beaconData.genesisTime = _genesisTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICoreRef.sol";

/// @title Oracle interface
/// @author Ankit Parashar
interface IStkEth is IERC20{

    function pricePerShare() external view returns (uint256 amount);

    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Oracle interface
/// @author Ankit Parashar
interface IOracle {

    event Distribute(uint256 amount,uint256 pricePerShare,uint256 timestamp);
    event Slash(uint256 amount,uint256 pricePerShare,uint256 timestamp);

    function pricePerShare() external view returns (uint256);

    function activatedValidators() external view returns (uint256);

    function addOracleMember(address newOracleMember) external;

    function removeOracleMember(address oracleMeberToDelete) external;

    function pushData(
        uint256 latestEthBalance,
        uint256 latestNonce,
        uint32 numberOfValidators
    ) external;

    function activateValidator(bytes[] calldata _publicKeys) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Staking Pool interface
/// @author Ankit Parashar
interface IStakingPool {
    
    function slash(uint256 amount) external;

    function numOfValidatorAllowed(address usr) external returns (uint256);

    function claimAndUpdateRewardDebt(address usr) external;

    function updateRewardPerValidator(uint256 newReward) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICoreRef.sol";
import "./interfaces/ICore.sol";
import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract CoreRef is ICoreRef, Pausable {

    ICore private _core;

    constructor(address core){
        require(core != address(0), "CoreRef: Zero address");
        _core = ICore(core);
        emit SetCore(core);
    }

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyKeyAdmin() {
        require(_core.isKeyAdmin(msg.sender), "Permissions: Caller is not a key admin");
        _;
    }

    modifier onlyNodeOperator() {
        require(_core.isNodeOperator(msg.sender), "Permissions: Caller is not a Node Operator");
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGovernor {
        _unpause();
    }

    /// @notice set new Core reference address
    /// @param core the new core address
    function setCore(address core) external override onlyGovernor {
        _core = ICore(core);
        emit SetCore(core);
    }

    function stkEth() public view override returns (IStkEth) {
        return _core.stkEth();
    }

    function core() public view override returns (ICore) {
        return _core;
    }

    function oracle() public view override returns (IOracle) {
        return IOracle(_core.oracle());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Issuer interface
/// @author Ankit Parashar
interface IIssuer {

    event SetMinActivationDeposit(uint256 _minActivatingDeposit);
    event SetPendingValidatorsLimit(uint256 _pendingValidatorsLimit);
    event UpdatePendingValidators(uint256 _pendingValidators);
    event Stake(address indexed_user,uint256 amount,uint256 block_time);
    function updatePendingValidator(uint256 newActiveValidators) external;

    function pendingValidators() external view returns (uint256);
    function ethStakedIssuer() external view returns (uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoreRef.sol";
import "./interfaces/IKeysManager.sol";
import { IStakingPool } from "./interfaces/IStakingPool.sol";

/// @title Keys manager contract
/// @author ...
/// @notice Contract for on managing public keys, signatures
contract KeysManager is IKeysManager, CoreRef {
    mapping(bytes => Validator) public _validators;

    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant SIGNATURE_LENGTH = 96;
    uint256 public constant VALIDATOR_DEPOSIT = 31e18;

    event AddValidator(bytes publicKey, bytes signature, address nodeOperator);
    event ActivateValidator(bytes[] publicKey);
    event DepositValidator(bytes publicKey);

    mapping (address => uint256) public override nodeOperatorValidatorCount;



    /// @notice constructor to initialize Core
    /// @param _core address of the core
    constructor(address _core) public CoreRef(_core) {}



    /// @notice function that returns public key of a particular validator.
    /// @param publicKey public key of the validator.
    function validators(bytes calldata publicKey)
        external
        view
        override
        returns (Validator memory)
    {
        return _validators[publicKey];
    }


    /// @notice function to add a new validator
    /// @param publicKey public key of the validator
    /// @param signature signature with private key needed for eth2 deposit
    /// @param nodeOperator address of the node operator
    function addValidator(
        bytes calldata publicKey,
        bytes calldata signature,
        address nodeOperator
    ) external override onlyNodeOperator {
        Validator memory _validator = _validators[publicKey];
        require(
            _validator.state == State.INVALID,
            "KeysManager: validator already exist"
        );

        _validator.state = State.VALID;
        _validator.signature = signature;
        _validator.nodeOperator = nodeOperator;
        _validator.deposit_root = calculateDepositDataRoot(publicKey, signature);

        _validators[publicKey] = _validator;
        emit AddValidator(publicKey, signature, nodeOperator);
    }




    /// @notice function for activating the status of an array of validator public keys
    /// @param publicKeys public keys array of validators.
    function activateValidator(bytes[] memory publicKeys) external override {
        require(
            msg.sender == core().oracle(),
            "KeysManager: Only oracle can activate"
        );
        for (uint256 i = 0; i < publicKeys.length; i++) {
            Validator storage validator = _validators[publicKeys[i]];
            require(validator.state == State.VALID, "KeysManager: Validator not in valid state");
            validator.state = State.ACTIVATED;
        }
        emit ActivateValidator(publicKeys);
    }



    /// @notice set status of validator to deposited
    /// @param publicKey public key of the validator.
    function depositValidator(bytes memory publicKey) external override {
        require(
            msg.sender == core().issuer(),
            "KeysManager: Only issuer can activate"
        );

        Validator storage validator = _validators[publicKey];
        
        require(
            IStakingPool(core().validatorPool()).numOfValidatorAllowed(validator.nodeOperator) > 
            nodeOperatorValidatorCount[validator.nodeOperator],
            "KeysManager: validator deposit not added by node operator"
        );
        
        require(
            validator.state == State.ACTIVATED,
            "KeysManager: Key not activated"
        );
        validator.state = State.DEPOSITED;
        nodeOperatorValidatorCount[validator.nodeOperator] += 1;

        IStakingPool(core().validatorPool()).claimAndUpdateRewardDebt(validator.nodeOperator);

        emit DepositValidator(publicKey);
    }


    /// @notice function to return the deposit data root node
    /// @return depositRoot is deposit root node 
    function calculateDepositDataRoot(
        bytes calldata pubKey,
        bytes calldata signature
    ) internal returns (bytes32 depositRoot) {
        uint256 deposit_amount = VALIDATOR_DEPOSIT / 1 gwei;
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));

        bytes32 withdrawal_credentials = core().withdrawalCredential();
        bytes32 pubkey_root = sha256(abi.encodePacked(pubKey, bytes16(0)));
        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature[:64])),
                sha256(abi.encodePacked(signature[64:], bytes32(0)))
            )
        );
        depositRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
                sha256(abi.encodePacked(amount, bytes24(0), signature_root))
            )
        );
        require(pubKey.length == 48, "DepositContract: invalid pubkey length");
        require(
            signature.length == 96,
            "DepositContract: invalid signature length"
        );
        require(
            withdrawal_credentials.length == 32,
            "DepositContract: invalid withdrawal_credentials length"
        );
        
    }


    /// @notice function to convert address to Bytes
    /// @param a address to be converted to bytes.
    function toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }


    /// @notice function to convert to integer to little endian 64 bytes format.
    /// @param value is the integer number.
    /// @return ret is 8 byte array.
    function to_little_endian_64(uint64 value)
        internal
        pure
        returns (bytes memory ret)
    {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
    

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICore.sol";
import "./IStkEth.sol";
import "./IOracle.sol";

/// @title CoreRef interface
/// @author Ankit Parashar
interface ICoreRef {

    event SetCore(address _core);

    function setCore(address core) external;

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function stkEth() external view returns (IStkEth);

    function oracle() external view returns (IOracle);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPermissions.sol";
import "./IStkEth.sol";

/// @title Core interface
/// @author Ankit Parashar
interface ICore is IPermissions {

    event SetCoreContract(bytes32 _key, address indexed _address);

    event SetWithdrawalCredential(bytes32 _withdrawalCreds);

    function stkEth() external view returns(IStkEth);

    function oracle() external view returns(address);

    function withdrawalCredential() external view returns(bytes32);

    function keysManager() external view returns(address);

    function pstakeTreasury() external view returns(address);

    function validatorPool() external view returns(address);

    function issuer() external view returns(address);

    function set(bytes32 _key, address _address) external;

    function coreContract(bytes32 key) external view returns (address);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Permissions interface
/// @author Ankit Parashar
interface IPermissions {

    // ----------- Governor only state changing functions -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantNodeOperator(address nodeOperator) external;

    function grantKeyAdmin(address keyAdmin) external;

    function revokeGovernor(address governor) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokeNodeOperator(address nodeOperator) external;

    function revokeKeyAdmin(address keyAdmin) external;

    // ----------- Getters -----------

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isBurner(address _address) external view returns (bool);

    function isNodeOperator(address _address) external view returns (bool);

    function isKeyAdmin(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KeysManager interface
/// @author Ankit Parashar
interface IKeysManager {

    enum State { INVALID, VALID, ACTIVATED, DEPOSITED }

    struct Validator {
        State state;
        bytes signature;
        address nodeOperator;
        bytes32 deposit_root;
    }

    function validators(bytes calldata publicKey) external view returns (Validator memory);

    function addValidator(bytes calldata publicKey, bytes calldata signature,  address nodeOperator) external;

    function activateValidator(bytes[] memory publicKey) external;

    function depositValidator(bytes memory publicKey) external;

    function nodeOperatorValidatorCount(address usr) external returns (uint256);
}
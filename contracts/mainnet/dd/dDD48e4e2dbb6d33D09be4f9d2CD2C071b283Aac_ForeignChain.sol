// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Chain.sol";

/// @dev contract for foreign chains
contract ForeignChain is Chain {
    error NotSupported();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) Chain(_contractRegistry, _padding, _requiredSignatures, _allowForMixedType) {
        // no additional configuration needed
    }

    /// @inheritdoc BaseChain
    function isForeign() external pure override returns (bool) {
        return true;
    }

    /// @inheritdoc Chain
    /// @notice this method is made to be compatible with MasterChain, but it does not return full data eg validators
    /// data will be missing.
    /// @return blockNumber `block.number`
    /// @return timePadding `this.padding`
    /// @return lastDataTimestamp timestamp for last submitted consensus
    /// @return lastId ID of last submitted consensus
    /// @return nextLeader will be always address(0)
    /// @return nextBlockId block ID for `block.timestamp + padding`
    /// @return validators array will be always empty
    /// @return powers array will be always empty
    /// @return locations array will be always empty
    /// @return staked total UMB staked by validators
    /// @return minSignatures `this.requiredSignatures`
    function getStatus() external view override returns(
        uint256 blockNumber,
        uint32 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        address nextLeader,
        uint32 nextBlockId,
        address[] memory validators,
        uint256[] memory powers,
        string[] memory locations,
        uint256 staked,
        uint16 minSignatures
    ) {
        ConsensusData memory data = _consensusData;

        blockNumber = block.number;
        timePadding = data.padding;
        lastId = data.lastTimestamp;
        lastDataTimestamp = lastId;
        minSignatures = _REQUIRED_SIGNATURES;

        staked = stakingBank.totalSupply();
        uint256 numberOfValidators = 0;
        powers = new uint256[](numberOfValidators);
        validators = new address[](numberOfValidators);
        locations = new string[](numberOfValidators);
        nextLeader = address(0);

        unchecked {
            // we will not overflow with timestamp in a lifetime
            nextBlockId = lastId + data.padding + 1;
        }
    }

    function getLeaderIndex(uint256, uint256) public pure override returns (uint256) {
        revert NotSupported();
    }

    function getLeaderAddressAtTime(uint256) public pure override returns (address) {
        revert NotSupported();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./BaseChain.sol";

contract Chain is BaseChain {
    IStakingBank public immutable stakingBank;

    event LogMint(address indexed minter, uint256 blockId, uint256 staked, uint256 power);
    event LogVoter(uint256 indexed blockId, address indexed voter, uint256 vote);

    error NotEnoughSignatures();
    error SignaturesOutOfOrder();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    /// @param _allowForMixedType we have two "types" of Chain: HomeChain and ForeignChain, when we redeploying
    /// we don't want to mix up them, so we checking, if new Chain has the same type as current one.
    /// However, when we will be switching from one homechain to another one, we have to allow for this mixing up.
    /// This flag will tell contract, if this is the case.
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) BaseChain(_contractRegistry, _padding, _requiredSignatures, _allowForMixedType) {
        stakingBank = IStakingBank(_contractRegistry.requireAndGetAddress("StakingBank"));
    }

    /// @dev method for submitting consensus data
    /// @param _dataTimestamp consensus timestamp, this is time for all data in merkle tree including FCDs
    /// @param _root merkle root
    /// @param _keys FCDs keys
    /// @param _values FCDs values
    /// @param _v array of `v` part of validators signatures
    /// @param _r array of `r` part of validators signatures
    /// @param _s array of `s` part of validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function submit(
        uint32 _dataTimestamp,
        bytes32 _root,
        bytes32[] memory _keys,
        uint256[] memory _values,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) external {
        // below two checks are only for pretty errors, so we can safe gas and allow for raw revert
        // if (_keys.length != _values.length) revert ArraysDataDoNotMatch();
        // if (_v.length != _r.length || _r.length != _s.length) revert ArraysDataDoNotMatch();

        _verifySubmitTimestampAndIncSequence(_dataTimestamp);

        // we can't expect minter will have exactly the same timestamp
        // but for sure we can demand not to be off by a lot, that's why +3sec
        // temporary remove this condition, because recently on ropsten we see cases when minter/node
        // can be even 100sec behind
        // require(_dataTimestamp <= block.timestamp + 3,
        //   string(abi.encodePacked("oh, so you can predict the future:", _dataTimestamp - block.timestamp + 48)));

        bytes memory testimony = abi.encodePacked(_dataTimestamp, _root);

        for (uint256 i = 0; i < _keys.length;) {
            if (uint224(_values[i]) != _values[i]) revert FCDOverflow();

            fcds[_keys[i]] = FirstClassData(uint224(_values[i]), _dataTimestamp);
            testimony = abi.encodePacked(testimony, _keys[i], _values[i]);

            unchecked {
                // we can't pass enough data to overflow
                i++;
            }
        }

        uint256 signatures = 0;
        uint256 power = 0;
        //uint256 staked = stakingBank.totalSupply();
        bytes32 affidavit = keccak256(testimony);

        address prevSigner = address(0x0);

        for (uint256 i; i < _v.length;) {
            address signer = recoverSigner(affidavit, _v[i], _r[i], _s[i]);
            uint256 balance = stakingBank.balanceOf(signer);

            if (prevSigner >= signer) revert SignaturesOutOfOrder();

            prevSigner = signer;

            if (balance == 0) {
                unchecked { i++; }
                continue;
            }

            signatures++;
            emit LogVoter(uint256(_dataTimestamp), signer, balance);

            unchecked {
                // we can't overflow because that means token overflowed
                // and even if we do, we will get lower power
                power += balance;
                i++;
            }
        }

        if (signatures < _REQUIRED_SIGNATURES) revert NotEnoughSignatures();

        emit LogMint(msg.sender, _dataTimestamp, stakingBank.totalSupply(), power);

        // TODO remember to protect against flash loans when DPoS will be in place
        // we turn on power once we have DPoS in action, we have PoA now
        // require(power * 100 / staked >= 66, "not enough power was gathered");

        roots[_dataTimestamp] = _root;
        _consensusData.lastTimestamp = _dataTimestamp;
    }

    /// @inheritdoc BaseChain
    function isForeign() external pure virtual override returns (bool) {
        return false;
    }

    /// @dev helper method that returns all important data about current state of contract
    /// @return blockNumber `block.number`
    /// @return timePadding `this.padding`
    /// @return lastDataTimestamp timestamp for last submitted consensus
    /// @return lastId ID of last submitted consensus
    /// @return nextLeader leader for `block.timestamp + 1`
    /// @return nextBlockId block ID for `block.timestamp + padding`
    /// @return validators array of all validators addresses
    /// @return powers array of all validators powers
    /// @return locations array of all validators locations
    /// @return staked total UMB staked by validators
    /// @return minSignatures `this.requiredSignatures`
    function getStatus() external view virtual returns(
        uint256 blockNumber,
        uint32 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        address nextLeader,
        uint32 nextBlockId,
        address[] memory validators,
        uint256[] memory powers,
        string[] memory locations,
        uint256 staked,
        uint16 minSignatures
    ) {
        ConsensusData memory data = _consensusData;

        blockNumber = block.number;
        timePadding = data.padding;
        lastId = data.lastTimestamp;
        lastDataTimestamp = lastId;
        minSignatures = _REQUIRED_SIGNATURES;

        staked = stakingBank.totalSupply();
        uint256 numberOfValidators = stakingBank.getNumberOfValidators();
        powers = new uint256[](numberOfValidators);
        validators = new address[](numberOfValidators);
        locations = new string[](numberOfValidators);

        for (uint256 i = 0; i < numberOfValidators;) {
            validators[i] = stakingBank.addresses(i);
            (, locations[i]) = stakingBank.validators(validators[i]);
            powers[i] = stakingBank.balanceOf(validators[i]);

            unchecked {
                // we will run out of gas before overflow happen
                i++;
            }
        }

        unchecked {
            // we will not overflow with timestamp in a lifetime
            nextBlockId = lastId + data.padding + 1;

            nextLeader = numberOfValidators > 0
                // we will not overflow with timestamp in a lifetime
                ? validators[getLeaderIndex(numberOfValidators, block.timestamp + 1)]
                : address(0);
        }
    }

    /// @return address of leader for next second
    function getNextLeaderAddress() external view returns (address) {
        return getLeaderAddressAtTime(block.timestamp + 1);
    }

    /// @return address of current leader
    function getLeaderAddress() external view returns (address) {
        return getLeaderAddressAtTime(block.timestamp);
    }

    /// @param _numberOfValidators total number of validators
    /// @param _timestamp timestamp for which you want to calculate index
    /// @return leader index, use it for StakingBank.addresses[index] to fetch leader address
    function getLeaderIndex(uint256 _numberOfValidators, uint256 _timestamp) public view virtual returns (uint256) {
        ConsensusData memory data = _consensusData;

        unchecked {
            // we will not overflow on `timestamp` and `padding` in a life time
            // timePadding + 1 => because padding is a space between blocks,
            // so next round starts on first block after padding
            // TODO will it work for off-chain??
            uint256 validatorIndex = data.sequence + (_timestamp - data.lastTimestamp) / (data.padding + 1);

            return validatorIndex % _numberOfValidators;
        }
    }

    // @todo - properly handled non-enabled validators, newly added validators, and validators with low stake
    /// @param _timestamp timestamp for which you want to calculate leader address
    /// @return leader address for provider timestamp
    function getLeaderAddressAtTime(uint256 _timestamp) public view virtual returns (address) {
        uint256 numberOfValidators = stakingBank.getNumberOfValidators();

        if (numberOfValidators == 0) {
            return address(0x0);
        }

        uint256 validatorIndex = getLeaderIndex(numberOfValidators, _timestamp);

        return stakingBank.addresses(validatorIndex);
    }

    /// @dev we had stack too deep in `submit` so this method was created as a solution
    // we increasing `_consensusData.sequence` here so we don't have to read sequence again in other place
    function _verifySubmitTimestampAndIncSequence(uint256 _dataTimestamp) internal {
        ConsensusData memory data = _consensusData;

        // `data.lastTimestamp` must be setup either on deployment
        // or via cloning from previous contract
        if (data.lastTimestamp == 0) revert ContractNotReady();

        unchecked {
            // we will not overflow with timestamp and padding in a life time
            if (data.lastTimestamp + data.padding >= _dataTimestamp) revert BlockSubmittedToFastOrDataToOld();
        }

        unchecked {
            // we will not overflow in a life time
            _consensusData.sequence = uint32(data.sequence + 1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@umb-network/toolbox/dist/contracts/lib/ValueDecoder.sol";

import "./interfaces/IBaseChainV1.sol";
import "./interfaces/IStakingBank.sol";
import "./extensions/Registrable.sol";
import "./Registry.sol";

abstract contract BaseChain is Registrable, Ownable {
    using ValueDecoder for bytes;
    using ValueDecoder for uint224;
    using MerkleProof for bytes32[];

    /// @param root merkle root for consensus
    /// @param dataTimestamp consensus timestamp
    struct Block {
        bytes32 root;
        uint32 dataTimestamp;
    }

    /// @param value FCD value
    /// @param dataTimestamp FCD timestamp
    struct FirstClassData {
        uint224 value;
        uint32 dataTimestamp;
    }

    /// @param blocksCountOffset number of all blocks that were generated before switching to this contract
    /// @param sequence is a total number of blocks (consensus rounds) including previous contracts
    /// @param lastTimestamp is a timestamp of last submitted block
    /// @param padding number of seconds that need to pass before new submit will be possible
    /// @param deprecated flag that changes to TRUE on `unregister`, when TRUE submissions are not longer available
    struct ConsensusData {
        uint32 blocksCountOffset;
        uint32 sequence;
        uint32 lastTimestamp;
        uint32 padding;
        bool deprecated;
    }

    uint256 constant public VERSION = 2;

    bool internal immutable _ALLOW_FOR_MIXED_TYPE; // solhint-disable-line var-name-mixedcase

    bytes4 constant private _VERSION_SELECTOR = bytes4(keccak256("VERSION()"));

    /// @dev minimal number of signatures required for accepting submission (PoA)
    uint16 internal immutable _REQUIRED_SIGNATURES; // solhint-disable-line var-name-mixedcase

    ConsensusData internal _consensusData;

    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    /// @dev block id (consensus ID) => root
    /// consensus ID is at the same time consensus timestamp
    mapping(uint256 => bytes32) public roots;

    /// @dev FCD key => FCD data
    mapping(bytes32 => FirstClassData) public fcds;

    event LogDeprecation(address indexed deprecator);
    event LogPadding(address indexed executor, uint32 timePadding);

    error ArraysDataDoNotMatch();
    error AlreadyDeprecated();
    error AlreadyRegistered();
    error BlockSubmittedToFastOrDataToOld();
    error ContractNotReady();
    error FCDOverflow();
    error InvalidContractType();
    error NoChangeToState();
    error OnlyOwnerOrRegistry();
    error UnregisterFirst();

    modifier onlyOwnerOrRegistry () {
        if (msg.sender != address(contractRegistry) && msg.sender != owner()) revert OnlyOwnerOrRegistry();
        _;
    }

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) Registrable(_contractRegistry) {
        _ALLOW_FOR_MIXED_TYPE = _allowForMixedType;
        _REQUIRED_SIGNATURES = _requiredSignatures;

        _setPadding(_padding);

        BaseChain oldChain = BaseChain(_contractRegistry.getAddress("Chain"));

        if (address(oldChain) == address(0)) {
            // if this is first contract in sidechain, then we need to initialise lastTimestamp so submission
            // can be possible
            _consensusData.lastTimestamp = uint32(block.timestamp) - _padding - 1;
        }
    }

    /// @dev setter for `padding`
    function setPadding(uint16 _padding) external {
        _setPadding(_padding);
    }

    /// @notice if this method needs to be called manually (not from Registry)
    /// it is important to do it as part of tx batch
    /// eg using multisig, we should prepare set of transactions and confirm them all at once
    /// @inheritdoc Registrable
    function register() external override onlyOwnerOrRegistry {
        address oldChain = contractRegistry.getAddress("Chain");

        // registration must be done before address in registry is replaced
        if (oldChain == address(this)) revert AlreadyRegistered();

        if (oldChain == address(0x0)) {
            return;
        }

        _cloneLastDataFromPrevChain(oldChain);
    }

    /// @inheritdoc Registrable
    function unregister() external override onlyOwnerOrRegistry {
        // in case we deprecated contract manually, we simply return
        if (_consensusData.deprecated) return;

        address newChain = contractRegistry.getAddress("Chain");
        // unregistering must be done after address in registry is replaced
        if (newChain == address(this)) revert UnregisterFirst();

        // TODO:
        // I think we need to remove restriction for type (at least once)
        // when we will switch to multichain architecture

        if (!_ALLOW_FOR_MIXED_TYPE) {
            // can not be replaced with chain of different type
            if (BaseChain(newChain).isForeign() != this.isForeign()) revert InvalidContractType();
        }

        _consensusData.deprecated = true;
        emit LogDeprecation(msg.sender);
    }

    /// @notice it allows to deprecate contract manually
    /// Only new Registry calls `unregister()` where we set deprecated to true
    /// In old Registries we don't have this feature, so in order to safely redeploy new Chain
    /// we will have to first deprecate current contract manually, then register new contract
    function deprecate() external onlyOwnerOrRegistry {
        if (_consensusData.deprecated) revert AlreadyDeprecated();

        _consensusData.deprecated = true;
        emit LogDeprecation(msg.sender);
    }

    /// @dev getter for `_consensusData`
    function getConsensusData() external view returns (ConsensusData memory) {
        return _consensusData;
    }

    /// @dev number of blocks (consensus rounds) saved in this contract
    function blocksCount() external view returns (uint256) {
        return _consensusData.sequence - _consensusData.blocksCountOffset;
    }

    function blocksCountOffset() external view returns (uint32) {
        return _consensusData.blocksCountOffset;
    }

    function lastBlockId() external view returns (uint256) {
        return _consensusData.lastTimestamp;
    }

    /// @return TRUE if contract is ForeignChain, FALSE otherwise
    function isForeign() external pure virtual returns (bool);

    /// @inheritdoc Registrable
    function getName() external pure override returns (bytes32) {
        return "Chain";
    }

    /// @param _affidavit root and FCDs hashed together
    /// @param _v part of signature
    /// @param _r part of signature
    /// @param _s part of signature
    /// @return signer address
    function recoverSigner(bytes32 _affidavit, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(ETH_PREFIX, _affidavit));
        return ecrecover(hash, _v, _r, _s);
    }

    /// @param _blockId ID of submitted block
    /// @return block data (root + timestamp)
    function blocks(uint256 _blockId) external view returns (Block memory) {
        return Block(roots[_blockId], uint32(_blockId));
    }

    /// @return current block ID
    /// please note, that current ID is not the same as last ID, current means that once padding pass,
    /// ID will switch to next one and it will be pointing to empty submit until submit for that ID is done
    function getBlockId() external view returns (uint32) {
        if (_consensusData.lastTimestamp == 0) return 0;

        return getBlockIdAtTimestamp(block.timestamp);
    }

    function requiredSignatures() external view returns (uint16) {
        return _REQUIRED_SIGNATURES;
    }

    /// @dev calculates block ID for provided timestamp
    /// this function does not works for past timestamps
    /// @param _timestamp current or future timestamp
    /// @return block ID for provided timestamp
    function getBlockIdAtTimestamp(uint256 _timestamp) virtual public view returns (uint32) {
        ConsensusData memory data = _consensusData;

        unchecked {
            // we can't overflow because we adding two `uint32`
            if (data.lastTimestamp + data.padding < _timestamp) {
                return uint32(_timestamp);
            }
        }

        return data.lastTimestamp;
    }

    /// @return last submitted block ID, please note, that on deployment, when there is no submission for this contract
    /// block for last ID will be available in previous contract
    function getLatestBlockId() virtual public view returns (uint32) {
        return _consensusData.lastTimestamp;
    }

    /// @dev verifies if the leaf is valid leaf for merkle tree
    /// @param _proof merkle proof for merkle tree
    /// @param _root merkle root
    /// @param _leaf leaf hash
    /// @return TRUE if `_leaf` is valid, FALSE otherwise
    function verifyProof(bytes32[] memory _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
        if (_root == bytes32(0)) {
            return false;
        }

        return _proof.verify(_root, _leaf);
    }

    /// @dev creates leaf hash, that has is used in merkle tree
    /// @param _key key under which we store the value
    /// @param _value value itself as bytes
    /// @return leaf hash
    function hashLeaf(bytes memory _key, bytes memory _value) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key, _value));
    }

    /// @dev verifies, if provided key-value pair was part of consensus
    /// @param _blockId consensus ID for which we doing a check
    /// @param _proof merkle proof for pair
    /// @param _key pair key
    /// @param _value pair value
    /// @return TRUE if key-value par was part of consensus, FALSE otherwise
    function verifyProofForBlock(
        uint256 _blockId,
        bytes32[] memory _proof,
        bytes memory _key,
        bytes memory _value
    )
        public
        view
        returns (bool)
    {
        return _proof.verify(roots[_blockId], keccak256(abi.encodePacked(_key, _value)));
    }

    /// @dev this is helper method, that extracts one merkle proof from many hashed provided as bytes
    /// @param _data many hashes as bytes
    /// @param _offset this is starting point for extraction
    /// @param _items how many hashes to extract
    /// @return merkle proof (array of bytes32 hashes)
    function bytesToBytes32Array(
        bytes memory _data,
        uint256 _offset,
        uint256 _items
    )
        public
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory dataList = new bytes32[](_items);

        // we can unchecked because we working only with `i` and `_offset`
        // in case of wrong `_offset` it will throw
        unchecked {
            for (uint256 i = 0; i < _items; i++) {
                bytes32 temp;
                uint256 idx = (i + 1 + _offset) * 32;

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    temp := mload(add(_data, idx))
                }

                dataList[i] = temp;
            }
        }

        return (dataList);
    }

    /// @dev batch method for data verification
    /// @param _blockIds consensus IDs for which we doing a checks
    /// @param _proofs merkle proofs for all pair, sequence of hashes provided as bytes
    /// @param _proofItemsCounter array of counters, each counter tells how many hashes proof for each leaf has
    /// @param _leaves array of merkle leaves
    /// @return results array of verification results, TRUE if leaf is part of consensus, FALSE otherwise
    function verifyProofs(
        uint32[] memory _blockIds,
        bytes memory _proofs,
        uint256[] memory _proofItemsCounter,
        bytes32[] memory _leaves
    )
        public
        view
        returns (bool[] memory results)
    {
        results = new bool[](_leaves.length);
        uint256 offset = 0;

        for (uint256 i = 0; i < _leaves.length;) {
            results[i] = bytesToBytes32Array(_proofs, offset, _proofItemsCounter[i]).verify(
                roots[_blockIds[i]], _leaves[i]
            );

            unchecked {
                // we can uncheck because it will not overflow in a lifetime, and if someone provide invalid counter
                // we verification will not be valid (or we throw because of invalid memory access)
                offset += _proofItemsCounter[i];
                // we can uncheck because `i` will not overflow in a lifetime
                i++;
            }
        }
    }

    /// @param _blockId consensus ID
    /// @return root for provided consensus ID
    function getBlockRoot(uint32 _blockId) external view returns (bytes32) {
        return roots[_blockId];
    }

    /// @param _blockId consensus ID
    /// @return timestamp for provided consensus ID
    function getBlockTimestamp(uint32 _blockId) external view returns (uint32) {
        return roots[_blockId] == bytes32(0) ? 0 : _blockId;
    }

    /// @dev batch getter for FCDs
    /// @param _keys FCDs keys to fetch
    /// @return values array of FCDs values
    /// @return timestamps array of FCDs timestamps
    function getCurrentValues(bytes32[] calldata _keys)
        external
        view
        returns (uint256[] memory values, uint32[] memory timestamps)
    {
        timestamps = new uint32[](_keys.length);
        values = new uint256[](_keys.length);

        for (uint i=0; i<_keys.length;) {
            FirstClassData storage numericFCD = fcds[_keys[i]];
            values[i] = uint256(numericFCD.value);
            timestamps[i] = numericFCD.dataTimestamp;

            unchecked {
                // we can uncheck because `i` will not overflow in a lifetime
                i++;
            }
        }
    }

    /// @dev getter for single FCD value
    /// @param _key FCD key
    /// @return value FCD value
    /// @return timestamp FCD timestamp
    function getCurrentValue(bytes32 _key) external view returns (uint256 value, uint256 timestamp) {
        FirstClassData storage numericFCD = fcds[_key];
        return (uint256(numericFCD.value), numericFCD.dataTimestamp);
    }

    /// @dev getter for single FCD value in case its type is `int`
    /// @param _key FCD key
    /// @return value FCD value
    /// @return timestamp FCD timestamp
    function getCurrentIntValue(bytes32 _key) external view returns (int256 value, uint256 timestamp) {
        FirstClassData storage numericFCD = fcds[_key];
        return (numericFCD.value.toInt(), numericFCD.dataTimestamp);
    }

    function _setPadding(uint32 _padding) internal onlyOwner {
        if (_consensusData.padding == _padding) revert NoChangeToState();

        _consensusData.padding = _padding;
        emit LogPadding(msg.sender, _padding);
    }

    /// @dev we cloning last block time, because we will need reference point for next submissions
    function _cloneLastDataFromPrevChain(address _prevChain) internal {
        (bool success, bytes memory v) = _prevChain.staticcall(abi.encode(_VERSION_SELECTOR));
        uint256 prevVersion = success ? abi.decode(v, (uint256)) : 1;

        if (prevVersion == 1) {
            uint32 latestId = IBaseChainV1(address(_prevChain)).getLatestBlockId();
            _consensusData.lastTimestamp = IBaseChainV1(address(_prevChain)).getBlockTimestamp(latestId);

            // +1 because getLatestBlockId subtracts 1
            // +1 because it might be situation when tx is already in progress in old contract
            // and old contract do not have deprecated flag
            _consensusData.sequence = latestId + 2;
            _consensusData.blocksCountOffset = latestId + 2;
        } else { // VERSION 2
            // with new Registry, we have register/unregister methods
            // Chain will be deprecated, so there is no need to do "+1" as in old version
            // TODO what with current Registries??
            // we need a way to make it deprecated!
            ConsensusData memory data = BaseChain(_prevChain).getConsensusData();

            _consensusData.sequence = data.sequence;
            _consensusData.blocksCountOffset = data.sequence;
            _consensusData.lastTimestamp = data.lastTimestamp;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

import "./extensions/Registrable.sol";
import "./interfaces/IRegistry.sol";

/// @dev contracts registry
/// protocol uses this registry to fetch current contract addresses
contract Registry is IRegistry, Ownable {
    /// name => contract address
    mapping(bytes32 => address) public registry;


    error NameNotRegistered();
    error ArraysDataDoNotMatch();

    /// @inheritdoc IRegistry
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external onlyOwner {
        if (_names.length != _destinations.length) revert ArraysDataDoNotMatch();

        for (uint i = 0; i < _names.length;) {
            registry[_names[i]] = _destinations[i];
            emit LogRegistered(_destinations[i], _names[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IRegistry
    function importContracts(address[] calldata _destinations) external onlyOwner {
        for (uint i = 0; i < _destinations.length;) {
            bytes32 name = Registrable(_destinations[i]).getName();
            registry[name] = _destinations[i];
            emit LogRegistered(_destinations[i], name);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IRegistry
    function atomicUpdate(address _newContract) external onlyOwner {
        Registrable(_newContract).register();

        bytes32 name = Registrable(_newContract).getName();
        address oldContract = registry[name];
        registry[name] = _newContract;

        Registrable(oldContract).unregister();

        emit LogRegistered(_newContract, name);
    }

    /// @inheritdoc IRegistry
    function requireAndGetAddress(bytes32 name) external view returns (address) {
        address _foundAddress = registry[name];
        if (_foundAddress == address(0)) revert NameNotRegistered();

        return _foundAddress;
    }

    /// @inheritdoc IRegistry
    function getAddress(bytes32 _bytes) external view returns (address) {
        return registry[_bytes];
    }

    /// @inheritdoc IRegistry
    function getAddressByString(string memory _name) public view returns (address) {
        return registry[stringToBytes32(_name)];
    }

    /// @inheritdoc IRegistry
    function stringToBytes32(string memory _string) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);

        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(_string, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseChainV1 {
    /// @dev number of blocks (consensus rounds) saved in this contract
    function blocksCount() external returns (uint32);

    /// @dev number of all blocks that were generated before switching to this contract
    /// please note, that there might be a gap of one block when we switching from old to new contract
    /// see constructor for details
    function blocksCountOffset() external returns (uint32);

    function getLatestBlockId() external view returns (uint32);

    function getBlockTimestamp(uint32 _blockId) external view returns (uint32);

    function getStatus() external view returns (
        uint256 blockNumber,
        uint16 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        uint32 nextBlockId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingBank is IERC20 {
    /// @param id address of validator wallet
    /// @param location URL of the validator API
    struct Validator {
        address id;
        string location;
    }

    event LogValidatorRegistered(address indexed id);
    event LogValidatorUpdated(address indexed id);
    event LogValidatorRemoved(address indexed id);
    event LogMinAmountForStake(uint256 minAmountForStake);

    /// @dev setter for `minAmountForStake`
    function setMinAmountForStake(uint256 _minAmountForStake) external;

    /// @dev allows to stake `token` by validators
    /// Validator needs to approve StakingBank beforehand
    /// @param _value amount of tokens to stake
    function stake(uint256 _value) external;

    /// @dev notification about approval from `_from` address on UMB token
    /// Staking bank will stake max approved amount from `_from` address
    /// @param _from address which approved token spend for IStakingBank
    function receiveApproval(address _from) external returns (bool success);

    /// @dev withdraws stake tokens
    /// it throws, when balance will be less than required minimum for stake
    /// to withdraw all use `exit`
    function withdraw(uint256 _value) external returns (bool success);

    /// @dev unstake and withdraw all tokens
    function exit() external returns (bool success);

    /// @dev creates (register) new validator
    /// @param _id validator address
    /// @param _location location URL of the validator API
    function create(address _id, string calldata _location) external;

    /// @dev removes validator
    /// @param _id validator wallet
    function remove(address _id) external;

    /// @dev updates validator location
    /// @param _id validator wallet
    /// @param _location new validator URL
    function update(address _id, string calldata _location) external;

    /// @return total number of registered validators (with and without balance)
    function getNumberOfValidators() external view returns (uint256);

    /// @dev gets validator address for provided index
    /// @param _ix index in array of list of all validators wallets
    function addresses(uint256 _ix) external view returns (address);

    /// @param _id address of validator
    /// @return id address of validator
    /// @return location URL of validator
    function validators(address _id) external view returns (address id, string memory location);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

/// @dev Any contract that we want to register in ContractRegistry, must inherit from Registrable
abstract contract Registrable {
    IRegistry public immutable contractRegistry;

    modifier onlyFromContract(address _msgSender, bytes32 _contractName) {
        require(
            contractRegistry.getAddress(_contractName) == _msgSender,
            string(abi.encodePacked("caller is not ", _contractName))
        );
        _;
    }

    modifier withRegistrySetUp() {
        require(address(contractRegistry) != address(0x0), "_registry is empty");
        _;
    }

    constructor(IRegistry _contractRegistry) {
        require(address(_contractRegistry) != address(0x0), "_registry is empty");
        contractRegistry = _contractRegistry;
    }

    /// @dev this method will be called as a first method in registration process when old contract will be replaced
    /// when called, old contract address is still in registry
    function register() virtual external;

    /// @dev this method will be called as a last method in registration process when old contract will be replaced
    /// when called, new contract address is already in registry
    function unregister() virtual external;

    /// @return contract name as bytes32
    function getName() virtual external pure returns (bytes32);

    /// @dev helper method for fetching StakingBank address
    function stakingBankContract() public view returns (IStakingBank) {
        return IStakingBank(contractRegistry.requireAndGetAddress("StakingBank"));
    }

    /// @dev helper method for fetching UMB address
    function tokenContract() public view withRegistrySetUp returns (ERC20) {
        return ERC20(contractRegistry.requireAndGetAddress("UMB"));
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.8;

library ValueDecoder {
  function toUint(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 32))
    }
  }

  function toUint(bytes32 _bytes) internal pure returns (uint256 value) {
    assembly {
      value := _bytes
    }
  }

  function toInt(uint224 u) internal pure returns (int256) {
    int224 i;
    uint224 max = type(uint224).max;

    if (u <= (max - 1) / 2) { // positive values
      assembly {
        i := add(u, 0)
      }

      return i;
    } else { // negative values
      assembly {
        i := sub(sub(u, max), 1)
      }
    }

    return i;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IRegistry {
    event LogRegistered(address indexed destination, bytes32 name);

    /// @dev imports new contract addresses and override old addresses, if they exist under provided name
    /// This method can be used for contracts that for some reason do not have `getName` method
    /// @param  _names array of contract names that we want to register
    /// @param  _destinations array of contract addresses
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external;

    /// @dev imports new contracts and override old addresses, if they exist.
    /// Names of contracts are fetched directly from each contract by calling `getName`
    /// @param  _destinations array of contract addresses
    function importContracts(address[] calldata _destinations) external;

    /// @dev this method ensure, that old and new contract is aware of it state in registry
    /// Note: BSC registry does not have this method. This method was introduced in later stage.
    /// @param _newContract address of contract that will replace old one
    function atomicUpdate(address _newContract) external;

    /// @dev similar to `getAddress` but throws when contract name not exists
    /// @param name contract name
    /// @return contract address registered under provided name or throws, if does not exists
    function requireAndGetAddress(bytes32 name) external view returns (address);

    /// @param name contract name in a form of bytes32
    /// @return contract address registered under provided name
    function getAddress(bytes32 name) external view returns (address);

    /// @param _name contract name
    /// @return contract address assigned to the name or address(0) if not exists
    function getAddressByString(string memory _name) external view returns (address);

    /// @dev helper method that converts string to bytes32,
    /// you can use to to generate contract name
    function stringToBytes32(string memory _string) external pure returns (bytes32 result);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
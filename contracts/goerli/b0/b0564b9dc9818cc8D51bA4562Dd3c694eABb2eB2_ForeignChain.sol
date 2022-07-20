// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Registry.sol";
import "./BaseChain.sol";

/// @dev contract for foreign-chains
contract ForeignChain is BaseChain {
    using MerkleProof for bytes32;

    /// @dev replicator is the one who can replicate consensus from home-chain to this contract
    address public immutable replicator;

    /// @dev last submitted consensus ID
    uint32 public lastBlockId;

    /// @dev flag that lets, if this contract was replaced by newer one
    /// if TRUE, block submission is not longer available
    bool public deprecated;

    event LogBlockReplication(address indexed minter, uint32 blockId);
    event LogDeprecation(address indexed deprecator);

    error OnlyReplicator();
    error OnlyContractRegistryCanRegister();
    error AlreadyRegistered();
    error AlreadyDeprecated();
    error UnregisterFirst();
    error InvalidContractType();
    error ContractDeprecated();
    error DuplicatedBlockId();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures this is only for compatibility
    /// @param _replicator address of wallet that is allow to do submit
    constructor(
        IRegistry _contractRegistry,
        uint16 _padding,
        uint16 _requiredSignatures,
        address _replicator
    ) BaseChain(_contractRegistry, _padding, _requiredSignatures) {
        replicator = _replicator;
    }

    modifier onlyReplicator() {
        if (msg.sender != replicator) revert OnlyReplicator();
        _;
    }

    /// @inheritdoc Registrable
    function register() external override {
        if (msg.sender != address(contractRegistry)) revert OnlyContractRegistryCanRegister();

        ForeignChain oldChain = ForeignChain(contractRegistry.getAddress("Chain"));
        // registration must be done before address in registry is replaced
        if (address(oldChain) == address(this)) revert AlreadyRegistered();

        if (address(oldChain) != address(0x0)) {
            lastBlockId = oldChain.lastBlockId();
            // we cloning last block time, because we will need reference point for next submissions

            // TODO remove this after first redeployment will be done
            //      we need two deployment to switch from blocks -> squashedRoots because previous version and this one
            //      are not compatible in a sense of registering/unregistering
            //      on release we will deploy contract with step1) then we can delete step1) completely
            //      later deployment can be done normally, using step2
            // step 1) first update
            uint32 lastBlockTime = oldChain.blocks(lastBlockId).dataTimestamp;
            bytes32 lastRootTime;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                lastRootTime := or(0x0, lastBlockTime)
            }

            squashedRoots[lastBlockId] = lastRootTime;

            // step 2) next updates (we can remove step1)
            // squashedRoots[lastBlockId] = oldChain.squashedRoots(lastBlockId);
        }
    }

    /// @inheritdoc Registrable
    function unregister() external override {
        if (msg.sender != address(contractRegistry)) revert OnlyContractRegistryCanRegister();
        if (deprecated) revert AlreadyDeprecated();

        ForeignChain newChain = ForeignChain(contractRegistry.getAddress("Chain"));
        // unregistering must be done after address in registry is replaced
        if (address(newChain) == address(this)) revert UnregisterFirst();
        // can not be replaced with chain of different type
        if (!newChain.isForeign()) revert InvalidContractType();

        deprecated = true;
        emit LogDeprecation(msg.sender);
    }

    /// @dev method for submitting/replicating consensus data
    /// @param _dataTimestamp consensus timestamp, this is time for all data in merkle tree including FCDs
    /// @param _root merkle root
    /// @param _keys FCDs keys
    /// @param _values FCDs values
    /// @param _blockId consensus ID from homechain
    // solhint-disable-next-line code-complexity
    function submit(
        uint32 _dataTimestamp,
        bytes32 _root,
        bytes32[] calldata _keys,
        uint256[] calldata _values,
        uint32 _blockId
    ) external onlyReplicator {
        if (deprecated) revert ContractDeprecated();

        uint lastDataTimestamp = squashedRoots[lastBlockId].extractTimestamp();

        if (squashedRoots[_blockId].extractTimestamp() != 0) revert DuplicatedBlockId();
        if (_dataTimestamp <= lastDataTimestamp) revert DataToOld();

        unchecked {
            // we will not overflow on `timestamp` and `padding` in a life time
            if (lastDataTimestamp + padding >= block.timestamp) revert BlockSubmittedToFast();
        }

        if (_keys.length != _values.length) revert ArraysDataDoNotMatch();

        for (uint256 i = 0; i < _keys.length;) {
            if (uint224(_values[i]) != _values[i]) revert FCDOverflow();

            fcds[_keys[i]] = FirstClassData(uint224(_values[i]), _dataTimestamp);

            unchecked {
                i++;
            }
        }

        squashedRoots[_blockId] = MerkleProof.makeSquashedRoot(_root, _dataTimestamp);
        lastBlockId = _blockId;

        emit LogBlockReplication(msg.sender, _blockId);
    }

    /// @inheritdoc BaseChain
    function isForeign() external pure override returns (bool) {
        return true;
    }

    /// @inheritdoc Registrable
    function getName() external pure override returns (bytes32) {
        return "Chain";
    }

    /// @dev helper method that returns all important data about current state of contract
    /// @return blockNumber `block.number`
    /// @return timePadding `this.padding`
    /// @return lastDataTimestamp timestamp for last submitted consensus
    /// @return lastId ID of last submitted consensus
    /// @return nextBlockId block ID for `block.timestamp + 1`
    function getStatus() external view returns(
        uint256 blockNumber,
        uint16 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        uint32 nextBlockId
    ) {
        blockNumber = block.number;
        timePadding = padding;
        lastId = lastBlockId;
        lastDataTimestamp = squashedRoots[lastId].extractTimestamp();

        unchecked {
            // we will not overflow on `timestamp` in a life time
            nextBlockId = getBlockIdAtTimestamp(block.timestamp + 1);
        }
    }

    // this function does not works for past timestamps
    function getBlockIdAtTimestamp(uint256 _timestamp) public view override returns (uint32) {
        uint32 lastId = lastBlockId;
        uint32 dataTimestamp = squashedRoots[lastId].extractTimestamp();

        if (dataTimestamp == 0) {
            return 0;
        }

        unchecked {
            // we will not overflow on `timestamp` and `padding` in a life time
            if (dataTimestamp + padding < _timestamp) {
                return lastId + 1;
            }
        }

        return lastId;
    }

    /// @inheritdoc BaseChain
    function getLatestBlockId() public view override returns (uint32) {
        return lastBlockId;
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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@umb-network/toolbox/dist/contracts/lib/ValueDecoder.sol";

import "./interfaces/IStakingBank.sol";
import "./extensions/Registrable.sol";
import "./Registry.sol";

import "./lib/MerkleProof.sol";

abstract contract BaseChain is Registrable, Ownable {
    using ValueDecoder for bytes;
    using ValueDecoder for uint224;
    using MerkleProof for bytes32;

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

    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    /// @dev block id (consensus ID) => root (squashedRoot)
    /// squashedRoots is composed as: 28 bytes of original root + 4 bytes for timestamp
    mapping(uint256 => bytes32) public squashedRoots;

    /// @dev FCD key => FCD data
    mapping(bytes32 => FirstClassData) public fcds;

    /// @dev number of blocks (consensus rounds) saved in this contract
    uint32 public blocksCount;

    /// @dev number of all blocks that were generated before switching to this contract
    /// please note, that there might be a gap of one block when we switching from old to new contract
    /// see constructor for details
    uint32 public immutable blocksCountOffset;

    /// @dev number of seconds that need to pass before new submit will be possible
    uint16 public padding;

    /// @dev minimal number of signatures required for accepting submission (PoA)
    uint16 public immutable requiredSignatures;

    error NoChangeToState();
    error DataToOld();
    error BlockSubmittedToFast();
    error ArraysDataDoNotMatch();
    error FCDOverflow();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    /// we have a plan to use signatures also in foreign Chains so lets keep it in BaseChain
    constructor(
        IRegistry _contractRegistry,
        uint16 _padding,
        uint16 _requiredSignatures
    ) Registrable(_contractRegistry) {
        _setPadding(_padding);
        requiredSignatures = _requiredSignatures;
        BaseChain oldChain = BaseChain(_contractRegistry.getAddress("Chain"));

        blocksCountOffset = address(oldChain) != address(0x0)
        // +1 because it might be situation when tx is already in progress in old contract
        ? oldChain.blocksCount() + oldChain.blocksCountOffset() + 1
        : 0;
    }

    /// @dev setter for `padding`
    function setPadding(uint16 _padding) external {
        _setPadding(_padding);
    }

    /// @return TRUE if contract is ForeignChain, FALSE otherwise
    function isForeign() virtual external pure returns (bool);

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
        bytes32 root = squashedRoots[_blockId];
        return Block(root, root.extractTimestamp());
    }

    /// @return current block ID, please not this is different from last block ID, current means that once padding pass
    /// block ID will switch to next one and it will be pointing to empty submit, until submit for that block is done
    function getBlockId() public view returns (uint32) {
        return getBlockIdAtTimestamp(block.timestamp);
    }

    /// @dev calculates block ID for provided timestamp
    /// this function does not works for past timestamps
    /// @param _timestamp current or future timestamp
    /// @return block ID for provided timestamp
    function getBlockIdAtTimestamp(uint256 _timestamp) virtual public view returns (uint32) {
        uint32 _blocksCount = blocksCount + blocksCountOffset;

        if (_blocksCount == 0) {
            return 0;
        }

        unchecked {
            // in theory we can overflow when we manually provide `_timestamp`
            // but for internal usage, we using block.timestamp, so we are safe when doing `+padding(uint16)`
            if (squashedRoots[_blocksCount - 1].extractTimestamp() + padding < _timestamp) {
                return _blocksCount;
            }

            // we can't underflow because of above `if (_blocksCount == 0)`
            return _blocksCount - 1;
        }
    }

    /// @return last submitted block ID, please note, that on deployment, when there is no submission for this contract
    /// block for last ID will be available in previous contract
    function getLatestBlockId() virtual public view returns (uint32) {
        unchecked {
            // underflow: we can underflow on very begin and this is OK,
            // because next blockId will be +1 => that gives 0 (first block)
            // overflow: is not possible in a life time
            return blocksCount + blocksCountOffset - 1;
        }
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

        return _root.verify(_proof, _leaf);
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
    ) public view returns (bool) {
        return squashedRoots[_blockId].verifySquashedRoot(_proof, keccak256(abi.encodePacked(_key, _value)));
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
    ) public pure returns (bytes32[] memory) {
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
    ) public view returns (bool[] memory results) {
        results = new bool[](_leaves.length);
        uint256 offset = 0;

        for (uint256 i = 0; i < _leaves.length;) {
            results[i] = squashedRoots[_blockIds[i]].verifySquashedRoot(
                bytesToBytes32Array(_proofs, offset, _proofItemsCounter[i]), _leaves[i]
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
        return squashedRoots[_blockId].extractRoot();
    }

    /// @param _blockId consensus ID
    /// @return timestamp for provided consensus ID
    function getBlockTimestamp(uint32 _blockId) external view returns (uint32) {
        return squashedRoots[_blockId].extractTimestamp();
    }

    /// @dev batch getter for FCDs
    /// @param _keys FCDs keys to fetch
    /// @return values array of FCDs values
    /// @return timestamps array of FCDs timestamps
    function getCurrentValues(bytes32[] calldata _keys)
    external view returns (uint256[] memory values, uint32[] memory timestamps) {
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

    function _setPadding(uint16 _padding) internal onlyOwner {
        if (padding == _padding) revert NoChangeToState();

        padding = _padding;
        emit LogPadding(msg.sender, _padding);
    }

    event LogPadding(address indexed executor, uint16 timePadding);
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

    /// @dev this is required only for ForeignChain
    /// in order to use this method, we need new registry
    function register() virtual external {
        // for backward compatibility the body is implemented as empty
    }

    /// @dev this is required only for ForeignChain
    /// in order to use this method, we need new registry
    function unregister() virtual external {
        // for backward compatibility the body is implemented as empty
    }

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 *      based on openzeppelin/contracts/cryptography/MerkleProof.sol
 *      adjusted to support squashed root
 */
library MerkleProof {
    uint256 constant public ROOT_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000;
    uint256 constant public TIMESTAMP_MASK = 0xffffffff;

    function extractSquashedData(bytes32 _rootTimestamp) internal pure returns (bytes32 root, uint32 dataTimestamp) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            root := and(_rootTimestamp, ROOT_MASK)
            dataTimestamp := and(_rootTimestamp, TIMESTAMP_MASK)
        }
    }

    function extractRoot(bytes32 _rootTimestamp) internal pure returns (bytes32 root) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            root := and(_rootTimestamp, ROOT_MASK)
        }
    }

    function extractTimestamp(bytes32 _rootTimestamp) internal pure returns (uint32 dataTimestamp) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            dataTimestamp := and(_rootTimestamp, TIMESTAMP_MASK)
        }
    }

    function makeSquashedRoot(bytes32 _root, uint32 _timestamp) internal pure returns (bytes32 rootTimestamp) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            rootTimestamp := or(and(_root, ROOT_MASK), _timestamp)
        }
    }

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
    function verifySquashedRoot(bytes32 squashedRoot, bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bool)
    {
        return extractRoot(computeRoot(proof, leaf)) == extractRoot(squashedRoot);
    }

    function verify(bytes32 root, bytes32[] memory proof, bytes32 leaf) internal pure returns (bool) {
        return computeRoot(proof, leaf) == root;
    }

    function computeRoot(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length;) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

        unchecked {
            i++;
        }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash;
    }
}
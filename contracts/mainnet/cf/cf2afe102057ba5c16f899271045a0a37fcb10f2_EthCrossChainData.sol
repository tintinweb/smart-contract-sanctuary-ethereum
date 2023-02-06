/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// File: eth-contracts/contracts/core/cross_chain_manager/interface/IEthCrossChainData.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the EthCrossChainData contract, the implementation is in EthCrossChainData.sol
 */
interface IEthCrossChainData {
    function putCurEpochStartHeight(uint32 curEpochStartHeight) external returns (bool);
    function getCurEpochStartHeight() external view returns (uint32);
    function putCurEpochConPubKeyBytes(bytes calldata curEpochPkBytes) external returns (bool);
    function getCurEpochConPubKeyBytes() external view returns (bytes memory);
    function markFromChainTxExist(uint64 fromChainId, bytes32 fromChainTx) external returns (bool);
    function checkIfFromChainTxExist(uint64 fromChainId, bytes32 fromChainTx) external view returns (bool);
    function getEthTxHashIndex() external view returns (uint256);
    function putEthTxHash(bytes32 ethTxHash) external returns (bool);
    function putExtraData(bytes32 key1, bytes32 key2, bytes calldata value) external returns (bool);
    function getExtraData(bytes32 key1, bytes32 key2) external view returns (bytes memory);
    function transferOwnership(address newOwner) external;
    function pause() external returns (bool);
    function unpause() external returns (bool);
    function paused() external view returns (bool);
    // Not used currently by ECCM
    function getEthTxHash(uint256 ethTxHashIndex) external view returns (bytes32);
}
// File: eth-contracts/contracts/libs/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 * Refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: eth-contracts/contracts/libs/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called to pause, triggers stopped state.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called to unpause, returns to normal state.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: eth-contracts/contracts/libs/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
    function transferOwnership(address newOwner) public  onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: eth-contracts/contracts/core/cross_chain_manager/data/EthCrossChainData.sol

pragma solidity ^0.5.0;




contract EthCrossChainData is IEthCrossChainData, Ownable, Pausable{
    /*
     Ethereum cross chain tx hash indexed by the automatically increased index.
     This map exists for the reason that Poly chain can verify the existence of 
     cross chain request tx coming from Ethereum
    */
    mapping(uint256 => bytes32) public EthToPolyTxHashMap;
    // This index records the current Map length
    uint256 public EthToPolyTxHashIndex;

    /* 
     When Poly chain switches the consensus epoch book keepers, the consensus peers public keys of Poly chain should be 
     changed into no-compressed version so that solidity smart contract can convert it to address type and 
     verify the signature derived from Poly chain account signature.
     ConKeepersPkBytes means Consensus book Keepers Public Key Bytes
    */
    bytes public ConKeepersPkBytes;
    
    // CurEpochStartHeight means Current Epoch Start Height of Poly chain block
    uint32 public CurEpochStartHeight;
    
    // Record the from chain txs that have been processed
    mapping(uint64 => mapping(bytes32 => bool)) FromChainTxExist;
    
    // Extra map for the usage of future potentially
    mapping(bytes32 => mapping(bytes32 => bytes)) public ExtraData;
    
    // Store Current Epoch Start Height of Poly chain block
    function putCurEpochStartHeight(uint32 curEpochStartHeight) public whenNotPaused onlyOwner returns (bool) {
        CurEpochStartHeight = curEpochStartHeight;
        return true;
    }

    // Get Current Epoch Start Height of Poly chain block
    function getCurEpochStartHeight() public view returns (uint32) {
        return CurEpochStartHeight;
    }

    // Store Consensus book Keepers Public Key Bytes
    function putCurEpochConPubKeyBytes(bytes memory curEpochPkBytes) public whenNotPaused onlyOwner returns (bool) {
        ConKeepersPkBytes = curEpochPkBytes;
        return true;
    }

    // Get Consensus book Keepers Public Key Bytes
    function getCurEpochConPubKeyBytes() public view returns (bytes memory) {
        return ConKeepersPkBytes;
    }

    // Mark from chain tx fromChainTx as exist or processed
    function markFromChainTxExist(uint64 fromChainId, bytes32 fromChainTx) public whenNotPaused onlyOwner returns (bool) {
        FromChainTxExist[fromChainId][fromChainTx] = true;
        return true;
    }

    // Check if from chain tx fromChainTx has been processed before
    function checkIfFromChainTxExist(uint64 fromChainId, bytes32 fromChainTx) public view returns (bool) {
        return FromChainTxExist[fromChainId][fromChainTx];
    }

    // Get current recorded index of cross chain txs requesting from Ethereum to other public chains
    // in order to help cross chain manager contract differenciate two cross chain tx requests
    function getEthTxHashIndex() public view returns (uint256) {
        return EthToPolyTxHashIndex;
    }

    // Store Ethereum cross chain tx hash, increase the index record by 1
    function putEthTxHash(bytes32 ethTxHash) public whenNotPaused onlyOwner returns (bool) {
        EthToPolyTxHashMap[EthToPolyTxHashIndex] = ethTxHash;
        EthToPolyTxHashIndex = EthToPolyTxHashIndex + 1;
        return true;
    }

    // Get Ethereum cross chain tx hash indexed by ethTxHashIndex
    function getEthTxHash(uint256 ethTxHashIndex) public view returns (bytes32) {
        return EthToPolyTxHashMap[ethTxHashIndex];
    }

    // Store extra data, which may be used in the future
    function putExtraData(bytes32 key1, bytes32 key2, bytes memory value) public whenNotPaused onlyOwner returns (bool) {
        ExtraData[key1][key2] = value;
        return true;
    }
    // Get extra data, which may be used in the future
    function getExtraData(bytes32 key1, bytes32 key2) public view returns (bytes memory) {
        return ExtraData[key1][key2];
    }
    
    function pause() onlyOwner whenNotPaused public returns (bool) {
        _pause();
        return true;
    }
    
    function unpause() onlyOwner whenPaused public returns (bool) {
        _unpause();
        return true;
    }
}
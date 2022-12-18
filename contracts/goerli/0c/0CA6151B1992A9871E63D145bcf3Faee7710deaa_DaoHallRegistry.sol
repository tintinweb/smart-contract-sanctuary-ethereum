/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/registrar/Operable.sol



pragma solidity ^0.8.4;
abstract contract Operable is Ownable {
    mapping(address => bool) private _operators;

    modifier onlyOperator() {
        require(_operators[msg.sender], "onlyOperator");
        _;
    }

    function setOperator(address operator, bool enabled) external onlyOwner {
        _operators[operator] = enabled;
    }

    function isOperator(address operator) external view returns (bool){
        return _operators[operator];
    }
}


// File contracts/interfaces/IDaoHallRegistry.sol



pragma solidity ^0.8.0;

struct NodeRecord{
    uint256 startTime;
    uint256[5] annualPrice;
    uint256[5] maxPrice;

    uint256 whitelistStartTime;
    uint256 whitelistParam;
    bytes32 whitelistRoot;
}

interface IDaoHallRegistry {
    function setRecord(bytes32 node, address owner, NodeRecord calldata record) external;
    function getRecord(bytes32 node, address owner) external view returns (NodeRecord memory);

    function setWhitelistClaimed(bytes32 root, address claimer, uint256 count) external;
    function getWhitelistClaimed(bytes32 root, address claimer) external view returns (uint256);
}


// File contracts/registrar/DaoHallRegistry.sol



pragma solidity ^0.8.4;
contract DaoHallRegistry is IDaoHallRegistry, Operable {

    mapping(bytes32 => mapping(address => NodeRecord)) private _nodeRecords;
    mapping(bytes32 => mapping(address => uint256)) private _whitelistClaims;

    function setRecord(bytes32 node, address owner, NodeRecord calldata record) external override onlyOperator{
        _nodeRecords[node][owner] = record;
    }

    function getRecord(bytes32 node, address owner) external view override returns (NodeRecord memory) {
        return _nodeRecords[node][owner];
    }

    function setWhitelistClaimed(bytes32 root, address claimer, uint256 count) external override onlyOperator{
        _whitelistClaims[root][claimer] = count;
    }

    function getWhitelistClaimed(bytes32 root, address claimer) external view override returns (uint256) {
        return _whitelistClaims[root][claimer];
    }
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DocumentStash is Ownable {
    using Counters for Counters.Counter;
    
    struct Company  {
        string companyID;
        string companyName;
        bool initialized;

        Counters.Counter claimsCounter;

        mapping(uint256 => Claim) claimMap;
    }

    struct Claim {
        uint256 claimID;
        string claimName;
        bool initialized;

        Counters.Counter documentsCounter;

        mapping(uint256 => Document) documentMap;
    }

    struct Document {
        uint256 documentID;
        bytes32 documentHash;
        string documentName;
        uint256 timestamp;
        bool initialized;
        
        bytes32[] signatures;
    }

    mapping(string => Company) public companyMap;

    event CompanyCreated(string ID, string name);
    event ClaimCreated(uint256 ID, string name);
    event DocumentCreated(uint256 ID, string name, bytes32 dochash);

    function createNewCompany(string memory _companyID, string memory _companyName) public onlyOwner {
        require(bytes(_companyID).length == 6, "Company ID should be of length 6");
        require(companyMap[_companyID].initialized != true, "Company already exists");

        companyMap[_companyID].companyID = _companyID;
        companyMap[_companyID].companyName = _companyName;
        companyMap[_companyID].initialized = true;

        emit CompanyCreated(_companyID, _companyName);
    }

    function createNewClaim(string memory _companyID, string memory _claimName) public onlyOwner {
        require(companyMap[_companyID].initialized == true, "Company does not exist");

        uint256 claimID = companyMap[_companyID].claimsCounter.current();

        companyMap[_companyID].claimMap[claimID].claimID = claimID;
        companyMap[_companyID].claimMap[claimID].claimName = _claimName;
        companyMap[_companyID].claimMap[claimID].initialized = true;

        emit ClaimCreated(claimID, _claimName);

        companyMap[_companyID].claimsCounter.increment();
    }

    function createNewDocument(string memory _companyID, uint256 _claimID, bytes32 _documentHash, string memory _documentName) public onlyOwner {
        require(companyMap[_companyID].initialized == true, "Company does not exist");
        require(companyMap[_companyID].claimMap[_claimID].initialized == true, "Claim does not exit");
        
        uint256 documentID = companyMap[_companyID].claimMap[_claimID].documentsCounter.current();

        companyMap[_companyID].claimMap[_claimID].documentMap[documentID].documentID = documentID;
        companyMap[_companyID].claimMap[_claimID].documentMap[documentID].documentName = _documentName;
        companyMap[_companyID].claimMap[_claimID].documentMap[documentID].documentHash = _documentHash;
        companyMap[_companyID].claimMap[_claimID].documentMap[documentID].timestamp = block.timestamp;
        companyMap[_companyID].claimMap[_claimID].documentMap[documentID].initialized = true;

        emit DocumentCreated(documentID, _documentName, _documentHash);

        companyMap[_companyID].claimMap[_claimID].documentsCounter.increment();
    }

    function addNewSignature(string memory _companyID, uint256 _claimID, uint256 _documentID, bytes32 _signature) public onlyOwner {
        require(companyMap[_companyID].initialized == true, "Company does not exist");
        require(companyMap[_companyID].claimMap[_claimID].initialized == true, "Claim does not exit");
        require(companyMap[_companyID].claimMap[_claimID].documentMap[_documentID].initialized == true, "Document does not exist");

        companyMap[_companyID].claimMap[_claimID].documentMap[_documentID].signatures.push(_signature);
    }

    function getClaim(string memory _companyID, uint256 _claimID) public view onlyOwner returns (Document[] memory, string memory) {
        require(companyMap[_companyID].initialized == true, "Company does not exist");
        require(companyMap[_companyID].claimMap[_claimID].initialized == true, "Claim does not exit");

        uint256 numberOfDocuments = companyMap[_companyID].claimMap[_claimID].documentsCounter.current();

        Document[] memory documents = new Document[](numberOfDocuments);

        for (uint256 i = 0; i < numberOfDocuments ; i++) {
            documents[i] = companyMap[_companyID].claimMap[_claimID].documentMap[i];
        }

        return (documents, companyMap[_companyID].claimMap[_claimID].claimName);
    }

    function getClaimsCounter(string memory _companyID) public view onlyOwner returns(uint256) {
        require(companyMap[_companyID].initialized == true, "Company does not exist");
        return  companyMap[_companyID].claimsCounter.current();
    }

    function getDocumentsCounter(string memory _companyID, uint256 _claimID) public view onlyOwner returns(Counters.Counter memory) {
        require(companyMap[_companyID].initialized == true, "Company does not exist");
        require(companyMap[_companyID].claimMap[_claimID].initialized == true, "Claim does not exit");

        return companyMap[_companyID].claimMap[_claimID].documentsCounter;
    }
}
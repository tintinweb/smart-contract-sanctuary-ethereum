//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/INitroCollection1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author NitroLeague.
contract ListController is Ownable, Pausable, ReentrancyGuard {
    struct Allowlist {
        string listName;
        uint allowed;
    }

    Allowlist[] public allowlists;
    uint public currentList;
    /**list index => (wallet => minted/or remaining mints) */
    mapping(uint => mapping(address => uint)) public mintCount;
    /**allow list name (string) to index mapping */
    mapping(string => uint) public listIndices;

    uint256 private constant maxAllowlistTokenID = 4;
    INitroCollection1155[] public collections;

    event CollectionAdded(address collection);
    event UserMinted(
        address indexed account,
        string indexed listName,
        uint quantity
    );

    constructor(address[] memory _collections) {
        for (uint256 i = 0; i < _collections.length; i++) {
            collections.push(INitroCollection1155(_collections[i]));
            emit CollectionAdded(_collections[i]);
        }
        /**initialize with a public list */
        allowlists.push(Allowlist("public", 1));
        listIndices["public"] = 0;
        /**initialize to list number 1 so that public cannot mint */
        currentList = 1;
        _transferOwnership(_msgSender());
    }

    function mint(uint256 _quantity)
        external
        allowedToMint(_quantity)
        whenNotPaused
    {
        (uint256 i, uint[] memory ids, uint[] memory amounts) = getTokenIDs(
            _quantity
        );

        callMint(i, _quantity, ids, amounts);
    }

    function callMint(
        uint256 i,
        uint256 _quantity,
        uint[] memory ids,
        uint[] memory amounts
    ) internal nonReentrant whenCollectionNotPaused(i) {
        _updateMinted(_msgSender(), _quantity);

        collections[i].mintAllowlisted(_msgSender(), ids, amounts);

        emit UserMinted(
            _msgSender(),
            allowlists[currentList].listName,
            _quantity
        );
    }

    function getNumberOfLists() external view returns (uint listsLength) {
        return allowlists.length;
    }

    modifier allowedToMint(uint quantity) {
        require(quantity > 0, "Quantity Cannot be Zero");
        require(
            getRemainingMints(currentList, _msgSender()) >= quantity,
            "Quantity > Allowed"
        );
        _;
    }

    function getRemainingMints(uint listIndex, address account)
        public
        view
        returns (uint)
    {
        uint allowed = allowlists[listIndex].allowed;
        uint count = mintCount[listIndex][account];
        /** Public mint */
        if (listIndex == 0) {
            if (count > allowed) return 0; /**User minted more than allowed */
            unchecked {
                return allowed - count;
            }
        }

        /**Allow listed mint */
        if (count > allowed) return allowed;

        return count;
    }

    function createAllowlists(
        string[] calldata listNames,
        uint[] calldata allowed
    ) external onlyOwner {
        require(listNames.length == allowed.length, "Array Lengths Mismatch");

        for (uint i = 0; i < listNames.length; i++) {
            allowlists.push(Allowlist(listNames[i], allowed[i]));
            listIndices[listNames[i]] = allowlists.length - 1;
        }
    }

    function setCurrentList(uint listIndex)
        public
        onlyOwner
        validListIndex(listIndex)
    {
        currentList = listIndex;
    }

    function setNextList() external onlyOwner {
        setCurrentList(currentList + 1);
    }

    function addToAllowlist(uint listIndex, address[] memory accounts)
        external
        onlyOwner
        validListIndex(listIndex)
    {
        uint allowed = allowlists[listIndex].allowed;
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            mintCount[listIndex][account] = allowed;
        }
    }

    modifier validListIndex(uint listIndex) {
        /**Check list index is neither negative nor greater than max lists */
        require(
            listIndex >= 0 && listIndex < allowlists.length,
            "Invalid Index"
        );
        _;
    }

    function setMaxMints(uint listIndex, uint allowed)
        external
        onlyOwner
        validListIndex(listIndex)
    {
        allowlists[listIndex].allowed = allowed;
    }

    function _updateMinted(address account, uint quantity) internal {
        if (currentList == 0) mintCount[currentList][account] += quantity;
        else {
            unchecked {
                mintCount[currentList][account] -= quantity;
            }
        }
    }

    function getTokenIDs(uint256 _quantity)
        internal
        view
        returns (
            uint collection,
            uint[] memory ids,
            uint[] memory amounts
        )
    {
        ids = new uint[](_quantity);
        amounts = new uint[](_quantity);
        uint i = 0;
        for (i; i < _quantity; i++) {
            ids[i] = (randomNumber(i) % maxAllowlistTokenID) + 1;
            amounts[i] = 1;
        }
        collection = (randomNumber(i) + 1) % collections.length;
        return (collection, ids, amounts);
    }

    function randomNumber(uint i) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, i)));
    }

    function addCollection(address _newColletion) external onlyOwner {
        collections.push(INitroCollection1155(_newColletion));
        emit CollectionAdded(_newColletion);
    }

    /**
     * @dev Throws error if daily mints limit is reached
     */
    function isLimitReahed(uint256 i) internal virtual returns (bool) {
        if (collections[i].mintsCounter() >= collections[i].maxDailyMints()) {
            if (block.timestamp >= (collections[i].lastChecked() + 86400))
                return false; /**Day passed which means limit will reset on next call */
            return true;
        }
        return false;
    }

    function collectionPaused(uint i) external view returns (bool) {
        return collections[i].paused();
    }

    modifier inDailyLimit(uint256 i) {
        require(!isLimitReahed(i), "Daily mint reached");
        _;
    }

    modifier whenCollectionNotPaused(uint256 i) {
        require(!collections[i].paused(), "Pausable: paused");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author NitroLeague.
interface INitroCollection1155 {
    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     *
     * @param newuri base uri for tokens
     */
    function setURI(string memory newuri) external;

    /**
     * Get URI of token with given id.
     */
    function uri(uint256 _tokenid) external;

    /**
     * @dev Mints a token to a wallet (called by owner)
     *
     * @param to address to mint to
     * @param id token id to be minted.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Mints a token to a winner against a context (called by minter)
     *
     * @param _context Race/Event address, Lootbox or blueprint ID.
     * @param _to address to mint to
     * @param id token id to be minted.
     */
    function mintGame(
        string calldata _context,
        address _to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Mints multiple ids to a wallet (called by owner)
     *
     * @param to address to mint to
     * @param ids token ids to be minted.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function mintAllowlisted(
        address _to,
        uint[] memory ids,
        uint[] memory amounts
    ) external;

    function lockMetaData() external;

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;

    function getClaimed(string memory context, address account)
        external
        view
        returns (bool claimed);

    function mintsCounter() external view returns (uint);

    function maxDailyMints() external view returns (uint);

    function lastChecked() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

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
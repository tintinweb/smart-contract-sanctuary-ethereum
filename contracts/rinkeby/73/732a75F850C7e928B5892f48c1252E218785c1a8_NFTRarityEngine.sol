/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// File: localhost/INFTRarityEngine.sol



pragma solidity ^0.8.2;

interface INFTRarityEngine {
    function rollType() external returns (uint256);
}
// File: localhost/IChaos.sol



pragma solidity ^0.8.2;

interface IChaos {
    function entropy(int256 a, int256 b) external returns (uint256);
    function enthalpy() external;
}
// File: localhost/IACM.sol



pragma solidity ^0.8.2;

interface IACM {
    function isAddressAllowed(address _address) external returns (bool);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: localhost/NFTRarityEngine.sol



pragma solidity ^0.8.2;





contract NFTRarityEngine is INFTRarityEngine, Ownable {

    /** --------------------------------------------------------------- */
    /**                             Vars                                */
    /** --------------------------------------------------------------- */

    string public NAME;

    uint256[] public MAX_SUPPLY_BY_TYPE;  // e.g. [4, 3, 2, 1];
    uint256[] public COUNT_BY_TYPE;       // e.g. [0, 0, 0, 0];

    uint256[] public TYPES_BY_INDEX;      // e.g. [0, 1, 2, 3];
    uint256[] public RARITY_MIN_BY_INDEX; // e.g. [0, 45, 75, 90];
    uint256[] public RARITY_MAX_BY_INDEX; // e.g. [44, 74, 89, 99];
    
    uint256 private MAX_CHAOS;            // e.g. 99;

    IACM public acm;
    IChaos private chaos;

    /** --------------------------------------------------------------- */
    /**                             OnInit                              */
    /** --------------------------------------------------------------- */


    constructor(
        string memory name,
        address chaosAddress,
        address acmAddress,
        uint256[] memory maxSupplyByType,
        uint256[] memory rarityMinByIndex,
        uint256[] memory rarityMaxByIndex
    ) {
        require(maxSupplyByType.length == rarityMinByIndex.length, "Arrays are not of equal length");
        require(maxSupplyByType.length == rarityMaxByIndex.length, "Arrays are not of equal length");
        NAME = name;
        chaos = IChaos(chaosAddress);
        acm = IACM(acmAddress);
        MAX_SUPPLY_BY_TYPE = maxSupplyByType;
        RARITY_MIN_BY_INDEX = rarityMinByIndex;
        RARITY_MAX_BY_INDEX = rarityMaxByIndex;
        for (uint256 i = 0; i < maxSupplyByType.length; i++) {
            COUNT_BY_TYPE.push(0);
            TYPES_BY_INDEX.push(i);
        }
    }

    /** --------------------------------------------------------------- */
    /**                           Modifiers                             */
    /** --------------------------------------------------------------- */

    modifier allowedAddress() {
        require(address(acm) != address(0), "Contract is not set");
		require(acm.isAddressAllowed(msg.sender) == true, "Calling address is not whitelisted");
        _;
    }

    /** --------------------------------------------------------------- */
    /**                           Setters                               */
    /** --------------------------------------------------------------- */

    function setACM(address acmAddress) public onlyOwner {
        acm = IACM(acmAddress);
    }

    function setChaos(address _address) public onlyOwner {
        chaos = IChaos(_address);
    }

    function setMaxChaos(uint256 _maxChaos) public onlyOwner {
        MAX_CHAOS = _maxChaos;
    }

    function setMaxSupplyByType(uint256 [] memory maxSupplyByType) public onlyOwner {
        MAX_SUPPLY_BY_TYPE = maxSupplyByType;
    }

    function setTypesByIndex(uint256[] memory typesByIndex) public onlyOwner {
        TYPES_BY_INDEX = typesByIndex;
    }

    function setRarityMinMaxByIndex(uint256[] memory rarityMinByIndex, uint256[] memory rarityMaxByIndex) public onlyOwner {
        require(RARITY_MIN_BY_INDEX.length == RARITY_MAX_BY_INDEX.length, "Arrays are not of equal length");
        RARITY_MIN_BY_INDEX = rarityMinByIndex;
        RARITY_MAX_BY_INDEX = rarityMaxByIndex;
    }

    /** --------------------------------------------------------------- */
    /**                            Getters                              */
    /** --------------------------------------------------------------- */

    function getEntropy(uint256 a, uint256 b) internal returns (uint256) {
        require(address(chaos) != address(0), "Contract is not set");
        return chaos.entropy(int256(a), int256(b));
    }

    function rollType() public override allowedAddress returns (uint256) {
        uint256 r = getEntropy(0, MAX_CHAOS);
        uint256 rType;
        for (uint256 i = 0; i < TYPES_BY_INDEX.length; i++) {
            if (r >= RARITY_MIN_BY_INDEX[i] && r <= RARITY_MAX_BY_INDEX[i]) {
                rType = TYPES_BY_INDEX[i];
            }
        }
        COUNT_BY_TYPE[rType]++;
        if (COUNT_BY_TYPE[rType] == MAX_SUPPLY_BY_TYPE[rType]) {
            whenRarityTypeMaxedOut(rType);
        }
        return rType;
    }

    /** --------------------------------------------------------------- */
    /**                        State Changers                           */
    /** --------------------------------------------------------------- */

    function addNewType(uint256 maxSupplyOfType, uint256 rarityMin, uint256 rarityMax) public onlyOwner {
        uint256 newIndex = MAX_SUPPLY_BY_TYPE.length;
        MAX_SUPPLY_BY_TYPE.push(maxSupplyOfType);
        COUNT_BY_TYPE.push(0);
        TYPES_BY_INDEX.push(newIndex);
        RARITY_MIN_BY_INDEX.push(rarityMin);
        RARITY_MAX_BY_INDEX.push(rarityMax);
    }

    // Deletes without preserving order.
    function whenRarityTypeMaxedOut(uint256 rType) internal {
        TYPES_BY_INDEX[rType] = TYPES_BY_INDEX[TYPES_BY_INDEX.length - 1];
        RARITY_MIN_BY_INDEX[rType] = RARITY_MIN_BY_INDEX[RARITY_MIN_BY_INDEX.length - 1];
        RARITY_MAX_BY_INDEX[rType] = RARITY_MAX_BY_INDEX[RARITY_MAX_BY_INDEX.length - 1];

        delete TYPES_BY_INDEX[TYPES_BY_INDEX.length - 1];
        delete RARITY_MIN_BY_INDEX[RARITY_MIN_BY_INDEX.length - 1];
        delete RARITY_MAX_BY_INDEX[RARITY_MAX_BY_INDEX.length - 1];
    }

    // MIGHT BE EXPENSIVE. Last Resort.
    function sortRarityTypePriority(uint256[] memory newRarityIndexes) public onlyOwner {
        require(newRarityIndexes.length == TYPES_BY_INDEX.length,      "Unequal array length! Something is very wrong.");
        require(newRarityIndexes.length == RARITY_MIN_BY_INDEX.length, "Unequal array length! Something is very wrong.");
        require(newRarityIndexes.length == RARITY_MAX_BY_INDEX.length, "Unequal array length! Something is very wrong.");

        uint256 l = TYPES_BY_INDEX.length;

        uint256[] memory TYPES_BY_INDEX_NEW =      new uint256[](l);
        uint256[] memory RARITY_MIN_BY_INDEX_NEW = new uint256[](l);
        uint256[] memory RARITY_MAX_BY_INDEX_NEW = new uint256[](l);

        for (uint256 i = 0; i < l; i++) {
            TYPES_BY_INDEX_NEW[newRarityIndexes[i]] =      TYPES_BY_INDEX[i];
            RARITY_MIN_BY_INDEX_NEW[newRarityIndexes[i]] = RARITY_MIN_BY_INDEX[i];
            RARITY_MAX_BY_INDEX_NEW[newRarityIndexes[i]] = RARITY_MAX_BY_INDEX[i];
        }

        TYPES_BY_INDEX =      TYPES_BY_INDEX_NEW;
        RARITY_MIN_BY_INDEX = RARITY_MIN_BY_INDEX_NEW;
        RARITY_MAX_BY_INDEX = RARITY_MAX_BY_INDEX_NEW;
    }



}
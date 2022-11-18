// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * # WondrousXRaffle
 * Used for randomizing the winners for rare classes of Wondrous-X.
 * The winners will be picked from the list of tokens that have chosen
 * the species in the website.
 *
 * ## Overview
 * - Total Supply: 1427
 * - 5 Species:
 *    - AQUATIC_ANIMALS x 286
 *    - INSECT x 285
 *    - LAND_ANIMALS x 285
 *    - POULTRY x 286
 *    - WILD_ANIMALS x 285
 * - 3 Classes:
 *    - Glorious x 5 (1 per species)
 *    - Special x 30 (6 per species)
 *    - Normal x 1392
 * - Tokens with chosen Species:
 *    - AQUATIC_ANIMALS x 202
 *    - INSECT x 153
 *    - LAND_ANIMALS x 150
 *    - POULTRY x 243
 *    - WILD_ANIMALS x 176
 *
 * ## Process
 * - Assign the Token ID who chose the species to the number index from 1 to max (ex. 1 to 202 for Aquatic Animals).
 * - Pin the information of token ID Index to the IPFS for public verification (TOKEN_INDEX_DATA).
 * - Randomly pick 8 numbers from 1 to max species for each species.
 *    - 1st pick: Glorious class
 *    - 2nd to 7th pick: Special class
 *    - 8th pick: Starting index for all normal class eggs
 * - For an occasion that the indexes from 1st to 8th are duplicated, re-pick all 1st to 8th for that speicies.
 */
contract WondrousXRaffle is Ownable {
    uint256 public constant TOTAL_RAFFLE_PICKS_PER_SPECIES = 8;
    uint256 public constant MAX_AQUATIC_ANIMALS_TOKEN_INDEX = 202;
    uint256 public constant MAX_INSECT_TOKEN_INDEX = 153;
    uint256 public constant MAX_LAND_ANIMALS_TOKEN_INDEX = 150;
    uint256 public constant MAX_POULTRY_TOKEN_INDEX = 243;
    uint256 public constant MAX_WILD_ANIMALS_TOKEN_INDEX = 176;

    event SpeciesRaffled(string species, uint256[] raffleResult);

    enum Species {
        AQUATIC_ANIMALS,
        INSECT,
        LAND_ANIMALS,
        POULTRY,
        WILD_ANIMALS
    }

    // CSV of token index for each species
    string public constant TOKEN_INDEX_DATA =
        "https://metawarden.mypinata.cloud/ipfs/QmcVNZPo9aeKqz2QTTkqVTfya3otv2HZ3C5EcY6AZ2oX27";

    // Mapping of species to raffle result
    mapping(Species => uint256[]) public speciesRaffleResult;

    // require species must be in enums
    modifier onlyValidSpecies(Species species) {
        require(
            species == Species.AQUATIC_ANIMALS ||
                species == Species.INSECT ||
                species == Species.LAND_ANIMALS ||
                species == Species.POULTRY ||
                species == Species.WILD_ANIMALS,
            "Invalid species"
        );
        _;
    }

    function raffleForSpecies(Species species)
        public
        onlyValidSpecies(species)
        onlyOwner
    {
        uint256 maxTokenIndex = speciesMaxTokenIndexes(species);
        speciesRaffleResult[species] = _randomMultiple(maxTokenIndex);

        emit SpeciesRaffled(
            speciesToString(species),
            speciesRaffleResult[species]
        );
    }

    function viewRaffleResult(Species species)
        public
        view
        onlyValidSpecies(species)
        returns (uint256[] memory)
    {
        return speciesRaffleResult[species];
    }

    function _randomMultiple(uint256 maxIndex)
        internal
        view
        returns (uint256[] memory randomValues)
    {
        randomValues = new uint256[](TOTAL_RAFFLE_PICKS_PER_SPECIES);
        for (uint256 i = 0; i < TOTAL_RAFFLE_PICKS_PER_SPECIES; i++) {
            randomValues[i] = (_random(i) % maxIndex) + 1;
        }
        return randomValues;
    }

    function _random(uint256 index) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.number,
                        block.timestamp,
                        blockhash(block.number - 1),
                        address(this),
                        msg.sender,
                        index
                    )
                )
            );
    }

    function speciesToString(Species species)
        public
        pure
        onlyValidSpecies(species)
        returns (string memory)
    {
        if (species == Species.AQUATIC_ANIMALS) {
            return "AQUATIC_ANIMALS";
        } else if (species == Species.INSECT) {
            return "INSECT";
        } else if (species == Species.LAND_ANIMALS) {
            return "LAND_ANIMALS";
        } else if (species == Species.POULTRY) {
            return "POULTRY";
        } else if (species == Species.WILD_ANIMALS) {
            return "WILD_ANIMALS";
        } else {
            return "INVALID";
        }
    }

    function speciesMaxTokenIndexes(Species species)
        public
        pure
        onlyValidSpecies(species)
        returns (uint256)
    {
        if (species == Species.AQUATIC_ANIMALS) {
            return MAX_AQUATIC_ANIMALS_TOKEN_INDEX;
        } else if (species == Species.INSECT) {
            return MAX_INSECT_TOKEN_INDEX;
        } else if (species == Species.LAND_ANIMALS) {
            return MAX_LAND_ANIMALS_TOKEN_INDEX;
        } else if (species == Species.POULTRY) {
            return MAX_POULTRY_TOKEN_INDEX;
        } else if (species == Species.WILD_ANIMALS) {
            return MAX_WILD_ANIMALS_TOKEN_INDEX;
        } else {
            return 0;
        }
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
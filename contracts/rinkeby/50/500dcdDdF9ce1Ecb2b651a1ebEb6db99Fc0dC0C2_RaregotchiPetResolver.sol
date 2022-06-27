// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProtectedMint is Ownable {
    address[] public minterAddresses;

    modifier onlyMinter() {
        bool isAllowed;

        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == msg.sender) {
                isAllowed = true;

                break;
            }
        }

        require(isAllowed, "Minter: caller is not an allowed minter");

        _;
    }

    /**
     * @dev Adds an address that is allowed to mint
     */
    function addMinterAddress(address _minterAddress) external onlyOwner {
        minterAddresses.push(_minterAddress);
    }

    /**
     * @dev Removes
     */
    function removeMinterAddress(address _minterAddress) external onlyOwner {
        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] != _minterAddress) {
                continue;
            }

            minterAddresses[i] = minterAddresses[minterAddresses.length - 1];

            minterAddresses.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProtectedMint.sol";

contract RaregotchiPetResolver is ProtectedMint {
    event Open(uint8 _type, uint8 _size, uint256[] _ids, bool _special);

    mapping (uint8 => uint8) petAmountPerBucketSize;
    mapping (uint8 => mapping(uint8 => uint256)) specialPetAmounts;
    mapping (uint8 => uint16) mintedPetAmounts;
    mapping (uint8 => uint16) mintedSpecialPetAmounts;
    mapping (uint8 => uint8) specialPetsPerSize;
    mapping (uint8 => uint256[]) petIdRanges;
    mapping (uint8 => mapping(uint256 => uint256)) petIdMatrix;
    mapping (uint8 => mapping(uint256 => uint256)) specialPetIdMatrix;
    mapping (uint8 => uint256[]) specialPetIdRanges;
    mapping (uint256 => uint256[]) public toysToPets;

    uint8 SCHOOL_KID = 0;
    uint8 ALIEN_BABY = 1;
    uint8 SNOW_CONE = 2;

    uint8 REGULAR = 0;
    uint8 LARGE = 1;
    uint8 HUGE = 2;

    constructor() {
        petAmountPerBucketSize[REGULAR] = 3;
        petAmountPerBucketSize[LARGE] = 4;
        petAmountPerBucketSize[HUGE] = 6;

        specialPetsPerSize[REGULAR] = 105;
        specialPetsPerSize[LARGE] = 30;
        specialPetsPerSize[HUGE] = 15;

        // Legendary, Epics, Full Sets and Shinies
        specialPetIdRanges[SCHOOL_KID] = [1, 150];
        specialPetIdRanges[ALIEN_BABY] = [151, 300];
        specialPetIdRanges[SNOW_CONE] = [301, 450];

        // Regulars
        petIdRanges[SCHOOL_KID] = [451, 3633];
        petIdRanges[ALIEN_BABY] = [3634, 6816];
        petIdRanges[SNOW_CONE] = [6817, 9999];

        useSpecialTokenId(SCHOOL_KID, 1);
        useSpecialTokenId(SCHOOL_KID, 2);
        useSpecialTokenId(SCHOOL_KID, 3);
        useSpecialTokenId(ALIEN_BABY, 151);
        useSpecialTokenId(ALIEN_BABY, 152);
        useSpecialTokenId(ALIEN_BABY, 153);
        useSpecialTokenId(SNOW_CONE, 301);
        useSpecialTokenId(SNOW_CONE, 302);
        useSpecialTokenId(SNOW_CONE, 303);

        specialPetAmounts[SCHOOL_KID][REGULAR] = 3;
        mintedSpecialPetAmounts[SCHOOL_KID] = 3;

        specialPetAmounts[ALIEN_BABY][REGULAR] = 3;
        mintedSpecialPetAmounts[ALIEN_BABY] = 3;

        specialPetAmounts[SNOW_CONE][REGULAR] = 3;
        mintedSpecialPetAmounts[SNOW_CONE] = 3;
    }

    function getPetsForToy(uint256 _toyId) external view returns (uint256[] memory) {
        return toysToPets[_toyId];
    }

    function open(uint256 _toyId, uint8 _type, uint8 _size) external onlyMinter {
        require(_type == SCHOOL_KID || _type == ALIEN_BABY || _type == SNOW_CONE, "Invalid pet type");
        require(_size == REGULAR || _size == LARGE || _size == HUGE, "Invalid pet size");
        require(toysToPets[_toyId].length == 0, "This toy has already been opened");
        require(getMintedPets() < 9999, "All pets have been given");

        uint256 lastId;
        bool specialGranted = false;

        if (_toyId == 1) {
            toysToPets[_toyId] = [1, 2, 3];
            return;
        } else if (_toyId == 2) {
            toysToPets[_toyId] = [151, 152, 153];
            return;
        } else if (_toyId == 3) {
            toysToPets[_toyId] = [301, 302, 303];
            return;
        }

        uint256[] memory petIds = new uint256[](petAmountPerBucketSize[_size]);

        for (uint8 i = 0; i < petAmountPerBucketSize[_size]; i++) {
            if (
                specialGranted == false &&
                specialPetAmounts[_type][_size] < specialPetsPerSize[_size] &&
                lastId > 0 &&
                lastId % 9 == 0
            ) {
                specialGranted = true;
                lastId = getSpecialTokenId(_type);
                mintedSpecialPetAmounts[_type]++;
                specialPetAmounts[_type][_size]++;
            } else {
                lastId = getTokenId(_type);
                mintedPetAmounts[_type]++;
            }

            petIds[i] = lastId;
        }

        toysToPets[_toyId] = petIds;

        emit Open(_type, _size, petIds, specialGranted);
    }

    function getTokenId(uint8 _type) private returns (uint256) {
        uint256[] memory range = petIdRanges[_type];
        uint256 maxTokensToMint = range[1] - range[0] + 1;

        uint256 maxIndex = maxTokensToMint - mintedPetAmounts[_type];

        uint256 random = _getRandomNumber(maxIndex, maxTokensToMint);

        uint256 tokenId = petIdMatrix[_type][random];

        if (tokenId == 0) {
            tokenId = random;
        }

        if (petIdMatrix[_type][maxIndex - 1] == 0) {
            petIdMatrix[_type][random] = maxIndex - 1;
        } else {
            petIdMatrix[_type][random] = petIdMatrix[_type][maxIndex - 1];
        }

        return tokenId + range[0];
    }

    function getSpecialTokenId(uint8 _type) private returns (uint256) {
        uint256[] memory range = specialPetIdRanges[_type];
        uint256 maxTokensToMint = range[1] - range[0] + 1;

        uint256 maxIndex = maxTokensToMint - mintedSpecialPetAmounts[_type];
        uint256 random = _getRandomNumber(maxIndex, maxTokensToMint);
        uint256 tokenId = specialPetIdMatrix[_type][random];

        if (tokenId == 0) {
            tokenId = random;
        }

        if (specialPetIdMatrix[_type][maxIndex - 1] == 0) {
            specialPetIdMatrix[_type][random] = maxIndex - 1;
        } else {
            specialPetIdMatrix[_type][random] = specialPetIdMatrix[_type][maxIndex - 1];
        }

        return tokenId + range[0];
    }


    function useSpecialTokenId(uint8 _type, uint256 _id) private {
        uint256[] memory range = specialPetIdRanges[_type];
        uint256 maxTokensToMint = range[1] - range[0] + 1;
        uint256 maxIndex = maxTokensToMint - mintedSpecialPetAmounts[_type];

        uint256 nonRandom = _id - range[0];

        uint256 tokenId = specialPetIdMatrix[_type][nonRandom];

        if (tokenId == 0) {
            tokenId = nonRandom;
        }

        if (specialPetIdMatrix[_type][maxIndex - 1] == 0) {
            specialPetIdMatrix[_type][nonRandom] = maxIndex - 1;
        } else {
            specialPetIdMatrix[_type][nonRandom] = specialPetIdMatrix[_type][maxIndex - 1];
        }
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper, uint256 _nonce) private view returns (uint256) {
        uint256 random = uint256(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _nonce,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return (random % _upper);
    }

    function getMintedPets() private view returns (uint16) {
        return (
            mintedPetAmounts[SCHOOL_KID] + mintedPetAmounts[ALIEN_BABY] + mintedPetAmounts[SNOW_CONE] +
            mintedSpecialPetAmounts[SCHOOL_KID] + mintedSpecialPetAmounts[ALIEN_BABY] + mintedSpecialPetAmounts[SNOW_CONE]
        );
    }
}
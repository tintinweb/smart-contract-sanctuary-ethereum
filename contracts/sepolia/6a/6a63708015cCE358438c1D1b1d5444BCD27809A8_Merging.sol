// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721Crystal {
    function mintCrystals(address to, uint24 _elementId, uint256 count) external payable;

    function burnCrystals(uint256[] calldata tokenIds) external;

    function elementId(uint256) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalMinted() external view returns (uint256);
}

contract Merging is Ownable, ReentrancyGuard {
    // ---- ERRORS ----
    error IncorrectElementsCount();
    error IncorrectElementNumber();
    error NotAllowedMergeMapRewrite();
    error IncorrectMergeSet();
    error IncorrectPercentsArrSize();
    error NotEqToHundredPercentsSum();

    // ---- CONSTANTS-BITS ----
    uint256 private constant _BITMASK_ELEMENT_ID = (1 << 10) - 1;
    uint256 private constant _BITLENGTH_ELEMENT_ID = 10;
    uint256 private constant _BITMASK_RESULT_PERCENT = (1 << 7) - 1;
    uint256 private constant _BITPOS_RESULT_PERCENT = 90;
    uint256 private constant _BITLENGTH_RESULT_PERCENT = 7;

    // ---- STORAGE ----
    IERC721Crystal public nftToken;

    // Bits Layout: elID~uint10 | Base%~uint7 | Modify~
    //    key:                value:
    // [0..9]    `el1`  |  [0..9 | 10..19 | 20..29]        `a1|a2|a3`
    // [10..19]  `el2`  |  [30..39 | 40..49 | 50..59]      `b1|b2|b3`
    // [20..29]  `el3`  |  [60..69 | 70..79 | 80..89]      `c1|c2|c3`
    // [30..39]  `el4`  |  [90..96 | 97..103 | 104..110]   `a%|b%|c%`
    mapping(uint256 => uint256) internal MergeMap;

    event MergeEvent(uint256[] mergeElements, uint256 startIndex, uint256 endIndex);

    constructor(IERC721Crystal _nftToken) {
        nftToken = _nftToken;
    }

    // ---- MAIN ----
    // -------------------------------
    function merge(uint256[] calldata tokenIds) public nonReentrant {
        uint256 tokensLen = tokenIds.length;
        if (tokensLen < 2) revert IncorrectElementsCount();
        if (tokensLen > 4) revert IncorrectElementsCount();

        uint256[] memory resultElements = _selectResultArr(tokenIds);

        nftToken.burnCrystals(tokenIds);

        uint256 count;
        for (uint256 i; i < resultElements.length; ) {
            unchecked {
                if (resultElements[i] > 0) {
                    nftToken.mintCrystals(msg.sender, uint24(resultElements[i]), 1);
                    ++count;
                }
                ++i;
            }
        }

        emit MergeEvent(tokenIds, nftToken.totalMinted() - (count + 1), count);
    }

    // view
    function getValuesFromKey(uint256 finalKey) public pure returns (uint256[] memory, uint256[] memory) {
        uint256 length = 9; // Get array length from first 4 bits
        uint256[] memory keys = new uint256[](length);
        uint256[] memory percents = new uint256[](3);

        // Extract keys from final key
        for (uint i = 0; i < length; ++i) {
            // Shift right by 10 bits times position and mask last 10 bits
            keys[i] = ((finalKey >> (i * _BITLENGTH_ELEMENT_ID)) & _BITMASK_ELEMENT_ID);
        }

        for (uint i = 0; i < 3; ++i) {
            percents[i] = ((finalKey >> (_BITLENGTH_RESULT_PERCENT * i + _BITPOS_RESULT_PERCENT)) &
                _BITMASK_RESULT_PERCENT);
        }

        return (keys, percents);
    }

    // ---- ADMIN ----
    // -------------------------------
    function setMergeMap(uint256[][5][] calldata Elements) external onlyOwner {
        for (uint256 i; i < Elements.length; ) {
            uint256 finalKey = _packElementBits(Elements[i][0]);

            if (MergeMap[finalKey] > 0) revert NotAllowedMergeMapRewrite();

            uint256 packedValue = _packValueBits(Elements[i][1], Elements[i][2], Elements[i][3], Elements[i][4]);
            MergeMap[finalKey] = packedValue;

            unchecked {
                ++i;
            }
        }
    }

    // ---- INTERNAL TOOLS ----
    // -------------------------------
    function _getElementIds(uint256[] calldata elements) internal view returns (uint256[] memory) {
        uint256[] memory elementIds = new uint256[](elements.length);
        for (uint256 i; i < elements.length; ) {
            elementIds[i] = nftToken.elementId(elements[i]);
            unchecked {
                ++i;
            }
        }

        return elementIds;
    }

    function _selectResultArr(uint256[] calldata tokenIds) internal view returns (uint256[] memory resultArr) {
        // generate pseudo-random number
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))) % 100;

        uint256[] memory elementIds = _getElementIds(tokenIds);
        uint256 key = _packElementBits(elementIds);

        if (MergeMap[key] <= 0) revert IncorrectMergeSet();

        uint256 a = (MergeMap[key] >> (_BITPOS_RESULT_PERCENT)) & _BITMASK_RESULT_PERCENT;
        uint256 b = (MergeMap[key] >> (_BITPOS_RESULT_PERCENT + _BITLENGTH_RESULT_PERCENT)) & _BITMASK_RESULT_PERCENT;
        // uint256 c = (MergeMap[key] >> (_BITPOS_RESULT_PERCENT + _BITLENGTH_RESULT_PERCENT * 2)) & _BITMASK_RESULT_PERCENT;

        resultArr = new uint256[](3);

        uint256 startBit;
        if (randomNum < a) {
            startBit = 0; // result A
        } else if (randomNum < (a + b)) {
            startBit = 30; // result B
        } else {
            startBit = 60; // result C
        }

        for (uint256 i; i < 3; ) {
            unchecked {
                uint256 value = (MergeMap[key] >> (startBit + i * _BITLENGTH_ELEMENT_ID)) & _BITMASK_ELEMENT_ID;
                if (value > 0) {
                    resultArr[i] = value;
                }
                ++i;
            }
        }
    }

    function _packValueBits(
        uint256[] calldata a,
        uint256[] calldata b,
        uint256[] calldata c,
        uint256[] calldata percents
    ) internal pure returns (uint256 packedValue) {
        uint256[] memory elements = a;

        if (percents.length != 3) revert IncorrectPercentsArrSize();
        if ((percents[0] + percents[1] + percents[2]) != 100) revert NotEqToHundredPercentsSum();
        for (uint256 i; i < 3; ) {
            unchecked {
                if (i == 0) elements = a;
                if (i == 1) elements = b;
                if (i == 2) elements = c;

                // if (elements.length < 1) revert IncorrectElementsCount();
                if (elements.length > 3) revert IncorrectElementsCount();

                for (uint256 j; j < elements.length; ) {
                    if (elements[j] < 100) revert IncorrectElementNumber();
                    if (elements[j] > 999) revert IncorrectElementNumber();

                    packedValue |= elements[j] << ((i * 3 + j) * _BITLENGTH_ELEMENT_ID);

                    ++j;
                }
                // pack drops percent for each array
                packedValue |= percents[i] << ((_BITLENGTH_RESULT_PERCENT * i) + _BITPOS_RESULT_PERCENT);

                ++i;
            }
        }
    }

    // pack elementIds to uint256 bits as mapping key
    function _packElementBits(uint256[] memory keyElements) internal pure returns (uint256 bitsUint) {
        keyElements = _insertionSort(keyElements);

        uint256 length = keyElements.length;

        if (length < 2) revert IncorrectElementsCount();
        if (length > 4) revert IncorrectElementsCount();

        for (uint256 i; i < length; ) {
            unchecked {
                if (keyElements[i] < 100) revert IncorrectElementNumber();
                if (keyElements[i] > 999) revert IncorrectElementNumber();

                bitsUint |= keyElements[i] << (i * _BITLENGTH_ELEMENT_ID);
                ++i;
            }
        }
    }

    // @github.com/vectorized/solady
    // sort array items in ascending order
    function _insertionSort(uint256[] memory a) public pure returns (uint256[] memory) {
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.
            let h := add(a, shl(5, n)) // High slot.
            let s := 0x20
            let w := not(31)
            for {
                let i := add(a, s)
            } 1 {

            } {
                i := add(i, s)
                if gt(i, h) {
                    break
                }
                let k := mload(i) // Key.
                let j := add(i, w) // The slot before the current slot.
                let v := mload(j) // The value of `j`.
                if iszero(gt(v, k)) {
                    continue
                }
                for {

                } 1 {

                } {
                    mstore(add(j, s), v)
                    j := add(j, w) // `sub(j, 0x20)`.
                    v := mload(j)
                    if iszero(gt(v, k)) {
                        break
                    }
                }
                mstore(add(j, s), k)
            }
            mstore(a, n) // Restore the length of `a`.
        }

        return a;
    }
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
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./libs/IDescriptor.sol";
import "./libs/StringsA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DescriptorBBC is IDescriptor, Ownable {
    using StringsA for uint256;

    address public descriptedContract;
    string private _baseURL =
        "https://arweave.net/DKpf6UOgobZQIua-Y3_t-VrWWf6TuJZX9ZR_CTASnIw11/";
    string private _baseURLVeil =
        "https://arweave.net/DKpf6UOgobZQIua-Y3_t-VrWWf6TuJZX9ZR_CTASnIw/";
    string private _imageExt = ".png";
    string private _imageExtVeil = ".jpg";
    string private constant _name = "BabyBunta 2nd collection";
    string private _description =
        unicode'\\"Bunta\\" is one of the most fashionable pugs and loves to make people happy.  \\n  He%27s a baby but he looks like an uncle!  \\n  \\n  I am striving to reach the top of the pug world someday.  \\n  \\n  \\"ぶんた\\"はパグの中でも大のオシャレ好きで、人を幸せにする事が大好きです。  \\n  赤ちゃんですが見た目はおじさんです！  \\n  \\n  いつの日かパグ界の頂点を目指して奮闘中です。';

    bool public revealed;

    error InvalidCaller(address caller);

    constructor(address __addr) {
        setDescriptedContract(__addr);
    }

    function setDescriptedContract(address _addr) public onlyOwner {
        descriptedContract = _addr;
    }

    function setBaseURL(string memory _newURL) external onlyOwner {
        _baseURL = _newURL;
    }

    function setBaseURLVeil(string memory _newURL) external onlyOwner {
        _baseURLVeil = _newURL;
    }

    function setImageExt(string memory _newExt) external onlyOwner {
        _imageExt = _newExt;
    }

    function setImageExtVeil(string memory _newExt) external onlyOwner {
        _imageExtVeil = _newExt;
    }

    function setDescription(string memory _newDescription) external onlyOwner {
        _description = _newDescription;
    }

    function setReveal(bool _state) external onlyOwner {
        revealed = _state;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (msg.sender != descriptedContract) revert InvalidCaller(msg.sender);
        string memory strId = tokenId.toString();
        string memory imageId;
        string memory url;
        string memory extension;
        if (revealed) {
            imageId = strId;
            url = _baseURL;
            extension = _imageExt;
        } else {
            imageId = (uint256(keccak256(abi.encodePacked("BBC#", tokenId))) %
                3).toString();
            url = _baseURLVeil;
            extension = _imageExtVeil;
        }

        return
            string.concat(
                "data:application/json;,",
                '{"name":"',
                _name,
                " #",
                strId,
                '","description":"',
                _description,
                '","image":"',
                url,
                imageId,
                extension,
                '","attributes":{}}'
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// Extracted from ERC721A v4.2.3
pragma solidity ^0.8.4;

library StringsA {
    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}
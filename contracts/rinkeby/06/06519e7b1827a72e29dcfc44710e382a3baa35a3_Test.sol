// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

//import {ERC165} from "@openzeppelin/[email protected]/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

import "./UTF8.sol";
import "./IEmoji.sol";
import "./IValidator.sol";

contract Test is Ownable {

    address public emoji;
    address public validator;

    function setEmoji(address x) public onlyOwner {
        emoji = x;
    }

    function setValidator(address x) public onlyOwner {
        validator = x;
    }

    function decode(string memory s) public pure returns (uint24[] memory) {
        return UTF8.decode(bytes(s));
    }

    function filter(string memory s, bool skipFE0F) public view returns (uint24[] memory) {
        return IEmoji(emoji).filter(decode(s), skipFE0F);
    }

    function isEmoji(string memory s) public view returns (bool) {
        uint24[] memory v = IEmoji(emoji).filter(decode(s), true);
        return v.length == 1 && v[0] > 0x10FFFF;
    }

    function validate(string memory s) public view returns (bool) {
        IValidator(validator).validate(IEmoji(emoji).filter(decode(s), false));
        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IValidator {
    //function name() external view returns (string);
    function validate(uint24[] memory cps) external view;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IEmoji {
    function filter(uint24[] memory cps, bool skipFE0F) external view returns (uint24[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

library UTF8 {

    error InvalidUTF8();

    function decode(bytes memory v) public pure returns (uint24[] memory cps) {
        uint256 n = v.length;
		cps = new uint24[](n);
		uint256 i;
		uint256 j;
		unchecked { while (i < n) {
			uint256 cp = uint8(v[i++]);
			if ((cp & 0x80) == 0) { // [1] 0xxxxxxx
				//
			} else if ((cp & 0xE0) == 0xC0) { // [2] 110xxxxx (5)
				if (i >= n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				if ((a & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0x1F) << 6) | a;
				if (cp < 0x80) revert InvalidUTF8();
			} else if ((cp & 0xF0) == 0xE0) { // [3] 1110xxxx (4)
				if (i + 2 > n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				uint256 b = uint8(v[i++]);
				if (((a | b) & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0xF) << 12) | ((a & 0x3F) << 6) | (b & 0x3F);
				if (cp < 0x0800) revert InvalidUTF8();
			} else if ((cp & 0xF8) == 0xF0) { // [4] 11110xxx (3)
				if (i + 3 > n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				uint256 b = uint8(v[i++]);
				uint256 c = uint8(v[i++]);
				if (((a | b | c) & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0x7) << 18) | ((a & 0x3F) << 12) | ((b & 0x3F) << 6) | (c & 0x3F);
				if (cp < 0x10000 || cp > 0x10FFFF) revert InvalidUTF8();
			} else {
				revert InvalidUTF8();
			}
			cps[j++] = uint24(cp);
		} }
		assembly { mstore(cps, j) }
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
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

contract Ethmoji is Ownable {

	uint256 constant EMOJI_STATE_MASK  = 0x07FF; 
	uint256 constant EMOJI_STATE_QUIRK = 0x0800;
	uint256 constant EMOJI_STATE_VALID = 0x1000;
	uint256 constant EMOJI_STATE_SAVE  = 0x2000;
	uint256 constant EMOJI_STATE_CHECK = 0x4000;
	uint256 constant EMOJI_STATE_FE0F  = 0x8000;

	mapping (uint256 => uint256) _emoji;

	function uploadEmoji(bytes calldata data) public onlyOwner {
        uint256 i;
		uint256 e;
	    uint256 mask = 0xFFFFFFFF;
		assembly {
			i := data.offset
			e := add(i, data.length)
		}
		while (i < e) {
			uint256 k;
			uint256 v;
			assembly {
				v := calldataload(i)
				i := add(i, 4)
				k := and(calldataload(i), mask)
				i := add(i, 32)
			}
			_emoji[k] = v;
		}
	}

	function getEmoji(uint256 s0, uint256 cp) private view returns (uint256) {
		return (_emoji[(s0 << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
	}

	function debugEmojiState(uint256 s0, uint256 cp) public view returns (uint256 value, bool fe0f, bool check, bool save, bool valid, bool quirk, uint256 s1) {
		value = getEmoji(s0, cp);
		fe0f = (value & EMOJI_STATE_FE0F) != 0;
		check = (value & EMOJI_STATE_CHECK) != 0;
		save = (value & EMOJI_STATE_SAVE) != 0;
		valid = (value & EMOJI_STATE_VALID) != 0;
		quirk = (value & EMOJI_STATE_QUIRK) != 0;
		s1 = value & EMOJI_STATE_MASK; // next state
	}

    function test(string memory name) public view returns (string memory) {
        return string(beautify(bytes(name)));
    }

	function beautify(bytes memory name) private view returns (bytes memory ret) {
        uint256 len = name.length;
        require(len >= 7, "too short"); // 3 + ".eth"
        uint256 off;
        uint256 end;
        uint256 prev;
        uint256 next;  
        assembly {
            off := mload(add(name, len))
        }
        require((off & 0xFFFFFFFF) == 0x2E657468, ".eth"); // require that it ends in .eth
        len -= 4;
        ret = new bytes(len << 1); // we might add fe0f
        assembly {
			off := name
			end := add(off, len)
			prev := ret
		}
		while (off < end) {
			(off, next) = processEmoji(off, end, prev);
			require(next > prev, "not emoji"); 
            prev = next;			
        }
        assembly {
			mstore(ret, sub(prev, ret))
		}
    }

    function processEmoji(uint256 pos, uint256 end, uint256 dst0) private view returns (uint256 valid_pos, uint256 dst) {
		unchecked {
			uint256 state;
			uint256 fe0f;
			uint256 saved;
			uint256 buf; // the largest emoji is 35 bytes, which exceeds 32-byte buf
			uint256 len; // but the largest non-valid emoji sequence is only 27-bytes
			dst = dst0;
			while (pos < end) {
				(uint256 cp, uint256 step, uint256 raw) = readUTF8(pos);
                if (cp == 0xFE0F) {
                    if (fe0f == 0) break; // invalid FEOF
                    fe0f = 0; // clear flag to prevent more
					pos += step; // skip over FE0F
					if (len == 0) { // last was valid so
						valid_pos = pos; // consume FE0F as well
					}
                } else {
                    state = getEmoji(state & EMOJI_STATE_MASK, cp);
                    if (state == 0) break;
                    if ((state & EMOJI_STATE_SAVE) != 0) { 
                        saved = cp; 
                    } else if ((state & EMOJI_STATE_CHECK) != 0) { 
                        if (cp == saved) break;
                    }
                    pos += step; 
                    len += step; 
                    buf = (buf << (step << 3)) | raw; // use raw instead of converting cp back to UTF8
                    fe0f = state & EMOJI_STATE_FE0F;
                    if (fe0f != 0) {
                        buf = (buf << 24) | 0xEFB88F; // UTF8-encoded FE0F
                        len += 3;
                    }
                    if ((state & EMOJI_STATE_VALID) != 0) { // valid
                        if ((state & EMOJI_STATE_QUIRK) != 0) {
                            dst -= 3; // overwrite the last FE0F
                        }
                        dst = appendBytes(dst, buf, len);
                        buf = 0;
                        len = 0;
                        valid_pos = pos; // everything output so far is valid
                    } 
                }
            }
		}
	}

	// read one cp from memory at ptr
	// step is number of encoded bytes (1-4)
	// raw is encoded bytes
	// warning: assumes valid UTF8
	function readUTF8(uint256 ptr) private pure returns (uint256 cp, uint256 step, uint256 raw) {
		// 0xxxxxxx => 1 :: 0aaaaaaa ???????? ???????? ???????? =>                   0aaaaaaa
		// 110xxxxx => 2 :: 110aaaaa 10bbbbbb ???????? ???????? =>          00000aaa aabbbbbb
		// 1110xxxx => 3 :: 1110aaaa 10bbbbbb 10cccccc ???????? => 000000aa aaaabbbb bbcccccc
		// 11110xxx => 4 :: 11110aaa 10bbbbbb 10cccccc 10dddddd => 000aaabb bbbbcccc ccdddddd
		assembly {
			raw := and(mload(add(ptr, 4)), 0xFFFFFFFF)
		}
		uint256 upper = raw >> 28;
		if (upper < 0x8) {
			step = 1;
			raw >>= 24;
			cp = raw;
		} else if (upper < 0xE) {
			step = 2;
			raw >>= 16;
			cp = ((raw & 0x1F00) >> 2) | (raw & 0x3F);
		} else if (upper < 0xF) {
			step = 3;
			raw >>= 8;
			cp = ((raw & 0x0F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		} else {
			step = 4;
			cp = ((raw & 0x07000000) >> 6) | ((raw & 0x3F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		}
	}

	// write len lower-bytes of buf at ptr
	// return ptr advanced by len
	function appendBytes(uint256 ptr, uint256 buf, uint256 len) private pure returns (uint256 ptr1) {
		assembly {
			ptr1 := add(ptr, len) // advance by len bytes
			let word := mload(ptr1) // load right-aligned word
			let mask := sub(shl(shl(3, len), 1), 1) // compute len-byte mask: 1 << (len << 3) - 1
			mstore(ptr1, or(and(word, not(mask)), and(buf, mask))) // merge and store
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
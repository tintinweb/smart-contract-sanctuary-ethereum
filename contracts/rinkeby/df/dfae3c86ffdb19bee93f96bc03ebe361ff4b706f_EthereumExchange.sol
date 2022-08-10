/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/marketplace/ethereum/token/ERC20/ERC20Basic.sol


pragma solidity ^0.8.0;

interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    external view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


// File contracts/library/SafeMath.sol


pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;

		return c;
	}

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}
}


// File contracts/library/ArrayUtils.sol


pragma solidity ^0.8.0;

library ArrayUtils {
  function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask) internal pure {
    require(array.length == desired.length);
    require(array.length == mask.length);

    uint words = array.length / 0x20;
    uint index = words * 0x20;
    assert(index / 0x20 == words);
    uint i;

    for (i = 0; i < words; i++) {
      assembly {
        let commonIndex := mul(0x20, add(1, i))
        let maskValue := mload(add(mask, commonIndex))
        mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
      }
    }

    if (words > 0) {
      i = words;
      assembly {
        let commonIndex := mul(0x20, add(1, i))
        let maskValue := mload(add(mask, commonIndex))
        mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
      }
    } else {
      for (i = index; i < array.length; i++) {
        array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
      }
    }
  }

  function arrayEq(bytes memory a, bytes memory b) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(a)

      switch eq(length, mload(b))
      case 1 {
        let cb := 1

        let mc := add(a, 0x20)
        let end := add(mc, length)

        for { 
          let cc := add(b, 0x20)
        } eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          if iszero(eq(mload(mc), mload(cc))) {
            success := 0
            cb := 0
          }
        }
      }
      default {
        success := 0
      }
    }
    return success;
  }

  function unsafeWriteBytes(uint index, bytes memory source) internal pure returns (uint) {
    if (source.length > 0) {
      assembly {
        let length := mload(source)
        let end := add(source, add(0x20, length))
        let arrIndex := add(source, 0x20)
        let tempIndex := index
        for { } eq(lt(arrIndex, end), 1) {
          arrIndex := add(arrIndex, 0x20)
          tempIndex := add(tempIndex, 0x20)
        } {
          mstore(tempIndex, mload(arrIndex))
        }
        index := add(index, length)
      }
    }
    return index;
  }

  function unsafeWriteAddress(uint index, address source) internal pure returns (uint) {
    uint conv = uint(uint160(source)) << 0x60;
    assembly {
      mstore(index, conv)
      index := add(index, 0x14)
    }
    return index;
  }

  function unsafeWriteUint(uint index, uint source) internal pure returns (uint) {
    assembly {
      mstore(index, source)
      index := add(index, 0x20)
    }
    return index;
  }

  function unsafeWriteUint8(uint index, uint8 source) internal pure returns (uint) {
    assembly {
      mstore8(index, source)
      index := add(index, 0x1)
    }
    return index;
  }
}


// File contracts/library/Context.sol


pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal pure returns (bytes memory) {
    return msg.data;
  }

  function _msgValue() internal view returns (uint256) {
    return msg.value;
  }
}


// File contracts/common/Ownable.sol


pragma solidity ^0.8.0;

contract Ownable is Context {
  address private _owner;
  /* owner 제거 시 event*/
  event OwnershipRenounced(address indexed previousOwner);
  /* 기존 owner에서 새로운 Owner로 owner 변경*/
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = _msgSender();
  }

  modifier onlyOwner() {
    require(_msgSender() == _owner, "Ownable: owner not matched");
    _;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  /* owner 변경 */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: owner is must be not zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /* owner 제거 */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }
}


// File contracts/marketplace/ethereum/MarketplaceStorage.sol


pragma solidity ^0.8.0;


contract EthereumMarketplaceStorage is Context, Ownable {
  mapping(bytes32 => uint) private saleCounts;
  mapping(address => bool) private adminAddresses;
  mapping(address => bool) private tradableTokenAddresses;
  mapping(bytes32 => bool) private cancelled;
  
  address payable private feeAddress;
  address private marketplaceAddress;

  uint private marketplaceFee;
  bool private paused = false;

  modifier onlyMarketplace() {
    require(_msgSender() == marketplaceAddress, "storage modify function call is possible only marketplace address");
    _;
  }

  function setFeeAddress(address payable feeAddress_) public onlyOwner {
    require(feeAddress_ != address(0), "fee address must not be a zero address");
    require(feeAddress != feeAddress_, "already set fee address");

    feeAddress = feeAddress_;
  }

  function getFeeAddress() public view returns (address payable) {
    return feeAddress;
  }

  function setMarketplaceAddress(address marketplaceAddress_) public onlyOwner {
    require(marketplaceAddress_ != address(0), "marketplace address must not be a zero address");
    require(marketplaceAddress != marketplaceAddress_, "already set marketplace address");

    marketplaceAddress = marketplaceAddress_;
  }

  function getMarketplaceAddress() public view returns (address) {
    return marketplaceAddress;
  }

  function setMarketplaceFee(uint marketplaceFee_) public onlyOwner {
    require(marketplaceFee_ != 0, "marketplace fee must not be a zero");

    marketplaceFee = marketplaceFee_;
  }

  function getMarketplaceFee() public view returns (uint) {
    return marketplaceFee;
  }

  function setSaleCount(bytes32 hash, uint count) public onlyMarketplace {
    require(count > 0, "count must bigger than zero");

    saleCounts[hash] += count;
  }

  function getSaleCount(bytes32 hash) public view returns (uint) {
    return saleCounts[hash];
  }

  function setCancelled(bytes32 hash, bool cancel) public onlyMarketplace {
    require(isCancelled(hash) != cancel, "already set cancelled");

    cancelled[hash] = cancel;
  }

  function isCancelled(bytes32 hash) public view returns (bool) {
    return cancelled[hash];
  }

  function setAdminAddress(address adminAddress, bool active) public onlyOwner {
    require(adminAddress != address(0), "admin address must not be a zero address");
    require(isActiveAdminAddress(adminAddress) != active, "already set admin adress");

    adminAddresses[adminAddress] = active;
  }

  function isActiveAdminAddress(address adminAddress) public view returns (bool) {
    return adminAddresses[adminAddress];
  }

  function setTradableTokenAddress(address tokenAddress, bool active) public onlyOwner {
    require(tokenAddress != address(0), "token address must not be a zero address");
    require(isActiveTradableTokenAddress(tokenAddress) != active, "already set tradable token address");
    
    tradableTokenAddresses[tokenAddress] = active;
  }

  function isActiveTradableTokenAddress(address tokenAddress) public view returns (bool) {
    return tradableTokenAddresses[tokenAddress];
  }
}


// File solidity-bytes-utils/contracts/[email protected]

// SPDX-License-Identifier: MIT
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}


// File contracts/marketplace/ethereum/exchange/EthereumExchangeCore.sol


pragma solidity ^0.8.0;



contract EthereumExchangeCore is Context {

  address private storageAddress;

  enum SellType { FixedPrice, Auction, Offer }
  enum PublishType { Mint, Transfer }

  uint public constant INVERSE_BASIS_POINT = 10000;

  struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct SellOrder {
    address payable royaltyReceiver;
    address payable creator;
    address payable maker;
    address payable taker;
    address target;
    address paymentToken;
    address reserveBuyer;
    uint itemId;
    uint tokenId;
    uint quantity;
    uint offerId;
    uint bidId;
    uint editionCount;
    uint royalty;
    uint basePrice;
    uint reservePrice;
    uint listingTime;
    uint expirationTime;
    SellType sellType;
    PublishType publishType;
    bytes callData;
    bytes saleUniqueId;
  }

  struct BuyOrder {
    address payable maker;
    address payable taker;
    address target;
    address paymentToken;
    uint itemId;
    uint tokenId;
    uint quantity;
    uint royalty;
    uint price;
    uint expirationTime;
    bytes callData;
  }

  event OrdersMatched (address indexed from, address indexed to, address indexed paymentToken, uint itemId, uint price);
  event AcceptOffer (address indexed offeror, uint itemId, uint offerId);
  event AcceptBid (address indexed bidder, uint itemId, uint bidId);
  event SaleAmount (address indexed paymentToken, uint itemId, uint price, uint royalty, uint fee);
  event OrderCancelled (address indexed sender, uint itemId);
  event OrderResale (address indexed sender, uint itemId);

  constructor() {}

  function sizeOfSellOrder(SellOrder memory sellOrder) internal pure returns (uint) {
    return ((0x14 * 7) + (0x20 * 11) + 2 + sellOrder.callData.length + sellOrder.saleUniqueId.length);
  }

  function sizeOfBuyOrder(BuyOrder memory buyOrder) internal pure returns (uint) {
    return ((0x14 * 4) + (0x20 * 6) + buyOrder.callData.length);
  }

  function hashSellOrder_(SellOrder memory sellOrder) internal pure returns (bytes32 hash) {
    uint size = sizeOfSellOrder(sellOrder);
    bytes memory array = new bytes(size);
		uint index;
		assembly {
			index := add(array, 0x20)
		}
		index = ArrayUtils.unsafeWriteAddress(index, sellOrder.royaltyReceiver);
    index = ArrayUtils.unsafeWriteAddress(index, sellOrder.creator);
		index = ArrayUtils.unsafeWriteAddress(index, sellOrder.maker);
		index = ArrayUtils.unsafeWriteAddress(index, sellOrder.taker);
    index = ArrayUtils.unsafeWriteAddress(index, sellOrder.target);
    index = ArrayUtils.unsafeWriteAddress(index, sellOrder.paymentToken);
    index = ArrayUtils.unsafeWriteAddress(index, sellOrder.reserveBuyer);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.itemId);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.tokenId);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.quantity);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.offerId);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.bidId);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.editionCount);
		index = ArrayUtils.unsafeWriteUint(index, sellOrder.royalty);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.basePrice);
		index = ArrayUtils.unsafeWriteUint(index, sellOrder.reservePrice);
    index = ArrayUtils.unsafeWriteUint(index, sellOrder.listingTime);
		index = ArrayUtils.unsafeWriteUint(index, sellOrder.expirationTime);
    index = ArrayUtils.unsafeWriteUint8(index, uint8(sellOrder.sellType));
		index = ArrayUtils.unsafeWriteUint8(index, uint8(sellOrder.publishType));
    index = ArrayUtils.unsafeWriteBytes(index, sellOrder.callData);
    index = ArrayUtils.unsafeWriteBytes(index, sellOrder.saleUniqueId);
		assembly {
			hash := keccak256(add(array, 0x20), size)
		}
		return hash;
  }

  function hashBuyOrder_(BuyOrder memory buyOrder) internal pure returns (bytes32 hash) {
    uint size = sizeOfBuyOrder(buyOrder);
    bytes memory array = new bytes(size);
		uint index;
		assembly {
			index := add(array, 0x20)
		}
		index = ArrayUtils.unsafeWriteAddress(index, buyOrder.maker);
		index = ArrayUtils.unsafeWriteAddress(index, buyOrder.taker);
    index = ArrayUtils.unsafeWriteAddress(index, buyOrder.target);
    index = ArrayUtils.unsafeWriteAddress(index, buyOrder.paymentToken);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.itemId);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.tokenId);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.quantity);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.royalty);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.price);
    index = ArrayUtils.unsafeWriteUint(index, buyOrder.expirationTime);
    index = ArrayUtils.unsafeWriteBytes(index, buyOrder.callData);
		assembly {
			hash := keccak256(add(array, 0x20), size)
		}
		return hash;
  }

  function buyOrderToHash(BuyOrder memory buyOrder) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashBuyOrder_(buyOrder)));
	}

  function sellOrderToHash(SellOrder memory sellOrder) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashSellOrder_(sellOrder)));
	}

  function requireValidBuyOrder(BuyOrder memory buyOrder, Sig memory sig) internal pure returns (bytes32) {
    bytes32 hash = buyOrderToHash(buyOrder);

    require(ecrecover(hash, sig.v, sig.r, sig.s) == buyOrder.maker, "not matched buy hash maker");
    return hash;
  }

  function requireValidSellOrder(SellOrder memory sellOrder, Sig memory sig) internal pure returns (bytes32) {
    bytes32 hash = sellOrderToHash(sellOrder);

    require(ecrecover(hash, sig.v, sig.r, sig.s) == sellOrder.maker, "not matched sell hash maker");
    return hash;
  }

  function calculatePrice(SellOrder memory sellOrder, BuyOrder memory buyOrder) pure internal returns (uint) {
    if (sellOrder.sellType == SellType.FixedPrice) {
      require(sellOrder.basePrice == buyOrder.price, "sell price and buy price not matched");
    } else if (sellOrder.sellType == SellType.Auction) {
      require(sellOrder.basePrice <= buyOrder.price, "buyPrice must be greater or equal than sellPrice when auction order");
    } else if (sellOrder.sellType == SellType.Offer) {
      require(sellOrder.basePrice == buyOrder.price, "sell price and buy price not matched");
    } else {
      revert("sell type not matched");
    }

    return buyOrder.price;
  }

  function tokenTransfer(SellOrder memory sellOrder, BuyOrder memory buyOrder) internal returns (uint, uint, uint) {
    EthereumMarketplaceStorage marketStorage = EthereumMarketplaceStorage(storageAddress);

    uint fee = marketStorage.getMarketplaceFee();
    if (sellOrder.paymentToken != address(0)) {
      require(msg.value == 0, "when ERC20 transfer, must be value is zero");
      require(marketStorage.isActiveTradableTokenAddress(sellOrder.paymentToken), "impossible transfer token type");
    }

    uint price = calculatePrice(sellOrder, buyOrder);

    if (price == 0) {
      return (0, 0, 0);
    }

    uint royaltyAmount = 0;
    uint feeAmount = 0;
    uint receiveAmount = 0;

    if (sellOrder.royaltyReceiver != address(0) && sellOrder.royalty > 0) {
      royaltyAmount = SafeMath.div(SafeMath.mul(sellOrder.royalty, price), INVERSE_BASIS_POINT);
    }

    address payable feeAddress = marketStorage.getFeeAddress();
    bool isActiveAdminAddress = marketStorage.isActiveAdminAddress(sellOrder.maker);

    if (feeAddress != address(0) && fee > 0) {
      feeAmount = SafeMath.div(SafeMath.mul(fee, price), INVERSE_BASIS_POINT);
    }

    receiveAmount = SafeMath.sub(SafeMath.sub(price, royaltyAmount), feeAmount);

    if (sellOrder.paymentToken == address(0)) {
      require(_msgValue() == buyOrder.price, "not matched buy price with value");
      feeAddress.transfer(feeAmount);

      if (sellOrder.publishType == PublishType.Mint && isActiveAdminAddress) {
        sellOrder.creator.transfer(receiveAmount);
        sellOrder.royaltyReceiver.transfer(royaltyAmount);
      } else {
        sellOrder.maker.transfer(receiveAmount);
        sellOrder.royaltyReceiver.transfer(royaltyAmount);
      }
    } else {
      require(ERC20(sellOrder.paymentToken).transferFrom(buyOrder.maker, feeAddress, feeAmount), "failed fee amount transfer");
      if (sellOrder.publishType == PublishType.Mint && isActiveAdminAddress) {
        require(ERC20(sellOrder.paymentToken).transferFrom(buyOrder.maker, sellOrder.creator, receiveAmount), "failed receive amount transfer to royaltyReceiver");
        require(ERC20(sellOrder.paymentToken).transferFrom(buyOrder.maker, sellOrder.royaltyReceiver, royaltyAmount), "failed royalty amount transfer to royaltyReceiver");
      } else {
        require(ERC20(sellOrder.paymentToken).transferFrom(buyOrder.maker, sellOrder.maker, receiveAmount), "failed receive amount transfer to maker");
        require(ERC20(sellOrder.paymentToken).transferFrom(buyOrder.maker, sellOrder.royaltyReceiver, royaltyAmount), "failed royalty amount transfer to royaltyReceiver");
      }
    }

    return (price, royaltyAmount, feeAmount);
  }

  function ordersMatch(BuyOrder memory buyOrder, SellOrder memory sellOrder) internal view returns (bool) {
    EthereumMarketplaceStorage marketStorage = EthereumMarketplaceStorage(storageAddress);
    bool isAdminMaker = marketStorage.isActiveAdminAddress(sellOrder.maker);

    if (
      buyOrder.target != sellOrder.target ||
      buyOrder.paymentToken != sellOrder.paymentToken ||
      buyOrder.itemId != sellOrder.itemId ||
      buyOrder.royalty != sellOrder.royalty ||
      buyOrder.tokenId != sellOrder.tokenId ||
      buyOrder.quantity != sellOrder.quantity
    ) {
      return false;
    }

    if (sellOrder.sellType == SellType.FixedPrice) {
      if (sellOrder.listingTime != 0 && sellOrder.listingTime > block.timestamp) {
        return false;
      }

      if (sellOrder.expirationTime != 0 && sellOrder.expirationTime < block.timestamp) {
        return false;
      }

      if (buyOrder.maker != _msgSender()) {
        return false;
      }

      if (sellOrder.reserveBuyer != address(0) && sellOrder.reserveBuyer != _msgSender()) {
        return false;
      }

      if (isAdminMaker && sellOrder.creator != buyOrder.taker) {
        return false;
      }

      if (!isAdminMaker && sellOrder.maker != buyOrder.taker) {
        return false;
      }
    } else if (sellOrder.sellType == SellType.Auction) {
      if (buyOrder.price == 0) {
        return false;
      }

      if (sellOrder.reservePrice != 0 && sellOrder.basePrice > sellOrder.reservePrice) {
        return false;
      }

      if (sellOrder.reservePrice == 0 || (sellOrder.reservePrice > buyOrder.price)) {
        if (sellOrder.expirationTime != 0 && sellOrder.expirationTime > block.timestamp) {
          return false;
        }

        if (sellOrder.maker != buyOrder.taker) {
          return false;
        }

        if (sellOrder.maker != _msgSender()) {
          return false;
        }
      } else {
        if (buyOrder.maker != _msgSender()) {
          return false;
        }

        if (sellOrder.publishType == PublishType.Mint && sellOrder.creator != buyOrder.taker) {
          return false;
        }

        if (sellOrder.publishType == PublishType.Transfer && sellOrder.maker != buyOrder.taker) {
          return false;
        }
      }
    } else if (sellOrder.sellType == SellType.Offer) {
      if (buyOrder.price == 0) {
        return false;
      }

      if (buyOrder.expirationTime != 0 && buyOrder.expirationTime < block.timestamp) {
        return false;
      }

      if (sellOrder.maker != _msgSender()) {
        return false;
      }

      if (buyOrder.taker != sellOrder.maker) {
        return false;
      }
    } else {
      return false;
    }

    return true;
  }

  function validateCallData(SellOrder memory sellOrder, BuyOrder memory buyOrder) internal pure {
    bytes memory sellOrderCallData = sellOrder.callData;
    bytes memory buyOrderCallData = buyOrder.callData;

    bytes memory encodedMintTo = abi.encodePacked(keccak256("mintTo(address,string,uint256)"));
    bytes memory encodedTransferFrom = abi.encodePacked(keccak256("transferFrom(address,address,uint256)"));
    bytes memory encodedSafeTransferFrom = abi.encodePacked(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    bytes memory mintToFunctionName = BytesLib.slice(encodedMintTo, 0, 4);
    bytes memory transferFromFunctionName = BytesLib.slice(encodedTransferFrom, 0, 4);
    bytes memory safeTransferFromFunctionName = BytesLib.slice(encodedSafeTransferFrom, 0, 4);
    bytes memory functionName = BytesLib.slice(sellOrderCallData, 0, 4);

    bool isMintTo = BytesLib.equal(mintToFunctionName, functionName);
    bool isTransferFrom = BytesLib.equal(transferFromFunctionName, functionName);
    bool isSafeTransferFrom = BytesLib.equal(safeTransferFromFunctionName, functionName);

    if (isMintTo) {
      // mint to의 from
      require(
        BytesLib.toAddress(buyOrderCallData, 16) == buyOrder.maker,
        "not matched buy order maker with to address"
      );
    } else if (isTransferFrom) {
      // tranferFrom의 from
      require(
        BytesLib.toAddress(sellOrderCallData, 16) == sellOrder.maker &&
        BytesLib.toAddress(buyOrderCallData, 16) == sellOrder.maker,
        "not matched buy order maker with transfer from address"
      );

      // transferFrom의 to
      require(
        BytesLib.toAddress(buyOrderCallData, 48) == buyOrder.maker ||
        BytesLib.toAddress(sellOrderCallData, 48) == buyOrder.maker,
        "not matched sell order maker with transfer to address"
      );

      require(
        BytesLib.toUint256(buyOrderCallData, 68) == sellOrder.tokenId &&
        BytesLib.toUint256(sellOrderCallData, 68) == sellOrder.tokenId,
        "not matched token id with transfer token id"
      );
    } else if (isSafeTransferFrom) {
      require(
        BytesLib.toAddress(sellOrderCallData, 16) == sellOrder.maker &&
        BytesLib.toAddress(buyOrderCallData, 16) == sellOrder.maker,
        "not matched buy order maker with transfer from address"
      );

      require(
        BytesLib.toAddress(buyOrderCallData, 48) == buyOrder.maker ||
        BytesLib.toAddress(sellOrderCallData, 48) == buyOrder.maker,
        "not matched sell order maker with transfer to address"
      );

      require(
        BytesLib.toUint256(buyOrderCallData, 68) == sellOrder.tokenId &&
        BytesLib.toUint256(sellOrderCallData, 68) == sellOrder.tokenId,
        "not matched token id with transfer token id"
      );

      require(
        BytesLib.toUint256(buyOrderCallData, 100) == sellOrder.quantity &&
        BytesLib.toUint256(sellOrderCallData, 100) == sellOrder.quantity,
        "not matched quantity with transfer amount"
      );
    } else {
      revert("not matched function name");
    }
  }

  function nftTransfer(SellOrder memory sellOrder, BuyOrder memory buyOrder) internal returns (bool) {
    bool result;

    validateCallData(sellOrder, buyOrder);

    if (sellOrder.sellType == SellType.Offer) {
      (result, ) = sellOrder.target.call(sellOrder.callData);
    } else if (sellOrder.sellType == SellType.Auction) {
      if (_msgSender() == sellOrder.creator || _msgSender() == sellOrder.maker) {
        (result, ) = sellOrder.target.call(sellOrder.callData);
      } else {
        (result, ) = sellOrder.target.call(buyOrder.callData);
      }
    } else {
      (result, ) = sellOrder.target.call(buyOrder.callData);
    }

    return result;
  }

  function executeOrder_(SellOrder memory sellOrder, Sig memory sellSig, BuyOrder memory buyOrder, Sig memory buySig) internal {
    bytes32 sellHash = hashSellOrder_(sellOrder);
    EthereumMarketplaceStorage marketStorage = EthereumMarketplaceStorage(storageAddress);

    require(!marketStorage.isCancelled(sellHash), "already cancel order");
    require(buyOrder.maker == _msgSender() || sellOrder.maker == _msgSender() || sellOrder.creator == _msgSender(), "msg sender unknown");

    if (sellOrder.maker == _msgSender()) {
      requireValidBuyOrder(buyOrder, buySig);
    } else {
      requireValidSellOrder(sellOrder, sellSig);
    }

    require(ordersMatch(buyOrder, sellOrder), "orders that cannot be processed");
    require(marketStorage.getSaleCount(sellHash) < sellOrder.editionCount, "not enough quantity");

    uint size;
    address target = sellOrder.target;
    assembly {
      size := extcodesize(target)
    }
    require(size > 0, "target not exist");

    (uint price, uint royalty, uint fee) = tokenTransfer(sellOrder, buyOrder);

    bool nftTransferResult = nftTransfer(sellOrder, buyOrder);
    require(nftTransferResult, "NFT transfer or mint failed");

    marketStorage.setSaleCount(sellHash, sellOrder.quantity);

    if (sellOrder.sellType == SellType.Auction) {
      emit AcceptBid(buyOrder.maker, sellOrder.itemId, sellOrder.bidId);
    } else if (sellOrder.sellType == SellType.Offer) {
      emit AcceptOffer(buyOrder.maker, sellOrder.itemId, sellOrder.offerId);
    }

    emit OrdersMatched(sellOrder.maker, buyOrder.maker, sellOrder.paymentToken, sellOrder.itemId, price);
    emit SaleAmount(sellOrder.paymentToken, sellOrder.itemId, price, royalty, fee);
  }

  function cancelOrder_(SellOrder memory sellOrder, Sig memory sig) internal {
    bytes32 hash = hashSellOrder_(sellOrder);
    requireValidSellOrder(sellOrder, sig);

    require(sellOrder.maker == _msgSender(), "not matched signed address");

    EthereumMarketplaceStorage marketStorage = EthereumMarketplaceStorage(storageAddress);
    marketStorage.setCancelled(hash, true);

    emit OrderCancelled(sellOrder.maker, sellOrder.itemId);
  }
}


// File contracts/marketplace/ethereum/exchange/EthereumExchange.sol


pragma solidity ^0.8.0;

contract EthereumExchange is EthereumExchangeCore {
  constructor () EthereumExchangeCore() {}

  function executeOrder(
    address payable[11] memory addrs,
    uint[17] memory uints,
    uint8[2] memory enumValues,
    bytes[3] memory bytesArray,
    uint8[2] memory vs,
    bytes32[4] memory metadata
  ) public payable {
    executeOrder_(
      SellOrder(addrs[0], addrs[1], addrs[2], addrs[3], addrs[4], addrs[5], addrs[6], uints[0], uints[1], uints[2], uints[3], uints[4], uints[5], uints[6], uints[7], uints[8], uints[9], uints[10], SellType(enumValues[0]), PublishType(enumValues[1]), bytesArray[0], bytesArray[1]),
      Sig(vs[0], metadata[0], metadata[1]),
      BuyOrder(addrs[7], addrs[8], addrs[9], addrs[10], uints[11], uints[12], uints[13], uints[14], uints[15], uints[16], bytesArray[2]),
      Sig(vs[1], metadata[2], metadata[3])
    );
  }

  function cancelOrder(
    address payable[7] memory addrs,
    uint[11] memory uints,
    uint8[2] memory enumValues,
    bytes[2] memory bytesArray,
    uint8 v,
		bytes32 r,
		bytes32 s
  ) public {
    cancelOrder_(
      SellOrder(addrs[0], addrs[1], addrs[2], addrs[3], addrs[4], addrs[5], addrs[6], uints[0], uints[1], uints[2], uints[3], uints[4], uints[5], uints[6], uints[7], uints[8], uints[9], uints[10], SellType(enumValues[0]), PublishType(enumValues[1]), bytesArray[0], bytesArray[1]),
      Sig(v, r, s)
    );
  }
}
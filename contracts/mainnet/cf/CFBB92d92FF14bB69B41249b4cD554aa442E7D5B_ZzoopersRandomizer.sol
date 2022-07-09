// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./ZzoopersBitMap.sol";

/**
 * @title Zzoopers contract
 */
contract ZzoopersRandomizer is Ownable {
    using ZzoopersBitMaps for *;

    uint32 constant BATCH_SIZE = 1111;
    uint32 constant LIMIT_AMOUNT = 5555;

    address private _zzoopersAddress;

    mapping(uint256 => ZzoopersBitMaps.ZzoopersBitMap) private _metadataIds;

    constructor() Ownable() {
        //init _metadataIds for 5 batch, each for 1111, total is 5555;
        _metadataIds[0].init(BATCH_SIZE);
        _metadataIds[1].init(BATCH_SIZE);
        _metadataIds[2].init(BATCH_SIZE);
        _metadataIds[3].init(BATCH_SIZE);
        _metadataIds[4].init(BATCH_SIZE);
    }

    function setZzoopersAddress(address zzoopersAddress) public onlyOwner {
        _zzoopersAddress = zzoopersAddress;
    }

    //batchNo should start from 1
    function getMetadataId(uint256 batchNo, uint256 zzoopersEVOTokenId)
        external
        returns (uint256 metadataId)
    {
        require(
            msg.sender == _zzoopersAddress,
            "ZzoopersRandomizer: caller not authorized"
        );
        require(
            batchNo >= 1 && batchNo <= 5,
            "ZzoopersRandomizer: BatchNo must between: 1 and 5"
        );
        require(
            zzoopersEVOTokenId <= LIMIT_AMOUNT,
            "ZzoopersRandomizer: TokenId cannot large than 5555"
        );
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.timestamp),
                    batchNo,
                    zzoopersEVOTokenId
                )
            )
        );
        uint256 totalUnused = 0;

        unchecked {
            for (uint256 i = 0; i < batchNo; i++) {
                totalUnused += _metadataIds[i].unused();
            }
            require(totalUnused > 0, "ZzoopersRandomizer: Batch limit reached");

            uint256 index = random % totalUnused;
            uint256 count = 0;
            uint256 targetBatchNo = 0;
            for (; targetBatchNo < batchNo; targetBatchNo++) {
                count += _metadataIds[targetBatchNo].unused();
                if (index < count) {
                    break;
                }
            }
            metadataId =
                targetBatchNo *
                BATCH_SIZE +
                _metadataIds[targetBatchNo].trySetTo(
                    random % _metadataIds[targetBatchNo].cap()
                ) +
                1; //metadataId start from 1
        }
        return metadataId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

library ZzoopersBitMaps {
    struct ZzoopersBitMap {
        uint32 _cap; //The cap of BitMap
        uint32 _used; //The used bit in BitMap;
        //Bucket => bitMap, the first 8 bits of bitMap is the count of used bits, so the cap of a bucket is (32 - 1) * 8 = 248;
        mapping(uint256 => uint256) _bits;
    }

    function cap(ZzoopersBitMap storage bitMap)
        internal
        view
        returns (uint256)
    {
        return bitMap._cap;
    }

    function init(ZzoopersBitMap storage bitMap, uint32 _cap) internal {
        bitMap._cap = _cap;
    }

    function unused(ZzoopersBitMap storage bitMap)
        internal
        view
        returns (uint256)
    {
        return bitMap._cap - bitMap._used;
    }

    function getBits(ZzoopersBitMap storage bitMap, uint256 bucket)
        internal
        view
        returns (uint256)
    {
        return bitMap._bits[bucket];
    }

    /**
     * @dev Sets the bit at `index`, if the bit has already been set, try the next bit until find a unset bit.
     * @dev Returns the really set index.
     */
    function trySetTo(ZzoopersBitMap storage bitMap, uint256 index)
        internal
        returns (uint256 setIndex)
    {
        require(index < bitMap._cap, "ZooBitMap: Index out of range");
        require(bitMap._cap - bitMap._used > 0, "ZooBitMap: Out of cap");

        unchecked {
            uint256 bucket = index / 248;
            uint256 i = index % 248; // index in bucket;
            uint256 maxBucket = bitMap._cap / 248;
            if (bitMap._cap % 248 != 0) {
                maxBucket++;
            }

            bool success = false;
            while (true) {
                uint256 bits = bitMap._bits[bucket];
                uint256 usedOfBucket = (bits >> 248) & 0xff;
                if (usedOfBucket < 248) {
                    uint256 bound = bitMap._cap - bucket * 248;
                    if (bound > 248) {
                        bound = 248;
                    }
                    for (; i < bound; i++) {
                        uint256 mask = 1 << (i & 0xff);
                        if (mask & bits == 0) {
                            //found a unused bit
                            bits = bits | mask; // set bit
                            usedOfBucket++;
                            mask = usedOfBucket << 248;
                            bits = ((bits << 8) >> 8) | mask; // update usedOfBucket
                            bitMap._bits[bucket] = bits; //update bits in bucket
                            bitMap._used++;
                            success = true;
                            break;
                        }
                    }
                    if (success) {
                        break;
                    }
                }
                //move to next bucket
                i = 0;
                bucket++;
                if (bucket == maxBucket) {
                    bucket = 0;
                }
            }
            setIndex = bucket * 248 + i;
        }

        return setIndex;
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
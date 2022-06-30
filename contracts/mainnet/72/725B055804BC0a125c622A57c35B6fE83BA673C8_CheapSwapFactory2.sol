//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICheapSwapFactory2.sol";
import "./CheapSwapAddress.sol";

contract CheapSwapFactory2 is ICheapSwapFactory2, Ownable {
    mapping(address => address) public addressMap;
    uint256 public fee = 0.001 ether;
    address public feeAddress;

    constructor() {
        feeAddress = msg.sender;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function createAddress() external {
        addressMap[msg.sender] = address(new CheapSwapAddress(msg.sender));
        emit CreateAddress(msg.sender, addressMap[msg.sender]);
    }

    /* =================== ADMIN FUNCTIONS =================== */

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
}

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
pragma solidity ^0.8.12;

interface ICheapSwapFactory2 {
    /* ==================== EVENTS =================== */

    event CreateAddress(address owner, address chatSwapAddress);

    /* ==================== VIEW FUNCTIONS =================== */

    function fee() external view returns (uint256);

    function feeAddress() external view returns (address);

    /* ================ TRANSACTION FUNCTIONS ================ */

    function createAddress() external;

    /* ==================== ADMIN FUNCTIONS =================== */

    function setFeeAddress(address _feeAddress) external;

    function setFee(uint256 _fee) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "../lib/BytesLib.sol";
import "./interfaces/ICheapSwapAddress.sol";
import "./interfaces/ICheapSwapFactory2.sol";

contract CheapSwapAddress is ICheapSwapAddress {
    using BytesLib for bytes;

    bool public callPause;
    address public owner;
    ICheapSwapFactory2 public cheapSwapFactory;
    mapping(uint256 => bytes) public targetDataMap;
    mapping(address => bool) public callApprove;

    constructor(address _owner) {
        owner = _owner;
        cheapSwapFactory = ICheapSwapFactory2(msg.sender);
    }

    /* ==================== UTIL FUNCTIONS =================== */

    modifier _onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        doReceive();
    }

    function doReceive() public payable {
        require(targetDataMap[msg.value].length != 0, "CheapSwapAddress: empty targetData");
        uint256 fee = cheapSwapFactory.fee();
        require(msg.value >= fee, "CheapSwapAddress: insufficient value");
        payable(cheapSwapFactory.feeAddress()).transfer(fee);
        uint256 value = msg.value - fee;
        if (value > 0) {
            payable(owner).transfer(value);
        }
        bytes memory targetData = targetDataMap[msg.value];
        (bool success, ) = targetData.toAddress(0).call(targetData.slice(20, targetData.length - 20));
        require(success, "CheapSwapAddress: call error");
    }

    function call(address target, bytes calldata data) external payable {
        require(callApprove[msg.sender] && !callPause, "CheapSwapAddress: not allow call");
        bool success;
        if (msg.value > 0) {
            (success, ) = target.call{value: msg.value}(data);
        } else {
            (success, ) = target.call(data);
        }
        require(success, "CheapSwapAddress: call error");
    }

    /* ==================== ADMIN FUNCTIONS ================== */

    function approveCall(address sender) external _onlyOwner {
        callApprove[sender] = !callApprove[sender];
        emit ApproveCall(sender, callApprove[sender]);
    }

    function pauseCall() external _onlyOwner {
        callPause = !callPause;
        emit PauseCall(callPause);
    }

    function setTargetData(uint256 value, bytes calldata targetData) external _onlyOwner {
        targetDataMap[value] = targetData;
        emit SetTargetData(value, targetData);
    }

    function setTargetDataList(uint256[] calldata valueList, bytes[] calldata targetDataList) external _onlyOwner {
        require(valueList.length == targetDataList.length, "CheapSwapAddress: not equal length");
        uint256 length = valueList.length;
        for (uint256 i = 0; i < length; ++i) {
            targetDataMap[valueList[i]] = targetDataList[i];
            emit SetTargetData(valueList[i], targetDataList[i]);
        }
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

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
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
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapAddress {
    /* ==================== EVENTS =================== */

    event ApproveCall(address sender, bool callApprove);

    event SetTargetData(uint256 value, bytes targetData);

    event PauseCall(bool cancelCall);

    /* ==================== VIEW FUNCTIONS =================== */

    function owner() external view returns (address);

    /* ================ TRANSACTION FUNCTIONS ================ */

    function doReceive() external payable;

    function call(address target, bytes calldata data) external payable;

    /* ===================== ADMIN FUNCTIONS ==================== */

    function approveCall(address sender) external;

    function pauseCall() external;

    function setTargetData(uint256 value, bytes calldata targetData) external;

    function setTargetDataList(uint256[] calldata valueList, bytes[] calldata targetDataList) external;
}
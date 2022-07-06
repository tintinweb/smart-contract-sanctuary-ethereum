//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./lib/CheapSwapAddressBytesLib.sol";
import "./interfaces/ICheapSwapAddress.sol";
import "./interfaces/ICheapSwapFactory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CheapSwapAddress is ICheapSwapAddress, ReentrancyGuard {
    using CheapSwapAddressBytesLib for bytes;

    // call调用是否暂停
    bool public pause;
    // 所有者地址
    address public owner;
    // cheapSwapFactory 地址
    ICheapSwapFactory public cheapSwapFactory;
    // msgValue 到 targetData 的映射
    mapping(uint256 => bytes) public targetDataMap;

    constructor(address _owner) {
        owner = _owner;
        cheapSwapFactory = ICheapSwapFactory(msg.sender);
    }

    /* ==================== UTIL FUNCTIONS =================== */

    modifier _onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _checkApprove(
        uint8 runTime,
        uint8 maxRunTime,
        uint40 deadline
    ) internal view {
        require(!pause, "CheapSwapAddress: pause");
        // 不能超时
        require(block.timestamp <= deadline, "CheapSwapAddress: over deadline");
        // 不能超过运行次数
        if (maxRunTime != 0) {
            require(runTime < maxRunTime, "CheapSwapAddress: over runTime");
        }
    }

    /* =================== VIEW FUNCTIONS =================== */

    function getTargetData(uint256 msgValue)
        public
        view
        returns (
            // 运行次数
            uint8 runTime,
            // 最大运行次数
            uint8 maxRunTime,
            // 截止日期
            uint40 deadline,
            // 目标地址
            address target,
            // value
            uint80 value,
            // data
            bytes memory data
        )
    {
        bytes memory targetData = targetDataMap[msgValue];
        runTime = targetData.toUint8(0);
        maxRunTime = targetData.toUint8(1);
        deadline = targetData.toUint40(2);
        target = targetData.toAddress(7);
        if (msgValue > 0) {
            value = targetData.toUint80(27);
            data = abi.encodePacked(
                targetData.toUint32(37),
                uint80(msgValue),
                targetData.slice(41, targetData.length - 41)
            );
        } else {
            data = abi.encodePacked(
                targetData.toUint32(27),
                uint80(msgValue),
                targetData.slice(31, targetData.length - 31)
            );
        }
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        // 所有者默认存入 value
        if (msg.sender != owner) {
            doReceive();
        }
    }

    function doReceive() public payable nonReentrant {
        unchecked {
            uint256 msgValue;
            // 如果 msg.value 映射的 targetData 不为空，msgValue 等于 msg.value
            if (targetDataMap[msg.value].length != 0) {
                msgValue = msg.value;
            }
            // 如果 0 映射的 targetData 不为空，也能执行
            if (msgValue != 0 || targetDataMap[0].length != 0) {
                (
                    uint8 runTime,
                    uint8 maxRunTime,
                    uint40 deadline,
                    address target,
                    uint80 value,
                    bytes memory data
                ) = getTargetData(msgValue);
                _checkApprove(runTime, maxRunTime, deadline);
                // 收费
                uint256 fee = cheapSwapFactory.fee();
                require(msg.value >= fee, "CheapSwapAddress: insufficient value");
                payable(cheapSwapFactory.feeAddress()).transfer(fee);
                // 除非 msgValue 为 0，否则退给所有者 msg.value
                if (msgValue != 0) {
                    if (msg.value - fee > 0) {
                        payable(owner).transfer(msg.value - fee);
                    }
                } else {
                    value = uint80(address(this).balance);
                }
                // 执行targetData
                (bool success, ) = target.call{value: value}(data);
                require(success, "CheapSwapAddress: call error");
                if (maxRunTime != 0) {
                    targetDataMap[msg.value][0] = bytes1(++runTime);
                }
            }
        }
    }

    function call(
        uint256 callMsgValue,
        address target,
        bytes calldata data
    ) external payable {
        (uint8 runTime, uint8 maxRunTime, uint40 deadline, address _target, , ) = getTargetData(callMsgValue);
        // 只有授权者和所有者才能调用
        if (msg.sender != owner) {
            _checkApprove(runTime, maxRunTime, deadline);
            require(msg.sender == _target, "CheapSwapAddress: not approver");
        }
        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "CheapSwapAddress: call error");
    }

    /* ==================== ADMIN FUNCTIONS ================== */
    // 获取value
    function getValue() external _onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // 暂停授权
    function setPause(bool isPause) external _onlyOwner {
        pause = isPause;
        emit SetPause(isPause);
    }

    // 设置 targetData
    function setTargetData(
        uint256 msgValue,
        uint8 maxRunTime,
        uint40 deadline,
        address target,
        uint80 value,
        bytes calldata data
    ) external _onlyOwner {
        bytes memory targetData;
        if (msgValue != 0) {
            targetData = abi.encodePacked(uint8(0), maxRunTime, deadline, target, value, data);
        } else {
            targetData = abi.encodePacked(uint8(0), maxRunTime, deadline, target, data);
        }
        targetDataMap[msgValue] = targetData;
        emit SetTargetData(msgValue, targetData);
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

library CheapSwapAddressBytesLib {
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

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint40(bytes memory _bytes, uint256 _start) internal pure returns (uint40) {
        require(_start + 5 >= _start, "toUint40_overflow");
        require(_bytes.length >= _start + 5, "toUint40_outOfBounds");
        uint40 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x5), _start))
        }

        return tempUint;
    }

    function toUint80(bytes memory _bytes, uint256 _start) internal pure returns (uint80) {
        require(_start + 10 >= _start, "toUint80_overflow");
        require(_bytes.length >= _start + 10, "toUint80_outOfBounds");
        uint80 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xa), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapAddress {
    /* ==================== EVENTS =================== */

    event SetTargetData(uint256 indexed value, bytes targetData);

    event SetPause(bool isPause);

    /* ==================== VIEW FUNCTIONS =================== */

    function owner() external view returns (address);

    function getTargetData(uint256 msgValue)
        external
        view
        returns (
            uint8 runTime,
            uint8 maxRunTime,
            uint40 deadline,
            address target,
            uint80 value,
            bytes memory data
        );

    /* ================ TRANSACTION FUNCTIONS ================ */

    function doReceive() external payable;

    function call(
        uint256 callMsgValue,
        address target,
        bytes calldata data
    ) external payable;

    /* ===================== ADMIN FUNCTIONS ==================== */

    function setPause(bool isPause) external;

    function setTargetData(
        uint256 msgValue,
        uint8 maxRunTime,
        uint40 deadline,
        address target,
        uint80 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapFactory {
    /* ==================== EVENTS =================== */

    event CreateAddress(address indexed owner, address cheapSwapAddress);

    /* ==================== VIEW FUNCTIONS =================== */

    function fee() external view returns (uint256);

    function feeAddress() external view returns (address);

    /* ================ TRANSACTION FUNCTIONS ================ */

    function createCheapSwapAddress() external;

    /* ==================== ADMIN FUNCTIONS =================== */

    function setFeeAddress(address _feeAddress) external;

    function setFee(uint256 _fee) external;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
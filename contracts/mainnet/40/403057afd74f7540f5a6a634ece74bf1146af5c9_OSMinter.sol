// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IOSMinter.sol";
import "../../../core/model/IOrganization.sol";
import "@ethereansos/swissknife/contracts/generic/impl/LazyInitCapableElement.sol";
import "@ethereansos/items-v2/contracts/projection/IItemProjection.sol";
import "@ethereansos/items-v2/contracts/model/IItemInteroperableInterface.sol";
import { ComponentsGrimoire } from "../../lib/KnowledgeBase.sol";
import { AddressUtilities, Uint256Utilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";

contract OSMinter is IOSMinter, LazyInitCapableElement {
    using AddressUtilities for address;
    using Uint256Utilities for uint256;

    address private _projectionAddress;
    uint256 private _itemId;
    bytes32 private _collectionId;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory) {
        address itemAddress;
        (_projectionAddress, itemAddress) = abi.decode(lazyInitData, (address, address));
        _collectionId = IItemProjection(_projectionAddress).collectionId();
        _itemId = IItemInteroperableInterface(itemAddress).itemId();
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IOSMinter).interfaceId ||
            interfaceId == this.mint.selector;
    }

    function mint(uint256 value, address receiver) external override {
        require(msg.sender == IOrganization(host).get(ComponentsGrimoire.COMPONENT_KEY_TOKEN_MINTER_AUTH), "unauthorized");
        CreateItem[] memory createItems = new CreateItem[](1);
        createItems[0] = CreateItem(
            Header(address(0), "", "", ""),
            _collectionId,
            _itemId,
            receiver.asSingletonArray(),
            value.asSingletonArray()
        );
        IItemProjection(_projectionAddress).mintItems(createItems);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";
    string internal constant BASE64_ENCODER_DATA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint256(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function asSingletonArray(bytes memory a) internal pure returns(bytes[] memory array) {
        array = new bytes[](1);
        array[0] = a;
    }

    function toBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        string memory table = BASE64_ENCODER_DATA;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    bytes  internal constant BASE64_DECODER_DATA = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                                   hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                                   hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                                   hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint256 i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string memory str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function toBase64(string memory input) internal pure returns(string memory) {
        return BytesUtilities.toBase64(abi.encodePacked(input));
    }

    function fromBase64(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        bytes memory table = BASE64_DECODER_DATA;

        uint256 decodedLen = (data.length / 4) * 3;

        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            mstore(result, decodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toHex(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }

    function toString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function sum(uint256[] memory arr) internal pure returns (uint256 result) {
        for(uint256 i = 0; i < arr.length; i++) {
            result += arr[i];
        }
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

library TransferUtilities {
    using ReflectionUtilities for address;

    function balanceOf(address erc20TokenAddress, address account) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return account.balance;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).balanceOf.selector, account)), (uint256));
    }

    function allowance(address erc20TokenAddress, address account, address spender) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return 0;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).allowance.selector, account, spender)), (uint256));
    }

    function safeApprove(address erc20TokenAddress, address spender, uint256 value) internal {
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, spender, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Grimoire {
    bytes32 constant public SUBDAO_KEY_ETHEREANSOS_V1 = 0x1d3784c94477427ee3ebf963dc80bcdc1be400c47ff2754fc2a9cd7328837eb4;
}

library ComponentsGrimoire {
    bytes32 constant public COMPONENT_KEY_TOKEN_MINTER = 0x4668877ff569021c2e8188be2e797f8aa73265eac3479789edfd2531e130b1a1;
    bytes32 constant public COMPONENT_KEY_TOKEN_MINTER_AUTH = 0x9c4db151be7222e332a1dcdb260c7b85b81f214f6b6d83d96c94f814d48a75a5;
    bytes32 constant public COMPONENT_KEY_DIVIDENDS_FARMING = 0x3104750b9808e498d0ff489ed3bdbb01b8ea8018a22c284a054db2dc8fc580a7;
    bytes32 constant public COMPONENT_KEY_OS_FARMING = 0x8ec6626208f22327b5df97db347dd390d4bbb54909af6bc9e8b044839ff9c2ef;
}

library State {
    string constant public STATEMANAGER_ENTRY_NAME_FACTORY_OF_FACTORIES_FEE_PERCENTAGE_FOR_TRANSACTED = "factoryOfFactoriesFeePercentageTransacted";
    string constant public STATEMANAGER_ENTRY_NAME_FACTORY_OF_FACTORIES_FEE_PERCENTAGE_FOR_BURN = "factoryOfFactoriesFeePercentageBurn";

    string constant public STATEMANAGER_ENTRY_NAME_FARMING_FEE_PERCENTAGE_FOR_TRANSACTED = "farmingFeePercentageTransacted";
    string constant public STATEMANAGER_ENTRY_NAME_FARMING_FEE_FOR_BURNING_OS = "farmingFeeBurnOS";

    string constant public STATEMANAGER_ENTRY_NAME_INFLATION_FEE_PERCENTAGE_FOR_TRANSACTED = "inflationFeePercentageTransacted";

    string constant public STATEMANAGER_ENTRY_NAME_DELEGATIONS_ATTACH_INSURANCE = "delegationsAttachInsurance";
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IItemInteroperableInterface is IERC20, IERC20Metadata, IERC20Permit {

    function init() external;
    function mainInterface() external view returns(address);
    function itemId() external view returns(uint256);
    function emitEvent(bool forApprove, bool isMulti, bytes calldata data) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() external view returns(string memory name, string memory version);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../model/Item.sol";
import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IItemProjection is Item, ILazyInitCapableElement {

    function mainInterface() external view returns(address);

    function collectionId() external view returns(bytes32);
    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);
    function itemPlainUri(uint256 itemId) external view returns(string memory);
    function setHeader(Header calldata value) external returns(Header memory oldValue);

    function toInteroperableInterfaceAmount(uint256 amount, uint256 itemId, address account) external view returns(uint256);
    function toMainInterfaceAmount(uint256 amount, uint256 itemId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/ILazyInitCapableElement.sol";
import { ReflectionUtilities } from "../../lib/GeneralUtilities.sol";

abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = host;
        host = newValue;
        emit Host(oldValue, newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 selector) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/dynamicMetadata/model/IDynamicMetadataCapableElement.sol";

interface IOrganization is IDynamicMetadataCapableElement {

    struct Component {
        bytes32 key;
        address location;
        bool active;
        bool log;
    }

    function keyOf(address componentAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory componentsAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory componentsAddresses);

    function get(bytes32 key) external view returns(address componentAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory componentsAddresses);
    function isActive(address subject) external view returns(bool);
    function keyIsActive(bytes32 key) external view returns(bool);

    function set(Component calldata) external returns(address replacedComponentAddress);
    function batchSet(Component[] calldata) external returns (address[] memory replacedComponentAddresses);

    event ComponentSet(bytes32 indexed key, address indexed from, address indexed to, bool active);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";

interface IOSMinter is ILazyInitCapableElement {
    function mint(uint256 value, address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../generic/model/ILazyInitCapableElement.sol";

interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC1155Views.sol";

struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata newValues) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
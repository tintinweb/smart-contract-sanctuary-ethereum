/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}
interface IERC1822ProxiableUpgradeable {
    function proxiableUUID() external view returns (bytes32);
}
interface IBeaconUpgradeable {
    function implementation() external view returns (address);
}
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }
    struct BooleanSlot {
        bool value;
    }
    struct Bytes32Slot {
        bytes32 value;
    }
    struct Uint256Slot {
        uint256 value;
    }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
   function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }
    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    event Upgraded(address indexed implementation);
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    event AdminChanged(address previousAdmin, address newAdmin);
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    event BeaconUpgraded(address indexed beacon);
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }
    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    address private immutable __self = address(this);
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
interface IERC721Upgradeable is IERC165Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }
    function __ERC165_init_unchained() internal onlyInitializing {
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }
    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }
    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }
    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}
interface WETH {
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}
contract AquaCultureNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC721URIStorageUpgradeable{ 
    address wethAddress;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces; //for mi
    mapping(uint256 => tokenInfo) public allTokensInfo;
    mapping(uint256 => assetInfo) public allAssetsInfo;
    mapping(uint256 => uint256[]) public assetsNumbersForSale;
    uint256 PLATFORM_SHARE_PERCENT;
    uint256 ROYALTY_PERCENT;
    uint256 public newItemId;
    Counters.Counter private _tokenIds;
    Counters.Counter private _assetIds;
    struct tokenInfo {
        uint256 tokenId;
        address payable creator;
    }
    struct assetInfo {
        address creator;
        string metadata;
        uint256 assetId;
        uint256 maxMints;
        uint256 currentMints;
        uint256 price;
    }
    struct createNftData {
        string metaData;
        address creator;
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
    }
    struct PercentagesResponse {
        uint256 royaltyPercent;
        uint256 platformSharePercent;
    }
    struct createAssetPublicData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 maxAllowed;
        string metadata;
        uint256 price;
    }
    struct createNFTPublicData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 maxAllowed;
        string metadata;
        uint256 price;
    }
    struct buyAndMintData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 assetId;
        uint payThrough;
        string metadata;
        uint256 assetNumber;
        string nftId;
        string ownerId;
        string buyerId;
        uint8 currency;
        uint8 selectedNft;
        uint8 sellingMethod;
        string sellingNftId;
    }
    struct buyAndMintAssetAcceptData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 assetId;
        address newOwner;
        string metadata;
        uint256 nftNumber;
        string bidId;
        string offerId;
        string sellingNftId;
    }
    struct transferByAcceptData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 tokenId;
        address newOwner;
        string bidId;
        string offerId;
        string sellingNftId;
    }
    struct buyNowData {
        string encodeKey;
        uint256 nonce;
        uint256 amount;
        bytes signature;
        uint256 tokenId;
        uint payThrough;
        address owner;
        string nftId;
        uint8 currency;
        uint8 sellingMethod;
        string sellingNftId;
    }

    event NewNFT(uint256 indexed tokenId);
    event NewAssetTransferred(uint256 indexed tokenId, address from, address to, string nftId, uint8 currency, uint8 selectedNft, uint8 sellingMethod, string sellingNftId, uint256 amount);
    event NFTTransferred(uint256 indexed tokenId, address from, address to, string nftId, uint8 currency, uint8 sellingMethod, string sellingNftId, uint256 amount);
    event NewAssetTransferredByAccept(uint256 indexed tokenId, uint256 nftNumber, string bidId, string offerId, string sellingNftId);
    event NFTTransferredByAccept(uint256 indexed tokenId, string bidId, string offerId, string sellingNftId);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event BidAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event NFTPurchased(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event NewAsset(uint256 assetId);
    function initialize(string memory tokenName, string memory tokenSymbol, address _weth, uint256 platform_share_percentage, uint256 royalty_percentage) public initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        wethAddress = _weth;
        PLATFORM_SHARE_PERCENT = platform_share_percentage;
        ROYALTY_PERCENT = royalty_percentage;
	}
    function _authorizeUpgrade(address) internal override onlyOwner{}
    function putOnSale(uint256[] memory assetNumbers, uint256 assetId) public onlyProxy {
        uint256[] storage currentForSale = assetsNumbersForSale[assetId];
        for(uint256 x=0; x<assetNumbers.length; x++) {
            currentForSale.push(assetNumbers[x]);
        }
    }
    function putOffSale(uint256 assetId) public onlyProxy {
        uint256[] storage currentForSale = assetsNumbersForSale[assetId];
        for(uint256 y=0; y< currentForSale.length; y++) {
            currentForSale[y] = 0;
        }
    }
    function createAsset(uint256 maxAllowed, string memory metadata, uint256 price) public onlyOwner onlyProxy {
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();
        assetInfo memory newAsset = assetInfo(
            owner(),
            metadata,
            newAssetId,
            maxAllowed,
            0,
            price
        );
        allAssetsInfo[newAssetId] = newAsset;
        emit NewAsset(newAssetId);
    }
    function createAssetPublic(createAssetPublicData memory _createAssetData) public onlyProxy {
        require(!seenNonces[msg.sender][_createAssetData.nonce], "Invalid request");
        seenNonces[msg.sender][_createAssetData.nonce] = true;
        require(verify(msg.sender, msg.sender, _createAssetData.amount, _createAssetData.encodeKey, _createAssetData.nonce, _createAssetData.signature), "invalid signature");
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();
        assetInfo memory newAsset = assetInfo(
            msg.sender,
            _createAssetData.metadata,
            newAssetId,
            _createAssetData.maxAllowed,
            0,
            _createAssetData.price
        );
        allAssetsInfo[newAssetId] = newAsset;
        emit NewAsset(newAssetId);
    }
    function createNFT(createNftData memory _nftData) public onlyProxy {
        require(!seenNonces[msg.sender][_nftData.nonce], "Invalid request");
        seenNonces[msg.sender][_nftData.nonce] = true;
        require(verify(msg.sender, msg.sender, _nftData.amount, _nftData.encodeKey, _nftData.nonce, _nftData.signature), "invalid signature");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        require(!_exists(newTokenId), "Token ID already exists");
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _nftData.metaData);
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(msg.sender)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        emit NewNFT(newTokenId);
    }
    function buyAndMintAsset(buyAndMintData memory _buyAndMintData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_buyAndMintData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyAndMintData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyAndMintData.amount, _buyAndMintData.encodeKey, _buyAndMintData.nonce, _buyAndMintData.signature), "invalid signature");
        assetInfo memory assetInfoById = allAssetsInfo[_buyAndMintData.assetId];
        uint256 amount = msg.value;
        if(_buyAndMintData.payThrough == 1) {
            require(msg.value >= assetInfoById.price, "Invalid Price");
        }
        require(assetInfoById.maxMints >= assetInfoById.currentMints, "NFT Not available");
        uint256[] storage currentForSale = assetsNumbersForSale[_buyAndMintData.assetId];
        bool availableAssetNumber = false;
        for(uint256 x=0; x<currentForSale.length; x++) {
            if(currentForSale[x]==_buyAndMintData.assetNumber) {
                availableAssetNumber = true;
                currentForSale[x]=0;
                assetsNumbersForSale[_buyAndMintData.assetId] = currentForSale;
                continue;
            }
        }
        require(availableAssetNumber, "NFT Number Already Taken");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _buyAndMintData.metadata);
        assetInfoById.currentMints = assetInfoById.currentMints+1;
        allAssetsInfo[_buyAndMintData.assetId] = assetInfoById;
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(assetInfoById.creator)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        if(_buyAndMintData.payThrough == 1) {
            uint256 amountToTransfer = amount;
            if(assetInfoById.creator != owner()) {
                if(PLATFORM_SHARE_PERCENT > 0) {
                    uint256 platformSharePercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
                    amountToTransfer = amountToTransfer-platformSharePercent;
                }
                payable(assetInfoById.creator).transfer(amountToTransfer);
            }
        }
        
        emit NewNFT(newTokenId);
        emit NewAssetTransferred(newTokenId, assetInfoById.creator, msg.sender, _buyAndMintData.nftId, _buyAndMintData.currency, _buyAndMintData.selectedNft, _buyAndMintData.sellingMethod, _buyAndMintData.sellingNftId, _buyAndMintData.amount);
    }
    function buyAndMintAssetByAccept(buyAndMintAssetAcceptData memory _buyAndMintAssetAcceptData) external payable onlyProxy{
        require(!seenNonces[msg.sender][_buyAndMintAssetAcceptData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyAndMintAssetAcceptData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyAndMintAssetAcceptData.amount, _buyAndMintAssetAcceptData.encodeKey, _buyAndMintAssetAcceptData.nonce, _buyAndMintAssetAcceptData.signature), "invalid signature");
        assetInfo memory assetInfoById = allAssetsInfo[_buyAndMintAssetAcceptData.assetId];
        require(assetInfoById.maxMints >= assetInfoById.currentMints, "NFT Not available");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _buyAndMintAssetAcceptData.metadata);
        _transfer(msg.sender, _buyAndMintAssetAcceptData.newOwner, newTokenId);
        assetInfoById.currentMints = assetInfoById.currentMints+1;
        allAssetsInfo[_buyAndMintAssetAcceptData.assetId] = assetInfoById;
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(assetInfoById.creator)
        );
        allTokensInfo[newTokenId] = newTokenInfo;
        uint256 amountToTransfer = _buyAndMintAssetAcceptData.amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(_buyAndMintAssetAcceptData.amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(_buyAndMintAssetAcceptData.newOwner, address(this), platformSharePercent);
        }
        transferwethToOwner(_buyAndMintAssetAcceptData.newOwner, msg.sender, amountToTransfer);
        emit NewNFT(newTokenId);
        emit NewAssetTransferredByAccept(newTokenId, _buyAndMintAssetAcceptData.nftNumber, _buyAndMintAssetAcceptData.bidId, _buyAndMintAssetAcceptData.offerId, _buyAndMintAssetAcceptData.sellingNftId);

    }
    function transferByAccept(transferByAcceptData memory _transferByAcceptData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_transferByAcceptData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferByAcceptData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferByAcceptData.amount, _transferByAcceptData.encodeKey, _transferByAcceptData.nonce, _transferByAcceptData.signature), "invalid signature");
        tokenInfo memory tokenInfoById = allTokensInfo[_transferByAcceptData.tokenId];
        uint256 amountToTransfer = _transferByAcceptData.amount;
        uint256 platformShareAfterRoyalty = PLATFORM_SHARE_PERCENT;
        if(msg.sender != tokenInfoById.creator && ROYALTY_PERCENT > 0 && PLATFORM_SHARE_PERCENT > 0) {
            uint256 royaltyPercent = calculatePercentValue(_transferByAcceptData.amount, ROYALTY_PERCENT);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transferwethToOwner(_transferByAcceptData.newOwner, tokenInfoById.creator, royaltyPercent);
            platformShareAfterRoyalty = platformShareAfterRoyalty - royaltyPercent;
        }
        if(platformShareAfterRoyalty > 0) {
            uint256 platformSharePercent = calculatePercentValue(_transferByAcceptData.amount, platformShareAfterRoyalty);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(_transferByAcceptData.newOwner, address(this), platformSharePercent);
        }
        transferwethToOwner(_transferByAcceptData.newOwner, msg.sender, amountToTransfer);
        _transfer(msg.sender, _transferByAcceptData.newOwner, _transferByAcceptData.tokenId);
        emit OfferAccepted(_transferByAcceptData.tokenId,_transferByAcceptData.amount,msg.sender,_transferByAcceptData.newOwner);
        emit NFTTransferredByAccept(_transferByAcceptData.tokenId, _transferByAcceptData.bidId, _transferByAcceptData.offerId, _transferByAcceptData.sellingNftId);
    
    }
    function acceptBid(uint256 tokenId, address newOwner, address owner, uint256 amount) external payable onlyOwner onlyProxy {
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        uint256 amountToTransfer = amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(newOwner, address(this), platformSharePercent);
        }
        if(ROYALTY_PERCENT > 0) {
            uint256 royaltyPercent = calculatePercentValue(amount, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transferwethToOwner(newOwner, tokenInfoById.creator, royaltyPercent);
        }
        transferwethToOwner(newOwner, owner, amountToTransfer);
        _transfer(owner, newOwner, tokenId);
        emit BidAccepted(tokenId,amount,owner,newOwner);
    }
    function buyNow(buyNowData memory _buyNowData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_buyNowData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyNowData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyNowData.amount, _buyNowData.encodeKey, _buyNowData.nonce, _buyNowData.signature), "invalid signature");
        uint256 amount = msg.value;
        tokenInfo memory tokenInfoById = allTokensInfo[_buyNowData.tokenId];
        address owner = _buyNowData.owner;
        if(_buyNowData.payThrough == 1) {
            uint256 amountToTransfer = amount;
            uint256 platformShareAfterRoyalty = PLATFORM_SHARE_PERCENT;
            if(owner != tokenInfoById.creator && ROYALTY_PERCENT > 0 && PLATFORM_SHARE_PERCENT > 0) {
                uint256 royaltyPercent = calculatePercentValue(_buyNowData.amount, ROYALTY_PERCENT);
                payable(tokenInfoById.creator).transfer(royaltyPercent);
                amountToTransfer = amountToTransfer-royaltyPercent;
                platformShareAfterRoyalty = platformShareAfterRoyalty - royaltyPercent;
            }
            if(platformShareAfterRoyalty > 0) {
                uint256 platformSharePercent = calculatePercentValue(_buyNowData.amount, platformShareAfterRoyalty);
                amountToTransfer = amountToTransfer-platformSharePercent;
            }
            payable(owner).transfer(amountToTransfer);
        }
        
        _transfer(owner, msg.sender, _buyNowData.tokenId);
        emit NFTPurchased(_buyNowData.tokenId,msg.value,owner,msg.sender);
        emit NFTTransferred(_buyNowData.tokenId, owner, msg.sender, _buyNowData.nftId, _buyNowData.currency, _buyNowData.sellingMethod, _buyNowData.sellingNftId, _buyNowData.amount);
    }
    // fallback function to receive direct payments sent by metamask (for testing)
    fallback () payable external {}
    receive () payable external {}
    function checkPercentages() public view onlyProxy returns (PercentagesResponse memory) {
        PercentagesResponse memory percentagesResponse = PercentagesResponse(
            PLATFORM_SHARE_PERCENT,
            ROYALTY_PERCENT
        );
        return percentagesResponse;
    }
    function updatePercentages(uint256 platformPercent, uint256 royaltyPercent) public onlyProxy onlyOwner{
        PLATFORM_SHARE_PERCENT = platformPercent;
        ROYALTY_PERCENT = royaltyPercent;
    }
    function updatePlatformSharePercent(uint256 percent) public onlyProxy onlyOwner{
        PLATFORM_SHARE_PERCENT = percent;
    }
    function updateRoyaltyPercent(uint256 percent) public onlyProxy onlyOwner{
        ROYALTY_PERCENT = percent;
    }
    function checkPlatformSharePercent() public view onlyProxy returns (uint256) {
        return PLATFORM_SHARE_PERCENT;
    }
    function checkRoyaltyPercent() public view onlyProxy returns (uint256) {
        return ROYALTY_PERCENT;
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(10000);//*100
        return percentValue;
    }
    function transferwethToOwner(address from, address to, uint256 amount) private {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        weth.transferFrom(from, to, amount);
    }
    function safeMint(address to, string memory uri) public onlyOwner onlyProxy{
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    function updateMetadata(uint256 tokenId, string memory metadata) public onlyProxy onlyOwner {
        _setTokenURI(tokenId, metadata);
    }
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) onlyOwner onlyProxy{
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view onlyProxy override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function withdrawETH() public onlyOwner onlyProxy {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawWETH() public onlyOwner onlyProxy {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        weth.transfer(owner(), balance);
    }
    function updateTokenId(uint256 setValue) public onlyOwner onlyProxy {
        uint256 currentValue = _tokenIds.current();
        while (currentValue < setValue) {
            _tokenIds.increment();
            currentValue = _tokenIds.current();
        }
    }
    function currentTokenIds() public view onlyProxy returns (uint256) {
        return _tokenIds.current();
    }
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    function getMessageHash( address _to, uint256 _amount, string memory _message, uint256 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    function splitSignature(bytes memory sig) internal pure returns ( bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
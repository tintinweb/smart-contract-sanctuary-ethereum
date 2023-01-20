/**
 *Submitted for verification at Etherscan.io on 2023-01-19
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
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
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
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

contract Verification {
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

interface ERC20Token {
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface IERC1155Token {
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function mint(uint256 amount, address to) external returns(uint256 value);
}

interface IERC721Token {
    function safeMint(address to, string memory uri) external returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address owner);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
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
// contract ElumntNFTMarketplace is Ownable, Verification {
contract ElumntNFTMarketplace is Initializable, UUPSUpgradeable, OwnableUpgradeable, Verification {
    // constructor() {}
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces;
    struct mint721Data {
        string metadata;
        address payable owner;
        address nft;
    }
    struct mint1155Data {
        address payable owner;
        address nft;
        uint256 amount;
    }
    struct acceptOfferBid721Data {
        string metadata;
        uint256 tokenId;
        address newOwner;
        address creator;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        string encodeKey;
        uint256 nonce;
        address erc20token;
    }
    struct acceptOfferBid1155Data {
        uint256 tokenId;
        address newOwner;
        address creator;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        string encodeKey;
        uint256 nonce;
        address erc20token;
    }
    struct create721Data {
        string metadata;
        address owner;
        address nft;
        bytes signature;
        uint256 amount;
        string encodeKey;
        uint256 nonce;
    }
    struct create1155Data {
        address owner;
        address nft;
        bytes signature;
        uint256 amount;
        string encodeKey;
        uint256 nonce;
        uint256 totalQuantity;
    }
    struct buy721Data {
        string metadata;
        uint256 tokenId;
        address owner;
        address creator;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        string encodeKey;
        uint256 nonce;
        address erc20token;
        uint8 currency;
    }
    struct buy1155Data {
        uint256 tokenId;
        address owner;
        address creator;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        string encodeKey;
        uint256 nonce;
        address erc20token;
        uint8 currency;
    }
    struct acceptData {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address creator;
        address nft;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        address currentOwner;
        address erc20token;
    }
    struct transfer721Data {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address nft;
        uint256 amount;
        bytes signature;
        address currentOwner;
        string encodeKey;
        uint256 nonce;
    }
    struct transfer1155Data {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address nft;
        uint256 amount;
        uint256 quantity;
        bytes signature;
        address currentOwner;
        string encodeKey;
        uint256 nonce;
    }
    event CreatedNFT(uint256 tokenId);
    event BidOfferAccepted(uint256 tokenId, uint256 price, address from, address to, uint256 creatorEarning);
    event NftTransferred(uint256 tokenId, uint256 price, address from, address to, uint256 creatorEarning);
    event AutoAccepted(uint256 indexed tokenId,uint256 creatorEarning);
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
	}
    function _authorizeUpgrade(address) internal override onlyOwner{}
    // Internal / Private functions to be used in side the contract's different methods
    function mint721(mint721Data memory _nftData) internal returns (uint256) {
        IERC721Token nftToken = IERC721Token(_nftData.nft);
        uint256 tokenId = nftToken.safeMint(_nftData.owner, _nftData.metadata);
        return tokenId;
    }
    function mint1155(mint1155Data memory _nftData) internal returns (uint256) {
        IERC1155Token nftToken = IERC1155Token(_nftData.nft);
        uint256 tokenId = nftToken.mint(_nftData.amount, _nftData.owner);
        return tokenId;
    }
    function transfer721(address cAddress, address from, address to, uint256 token) internal {
        IERC721Token nftToken = IERC721Token(cAddress);
        nftToken.safeTransferFrom(from, to, token);
    }
    function transfer1155(address cAddress, address from, address to, uint256 amount, uint256 token) internal {
        IERC1155Token nftToken = IERC1155Token(cAddress);
        nftToken.safeTransferFrom(from, to, token, amount, "");
    }
    function transfer20(address from, address to, uint256 amount, address tokenAddress) internal {
        ERC20Token token = ERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transferFrom(from, to, amount);
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(10000);//10000 base
        return percentValue;
    }

    //Public functions to manage NFTs
    function acceptOfferBid721(acceptOfferBid721Data memory _transferData) external payable onlyProxy {
        uint256 tokenId = _transferData.tokenId;
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        if(_transferData.tokenId == 0) {
            mint721Data memory mintData = mint721Data(
                _transferData.metadata,
                payable(msg.sender),
                _transferData.nft
            );
            tokenId = mint721(mintData);
        }
        uint256 amountToTransfer = _transferData.amount;
        if(_transferData.percent > 0) {
            uint256 platformSharePercent = calculatePercentValue(_transferData.amount, _transferData.percent);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, _transferData.erc20token);
        }
        uint256 royaltyPercent;
        if(_transferData.royalty > 0 && _transferData.creator != msg.sender) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, _transferData.erc20token);
        }
        
        transfer20(_transferData.newOwner, msg.sender, amountToTransfer, _transferData.erc20token);
        transfer721(_transferData.nft, msg.sender, _transferData.newOwner, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, royaltyPercent);
    }
    function acceptOfferBid1155(acceptOfferBid1155Data memory _transferData) external payable onlyProxy {
        uint256 tokenId = _transferData.tokenId;
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        if(_transferData.tokenId == 0) {
            mint1155Data memory mintData = mint1155Data(
                payable(msg.sender),
                _transferData.nft,
                _transferData.totalQuantity
            );
            tokenId = mint1155(mintData);
        }
        uint256 amountToTransfer = _transferData.amount;
        if(_transferData.percent > 0) {
            uint256 platformSharePercent = calculatePercentValue(_transferData.amount, _transferData.percent);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, _transferData.erc20token);
        }
        uint256 royaltyPercent;
        if(_transferData.royalty > 0 && _transferData.creator != msg.sender) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, _transferData.erc20token);
        }
        
        transfer20(_transferData.newOwner, msg.sender, amountToTransfer, _transferData.erc20token);
        transfer1155(_transferData.nft, msg.sender, _transferData.newOwner, _transferData.quantity, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, royaltyPercent);
    }
    function buy721(buy721Data memory _buyData) external payable onlyProxy {
        uint256 tokenId = _buyData.tokenId;
        require(!seenNonces[msg.sender][_buyData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyData.amount, _buyData.encodeKey, _buyData.nonce, _buyData.signature), "invalid signature");
        if(_buyData.tokenId == 0) {
            mint721Data memory mintData = mint721Data(
                _buyData.metadata,
                payable(_buyData.owner),
                _buyData.nft
            );
            tokenId = mint721(mintData);
        }
        uint256 amountToTransfer = _buyData.amount;
        if(_buyData.percent > 0) {
            uint256 platformSharePercent = calculatePercentValue(_buyData.amount, _buyData.percent);
            amountToTransfer = amountToTransfer-platformSharePercent;
            if(_buyData.currency!=1) {
                transfer20(msg.sender, address(this), platformSharePercent, _buyData.erc20token);
            }
        }
        uint256 royaltyPercent;
        if(_buyData.royalty > 0 && _buyData.creator != _buyData.owner) {
            royaltyPercent = calculatePercentValue(_buyData.amount, _buyData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            if(_buyData.currency==1) {
                payable(_buyData.creator).transfer(royaltyPercent);
            } else {
                transfer20(msg.sender, _buyData.creator, royaltyPercent, _buyData.erc20token);
            }
        }
        transfer721(_buyData.nft, _buyData.owner, msg.sender, tokenId);
        if(_buyData.currency==1) {
            payable(_buyData.owner).transfer(amountToTransfer);
        } else {
            transfer20(msg.sender, _buyData.owner, amountToTransfer, _buyData.erc20token);
        }
        emit NftTransferred(tokenId, msg.value, _buyData.owner, msg.sender, royaltyPercent);
    }
    function buy1155(buy1155Data memory _buyData) external payable onlyProxy {
        uint256 tokenId = _buyData.tokenId;
        require(!seenNonces[msg.sender][_buyData.nonce], "Invalid request");
        seenNonces[msg.sender][_buyData.nonce] = true;
        require(verify(msg.sender, msg.sender, _buyData.amount, _buyData.encodeKey, _buyData.nonce, _buyData.signature), "invalid signature");
        if(_buyData.tokenId == 0) {
            mint1155Data memory mintData = mint1155Data(
                payable(_buyData.owner),
                _buyData.nft,
                _buyData.totalQuantity
            );
            tokenId = mint1155(mintData);
        }
        
        uint256 amountToTransfer = _buyData.amount;
        if(_buyData.percent > 0) {
            uint256 platformSharePercent = calculatePercentValue(_buyData.amount, _buyData.percent);
            amountToTransfer = amountToTransfer-platformSharePercent;
            if(_buyData.currency!=1) {
                transfer20(msg.sender, address(this), platformSharePercent, _buyData.erc20token);
            }
        }

        uint256 royaltyPercent;
        if(_buyData.royalty > 0 && _buyData.creator != _buyData.owner) {
            royaltyPercent = calculatePercentValue(_buyData.amount, _buyData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            if(_buyData.currency==1) {
                payable(_buyData.creator).transfer(royaltyPercent);
            } else {
                transfer20(msg.sender, _buyData.creator, royaltyPercent, _buyData.erc20token);
            }
        }
        transfer1155(_buyData.nft, _buyData.owner, msg.sender, _buyData.quantity, tokenId);
        
        if(_buyData.currency==1) {
            payable(_buyData.owner).transfer(amountToTransfer);
        } else {
            transfer20(msg.sender, _buyData.owner, amountToTransfer, _buyData.erc20token);
        }
        emit NftTransferred(tokenId, msg.value, _buyData.owner, msg.sender, royaltyPercent);
    }
    function create721(create721Data memory _createData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_createData.nonce], "Invalid request");
        seenNonces[msg.sender][_createData.nonce] = true;
        require(verify(msg.sender, msg.sender, _createData.amount, _createData.encodeKey, _createData.nonce, _createData.signature), "invalid signature");
        mint721Data memory mintData = mint721Data(
            _createData.metadata,
            payable(msg.sender),
            _createData.nft
        );
        uint256 tokenId = mint721(mintData);

        emit CreatedNFT(tokenId);
    }
    function create1155(create1155Data memory _createData) external payable onlyProxy {
        require(!seenNonces[msg.sender][_createData.nonce], "Invalid request");
        seenNonces[msg.sender][_createData.nonce] = true;
        require(verify(msg.sender, msg.sender, _createData.amount, _createData.encodeKey, _createData.nonce, _createData.signature), "invalid signature");
        mint1155Data memory mintData = mint1155Data(
            payable(msg.sender),
            _createData.nft,
            _createData.totalQuantity
        );
        uint256 tokenId = mint1155(mintData);

        emit CreatedNFT(tokenId);
    }
    function transferForFree721(transfer721Data memory _transferData) public onlyProxy {
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        uint256 tokenId = _transferData.tokenId;
        if(_transferData.tokenId == 0) {
            mint721Data memory mintData = mint721Data(
                _transferData.metadata,
                payable(msg.sender),
                _transferData.nft
            );
            tokenId = mint721(mintData);
        }
        transfer721(_transferData.nft, msg.sender, _transferData.newOwner, tokenId);
    }
    function transferForFree1155(transfer1155Data memory _transferData) public onlyProxy {
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid request");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        uint256 tokenId = _transferData.tokenId;
        if(_transferData.tokenId == 0) {
            mint1155Data memory mintData = mint1155Data(
                payable(msg.sender),
                _transferData.nft,
                _transferData.quantity
            );
            tokenId = mint1155(mintData);
        }
        transfer1155(_transferData.nft, _transferData.currentOwner, _transferData.newOwner, _transferData.quantity, tokenId);
    }

    //Functions only available for owner
    function acceptBid(acceptData memory _transferData) external payable onlyOwner onlyProxy {
        uint256 tokenId = _transferData.tokenId;
        if(_transferData.tokenId == 0) {
            mint721Data memory mintData = mint721Data(
                _transferData.metadata,
                payable(msg.sender),
                _transferData.nft
            );
            tokenId = mint721(mintData);
        }

        uint256 amountToTransfer = _transferData.amount;
        if(_transferData.percent > 0) {
            uint256 platformSharePercent = calculatePercentValue(_transferData.amount, _transferData.percent);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, _transferData.erc20token);
        }
        
        uint256 royaltyPercent;
        if(_transferData.royalty > 0) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, _transferData.erc20token);
        }

        transfer20(_transferData.newOwner, _transferData.currentOwner, amountToTransfer, _transferData.erc20token);
        transfer721(_transferData.nft, _transferData.currentOwner, _transferData.newOwner, tokenId);
        emit AutoAccepted(tokenId, royaltyPercent);
    }
    function withdrawBNB() public onlyOwner onlyProxy {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawERC20(address tokenAddress) public onlyOwner onlyProxy {
        ERC20Token token = ERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        token.transfer(owner(), balance);
    }
    fallback () payable external {}
    receive () payable external {}
}
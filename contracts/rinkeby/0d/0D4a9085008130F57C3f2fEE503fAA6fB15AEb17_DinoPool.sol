/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;


interface IDinoToken {

    function ownerOf(
        uint256 tokenId
    ) external returns (address);

}


interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(
        address owner
    ) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

}


interface IERC20 {

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );

    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
    function approve(
        address spender, 
        uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function allowance(
        address owner, 
        address spender
    ) external view returns (uint256);
    function totalSupply() external view returns (uint256);

}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

}


interface IRewardsPool {

    function addReward(
        address _receiver, 
        uint256 _amount
    ) external;

}


interface IUtilityManager {

    function updateStakedAmount(
        uint256 _amount
    ) external;
    function updateClaimedAmount(
        uint256 _amount
    ) external;
    function updateUnclaimedAmount(
        uint256 _amount, 
        uint256 _operation
    ) external;
    function updateTotalValueLockedAmount(
        uint256 _amount, 
        uint256 _operation
    ) external;

}


interface IAbstractRewards {

    event RewardsDistributed(
        address indexed by, 
        uint256 rewardsDistributed
    );
    event RewardsWithdrawn(
        address indexed by, 
        uint256 fundsWithdrawn
    );

    function withdrawableRewardsOf(
        address account
    ) external view returns (uint256);
    function withdrawnRewardsOf(
        address account
    ) external view returns (uint256);
    function cumulativeRewardsOf(
        address account
    ) external view returns (uint256);

}


interface ITimeLockPool {

    function deposit(
        uint256[] memory _ids,
        uint256 _duration,
        address _receiver
    ) external;

}


interface IBasePool {

    function distributeRewards(
        uint256 _amount
    ) external;

}


interface IERC165 {

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool);

}


interface IAccessControl {

    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function grantRole(
        bytes32 role, 
        address account
    ) external;
    function revokeRole(
        bytes32 role, 
        address account
    ) external;
    function renounceRole(
        bytes32 role, 
        address account
    ) external;
    function hasRole(
        bytes32 role, 
        address account
    ) external view returns (bool);
    function getRoleAdmin(
        bytes32 role
    ) external view returns (bytes32);
    
}


interface IAccessControlEnumerable is IAccessControl {

    function getRoleMember(
        bytes32 role, 
        uint256 index
    ) external view returns (address);
    function getRoleMemberCount(
        bytes32 role
    ) external view returns (uint256);

}


library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function add(
        Bytes32Set storage set, 
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(
        Bytes32Set storage set, 
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function add(
        AddressSet storage set, 
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressSet storage set, 
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(
        UintSet storage set, 
        uint256 value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        UintSet storage set, 
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function _add(
        Set storage set, 
        bytes32 value
    ) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(
        Set storage set, 
        bytes32 value
    ) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; 
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function contains(
        Bytes32Set storage set, 
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(
        Bytes32Set storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(
        Bytes32Set storage set, 
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    function contains(
        AddressSet storage set, 
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(
        AddressSet storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(
        AddressSet storage set, 
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function contains(
        UintSet storage set, 
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(
        UintSet storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(
        UintSet storage set, 
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function _contains(
        Set storage set, 
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(
        Set storage set
    ) private view returns (uint256) {
        return set._values.length;
    }

    function _at(
        Set storage set, 
        uint256 index
    ) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(
        Set storage set
    ) private view returns (bytes32[] memory) {
        return set._values;
    }

}


library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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


library Math {

    function max(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(
        uint256 a, 
        uint256 b
    ) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

}


library SafeERC20 {

    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function _callOptionalReturn(
        IERC20 token, 
        bytes memory data
    ) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }

}


library Counters {

    struct Counter {
        uint256 _value; // default: 0
    }

    function increment(
        Counter storage counter
    ) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(
        Counter storage counter
    ) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(
        Counter storage counter
    ) internal {
        counter._value = 0;
    }

    function current(
        Counter storage counter
    ) internal view returns (uint256) {
        return counter._value;
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

    function tryRecover(
        bytes32 hash, 
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
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

    function recover(
        bytes32 hash, 
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
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

    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function toTypedDataHash(
        bytes32 domainSeparator, 
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }

    function _throwError(
        RecoverError error
    ) private pure {
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

}


library SafeCast {

    function toUint224(
        uint256 value
    ) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(
        uint256 value
    ) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(
        uint256 value
    ) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(
        uint256 value
    ) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(
        uint256 value
    ) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(
        uint256 value
    ) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(
        uint256 value
    ) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(
        int256 value
    ) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(
        int256 value
    ) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(
        int256 value
    ) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(
        int256 value
    ) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(
        int256 value
    ) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(
        int256 value
    ) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(
        uint256 value
    ) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }

}


library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(
        uint256 value
    ) internal pure returns (string memory) {
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

    function toHexString(
        uint256 value
    ) internal pure returns (string memory) {
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

    function toHexString(
        uint256 value, 
        uint256 length
    ) internal pure returns (string memory) {
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

}


abstract contract EIP712 {

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    constructor(
        string memory name, 
        string memory version
    ) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _TYPE_HASH = typeHash;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

}


abstract contract ERC165 is IERC165 {

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}


abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}


abstract contract AccessControl is Context, IAccessControl, ERC165 {

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(
        bytes32 role
    ) {
        _checkRole(role, _msgSender());
        _;
    }

    function grantRole(
        bytes32 role, 
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(
        bytes32 role, 
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(
        bytes32 role, 
        address account
    ) public virtual override {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    function _setupRole(
        bytes32 role, 
        address account
    ) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(
        bytes32 role, 
        bytes32 adminRole
    ) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(
        bytes32 role, 
        address account
    ) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(
        bytes32 role, 
        address account
    ) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function hasRole(
        bytes32 role, 
        address account
    ) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(
        bytes32 role
    ) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function _checkRole(
        bytes32 role, 
        address account
    ) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

}


abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    function grantRole(
        bytes32 role, 
        address account
    ) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function revokeRole(
        bytes32 role, 
        address account
    ) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    function renounceRole(
        bytes32 role, 
        address account
    ) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    function _setupRole(
        bytes32 role, 
        address account
    ) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getRoleMember(
        bytes32 role, 
        uint256 index
    ) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(
        bytes32 role
    ) public view override returns (uint256) {
        return _roleMembers[role].length();
    }
    
}


abstract contract AbstractRewards is IAbstractRewards {

    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

    function(address) view returns (uint256) private immutable getSharesOf;
    function() view returns (uint256) private immutable getTotalShares;

    uint256 public pointsPerShare;
    mapping(address => int256) public pointsCorrection;
    mapping(address => uint256) public withdrawnRewards;

    constructor(
        function(address) view returns (uint256) getSharesOf_,
        function() view returns (uint256) getTotalShares_
    ) {
        getSharesOf = getSharesOf_;
        getTotalShares = getTotalShares_;
    }

    function _distributeRewards(
        uint256 _amount
    ) internal {
        uint256 shares = getTotalShares();
        require(
            shares > 0,
            "total share supply is zero"
        );

        if (_amount > 0) {
            pointsPerShare =
                pointsPerShare +
                ((_amount * POINTS_MULTIPLIER) / shares);
            emit RewardsDistributed(msg.sender, _amount);
        }
    }

    function _prepareCollect(
        address _account
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableRewardsOf(_account);
        if (_withdrawableDividend > 0) {
            withdrawnRewards[_account] =
                withdrawnRewards[_account] +
                _withdrawableDividend;
            emit RewardsWithdrawn(_account, _withdrawableDividend);
        }
        return _withdrawableDividend;
    }

    function _correctPointsForTransfer(
        address _from,
        address _to,
        uint256 _shares
    ) internal {
        int256 _magCorrection = (pointsPerShare * _shares).toInt256();
        pointsCorrection[_from] = pointsCorrection[_from] + _magCorrection;
        pointsCorrection[_to] = pointsCorrection[_to] - _magCorrection;
    }

    function _correctPoints(
        address _account, 
        int256 _shares
    ) internal {
        pointsCorrection[_account] =
            pointsCorrection[_account] + (_shares * (int256(pointsPerShare)));
    }

    function withdrawableRewardsOf(
        address _account
    ) public view override returns (uint256) {
        return cumulativeRewardsOf(_account) - withdrawnRewards[_account];
    }

    function withdrawnRewardsOf(
        address _account
    ) public view override returns (uint256) {
        return withdrawnRewards[_account];
    }

    function cumulativeRewardsOf(
        address _account
    ) public view override returns (uint256) {
        return
            ((pointsPerShare * getSharesOf(_account)).toInt256() +
                pointsCorrection[_account]).toUint256() / POINTS_MULTIPLIER;
    }

}


contract ERC20 is Context, IERC20, IERC20Metadata {

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_, 
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
    }

    function transfer(
        address recipient, 
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(
        address spender, 
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender, 
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender, 
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "zero address");
        require(recipient != address(0), "zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(
        address account, 
        uint256 amount
    ) internal virtual {
        require(account != address(0), "zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(
        address account, 
        uint256 amount
    ) internal virtual {
        require(account != address(0), "zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "zero address");
        require(spender != address(0), "zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner, 
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

}


abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
   
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 private immutable _PERMIT_TYPEHASH =
    keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    constructor(
        string memory name
    ) EIP712(name, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }

    function _useNonce(
        address owner
    ) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function nonces(
        address owner
    ) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

}


abstract contract ERC20Votes is ERC20Permit {

    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    Checkpoint[] private _totalSupplyCheckpoints;

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;

    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    function delegate(
        address delegatee
    ) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        return _delegate(signer, delegatee);
    }

    function _mint(
        address account, 
        uint256 amount
    ) internal virtual override {
        super._mint(account, amount);
        require(
            totalSupply() <= _maxSupply(),
            "total supply risks overflowing votes"
        );

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    function _burn(
        address account, 
        uint256 amount
    ) internal virtual override {
        super._burn(account, amount);
        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    function _delegate(
        address delegator, 
        address delegatee
    ) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[src],
                    _subtract,
                    amount
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[dst],
                    _add,
                    amount
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCast.toUint32(block.number),
                    votes: SafeCast.toUint224(newWeight)
                })
            );
        }
    }

    function _add(
        uint256 a, 
        uint256 b
    ) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(
        uint256 a, 
        uint256 b
    ) private pure returns (uint256) {
        return a - b;
    }

    function checkpoints(
        address account, 
        uint32 pos
    ) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    function numCheckpoints(
        address account
    ) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    function delegates(
        address account
    ) public view virtual returns (address) {
        return _delegates[account];
    }

    function getVotes(
        address account
    ) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    function getPastVotes(
        address account, 
        uint256 blockNumber
    ) public view returns (uint256) {
        require(blockNumber < block.number, "block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    function getPastTotalSupply(
        uint256 blockNumber
    ) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    function _checkpointsLookup(
        Checkpoint[] storage ckpts, 
        uint256 blockNumber
    ) private view returns (uint256) {
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

}


contract TokenSaver is AccessControlEnumerable {

    using SafeERC20 for IERC20;

    bytes32 public constant TOKEN_SAVER_ROLE = keccak256("TOKEN_SAVER_ROLE");

    event TokenSaved(
        address indexed by,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    modifier onlyTokenSaver() {
        require(
            hasRole(TOKEN_SAVER_ROLE, _msgSender()),
            "TokenSaver.onlyTokenSaver: permission denied"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function saveToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyTokenSaver {
        IERC20(_token).safeTransfer(_receiver, _amount);
        emit TokenSaved(_msgSender(), _receiver, _token, _amount);
    }

}


abstract contract BasePool is ERC20Votes, AbstractRewards, IBasePool, TokenSaver {
    
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }

    IERC20 public immutable depositToken;
    IERC20 public immutable rewardToken;

    address public utilityManager;
    address public rewardsPool;

    mapping(address => Deposit[]) public depositsOf;

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 _rewardAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        address _utilityManager,
        address _rewardsPool
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(
            _depositToken != address(0),
            "Deposit token not set"
        );
        depositToken = IERC20(_depositToken);
        rewardToken = IERC20(_rewardToken);
        utilityManager = _utilityManager;
        rewardsPool = _rewardsPool;
    }

    function distributeRewards(
        uint256 _amount
    ) external override {
        rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_amount);
    }

    function claimRewards(
        address _receiver
    ) external {
        uint256 rewardAmount = withdrawableRewardsOf(_receiver);

        if (rewardAmount != 0) {
            withdrawnRewards[_receiver] =
                withdrawnRewards[_receiver] +
                rewardAmount;
            rewardToken.safeTransfer(rewardsPool, rewardAmount);
            IRewardsPool(rewardsPool).addReward(_receiver, rewardAmount);
            IUtilityManager(utilityManager).updateClaimedAmount(rewardAmount);
            IUtilityManager(utilityManager).updateUnclaimedAmount(
                rewardAmount,
                0
            );
        }

        emit RewardsClaimed(_msgSender(), _receiver, rewardAmount);
    }

    function _mint(
        address _account, 
        uint256 _amount
    ) internal virtual override {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(
        address _account, 
        uint256 _amount
    ) internal virtual override {
        super._burn(_account, _amount);
        _correctPoints(_account, _amount.toInt256());
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._transfer(_from, _to, _value);
        _correctPointsForTransfer(_from, _to, _value);
    }

}


contract DinoPool is BasePool, ITimeLockPool {
 
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public maxBonus;
    uint256 public maxLockDuration;
    uint256 public minimumLockDuration = 10 minutes;
    uint256 public maximumNftStakingAllowed = 20;
    uint256 public maximumNftUnstakingAllowed = 20;
    uint256 public constant SINGLE_TOKEN = 1;

    address public owner;
    address public dinoToken;

    event Deposited(
        uint256 amount,
        uint256 duration,
        address indexed receiver,
        address indexed from
    );
    event Withdrawn(
        uint256 indexed depositId,
        address indexed receiver,
        address indexed from,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        uint256 _maxBonus,
        uint256 _maxLockDuration,
        address _utilityManager,
        address _rewardsPool,
        address _dinoToken
    ) BasePool(_name, _symbol, _depositToken, _rewardToken, _utilityManager, _rewardsPool) {
        require(
            _maxLockDuration >= minimumLockDuration,
            "Invalid lock duration"
        );
        maxBonus = _maxBonus;
        maxLockDuration = _maxLockDuration;
        owner = msg.sender;
        dinoToken = _dinoToken;
    }

    function setMaximumBonus(
        uint256 _maximumBonus
    ) external {
        require(
            owner == msg.sender,
            "Access Denied!"
        );
        require(
            _maximumBonus >= 1000000000000000000,
            "Minimum bonus required 1000000000000000000!"
        );
        maxBonus = _maximumBonus;
    }

    function setMinimumLockDuration(
        uint256 _minimumLockDuration
    ) external {
        require(
            owner == msg.sender,
            "Access Denied!"
        );
        require(
            maxLockDuration >= _minimumLockDuration,
            "Invalid duration"
        );
        minimumLockDuration = _minimumLockDuration;
    }

    function setMaximumLockDuration(
        uint256 _maximumLockDuration
    ) external {
        require(
            owner == msg.sender,
            "Access Denied!"
        );
        require(
            _maximumLockDuration >= minimumLockDuration,
            "Invalid lock duration"
        );
        maxLockDuration = _maximumLockDuration;
    }

    function setMaximumNftStakingAllowed(
        uint256 _maximumNftStakingAllowed
    ) external {
        require(
            owner == msg.sender,
            "Access Denied!"
        );
        maximumNftStakingAllowed = _maximumNftStakingAllowed;
    }

    function setMaximumNftUnstakingAllowed(
        uint256 _maximumNftUnstakingAllowed
    ) external {
        require(
            owner == msg.sender,
            "Access Denied!"
        );
        maximumNftUnstakingAllowed = _maximumNftUnstakingAllowed;
    }

    function changeContractOwner(
        address newOwner
    ) external {
        require(msg.sender == owner, "Access Denied!");
        require(newOwner != address(0), "Invalid address!");
        owner = newOwner;
    }

    function deposit(
        uint256[] memory _ids,
        uint256 _duration,
        address _receiver
    ) external override {
        require(
            _ids.length <= maximumNftStakingAllowed && _ids.length > 0,
            "Out of limit"
        );

        uint256 duration = _duration.min(maxLockDuration);
        duration = duration.max(minimumLockDuration);

        for (uint256 i = 0; i < _ids.length; i++) {
            _deposit(_ids[i], duration, _receiver);
        }

        // Minting SDT's as per NFT's staked
        uint256 mintAmount = (_ids.length * getMultiplier(duration)) / 1e18;
        _mint(_receiver, mintAmount);

        // Updating util values
        IUtilityManager(utilityManager).updateStakedAmount(_ids.length);
        IUtilityManager(utilityManager).updateTotalValueLockedAmount(
            _ids.length,
            1
        );
    }

    function withdraw(
        uint256[] memory _depositIds, 
        address _receiver
    ) external {
        require(_depositIds.length <= maximumNftUnstakingAllowed && _depositIds.length > 0, "Out of limit!");
        for (uint256 i = _depositIds.length - 1; i >= 0; i--) {
            require(
                _depositIds[i] < depositsOf[_msgSender()].length,
                "Deposit does not exist"
            );
            _withdraw(_depositIds[i], _receiver);
            if (i == 0) {
                break;
            }
        }
    }

    function _deposit(
        uint256 _amount,
        uint256 _duration,
        address _receiver
    ) internal {
        // Checking whether token belongs to caller or not
        address tokenOwner = IDinoToken(dinoToken).ownerOf(_amount);
        require(tokenOwner == msg.sender, "Not a owner!");

        // Transferring token to this contract
        depositToken.safeTransferFrom(_msgSender(), address(this), _amount);

        // creating a deposit entry for NFT
        depositsOf[_receiver].push(
            Deposit({
                amount: _amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(_duration)
            })
        );

        emit Deposited(_amount, _duration, _receiver, _msgSender());
    }

    function _withdraw(
        uint256 _depositId, 
        address _receiver
    ) internal {
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];

        if (block.timestamp >= userDeposit.end) {
            // No risk of wrapping around on casting to uint256 since deposit end always > deposit start and types are 64 bits
            uint256 shareAmount = (SINGLE_TOKEN *
                getMultiplier(uint256(userDeposit.end - userDeposit.start))) /
                1e18;

            // remove Deposit
            depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][
                depositsOf[_msgSender()].length - 1
            ];
            depositsOf[_msgSender()].pop();

            // burn pool shares
            _burn(_msgSender(), shareAmount);

            // return tokens
            depositToken.safeTransferFrom(
                address(this),
                _receiver,
                userDeposit.amount
            );

            // update util value
            IUtilityManager(utilityManager).updateTotalValueLockedAmount(
                SINGLE_TOKEN,
                0
            );

            emit Withdrawn(
                _depositId,
                _receiver,
                _msgSender(),
                userDeposit.amount
            );
        }
    }

    function getMultiplier(
        uint256 _lockDuration
    ) public view returns (uint256) {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    function getTotalDeposit(
        address _account
    ) public view returns (uint256) {
        return depositsOf[_account].length;
    }

    function getDepositsOf(
        address _account
    ) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(
        address _account
    ) public view returns (uint256) {
        return depositsOf[_account].length;
    }

}
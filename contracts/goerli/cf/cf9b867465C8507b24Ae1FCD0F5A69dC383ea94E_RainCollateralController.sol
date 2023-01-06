// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRainCollateral.sol";

/**
 *  @title RainCollateralController contract
 *  @notice Used to manage RainCollateral contracts.
 *          Most operational logics are implemented here
 *          while RainCollateral is mainly used to keep collateral.
 *          This contract will be owned by Rain company.
 */
contract RainCollateralController is Ownable {
    /// @notice Elliptic Curve Digital Signature Algorithm Used to validate signature
    using ECDSA for bytes32;

    // Struct of required fields for EIP-712 domain separator
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
    }

    // Struct of required fields for Pay signature
    struct Pay {
        address user;
        address collateral;
        address[] assets;
        uint256[] amounts;
        uint256 nonce;
        uint256 expiresAt;
    }

    // Struct of required fields for Withdraw signature
    struct Withdraw {
        address user;
        address collateral;
        address asset;
        uint256 amount;
        address recipient;
        uint256 nonce;
        uint256 expiresAt;
    }

    // User readable name of signing domain
    string public constant EIP712_DOMAIN_NAME = "Rain Collateral";

    // Current major version of signing domain
    string public constant EIP712_DOMAIN_VERSION = "1";

    // Type hash to check EIP712 domain separator validity in signature
    bytes32 public constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    // Type hash to check pay signature validity
    bytes32 public constant PAY_TYPE_HASH =
        keccak256(
            "Pay(address user,address collateral,address[] assets,uint[] amounts,uint nonce,uint expiresAt)"
        );

    // Type hash to check withdraw signature validity
    bytes32 public constant WITHDRAW_TYPE_HASH =
        keccak256(
            "Withdraw(address user,address collateral,address asset,uint amount,address recipient,uint nonce,uint expiresAt)"
        );

    /// @notice Address that runs admin functions.
    ///         Signature should be created by this address.
    address public controllerAdmin;

    /// @notice Treasury contract address where Rain Company keeps its treasury.
    ///         Payment and liqudation moves assets to treasury.
    address public treasury;

    /// @notice A counter to prevent duplicate transaction with same signature
    /// @dev using single nonce for all type of transactions
    ///      to ensure their order.
    /// key: address of RainCollateral
    /// value: counter of past transactions
    mapping(address => uint256) public nonce;

    /**
     * @notice Emitted when withdrawAsset is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _asset Asset contract address
     * @param _amount Amount of assets withdrawn
     */
    event Withdrawal(
        address indexed _collateralProxy,
        address _asset,
        uint256 _amount
    );

    /**
     * @notice Emitted when makePayment is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _assets Array of asset contract addresses paid from.
     *                Must be the same length with _amounts.
     * @param _amounts Array of amount of assets paid.
     *                 Must be the same length with _assets.
     */
    event Payment(
        address indexed _collateralProxy,
        address[] _assets,
        uint256[] _amounts
    );

    /**
     * @notice Emitted when liquidateAsset is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _assets Array of asset contract addresses liquidated from.
     *                Must be the same length with _amounts.
     * @param _amounts Array of amount of assets liquidated.
     *                 Must be the same length with _assets.
     */
    event Liquidation(
        address indexed _collateralProxy,
        address[] _assets,
        uint256[] _amounts
    );

    /**
     * @notice Used to authorize only RainCollateral admin
     * @dev Throws if called by any account other than RainCollateral admin.
     */
    modifier isCollateralAdmin(address _collateralProxy) {
        require(
            IRainCollateral(_collateralProxy).isAdmin(address(msg.sender)),
            "Unauthorized"
        );
        _;
    }

    /**
     * @notice Check if the signature is expired
     * @param _expiresAt timestamp when the signature expires
     */
    modifier activeSignature(uint256 _expiresAt) {
        // _expiresAt will be within 30 minutes to an hour since the signature was issued.
        require(block.timestamp < _expiresAt, "Expired signature");
        _;
    }

    /**
     * @notice Used to initialize
     * @dev Called only once and sets admin and treasury addresses
     * @param _controllerAdmin controller admin address to operate collateralProxies
     * @param _treasury Rain Company's treasury contract address
     */
    constructor(address _controllerAdmin, address _treasury) {
        controllerAdmin = _controllerAdmin;
        treasury = _treasury;
    }

    /**
     * @notice Used to withdraw assets owned by RainCollateral contract
     * @dev Checks {isCollateralAdmin} first
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _asset asset's contract address
     * @param _amount amount to withdraw
     * @param _recipient address to receive assets
     * @param _expiresAt timestamp when signature expires, in unix seconds
     * @param _salt disambiguating salt for signature
     * @param _signature controllerAdmin's signature for this action (generated by ECDSA)
     * NOTE: `_asset` can be only ERC20 token. ETHER is not supported in V1.
     *       see {ERC20-allowance} and {ERC20-transferFrom}
     *       see {_verifyWithdrawalSignature} function
     * Requirements:
     * - `_expiresAt` should be less than block timestamp.
     * - `_signature` should be valid.
     * - RainCollateral must have balance of asset >= `_amount`.
     */
    function withdrawAsset(
        address _collateralProxy,
        address _asset,
        uint256 _amount,
        address _recipient,
        uint256 _expiresAt,
        bytes32 _salt,
        bytes memory _signature
    ) external isCollateralAdmin(_collateralProxy) activeSignature(_expiresAt) {
        bytes32 messageHash = _hash(
            Withdraw({
                user: msg.sender,
                collateral: _collateralProxy,
                asset: _asset,
                amount: _amount,
                recipient: _recipient,
                nonce: nonce[_collateralProxy],
                expiresAt: _expiresAt
            })
        );
        _verifySignature(_collateralProxy, messageHash, _salt, _signature);

        IRainCollateral(_collateralProxy).withdrawAsset(
            _asset,
            _recipient,
            _amount
        );

        emit Withdrawal(_collateralProxy, _asset, _amount);
    }

    /**
     * @notice Used to make payment with  collateral assets owned by RainCollateral contract
     * @dev Use {_verifyPaymentSignature} to verify signature
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _assets array of asset's contract addresses
     * @param _amounts array of amounts corresponding to _assets
     * @param _expiresAt timestamp when signature expires as unix seconds
     * @param _salt disambiguating salt for signature
     * @param _signature controllerAdmin's signature for this action (generated by ECDSA)
     * Requirements:
     *
     * - `_expiresAt` should be less than block timestamp.
     * - `_signature` should be valid .
     */
    function makePayment(
        address _collateralProxy,
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256 _expiresAt,
        bytes32 _salt,
        bytes memory _signature
    ) external activeSignature(_expiresAt) {
        require(_assets.length == _amounts.length, "Invalid Params");

        bytes32 messageHash = _hash(
            Pay({
                user: msg.sender,
                collateral: _collateralProxy,
                assets: _assets,
                amounts: _amounts,
                nonce: nonce[_collateralProxy],
                expiresAt: _expiresAt
            })
        );
        _verifySignature(_collateralProxy, messageHash, _salt, _signature);

        for (uint256 i = 0; i < _assets.length; i++) {
            _transferToTreasury(_collateralProxy, _assets[i], _amounts[i]);
        }

        emit Payment(_collateralProxy, _assets, _amounts);
    }

    /**
     * @notice Used to transfer an amount of asset from RainCollateral contract to treasury contract
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _asset asset's contract address
     * @param _amount asset amount to transfer
     */

    function _transferToTreasury(
        address _collateralProxy,
        address _asset,
        uint256 _amount
    ) internal {
        IRainCollateral(_collateralProxy).withdrawAsset(
            _asset,
            treasury,
            _amount
        );
    }

    /**
     * @notice Sub function of _verifyPaymentSignature and _verifyWithdrawal
     *         used to verify signature is from controller admin
     * @dev increment nonce when signature is valid
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _messageHash keccak256 hashed message
     * @param _salt disambiguating salt for signature
     * @param _signature signature generated by controllerAdmin
     */
    function _verifySignature(
        address _collateralProxy,
        bytes32 _messageHash,
        bytes32 _salt,
        bytes memory _signature
    ) internal {
        bytes32 domainSeparator = _hash(
            EIP712Domain({
                name: EIP712_DOMAIN_NAME,
                version: EIP712_DOMAIN_VERSION,
                chainId: block.chainid,
                verifyingContract: address(this),
                salt: _salt
            })
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, _messageHash)
        );

        // verify that the signature was generated by controllerAdmin
        require(
            digest.recover(_signature) == controllerAdmin,
            "Invalid signature"
        );

        // update nonce
        nonce[_collateralProxy] += 1;
    }

    /**
     * @notice Build hash of EIP712 domain separator
     * @return bytes32 hash value
     */
    function _hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPE_HASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract,
                    eip712Domain.salt
                )
            );
    }

    /**
     * @notice Build hash of withdraw signature fields
     * @return bytes32 hash value
     */
    function _hash(Withdraw memory withdraw) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        WITHDRAW_TYPE_HASH,
                        withdraw.user,
                        withdraw.collateral,
                        withdraw.asset,
                        withdraw.amount
                    ),
                    abi.encode(
                        withdraw.recipient,
                        withdraw.nonce,
                        withdraw.expiresAt
                    )
                )
            );
    }

    /**
     * @notice Build hash of pay signature fields
     * @return bytes32 hash value
     */
    function _hash(Pay memory pay) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        PAY_TYPE_HASH,
                        pay.user,
                        pay.collateral,
                        keccak256(abi.encodePacked(pay.assets)),
                        keccak256(abi.encodePacked(pay.amounts))
                    ),
                    abi.encode(pay.nonce, pay.expiresAt)
                )
            );
    }

    /**
     * @notice Used to liquidate assets owned by RainCollateral contract
     * @dev loop to the assets and transfer them to treasury
     * Requirements:
     * - only controllerAdmin can call this function.
     * @param _collateralProxy targeting RainCollateral contract address
     * @param _assets array of asset's contract addresses
     * @param _amounts array of amounts corresponding to _assets
     */
    function liquidateAsset(
        address _collateralProxy,
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external {
        require(msg.sender == controllerAdmin, "Not controller admin");
        require(_assets.length == _amounts.length, "Invalid Params");
        for (uint256 i = 0; i < _assets.length; i++) {
            _transferToTreasury(_collateralProxy, _assets[i], _amounts[i]);
        }

        emit Liquidation(_collateralProxy, _assets, _amounts);
    }

    /**
     * @notice Used to update controller admin address
     * @dev only owner can call this function
     * @param _controllerAdmin new controller admin address
     * Requirements:
     * - `_controllerAdmin` should not be NullAddress.
     */
    function updateControllerAdmin(address _controllerAdmin)
        external
        onlyOwner
    {
        require(_controllerAdmin != address(0), "Zero Address");
        controllerAdmin = _controllerAdmin;
    }

    /**
     * @notice Used to update treasury contract address
     * @dev only owner can call this function
     * @param _treasury new treasury contract address
     * Requirements:
     * - `_newAddress` should not be NullAddress.
     */
    function updateTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero Address");
        treasury = _treasury;
    }

    /**
     * @notice Increase nonce of a collateral proxy by onwer
     * @dev can be used to invalidate a signature
     */
    function increaseNonce(address _collateralProxy) external onlyOwner {
        nonce[_collateralProxy]++;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
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

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
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

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IRainCollateral {
    function isAdmin(address) external view returns (bool);

    function withdrawAsset(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
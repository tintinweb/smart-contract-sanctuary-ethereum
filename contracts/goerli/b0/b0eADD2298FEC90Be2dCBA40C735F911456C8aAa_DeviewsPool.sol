// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../utils/IERC20.sol";
import "../utils/Init.sol";

///@title Deviews bonus pool contract
///@author Deviews
///@notice You can use this contract to withdraw bonuses.
///@dev Fund pool account,Contains the functions of signing multiple signatures and preventing re-entry attacks
///Prevent reentry attacks by assigning different nonce to each address,The contract can be used to withdraw
///cash after signing under the multi-wallet chain set in the contract.
contract DeviewsPool is Ownable, Init {
    event SignerUpdate(address signer, bool permission);
    event MultiSignState(bool state);
    event TokenChange(address token);
    event SignerNumberUpdate(uint256 signerNumber);
    event UpdateTeam(address team);
    event UpdateTreasury(address treasury);
    event UpdateStaker(address staker);
    event UpdateProportion(
        uint256 team,
        uint256 treasury,
        uint256 staker,
        uint256 burn,
        uint256 pool
    );
    event Withdrawal(address indexed toAddress, uint256 value);
    event AddRewards(
        address indexed supportAddress,
        bytes32 indexed project,
        uint256 poolAmount,
        uint256 stakerAmount,
        uint256 burnAmount,
        uint256 teamAmount,
        uint256 treasuryAmount,
        uint256 releaseDays
    );

    //Does the account have signature authority
    mapping(address => bool) private signers;
    //Nonce to Prevent Re-entry Attacks
    mapping(address => uint256) private poolNonce;
    //Account with signature permission
    address[] private listOfSigner;
    //Profit sharing ratio
    //ts：team , trs treasury , ss staker , bs burn , ps pool
    uint256 ts;
    uint256 trs;
    uint256 ss;
    uint256 bs;
    uint256 ps;
    //Number of signatures required when multiple signatures are opened
    uint256 private signerNumber;
    //Whether to turn on multi-sign
    bool private multiSig;
    //Deviews ERC20 token address
    address private token;

    address private _team;
    address private _treasury;
    address private _staker;

    ///@dev The access method requires multiple signatures to be turned on.
    modifier openMuiltSig() {
        require(multiSig, "Multiple signatures are not supported");
        _;
    }
    ///@dev The access method requires multiple signatures to be turned off.
    modifier closeMuiltSig() {
        require(!multiSig, "Single sign is not supported");
        _;
    }

    ///@dev Can only run once
    function init(
        address tokenAddr,
        address team,
        address treasury,
        address staker,
        uint256[5] memory proportion,
        bool useMultiSig
    ) public onlyOwner initializer {
        token = tokenAddr;
        _team = team;
        _treasury = treasury;
        _staker = staker;
        multiSig = useMultiSig;
        ts = proportion[0];
        trs = proportion[1];
        ss = proportion[2];
        bs = proportion[3];
        ps = proportion[4];
    }

    function updateTeam(address team) public onlyOwner {
        _team = team;
        emit UpdateTeam(_team);
    }

    function updateTreasury(address treasury) public onlyOwner {
        _treasury = treasury;
        emit UpdateTreasury(_treasury);
    }

    function updateStaker(address staker) public onlyOwner {
        _staker = staker;
        emit UpdateStaker(_staker);
    }

    function updateProportion(
        uint256 team,
        uint256 treasury,
        uint256 staker,
        uint256 burn,
        uint256 pool
    ) public onlyOwner {
        ts = team;
        trs = treasury;
        ss = staker;
        bs = burn;
        ps = pool;
        emit UpdateProportion(ts, trs, ss, bs, ps);
    }

    ///@dev Add signature address
    ///@param poolSigner Signature address
    function addSigner(address poolSigner) public onlyOwner {
        signers[poolSigner] = true;
        uint256 signerIndex = 0;
        for (uint256 i = 0; i < listOfSigner.length; i++) {
            if (listOfSigner[i] == poolSigner) {
                signerIndex = i + 1;
            }
        }
        if (signerIndex == 0) {
            listOfSigner.push(poolSigner);
        }
        emit SignerUpdate(poolSigner, true);
    }

    ///@dev Remove signature address
    ///@param poolSigner Signature address
    function removaSigner(address poolSigner) public onlyOwner {
        signers[poolSigner] = false;
        uint256 signerIndex = 0;
        for (uint256 i = 0; i < listOfSigner.length; i++) {
            if (listOfSigner[i] == poolSigner) {
                signerIndex = i + 1;
            }
        }
        if (signerIndex >= 1) {
            listOfSigner[signerIndex - 1] = listOfSigner[
                listOfSigner.length - 1
            ];
            listOfSigner.pop();
        }
        emit SignerUpdate(poolSigner, false);
    }

    ///@notice Turn multiple signatures on or off, depending on the current contract status
    function enableOrStopMuiltSig() public onlyOwner {
        multiSig = !multiSig;
        emit MultiSignState(multiSig);
    }

    function updateToken(address tokenAddr) public onlyOwner {
        token = tokenAddr;
        emit TokenChange(tokenAddr);
    }

    ///@notice Change the number of signatures
    ///@notice The number of signatures is less than or equal to the number of people with signature permissions.
    function updateSignerNumber(uint256 num) public onlyOwner {
        signerNumber = num;
        emit SignerNumberUpdate(num);
    }

    function generateEthSignMessage(
        address toAddress,
        uint256 value,
        uint256 deadline
    ) public view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(toAddress, value, deadline, poolNonce[toAddress])
        );
        bytes32 ethMsg = ECDSA.toEthSignedMessageHash(message);
        return ethMsg;
    }

    ///@notice To claim rewards, the key issued by the bonus pool address is needed
    ///@param toAddress target address
    ///@param value rewards to be claimed
    ///@param deadline the timestamp of deadline
    ///@param v key v
    ///@param r key r
    ///@param s key s
    function rewards(
        address toAddress,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public closeMuiltSig {
        //check the current time whether reached the deadline
        require(block.timestamp <= deadline, "Expired");
        //verify the signature
        require(
            signers[recoverSigner(toAddress, value, deadline, v, r, s)],
            "Unauthorized"
        );
        _useNonce(toAddress);
        //transfer
        IERC20(token).transfer(toAddress, value);
        emit Withdrawal(toAddress, value);
    }

    ///@notice Multi-Signature Bonus
    ///@param toAddress target address
    ///@param value rewards to be claimed
    ///@param deadline the timestamp of deadline
    ///@param kvs key v
    ///@param krs key r
    ///@param kss key s
    function rewardsMultisig(
        address toAddress,
        uint256 value,
        uint256 deadline,
        uint8[] memory kvs,
        bytes32[] memory krs,
        bytes32[] memory kss
    ) public openMuiltSig {
        require(block.timestamp <= deadline, "Expired");
        require(kvs.length == krs.length, "Unauthorized");
        require(kss.length == krs.length, "Unauthorized");
        require(kss.length == signerNumber, "Unauthorized");
        address[] memory addrs = new address[](kvs.length);
        for (uint256 i = 0; i < kvs.length; i++) {
            address _signer = recoverSigner(
                toAddress,
                value,
                deadline,
                kvs[i],
                krs[i],
                kss[i]
            );
            addrs[i] = _signer;
        }
        require(distinctSigs(addrs), "Unauthorized");
        _useNonce(toAddress);
        //transfer
        IERC20(token).transfer(toAddress, value);
        emit Withdrawal(toAddress, value);
    }

    ///@notice Add bonus to a project to support it, trigger Support event, listen to the amount of bonus added
    ///@param project the address of the contract
    ///@param amount the amount of bonus added
    ///@param releaseDays the time for releasing
    function addRewards(
        bytes32 project,
        uint256 amount,
        uint256 releaseDays
    ) public returns (bool) {
        require(amount != 0, "Support amount cannot be 0");
        require(releaseDays != 0, "Release days cannot be 0");
        //sum of the proportions
        uint256 _total = ts + trs + ss + bs + ps;
        // _transfer(_msgSender(), contractAddress, amount);
        //the amount to the team
        uint256 ta = (amount * ts) / _total;
        //the amount to the treasury
        uint256 tra = (amount * trs) / _total;
        //the amount to staker
        uint256 sa = (amount * ss) / _total;
        //the amount for burning
        uint256 ba = (amount * bs) / _total;
        //considering the calculation precision, the rewards to reviewers will be calculated by subtracting team,
        //treasury, staker, burn from the total bonus added
        uint256 poolAmount = amount - ta - tra - sa - ba;
        IERC20(token).transferFrom(_msgSender(), _team, ta);
        IERC20(token).transferFrom(_msgSender(), _treasury, tra);
        IERC20(token).transferFrom(_msgSender(), _staker, sa);
        IERC20(token).burnFrom(_msgSender(), ba);
        IERC20(token).transferFrom(_msgSender(), address(this), poolAmount);
        //trigger Support event
        emit AddRewards(
            _msgSender(),
            project,
            poolAmount,
            sa,
            ba,
            ta,
            tra,
            releaseDays
        );
        return true;
    }

    ///@notice Get the assigned nonce of the target address
    ///@param toAddress target address
    ///@return assigned nonce of target address
    function nonce(address toAddress) public view returns (uint256) {
        return poolNonce[toAddress];
    }

    function viewExternalAddress()
        public
        view
        returns (
            address,
            address,
            address
        )
    {
        return (_team, _staker, _treasury);
    }

    function viewSigners() public view returns (address[] memory) {
        return listOfSigner;
    }

    function viewMuiltSig() public view returns (bool) {
        return multiSig;
    }

    function viewProportion()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (ts, trs, ss, bs, ps);
    }

    ///@dev Determine whether the address is a signature address
    ///Determine if the address is duplicated
    ///@param addresses signers
    function distinctSigs(address[] memory addresses)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            //address should be distinct
            if (!signers[addresses[i]]) {
                return false;
            }
            for (uint256 j = 0; j < i; j++) {
                if (addresses[i] == addresses[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function recoverSigner(
        address toAddress,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 _hash = generateEthSignMessage(toAddress, value, deadline);
        return ECDSA.recover(_hash, v, r, s);
    }

    ///@notice Use nonce to increase
    function _useNonce(address toAddress) internal {
        poolNonce[toAddress]++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

///@dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
    ///@dev Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    ///@dev Moves `amount` tokens from the caller's account to `to`.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) external returns (bool);

    ///@dev burn tokens in authorized accounts
    function burnFrom(address account, uint256 amount) external;

    ///@dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev Moves `amount` tokens from `from` to `to` using the
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

///@dev Guaranteed that the contract can only be initialized once
abstract contract Init {
    bool private _init;

    event Initialized(bool);
    ///@dev Initialization function modifier
    modifier initializer() {
        require(!_init, "Initialized");
        _init = true;
        emit Initialized(true);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
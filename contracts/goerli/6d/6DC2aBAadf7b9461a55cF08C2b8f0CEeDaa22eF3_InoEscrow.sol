//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./InoEscrowDeclaration.sol";
import "./access/OwnableForever.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract InoEscrow is InoEscrowDeclaration, OwnableForever {
    // maps inoID => Ino struct
    mapping(uint256 => Ino) public inos;

    // maps inoID => skuID => quantity available (for FCFS INOs)
    mapping(uint256 => mapping(uint256 => uint256)) public inoSkusAvailable;

    // maps userAddress => inoID => skuID => UserInoSku struct
    mapping(address => mapping(uint256 => mapping(uint256 => UserInoSku))) public userInoSkus;

    address public couponSigner;

    constructor(
        address _couponSigner
    ) {
        couponSigner = _couponSigner;
    }

    function purchase(
        uint256 _inoID,
        uint256 _skuID,
        uint232 _escrowAmount,
        uint16 _numNftsToPurchase,
        uint256 _numNftsAllowed,
        uint256 _expirationDate,
        bytes calldata _signature
    )
        external
        payable
    {
        // Verify _signature against details and revert if invalid.
        if (!isValidPurchaseSignature(
            _signature,
            _msgSender(),
            _inoID,
            _skuID,
            _escrowAmount,
            _numNftsToPurchase,
            _numNftsAllowed,
            _expirationDate,
            block.chainid,
            address(this)
        )) revert InvalidSignature();

        // Revert if the signature's expirationDate has passed
        if (_expirationDate < block.timestamp) revert SignatureExpired();

        // Look up INO details and revert if not yet created.
        Ino storage ino = inos[_inoID];
        if (!ino.created) revert InoNotFound();

        // If FCFS, check against inoSkusAvailable, revert or reduce qty available
        if (!ino.isLottery) {
            if (_numNftsToPurchase > inoSkusAvailable[_inoID][_skuID])
                revert ExceedsSkuQuantityAvailable();
            unchecked {
                inoSkusAvailable[_inoID][_skuID] -= _numNftsToPurchase;
            }
        }

        // Look up user INO details
        UserInoSku storage userInoSku = userInoSkus[_msgSender()][_inoID][_skuID];

        // Update the INO
        unchecked {
            ino.totalEscrowBalance += _escrowAmount;
        }

        // Update this userInoSku
        unchecked {
            userInoSku.escrowBalance += _escrowAmount;
            userInoSku.nftsPurchased += _numNftsToPurchase;
        }

        // Revert if this purchase puts the user over their limit.
        if (userInoSku.nftsPurchased > _numNftsAllowed)
            revert ExceedsUserAllocation();

        if (ino.escrowToken == address(0)) {
            if (msg.value != _escrowAmount) revert IncorrectEscrowAmount();
        }
        else {
            IERC20(ino.escrowToken).transferFrom(
                _msgSender(),
                address(this),
                _escrowAmount
            );
        }

        emit PurchaseEscrowed(
            _msgSender(),
            _inoID,
            _skuID,
            _escrowAmount,
            _numNftsToPurchase
        );
    }

    function claimRefund(
        uint256 _inoID,
        uint256 _skuID,
        uint232 _refundAmount,
        uint16 _numNftsToRefund,
        bytes calldata _signature
    )
        external
    {
        // Verify _signature against details and revert if invalid.
        if (!isValidRefundSignature(
            _signature,
            _msgSender(),
            _inoID,
            _skuID,
            _refundAmount,
            _numNftsToRefund,
            block.chainid,
            address(this)
        )) revert InvalidSignature();

        // Look up INO details, revert if not found or not a lottery
        Ino storage ino = inos[_inoID];
        if (!ino.created) revert InoNotFound();
        if (!ino.isLottery) revert InoNotLottery();

        // Revert if the INO refunds have expired
        if (block.timestamp > ino.refundExpiryDate) revert RefundExpired();

        // Revert if the INO doesn't have enough to cover refund
        if (_refundAmount > ino.totalEscrowBalance)
            revert RefundExceedsInoEscrow();

        // Look up user INO details
        UserInoSku storage userInoSku = userInoSkus[_msgSender()][_inoID][_skuID];

        // Revert if this userInoSku was already refunded
        if (userInoSku.refunded) revert RefundAlreadyClaimed();

        // Revert if there's not enough escrow for the refund
        if (_refundAmount > userInoSku.escrowBalance)
            revert RefundExceedsUserEscrow();

        // Update the INO
        unchecked {
            ino.totalEscrowBalance -= _refundAmount;
        }

        // Update the userInoSku
        unchecked {
            userInoSku.escrowBalance -= _refundAmount;
            userInoSku.nftsPurchased -= _numNftsToRefund;
            userInoSku.refunded = true;
        }

        // Issue refund
        if (ino.escrowToken == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: _refundAmount}("");
            if (!success) revert RefundWithdrawCallFailed();
        }
        else {
            IERC20(ino.escrowToken).transfer(
                _msgSender(),
                _refundAmount
            );
        }

        emit RefundClaimed(
            _msgSender(),
            _inoID,
            _skuID,
            _refundAmount,
            _numNftsToRefund
        );
    }

    function createInoLottery(
        uint256 _inoID,
        address _escrowToken,
        uint16 _refundExpiryDays
    )
        external
        onlyOwner
    {
        if (_refundExpiryDays == 0) _refundExpiryDays = 1825;
        uint256[] memory empty = new uint256[](0);
        _createIno(
            _inoID,
            _escrowToken,
            _refundExpiryDays,
            empty,
            empty
        );
    }

    function createInoFcfs(
        uint256 _inoID,
        address _escrowToken,
        uint256[] calldata _skuIDs,
        uint256[] calldata _skuQuantities
    )
        external
        onlyOwner
    {
        if (_skuIDs.length == 0) revert MissingSkus();
        _createIno(
            _inoID,
            _escrowToken,
            0,
            _skuIDs,
            _skuQuantities
        );
    }

    function _createIno(
        uint256 _inoID,
        address _escrowToken,
        uint16 _refundExpiryDays,
        uint256[] memory _skuIDs,
        uint256[] memory _skuQuantities
    )
        private
    {
        if (_skuIDs.length != _skuQuantities.length)
            revert ArrayLengthMismatch();

        Ino storage ino = inos[_inoID];
        if (ino.created) revert InoAlreadyCreated();

        ino.created = true;
        ino.escrowToken = _escrowToken;
        ino.refundExpiryDate = addDays(block.timestamp, _refundExpiryDays);
        ino.isLottery = _skuIDs.length == 0;
        if (!ino.isLottery) {
            for (uint i; i < _skuIDs.length; i++) {
                if (inoSkusAvailable[_inoID][_skuIDs[i]] > 0) revert SkuIdDuplicated();
                if (_skuQuantities[i] == 0) revert SkuQuantityCannotBeZero();
                inoSkusAvailable[_inoID][_skuIDs[i]] = _skuQuantities[i];
            }
        }
    }

    function extendInoRefundExpiryDate(
        uint256 _inoID,
        uint16 _daysToExtend
    )
        external
        onlyOwner
    {
        Ino storage ino = inos[_inoID];
        if (!ino.isLottery) revert FcfsCannotHaveRefunds();
        ino.refundExpiryDate = addDays(ino.refundExpiryDate, _daysToExtend);
    }

    function disburseInoFunds(
        uint256 _inoID,
        uint256 _disburseAmount,
        address _disburseTo
    )
        external
        onlyOwner
    {
        if (_disburseTo == address(0)) revert CannotDisburseToZeroAddress();

        Ino storage ino = inos[_inoID];
        if (_disburseAmount > ino.totalEscrowBalance)
            revert DisburseExceedsInoEscrow();

        unchecked {
            ino.totalEscrowBalance -= _disburseAmount;
            ino.totalDisbursed += _disburseAmount;
        }

        if (ino.escrowToken == address(0)) {
            (bool success, ) = payable(_disburseTo).call{value: _disburseAmount}("");
            if (!success) revert DisburseCallFailed();
        }
        else {
            IERC20(ino.escrowToken).transfer(_disburseTo, _disburseAmount);
        }
    }

    function setCouponSigner(
        address _newCouponSigner
    )
        external
        onlyOwner
    {
        couponSigner = _newCouponSigner;
    }

    function isValidPurchaseSignature(
        bytes calldata _signature,
        address _sender,
        uint256 _inoID,
        uint256 _skuID,
        uint240 _escrowAmount,
        uint16 _numNftsToPurchase,
        uint256 _numNftsAllowed,
        uint256 _expirationDate,
        uint256 _chainID,
        address _contract
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _sender,
                    _inoID,
                    _skuID,
                    _escrowAmount,
                    _numNftsToPurchase,
                    _numNftsAllowed,
                    _expirationDate,
                    _chainID,
                    _contract
                )
            )
        );
        return couponSigner == ECDSA.recover(hash, _signature);
    }

    function isValidRefundSignature(
        bytes calldata _signature,
        address _sender,
        uint256 _inoID,
        uint256 _skuID,
        uint240 _refundAmount,
        uint16 _numNftsToRefund,
        uint256 _chainID,
        address _contract
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _sender,
                    _inoID,
                    _skuID,
                    _refundAmount,
                    _numNftsToRefund,
                    _chainID,
                    _contract
                )
            )
        );
        return couponSigner == ECDSA.recover(hash, _signature);
    }

    function addDays(
        uint256 _timestamp,
        uint16 _numDays
    )
        private
        pure
        returns (uint256)
    {
        return _timestamp + uint256(_numDays) * 1 days;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InoEscrowDeclaration {
    struct Ino {
        bool created;
        bool isLottery;
        address escrowToken;
        uint256 refundExpiryDate;
        uint256 totalEscrowBalance;
        uint256 totalDisbursed;
    }

    struct UserInoSku {
        uint232 escrowBalance;
        uint16 nftsPurchased;
        bool refunded;
    }

    event PurchaseEscrowed(
        address indexed sender,
        uint256 indexed inoID,
        uint256 indexed skuID,
        uint232 escrowAmount,
        uint16 numNfts
    );

    event RefundClaimed(
        address indexed receiver,
        uint256 indexed inoID,
        uint256 indexed skuID,
        uint232 refundAmount,
        uint16 numNfts
    );

    error ArrayLengthMismatch();
    error CannotDisburseToZeroAddress();
    error ExceedsUserAllocation();
    error ExceedsSkuQuantityAvailable();
    error DisburseCallFailed();
    error DisburseExceedsInoEscrow();
    error FcfsCannotHaveRefunds();
    error IncorrectEscrowAmount();
    error InoAlreadyCreated();
    error InoNotFound();
    error InoNotLottery();
    error InvalidSignature();
    error MissingSkus();
    error RefundAlreadyClaimed();
    error RefundExceedsInoEscrow();
    error RefundExceedsUserEscrow();
    error RefundExpired();
    error RefundWithdrawCallFailed();
    error SignatureExpired();
    error SkuIdDuplicated();
    error SkuQuantityCannotBeZero();
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// With renounceOwnership removed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract OwnableForever is Context {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
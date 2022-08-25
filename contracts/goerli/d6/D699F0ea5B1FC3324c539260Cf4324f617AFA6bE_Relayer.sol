pragma solidity 0.5.7;

import "IRSV.sol";
import "Ownable.sol";
import "ECDSA.sol";

/**
 * @title The Reserve Relayer Contract
 * @dev A contract to support metatransactions via ECDSA signature verification.
 *
 */
contract Relayer is Ownable {

    IRSV public trustedRSV;
    mapping(address => uint) public nonce;

    event RSVChanged(address indexed oldRSVAddr, address indexed newRSVAddr);

    event TransferForwarded(
        bytes sig,
        address indexed from,
        address indexed to,
        uint256 indexed amount,
        uint256 fee
    );
    event TransferFromForwarded(
        bytes sig,
        address indexed holder,
        address indexed spender,
        address indexed to,
        uint256 amount,
        uint256 fee
    );
    event ApproveForwarded(
        bytes sig,
        address indexed holder,
        address indexed spender,
        uint256 amount,
        uint256 fee
    );
    event FeeTaken(address indexed from, address indexed to, uint256 indexed value);

    constructor(address rsvAddress) public {
        trustedRSV = IRSV(rsvAddress);
    }

    /// Set the Reserve contract address.
    function setRSV(address newTrustedRSV) external onlyOwner {
        emit RSVChanged(address(trustedRSV), newTrustedRSV);
        trustedRSV = IRSV(newTrustedRSV);
    }

    /// Forward a signed `transfer` call to the RSV contract if `sig` matches the signature.
    /// Note that `amount` is not reduced by `fee`; the fee is taken separately.
    function forwardTransfer(
        bytes calldata sig,
        address from,
        address to,
        uint256 amount,
        uint256 fee
    )
        external
    {
        bytes32 hash = keccak256(abi.encodePacked(
            address(trustedRSV),
            "forwardTransfer",
            from,
            to,
            amount,
            fee,
            nonce[from]
        ));
        nonce[from]++;

        address recoveredSigner = _recoverSignerAddress(hash, sig);
        require(recoveredSigner == from, "invalid signature");

        _takeFee(from, fee);

        require(
            trustedRSV.relayTransfer(from, to, amount), 
            "Reserve.sol relayTransfer failed"
        );
        emit TransferForwarded(sig, from, to, amount, fee);
    }

    /// Forward a signed `approve` call to the RSV contract if `sig` matches the signature.
    /// Note that `amount` is not reduced by `fee`; the fee is taken separately.
    function forwardApprove(
        bytes calldata sig,
        address holder,
        address spender,
        uint256 amount,
        uint256 fee
    )
        external
    {
        bytes32 hash = keccak256(abi.encodePacked(
            address(trustedRSV),
            "forwardApprove",
            holder,
            spender,
            amount,
            fee,
            nonce[holder]
        ));
        nonce[holder]++;

        address recoveredSigner = _recoverSignerAddress(hash, sig);
        require(recoveredSigner == holder, "invalid signature");

        _takeFee(holder, fee);

        require(
            trustedRSV.relayApprove(holder, spender, amount), 
            "Reserve.sol relayApprove failed"
        );
        emit ApproveForwarded(sig, holder, spender, amount, fee);
    }

    /// Forward a signed `transferFrom` call to the RSV contract if `sig` matches the signature.
    /// Note that `fee` is not deducted from `amount`, but separate.
    /// Allowance checking is left up to the Reserve contract to do.
    function forwardTransferFrom(
        bytes calldata sig,
        address holder,
        address spender,
        address to,
        uint256 amount,
        uint256 fee
    )
        external
    {
        bytes32 hash = keccak256(abi.encodePacked(
            address(trustedRSV),
            "forwardTransferFrom",
            holder,
            spender,
            to,
            amount,
            fee,
            nonce[spender]
        ));
        nonce[spender]++;

        address recoveredSigner = _recoverSignerAddress(hash, sig);
        require(recoveredSigner == spender, "invalid signature");

        _takeFee(spender, fee);

        require(
            trustedRSV.relayTransferFrom(holder, spender, to, amount), 
            "Reserve.sol relayTransfer failed"
        );
        emit TransferFromForwarded(sig, holder, spender, to, amount, fee);
    }

    /// Recover the signer's address from the hash and signature.
    function _recoverSignerAddress(bytes32 hash, bytes memory sig)
        internal pure
        returns (address)
    {
        bytes32 ethMessageHash = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(ethMessageHash, sig);
    }

    /// Transfer a fee from payer to sender.
    function _takeFee(address payer, uint256 fee) internal {
        if (fee != 0) {
            require(trustedRSV.relayTransfer(payer, msg.sender, fee), "fee transfer failed");
            emit FeeTaken(payer, msg.sender, fee);
        }
    }

}

pragma solidity 0.5.7;

interface IRSV {
    // Standard ERC20 functions
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function allowance(address, address) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // RSV-specific functions
    function decimals() external view returns(uint8);
    function mint(address, uint256) external;
    function burnFrom(address, uint256) external;
    function relayTransfer(address, address, uint256) external returns(bool);
    function relayTransferFrom(address, address, address, uint256) external returns(bool);
    function relayApprove(address, address, uint256) external returns(bool);
}

pragma solidity 0.5.7;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account
 * (owner) that can be granted exclusive access to specific functions.
 *
 * This module is used through inheritance by using the modifier `onlyOwner`.
 *
 * To change ownership, use a 2-part nominate-accept pattern.
 *
 * This contract is loosely based off of https://git.io/JenNF but additionally requires new owners
 * to accept ownership before the transition occurs.
 */
contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event NewOwnerNominated(address indexed previousOwner, address indexed nominee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current nominated owner.
     */
    function nominatedOwner() external view returns (address) {
        return _nominatedOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(_msgSender() == _owner, "caller is not owner");
    }

    /**
     * @dev Nominates a new owner `newOwner`.
     * Requires a follow-up `acceptOwnership`.
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is 0 address");
        emit NewOwnerNominated(_owner, newOwner);
        _nominatedOwner = newOwner;
    }

    /**
     * @dev Accepts ownership of the contract.
     */
    function acceptOwnership() external {
        require(_nominatedOwner == _msgSender(), "unauthorized");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
    }

    /** Set `_owner` to the 0 address.
     * Only do this to deliberately lock in the current permissions.
     *
     * THIS CANNOT BE UNDONE! Call this only if you know what you're doing and why you're doing it!
     */
    function renounceOwnership(string calldata declaration) external onlyOwner {
        string memory requiredDeclaration = "I hereby renounce ownership of this contract forever.";
        require(
            keccak256(abi.encodePacked(declaration)) ==
            keccak256(abi.encodePacked(requiredDeclaration)),
            "declaration incorrect");

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

pragma solidity 0.5.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.5.7;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 *
 * All credit to OpenZeppelin. Taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol at commit 65e4ffde586ec89af3b7e9140bdc9235d1254853.
 *
 * Note that the solidity version has been changed from ^0.6.0 to 0.5.7. 
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        // require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
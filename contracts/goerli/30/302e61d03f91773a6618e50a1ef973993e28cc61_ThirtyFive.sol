/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

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

/**
 * @title ThirtyFive
 * @author Razzor (https://ciphershastra.com/ThirtyFive)
 */

pragma solidity ^0.7.0;

contract ThirtyFive{
    using ECDSA for bytes32;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"); 
    bytes32 public constant SIGNING_TYPEHASH = keccak256("SIGNING(uint16 nonce,uint256 expiry)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable name;
    bytes32 public immutable version;

    mapping(address=>uint24) public nonces;
    mapping(address=>bytes32) internal verificationTokens;
    mapping(address=>bool) internal isTokenGenerated;
    mapping(bytes32=>bool) internal identifiers;
    mapping(address=>uint256) public pwnCounter;

    event TokenGen(address indexed signer, bytes32 indexed token);

    constructor(string memory _name, string memory _version){
        bytes32 name_ = keccak256(bytes(_name));
        bytes32 version_ = keccak256(bytes(_version));
        name = name_;
        version = version_;
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, name_, version_, chainId, address(this)));
    }
    
    fallback() payable external{

    }

    function signItLikeYouMeanIt(uint16 nonce, uint deadline, bytes memory signature) external{
        require(block.timestamp <= deadline, "Expired");
        require(nonce == nonces[msg.sender]+1, "Invalid Nonce");
        bytes32 structHash = keccak256(abi.encode(SIGNING_TYPEHASH, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = digest.recover(signature);
        require(signer == msg.sender, "Only Self Signed Signatures are allowed");
        bytes32 slot = keccak256(abi.encode(msg.sender, 0));
        assembly{
            sstore(slot, calldataload(4))     
        }
    }

    function giveMeMyToken() external{
        if (nonces[msg.sender] > 0x5014C3 && !isTokenGenerated[msg.sender]) {
            bytes32 token = keccak256(abi.encode(msg.sender,block.timestamp));
            verificationTokens[msg.sender] = token;
            isTokenGenerated[msg.sender]=true;
            emit TokenGen(msg.sender, token);
        }
    }

    function pwn(bytes32 token) external{
        require(token!=bytes32(0), "No Token Yet");
        require(token == verificationTokens[msg.sender], "Invalid Token");
        bytes32 id = keccak256(msg.data);
        require(!identifiers[id], "Already executed");
        identifiers[id] = true;
        ++pwnCounter[msg.sender]; 
    }

    function HackerWho() external view returns(string memory){
        uint counter = pwnCounter[msg.sender];

        if (counter > 0 && counter <= 2){
            return "Yayyy! You solved the challenge";
        }
        else if (counter > 2) {
            return "Hello Hacker";
        }

        else { return "Not yet" ;}
   
    }

}
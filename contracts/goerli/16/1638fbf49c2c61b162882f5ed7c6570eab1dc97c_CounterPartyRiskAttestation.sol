// @title CounterPartyRiskAttestation
// @notice Provides functions to verify off chain information about counter party risk
// @author Anibal Catalan <[email protected]>
pragma solidity ^0.8.17;

import "@src/ICounterPartyRiskAttestation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CounterPartyRiskAttestation is ICounterPartyRiskAttestation, Ownable {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    // Events
    event CounterpartyRiskAttestation(address indexed _customerVASP, address indexed _originator, address indexed _beneficiary, string _symbol, uint256 _amount);

    address private signer;

    // Notabene txHash to source to verified
    mapping (bytes32 =>  bytes) private signatureOfHash; 

    // Domain Hash
    bytes32 private immutable eip712DomainHash;

    // Type Hash
    bytes32 constant CRA_TYPEHASH = keccak256(
        "CRA(address VASPAddress,address originator,address beneficiary,string symbol,uint256 amount,uint256 expireAt)"
    );

    // Domain hash
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    constructor(address _signer) {
        require(_signer != address(0), "CRA: Please use a non 0 address");
        signer = _signer;
        eip712DomainHash = _hash(EIP712Domain({
            name: "Counter Party Risk Attestation",
            version: '1',
            // block.chainid
            chainId: 1,
            //address(this)
            verifyingContract: 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC
        }));
    }
    
    // External Functions

    function verifyCounterpartyRisk(CRA memory _msg, bytes calldata _sig) external {
        require(_msg.expireAt > block.timestamp, "CRA: Deadline expired");
        require(_msg.VASPAddress == _msg.originator || _msg.VASPAddress == _msg.beneficiary, "CRA: Invalid customer VASP");
        address vasp;
        _msg.VASPAddress == _msg.originator ? vasp = _msg.originator : vasp = _msg.beneficiary;
        //require(vasp == msg.sender, "CRA: Invalid sender");
        bytes32 hashedStruct = getStructHash(_msg);
        require(signatureOfHash[hashedStruct].length == 0, "CRA: Already verified by the customer VASP");    
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_sig);
        address signer_ = _verifyMessage(eip712DomainHash, hashedStruct, v, r, s);
        require(signer_ == signer, "CRA: Invalid signature");
        //require(signer_ != address(0), "ECDSA: Invalid signature");  

        signatureOfHash[hashedStruct] = _sig;
        emit CounterpartyRiskAttestation(_msg.VASPAddress, _msg.originator, _msg.beneficiary, _msg.symbol, _msg.amount);
    }

    // Setters
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "CRA: Please use a non 0 address");
        signer = _signer;
    }

    // Getters
    function getSigner() view external returns (address) {
        return signer;
    }

    function hashSignature(bytes32 _sigHash) view external returns (bytes memory) {
        return signatureOfHash[_sigHash];
    }

    function getDomainHash() view external returns (bytes32) {
        return eip712DomainHash;
    }

    // Internal Functions

    function _hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function getStructHash(CRA memory _msg) public pure returns (bytes32) {
        return keccak256(abi.encode(
            CRA_TYPEHASH,
            _msg.VASPAddress,
            _msg.originator,
            _msg.beneficiary,
            keccak256(bytes(_msg.symbol)),
            _msg.amount,
            _msg.expireAt
        ));
    }

    function _verifyMessage(bytes32 _eip712DomainHash, bytes32 _hashedStruct, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        //bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory prefix = "\x19\x01";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _eip712DomainHash, _hashedStruct));
        address signer_ = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer_;
    }

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "CRA: Invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// @title Interface CounterPartyRiskAttestation
// @notice Provides functions interface to verify off chain information about counter party risk
// @author Anibal Catalan <[email protected]>
pragma solidity ^0.8.17;

interface ICounterPartyRiskAttestation {

    struct craParams {
        uint256 expireAt;
        bytes signature;
    }

    struct CRA {
        address VASPAddress;
        address originator;
        address beneficiary;
        string symbol;
        uint256 amount;
        uint256 expireAt;
    }

    function verifyCounterpartyRisk(CRA calldata msg, bytes calldata sig) external;

    function setSigner(address signer) external;

    function getSigner() view external returns (address);

    function hashSignature(bytes32 _sigHash) view external returns (bytes calldata);

    function getDomainHash() view external returns (bytes32);

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
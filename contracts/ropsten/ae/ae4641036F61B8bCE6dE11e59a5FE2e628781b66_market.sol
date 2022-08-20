/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Signer is Context, Ownable {
    address private _signer;

    event SignerTransferred(address indexed oldSigner, address indexed newSigner);

    constructor( address signer_) {
        _setSigner(signer_);
    }

    function signer() public view virtual returns (address) {
        return _signer;
    }

    function transferSigner(address newSigner) public virtual onlyOwner {
        require(newSigner != address(0), "Signer: new signer is the zero address");
        _setSigner(newSigner);
    }

    function _setSigner(address newSigner) private {
        address oldSigner = _signer;
        _signer = newSigner;
        emit SignerTransferred(oldSigner, newSigner);
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
            return;
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

    function recover(bytes32 hash,uint8 v,bytes32 r,bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract market is Signer{

    mapping(address => uint256) public balanceOf;
    mapping(bytes32 => bool) public isHashExsit;

    constructor(address _signer) Signer(_signer){

    }

    function deposit(uint256 _amount, uint8 v, bytes32 r, bytes32 s) external returns(bool){
        require(signer() == validateOrder(_amount, v, r, s), 'INVALID Signer');
        balanceOf[msg.sender] += _amount;
        return true;
    }

    function validateOrder(uint256 _amount, uint8 v, bytes32 r, bytes32 s) public returns(address){
        bytes32 messageHash = createMessageHash(msg.sender, _amount);
        messageHash = ECDSA.toEthSignedMessageHash(messageHash);
        require(!isHashExsit[messageHash], "validateOrder : hash exist");
        isHashExsit[messageHash] = true;
        return ECDSA.recover(messageHash, v, r, s);
    }

    function createMessageHash(address _user, uint256 _amount) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                address(this),
                _user,
                _amount
            )
        );
    }
    
}
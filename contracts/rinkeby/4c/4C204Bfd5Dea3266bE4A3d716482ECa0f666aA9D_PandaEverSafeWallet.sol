/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
// By PandaEver
// Date: 07/07/2022
// Time: 11:56 WIB

pragma solidity ^0.8.13;
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
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC721 {
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
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function initialize(address, address, uint256) external;
}
interface IPEFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function allWalletsLength() external view returns (uint);

    function createWallet(address Signersadd, address user) external returns (address UserWallet);
    function FeeToken() external view returns (address);
    function WDTokenFee() external view returns (uint256);
    function WDFee() external view returns (uint256);
    function setFeeTo(address) external;
    function setFeeToken(address) external;
    function setFeeToSetter(address) external;
}


contract PandaEverSafeWallet is ReentrancyGuard {
    using ECDSA for bytes32;
    address private signers;
    address public FactoryAddress;
    uint256 public chainId = block.chainid;
    uint256 public nonces = 0;
    uint256 private selfdes = 0;
    uint256 public WalletCode;
    mapping(address => bool) whitelist;
    event send(address to, uint amount);
    event sendtoken(address to,address receivers,address sc, uint amount);
    event sendNFT(address to,address receivers,address sc, uint tokenId);
    constructor(){
        FactoryAddress = msg.sender;
    }
    receive() external payable {}

    function initialize(address Signersadresss, address users, uint256 WalletNum) external {
        require(msg.sender == FactoryAddress, 'PandaEver: FORBIDDEN'); // sufficient check
        signers = Signersadresss;
        whitelist[users] = true;
        WalletCode = WalletNum;
    }

    function isMessageValid(bytes memory _signature,uint256 nonce, uint256 time)
        private
        view
        returns (bool)
    {
        if (block.timestamp <= time){
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), signers, nonce, time, chainId)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );

        if (signers == signer) {
            return (true);
        } else {
            return (false);
        }
        }else{
            return (false);
        }
    }

    function addUser(address _newuser, bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        whitelist[_newuser] = true;
        nonces = nonces+1;
    }

    function removeUser(address _user, bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        whitelist[_user] = false;
        nonces = nonces+1;
    }

    function changesigner(address _user, bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        signers = _user;
        nonces = nonces+1;
    }

    function withdrawtoken(address smartcontract, uint256 _amount, address receiver, bytes memory sig, uint256 time) public nonReentrant {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        IPEFactory PEFactory = IPEFactory(FactoryAddress);
        if(smartcontract != PEFactory.FeeToken()){
            nonces = nonces+1;
        }else{
            if(PEFactory.FeeToken() == address(0)){
                IERC20 _token = IERC20(smartcontract);
                _token.transfer(receiver,_amount);
                nonces = nonces+1;
                emit sendtoken(address(this), receiver, smartcontract,_amount);
            }else{
                uint256 tfee = PEFactory.WDTokenFee();
                IERC20 _tokenFee = IERC20(PEFactory.FeeToken());
                _tokenFee.transfer(PEFactory.feeTo(), tfee);
                IERC20 _token = IERC20(smartcontract);
                _token.transfer(receiver,_amount);
                nonces = nonces+1;
                emit sendtoken(address(this), receiver, smartcontract,_amount);
            }
        }
    }

    function withdrawNFT(address smartcontract, uint256 tokenId, address receiver, bytes memory sig, uint256 time) public nonReentrant {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        IPEFactory PEFactory = IPEFactory(FactoryAddress);
        if(PEFactory.FeeToken() == address(0)){
             IERC721 _token = IERC721(smartcontract);
            _token.transferFrom(address(this), receiver, tokenId);
            nonces = nonces+1;
            emit sendNFT(address(this), receiver, smartcontract, tokenId);
        }else{
            uint256 tfee = PEFactory.WDTokenFee();
            IERC20 _tokenFee = IERC20(PEFactory.FeeToken());
            _tokenFee.transfer(PEFactory.feeTo(), tfee);
            IERC721 _token = IERC721(smartcontract);
            _token.transferFrom(address(this), receiver, tokenId);
            nonces = nonces+1;
            emit sendNFT(address(this), receiver, smartcontract, tokenId);
        }
    }

    function BurnToken(address smartcontract, uint256 _amount, bytes memory sig, uint256 time) public nonReentrant {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        IERC20 _token = IERC20(smartcontract);
        _token.transfer(address(0x000000000000000000000000000000000000dEaD),_amount);
        nonces = nonces+1;
        emit sendtoken(address(this), address(0x000000000000000000000000000000000000dEaD), smartcontract,_amount);
    }

    function withdraw(uint256 _amount, address receiver, bytes memory sig, uint256 time) public nonReentrant {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        IPEFactory PEFactory = IPEFactory(FactoryAddress);
        if(PEFactory.FeeToken() == address(0)){
            payable(receiver).transfer(_amount);
            nonces = nonces+1;
            emit send(address(this),_amount);
        }else{
            uint256 tfee = PEFactory.WDFee();
            IERC20 _tokenFee = IERC20(PEFactory.FeeToken());
            payable(receiver).transfer(_amount);
            nonces = nonces+1;
            emit send(address(this),_amount);
            _tokenFee.transfer(PEFactory.feeTo(), tfee);
        }
    }

    function VoteSelfdestruct(bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        nonces = nonces+1;
        selfdes = 1;
    }

    function ClearSelfdestructVote(bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        nonces = nonces+1;
        selfdes = 0;
    }

    function confirmSelfdestruct(bytes memory sig, uint256 time) public {
        require(isMessageValid(sig, nonces, time),"Expired Or Invalid Signature");
        require(selfdes == 1, "Require 1 Vote");
        require(whitelist[msg.sender], "Caller Is Not WhiteList");
        selfdestruct(payable(address(signers)));
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getTokenBalance(address smartcontract) external view returns (uint) {
        IERC20 _token = IERC20(smartcontract);
        return _token.balanceOf(address(this));
    }

    function whitelists(address user) external view returns (bool) {
       return whitelist[user];
    } 

    function signeraddress() external view returns (address) {
       return signers;
    } 
}
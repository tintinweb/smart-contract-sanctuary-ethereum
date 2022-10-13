/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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

contract ElumntNFTMarketplace is Ownable, Verification {
    address wbnbAddress;
    constructor(address _wbnb) {
        wbnbAddress = _wbnb;
    }
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces;
    struct pixulLimitWithPercentData {
        uint256 pixulLimit;
        uint256 percentForLess;
        uint256 percentForMore;
    }
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
        uint256 pixel;
        uint256 tokenId;
        address newOwner;
        address creator;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct acceptOfferBid1155Data {
        uint256 tokenId;
        uint256 pixel;
        address newOwner;
        address creator;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
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
        uint256 pixel;
        uint256 tokenId;
        address owner;
        address creator;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct buy1155Data {
        uint256 tokenId;
        uint256 pixel;
        address owner;
        address creator;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct acceptData {
        string metadata;
        uint256 pixel;
        uint256 tokenId; 
        address newOwner;
        address creator;
        address nft;
        uint256 amount;
        uint256 percent;
        uint256 royalty;
        uint256 collectionId;
        address currentOwner;
    }
    struct transferNFTData {
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
    function acceptOfferBid721(acceptOfferBid721Data memory _transferData) external payable {
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
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }
        uint256 royaltyPercent;
        if(_transferData.royalty > 0 && _transferData.creator != msg.sender) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, wbnbAddress);
        }
        
        transfer20(_transferData.newOwner, msg.sender, amountToTransfer, wbnbAddress);
        transfer721(_transferData.nft, msg.sender, _transferData.newOwner, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, royaltyPercent);
    }
    function acceptOfferBid1155(acceptOfferBid1155Data memory _transferData) external payable {
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
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }
        uint256 royaltyPercent;
        if(_transferData.royalty > 0 && _transferData.creator != msg.sender) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, wbnbAddress);
        }
        
        transfer20(_transferData.newOwner, msg.sender, amountToTransfer, wbnbAddress);
        transfer1155(_transferData.nft, msg.sender, _transferData.newOwner, _transferData.quantity, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, royaltyPercent);
    }
    function buy721(buy721Data memory _buyData) external payable {
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
        }
        uint256 royaltyPercent;
        if(_buyData.royalty > 0 && _buyData.creator != _buyData.owner) {
            royaltyPercent = calculatePercentValue(_buyData.amount, _buyData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            payable(_buyData.creator).transfer(royaltyPercent);
        }
        transfer721(_buyData.nft, _buyData.owner, msg.sender, tokenId);
        
        payable(_buyData.owner).transfer(amountToTransfer);
        emit NftTransferred(tokenId, msg.value, _buyData.owner, msg.sender, royaltyPercent);
    }
    function create721(create721Data memory _createData) external payable {
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
    function create1155(create1155Data memory _createData) external payable {
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
    function buy1155(buy1155Data memory _buyData) external payable {
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
        }

        uint256 royaltyPercent;
        if(_buyData.royalty > 0 && _buyData.creator != _buyData.owner) {
            royaltyPercent = calculatePercentValue(_buyData.amount, _buyData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            payable(_buyData.creator).transfer(royaltyPercent);
        }
        transfer1155(_buyData.nft, _buyData.owner, msg.sender, _buyData.quantity, tokenId);
        
        payable(_buyData.owner).transfer(amountToTransfer);
        emit NftTransferred(tokenId, msg.value, _buyData.owner, msg.sender, royaltyPercent);
    }
    function transferForFree721(transfer721Data memory _transferData) public {
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
    function transferForFree1155(transfer1155Data memory _transferData) public {
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
    function acceptBid(acceptData memory _transferData) external payable onlyOwner {
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
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }
        
        uint256 royaltyPercent;
        if(_transferData.royalty > 0) {
            royaltyPercent = calculatePercentValue(_transferData.amount, _transferData.royalty);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, _transferData.creator, royaltyPercent, wbnbAddress);
        }

        transfer20(_transferData.newOwner, _transferData.currentOwner, amountToTransfer, wbnbAddress);
        transfer721(_transferData.nft, _transferData.currentOwner, _transferData.newOwner, tokenId);
        emit AutoAccepted(tokenId, royaltyPercent);
    }
    function withdrawBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawWBNB() public onlyOwner {
        ERC20Token wbnb = ERC20Token(wbnbAddress);
        uint256 balance = wbnb.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        wbnb.transfer(owner(), balance);
    }
    fallback () payable external {}
    receive () payable external {}
}
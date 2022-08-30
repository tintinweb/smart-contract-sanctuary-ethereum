// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Interface.sol";
import "./ERC1155Interface.sol";
import "./ERC20Interface.sol";
import {Verification} from "./Verification.sol";

contract ElumntNFTMarketplace is Ownable, Verification {
    address wbnbAddress;
    constructor(address _wbnb) {
        wbnbAddress = _wbnb;
    }
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces;
    mapping(uint256 => uint256) public royaltiesWBNB;
    mapping(uint256 => uint256) public royaltiesBNB;
    uint256 PLATFORM_SHARE_PERCENT = 0;
    uint256 HUNDERED = 100;
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
        uint256 tokenId;
        address newOwner;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct acceptOfferBid1155Data {
        uint256 tokenId;
        address newOwner;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct buy721Data {
        string metadata;
        uint256 tokenId;
        address owner;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct buy1155Data {
        uint256 tokenId;
        address owner;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct acceptData {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address nft;
        uint256 amount;
        uint256 percent;
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
        uint256 percentValue = division.div(100);
        return percentValue;
    }

    //Views to read data from blockcahin
    function checkPlatformSharePercent() public view returns (uint256) {
        return PLATFORM_SHARE_PERCENT;
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
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }
        
        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, address(this), royaltyPercent, wbnbAddress);
            uint256 amount = royaltiesWBNB[_transferData.collectionId];
            royaltiesWBNB[_transferData.collectionId] = amount + royaltyPercent;
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
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }
        
        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, address(this), royaltyPercent, wbnbAddress);
            uint256 amount = royaltiesWBNB[_transferData.collectionId];
            royaltiesWBNB[_transferData.collectionId] = amount + royaltyPercent;
        }
        
        transfer20(_transferData.newOwner, msg.sender, amountToTransfer, wbnbAddress);
        transfer1155(_transferData.nft, msg.sender, _transferData.newOwner, tokenId, _transferData.quantity);
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
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
        }

        uint256 royaltyPercent;
        if(_buyData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _buyData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            uint256 amount = royaltiesBNB[_buyData.collectionId];
            royaltiesBNB[_buyData.collectionId] = amount + royaltyPercent;
        }

        transfer721(_buyData.nft, _buyData.owner, msg.sender, tokenId);
        
        payable(_buyData.owner).transfer(amountToTransfer);
        emit NftTransferred(tokenId, msg.value, _buyData.owner, msg.sender, royaltyPercent);
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
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
        }

        uint256 royaltyPercent;
        if(_buyData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _buyData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            uint256 amount = royaltiesBNB[_buyData.collectionId];
            royaltiesBNB[_buyData.collectionId] = amount + royaltyPercent;
        }
        transfer1155(_buyData.nft, _buyData.owner, msg.sender, tokenId, _buyData.quantity);
        
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
        transfer1155(_transferData.nft, _transferData.currentOwner, _transferData.newOwner, tokenId, _transferData.quantity);
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
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transfer20(_transferData.newOwner, address(this), platformSharePercent, wbnbAddress);
        }

        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transfer20(_transferData.newOwner, address(this), royaltyPercent, wbnbAddress);
            uint256 amount = royaltiesWBNB[_transferData.collectionId];
            royaltiesWBNB[_transferData.collectionId] = amount + royaltyPercent;
        }

        transfer20(_transferData.newOwner, _transferData.currentOwner, amountToTransfer, wbnbAddress);
        transfer721(_transferData.nft, _transferData.currentOwner, _transferData.newOwner, tokenId);
        emit AutoAccepted(tokenId, royaltyPercent);
    }
    function updatePlatformSharePercent(uint256 percent) public onlyOwner {
        PLATFORM_SHARE_PERCENT = percent;
    }
    function transferRoyalties(uint256 collection, address payout) public onlyOwner {
        uint256 wbnbShare = royaltiesWBNB[collection];
        uint256 bnbShare = royaltiesBNB[collection];
        if(wbnbShare > 0) {
            transfer20(address(this), payout, wbnbShare, wbnbAddress);
            royaltiesWBNB[collection] = 0;
        }
        if(bnbShare > 0) {
            payable(payout).transfer(bnbShare);
            royaltiesBNB[collection] = 0;
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721Token {
    function safeMint(address to, string memory uri) external returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20Token { //WBNB, ANN
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155Token {
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function mint(uint256 amount, address to) external returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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
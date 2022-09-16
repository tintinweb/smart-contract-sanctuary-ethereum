// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Interface.sol";
import "./ERC20Interface.sol";
import "./ERC1155Interface.sol";
import {Verification} from "./Verification.sol";

// This line is added for temporary use
contract MyntistNFTMarketplace is Ownable, Verification {
    address wbnbAddress;
    address myntistTokenAddress;
    constructor(address mynt, address _wbnb) {
        wbnbAddress = _wbnb;
        myntistTokenAddress = mynt;
    }
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => bool)) seenNonces;
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
        uint8 acceptType;
        string metadata;
        uint256 tokenId;
        address newOwner;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
        Royalty[] nftRoyalty;
        uint256 platformShareAmount;
        uint256 ownerShare;
    }
    struct acceptOfferBid1155Data {
        uint8 acceptType;
        string metadata;
        uint256 tokenId;
        address newOwner;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
        Royalty[] nftRoyalty;
        uint256 platformShareAmount;
        uint256 ownerShare;
    }
    struct Royalty {
        uint256 amount;
        address wallet;
    }
    struct RoyaltyResponse {
        uint256 amount;
        address wallet;
    }
    struct buy721Data {
        string metadata;
        uint256 tokenId;
        address owner;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
        Royalty[] nftRoyalty;
        uint256 ownerShare;
        uint8 currency;
    }
    struct buy1155Data {
        string metadata;
        uint256 tokenId;
        address owner;
        uint256 quantity;
        uint256 totalQuantity;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
        Royalty[] nftRoyalty;
        uint256 ownerShare;
        uint8 currency;
    }
    struct acceptData721 {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address owner;
        address nft;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        Royalty[] nftRoyalty;
        uint256 platformShareAmount;
        uint256 ownerShare;
        address currentOwner;
    }
    struct acceptData1155 {
        string metadata;
        uint256 tokenId; 
        address newOwner;
        address owner;
        address nft;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        Royalty[] nftRoyalty;
        uint256 platformShareAmount;
        uint256 ownerShare;
        address currentOwner;
        uint256 quantity;
        uint256 totalQuantity;
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
    event BidOfferAccepted(uint256 tokenId, uint256 price, address from, address to, uint8 acceptType);
    event Nft721Transferred(uint256 tokenId, uint256 price, address from, address to);
    event Nft1155Transferred(uint256 tokenId, uint256 price, address from, address to, uint256 quantity);
    event AutoAccepted(uint256 tokenId);
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
        transferRoyaltiesToken(_transferData.nftRoyalty, _transferData.payThrough, _transferData.newOwner, _transferData.platformShareAmount);
        if(_transferData.payThrough==1) {
            transferERC20ToOwner(_transferData.newOwner, msg.sender, _transferData.ownerShare, myntistTokenAddress);
        }
        else {
            transferERC20ToOwner(_transferData.newOwner, msg.sender, _transferData.ownerShare, wbnbAddress);
        }
        transfer721(_transferData.nft, msg.sender, _transferData.newOwner, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, _transferData.acceptType);
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
        transferRoyaltiesToken(_transferData.nftRoyalty, _transferData.payThrough, _transferData.newOwner, _transferData.platformShareAmount);
        if(_transferData.payThrough==1) {
            transferERC20ToOwner(_transferData.newOwner, msg.sender, _transferData.ownerShare, myntistTokenAddress);
        }
        else {
            transferERC20ToOwner(_transferData.newOwner, msg.sender, _transferData.ownerShare, wbnbAddress);
        }
        transfer1155(_transferData.nft, msg.sender, _transferData.newOwner, _transferData.quantity, tokenId);
        emit BidOfferAccepted(tokenId, msg.value, msg.sender, _transferData.newOwner, _transferData.acceptType);
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
        transferRoyalties(_buyData.nftRoyalty);
        transfer721(_buyData.nft, _buyData.owner, msg.sender, tokenId);
        
        if(_buyData.currency==1) {
            payable(_buyData.owner).transfer(_buyData.ownerShare);
        }
        else if(_buyData.currency==2) {
            transferERC20ToOwner(msg.sender, _buyData.owner, _buyData.ownerShare, myntistTokenAddress);
        }
        emit Nft721Transferred(tokenId, msg.value, _buyData.owner, msg.sender);
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
        transferRoyalties(_buyData.nftRoyalty);
        transfer1155(_buyData.nft, _buyData.owner, msg.sender, _buyData.quantity, tokenId);

        if(_buyData.currency==1) {
            payable(_buyData.owner).transfer(_buyData.ownerShare);
        }
        else if(_buyData.currency==2) {
            transferERC20ToOwner(msg.sender, _buyData.owner, _buyData.ownerShare, myntistTokenAddress);
        }
        emit Nft1155Transferred(tokenId, msg.value, _buyData.owner, msg.sender, _buyData.quantity);
    }
    function acceptBid721(acceptData721 memory _transferData) external payable onlyOwner {
        uint256 tokenId = _transferData.tokenId;
        if(_transferData.tokenId == 0) {
            mint721Data memory mintData = mint721Data(
                _transferData.metadata,
                payable(_transferData.owner),
                _transferData.nft
            );
            tokenId = mint721(mintData);
        }
        transferRoyaltiesToken(_transferData.nftRoyalty, _transferData.payThrough, _transferData.newOwner, _transferData.platformShareAmount);
        if(_transferData.payThrough==1) {
            transferERC20ToOwner(_transferData.newOwner, _transferData.owner, _transferData.ownerShare, myntistTokenAddress);
        }
        else {
            transferERC20ToOwner(_transferData.newOwner, _transferData.owner, _transferData.ownerShare, wbnbAddress);
        }
        transfer721(_transferData.nft, _transferData.owner, _transferData.newOwner, tokenId);
        emit AutoAccepted(tokenId);
    }
    function acceptBid1155(acceptData1155 memory _transferData) external payable onlyOwner {
        uint256 tokenId = _transferData.tokenId;
        if(_transferData.tokenId == 0) {
            mint1155Data memory mintData = mint1155Data(
                payable(_transferData.owner),
                _transferData.nft,
                _transferData.totalQuantity
            );
            tokenId = mint1155(mintData);
        }
        transferRoyaltiesToken(_transferData.nftRoyalty, _transferData.payThrough, _transferData.newOwner, _transferData.platformShareAmount);
        if(_transferData.payThrough==1) {
            transferERC20ToOwner(_transferData.newOwner, _transferData.owner, _transferData.ownerShare, myntistTokenAddress);
        }
        else {
            transferERC20ToOwner(_transferData.newOwner, _transferData.owner, _transferData.ownerShare, wbnbAddress);
        }
        transfer721(_transferData.nft, _transferData.owner, _transferData.newOwner, tokenId);
        emit AutoAccepted(tokenId);
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
    function transfer721(address cAddress, address from, address to, uint256 token) internal {
        IERC721Token nftToken = IERC721Token(cAddress);
        nftToken.safeTransferFrom(from, to, token);
    }
    function transfer1155(address cAddress, address from, address to, uint256 amount, uint256 token) internal {
        IERC1155Token nftToken = IERC1155Token(cAddress);
        nftToken.safeTransferFrom(from, to, token, amount, "");
    }
    fallback () payable external {}
    receive () payable external {}
    function transferRoyalties(Royalty[] memory nftRoyalty) internal {
        for(uint x = 0; x < nftRoyalty.length; x++) {
            Royalty memory royalty = nftRoyalty[x];
            payable(royalty.wallet).transfer(royalty.amount);
        }
    }
    function transferRoyaltiesToken(Royalty[] memory nftRoyalty, uint256 paymentType, address buyer, uint256 platformShareAmount) internal {
        for(uint x = 0; x < nftRoyalty.length; x++) {
            Royalty memory royalty = nftRoyalty[x];
            if(paymentType==1) {
                transferERC20ToOwner(buyer, royalty.wallet, royalty.amount, myntistTokenAddress);
            }
            else {
                transferERC20ToOwner(buyer, royalty.wallet, royalty.amount, wbnbAddress);
            }
        }
        if(paymentType==1) {
            transferERC20ToOwner(buyer, address(this), platformShareAmount, myntistTokenAddress);
        }
        else {
            transferERC20ToOwner(buyer, address(this), platformShareAmount, wbnbAddress);
        }
    }
    function transferERC20ToOwner(address from, address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transferFrom(from, to, amount);
    }
    function withdrawBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawMYNT() public onlyOwner {
        IERC20Token annexToken = IERC20Token(myntistTokenAddress);
        uint256 balance = annexToken.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        annexToken.transfer(owner(), balance);
    }
    function withdrawWBNB() public onlyOwner {
        IERC20Token wbnb = IERC20Token(wbnbAddress);
        uint256 balance = wbnb.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        wbnb.transfer(owner(), balance);
    }
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

interface IERC20Token { //WBNB, ANN
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
//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GiveawayTruedapp is Ownable {
    struct Lot {
        address collection;
        uint128 id;
        uint128 maxParticipants;
        uint256 endDate;
        uint256 minBalance;
        uint64 stateNumber;
        uint64 lotCount;
        uint128 arrayPosInMeta;
        address exactColletion;
        address winner;
        string imageURL;
        string twitterInfo;
        string discordInfo;
        string password;
        bool closed;
    }

    struct InfoLot {
        address account;
        uint256 lotId;
    }

    struct MyGives {
        uint256 id;
        uint256 isClosed;
        uint256 IdFromAll;
        string myMetaData;
        uint128 maxParticipants;
        uint256 endTime;
    }

    uint64 private _lotsCount;
    uint64 private _maxAmountPart;
    string[] private _meta;
    address private _signer;
    string private _secret;

    mapping(address => uint256) private _countLotsByAddress;
    mapping(address => uint256[]) private _allLotIdByAddress;
    mapping(address => mapping(uint256 => Lot)) private _lotByLotOwnerAndLotId;
    mapping(address => mapping(uint256 => bool)) private _alreadyHasNft;
    mapping(uint256 => address) private _ownerLotByLotId;

    function getMessageHash(address user, uint256 timestamp) public view returns (bytes32) {
        return keccak256(abi.encodePacked(user, timestamp, _secret));
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function lotsCount() external view returns (uint256) {
        return _lotsCount;
    }

    function getAllMeta() external view returns (string[] memory allMeta) {
        allMeta = new string[](_meta.length);
        for (uint256 i = 0; i < _meta.length; i++) {
            allMeta[i] = _meta[i];
        }
    }

    function signer() external view returns (address) {
        return _signer;
    }

    function secret() external view returns (string memory) {
        return _secret;
    }

    function maxAmountPart() external view returns (uint256) {
        return _maxAmountPart;
    }

    function countsLotsByAddress(address account) external view returns (uint256) {
        return _countLotsByAddress[account];
    }

    function allLotIdByAddress(address account) external view returns (uint256[] memory) {
        return _allLotIdByAddress[account];
    }

    function lotByLotOwnerAndLotId(address account, uint256 lotId) external view returns (Lot memory) {
        uint256 idUser = _allLotIdByAddress[account][lotId - 1];
        return _lotByLotOwnerAndLotId[account][idUser];
    }

    function alreadyHasNft(address collection, uint256 id) external view returns (bool) {
        return _alreadyHasNft[collection][id];
    }

    function infoLotByLotId(uint256 id) external view returns (address) {
        return _ownerLotByLotId[id];
    }

    function myGiveaways(address user, uint256 offset, uint256 limit) external view returns (MyGives[] memory givesData) {
        uint256 countLot = _allLotIdByAddress[user].length;
        if (countLot == 0) return new MyGives[](0);
        if (offset > countLot) return new MyGives[](0);
        uint256 to = offset + limit;
        if (countLot < to) to = countLot;
        givesData = new MyGives[](to - offset);
        uint256[] memory allLotId = _allLotIdByAddress[user];
        MyGives[] memory allGives = new MyGives[](countLot);
        for (uint i = 0; i < allLotId.length; i++) {
            Lot memory lot = _lotByLotOwnerAndLotId[user][allLotId[i]];
            uint256 isClosed = lot.closed == true ? 2 : getTimestamp() > lot.endDate ? 1 : 0;
            allGives[i] = MyGives(i + 1, isClosed, lot.lotCount, _meta[lot.arrayPosInMeta], lot.maxParticipants, lot.endDate);
        }
        for (uint i = 0; i < givesData.length; i++) {
            givesData[i] = allGives[offset + i];
        }
    }

    constructor(uint64 maxAmountPart_, string memory secret_) {
        _maxAmountPart = maxAmountPart_;
        _signer = msg.sender;
        _secret = secret_;
    }

    function changeMaxPart(uint64 maxAmountPart_) external onlyOwner {
        _maxAmountPart = maxAmountPart_;
    }

    function changeSigner(address singer_) external onlyOwner {
        _signer = singer_;
    }

    function makeLottery(
        address collection,
        uint128 id,
        uint128 maxParticipants,
        uint256 endDate,
        uint64 stateNumber,
        uint256 minBalance,
        address exactColletion,
        string memory imageURL,
        string memory twitterInfo,
        string memory discordInfo,
        string memory password
    ) external returns (bool) {
        require(collection != address(0), "Collection eq address zero");
        IERC721 nftToken = IERC721(collection);
        address caller = msg.sender;
        require(nftToken.ownerOf(id) == caller, "Not owner of the NFT");
        if (stateNumber == 1) {
            require(minBalance > 0, "MinBalance lt eq zero");
        } else if (stateNumber == 2) {
            require(exactColletion != address(0), "ExactColletion eq zero address");
        } else if (stateNumber == 3) {
            require(minBalance > 0, "MinBalance lt eq zero");
            require(exactColletion != address(0), "ExactColletion eq zero address");
        }
        require(!_alreadyHasNft[collection][id], "Already participating it lottery");
        require(maxParticipants > 1, "MaxParticipants lt one");
        require(endDate > getTimestamp(), "EndDate lt time now");
        _lotsCount++;
        _countLotsByAddress[caller] += 1;
        _allLotIdByAddress[caller].push(_lotsCount);
        _ownerLotByLotId[_lotsCount] = caller;
        Lot storage lot = _lotByLotOwnerAndLotId[caller][_lotsCount];
        lot.collection = collection;
        lot.id = id;
        lot.maxParticipants = maxParticipants;
        lot.endDate = endDate;
        lot.stateNumber = stateNumber;
        lot.minBalance = minBalance;
        lot.exactColletion = exactColletion;
        lot.lotCount = _lotsCount;
        lot.imageURL = imageURL;
        lot.arrayPosInMeta = uint128(_meta.length);
        lot.twitterInfo = twitterInfo;
        lot.discordInfo = discordInfo;
        lot.password = password;
        _alreadyHasNft[collection][id] = true;
        _meta.push(imageURL);
        return true;
    }

    function closeLottery(uint256 id, address winner, uint256 inputTime, bytes memory _sig) external returns (bool) {
        address caller = msg.sender;
        uint256 idUser = _allLotIdByAddress[caller][id - 1];
        require(_ownerLotByLotId[idUser] == caller, "You dont have a lot");
        Lot storage lot = _lotByLotOwnerAndLotId[caller][idUser];
        require(lot.closed == false, "Already done");

        bytes32 message = getMessageHash(caller, inputTime);
        require(verify(message, _sig), "It's not a signer");

        lot.winner = winner;

        IERC721 nftToken = IERC721(lot.collection);
        nftToken.transferFrom(caller, winner, lot.id);
        lot.closed = true;
        _alreadyHasNft[lot.collection][lot.id] = false;
        return true;
    }

    function verify(bytes32 message, bytes memory _sig) internal view returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);
        return (recover(ethSignedMessageHash, _sig) == _signer);
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function _split(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature name");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
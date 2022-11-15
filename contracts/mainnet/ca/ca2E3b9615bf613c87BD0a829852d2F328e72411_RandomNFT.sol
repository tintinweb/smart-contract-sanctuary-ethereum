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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNFT is Ownable {
    mapping(address => mapping(uint256 => lot)) adrToLotIdToInfo;
    mapping(address => uint256) adrToLotAmount;
    address[] lotOwners;
    mapping(address => mapping(uint256 => bool)) colAdrToId;

    mapping(uint256 => infoLot) idToAdrToLotId;
    uint64 public AllLotsAmount;
    string[] meta;

    struct infoLot {
        address adr;
        uint256 lotId;
    }

    address private signer;
    string private secret;

    uint256 maxAmountPart;

    struct lot {
        address collection;
        uint128 id;
        uint128 maxPart;
        uint256 endDate;
        uint256 stateNumber;
        uint256 minBal;
        address exactCol;
        address winner;
        uint256 winnerId;
        bool done;
        bool closed;
        uint64 AllLotId;
        string follow;
        uint64 age;
        uint64 followers;
        uint128 postId;
        string str;
        uint256 arrayPos;
    }

    constructor(string memory secret_) {
        maxAmountPart = 20;
        signer = msg.sender;
        secret = secret_;
    }

    function changeMaxPart(uint256 newMax) external onlyOwner {
        maxAmountPart = newMax;
    }

    function changeSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function makeLotery(
        address collection,
        uint128 id,
        uint128 maxPart,
        uint256 endDate,
        uint256 stateNumber,
        uint256 minBal,
        address exactCol,
        string memory follow,
        uint64 age,
        uint64 followers,
        uint128 postId,
        string memory str
    ) external {
        require(
            !colAdrToId[collection][id],
            "Already participating it lottery"
        );
        IERC721 mainToken = IERC721(collection);
        require(mainToken.ownerOf(id) == msg.sender, "not owner of the NFT");
        if (stateNumber == 2 || stateNumber == 3) {
            require(exactCol != address(0), "col == 0");
        }
        AllLotsAmount++;

        adrToLotAmount[msg.sender]++;
        idToAdrToLotId[AllLotsAmount] = infoLot(
            msg.sender,
            adrToLotAmount[msg.sender]
        );

        adrToLotIdToInfo[msg.sender][adrToLotAmount[msg.sender]] = lot(
            collection,
            id,
            maxPart,
            endDate,
            stateNumber,
            minBal,
            exactCol,
            address(0),
            0,
            false,
            false,
            AllLotsAmount,
            follow,
            age,
            followers,
            postId,
            str,
            meta.length
        );

        lotOwners.push(msg.sender);
        colAdrToId[collection][id] = true;
        meta.push(str);
    }

    function checkTimeNow() external view returns (uint256) {
        return block.timestamp;
    }

    function isInArray(address[] memory array, address adr)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function getRandomNumber(
        address adr,
        uint64 lotId,
        uint64 maxCount,
        uint64 timestamp,
        bytes memory _sig
    ) external returns (uint256) {
        bytes32 message = getMessageHash(msg.sender, timestamp);
        require(verify(message, _sig), "It's not a signer");
        require(
            block.timestamp > adrToLotIdToInfo[adr][lotId].endDate,
            "Time is not over"
        );
        uint256 ran = random(maxCount) + 1;
        adrToLotIdToInfo[adr][lotId].winnerId = ran;
        return ran;
    }

    function closeLottery(
        address adr,
        uint64 lotId,
        address winner,
        uint64 timestamp,
        bytes memory _sig
    ) external {
        require(
            block.timestamp >= adrToLotIdToInfo[adr][lotId].endDate,
            "Time is not over yet"
        );
        require(adr == msg.sender, "you are not owner of the lot");
        require(adrToLotIdToInfo[adr][lotId].done == false, "Already done");
        require(isInArray(lotOwners, msg.sender), "you dont have a lot");

        bytes32 message = getMessageHash(msg.sender, timestamp);
        require(verify(message, _sig), "It's not a signer");

        adrToLotIdToInfo[adr][lotId].closed = true;
        adrToLotIdToInfo[adr][lotId].winner = winner;

        IERC721 mainToken = IERC721(adrToLotIdToInfo[adr][lotId].collection);
        mainToken.transferFrom(adr, winner, adrToLotIdToInfo[adr][lotId].id);
        adrToLotIdToInfo[adr][lotId].done = true;
        colAdrToId[adrToLotIdToInfo[adr][lotId].collection][
            adrToLotIdToInfo[adr][lotId].id
        ] = false;
    }

    function random(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }

    struct mygives {
        uint64 id;
        uint64 isClosed;
        uint64 IdFromAll;
        string myMetaData;
        uint128 maxParticipants;
    }

    mapping(address => mygives[]) myLotsInfoStruct;

    function myGiveaways(address user, uint256 startPoint)
        external
        view
        returns (mygives[] memory myInfo)
    {
        uint64[] memory IdArray = new uint64[](adrToLotAmount[user]);
        uint64[] memory array = new uint64[](adrToLotAmount[user]);
        uint64[] memory IdFromAllArray = new uint64[](adrToLotAmount[user]);
        string[] memory myMeta = new string[](adrToLotAmount[user]);
        uint128[] memory maxPart = new uint128[](adrToLotAmount[user]);
        for (uint16 i = 1; i <= adrToLotAmount[user]; i++) {
            if (adrToLotIdToInfo[user][i].done) {
                array[i - 1] = 2;
            } else {
                if (block.timestamp > adrToLotIdToInfo[user][i].endDate) {
                    array[i - 1] = 1;
                } else {
                    array[i - 1] = 0;
                }
            }
            IdFromAllArray[i - 1] = adrToLotIdToInfo[user][i].AllLotId;
            IdArray[i - 1] = i;
            myMeta[i - 1] = meta[adrToLotIdToInfo[user][i].arrayPos];
            maxPart[i - 1] = adrToLotIdToInfo[user][i].maxPart;
        }

        uint256 amount = 10;

        require(startPoint % 10 == 0, "startPoint must be 0, 8, 16 ... etc.");
        require(startPoint < uint256(IdArray.length), "startPoint too big");

        uint256 count;
        bool a;

        if (IdArray.length < startPoint + amount) {
            uint256 newStartPoint = startPoint - (startPoint % 8);

            mygives[] memory myStruct = new mygives[](
                IdArray.length - newStartPoint
            );

            for (uint256 i = newStartPoint; i < IdArray.length; i++) {
                myStruct[count].id = IdArray[i];
                myStruct[count].isClosed = array[i];
                myStruct[count].IdFromAll = IdFromAllArray[i];
                myStruct[count].myMetaData = myMeta[i];
                myStruct[count].maxParticipants = maxPart[i];
                count++;
            }
            return (myStruct);
        } else {
            mygives[] memory myStruct = new mygives[](amount);
            for (uint256 i = startPoint; i < startPoint + amount; i++) {
                myStruct[count].id = IdArray[i];
                myStruct[count].isClosed = array[i];
                myStruct[count].IdFromAll = IdFromAllArray[i];
                myStruct[count].myMetaData = myMeta[i];
                myStruct[count].maxParticipants = maxPart[i];

                count++;
                a = true;
            }

            return (myStruct);
        }
    }

    function checkAllIdLot(uint256 id) external view returns (infoLot memory) {
        return idToAdrToLotId[id];
    }

    function lotInfo(address adr, uint256 lotId)
        external
        view
        returns (lot memory)
    {
        return adrToLotIdToInfo[adr][lotId];
    }

    function checkLotOwners() external view returns (address[] memory) {
        return lotOwners;
    }

    function checkOwnerLotAmount(address adr) external view returns (uint256) {
        return adrToLotAmount[adr];
    }

    function checkMaxPart() external view returns (uint256) {
        return maxAmountPart;
    }

    function verify(bytes32 message, bytes memory _sig)
        public
        view
        returns (
            bool 
        )
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        return (recover(ethSignedMessageHash, _sig) == signer);
    }

    function getMessageHash(address user, uint256 timestamp)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, timestamp, secret));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature name");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function checkSecret() external view onlyOwner returns (string memory) {
        return secret;
    }

    function checkMyState(
        address participant,
        address lotOwner,
        uint32 lotId
    ) external view returns (uint256) {
        if (participant == lotOwner) {
            return 4;
        } else {
            if (block.timestamp > adrToLotIdToInfo[lotOwner][lotId].endDate) {
                if (adrToLotIdToInfo[lotOwner][lotId].winner == participant) {
                    if (adrToLotIdToInfo[lotOwner][lotId].done) {
                        return 4;
                    } else {
                        return 4;
                    }
                } else {
                    if (adrToLotIdToInfo[lotOwner][lotId].done) {
                        return 4;
                    } else {
                        return 4;
                    }
                }
            } else {
                return 1;
            }
        }
    }

    function isInArrayAdr(address[] memory array, address element)
        internal
        pure
        returns (bool)
    {
        for (uint32 i; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }
}
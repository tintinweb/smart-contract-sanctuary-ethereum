// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../storage/IStorage.sol";
import "../tokens/ERC20/IRoomerToken.sol";
import "../tokens/ERC721/IRoomNFT.sol";
import "../tokens/ERC1155/IAccessToken.sol";
import "./interface/IArtroomManager.sol";

contract ArtroomManager is IArtroomManager, ReentrancyGuard {
    IStorage public storageContract;
    IRoomNFT public roomNFT;
    IRoomerToken public roomerToken;
    IAccessToken public accessToken;
    uint256 public roomCreationFee;

    constructor(
        address _storageContract,
        address _roomNFT,
        address _roomerToken,
        address _accessToken,
        uint256 _roomCreationFee
    ) {
        storageContract = IStorage(_storageContract);
        roomNFT = IRoomNFT(_roomNFT);
        roomerToken = IRoomerToken(_roomerToken);
        accessToken = IAccessToken(_accessToken);
        roomCreationFee = _roomCreationFee;
    }

    modifier onlyOwner() {
        require(storageContract.owners(msg.sender), "021");
        _;
    }

    modifier onlyCurator(uint256 room_id) {
        require(
            msg.sender == storageContract.rooms(room_id).curator_address,
            "003"
        );
        _;
    }

    modifier onlyArtroomNFT {
        require(msg.sender == address(roomNFT), "031");
        _;
    }

    function _transferRoomer(address _from, address _to, uint256 _amount) internal {
        require(
            roomerToken.transferFrom(_from, _to, _amount),
            "039"
        );
    }

    function createArtroom(RoomObject memory item) external {
        if (storageContract.haveRoomsCreated(msg.sender)) {
            roomerToken.burnFrom(msg.sender, roomCreationFee);
        } else {
            storageContract.setRoomCreated(msg.sender);
        }
        uint256 new_id = storageContract.roomsLength(); 
        storageContract.newArtroom(
            IStorage.Room(
                new_id,
                item.startTime,
                item.endTime,
                msg.sender,
                item.roomOwnerPercentage,
                item.roomerPercentage,
                item.artworkOwnerPercentage,
                item.curatorAddress,
                item.curatorPercentage,
                item.roomerFee,
                0,
                0,
                false,
                false
            )
        );
        storageContract.newArtworkCountRegistry(new_id, 38);
        roomNFT.mint(msg.sender, new_id, item.uri);
        if (item.entranceFee > 0) storageContract.setPrivateRoom(new_id, item.entranceFee);
        emit roomCreated(
            RoomCreatedObject(
                new_id,
                item.startTime,
                item.endTime,
                item.roomName,
                msg.sender,
                item.curatorAddress,
                item.roomOwnerPercentage,
                item.roomerPercentage,
                item.artworkOwnerPercentage,
                item.curatorPercentage,
                item.roomerFee,
                item.entranceFee,
                item.description,
                item.uri,
                item.location
            )
        );
    }

    function approveRoomAuction(uint256 _room_id) external onlyCurator(_room_id) {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(!_room.auction_approved, "021");
        _room.auction_approved = true;
        storageContract.updateArtroom(_room_id, _room);
        emit auctionApproved(_room_id);
    }

    function buyAccess(uint256 _room_id) external {
        uint256 _entryFee = storageContract.privateRooms(_room_id); 
        require(_entryFee > 0, "037");
        require(roomerToken.balanceOf(msg.sender) >= _entryFee, "038");
        uint256 _halfFee = _entryFee / 2;
        _transferRoomer(msg.sender, storageContract.rooms(_room_id).owner_of, _halfFee);
        _transferRoomer(msg.sender, storageContract.rooms(_room_id).curator_address, _entryFee - _halfFee);
        accessToken.mintAccess(msg.sender, _room_id);
    }

    function updateCurator(uint256 _room_id, address _newCurator) external {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(msg.sender == _room.owner_of, "035");
        _room.curator_address = _newCurator;
        storageContract.updateArtroom(_room_id, _room);
        emit roomCuratorUpdated(_room_id, _newCurator);
    }

    function updateRoomOwner(uint256 _room_id, address _newOwner) external override onlyArtroomNFT {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        _room.owner_of = _newOwner;
        storageContract.updateArtroom(_room_id, _room);
        emit roomOwnerUpdated(_room_id, _newOwner);
    }

    function putRoomOnSale(uint256 _room_id, uint256 _price) external {
        require(_price != 0, "036");
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(msg.sender == _room.owner_of, "032");
        require(!_room.on_sale, "016");
        _room.on_sale = true;
        _room.price = _price;
        storageContract.updateArtroom(_room_id, _room);
        emit roomPutOnSale(_room_id, _price);
    }

    function buyRoom(uint256 _room_id) external payable nonReentrant {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        address old_owner = _room.owner_of;
        require(msg.sender != old_owner, "033");
        require(msg.value >= _room.price, "034");
        _room.price = 0;
        _room.on_sale = false;
        storageContract.updateArtroom(_room_id, _room);
        payable(old_owner).transfer(msg.value);
        roomNFT.safeTransferFrom(old_owner, msg.sender, _room_id);
        emit roomSold(_room_id, msg.value, old_owner, msg.sender);
    }

    function updateRoomCreationFee(uint256 _newRoomCreationFee) external onlyOwner {
        roomCreationFee = _newRoomCreationFee;
    }

    function setTokens(
        address _roomNFT,
        address _roomerToken,
        address _accessToken
    ) external onlyOwner {
        roomNFT = IRoomNFT(_roomNFT);
        roomerToken = IRoomerToken(_roomerToken);
        accessToken = IAccessToken(_accessToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArtroomManager {
    struct RoomObject {
        uint128 startTime;
        uint128 endTime;
        string roomName;
        address curatorAddress;
        uint16 roomOwnerPercentage;
        uint16 roomerPercentage;
        uint16 artworkOwnerPercentage;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 entranceFee;
        string description;
        string uri;
        string location;
    }

    struct RoomCreatedObject {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        string roomName;
        address owner_of;
        address curatorAddress;
        uint16 roomOwnerPercentage;
        uint16 roomerPercentage;
        uint16 artworkOwnerPercentage;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 entranceFee;
        string description;
        string uri;
        string location;
    }

    function updateRoomOwner(uint256 _room_id, address _newOwner) external;

    event roomCreated(RoomCreatedObject room);
    event roomOwnerUpdated(uint256 room_id, address new_owner);
    event roomCuratorUpdated(uint256 room_id, address new_curator);
    
    event auctionApproved(uint256 room_id);

    event roomPutOnSale(uint256 room_id, uint256 price);
    event roomSold(
        uint256 room_id,
        uint256 price,
        address old_owner,
        address new_owner
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessToken {
    function mintAccess(
        address _to,
        uint256 _room_id
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoomNFT {
    function mint(
        address _to, 
        uint256 _uid, 
        string memory _uri
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoomerToken {
    function burnFrom(address account, uint256 amount) external;
    function approve(address operator, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStorage {
    struct Room {
        uint256 uid;
        uint128 start_time;
        uint128 end_time;
        address owner_of;
        uint16 room_owner_percentage;
        uint16 artist_percentage;
        uint16 artwork_owner_percentage;
        address curator_address;
        uint16 curator_percentage;
        uint256 roomer_fee;
        uint256 price;
        uint128 tokens_approved;
        bool on_sale;
        bool auction_approved;
    }

    struct Token {
        uint256 uid;
        address token_address;
        address owner_of;
        uint256 token_id;
        uint256 room_id;
        uint256 price;
        uint256 amount;
        uint256 highest_bid;
        address highest_bidder;
        uint128 start_time;
        uint128 end_time;
        bool approved;
        bool resolved;
        bool is_auction;
    }
    
    struct Offer {
        address token_address;
        uint256 token_id;
        uint256 price;
        uint256 amount;
        address bidder;
        bool approved;
        bool resolved;
    }

    function owners(address _user) external view returns (bool);
    function getArtists(uint256 _uid) external view returns (address[] memory);
    function getArtworksOwnerAmount(uint256 _uid) external view returns (uint16[] memory);

    function rooms(uint256 _uid) external view returns (Room memory);
    function tokens(uint256 _uid) external view returns (Token memory);
    function offers(uint256 _uid) external view returns (Offer memory);
    function artists(uint256 _uid) external view returns (address[] memory);
    function artworksOwnerAmt(uint256 _uid) external view returns (uint16[] memory);

    function privateRooms(uint256 _uid) external view returns (uint256);
    function haveRoomsCreated(address _creator) external view returns (bool);
    function tokensOnSale(uint256 _uid) external view returns (uint256);
    function feesAvailable(uint256 _uid) external view returns (uint256);
    function tokenSubmitTime(uint256 _uid) external view returns (uint256);
    
    function updateArtroom(uint256 _uid, Room memory _updatedRoom) external;
    function updateToken(uint256 _uid, Token memory _updatedToken) external;
    function updateOffer(uint256 _uid, Offer memory _updatedOffer) external;
    
    function newArtroom(Room memory _newRoom) external;
    function newToken(Token memory _newToken) external;
    function newOffer(Offer memory _newOffer) external;
    function newArtworkCountRegistry(uint256 _uid, uint256 _size) external;

    function setRoomCreated(address _creator) external;
    function setPrivateRoom(uint256 _uid, uint256 _entranceFee) external;
    function setTokensOnSale(uint256 _uid, uint256 _amount) external;
    function setFeesAvailable(uint256 _uid, uint256 _amount) external;
    function setArtistsById(uint256 _uid, uint16 _index, address _artist) external;
    function setArtworksOwnerAmountById(uint256 _uid, uint16 _index, uint16 _amount) external;
    function setTokenSubmitTime(uint256 _uid, uint256 _timestamp) external;

    function roomsLength() external view returns (uint256);
    function tokensLength() external view returns (uint256);
    function offersLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
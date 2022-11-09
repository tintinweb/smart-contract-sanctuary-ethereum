/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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


////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IRoyaltyNFT {
    function getCreator(uint256 token_id) external returns (address);
    function getRoyaltyInfo(uint256 token_id) external view returns (address, uint256, bool);
    function updateFirstSale(uint256 token_id) external;
}

          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IAccessToken {
    function mintAccess(
        address _to,
        uint256 _room_id
    ) external;
}

            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IERC1155Min {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IERC721Min {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IRoomNFT {
    function mint(
        address _to, 
        uint256 _uid, 
        string memory _uri
    ) external;
}


////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IRoomerToken {
    function burnFrom(address account, uint256 amount) external;
    function approve(address operator, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IRoomContract {
    struct Offer {
        address token_address;
        uint256 token_id;
        uint256 price;
        uint256 amount;
        address bidder;
        bool approved;
        bool resolved;
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

    struct TokenObject {
        address token_address;
        uint256 token_id;
        uint256 room_id;
        uint256 price;
        uint256 amount;
        uint128 start_time;
        uint128 end_time;
        bool is_auction;
        bool is_physical;
        address owner;
    }

    struct Room {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        address owner_of;
        uint16 roomOwnerPercentage;
        uint16 artistPercentage;
        uint16 artworkOwnerPercentage;
        address[38] artists;
        uint8[38] artworks_owner_amt;
        address curatorAddress;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 price;
        bool on_sale;
        uint128 tokensApproved;
        bool auction_approved;
    }

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

    struct FeeRecipient {
        address recipient;
        uint16 percentage;
    }

    event auctionApproved(uint256 room_id);
    event bidAdded(uint256 auctId, uint256 highest_bid, address highest_bidder);
    event auctionFinalized(uint256 auctId, bool approve);

    event roomCreated(RoomCreatedObject room);

    event tokenProposed(TokenObject tokenInfo, uint256 uid);

    event tokenSold(
        uint256 uid,
        address old_owner,
        address new_owner,
        uint256 amount,
        uint256 total_price
    );

    event tokenApproved(bool isAuction, uint256 uid);
    event tokenRejected(bool isAuction, uint256 uid);
    event roomerRoyaltiesPayed(uint256 room_id, uint256 total_value);
    
    event proposalCancelled(uint256 uid);
    event saleCancelled(uint256 uid, address curator);
    
    event roomOwnerUpdated(uint256 room_id, address new_owner);
    event roomCuratorUpdated(uint256 room_id, address new_curator);

    event offerMade(address token_address, uint256 token_id, uint256 offer_id, uint256 price, uint256 amount, address bidder);
    event offerCancelled(uint256 offer_id);
    event offerResolved(uint256 offer_id, bool approved, address from);
}



pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


pragma solidity ^0.8.0;

contract Artroom is IRoomContract, ReentrancyGuard, Ownable {
    Room[] public rooms;
    Token[] public tokens;
    Offer[] public offers;

    mapping(uint256 => uint256) public feesAvailable;
    mapping(address => bool) public haveRoomsCreated;
    mapping(uint256 => uint256) public privateRooms;
    mapping(uint256 => uint256) public tokensOnSale;
    
    address public singleTokenAddress;
    address public multipleTokenAddress;
    address public roomNFTAddress;
    address public roomerToken;
    address public accessToken;
    uint256 public roomerTokenFee;
    uint256 public platformFee;
    FeeRecipient[] public platformFeeRecipients;

    constructor (
        address _roomNFTAddress,
        address _singleTokenAddress,
        address _multipleTokenAddress,
        address _roomerToken,
        address _accessToken,
        uint256 _roomerTokenFee
    ) {
        roomNFTAddress = _roomNFTAddress;
        singleTokenAddress = _singleTokenAddress;
        multipleTokenAddress = _multipleTokenAddress;
        roomerToken = _roomerToken;
        accessToken = _accessToken;
        roomerTokenFee = _roomerTokenFee;
    }
    
    modifier tokenOwnerOrFactory(address token_address, uint256 token_id, uint256 amount) {
        if (msg.sender != singleTokenAddress && msg.sender != multipleTokenAddress) {   
            require(
                amount == 0 ? IERC721Min(token_address).ownerOf(token_id) == msg.sender :
                    IERC1155Min(token_address).balanceOf(msg.sender, token_id) >= amount,
                "005"
            );
        }
        _;
    }

    modifier onlyCurator(uint256 room_id) {
        require(
            msg.sender == rooms[room_id].curatorAddress,
            "003"
        );
        _;
    }

    modifier validateDate(uint128 startDate, uint128 endDate) {
        if (startDate != 0) {
            require(
                block.timestamp > startDate && block.timestamp < endDate,
                "004"
            );
        }
        _;
    }

    modifier approvedToken(bool approved) {
        require(approved, "006");
        _;
    }

    modifier onlyTokenOwner(address owner_of) {
        require(owner_of == msg.sender, "002");
        _;
    } 

    modifier notTokenOwner(address owner_of) {
        require(owner_of != msg.sender, "007");
        _;
    }

    function _checkAccess(address _user, uint256 _room_id) internal view {
        address _curator = rooms[_room_id].curatorAddress;
        address _owner = rooms[_room_id].owner_of;
        if (privateRooms[_room_id] > 0 && _user != _curator && _user != _owner) {
            require(IERC1155Min(accessToken).balanceOf(_user, _room_id) >= 1, "018");
        }
    }

    function _transferRoomer(address _from, address _to, uint256 _amount) internal {
        require(
            IRoomerToken(roomerToken).transferFrom(_from, _to, _amount),
            "039"
        );
    }

    function _transferTokens(
        address token_address,
        uint256 token_id,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            IERC721Min(token_address).safeTransferFrom(from, to, token_id);
        } else {
            IERC1155Min(token_address).safeTransferFrom(from, to, token_id, amount, "");
        }
    }

    function _getRoyaltyInfo(
        address _token_address,
        uint256 _token_id
    ) internal view returns (
        address _creator, 
        uint256 _royalty, 
        bool _first_sale
    ) {
        try IRoyaltyNFT(_token_address).getRoyaltyInfo(_token_id) returns (
            address creator, 
            uint256 royalty, 
            bool first_sale
        ) {
            require(royalty <= 100, "009");
            return (creator, royalty, first_sale);
        } catch {
            return (address(0), 0, false);
        }
    }

    function _updateFirstSale(
        address _token_address,
        uint256 _token_id
    ) internal returns (bool success) {
        try IRoyaltyNFT(_token_address).updateFirstSale(_token_id) {
            return true;
        } catch {
            return false;
        } 
    }

    function _distributeFees(
        uint256 room_id, 
        uint256 total_value,
        address token_owner
    ) internal returns (uint256) {
        Room memory _room = rooms[room_id];
        uint256 _artistPercentage = _room.artistPercentage;
        uint256 _totalFees = total_value * _artistPercentage / 1000;
        uint8 _totalArtists;
        for (uint8 i; i < 38; i++) {
            if (_room.artists[i] == address(0)) {
                break;
            }
            _totalArtists += 1;
        }
        uint256 _singleArtistRoyalty = _totalFees / _totalArtists;
        for (uint8 i; i < _totalArtists; i++) {
            payable(_room.artists[i]).send(_singleArtistRoyalty);
        }

        uint256 _curatorFee = total_value * _room.curatorPercentage / 1000;
        payable(_room.curatorAddress).send(_curatorFee);
        _totalFees += _curatorFee;

        uint256 _ownerFee = total_value * _room.roomOwnerPercentage / 1000;
        payable(_room.owner_of).send(_ownerFee);
        _totalFees += _ownerFee;

        // transfer leftover tokens to NFT seller
        payable(token_owner).send(total_value - _totalFees);

        emit roomerRoyaltiesPayed(room_id, total_value);
        return _totalFees;
    }

    function _distributePlatformFees(uint256 value) internal {
        uint256 _value_left = value;
        for (uint i; i < platformFeeRecipients.length; i++) {
            FeeRecipient memory _feeRecipient = platformFeeRecipients[i];
            uint256 send_value = 
                value * _feeRecipient.percentage / 1000;
            if (_value_left < send_value) break;
            payable(_feeRecipient.recipient).transfer(send_value);
            _value_left -= send_value;
        }
        platformFee += _value_left;
    }

    function createRoom(RoomObject memory item) external {
        if (haveRoomsCreated[msg.sender]) {
            IRoomerToken(roomerToken).burnFrom(msg.sender, roomerTokenFee);
        } else {
            haveRoomsCreated[msg.sender] = true;
        }
        uint256 newId = rooms.length;
        address[38] memory artists;
        uint8[38] memory artworks_amts;  
        rooms.push(
            Room(
                newId,
                item.startTime,
                item.endTime,
                msg.sender,
                item.roomOwnerPercentage,
                item.roomerPercentage,
                item.artworkOwnerPercentage,
                artists,
                artworks_amts,
                item.curatorAddress,
                item.curatorPercentage,
                item.roomerFee,
                0,
                false,
                0,
                false
            )
        );
        IRoomNFT(roomNFTAddress).mint(msg.sender, newId, item.uri);
        if (item.entranceFee > 0) privateRooms[newId] = item.entranceFee;
        emit roomCreated(
            RoomCreatedObject(
                newId,
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

    function approveRoomAuction(uint256 room_id) external onlyCurator(room_id) {
        require(!rooms[room_id].auction_approved, "021");
        rooms[room_id].auction_approved = true;
        emit auctionApproved(room_id);
    }

    function proposeTokenToRoom(
        TokenObject memory tokenInfo
    )
        external
        tokenOwnerOrFactory(tokenInfo.token_address, tokenInfo.token_id, tokenInfo.amount)
        validateDate(
            rooms[tokenInfo.room_id].startTime,
            rooms[tokenInfo.room_id].endTime
        )
    {
        // Make sure token is sold or not listed
        if (tokenInfo.is_auction) {
            // Only single item auctions are allowed
            require(tokenInfo.amount == 1 || tokenInfo.amount == 0, "017");
            require(rooms[tokenInfo.room_id].auction_approved, "024");
        }
        address _caller = msg.sender == singleTokenAddress || msg.sender == multipleTokenAddress 
            ? tokenInfo.owner : msg.sender; 
        require(
            IRoomerToken(roomerToken)
                .balanceOf(_caller) >=
                rooms[tokenInfo.room_id].roomerFee, 
            "044"
        );
        _getRoyaltyInfo(tokenInfo.token_address, tokenInfo.token_id);
        uint256 _uid = tokens.length;
        if (tokenInfo.amount != 0) tokensOnSale[_uid] = tokenInfo.amount; 
        tokens.push(
            Token(
                _uid,
                tokenInfo.token_address,
                _caller,
                tokenInfo.token_id,
                tokenInfo.room_id,
                tokenInfo.price,
                tokenInfo.amount,
                0,
                address(0),
                tokenInfo.start_time,
                tokenInfo.end_time,
                false,
                false,
                tokenInfo.is_auction
            )
        );
        emit tokenProposed(
            tokenInfo,
            _uid
        );
    }

    function cancelProposal(uint256 uid) 
        external 
        onlyTokenOwner(tokens[uid].owner_of)
    {
        require(!tokens[uid].resolved, "013");
        tokens[uid].resolved = true;
        emit proposalCancelled(uid);
    }

    function cancelListedToken(uint256 uid)
        external 
        onlyTokenOwner(tokens[uid].owner_of) 
    {
        require(tokens[uid].approved, "008");
        tokens[uid].approved = false;
        uint256 _room_id = tokens[uid].room_id;
        uint256 _artists_length = rooms[_room_id].artists.length;
        uint8 _removed_roomer_index;
        uint8 _roomer_removed_flag;
        uint8 _last_index;
        for (uint8 i; i < _artists_length; i++) {
            if (rooms[_room_id].artists[i] == address(0)) {
                _last_index = i;
                break;
            }
            if (msg.sender == rooms[_room_id].artists[i]) {
                rooms[_room_id].artworks_owner_amt[i] -= 1;
                if (rooms[_room_id].artworks_owner_amt[i] == 0) {
                    rooms[_room_id].artists[i] = address(0);
                    _removed_roomer_index = i;
                    _roomer_removed_flag = 1;
                }
            }
        }
        // if roomers array is not empty, move last artists to removed user position,
        // e.g. [1, 2, 1, 1 <- removed user, 3, 1, 6, 0 ... 0] -> 
        //      [1, 2, 1, 6 (swapped with last item), 3, 1, 0 ... 0]
        if (_roomer_removed_flag == 1) {
            rooms[_room_id].artists[_removed_roomer_index] = rooms[_room_id].artists[_last_index];
            rooms[_room_id].artworks_owner_amt[_removed_roomer_index] = 
                rooms[_room_id].artworks_owner_amt[_last_index];
            rooms[_room_id].artists[_last_index] = address(0);
            rooms[_room_id].artworks_owner_amt[_last_index] = 0;
        }
        rooms[_room_id].tokensApproved--;
        emit saleCancelled(uid, msg.sender);
    }

    function approveTokenToRoom(
        uint256 uid,
        bool approve
    ) external nonReentrant {
        Token memory _token = tokens[uid];
        require(msg.sender == rooms[_token.room_id].curatorAddress, "003");
        require(!_token.resolved, "010");
        tokens[uid].approved = approve;
        tokens[uid].resolved = true;
        if (approve) {
            require(rooms[_token.room_id].tokensApproved < 38, "011");
            Room memory _room = rooms[_token.room_id];
            address token_owner = _token.owner_of;
            uint256 _roomerFeeSingle = _room.roomerFee / 2;
            if (_roomerFeeSingle > 0) {
                _transferRoomer(token_owner, _room.curatorAddress, _roomerFeeSingle);
                _transferRoomer(token_owner, _room.owner_of, _roomerFeeSingle);
            }
            for (uint8 i; i < 38; i++) {
                if (_room.artists[i] == token_owner) {
                    _room.artworks_owner_amt[i]++;
                    break;
                }
                if (_room.artists[i] == address(0)) {
                    _room.artists[i] = token_owner;
                    _room.artworks_owner_amt[i] = 1;
                    break;
                }
            }
            _room.tokensApproved++;
            rooms[tokens[uid].room_id] = _room;
            emit tokenApproved(_token.is_auction, uid);
        } else {
            emit tokenRejected(_token.is_auction, uid);
        }
    }

    function buyArtwork(uint256 uid, uint256 amount)
        external
        payable
        nonReentrant
        validateDate(
            rooms[tokens[uid].room_id].startTime,
            rooms[tokens[uid].room_id].endTime
        )
        approvedToken(tokens[uid].approved)
        notTokenOwner(tokens[uid].owner_of)
    {
        Token memory _token = tokens[uid];
        address _old_owner = _token.owner_of;
        { // prevent stack to deep
            _checkAccess(msg.sender, _token.room_id);
            require(msg.value >= _token.price, "012");
            require(amount <= tokensOnSale[uid], "019");
            if (amount == 0) require(IERC721Min(_token.token_address).ownerOf(_token.token_id) == _token.owner_of, "047");
            _transferTokens(_token.token_address, _token.token_id, _token.owner_of, msg.sender, amount); 
            tokensOnSale[uid] -= amount;
            tokens[uid] = _token;
            emit tokenSold(uid, _old_owner, msg.sender, amount, msg.value);
        }
        (address _creator, uint256 _royalty, bool _first_sale) = 
            _getRoyaltyInfo(_token.token_address, _token.token_id);
        uint256 _platformFee = msg.value / 40;
        uint256 _value = msg.value - _platformFee;
        _distributePlatformFees(_platformFee);
        if (!_first_sale && _creator != address(0)) {
            uint256 _creator_royalty = _value * _royalty / 1000;
            payable(_creator).send(_creator_royalty);
            _value -= _creator_royalty;
        }
        _distributeFees(_token.room_id, _value, _token.owner_of);
        if (_first_sale && _creator != address(0))
            _updateFirstSale(_token.token_address, _token.token_id);
    }

    function bid(uint256 uid)
        external
        payable
        nonReentrant
        approvedToken(tokens[uid].approved)
        validateDate(tokens[uid].start_time, tokens[uid].end_time)
        notTokenOwner(tokens[uid].owner_of)
    {
        Token memory _token = tokens[uid];
        uint256 _highest_bid = _token.highest_bid;
        require(
            msg.value >= _highest_bid + (_highest_bid / 10) && 
            msg.value >= _token.price,
            "014"
        );
        require(tokens[uid].is_auction, "042");
        _checkAccess(msg.sender, _token.room_id);
        address _highest_bidder = _token.highest_bidder;
        // do not allow contracts to bid on auctions
        require(msg.sender == tx.origin && msg.sender != _highest_bidder, "046");
        tokens[uid].highest_bid = msg.value;
        tokens[uid].highest_bidder = msg.sender;
        feesAvailable[uid] += msg.value;
        if (_highest_bidder != address(0)) {
            payable(_highest_bidder).send(_highest_bid);
        }
        emit bidAdded(uid, msg.value, msg.sender);
    }

    function finalizeAuction(uint256 uid, bool approve)
        external 
        onlyCurator(tokens[uid].room_id)
        nonReentrant
    {
        Token memory _token = tokens[uid];
        require(_token.is_auction, "001");
        if (approve) {
            require(feesAvailable[uid] > 0, "020");
            if (_token.end_time != 0) 
                require(block.timestamp >= _token.end_time, "015");
            _transferTokens(_token.token_address, _token.token_id, _token.owner_of, _token.highest_bidder, _token.amount);
            (address _creator, uint256 _royalty, bool _first_sale) = _getRoyaltyInfo(_token.token_address, _token.token_id);
            uint256 _platformFee = _token.highest_bid / 40; //  2.5% platform fee
            _distributePlatformFees(_platformFee);
            uint256 _value = _token.highest_bid - _platformFee;
            if (!_first_sale && _creator != address(0)) {
                uint256 _creator_royalty = _value * _royalty / 1000;
                payable(_creator).send(_creator_royalty);
                _value -= _creator_royalty;
            }
            _distributeFees(tokens[uid].room_id, _value, _token.owner_of);
            if (_first_sale && _creator != address(0)) _updateFirstSale(_token.token_address, _token.token_id);
            feesAvailable[uid] -= _token.highest_bid;
            tokens[uid] = _token;
        } else {
            // return bid to highest bidder
            payable(_token.highest_bidder).send(_token.highest_bid);
        }
        emit auctionFinalized(uid, approve);
    }

    function updateCurator(uint256 _room_id, address _newCurator) external {
        require(msg.sender == rooms[_room_id].owner_of, "035");
        rooms[_room_id].curatorAddress = _newCurator;
        emit roomCuratorUpdated(_room_id, _newCurator);
    }

    function makeOffer(
        address _token_address,
        uint256 _token_id,
        uint256 _amount
    ) external payable {
        uint256 _value = msg.value;
        require(_value > 0, "041");
        offers.push(
            Offer(
                _token_address,
                _token_id,
                _value,
                _amount,
                msg.sender,
                false,
                false
            )
        );
        emit offerMade(_token_address, _token_id, offers.length - 1, _value, _amount, msg.sender);
    }

    function cancelOffer(uint256 _offer_id) public nonReentrant {
        require(msg.sender == offers[_offer_id].bidder, "043");
        require(!offers[_offer_id].resolved, "030");
        offers[_offer_id].resolved = true;
        payable(msg.sender).transfer(offers[_offer_id].price);
        emit offerCancelled(_offer_id);
    }

    function resolveOffer(uint256 _offer_id, bool _approve) 
        external 
        nonReentrant
        tokenOwnerOrFactory(
            offers[_offer_id].token_address,
            offers[_offer_id].token_id,
            offers[_offer_id].amount
        )
    {
        Offer memory _offer = offers[_offer_id];
        require(!_offer.resolved, "045");
        offers[_offer_id].approved = _approve;
        offers[_offer_id].resolved = true;
        if (_approve) {
            _transferTokens(_offer.token_address, _offer.token_id, msg.sender, _offer.bidder, _offer.amount);
            (address _creator, uint256 _royalty, bool _first_sale) = 
                _getRoyaltyInfo(_offer.token_address, _offer.token_id);
            uint256 _platformFee = _offer.price / 40;
            _distributePlatformFees(_platformFee);
            uint256 _value = _offer.price - _platformFee;
            if (!_first_sale && _creator != address(0)) {
                uint256 _creator_royalty = _value * _royalty / 1000;
                payable(_creator).send(_creator_royalty);
                _value -= _creator_royalty;
            }
            payable(msg.sender).transfer(_value);
            if (_first_sale && _creator != address(0))
                _updateFirstSale(_offer.token_address, _offer.token_id);
        } else {
            if (_offer.amount == 0) {
                payable(offers[_offer_id].bidder).transfer(_offer.price);
            } else {
                offers[_offer_id].resolved = false;
            }
        }
        emit offerResolved(_offer_id, _approve, msg.sender);
    }

    function buyAccess(uint256 _room_id) external {
        uint256 _entryFee = privateRooms[_room_id]; 
        require(_entryFee > 0, "037");
        require(IRoomerToken(roomerToken).balanceOf(msg.sender) >= _entryFee, "038");
        uint256 _halfFee = _entryFee / 2;
        _transferRoomer(msg.sender, rooms[_room_id].owner_of, _halfFee);
        _transferRoomer(msg.sender, rooms[_room_id].curatorAddress, _entryFee - _halfFee);
        IAccessToken(accessToken).mintAccess(msg.sender, _room_id);
    }

    function withdraw(uint256 value) public onlyOwner {
        payable(msg.sender).transfer(value);
    }

    function setTokens(
        address _singleTokenAddress,
        address _multipleTokenAddress,
        address _roomNFTAddress,
        address _accessToken,
        address _roomerTokenAddress
    ) public onlyOwner {
        singleTokenAddress = _singleTokenAddress;
        multipleTokenAddress = _multipleTokenAddress;
        roomNFTAddress = _roomNFTAddress;
        accessToken = _accessToken;
        roomerToken = _roomerTokenAddress;
    }

    function updateRoomOwner(uint256 _room_id, address _newOwner) external {
        require(msg.sender == roomNFTAddress, "031");
        rooms[_room_id].owner_of = _newOwner;
        emit roomOwnerUpdated(_room_id, _newOwner);
    }

    function manageRoomSale(uint256 _room_id, uint256 _price) external {
        require(msg.sender == roomNFTAddress, "031");
        rooms[_room_id].on_sale = _price != 0;
        rooms[_room_id].price = _price;
    }

    function setFeeRecipients(FeeRecipient[] memory _recipients) external onlyOwner {
        delete platformFeeRecipients;
        for (uint8 i; i < _recipients.length; i++) {
            platformFeeRecipients.push(_recipients[i]);
        }
    }
}
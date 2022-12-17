// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/INFTManager.sol";
import "../tokens/ERC20/IRoomerToken.sol";
import "../tokens/ERC721/IRoomNFT.sol";
import "../tokens/ERC721/IERC721Min.sol";
import "../tokens/ERC1155/IERC1155Min.sol";
import "../tokens/IRoyaltyNFT.sol";
import "../storage/IStorage.sol";

contract NFTManager is INFTManager, ReentrancyGuard {
    IStorage public storageContract;
    IRoomerToken public roomerToken;
    address public accessTokenAddress;
    address public singleTokenAddress;
    address public multipleTokenAddress;

    uint256 public platformFee;
    FeeRecipient[] public platformFeeRecipients;

    constructor(
        address _storageContract,
        address _roomerToken,
        address _accessTokenAddress,
        address _singleTokenAddress,
        address _multipleTokenAddress
    ) {
        storageContract = IStorage(_storageContract);
        roomerToken = IRoomerToken(_roomerToken);
        accessTokenAddress = _accessTokenAddress;
        singleTokenAddress = _singleTokenAddress;
        multipleTokenAddress = _multipleTokenAddress;
    }

    modifier onlyOwner {
        require(storageContract.owners(msg.sender), "021");
        _;
    }

    modifier tokenOwnerOrFactory(
        address _token_address,
        uint256 _token_id,
        uint256 _amount
    ) {
        if (
            msg.sender != singleTokenAddress &&
            msg.sender != multipleTokenAddress
        ) {
            require(
                _amount == 0
                    ? IERC721Min(_token_address).ownerOf(_token_id) == msg.sender
                    : IERC1155Min(_token_address).balanceOf(
                        msg.sender,
                        _token_id
                    ) >= _amount,
                "005"
            );
        }
        _;
    }

    modifier validateDate(uint128 _start_date, uint128 _end_date) {
        if (_start_date != 0) {
            require(
                block.timestamp > _start_date && block.timestamp < _end_date,
                "004"
            );
        }
        _;
    }

    modifier approvedToken(bool _approved) {
        require(_approved, "006");
        _;
    }

    modifier onlyTokenOwner(address _owner_of) {
        require(_owner_of == msg.sender, "002");
        _;
    }

    modifier notTokenOwner(address _owner_of) {
        require(_owner_of != msg.sender, "007");
        _;
    }

    modifier onlyCurator(uint256 _room_id) {
        require(
            msg.sender == storageContract.rooms(_room_id).curator_address,
            "003"
        );
        _;
    }

    function _checkAccess(address _user, uint256 _room_id) internal view {
        address _curator = storageContract.rooms(_room_id).curator_address;
        address _owner = storageContract.rooms(_room_id).owner_of;
        if (
            storageContract.privateRooms(_room_id) > 0 &&
            _user != _curator &&
            _user != _owner
        ) {
            require(
                IERC1155Min(accessTokenAddress).balanceOf(_user, _room_id) >= 1,
                "018"
            );
        }
    }

    function _transferRoomer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(roomerToken.transferFrom(_from, _to, _amount), "039");
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
            IERC1155Min(token_address).safeTransferFrom(
                from,
                to,
                token_id,
                amount,
                ""
            );
        }
    }

    function _getRoyaltyInfo(address _token_address, uint256 _token_id)
        internal
        view
        returns (
            address _creator,
            uint256 _royalty,
            bool _first_sale
        )
    {
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

    function _updateFirstSale(address _token_address, uint256 _token_id)
        internal
        returns (bool success)
    {
        try IRoyaltyNFT(_token_address).updateFirstSale(_token_id) {
            return true;
        } catch {
            return false;
        }
    }

    function _distributeFees(
        uint256 _room_id,
        uint256 _total_value,
        address _token_owner
    ) internal returns (uint256) {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        uint256 _artistPercentage = _room.artist_percentage;
        uint256 _totalFees = (_total_value * _artistPercentage) / 1000;
        uint8 _totalArtists;
        address[] memory artists = storageContract.getArtists(_room_id);
        for (uint8 i; i < 38; i++) {
            if (artists[i] == address(0)) {
                break;
            }
            _totalArtists += 1;
        }
        uint256 _singleArtistRoyalty = _totalFees / _totalArtists;
        for (uint8 i; i < _totalArtists; i++) {
            payable(artists[i]).send(_singleArtistRoyalty);
        }

        uint256 _curatorFee = (_total_value * _room.curator_percentage) / 1000;
        payable(_room.curator_address).send(_curatorFee);
        _totalFees += _curatorFee;

        uint256 _ownerFee = (_total_value * _room.room_owner_percentage) / 1000;
        payable(_room.owner_of).send(_ownerFee);
        _totalFees += _ownerFee;

        // transfer leftover tokens to NFT seller
        payable(_token_owner).send(_total_value - _totalFees);

        emit roomerRoyaltiesPayed(_room_id, _total_value);
        return _totalFees;
    }

    function _distributePlatformFees(uint256 value) internal {
        uint256 _value_left = value;
        for (uint256 i; i < platformFeeRecipients.length; i++) {
            FeeRecipient memory _feeRecipient = platformFeeRecipients[i];
            uint256 send_value = (value * _feeRecipient.percentage) / 1000;
            if (_value_left < send_value) break;
            payable(_feeRecipient.recipient).transfer(send_value);
            _value_left -= send_value;
        }
        platformFee += _value_left;
    }

    function proposeTokenToRoom(TokenObject memory tokenInfo)
        external
        tokenOwnerOrFactory(
            tokenInfo.token_address,
            tokenInfo.token_id,
            tokenInfo.amount
        )
        validateDate(
            storageContract.rooms(tokenInfo.room_id).start_time,
            storageContract.rooms(tokenInfo.room_id).end_time
        )
    {
        // Make sure token is sold or not listed
        if (tokenInfo.is_auction) {
            // Only single item auctions are allowed
            require(tokenInfo.amount == 1 || tokenInfo.amount == 0, "017");
            require(
                storageContract.rooms(tokenInfo.room_id).auction_approved,
                "024"
            );
        }
        address _caller = msg.sender == singleTokenAddress || msg.sender == multipleTokenAddress
            ? tokenInfo.owner : msg.sender;
        require(
            roomerToken.balanceOf(_caller) >=
                storageContract.rooms(tokenInfo.room_id).roomer_fee,
            "044"
        );
        _getRoyaltyInfo(tokenInfo.token_address, tokenInfo.token_id);
        uint256 _uid = storageContract.tokensLength();
        if (tokenInfo.amount != 0) {
            storageContract.setTokensOnSale(_uid, tokenInfo.amount);
        }
        storageContract.setTokenSubmitTime(_uid, block.timestamp);
        storageContract.newToken(
            IStorage.Token(
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
        emit tokenProposed(tokenInfo, _uid);
    }

    function cancelProposal(uint256 _uid)
        external
        onlyTokenOwner(storageContract.tokens(_uid).owner_of)
    {
        IStorage.Token memory _token = storageContract.tokens(_uid);
        require(!_token.resolved, "013");
        _token.resolved = true;
        storageContract.updateToken(_uid, _token);
        emit proposalCancelled(_uid);
    }

    function cancelListedToken(uint256 _uid)
        external
        onlyTokenOwner(storageContract.tokens(_uid).owner_of)
        nonReentrant
    {
        require(storageContract.tokens(_uid).approved, "008");
        uint256 _room_id = storageContract.tokens(_uid).room_id;
        IStorage.Token memory _token = storageContract.tokens(_uid);
        _token.approved = false;
        storageContract.updateToken(_uid, _token);
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        address[] memory artists = storageContract.getArtists(_room_id);
        uint16[] memory artworks_owner_amt = storageContract.getArtworksOwnerAmount(_room_id);
        uint8 _removed_roomer_index;
        bool _roomer_removed_flag;
        uint8 _last_index = 37;
        for (uint8 i; i < 38; i++) {
            if (artists[i] == address(0)) {
                _last_index = i;
                break;
            }
            if (msg.sender == artists[i]) {
                artworks_owner_amt[i] -= 1;
                storageContract.setArtworksOwnerAmountById(
                    _room_id,
                    i,
                    artworks_owner_amt[i]
                );
                if (artworks_owner_amt[i] == 0) {
                    storageContract.setArtistsById(_room_id, i, address(0));
                    _removed_roomer_index = i;
                    _roomer_removed_flag = true;
                }
                break;
            }
        }
        // if roomers array is not empty, move last artists to removed user position,
        // e.g. [1, 2, 1, 1 <- removed user, 3, 1, 6, 0 ... 0] ->
        //      [1, 2, 1, 6 (swapped with last item), 3, 1, 0 ... 0]
        if (_roomer_removed_flag) {
            storageContract.setArtistsById(_room_id, _removed_roomer_index, artists[_last_index]);
            storageContract.setArtworksOwnerAmountById(
                _room_id,
                _removed_roomer_index,
                artworks_owner_amt[_last_index]
            );
            storageContract.setArtistsById(_room_id, _last_index, address(0));
            storageContract.setArtworksOwnerAmountById(_room_id, _last_index, 0);
        }
        _room.tokens_approved--;
        storageContract.updateArtroom(_room_id, _room);
        emit saleCancelled(_uid, msg.sender);
    }

    function approveTokenToRoom(uint256 _uid, bool approve)
        external
        nonReentrant
    {
        IStorage.Token memory _token = storageContract.tokens(_uid);
        require(
            msg.sender == storageContract.rooms(_token.room_id).curator_address,
            "003"
        );
        require(!_token.resolved, "010");
        require(storageContract.tokenSubmitTime(_uid) + 30 days >= block.timestamp, "037");
        _token.approved = approve;
        _token.resolved = true;
        storageContract.updateToken(_uid, _token);
        if (approve) {
            IStorage.Room memory _room = storageContract.rooms(_token.room_id);
            require(_room.tokens_approved < 38, "011");
            address token_owner = _token.owner_of;
            uint256 _roomerFeeSingle = _room.roomer_fee / 2;
            if (_roomerFeeSingle > 0) {
                _transferRoomer(
                    token_owner,
                    _room.curator_address,
                    _roomerFeeSingle
                );
                _transferRoomer(token_owner, _room.owner_of, _roomerFeeSingle);
            }
            address[] memory _artists = storageContract.getArtists(_token.room_id);
            uint16[] memory artworks_owner_amt = storageContract.getArtworksOwnerAmount(_token.room_id);
            for (uint8 i; i < 38; i++) {
                if (_artists[i] == address(0)) {
                    storageContract.setArtistsById(_token.room_id, i, token_owner);
                    _artists[i] = token_owner;
                }
                if (_artists[i] == token_owner) {
                    storageContract.setArtworksOwnerAmountById(
                        _token.room_id,
                        i,
                        artworks_owner_amt[i] + 1
                    );
                    break;
                }
            }
            _room.tokens_approved++;
            storageContract.updateArtroom(_token.room_id, _room);
            emit tokenApproved(_token.is_auction, _uid);
        } else {
            emit tokenRejected(_token.is_auction, _uid);
        }
    }

    function buyArtwork(uint256 _uid, uint256 _amount)
        external
        payable
        nonReentrant
        validateDate(
            storageContract
                .rooms(storageContract.tokens(_uid).room_id)
                .start_time,
            storageContract.rooms(storageContract.tokens(_uid).room_id).end_time
        )
        approvedToken(storageContract.tokens(_uid).approved)
        notTokenOwner(storageContract.tokens(_uid).owner_of)
    {
        IStorage.Token memory _token = storageContract.tokens(_uid);
        address _old_owner = _token.owner_of;
        {
            // prevent stack to deep
            _checkAccess(msg.sender, _token.room_id);
            require(msg.value >= _token.price, "012");
            require(_amount <= storageContract.tokensOnSale(_uid), "019");
            if (_amount == 0) {
                require(
                    IERC721Min(_token.token_address).ownerOf(_token.token_id) ==
                        _token.owner_of,
                    "047"
                );
            }
            _transferTokens(
                _token.token_address,
                _token.token_id,
                _token.owner_of,
                msg.sender,
                _amount
            );
            storageContract.setTokensOnSale(
                _uid,
                storageContract.tokensOnSale(_uid) - _amount
            );
            storageContract.updateToken(_uid, _token);
            emit tokenSold(_uid, _old_owner, msg.sender, _amount, msg.value);
        }
        (
            address _creator,
            uint256 _royalty,
            bool _first_sale
        ) = _getRoyaltyInfo(_token.token_address, _token.token_id);
        uint256 _platformFee = msg.value / 40;
        uint256 _value = msg.value - _platformFee;
        _distributePlatformFees(_platformFee);
        if (!_first_sale && _creator != address(0)) {
            uint256 _creator_royalty = (_value * _royalty) / 1000;
            payable(_creator).send(_creator_royalty);
            _value -= _creator_royalty;
        }
        _distributeFees(_token.room_id, _value, _token.owner_of);
        if (_first_sale && _creator != address(0))
            _updateFirstSale(_token.token_address, _token.token_id);
    }

    function bid(uint256 _uid)
        external
        payable
        nonReentrant
        approvedToken(storageContract.tokens(_uid).approved)
        validateDate(
            storageContract.tokens(_uid).start_time,
            storageContract.tokens(_uid).end_time
        )
        notTokenOwner(storageContract.tokens(_uid).owner_of)
    {
        IStorage.Token memory _token = storageContract.tokens(_uid);
        uint256 _highest_bid = _token.highest_bid;
        require(
            msg.value >= _highest_bid + (_highest_bid / 10) &&
                msg.value >= _token.price,
            "014"
        );
        require(_token.is_auction, "042");
        _checkAccess(msg.sender, _token.room_id);
        address _highest_bidder = _token.highest_bidder;
        // do not allow contracts to bid on auctions
        require(
            msg.sender == tx.origin && msg.sender != _highest_bidder,
            "046"
        );
        _token.highest_bid = msg.value;
        _token.highest_bidder = msg.sender;
        storageContract.setFeesAvailable(_uid, storageContract.feesAvailable(_uid) + msg.value);
        storageContract.updateToken(_uid, _token);
        if (_highest_bidder != address(0)) {
            payable(_highest_bidder).send(_highest_bid);
        }
        emit bidAdded(_uid, msg.value, msg.sender);
    }

    function finalizeAuction(uint256 _uid, bool _approve)
        external
        onlyCurator(storageContract.tokens(_uid).room_id)
        nonReentrant
    {
        IStorage.Token memory _token = storageContract.tokens(_uid);
        require(_token.is_auction, "001");
        if (_approve) {
            require(storageContract.feesAvailable(_uid) > 0, "020");
            if (_token.end_time != 0)
                require(block.timestamp >= _token.end_time, "015");
            _transferTokens(
                _token.token_address,
                _token.token_id,
                _token.owner_of,
                _token.highest_bidder,
                _token.amount
            );
            (
                address _creator,
                uint256 _royalty,
                bool _first_sale
            ) = _getRoyaltyInfo(_token.token_address, _token.token_id);
            uint256 _platformFee = _token.highest_bid / 40; //  2.5% platform fee
            _distributePlatformFees(_platformFee);
            uint256 _value = _token.highest_bid - _platformFee;
            if (!_first_sale && _creator != address(0)) {
                uint256 _creator_royalty = (_value * _royalty) / 1000;
                payable(_creator).send(_creator_royalty);
                _value -= _creator_royalty;
            }
            _distributeFees(
                storageContract.tokens(_uid).room_id,
                _value,
                _token.owner_of
            );
            if (_first_sale && _creator != address(0)) {
                _updateFirstSale(_token.token_address, _token.token_id);
            }
            storageContract.setFeesAvailable(
                _uid,
                storageContract.feesAvailable(_uid) - _token.highest_bid
            );
            storageContract.updateToken(_uid, _token);
        } else {
            // return bid to highest bidder
            payable(_token.highest_bidder).send(_token.highest_bid);
        }
        emit auctionFinalized(_uid, _approve);
    }

    function makeOffer(
        address _token_address,
        uint256 _token_id,
        uint256 _amount
    ) external payable {
        uint256 _value = msg.value;
        require(_value > 0, "041");
        uint256 _offer_id = storageContract.offersLength();
        storageContract.newOffer(
            IStorage.Offer(
                _token_address,
                _token_id,
                _value,
                _amount,
                msg.sender,
                false,
                false
            )
        );
        emit offerMade(
            _token_address,
            _token_id,
            _offer_id,
            _value,
            _amount,
            msg.sender
        );
    }

    function cancelOffer(uint256 _offer_id) public nonReentrant {
        IStorage.Offer memory _offer = storageContract.offers(_offer_id);
        require(msg.sender == _offer.bidder, "043");
        require(!_offer.resolved, "030");
        _offer.resolved = true;
        storageContract.updateOffer(_offer_id, _offer);
        payable(msg.sender).transfer(_offer.price);
        emit offerCancelled(_offer_id);
    }

    function resolveOffer(uint256 _offer_id, bool _approve)
        external
        nonReentrant
        tokenOwnerOrFactory(
            storageContract.offers(_offer_id).token_address,
            storageContract.offers(_offer_id).token_id,
            storageContract.offers(_offer_id).amount
        )
    {
        IStorage.Offer memory _offer = storageContract.offers(_offer_id);
        require(!_offer.resolved, "045");
        _offer.approved = _approve;
        _offer.resolved = true;
        if (_approve) {
            _transferTokens(
                _offer.token_address,
                _offer.token_id,
                msg.sender,
                _offer.bidder,
                _offer.amount
            );
            (
                address _creator,
                uint256 _royalty,
                bool _first_sale
            ) = _getRoyaltyInfo(_offer.token_address, _offer.token_id);
            uint256 _platformFee = _offer.price / 40;
            _distributePlatformFees(_platformFee);
            uint256 _value = _offer.price - _platformFee;
            if (!_first_sale && _creator != address(0)) {
                uint256 _creator_royalty = (_value * _royalty) / 1000;
                payable(_creator).send(_creator_royalty);
                _value -= _creator_royalty;
            }
            payable(msg.sender).transfer(_value);
            if (_first_sale && _creator != address(0))
                _updateFirstSale(_offer.token_address, _offer.token_id);
        } else {
            if (_offer.amount == 0) {
                payable(_offer.bidder).transfer(_offer.price);
            } else {
                _offer.resolved = false;
            }
        }
        storageContract.updateOffer(_offer_id, _offer);
        emit offerResolved(_offer_id, _approve, msg.sender);
    }

    function setFeeRecipients(FeeRecipient[] memory _recipients)
        external
        onlyOwner
    {
        if (platformFeeRecipients.length != 0) delete platformFeeRecipients;
        for (uint8 i; i < _recipients.length; i++) {
            platformFeeRecipients.push(_recipients[i]);
        }
    }

    function setTokens(
        address _roomerToken,
        address _accessTokenAddress,
        address _singleTokenAddress,
        address _multipleTokenAddress
    ) external onlyOwner {
        roomerToken = IRoomerToken(_roomerToken);
        accessTokenAddress = _accessTokenAddress;
        singleTokenAddress = _singleTokenAddress;
        multipleTokenAddress = _multipleTokenAddress;
    }
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
pragma solidity ^0.8.0;

interface IRoyaltyNFT {
    function getCreator(uint256 token_id) external returns (address);
    function getRoyaltyInfo(uint256 token_id) external view returns (address, uint256, bool);
    function updateFirstSale(uint256 token_id) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Min {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
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

interface INFTManager {
    struct Room {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        address owner_of;
        uint16 room_owner_percentage;
        uint16 artist_percentage;
        uint16 artwork_owner_percentage;
        address[38] artists;
        uint8[38] artworks_owner_amt;
        address curatorAddress;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 price;
        uint128 tokensApproved;
        bool on_sale;
        bool auction_approved;
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

    struct FeeRecipient {
        address recipient;
        uint16 percentage;
    }

    event tokenProposed(TokenObject tokenInfo, uint256 uid);
    event proposalCancelled(uint256 uid);

    event tokenApproved(bool isAuction, uint256 uid);
    event tokenRejected(bool isAuction, uint256 uid);
    event saleCancelled(uint256 uid, address curator);
    event tokenSold(
        uint256 uid,
        address old_owner,
        address new_owner,
        uint256 amount,
        uint256 total_price
    );
    event roomerRoyaltiesPayed(uint256 room_id, uint256 total_value);
    
    event bidAdded(uint256 auctId, uint256 highest_bid, address highest_bidder);
    event auctionFinalized(uint256 auctId, bool approve);
    
    event offerMade(address token_address, uint256 token_id, uint256 offer_id, uint256 price, uint256 amount, address bidder);
    event offerCancelled(uint256 offer_id);
    event offerResolved(uint256 offer_id, bool approved, address from);
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
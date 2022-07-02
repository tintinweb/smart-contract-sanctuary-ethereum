/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/
            
pragma solidity ^0.5.0;

//////import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata /*is IERC721*/ {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/
            
pragma solidity ^0.5.0;

//////import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable /*is IERC721*/ {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.5.10;

////import "./IERC721Enumerable.sol";
////import "./IERC721Metadata.sol";
/*
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
*/
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.

//interface IERC721Metadata /* is ERC721 */ {
/*
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
*/

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
//interface IERC721Enumerable /* is ERC721 */ {
/*
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
*/
interface IRoyalty {
//    function getRoyaltyFee() external view returns(uint16);

    function getRoyaltyOwner(uint _itemId) external view returns(address payable);

}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
contract IERC721 is /*IERC165,*/ IERC721TokenReceiver, IERC721Metadata, IERC721Enumerable, IRoyalty {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}




/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

////import "./IERC721.sol";

interface NFTAllowance {
//****************************************************************************
//* External Functions
//****************************************************************************
    function isAllowed(address _nftContract) external view returns(bool);

    function isRegistered(address _nftContract) external view returns(bool);

    function getNftContractsCount() external view returns(uint);
    
    function getNftContract(uint _index) external view returns(
        address _address,
        string memory _name,
        string memory _symbol,
        bool _allowed,
        bool _registered
        );

    function getPrimaryTokenContract() external view returns(address);

    function newNftContract(address _tokenContract) external;
    
    function isUserAuthorized(address _user) external view returns(bool);
    
}



/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/
            
pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
//////import "./IERC20.sol";
////import "./IERC721.sol";
////import "./INFTAllowance.sol";
//////import "./IERC721.sol";

contract BidERC721Data {
//****************************************************************************
//* Data
//****************************************************************************
    struct Auction {
        address nftTokenContract;
        uint itemId;
        uint baseValue;
        uint maxBidValue;
        address payable tokenSeller;
        address payable tokenBidder;
        uint40 bidTimeStart;
        uint40 bidTimeEnd;
        uint8 auctionStatus; // 1: Auction set, 2: Bid set, 3: Returned to seller, 4: paid to bidder 5: Cancelled
//        bytes12 collectionId;
    }
    struct History {
        mapping(uint => uint) history; // [index] => [Auction index]
        uint historyCount;
    }
    Auction[] auctions;
    mapping(address => uint[]) userAuctions;
    mapping(address => uint[]) myBids;
    mapping(address => mapping(uint => uint)) activeAuction ;
    mapping(address => mapping(uint => History)) nftTokenHistory;
//    mapping(address => Token) nftTokens;
//    address[] nftTokensArray;
//    mapping(bytes12 => uint[]) collectionAuctions;
//    bytes12[] collectionIds;
    uint[] activeAuctions;
    uint40 maxBidStartGap;
    uint40 maxBidDuration;
    uint16 winnerCommission = 50; // 50/1e4 => 0.5%
    uint16 primaryCreatorCommission = 1000; // 1000/1e4 => 10%
    uint16 secondaryCreatorCommission = 700; // 700/1e4 => 7%
    uint16 endAuctionGap = 900; // 15*60 => 15 min
    bool limitedToken = true;
    NFTAllowance NFTAllowanceContract;

//****************************************************************************
//* Modifiers
//****************************************************************************
    modifier nftContractAllowed(address _nftContract, uint _tokenId) {
        require(NFTAllowanceContract.isAllowed(_nftContract),"NFT contract is not allowed.");
        IERC721 erc721Token = IERC721(_nftContract);
        require(_tokenId <= erc721Token.totalSupply(),"Invalid NFT token id.");
        _;
    }

    modifier nftContractRegistered(address _nftContract) {
        require(NFTAllowanceContract.isRegistered(_nftContract),"NFT Contract is not registered.");
        _;
    }

    modifier validAuction(uint _index) {
        require(_index > 0 && _index < auctions.length,"Invalid auction index.");
        _;
    }

    modifier activeToken(address _tokenContract, uint _tokenId) {
        require(activeAuction[_tokenContract][_tokenId] > 0,"Inactive or invalid token.");
        _;
    }

//****************************************************************************
//* Events
//****************************************************************************
    event AuctionSet(address payable indexed _user, address indexed _nftContract, uint indexed _itemId);
    event BidSet(address payable indexed _user, uint indexed _index, uint _amount);
    event AuctionCancelled(address payable indexed _user, uint indexed _index);
    event BidWon(address payable indexed _user, uint indexed _index);
    event BidFailed(address payable indexed _user, uint indexed _index, uint _amount);
    event NoBid(address payable indexed _user, uint indexed _index);

}

/** 
 *  SourceUnit: /home/mohammadreza/Downloads/SC3/Market/BidERC721Getters.sol
*/

pragma solidity ^0.5.10;
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// Rinkeby Testnet: 0x5182c8D22A447354d8C5eD5da4349053ae3151A7

//////import "./SafeMath.sol";
//////import "./benefitable.sol";
//////import "./IERC20.sol";
////import "./IERC721.sol";
////import "./BidERC721Data.sol";

contract BidERC721Getters is BidERC721Data {

//****************************************************************************
//* Getter Functions
//****************************************************************************
    function getAuctionById(uint _index) public view validAuction(_index) returns(
        address _tokenContract,
        uint _tokenId,
        uint _baseValue,
        uint _maxBidValue,
        address payable _tokenSeller,
        address payable _tokenBidder,
        uint40 _bidTimeStart,
        uint40 _bidTimeEnd,
        uint8 _auctionStatus,
        uint8 _auctionTimeStatus
        ) {
        Auction memory _auction = auctions[_index];
        _tokenContract = _auction.nftTokenContract;
        _tokenId = _auction.itemId;
        _baseValue = _auction.baseValue;
        _maxBidValue = _auction.maxBidValue;
        _tokenSeller = _auction.tokenSeller;
        _tokenBidder = _auction.tokenBidder;
        _bidTimeStart = _auction.bidTimeStart;
        _bidTimeEnd = _auction.bidTimeEnd;
        _auctionStatus = _auction.auctionStatus;
        _auctionTimeStatus = _getTimeStatus(_bidTimeStart, _bidTimeEnd);
    }
    
    function getAuction(address _tokenContract, uint _tokenId) external view returns(
        uint _index,
        uint _baseValue,
        uint _maxBidValue,
        address payable _tokenSeller,
        address payable _tokenBidder,
        uint40 _bidTimeStart,
        uint40 _bidTimeEnd,
        uint8 _auctionStatus,
        uint8 _auctionTimeStatus
        ) {
        _index = activeAuction[_tokenContract][_tokenId];
        require(_index > 0,"Inactive or invalid token.");
        Auction memory _auction = auctions[_index];
        _baseValue = _auction.baseValue;
        _maxBidValue = _auction.maxBidValue;
        _tokenSeller = _auction.tokenSeller;
        _tokenBidder = _auction.tokenBidder;
        _bidTimeStart = _auction.bidTimeStart;
        _bidTimeEnd = _auction.bidTimeEnd;
        _auctionStatus = _auction.auctionStatus;
        _auctionTimeStatus = _getTimeStatus(_bidTimeStart, _bidTimeEnd);
    }
    
    function getNftTokenHistoryCount(address _tokenContract, uint _tokenId) external view returns(uint) {
        return(nftTokenHistory[_tokenContract][_tokenId].historyCount);
    }
    
    function getNftTokenHistoryIndex(address _tokenContract, uint _tokenId, uint _index) external view returns(uint) {
        require(_index < nftTokenHistory[_tokenContract][_tokenId].historyCount,"Invalid history index.");
        return(nftTokenHistory[_tokenContract][_tokenId].history[_index]);
    }
    
    function getAuctionTimeToStart(uint _index) external view validAuction(_index) returns(uint) {
        uint40 _timeStart = auctions[_index].bidTimeStart;
        if (now < _timeStart)
            return(_timeStart - now);
        return(0);
    }
    
    function getAuctionTimeToEnd(uint _index) external view validAuction(_index) returns(uint) {
        uint40 _timeEnd = auctions[_index].bidTimeEnd;
        if (now < _timeEnd)
            return(_timeEnd - now);
        return(0);
    }
    
    function getMyAuctionsCount() external view returns(uint) {
        return(userAuctions[msg.sender].length);
    }
    
    function getMyAuctionIndex(uint _index) external view returns(uint) {
        require(_index < userAuctions[msg.sender].length,"Invalid user auction index.");
        return(userAuctions[msg.sender][_index]);
    }
    
    function getMyBidsCount() external view returns(uint) {
        return(myBids[msg.sender].length);
    }

    function getMyBid(uint _index) external view returns(uint) {
        require(_index < myBids[msg.sender].length,"Invalid user bid index.");
        return(myBids[msg.sender][_index]);
    }

    function getMyActiveBids() external view returns(address[] memory, uint[] memory) {
        uint _len = myBids[msg.sender].length;
        uint[] memory _tmpArray = new uint[](_len);
        uint _auctionId;
        uint _auctionStatus;
        uint j = 0;
        for (uint i = 0; i < _len; i++) {
            _auctionId = myBids[msg.sender][i];
            _auctionStatus = auctions[_auctionId].auctionStatus;
            if (_auctionStatus == 1 || _auctionStatus == 2) {
                _tmpArray[j] = _auctionId;
                j++;
            }
        }
        address[] memory _nftContracts = new address[](j);
        uint[] memory _nftTokenIds = new uint[](j);
        for(uint i = 0; i < j; i++) {
            _nftContracts[i] = auctions[_tmpArray[i]].nftTokenContract;
            _nftTokenIds[i] = auctions[_tmpArray[i]].itemId;
        }
        return(_nftContracts, _nftTokenIds);
    }
    
    function getUserAuctionsCount(address _user) external view returns(uint) {
        return(userAuctions[_user].length);
    }
    
    function getUserAuctionIndex(address _user, uint _index) external view returns(uint) {
        require(_index < userAuctions[_user].length,"Invalid user auction index.");
        return(userAuctions[_user][_index]);
    }
    
    function getUserBidsCount(address _user) external view returns(uint) {
        return(myBids[_user].length);
    }
    
    function getUserBid(address _user, uint _index) external view returns(uint/**/) {
        require(_index < myBids[_user].length,"Invalid user bid index.");
        return(myBids[_user][_index]);
    }
    
    function getUserActiveBids(address _user) external view returns(address[] memory, uint[] memory) {
        uint _len = myBids[_user].length;
        uint[] memory _tmpArray = new uint[](_len);
        uint _auctionId;
        uint _auctionStatus;
        uint j = 0;
        for (uint i = 0; i < _len; i++) {
            _auctionId = myBids[_user][i];
            _auctionStatus = auctions[_auctionId].auctionStatus;
            if (_auctionStatus == 1 || _auctionStatus == 2) {
                _tmpArray[j] = _auctionId;
                j++;
            }
        }
        address[] memory _nftContracts = new address[](j);
        uint[] memory _nftTokenIds = new uint[](j);
        for(uint i = 0; i < j; i++) {
            _nftContracts[i] = auctions[_tmpArray[i]].nftTokenContract;
            _nftTokenIds[i] = auctions[_tmpArray[i]].itemId;
        }
        return(_nftContracts, _nftTokenIds);
    }
    
    function isNftContractRegistered(address _nftContract) external view returns(bool) {
        return(NFTAllowanceContract.isRegistered(_nftContract));
    }
    
    function isNftContractAllowed(address _nftContract) external view returns(bool) {
        return(NFTAllowanceContract.isAllowed(_nftContract));
    }
    
    function getNftContractsCount() external view returns(uint) {
        return(NFTAllowanceContract.getNftContractsCount());
    }
    
    function getNftContract(uint _index) external view returns(
        address,
        string memory,
        string memory,
        bool,
        bool
        ) {
        return(NFTAllowanceContract.getNftContract(_index));
    }
    
    function getMaxBidStartGap() external view returns(uint) {
        return(maxBidStartGap);
    }
    
    function getMaxBidDuration() external view returns(uint) {
        return(maxBidDuration);
    }
    
    function getWinnerCommission() external view returns(uint) {
        return(winnerCommission);
    }
    
    function getPrimaryCreatorCommission() external view returns(uint) {
        return(primaryCreatorCommission);
    }
    
    function getSecondaryCreatorCommission() external view returns(uint) {
        return(secondaryCreatorCommission);
    }
    
    function getAuctionsCount() external view returns(uint) {
        return(auctions.length);
    }
    
    function getActiveAuctionsCount() external view returns(uint) {
        return(activeAuctions.length);
    }

    function getActiveAuction(uint _index) external view returns(
        address _tokenContract,
        uint _tokenId,
        uint _baseValue,
        uint _maxBidValue,
        address payable _tokenSeller,
        address payable _tokenBidder,
        uint40 _bidTimeStart,
        uint40 _bidTimeEnd,
        uint8 _auctionStatus,
        uint8 _auctionTimeStatus
        ) {
        require(_index < activeAuctions.length,"Invalid active auction index.");
        uint _id = activeAuctions[_index];
        Auction memory _auction = auctions[_id];
        _tokenContract = _auction.nftTokenContract;
        _tokenId = _auction.itemId;
        _baseValue = _auction.baseValue;
        _maxBidValue = _auction.maxBidValue;
        _tokenSeller = _auction.tokenSeller;
        _tokenBidder = _auction.tokenBidder;
        _bidTimeStart = _auction.bidTimeStart;
        _bidTimeEnd = _auction.bidTimeEnd;
        _auctionStatus = _auction.auctionStatus;
        _auctionTimeStatus = _getTimeStatus(_bidTimeStart, _bidTimeEnd);
    }

    function getInTimeActiveAuctions() external view returns(uint[] memory) {
        uint _len = activeAuctions.length;
        uint j = 0;
        uint[] memory _tmpArray = new uint[](_len);
        for(uint i = 0; i < _len; i++) {
            if (now >= auctions[activeAuctions[i]].bidTimeStart && now <= auctions[activeAuctions[i]].bidTimeEnd) {
                _tmpArray[j] = activeAuctions[i];
                j++;
            }
        }
        uint[] memory _activeAuctions = new uint[](j);
        j = 0;
        for(uint i = 0; i < j; i++) {
            _activeAuctions[i] = _tmpArray[i];
        }
        return(_activeAuctions);
    }

    function getActiveAuctions() external view returns(uint[] memory) {
        return(activeAuctions);
    }

    function getNFTAllowanceContract() public view returns(address) {
        return(address(NFTAllowanceContract));
    }
    
//****************************************************************************
//* Internal Functions
//****************************************************************************
    function _getTimeStatus(uint40 _timeStart, uint40 _timeEnd) internal view returns(uint8 _timeStatus) {
        if (now < _timeStart)
            _timeStatus = 1; // Before start time
        else if (now > _timeEnd)
            _timeStatus = 3; // After end time
        else
            _timeStatus = 2; // Between start time and end time
    }

    function inArray(uint _needle, uint[] storage _hayStack) internal view returns(bool) {
        uint _len = _hayStack.length;
        for (uint i = 0; i < _len; i++) {
            if (_hayStack[i] == _needle)
                return(true);
        }
        return(false);
    }

    function inMemoryArray(bytes12 _needle, bytes12[] memory _hayStack) internal pure returns(bool) {
        uint _len = _hayStack.length;
        for (uint i = 0; i < _len; i++) {
            if (_hayStack[i] == _needle)
                return(true);
        }
        return(false);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata txType) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data,string calldata txType) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function setApprovalForAll(address operator, bool approved) external;
  
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}
contract AlvinMarketplace {

    enum AssetType { UNKNOWN, ERC721, ERC1155 }
    enum ListingStatus { ON_HOLD, ON_SALE, IS_AUCTION}
    bytes BUY = 'BUY';
    bytes SELL = 'SELL';
    bytes OFFER = 'OFFER';

    struct Listing {
        address contractAddress;
        AssetType assetType;
        ListingStatus status;
        uint numOfCopies;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
    }
    struct Offer {
        address contractAddress;
        address createdByAddress;
        AssetType assetType;
        uint numOfCopies;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool accepted;
    }
    address admin;
    mapping(address => mapping(uint256 => mapping(address => Listing))) private _listings;
    mapping(address => mapping(uint => Offer[])) private _offerListing;
    mapping(address => mapping(uint => mapping(address => mapping(uint => Offer)))) private _sOfferListing;
    mapping(address => uint256) private _outstandingPayments;

    event PurchaseConfirmed(uint256 indexed tokenId, address indexed itemOwner, address indexed buyer);
    event BatchPurchaseConfirmed(uint256[] indexed tokenId, address[] indexed itemOwner, address indexed buyer);
    event PaymentWithdrawn(uint256 indexed amount);
    event HighestBidIncreased(uint256 indexed tokenId,address itemOwner,address indexed bidder,uint256 indexed amount);
    event OfferCreated(address indexed contractAddress, address indexed createdByAddress, uint indexed tokenId);
    event OfferAccepted(address indexed contractAddress, address indexed createdByAddress, uint indexed tokenId);

    constructor(address _admin) {
        admin = _admin;
    }
    modifier _isAdmin{
        require(admin == msg.sender, "Marketplace:Caller is not an admin");
        _;
    }
    modifier _isType(AssetType _assetType){
        require(
            _assetType == AssetType.ERC721 || _assetType == AssetType.ERC1155,
            "Only ERC721/ERC1155 are supported"
        );
        _;
    }
    function updateAdmin(address _newAdmin)  external _isAdmin returns(bool){
        admin = _newAdmin;
        return true;
    }
    function setListing(
        address _contractAddress, 
        AssetType _assetType,
        uint _tokenId,
        ListingStatus _status,
        uint _numOfCopies,
        uint _price,
        uint256 _startTime,
        uint256 _endTime) _isType(_assetType) external {
        
        _checkTypeAndBalance(_assetType, _contractAddress, _tokenId, _numOfCopies);

        if (_status == ListingStatus.ON_HOLD) {
            require(
                _listings[_contractAddress][_tokenId][msg.sender].highestBidder == address(0),
                "Marketplace: bid already exists"
            );

            _listings[_contractAddress][_tokenId][msg.sender] = Listing({
                contractAddress: _contractAddress,
                assetType: _assetType,
                status: _status,
                numOfCopies:0,
                price: 0,
                startTime: 0,
                endTime: 0,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (_status == ListingStatus.ON_SALE) {
            require(
                _listings[_contractAddress][_tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "Marketplace: token not on hold"
            );

            _listings[_contractAddress][_tokenId][msg.sender] = Listing({
                contractAddress: _contractAddress,
                assetType: _assetType,
                status: _status,
                numOfCopies:_numOfCopies,
                price: _price,
                startTime: 0,
                endTime: 0,
                highestBidder: address(0),
                highestBid: 0
            });
        }        
    }

    function listingOf(address _contractAddress, address _account, uint256 _tokenId)
        external
        view
        returns (Listing memory)
    {
        require(_account != address(0),"Marketplace: address cannot be zero address");
        return _listings[_contractAddress][_tokenId][_account];
    }

    function buy(uint256 _tokenId, uint _numOfCopies,address _itemOwner, address _contractAddress, bool batch, uint _tokenPrice) public payable returns(bool){
        uint tokenPrice = 0;
        if(batch){tokenPrice = _tokenPrice;}
        else{ tokenPrice = msg.value;}

        require(
            _listings[_contractAddress][_tokenId][_itemOwner].status == ListingStatus.ON_SALE,
            "Marketplace: token not listed for sale"
        );
        //check balance and number of copies
        if (_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC721) {
            require(
                IERC721(_contractAddress).balanceOf(_itemOwner) > 0,
                "buy: Insufficient Copies to buy"
            );
            require(tokenPrice >= _listings[_contractAddress][_tokenId][_itemOwner].price*1, "buy721: not enough fund");
        } else if(_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC1155) {
            require(
                IERC1155(_contractAddress).balanceOf(_itemOwner, _tokenId) >= _listings[_contractAddress][_tokenId][_itemOwner].numOfCopies,
                " buy: Insufficient Copies to buy"
            );
            require(
                _listings[_contractAddress][_tokenId][_itemOwner].numOfCopies>=_numOfCopies,
                " buy: Insufficient Copies to buy"
            );
            require(tokenPrice >= _numOfCopies * _listings[_contractAddress][_tokenId][_itemOwner].price, "buy1155: not enough fund");
        }
        //safeTransferFrom
        uint copiesLeft = 0;
        if (_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC721) {
            IERC721(_contractAddress).safeTransferFrom(_itemOwner, msg.sender, _tokenId, BUY);
        } else if(_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC1155) {
            IERC1155(_contractAddress).safeTransferFrom(_itemOwner, msg.sender, _tokenId, _numOfCopies, "");
            copiesLeft = _listings[_contractAddress][_tokenId][_itemOwner].numOfCopies - _numOfCopies;
        }
         _listings[_contractAddress][_tokenId][_itemOwner] = Listing({
            contractAddress: copiesLeft >= 1 ? _contractAddress : address(0),
            assetType: copiesLeft >= 1 ? _listings[_contractAddress][_tokenId][_itemOwner].assetType : AssetType.UNKNOWN,
            status: copiesLeft >= 1 ? _listings[_contractAddress][_tokenId][_itemOwner].status : ListingStatus.ON_HOLD,
            numOfCopies: copiesLeft >= 1 ? copiesLeft : 0,
            price: copiesLeft >= 1 ? _listings[_contractAddress][_tokenId][_itemOwner].price : 0,
            startTime: 0,
            endTime: 0,
            highestBidder: address(0),
            highestBid: 0
        });
        
        _outstandingPayments[_itemOwner] += (msg.value);
        // uint256 _amount = _outstandingPayments[_itemOwner];
        // if (!payable(_itemOwner).send(_amount)) {
        //     _outstandingPayments[_itemOwner] = _amount;
        //     return false;
        // }
        
        emit PurchaseConfirmed(_tokenId, _itemOwner, msg.sender);
        return true;
    }
    
    function batchBuy(uint256[] memory _tokenId, uint[] memory _numOfCopies, address[] memory _itemOwner, address[] memory _contractAddress) external payable returns(bool){
        require(_tokenId.length == _numOfCopies.length, 'Marketplace:Uint length dont match');
        require(_itemOwner.length == _contractAddress.length, 'Marketplace:addresses length dont match');
        uint totalPrice = 0;
        uint tokenPrice = msg.value;
        for (uint i=0;i <_tokenId.length; ++i){
           totalPrice = totalPrice+ _listings[_contractAddress[i]][_tokenId[i]][_itemOwner[i]].price;
        }
        require(msg.value>=totalPrice,'BatchBuy: Insuffiecient Funds');
        for(uint i = 0; i < _tokenId.length; ++i){
            buy(_tokenId[i], _numOfCopies[i], _itemOwner[i], _contractAddress[i], true, tokenPrice);
            tokenPrice = msg.value - _listings[_contractAddress[i]][_tokenId[i]][_itemOwner[i]].price;
        }
        emit BatchPurchaseConfirmed(_tokenId, _itemOwner, msg.sender);
        return true;
    }
 
    function makeOffer( 
        address _contractAddress,
        AssetType _assetType,
        uint _tokenId,
        uint _numOfCopies,
        uint256 _startTime,
        uint256 _endTime) _isType(_assetType) external payable returns(Offer memory){

        require(_startTime > 0, 'Marketplace:Offer startTime must be > 0');
        require(_endTime > 0, 'Marketplace:Offer endTime must be > 0');
        _sOfferListing[_contractAddress][_tokenId][msg.sender][_startTime] = Offer({
            contractAddress: _contractAddress,
            createdByAddress: msg.sender,
            assetType: _assetType,
            numOfCopies:_numOfCopies,
            price: msg.value,
            startTime: _startTime,
            endTime: _endTime,
            accepted: false
        });
        _offerListing[_contractAddress][_tokenId].push(_sOfferListing[_contractAddress][_tokenId][msg.sender][_startTime]);
        _outstandingPayments[msg.sender] += msg.value;
        emit OfferCreated(_contractAddress, msg.sender, _tokenId);
        return _sOfferListing[_contractAddress][_tokenId][msg.sender][_startTime];
    }

    function acceptOffer(address _contractAddress, address _createdByAddress, uint _tokenId, uint _startTime) external returns(Offer memory){
        Offer storage _off = _sOfferListing[_contractAddress][_tokenId][_createdByAddress][_startTime];

        require(_off.accepted == false,'Marketplace: Offer is accepted already');
        require(block.timestamp <= _off.endTime && block.timestamp >= _off.startTime, 'Marketplace: Offer is expired');
        require(_outstandingPayments[_off.createdByAddress] >= _off.price,'Marketplace: User has insufficient funds');

        uint copiesLeft=0;
        if(_off.assetType == AssetType.ERC721){
            require(IERC721(_off.contractAddress).balanceOf(msg.sender) > 0,"Marketplace: Insufficient Balance");
            IERC721(_off.contractAddress).safeTransferFrom(msg.sender, _off.createdByAddress, _tokenId,OFFER);
        } else if(_off.assetType == AssetType.ERC1155) {
            require(IERC1155(_off.contractAddress).balanceOf(msg.sender, _tokenId) >= _off.numOfCopies,"Marketplace: Insufficient Balance");
            IERC1155(_off.contractAddress).safeTransferFrom(msg.sender, _off.createdByAddress, _tokenId, _off.numOfCopies, "");
            copiesLeft = _listings[_off.contractAddress][_tokenId][msg.sender].numOfCopies - _off.numOfCopies;
        }
        _off.accepted = true;
        _offerListing[_contractAddress][_tokenId].push(_sOfferListing[_contractAddress][_tokenId][_createdByAddress][block.timestamp]);
        
        if(_listings[_off.contractAddress][_tokenId][msg.sender].status == ListingStatus.ON_SALE){
            _listings[_off.contractAddress][_tokenId][msg.sender] = Listing({
                contractAddress: copiesLeft == 0 ? address(0): _off.contractAddress,
                assetType: copiesLeft >= 1 ? _listings[_off.contractAddress][_tokenId][msg.sender].assetType : AssetType.UNKNOWN,
                status: copiesLeft >= 1 ? _listings[_off.contractAddress][_tokenId][msg.sender].status : ListingStatus.ON_HOLD,
                numOfCopies: copiesLeft >= 1 ? copiesLeft : 0,
                price: copiesLeft >= 1 ? _listings[_off.contractAddress][_tokenId][msg.sender].price : 0,
                startTime: 0,
                endTime: 0,
                highestBidder: address(0),
                highestBid: 0
            });
        }

        _outstandingPayments[_off.createdByAddress] -= _off.price;
        _outstandingPayments[msg.sender] += _off.price;
        
        emit OfferAccepted(_off.createdByAddress, msg.sender, _tokenId);
        return _off;
    }
    function withdrawPayment() external returns (bool) {
        uint256 amount = _outstandingPayments[msg.sender];
        if (amount > 0) {
            _outstandingPayments[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingPayments[msg.sender] = amount;
                return false;
            }
            emit PaymentWithdrawn(amount);
        }
        return true;
    }

    function outstandingPayment(address _user) external view returns (uint256) {
        return _outstandingPayments[_user];
    }

    function getAllOffers(address _contractAddress, uint _tokenId) external view returns(Offer[] memory){
        return _offerListing[_contractAddress][_tokenId];
    }

    function getOfferByTimestamp(address _contractAddress, uint _tokenId, address _createdByAddress, uint _startTime) external view returns(Offer memory){
        return _sOfferListing[_contractAddress][_tokenId][_createdByAddress][_startTime];
    }

    function _checkTypeAndBalance(AssetType _assetType, address _contractAddress, uint _tokenId, uint _numOfCopies) internal view {
        if (_assetType == AssetType.ERC721) {
            require(
                IERC721(_contractAddress).balanceOf(msg.sender) > 0,
                "Marketplace: Insufficient Balance"
            );
            
            require(IERC721(_contractAddress).isApprovedForAll(msg.sender,address(this)),"Marketplace:should call setApproveForAll");
        } else if(_assetType == AssetType.ERC1155) {
            require(
                IERC1155(_contractAddress).balanceOf(msg.sender, _tokenId) >= _numOfCopies,
                "Marketplace: Insufficient Balance"
            );
            require(IERC1155(_contractAddress).isApprovedForAll(msg.sender,address(this)),"Marketplace:should call setApproveForAll");
        }
    }
}
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
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function setApprovalForAll(address operator, bool approved) external;
  
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}
contract AlvinMarketplace {

    enum AssetType { UNKNOWN, ERC721, ERC1155 }
    enum ListingStatus { ON_HOLD, ON_SALE, IS_AUCTION}

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

    address admin;
    mapping(address => mapping(uint256 => mapping(address => Listing))) private _listings;
    mapping(address => uint256) private _outstandingPayments;

    event PurchaseConfirmed(uint256 indexed tokenId, address indexed itemOwner, address indexed buyer);
    event PaymentWithdrawn(uint256 indexed amount);
    event HighestBidIncreased(uint256 indexed tokenId,address itemOwner,address indexed bidder,uint256 indexed amount);

    constructor(address _admin) {
        admin = _admin;
    }
    modifier _isAdmin{
        require(admin == msg.sender, "Marketplace:Caller is not an admin");
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
        uint256 _endTime) external {
        
        require(
            _assetType == AssetType.ERC721 || _assetType == AssetType.ERC1155,
            "Only ERC721/ERC1155 are supported"
        );
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

    function buy(uint256 _tokenId, uint _numOfCopies,address _itemOwner, address _contractAddress) external payable returns(bool){
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
            require(msg.value == _listings[_contractAddress][_tokenId][_itemOwner].price*1, "buy: not enough fund");
        } else if(_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC1155) {
            require(
                IERC1155(_contractAddress).balanceOf(_itemOwner, _tokenId) >= _listings[_contractAddress][_tokenId][_itemOwner].numOfCopies,
                " buy: Insufficient Copies to buy"
            );
            require(
                _listings[_contractAddress][_tokenId][_itemOwner].numOfCopies>=_numOfCopies,
                " buy: Insufficient Copies to buy"
            );
            require(msg.value == _numOfCopies * _listings[_contractAddress][_tokenId][_itemOwner].price, "buy: not enough fund");
        }
        //safeTransferFrom
        uint copiesLeft = 0;
        if (_listings[_contractAddress][_tokenId][_itemOwner].assetType == AssetType.ERC721) {
            IERC721(_contractAddress).safeTransferFrom(_itemOwner, msg.sender, _tokenId);
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
        uint256 _amount = _outstandingPayments[_itemOwner];
        if (!payable(_itemOwner).send(_amount)) {
            _outstandingPayments[_itemOwner] = _amount;
            return false;
        }
        emit PurchaseConfirmed(_tokenId, _itemOwner, msg.sender);
        return true;
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
}
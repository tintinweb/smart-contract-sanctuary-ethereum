// SPDX-License-Identifier: Apache-2.0
// 0.7.6
pragma solidity >=0.6.0 <0.8.0;
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./FeeManager.sol";

interface IMarketplace {

    struct Order {
        // Order ID
        bytes32 id;
        // Owner of the NFT
        address payable seller;
        // NFT registry address
        address nftAddress;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
        // Creator
        address creator;
        // royal fee
        uint royalFee;
    }

    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address
        address payable bidder;
        // Price for the bid in wei
        uint256 price;
        // Time when this bid ends
        uint256 expiresAt;
    }

    // ORDER EVENTS
    event OrderCreated(
        bytes32 id,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed assetId,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event OrderUpdated(
        bytes32 id,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event OrderSuccessful(
        bytes32 id,
        address indexed buyer,
        uint256 priceInWei
    );

    event OrderCancelled(bytes32 id);

    // BID EVENTS
    event BidCreated(
        bytes32 id,
        address indexed nftAddress,
        uint256 indexed assetId,
        address indexed bidder,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
}

contract EssentialMarketplace is Pausable, FeeManager, IMarketplace, ERC721Holder, ReentrancyGuard {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // IERC20 public acceptedToken;
    // address payable public owner;

    // From ERC721 registry assetId to Order (to avoid asset collision)
    mapping(address => mapping(uint256 => Order)) public orderByAssetId;

    // From ERC721 registry assetId to Bid (to avoid asset collision)
    mapping(address => mapping(uint256 => Bid)) public bidByOrderId;

    // 721 Interfaces
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    address public validator;
    address public adminAddress;
    uint256 public sellFee;

    modifier checkSigner(bytes memory _signature, address _creator, uint _royalFee) {
        bytes32 _hash = keccak256(abi.encodePacked(_creator, msg.sender, address(this), _royalFee)).toEthSignedMessageHash();
        require(_hash.recover(_signature) == validator, "Marketplace: !verify");
        _;
    }

    event ChangeValidator(address indexed _validator);
    /**
     * @dev Initialize this contract. Acts as a constructor
     */
    constructor() {
        adminAddress = msg.sender;
        validator = msg.sender;
        sellFee = 25000; // 2.5%
    }

    /**
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) external onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    function setSellFee(uint256 fee) external onlyOwner {
        sellFee = fee;
    }

    function setAdmin(address admin) external onlyOwner {
        adminAddress = admin;
    }

    function checkSign(bytes memory _signature, address _creator, uint _royalFee) public view returns(address){
        bytes32 _hash = keccak256(abi.encodePacked(_creator, msg.sender, address(this), _royalFee)).toEthSignedMessageHash();
        return _hash.recover(_signature);
    }

    function setValidator(address _validator) external onlyOwner {
        require(_validator != address(0) && !_validator.isContract(), "Marketplace: invalid address");
        validator = _validator;
        emit ChangeValidator(validator);
    }

    /**
     * @dev Creates a new order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _priceInWei - Price in Wei for the supported coin
     * @param _expiresAt - Duration of the order (in hours)
     */
    function createOrder(address _nftAddress, uint256 _assetId, uint256 _priceInWei, uint256 _expiresAt, address _creator, uint _royalFee, bytes memory _signature) external whenNotPaused checkSigner(_signature, _creator, _royalFee) {
        _createOrder(_nftAddress, _assetId, _priceInWei, _expiresAt, _creator, _royalFee);
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function cancelOrder(address _nftAddress, uint256 _assetId) external whenNotPaused {
        Order memory order = orderByAssetId[_nftAddress][_assetId];

        require(order.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");

        // Remove pending bid if any
        Bid memory bid = bidByOrderId[_nftAddress][_assetId];

        if (bid.id != 0) {
            _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
        }

        // Cancel order.
        _cancelOrder(order.id, _nftAddress, _assetId, order.seller);
    }

    /**
     * @dev Update an already published order
     *  can only be updated by seller
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function updateOrder(address _nftAddress, uint256 _assetId, uint256 _priceInWei, uint256 _expiresAt)
    external whenNotPaused {
        Order storage order = orderByAssetId[_nftAddress][_assetId];

        // Check valid order to update
        require(order.id != 0, "Marketplace: asset not published");
        require(order.seller == msg.sender, "Marketplace: sender not allowed");
        require(order.expiresAt >= block.timestamp, "Marketplace: order expired");

        // check order updated params
        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");
        require(_expiresAt > block.timestamp.add(1 minutes), "Marketplace: Expire time should be more than 1 minute in the future");

        order.price = _priceInWei;
        order.expiresAt = _expiresAt;

        emit OrderUpdated(order.id, _priceInWei, _expiresAt);
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function safeExecuteOrder(address _nftAddress, uint256 _assetId) external payable whenNotPaused {
        // Get the current valid order for the asset or fail
        Order memory order = _getValidOrder(_nftAddress, _assetId);

        /// Check the execution price matches the order price
        require(order.price == msg.value, "Marketplace: invalid price");
        require(order.seller != msg.sender, "Marketplace: unauthorized sender");

        // market fee to cut
        uint256 saleShareAmount = 0;
        uint256 royalFeeShareAmount = 0;
        uint256 feeAmount = 0;


        // Send market fees to owner

        if (cutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = (msg.value).mul(cutPerMillion).div(1e6);

            // Transfer share amount for marketplace Owner
            payable(owner()).transfer(saleShareAmount);
            // acceptedToken.safeTransferFrom(msg.sender,owner(),saleShareAmount);
        }

        if (order.creator != address(0) && order.royalFee > 0) {
            // Calculate sale share
            royalFeeShareAmount = (msg.value).mul(order.royalFee).div(PERCENTAGE);
            // Transfer share amount for marketplace Owner
            // acceptedToken.safeTransferFrom(msg.sender,owner(),saleShareAmount);
            payable(order.creator).transfer(royalFeeShareAmount);
        }
        if(sellFee > 0)
        {
            feeAmount = (msg.value).mul(sellFee).div(PERCENTAGE);
            payable(adminAddress).transfer(feeAmount);
        }

        // Transfer token amount minus market fee to seller
        order.seller.transfer(order.price.sub(saleShareAmount).sub(royalFeeShareAmount).sub(feeAmount));

        // acceptedToken.safeTransferFrom(msg.sender, order.seller, order.price.sub(saleShareAmount));

        // Remove pending bid if any
        Bid memory bid = bidByOrderId[_nftAddress][_assetId];

        if (bid.id != 0) {
            _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
        }

        _executeOrder(order.id, msg.sender, _nftAddress, _assetId, order.price);
    }

    /**
     * @dev Places a bid for a published NFT
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _expiresAt - Bid expiration time
     */
    function safePlaceBid(address _nftAddress, uint256 _assetId, uint256 _expiresAt)
    external payable whenNotPaused nonReentrant {
        //
        // require(
        //     _priceInWei == msg.value,
        //     "Marketplace: bid price value should be same as parameter"
        // );
        _createBid(_nftAddress, _assetId, msg.value, _expiresAt);
    }

    /**
     * @dev Cancel an already published bid
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function cancelBid(address _nftAddress, uint256 _assetId) external whenNotPaused {
        Bid memory bid = bidByOrderId[_nftAddress][_assetId];

        require(bid.bidder == msg.sender, "Marketplace: Unauthorized sender");

        _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
    }

    /**
     * @dev Executes the sale for a published NFT by accepting a current bid
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _priceInWei - Bid price in wei in acceptedTokens currency
     */
    function acceptBid(address _nftAddress, uint256 _assetId, uint256 _priceInWei) external whenNotPaused {
        // check order validity
        Order memory order = _getValidOrder(_nftAddress, _assetId);

        // item seller is the only allowed to accept a bid
        require(order.seller == msg.sender, "Marketplace: unauthorized sender");

        Bid memory bid = bidByOrderId[_nftAddress][_assetId];

        require(bid.price == _priceInWei, "Marketplace: invalid bid price");
        require(bid.expiresAt >= block.timestamp, "Marketplace: the bid expired");

        // remove bid
        delete bidByOrderId[_nftAddress][_assetId];

        emit BidAccepted(bid.id);

        // market fee to cut
        uint256 saleShareAmount = 0;

        // royalfee
        uint256 royalFeeShareAmount = 0;

        // Send market fees to owner

        if (cutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = bid.price.mul(cutPerMillion).div(PERCENTAGE);
            // Transfer share amount for marketplace Owner
            // acceptedToken.safeTransferFrom(msg.sender,owner(),saleShareAmount);
            payable(owner()).transfer(saleShareAmount);
        }

        if (order.creator != address(0) && order.royalFee > 0) {
            // Calculate sale share
            royalFeeShareAmount = bid.price.mul(order.royalFee).div(PERCENTAGE);
            // Transfer share amount for marketplace Owner
            // acceptedToken.safeTransferFrom(msg.sender,owner(),saleShareAmount);
            payable(order.creator).transfer(royalFeeShareAmount);
        }

        // transfer escrowed bid amount minus market fee to seller
        // acceptedToken.safeTransfer(order.seller,bid.price.sub(saleShareAmount));
        order.seller.transfer(bid.price.sub(saleShareAmount).sub(royalFeeShareAmount));


        _executeOrder(order.id, bid.bidder, _nftAddress, _assetId, _priceInWei);
    }

    /**
     * @dev Internal function gets Order by nftRegistry and assetId. Checks for the order validity
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function _getValidOrder(address _nftAddress, uint256 _assetId) internal view returns (Order memory order) {
        order = orderByAssetId[_nftAddress][_assetId];

        require(order.id != 0, "Marketplace: asset not published");
        require(order.expiresAt >= block.timestamp, "Marketplace: order expired");
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param _orderId - Order Id to execute
     * @param _buyer - address
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - NFT id
     * @param _priceInWei - Order price
     */
    function _executeOrder(bytes32 _orderId, address _buyer, address _nftAddress, uint256 _assetId, uint256 _priceInWei) internal {
        // remove order
        delete orderByAssetId[_nftAddress][_assetId];

        // Transfer NFT asset
        IERC721(_nftAddress).safeTransferFrom(address(this), _buyer, _assetId);

        // Notify ..
        emit OrderSuccessful(_orderId, _buyer, _priceInWei);
    }

    /**
     * @dev Creates a new order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _priceInWei - Price in Wei for the supported coin
     * @param _expiresAt - Expiration time for the order
     */
    function _createOrder(address _nftAddress, uint256 _assetId, uint256 _priceInWei, uint256 _expiresAt, address _creator, uint _royalFee) internal {
        // Check nft registry
        IERC721 nftRegistry = _requireERC721(_nftAddress);

        // Check order creator is the asset owner
        address assetOwner = nftRegistry.ownerOf(_assetId);

        require(
            assetOwner == msg.sender,
            "Marketplace: Only the asset owner can create orders"
        );

        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");

        require(
            _expiresAt > block.timestamp.add(1 minutes),
            "Marketplace: Publication should be more than 1 minute in the future"
        );

        require(_royalFee < maxCutPerMillion, "Marketplace: Royal fee must be < 100%");

        // get NFT asset from seller
        nftRegistry.safeTransferFrom(assetOwner, address(this), _assetId);

        // create the orderId
        bytes32 orderId = keccak256(abi.encodePacked(block.timestamp, assetOwner, _nftAddress, _assetId, _priceInWei));

        // save order
        orderByAssetId[_nftAddress][_assetId] = Order({
        id : orderId,
        seller : payable(assetOwner),
        nftAddress : _nftAddress,
        price : _priceInWei,
        expiresAt : _expiresAt,
        creator : _creator,
        royalFee : _royalFee
        });

        emit OrderCreated(orderId, assetOwner, _nftAddress, _assetId, _priceInWei, _expiresAt);
    }

    /**
     * @dev Creates a new bid on a existing order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _priceInWei - Price in Wei for the supported coin
     * @param _expiresAt - expires time
     */
    function _createBid(address _nftAddress, uint256 _assetId, uint256 _priceInWei, uint256 _expiresAt) internal {
        // Checks order validity
        Order memory order = _getValidOrder(_nftAddress, _assetId);

        // check on expire time
        if (_expiresAt > order.expiresAt) {
            _expiresAt = order.expiresAt;
        }

        // Check price if there's a previous bid
        Bid memory bid = bidByOrderId[_nftAddress][_assetId];

        // if theres no previous bid, just check price > 0
        if (bid.id != 0) {
            if (bid.expiresAt >= block.timestamp) {
                require(
                    _priceInWei > bid.price,
                    "Marketplace: bid price should be higher than last bid"
                );

            } else {
                require(_priceInWei > 0, "Marketplace: bid should be > 0");
            }

            _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);

        } else {
            require(_priceInWei > 0, "Marketplace: bid should be > 0");
        }

        // Transfer sale amount from bidder to escrow
        // acceptedToken.safeTransferFrom(msg.sender, address(this), _priceInWei);

        // Create bid
        bytes32 bidId = keccak256(abi.encodePacked(block.timestamp, msg.sender, order.id, _priceInWei, _expiresAt));

        // Save Bid for this order
        bidByOrderId[_nftAddress][_assetId] = Bid({
        id : bidId,
        bidder : msg.sender,
        price : _priceInWei,
        expiresAt : _expiresAt
        });

        emit BidCreated(bidId, _nftAddress, _assetId, msg.sender, _priceInWei, _expiresAt);
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _orderId - Bid identifier
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _seller - Address
     */
    function _cancelOrder(bytes32 _orderId, address _nftAddress, uint256 _assetId, address _seller) internal {
        delete orderByAssetId[_nftAddress][_assetId];

        /// send asset back to seller
        IERC721(_nftAddress).safeTransferFrom(address(this), _seller, _assetId);

        emit OrderCancelled(_orderId);
    }

    /**
     * @dev Cancel bid from an already published order
     *  can only be canceled by seller or the contract owner
     * @param _bidId - Bid identifier
     * @param _nftAddress - registry address
     * @param _assetId - ID of the published NFT
     * @param _bidder - Address
     * @param _escrowAmount - in acceptenToken currency
     */
    function _cancelBid(bytes32 _bidId, address _nftAddress, uint256 _assetId, address payable _bidder, uint256 _escrowAmount) internal {
        delete bidByOrderId[_nftAddress][_assetId];

        // return escrow to canceled bidder
        _bidder.transfer(_escrowAmount);
        // acceptedToken.safeTransfer(_bidder, _escrowAmount);

        emit BidCancelled(_bidId);
    }

    function _requireERC721(address _nftAddress) internal view returns (IERC721) {
        require(
            _nftAddress.isContract(),
            "The NFT Address should be a contract"
        );
        require(
            IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
            "The NFT contract has an invalid ERC721 implementation"
        );
        return IERC721(_nftAddress);
    }

    function verifySignature(bytes memory _signature, address _sender, address _creator, uint _royalFee) external view returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(_creator, _sender, address(this), _royalFee)).toEthSignedMessageHash();
        return _hash.recover(_signature) == validator;
    }

}
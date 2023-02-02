// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OriginMarketPlace is
    ERC1155Receiver,
    IERC721Receiver,
    ReentrancyGuard,
    Ownable
{
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _createdTokenIds;
    Counters.Counter private _offeringIds;
    Counters.Counter private _itemsSold;
    address private operator;
    address private serviceWallet;


    uint256 public serviceFee = 4.98 * 10 ** 17; // 0.498 %
    uint256 constant ROYALTY_MAX = 100 * 10 ** 18; // 10%

    constructor(
        address _operator,
        address _serviceWallet
    ) {
        require(_operator != address(0), 'Operator address cannot be the zero address');
        require(_serviceWallet != address(0), 'Service Wallet address cannot be the zero address');

        operator = _operator;
        serviceWallet = _serviceWallet;
    }

    /**  STRUCT START */
    struct CreateToken {
        address nftContract;
        uint256 tokenId;
        address owner;
        uint256 price;
        address RoyaltyAddress;
        uint RoyaltyPercentage;
        uint startDate;
        uint endDate;
        bool currentlyListed;
        bool createdByMarketpalce;
    }

    struct CreateOffering {
        uint256 nonce;
        bytes32 generatedABI;
        address offerer; // Oferrer
        uint256 listingID;
        address nftAddress; // Address of the NFT Collection contract
        uint256 tokenId;
        uint256 bidPrice; // Current highest bid for the auction
        uint256 startBlock; // Start block is always the time of bidding
        uint256 endBlock;
        address paymentToken;
    }

    /**  STRUCT END */

    /**  EVENTS START */
     event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 currentTokenID
    );

    event ListedItemUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event OfferingPlaced(
        uint256 nonce,
        bytes32 indexed offeringId,
        address indexed nftAddress,
        address indexed offerer,
        uint256 tokenId,
        uint price,
        uint256 startBlock,
        uint256 endBlock,
        address paymentToken
    );
    event SetNFTAddress(address _sender, address _nftAddress);
    event OfferingCancelled(uint indexed _nonce);
    event OfferingClosed(uint indexed _nonce, address indexed _buyer);
    event ServiceFeeUpdated(uint256 _feePrice);
    event SetOperator(address _operatorAddress);
    event TokenCreated(
        string _tokenURI,
        uint256 _tokenId,
        address _ownerAddress
    );
    event TokenOfferingsRemovedFor(address _tokenAddress, uint256 _tokenId);
    event TokenTransfered(uint256 _tokenId, address _from, address _to);
    /**  EVENTS START */

    /**  MAPPING START */
    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => CreateToken) private idToListedToken;
    mapping(bytes32 => CreateOffering) private offeringRegistry;
    mapping(uint256 => CreateOffering) private offerersData;
    /**  MAPPING END */

    /**  MODIFIERS END */
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        require(
            !idToListedToken[tokenId].currentlyListed,
            "Token is already listed"
        );
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        require(
            idToListedToken[tokenId].currentlyListed,
            "Can not proceed: Token is not listed"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            msg.sender == operator,
            "Only operator is able to use the method"
        );
        _;
    }

    /**  MODIFIERS END */

    function updateServiceFee(uint256 _feePrice) external onlyOwner {
        serviceFee = _feePrice;
        emit ServiceFeeUpdated(_feePrice);
    }

    function setOperator(address _operatorAddress) external onlyOwner {
        operator = _operatorAddress;
        emit SetOperator(_operatorAddress);
    }

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyAddress,
        uint256 royaltyPercentage,
        uint startDate,
        uint endDate
    ) external nonReentrant {
        require(
            startDate >= block.timestamp,
            "Start Date can not be smaller or equal to now"
        );
        require(
            startDate <= endDate,
            "End Date can not be smaller or equal to now"
        );
        require(royaltyPercentage <= ROYALTY_MAX, "Royalty percentage is greater than marketplace accepts");
        IERC1155 nft = IERC1155(nftAddress);

        if (nft.supportsInterface(0xd9b67a26) == true) {
            require(nft.balanceOf(msg.sender, tokenId) > 0, "You are not the owner of this NFT");
            require(
                nft.isApprovedForAll(msg.sender, address(this)),
                "NFT is not approved for sale"
            );
        }

        IERC721 nft721 = IERC721(nftAddress);
        if (nft721.supportsInterface(0x80ac58cd) == true) {
            require(nft721.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
            require(
                nft.isApprovedForAll(msg.sender, address(this)),
                "NFT is not approved for sale"
            );
        }

        require(nft.supportsInterface(0xd9b67a26) == true || nft721.supportsInterface(0x80ac58cd) == true, "Forbidden NFT Contract Interface");

        _tokenIds.increment();
        uint256 currentTokenID = _tokenIds.current();

        idToListedToken[currentTokenID] = CreateToken(
            nftAddress,
            tokenId,
            payable(msg.sender),
            price,
            royaltyAddress,
            royaltyPercentage,
            startDate,
            endDate,
            true,
            false
        );

        emit ItemListed(msg.sender, nftAddress, tokenId, price, currentTokenID);
    }

    function executeSale(
        address _nftAddress,
        uint256 _tokenId
    ) external payable isListed(_nftAddress, _tokenId) nonReentrant {
        require(
            block.timestamp < idToListedToken[_tokenId].endDate,
            "Listing has ended"
        );
        require(
            block.timestamp > idToListedToken[_tokenId].startDate,
            "Listing has not started yet"
        );
        require(msg.value == idToListedToken[_tokenId].price, "Price not met");

        bool isTokenTransferSuccess = _customTransfer(
            idToListedToken[_tokenId].owner,
            msg.sender,
            _nftAddress,
            idToListedToken[_tokenId].tokenId
        );
        require(isTokenTransferSuccess, "Transfer failed.");
        
        _itemsSold.increment();
        uint256 fee;
        uint256 userReceipt = 0;

        if (serviceFee > 0 && serviceWallet != address(0)) {
            fee = (msg.value * serviceFee) / ROYALTY_MAX;
            userReceipt += fee;
            (bool success, ) = payable(serviceWallet).call{value: fee}("");
            require(success, "Transfer failed.");
        }

        if (
            idToListedToken[_tokenId].RoyaltyPercentage > 0 &&
            idToListedToken[_tokenId].RoyaltyAddress != address(0)
        ) {
            fee =
                (msg.value * idToListedToken[_tokenId].RoyaltyPercentage) /
                ROYALTY_MAX;
            if (fee > 0) {
                userReceipt += fee;
                (bool isRoyaltySent, ) = payable(
                    idToListedToken[_tokenId].RoyaltyAddress
                ).call{value: fee}("");
                require(isRoyaltySent, "Transfer failed.");
            }
        }

        require(msg.value >= userReceipt, "invalid royalty or service fee");
        userReceipt = msg.value - userReceipt;

        if (userReceipt > 0) {
            (bool isSuccess, ) = payable(idToListedToken[_tokenId].owner).call{
                value: userReceipt
            }("");
            require(isSuccess, "Transfer failed.");
        }

        emit ItemBought(
            msg.sender,
            _nftAddress,
            _tokenId,
            idToListedToken[_tokenId].price
        );
         delete (idToListedToken[_tokenId]);
    }

    function operatorCancellation(
        address _nftAddress,
        uint256 _tokenId
    ) external isListed(_nftAddress, _tokenId) onlyOperator nonReentrant {
        delete (idToListedToken[_tokenId]);
        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    function cancelListing(
        address _nftAddress,
        uint256 _tokenId
    ) external isListed(_nftAddress, _tokenId) {
        delete (idToListedToken[_tokenId]);
        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 newPrice
    ) external isListed(_nftAddress, _tokenId) nonReentrant {
        require(newPrice >= 0, "Price must be equal or above zero");

        idToListedToken[_tokenId].price = newPrice;
        emit ListedItemUpdated(msg.sender, _nftAddress, _tokenId, newPrice);
    }

    function _customTransfer(
        address _sender,
        address _receiver,
        address _nftAddress,
        uint256 _tokenId
    ) private returns (bool success) {
        // Get NFT collection contract
        IERC1155 nft = IERC1155(_nftAddress);
        if (nft.supportsInterface(0xd9b67a26) == true) {
            require(
                nft.balanceOf(_sender, _tokenId) != 0,
                "Caller is not the owner of the NFT"
            );
            nft.safeTransferFrom(_sender, _receiver, _tokenId, 1, "");
            emit TokenTransfered(_tokenId, _sender, _receiver);
            return true;
        }

        IERC721 nft721 = IERC721(_nftAddress);
        if (nft721.supportsInterface(0x80ac58cd) == true) {
            // Make sure the sender that wants to create a new auction
            // for a specific NFT is the owner of this NFT
            require(
                nft721.ownerOf(_tokenId) == _sender,
                "Caller is not the owner of the NFT"
            );
            nft721.safeTransferFrom(_sender, _receiver, _tokenId);
            emit TokenTransfered(_tokenId, _sender, _receiver);
            return true;
        }
    }

    function placeOffer(
        uint256 listingID,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 startBlock,
        uint256 endBlock,
        address _paymentToken
    ) external nonReentrant {
        require(_paymentToken != address(0), "Invalid payment token address");
        require(
            idToListedToken[listingID].currentlyListed,
            "The offer is not allowed for not listed items"
        );

        require(
            startBlock <= endBlock,
            "Offering Time Must be greater than NOW"
        );

        _offeringIds.increment();
        uint256 nonce = _offeringIds.current();
        bytes32 generatedABI = keccak256(
            abi.encodePacked(nonce, nftAddress, tokenId)
        );

        offerersData[nonce] = CreateOffering(
            nonce,
            generatedABI,
            msg.sender,
            listingID,
            nftAddress,
            tokenId,
            price,
            startBlock,
            endBlock,
           _paymentToken
        );

        emit OfferingPlaced(
            nonce,
            generatedABI,
            nftAddress,
            msg.sender,
            tokenId,
            price,
            startBlock,
            endBlock,
            _paymentToken
        );
    }


    function cancelOffer(uint _nonce) external nonReentrant {
        require(
            msg.sender == offerersData[_nonce].offerer,
            "You are not allowed to cancel the offer"
        );
        delete (offerersData[_nonce]);
        emit OfferingCancelled(_nonce);
    }

    function operatorCancelOffer(
        uint _nonce
    ) external onlyOperator nonReentrant {
        delete (offerersData[_nonce]);
        emit OfferingCancelled(_nonce);
    }

    function acceptOffer(uint _nonce, address _token) external nonReentrant {
        CreateOffering storage currentOffer = offerersData[_nonce];

        require(_token == currentOffer.paymentToken, "Payment token chosen by buyer and seller must be the same");
        require(
            idToListedToken[currentOffer.tokenId].currentlyListed,
            "Item already has been bought"
        );
        require(block.timestamp < currentOffer.endBlock, "Offer Time Exceeds");
        require(
            idToListedToken[currentOffer.tokenId].owner == msg.sender,
            "Only owner of the NFT can accept the offer"
        );

        bool isTransferSuccess = _customTransfer(
            msg.sender,
            currentOffer.offerer,
            currentOffer.nftAddress,
            idToListedToken[currentOffer.tokenId].tokenId
        );
        require(isTransferSuccess, "Transfer failed");
        uint256 fee;
        uint256 userReceipt = 0;
        IERC20 token = IERC20(_token);

        if (serviceFee > 0 && serviceWallet != address(0)) {
            fee = (currentOffer.bidPrice * serviceFee) / ROYALTY_MAX;
            userReceipt += fee;
            bool isServiceTxSuccess = token.transferFrom(
                payable(currentOffer.offerer),
                serviceWallet,
                fee
            );
            require(isServiceTxSuccess, "Transfer failed");
        }

        if (
            idToListedToken[currentOffer.tokenId].RoyaltyPercentage > 0 &&
            idToListedToken[currentOffer.tokenId].RoyaltyAddress != address(0)
        ) {
            fee =
                (currentOffer.bidPrice *
                    idToListedToken[currentOffer.tokenId].RoyaltyPercentage) /
                ROYALTY_MAX;
            if (fee > 0) {
                userReceipt += fee;
                bool isRoyaltyTxSuccess = token.transferFrom(
                    payable(currentOffer.offerer),
                    payable(
                        idToListedToken[currentOffer.tokenId].RoyaltyAddress
                    ),
                    fee
                );
                require(isRoyaltyTxSuccess, "Transfer failed");
            }
        }

        require(
            currentOffer.bidPrice >= userReceipt,
            "invalid royalty or service fee"
        );
        userReceipt = currentOffer.bidPrice - userReceipt;

        if (userReceipt > 0) {
            bool isUserTxSuccess = token.transferFrom(
                payable(currentOffer.offerer),
                payable(msg.sender),
                userReceipt
            );
            require(isUserTxSuccess, "Transfer failed");
        }
        
        delete (offerersData[_nonce]);
        delete (idToListedToken[currentOffer.tokenId]);
        emit OfferingClosed(_nonce, msg.sender);
    }

    function withDraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid withdraw amount...");
        require(address(this).balance > _amount, "None left to withdraw...");

        (bool isSuccess, ) = payable(msg.sender).call{value: _amount}("");
        require(isSuccess, "Withdraw failed.");
    }

    function withDrawAll() external onlyOwner {
        uint256 remaining = address(this).balance;
        require(remaining > 0, "None left to withdraw...");

        (bool isSuccess, ) = payable(msg.sender).call{value: remaining}("");
        require(isSuccess, "Withdraw failed.");
    }

    receive() external payable {}

    fallback() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
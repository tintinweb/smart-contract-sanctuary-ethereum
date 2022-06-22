//SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

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

/**
 * @dev Required interface of an ERC721 compliant contract.
*/

interface IERC721 is IERC165 {
    function royaltyFee(uint256 tokenId) external view returns(address[] memory, uint256[] memory);

    function getCreator(uint256 tokenId) external view returns(address);

    function contractOwner() external view returns(address owner);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function mintAndTransfer(address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, string memory _tokenURI, bytes memory data)external returns(uint256);
}

interface IERC1155 is IERC165 {
    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function royaltyFee(uint256 tokenId) external view returns(address[] memory, uint256[] memory);
    function getCreator(uint256 tokenId) external view returns(address);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function mintAndTransfer(address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, uint256 _supply, string memory _tokenURI, uint256 qty, bytes memory data)external returns(uint256);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

   

contract TransferProxy {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
    
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external  {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }   

    function erc721mintAndTransfer(IERC721 token, address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, string memory tokenURI, bytes calldata data) external {
        token.mintAndTransfer(from, to, _royaltyAddress, _royaltyfee, tokenURI, data);
    }

    function erc1155mintAndTransfer(IERC1155 token, address from, address to, address[] memory _royaltyAddress, uint256[] memory _royaltyfee, uint256 supply, string memory tokenURI, uint256 qty, bytes calldata data) external {
        token.mintAndTransfer(from, to, _royaltyAddress, _royaltyfee, supply, tokenURI, qty, data);
    }
}

contract Trade {

    enum BuyingAssetType {ERC1155, ERC721 , LazyMintERC1155, LazyMintERC721}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFeeUpdated(uint8 sellerFee);
    event SwappingFeeUpdated(uint8 swappingFee);
    event BuyerFeeUpdated(uint8 buyerFee);
    event PlatformFee(uint8 PlatformFee);
    event SwappingFee(uint8 swappingFee);
    event BuyAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    uint8 private swappingFeePermille;                                   
    TransferProxy public transferProxy;
    address public owner;

    mapping(address => mapping(bytes => uint256)) internal nftlist;
    mapping(address => mapping(bytes => bool)) internal nftListStatus;
    mapping(address => mapping(bytes => mapping (uint256 => uint256))) internal nftDetails;
    mapping(uint256 => bool) private usedNonce;
    mapping(address => Referral) private nftReferrals;
    mapping( address => mapping(address => uint256)) private lockedNFTs;
    mapping(uint256 => uint256) private lockedNFTsQty;

    struct Fee {
        uint platformFee;
        uint assetFee;
        address[] royaltyAddress;
        uint[] royaltyFee;
        uint price;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct OrderItem {
        address nftAddress;
        uint256 price;
        uint256 tokenId;
        uint256 supply;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint256 supply;
        string tokenURI;
        address[] royaltyAddress;
        uint256[] royaltyfee;
        uint qty;
        bytes _orderItems;
    }

    struct Swapping {
        address from;
        address to;
        BuyingAssetType nftType;
        address erc20Address;
        uint256 swapTokenId0;
        uint256 swapTokenId1;
        address swapnftAddress0;
        address swapnftAddress1;
        uint256 sellingQty;
        uint256 buyingQty;
        uint swapingAmount0;                         
        uint swapingAmount1;                        
    }

    struct Referral {
        address referrer;
        uint256 tokenId;
        BuyingAssetType nftType;
        address nftAddress;
        uint256 qty;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, uint8 _swappingFee, TransferProxy _transferProxy) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        swappingFeePermille = _swappingFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }
    
    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFeeUpdated(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFeeUpdated(sellerFeePermille);
        return true;
    }


    function swappingFee() external view virtual returns (uint8) {                   
        return swappingFeePermille;
    }

    function setSwappingFee(uint8 _swappingFee) external onlyOwner returns(bool) {
        swappingFeePermille = _swappingFee;
        emit SwappingFee(swappingFeePermille);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }

    function verifySign(address seller, bytes memory _orderItems, address paymentAssetAddress, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(_orderItems, paymentAssetAddress, sign.nonce));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifySellerSign(address seller, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, sign.nonce));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSign(address buyer, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, uint qty, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount,qty, sign.nonce));
        require(buyer == getSigner(hash, sign), "buyer sign verification failed");
    }

    function verifyOwnerSign(address buyingAssetAddress,address seller, string memory tokenURI, Sign memory sign) internal view {
        address _owner = IERC721(buyingAssetAddress).contractOwner();
        bytes32 hash = keccak256(abi.encodePacked(this, seller, tokenURI, sign.nonce));
        require(_owner == getSigner(hash, sign), "Owner sign verification failed");
    }

    function claimNFT(Referral memory referral, Sign calldata sign) external {
        verifySellerSign(referral.referrer, referral.tokenId, referral.qty, address(this), referral.nftAddress, sign);
        nftReferrals[msg.sender] = referral;
        if(referral.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(referral.nftAddress), address(transferProxy), msg.sender, referral.tokenId);
        }
        if(referral.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(IERC1155(referral.nftAddress), address(transferProxy), msg.sender, referral.tokenId, referral.qty, ""); 
        }
        lockedNFTsQty[referral.tokenId] = 0;
    }

    function lockNFT(address nftAddress, BuyingAssetType nftType, uint256 tokenId, uint256 qty) external {
        if(nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(nftAddress),msg.sender, address(transferProxy), tokenId);
        }
        if(nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(IERC1155(nftAddress), msg.sender, address(transferProxy), tokenId, qty, ""); 
        }
        lockedNFTs[msg.sender][nftAddress] = tokenId;
        lockedNFTsQty[tokenId] = qty;
    }

    function unlockNFT(address nftAddress, BuyingAssetType nftType, uint256 tokenId, uint256 qty, Sign calldata sign) external {
        require(lockedNFTs[msg.sender][nftAddress] == tokenId,"Refer: non-exist in locked list");
        require(lockedNFTsQty[tokenId] > 0,"Refer: token already unlocked");
        verifySellerSign(msg.sender, tokenId, qty, address(this), nftAddress, sign);
        if(nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(nftAddress), address(transferProxy), msg.sender, tokenId);
        }
        if(nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(IERC1155(nftAddress), address(transferProxy), msg.sender, tokenId, qty, ""); 
        }
        lockedNFTsQty[tokenId] = 0;
    }


    function getFees(Order memory order, bool _import) internal view returns(Fee memory){
        uint platformFee;                                                                 
        uint fee;
        address[] memory royaltyAddress;
        uint[] memory royaltyPermille;
        uint assetFee;
        uint price = order.amount * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = order.amount - price;
        uint sellerFee = price * sellerFeePermille / 1000;
        platformFee = buyerFee + sellerFee;

        if(order.nftType == BuyingAssetType.ERC721 && !_import) {
            (royaltyAddress, royaltyPermille) = ((IERC721(order.nftAddress).royaltyFee(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.ERC1155 && !_import)  {
            (royaltyAddress, royaltyPermille) = ((IERC1155(order.nftAddress).royaltyFee(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721) {
            royaltyAddress = order.royaltyAddress;
            royaltyPermille = order.royaltyfee;
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155) {
            royaltyAddress = order.royaltyAddress;
            royaltyPermille = order.royaltyfee;
        }

        uint[] memory royaltyFee =  new uint[](royaltyAddress.length);
        if(!_import) {
            for(uint i = 0; i < royaltyAddress.length; i++) {
                fee += price * royaltyPermille[i] / 1000;
                royaltyFee[i] = price * royaltyPermille[i] / 1000;
            }
        }
        assetFee = price - fee - sellerFee;
        return Fee( platformFee, assetFee, royaltyAddress, royaltyFee, price);
    }

    function swapToken(Swapping memory swapMetaData, Sign memory sign) public returns(bool) {
        uint swappingFeeForEach;
        require(swapMetaData.buyingQty == swapMetaData.sellingQty,"Swap: Qty must be equal");
        verifyBuyerSign(swapMetaData.to, swapMetaData.swapTokenId0, swapMetaData.swapTokenId1, swapMetaData.swapnftAddress0, swapMetaData.swapnftAddress1, swapMetaData.buyingQty, sign);   
        if(swapMetaData.nftType == BuyingAssetType.ERC721) {
            
            transferProxy.erc721safeTransferFrom(IERC721(swapMetaData.swapnftAddress1), swapMetaData.from, swapMetaData.to, swapMetaData.swapTokenId1);
            transferProxy.erc721safeTransferFrom(IERC721(swapMetaData.swapnftAddress0), swapMetaData.to, swapMetaData.from, swapMetaData.swapTokenId0);
        }
        if(swapMetaData.nftType == BuyingAssetType.ERC1155)  {
            
            transferProxy.erc1155safeTransferFrom(IERC1155(swapMetaData.swapnftAddress1), swapMetaData.from, swapMetaData.to, swapMetaData.swapTokenId1, swapMetaData.sellingQty, ""); 
            transferProxy.erc1155safeTransferFrom(IERC1155(swapMetaData.swapnftAddress0), swapMetaData.to, swapMetaData.from, swapMetaData.swapTokenId0, swapMetaData.buyingQty, "");
            
        }
        swappingFeeForEach = (swapMetaData.swapingAmount0 + swapMetaData.swapingAmount1) * swappingFeePermille / 1000 ;
        transferProxy.erc20safeTransferFrom(IERC20(swapMetaData.erc20Address), swapMetaData.from, owner, swappingFeeForEach);              
        transferProxy.erc20safeTransferFrom(IERC20(swapMetaData.erc20Address), swapMetaData.to, owner, swappingFeeForEach);                
        emit BuyAsset(swapMetaData.to ,swapMetaData.swapTokenId0, swapMetaData.sellingQty, swapMetaData.from);
        emit BuyAsset(swapMetaData.from , swapMetaData.swapTokenId1, swapMetaData.buyingQty, swapMetaData.to);
        return true;
        
    }

    function tradeAsset(Order calldata order, Fee memory fee, address buyer, address seller) internal virtual {
        if(order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress), seller, buyer, order.tokenId);
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {
            transferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress), seller, buyer, order.tokenId, order.qty, ""); 
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721){
            transferProxy.erc721mintAndTransfer(IERC721(order.nftAddress), order.seller, order.buyer, order.royaltyAddress, order.royaltyfee, order.tokenURI,"" );
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155){
            transferProxy.erc1155mintAndTransfer(IERC1155(order.nftAddress), order.seller, order.buyer, order.royaltyAddress, order.royaltyfee, order.supply, order.tokenURI, order.qty, "");
        }
        for(uint i = 0; i < fee.royaltyAddress.length; i++) {
            if(fee.royaltyFee[i] > 0) {
                transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, fee.royaltyAddress[i], fee.royaltyFee[i]);
            }
        }        
        if(fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, owner, fee.platformFee);
        }
        transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), buyer, seller, fee.assetFee);
       
    }

    function mintAndBuyAsset(Order calldata order, Sign calldata ownerSign, Sign calldata sign) external returns(bool){
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        require(!usedNonce[ownerSign.nonce],"Nonce : ownerSign Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;

    }

    function mintAndExecuteBid(Order calldata order, Sign calldata ownerSign, Sign calldata sign) external returns(bool){
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        require(!usedNonce[ownerSign.nonce],"Nonce : ownerSign Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require((fee.price >= order.unitPrice * order.qty), " mintAndExecutPaid invalid amount");
        verifyOwnerSign(order.nftAddress,order.seller, order.tokenURI, ownerSign);
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty,sign);
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.seller , order.tokenId, order.qty, msg.sender);
        return true;

    }

    function buyAsset(Order calldata order, bool _import, Sign calldata sign, bool isBulkListed) external returns(Fee memory) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        Fee memory fee = getFees(order, _import);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        if(isBulkListed){
            updateNonce(order, sign.nonce);
            verifySign(order.seller, order._orderItems, order.erc20Address, sign);
        } else {
            usedNonce[sign.nonce] = true;
            verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        }
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        return fee;
    }

    function executeBid(Order calldata order, bool _import, Sign calldata sign) public returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty, sign);
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(msg.sender , order.tokenId, order.qty, order.buyer);
        return true;
    }

    function updateNonce(Order memory order, uint256 nonce) internal returns(bool) {
        OrderItem[] memory orderValues = abi.decode(order._orderItems, (OrderItem[]));

        if(!(nftListStatus[order.seller][order._orderItems])) {
            nftlist[order.seller][order._orderItems] = orderValues.length;
            nftListStatus[order.seller][order._orderItems] = true;
            if(order.nftType == BuyingAssetType.ERC1155) {
                for (uint i = 0; i < orderValues.length; i++) {
                    nftDetails[order.seller][order._orderItems][orderValues[i].tokenId] = orderValues[i].supply;
                }
            }
        }

        for(uint i = 0; i < orderValues.length; i++) {
            if(order.nftType == BuyingAssetType.ERC721 && order.tokenId == orderValues[i].tokenId && order.nftAddress == orderValues[i].nftAddress) {
                nftlist[order.seller][order._orderItems] -= 1;
                if(nftlist[order.seller][order._orderItems] == 0) 
                    usedNonce[nonce] = true;
                return true;
            }
            if(order.nftType == BuyingAssetType.ERC1155 && order.tokenId == orderValues[i].tokenId && order.nftAddress == orderValues[i].nftAddress) {
                require( order.qty <= nftDetails[order.seller][order._orderItems][order.tokenId], "insufficent listing qty");
                nftDetails[order.seller][order._orderItems][order.tokenId] -= order.qty;
                if(nftDetails[order.seller][order._orderItems][order.tokenId] == 0) {
                    nftlist[order.seller][order._orderItems] -= 1;
                }
                if(nftlist[order.seller][order._orderItems] == 0) {
                    usedNonce[nonce] = true;
                }
                return true;
            }
            require(i != orderValues.length - 1, "tokenId mismatch");
        }
        return true;
    }
}
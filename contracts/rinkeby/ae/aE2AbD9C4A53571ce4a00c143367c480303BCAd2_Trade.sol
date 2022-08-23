// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

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
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
    */

    function balanceOf(address owner) external view returns (uint256 balance);
    
    

    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

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

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */

    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

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

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
    */

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);


    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */

    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
    */

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */

    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
    */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
    */

    function approve(address spender, uint256 amount) external returns (bool);

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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
}

contract Trade {

    // enum BuyingAssetType {ERC1155, ERC721}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    // event ExecuteBid(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    address payable public owner;
    mapping(uint256 => bool) private usedNonce;

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
        uint[] charitiesFee;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        // BuyingAssetType nftType;
        bool nftType; 
        bool isImported;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint qty;
    }

    struct Charity {
        address chariter;
        uint8 charityPermille;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, address _transferProxy) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = ITransferProxy(_transferProxy);
        owner = payable(msg.sender);
    }

    function buyerServiceFee() external view returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        require(_buyerFee <= 25,"Fee: buyerFee should be less than or equal to 2.5%");
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        require(_sellerFee <= 25,"Fee: sellerFee should be less than or equal to 2.5%");
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = payable(newOwner);
        return true;
    }

    function getSigner(bytes32 hash, Sign calldata sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    function verifySellerSign(address buyer, uint256 tokenId, uint amount, address assetAddress, Sign calldata sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress,tokenId,buyer,amount));
        require(buyer == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSign(address seller, uint256 tokenId, uint amount, address assetAddress, Sign calldata sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress,tokenId,seller,amount));
        require(seller == getSigner(hash, sign), "buyer sign verification failed");
    }

    function getFees(uint paymentAmt, bool buyingAssetType, address buyingAssetAddress, uint tokenId, bool isImported, Charity[] calldata charities) internal view returns(Fee memory){
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint royaltyPermille;
        uint price = paymentAmt * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = paymentAmt - price;
        uint sellerFee = price * sellerFeePermille / 1000;
        uint[] memory charitiesFee = new uint[](charities.length); 
        platformFee = buyerFee + sellerFee;
        for (uint i = 0 ; i < charities.length ; i++) {
            charitiesFee[i] = price * charities[i].charityPermille / 1000;
        }
        if(buyingAssetType == false) {
        // if(buyingAssetType == ) {
            royaltyPermille = ((IERC721(buyingAssetAddress).royaltyFee(tokenId)));
            tokenCreator = ((IERC721(buyingAssetAddress).getCreator(tokenId)));
        }
        if(buyingAssetType == true && !isImported) {
        // if(buyingAssetType == 1 && !isImported) {
            royaltyPermille = ((IERC1155(buyingAssetAddress).royaltyFee(tokenId)));
            tokenCreator = ((IERC1155(buyingAssetAddress).getCreator(tokenId)));
        }
        royaltyFee = price * royaltyPermille / 1000;
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator, charitiesFee);
    }

    function tradeAsset(Order calldata order, Fee memory fee, address buyer, address seller, Charity[] calldata charities) internal virtual {
        if(order.nftType == false) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress), seller, buyer, order.tokenId);
        }
        if(order.nftType == true)  {
            transferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress), seller, buyer, order.tokenId, order.qty, ""); 
        }
        if(fee.platformFee > 0) {
            owner.transfer(fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            address payable tokenCreator = payable(fee.tokenCreator);
            tokenCreator.transfer(fee.royaltyFee);
        }
        for (uint i = 0 ; i < charities.length ; i++) {
            address payable charityAddress = payable(charities[i].chariter);
            charityAddress.transfer(fee.charitiesFee[i]);
        }
        address payable sellerAddress = payable(seller);
        sellerAddress.transfer(fee.assetFee);
    }

    function buyAsset(Order calldata order, Sign calldata sign, Charity[] calldata charities) external payable returns(bool) {
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order.amount, order.nftType, order.nftAddress, order.tokenId, order.isImported, charities);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifyBuyerSign(order.seller, order.tokenId, order.unitPrice, order.nftAddress, sign);
        tradeAsset(order, fee, order.buyer, order.seller, charities);
        emit BuyAsset(order.seller, order.tokenId, order.qty, order.buyer);
        return true;
    }

    // function executeBid(Order calldata order, Sign calldata sign) external returns(bool) {
    //     usedNonce[sign.nonce] = true;
    //     Fee memory fee = getFees(order.amount, order.nftType, order.nftAddress, order.tokenId, order.isImported);
    //     verifySellerSign(order.buyer, order.tokenId, order.amount, order.nftAddress, sign);
    //     tradeAsset(order, fee, order.buyer, order.seller);
    //     emit ExecuteBid(order.seller , order.tokenId, order.qty, order.buyer);
    //     return true;
    // }
}
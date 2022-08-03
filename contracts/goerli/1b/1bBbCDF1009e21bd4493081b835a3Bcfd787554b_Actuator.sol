/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function permit(address sender,address operator,bool approved,uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function permit(address sender,address operator,bool approved,uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IRoyaltyManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

library TransferHelper {
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}

contract Synchron{
    /**
    * @notice Administrator for this contract
    */
    address public admin;
    /**
    * @notice Active brains of Knowhere
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Knowhere
    */
    address public pendingComptrollerImplementation;

}

contract SynchronV1 is Synchron{

    enum OptionType{
        FIXED_OPTION,
        AUCTION_OPTION
    }

    enum OptionState{
        SOLDING,
        SALED,
        CANCELED,
        NUL
    }

    enum OfferState{
        EFFECTIVE,
        INVALID   
    }

    struct OptionParam{ 
        OptionType optionType;
        address token;
        uint256 identifier;
        uint256 amount;
        address creator;
        uint256 singlePrice;
        uint256 expectPrice;
        uint256 startTime;
        uint256 endTime;
    }
    //["0","0x746BC4ff6f350981685C9ca4a2d5A584cD185f56","1111","1","0x3024a5c0870dde2b65ddDd1BFC139f94941EDCAC","100000","0","0","1659074400"]
    //
    struct Option{
        OptionParam optionParam;
        OptionState state;
    }

    struct OfferParam{
        address bidder;
        uint256 price;
    }

    struct Offer{
        OfferParam offerParam;
        OfferState state;
    }

    mapping(uint256 => Option) public optionInfo;
    mapping(uint256 => Offer) public offerInfo;
    mapping(uint256 => uint) public offerIndex;

    mapping(uint256 => uint256[]) public optionCorrespondingOffer;
    mapping(uint256 => uint256) public offerCorrespondingOption;

    uint256 public initOptionNumber;

    uint256 initOfferNumber;
    /**
    * @notice Royalty management contract
    */
    address royaltyManager;
    /**
    * @notice WETH contract address
    */
    address public WETH;
    /**
    * @notice Nft transfer selector address
    */
    address transferSelector;
    /**
    * @notice Market fee receiving address
    */
    address marketFeeRecipient;
    /**
    * @notice Fixed price order exchange rate
    */
    uint256 marketFeeToFixed;
    /**
    * @notice Auction option exchange rate
    */
    uint256 marketFeeToAuction;
    /**
    * @notice IERC1155 protocol support switch
    */
    bool    isAuctionSupport1155;

}

contract KnowhereProxy is Synchron{

    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    event NewImplementation(address oldImplementation, address newImplementation);
    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public  {
        
        require(admin == msg.sender,"KnowhereProxy:not permit");

        address oldPendingImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

    }

    function _acceptImplementation() public returns(uint){

        require(pendingComptrollerImplementation == msg.sender && pendingComptrollerImplementation != address(0));

        // Save current values for inclusion in log
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;

        comptrollerImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = address(0);

        emit NewImplementation(oldImplementation, comptrollerImplementation);

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return 0;
    }

    function _updateAdmin(address _admin) public {
        require(admin == msg.sender,"KnowhereProxy:not permit");
        admin = _admin;
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

}


contract Actuator is SynchronV1{
    /**
     * @notice Emitted when option is created
    */
    event Created(address indexed creator,uint256 optionId,uint256 indexed crateTime);
    /**
     * @notice Emitted when option was successfully purchased
    */
    event Purchase(address purchase,uint256 price,uint256 indexed optionId,uint256 indexed purchaseTime);
    /**
     * @notice Emitted when option cancelled
    */
    event CancelOption(uint256 optionId,address indexed operator,uint256 indexed cancelTime);
    /**
     * @notice Emitted when unit price in the option is modified
    */
    event ModifyPrice(address indexed operator,uint256 singlePrice,uint256 optionId,uint256 indexed modifyTime);
    /**
     * @notice Emitted when creating new bidding information
    */
    event Bidding(address indexed bidder,uint256 optionId,uint256 offerId,uint256 price,uint256 indexed biddingTime);
    /**
     * @notice Emitted when canceling existing bidding information
    */
    event CancelBidding(address indexed operator,uint256 optionId,uint256 offerId,uint256 indexed biddingTime);
    /**
     * @notice Emitted when delivery occurs after the auction option is completed
    */
    event Delivery(uint256 indexed optionId,uint256 offerId,address receiver,uint256 deliveryPrice,uint256 indexed deliveryTime);
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Actuator:not permit");
        _;
    }
    //0xc778417E063141139Fce010982780140Aa0cD5Ab
    function initializeStorage(address _royaltyManager,address _WETH) public onlyOwner{
        require(initOfferNumber == 0,"Actuator:Duplicate initialization is not allowed");
        royaltyManager = _royaltyManager;
        WETH = _WETH;
        admin = msg.sender;
        initOfferNumber = 1;
    }

    function updateMarketFee(address _recipent,uint256 _fixed,uint256 _auction) external onlyOwner{
        marketFeeRecipient = _recipent;
        marketFeeToFixed  = _fixed;
        marketFeeToAuction = _auction;
    }

    function permit1155ToAuction(bool isSupport) external onlyOwner{
        isAuctionSupport1155 = isSupport;
    }
    /**
      * @notice The option id is preset to verify the validity of order parameters
      * @dev Public method for creating NFT orders on the chain
      * @param optionParam Option param is transferred in the form of structure.
      */
    function createOption(OptionParam calldata optionParam) public returns(uint256 optionId){
        //Initialize option id
        optionId = initOptionNumber;
        //Decide whether to reject the IERC1155 agreement to release the auction order according to the switch
        if(isAuctionSupport1155 == false && IERC165(optionParam.token).supportsInterface(0xd9b67a26) != false && 
            optionParam.optionType == OptionType.AUCTION_OPTION)
            revert("Auction orders are not supported yet"); 
        //Judge the rationality of price and time interval
        require(optionParam.singlePrice > 0 && optionParam.startTime < optionParam.endTime && optionParam.amount >0,"Actuator:Revenue data error");
        //Judge whether the user has sufficient assets for sale
        (uint256 holdQuantity,bool authorize) = whetherSufficientNFTForSale(optionParam.token, optionParam.identifier,msg.sender);
        require(holdQuantity >= optionParam.amount && optionParam.creator == msg.sender && authorize != false,"Actuator:There are asset management risks");
        //Store order related information
        optionInfo[optionId] = Option(optionParam,OptionState.SOLDING);
        initOptionNumber++;
        emit Created(msg.sender, optionId, block.timestamp);
    }

    function createOptionWithPermit(OptionParam calldata optionParam,uint deadline,uint8 v, bytes32 r, bytes32 s) external returns(uint256 optionId){
        (,bool authorize) = whetherSufficientNFTForSale(optionParam.token, optionParam.identifier,msg.sender);
        if(authorize != true){
            IERC721(optionParam.token).permit(msg.sender, address(this), true, deadline, v, r, s);
        }
        optionId = createOption(optionParam);
        //判断是否需要签名或授权
        //调用createOption
    }

    /**
      * @notice Verify the legitimacy of the option and help the buyer and the seller complete the asset exchange
      * @dev Public method for purchase of fixed price options
      * @param optionId Require incoming option number.
      */
    function purchaseFixedOption(uint256 optionId) external payable{
        //Option purchase operation compliance inspection
        Option storage option = optionInfo[optionId];
        require(option.state == OptionState.SOLDING && option.optionParam.optionType == OptionType.FIXED_OPTION,
            "Actuator:Option type and status error");
        require(option.optionParam.startTime <= block.timestamp && block.timestamp < option.optionParam.endTime,
            "Actuator:Purchase is not allowed in the current time period");
        require(msg.value >= option.optionParam.singlePrice * option.optionParam.amount,
            "Actuator:Insufficient payment amount");
        //NFTs asset deduction
        normalTransferNft(
            option.optionParam.token, 
            option.optionParam.identifier,
            option.optionParam.creator, 
            msg.sender,
            option.optionParam.amount);
        //Complete payment and option status changes
        splitIncome(optionId,msg.value);
        option.state = OptionState.SALED;
        emit Purchase(msg.sender, msg.value, optionId, block.timestamp);
    }
    /**
      * @notice Verify the legitimacy of the order and cancel the order
      * @dev Public method of canceling options
      * @param optionId Require incoming option number.
      */
    function cancelOption(uint256 optionId) external{
        Option storage option = optionInfo[optionId];
        //Check the compliance of cancellation operation, and pay attention to the bidding requirements of auction option cancellation operation
        if(option.optionParam.optionType == OptionType.AUCTION_OPTION) require(optionCorrespondingOffer[optionId].length ==0);
        require(option.optionParam.creator == msg.sender,"Actuator:No permission to cancel");
        require(option.state == OptionState.SOLDING,"Actuator:Option status error");
        option.state = OptionState.CANCELED; 
        emit CancelOption(optionId, msg.sender, block.timestamp);
    }
    /**
      * @notice Adjust the option price after verifying the modification permission
      * @dev Open method for modifying option unit price
      * @param optionId Option number of the option to be modified
      * @param single Set the unit price of the existing option to the specified value
      */
    function modifyPrice(uint256 optionId,uint256 single) external{
        Option storage option = optionInfo[optionId];
        require(option.optionParam.creator == msg.sender && option.state == OptionState.SOLDING && block.timestamp < option.optionParam.endTime, 
            "Actuator:Foundation modification conditions are not met");
        if(option.optionParam.optionType == OptionType.AUCTION_OPTION) 
            require(optionCorrespondingOffer[optionId].length ==0 && single < option.optionParam.singlePrice);
        option.optionParam.singlePrice = single;
        emit ModifyPrice(msg.sender, single, optionId, block.timestamp);
    }

    // function getEffectiveOfferPrice(uint256[] memory offerIds) public view returns(uint256 currentPrice){
    //    // uint256[] memory offerIds = optionCorrespondingOffer[optionId];
    //     uint256 result;
    //     for(uint i=0; i<offerIds.length; i++){
    //         if(offerIds[i] > 0) result = offerIds[i];
    //     }
    //     if(result > 0) currentPrice = offerInfo[result].offerParam.price;
    // }
    /**
      * @notice Verify the weth information of users and allow them to participate in the bidding of auction options
      * @dev Public method of participating in auction order auction
      * @param optionId Option number of the option to be modified
      * @param price Bid when bidding
      */
    function bidding(uint256 optionId,uint256 price) external returns(uint256 offerId){
        Option storage option = optionInfo[optionId];
        //Check the status and type of the option
        require(option.state == OptionState.SOLDING && option.optionParam.optionType == OptionType.AUCTION_OPTION,
            "Actuator:Option status and type error");
        //Check whether the time requirements of the order are met
        require(option.optionParam.startTime <= block.timestamp && block.timestamp < option.optionParam.endTime,
            "Actuator:Bidding is not allowed in the current time period");
        //Seller's asset amount check
        (uint256 amount,) = whetherSufficientNFTForSale(option.optionParam.token, option.optionParam.identifier, option.optionParam.creator);
        require(amount >= option.optionParam.amount,
            "Actuator:Asset deduction cannot be carried out as agreed");
        //Find a reasonable reserve price
        uint256[] memory offerIds = optionCorrespondingOffer[optionId];
        uint256 currentPrice = getEffectiveOfferPrice(offerIds);
        if(currentPrice == 0) require(price >= option.optionParam.singlePrice * option.optionParam.amount,
            "Actuator:Bidding is too low");
        if(currentPrice > 0) require(price >= currentPrice + (currentPrice * 5) / 100,"Actuator:Price is too low");
        //Judge the number and authorization of weth of bidders
        (uint256 allowed,uint256 hold) = getBiddingERC20Info(msg.sender);
        require(hold >= price && allowed >= price,"Actuator:Insufficient amount");
        //Id of initial bidding information,And assemble and store bidding information
        offerId = initOfferNumber;
        Offer memory offer = Offer(OfferParam(msg.sender,price),OfferState.EFFECTIVE);
        offerInfo[offerId] = offer;
        optionCorrespondingOffer[optionId].push(offerId);
        offerIndex[offerId] = optionCorrespondingOffer[optionId].length - 1;
        offerCorrespondingOption[offerId] = optionId;
        //Complete the operation to reach the expected price
        uint256 expectPrice = option.optionParam.expectPrice * option.optionParam.amount;
        if(expectPrice > 0  && price >= expectPrice){
            splitIncome(optionId,price);
            //address transferManager = ITransferSelector(transferSelector).getCollectionCorrespondingTransferManager(option.optionParam.token);
            normalTransferNft(
                option.optionParam.token, 
                option.optionParam.identifier, 
                option.optionParam.creator, 
                msg.sender, 
                option.optionParam.amount);
            option.state = OptionState.SALED;
            emit Delivery(optionId, offerId, msg.sender, price, block.timestamp);
        }
        //Complete the operation to reach the expected price
        if(option.optionParam.endTime - block.timestamp < 600 && option.state == OptionState.SOLDING) option.optionParam.endTime += 600;
        initOfferNumber++;
        //emit Bidding(msg.sender, optionId, offerId, price, block.timestamp);
        emit Bidding(msg.sender, optionId, offerId, price, block.timestamp);
    } 
    /**
      * @notice Verify user permissions and allow users to cancel bidding operations
      * @dev Help users cancel their bids
      * @param offerId Offer/Bid id of the offer info to be modified
      */
    function cancelBidding(uint256 offerId) external {
        require(offerInfo[offerId].offerParam.bidder == msg.sender,"Actuator:No permission to cancel");
        uint256 optionId = offerCorrespondingOption[offerId];
        require(optionCorrespondingOffer[optionId][offerIndex[offerId]] > 0,"Actuator:Bidding information does not exist");
        delete optionCorrespondingOffer[optionId][offerIndex[offerId]];
        offerInfo[offerId].state = OfferState.INVALID;
        emit CancelBidding(msg.sender, optionId,offerId, block.timestamp);
    }
    /**
      * @notice Verify the assets of taker
      * @dev Help get the offer ID that the current order can be used for delivery
      */
    function getDeliverableOfferId(uint256 optionId) public view returns(uint256 result){
        uint256[] memory offerIds = optionCorrespondingOffer[optionId];
        for(uint i=0; i<offerIds.length; i++){
            if(offerIds[i] > 0){
                Offer memory offer = offerInfo[offerIds[i]];
                uint256 hold = IERC20(WETH).balanceOf(offer.offerParam.bidder);
                if(hold >= offer.offerParam.price && offerInfo[offerIds[i]].state == OfferState.EFFECTIVE) result = offerIds[i];
            }
        }
    }
    /**
      * @notice Verify user permissions and allow users to cancel bidding operations
      * @dev Help users cancel their bids
      * @param optionId Order number for execution of delivery
      */
    function executeAuctionOption(uint256 optionId) external {
        Option storage option = optionInfo[optionId];
        //Verify current operator permissions
        require(option.optionParam.creator == msg.sender,"Actuator:not execute permit");
        uint256 deliverableOfferId = getDeliverableOfferId(optionId);
        //Verify the status and deliverability of the current option
        require(block.timestamp >= option.optionParam.endTime && option.state == OptionState.SOLDING && deliverableOfferId > 0,
            "Actuator:Currently not allowed to execute");
        //nft transfer
        //address transferManager = ITransferSelector(transferSelector).getCollectionCorrespondingTransferManager(option.optionParam.token);
        Offer memory offer = offerInfo[deliverableOfferId];
        normalTransferNft(
            option.optionParam.token, 
            option.optionParam.identifier, 
            option.optionParam.creator, 
            offer.offerParam.bidder, 
            option.optionParam.amount);
        splitIncome(optionId,offer.offerParam.price);
        option.state = OptionState.SALED;
        emit Delivery(optionId, deliverableOfferId, offer.offerParam.bidder, offer.offerParam.price, block.timestamp);
    }

    function getBiddingERC20Info(address bidder) public view returns(uint256 allowed,uint256 hold){
        allowed = IERC20(WETH).allowance(bidder, address(this));
        hold = IERC20(WETH).balanceOf(bidder);
    }
    
    function splitIncome(uint256 optionId,uint256 amount) internal {
        Option memory option = optionInfo[optionId];
        (address receiver,uint256 royalty) = IRoyaltyManager(royaltyManager).calculateRoyaltyFeeAndGetRecipient(
            option.optionParam.token, 
            option.optionParam.identifier, 
            amount);
        if(option.optionParam.optionType == OptionType.FIXED_OPTION){
            uint256 marketFee = amount * marketFeeToFixed / 10000;
            uint256 reward = amount - royalty - marketFee;
            TransferHelper.safeTransferETH(option.optionParam.creator, reward);
            if(receiver != address(0) && royalty > 0)TransferHelper.safeTransferETH(receiver, royalty);
            TransferHelper.safeTransferETH(marketFeeRecipient, marketFee);
        }else{
            Offer memory offer = offerInfo[getDeliverableOfferId(optionId)];
            uint256 marketFee = amount * marketFeeToAuction / 10000;
            uint256 reward = amount - royalty - marketFee;
            TransferHelper.safeTransferFrom(WETH, offer.offerParam.bidder, option.optionParam.creator, reward);
            if(receiver != address(0) && royalty > 0) TransferHelper.safeTransferFrom(WETH, offer.offerParam.bidder, receiver, royalty);
            TransferHelper.safeTransferFrom(WETH, offer.offerParam.bidder, marketFeeRecipient, marketFee);
        }
    }

    function _become(KnowhereProxy knowhereProxy) public {
        require(msg.sender == knowhereProxy.admin(), "only knowhereProxy admin");
        require(knowhereProxy._acceptImplementation() == 0, "change not authorized");
    }

    function normalTransferNft(address collection,uint256 identifier,address spender,address recipient,uint256 amount) internal {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721))
                IERC721(collection).safeTransferFrom(spender, recipient, identifier);

        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) 
                IERC1155(collection).safeTransferFrom(spender, recipient, identifier, amount, new bytes(0));
        
    }
    //(address(this),optionParam.token, msg.sender, optionParam.identifier);
    function whetherSufficientNFTForSale(
            address collection,
            uint256 identifier,
            address spender
        ) public view returns
        (
            uint256 amount,
            bool    authorization
        ){
            authorization = IERC721(collection).isApprovedForAll(spender, address(this));
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)){
                address holder = IERC721(collection).ownerOf(identifier);
                if(holder == spender) amount = 1;
                
            }
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)){
                amount = IERC1155(collection).balanceOf(spender, identifier);
            }           
    }

    function getEffectiveOfferPrice(uint256[] memory offerIds) public view returns (uint256 currentPrice){
        uint256 result;
        uint256 len = offerIds.length;
        for (uint i = 0; i < len; i++) {
            if (offerIds[len - i - 1] > 0) {
                result = offerIds[len - i - 1];
                break;
            }
        }
        if (result > 0) currentPrice = offerInfo[result].offerParam.price;
    }
    
}
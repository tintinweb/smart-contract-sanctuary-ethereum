/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
}

interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IStructure{
    enum TradingType{trading,auction}
    enum State{solding,saled,cancelled,nul}
    //["0","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","10001","10","1000000","7","0"]
    //
    struct Option{
        TradingType tradingType;
        address token;
        address creator;
        uint    tokenId;
        uint256 amount;
        uint256 single;
        uint256 expiration;
        uint256 expect;
    }

    struct Offer{
        address bidder;
        uint256 price;
    }

    struct StandardOrder{
        TradingType tradingType;
        address token;
        address creator;
        uint    tokenId;
        uint256 amount;
        uint256 single;
        uint256 expect;
        uint256 expiration;
        State   state;
    }

}


interface ISynchron{
    function add(bytes memory hash) external;
    function update(bytes memory overHash,bytes memory newHash) external;
    function cancel(bytes memory hash,bytes memory order) external;
    function addBidding(bytes memory orderHash,bytes memory offerHash) external;
    function cancelBiding(bytes memory orderHash,bytes memory offerHash) external;
    function getBiddingForOrder(bytes memory orderHash) external view returns(bytes[] memory offers);
}

contract Synchron is ISynchron,ERC1155Holder,ERC721Holder{
    using SafeMath for uint256;

    bytes[] effectiveOption;

    bytes[] invalidOption;
    
    mapping(bytes => uint) orderIndex;

    mapping(bytes => uint) offerIndex;

    mapping(bytes => bytes[]) CorrespondingBid;

    address operator;

    address owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Synchron:not permit!");
        _;
    }

    modifier onlyOperator(){
        require(operator == msg.sender,"Synchron:not permit!");
        _;
    }

    function updateOperator(address _operator) public onlyOwner{
        operator = _operator;
    }

    function add(bytes memory hash) external override onlyOperator{
        effectiveOption.push(hash);
        orderIndex[hash] = effectiveOption.length - 1;
    }

    function update(bytes memory overHash,bytes memory newHash) external override onlyOperator{
        effectiveOption[orderIndex[overHash]] = newHash;
    }

    function cancel(bytes memory hash,bytes memory order) external override onlyOperator{    
        if(effectiveOption.length > 0){
            effectiveOption[orderIndex[hash]] = effectiveOption[effectiveOption.length - 1];
        }
        effectiveOption.pop();
        invalidOption.push(order);
    }

    function addBidding(bytes memory orderHash,bytes memory offerHash) external override onlyOperator{}

    function cancelBiding(bytes memory orderHash,bytes memory offerHash) external override onlyOperator{}

    function getBiddingForOrder(bytes memory orderHash) external override view returns(bytes[] memory offers){
        offers = CorrespondingBid[orderHash];
    }

    function getOrder() external view returns(bytes[] memory effective,bytes[] memory invalid){
        effective = effectiveOption;
        invalid = invalidOption;
    }
}

interface IGlibrary is IStructure{
    function analyseOption(bytes memory hash) external pure returns(StandardOrder memory order);
    function getPurchaseStatus(bytes memory hash,address customer,uint256 payment) external view returns(bool state);
    function getModifyStatus(bytes memory hash,address customer,uint256 single) external view returns(bool state);
    function getBiddingStatus(bytes memory orderHash,address join,uint256 price) external view returns(bool state);
    function getCancelBiddingStatus(bytes memory orderHash,bytes memory offerHash) external view returns(bool state);
    function getDeliveryStatus(bytes memory orderHash,address operator) external view returns(bool state);
    function getRefuseDeliveryStatus(bytes memory orderHash,address operator) external view returns(bool state);
}

contract Glibrary is IGlibrary{

    using SafeMath for uint256;

    function analyseOption(bytes memory hash) public override pure returns(StandardOrder memory order){
        (bytes memory orderInfo,) = abi.decode(hash,(bytes,bytes4));
        (TradingType tradingType,address token,address creator,uint tokenId,uint256 amount,
        uint256 single,uint256 expect,uint256 expiration,State   state) = abi.decode(orderInfo,(TradingType,address,address,
        uint,uint256,uint256,uint256,uint256,State));
        order = StandardOrder(tradingType,token,creator,tokenId,amount,single,expect,expiration,state);
    }

    function getCreateStatus(Option calldata option) external  view returns(bool state){}

    function getCancelStatus(bytes memory orderHash,address operator) external view returns(bool state){}

    function getPurchaseStatus(bytes memory hash,address customer,uint256 payment) external override view returns(bool state){
        StandardOrder memory order = analyseOption(hash);
        bool time = block.timestamp <= order.expiration;
        bool pay = payment >= order.amount.mul(order.single);
        bool own = customer != order.creator;
        if(time != false && pay != false && own != false) state = true;
    }

    function getModifyStatus(bytes memory hash,address customer,uint256 single) external override view returns(bool state){
        StandardOrder memory order = analyseOption(hash);
        if(order.tradingType == TradingType.trading){
            if(customer == order.creator && block.timestamp <= order.expiration && order.state == State.solding){
                state = true;
            }
        }else{
            if(customer == order.creator && block.timestamp <= order.expiration && order.state == State.solding && 
                single < order.single){
                    state = true;
            }
        }
    }

    function getBiddingStatus(bytes memory orderHash,address join,uint256 price) external override view returns(bool state){}

    function getCancelBiddingStatus(bytes memory orderHash,bytes memory offerHash) external override view returns(bool state){}

    function getDeliveryStatus(bytes memory orderHash,address operator) external override view returns(bool state){}

    function getRefuseDeliveryStatus(bytes memory orderHash,address operator) external override view returns(bool state){}

}

contract Trading is IStructure{

    using SafeMath for uint256;

    address synchron;

    address glibrary;

    address owner;

    address feeTo;

    address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    uint256 taxFixedFee = 2;

    uint256 taxAuctionFee = 25;

    uint256 initNum;

    constructor(address _sync,address _library){
        owner = msg.sender;
        synchron = _sync;
        glibrary = _library;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Trading:not permit");
        _;
    }

    function getApprovedStatus(address token,address sender,address spent) public view returns(uint256 amount){}

    function getNftApprovedStatus(address token,address sender,address spent) public view returns(bool state){}

    function updateFeeInfo(address _feeTo,uint256 _fixedFee,uint256 _auctionFee) public onlyOwner{
        feeTo = _feeTo;
        taxFixedFee = _fixedFee;
        taxAuctionFee = _auctionFee;
    }

    function create(Option calldata option) external returns(bytes memory orderHash){
        require(option.expiration > 0 && option.single > 0,"Trading:Order information error");
        StandardOrder memory order = StandardOrder(
            option.tradingType,
            option.token,
            option.creator,
            option.tokenId,
            option.amount,
            option.single,
            option.expect,
            option.expiration.mul(3600).add(block.timestamp),
            State.solding
            );
        ISynchron(synchron).add(getOrderHash(order));
        orderHash = getOrderHash(order);
        initNum++;
    }

    function getOrderHash(StandardOrder memory order) public view returns(bytes memory orderHash){
        bytes memory orderInfo = abi.encode(order);
        uint256 init = initNum;
        bytes4 salt;
        assembly{
            mstore(add(salt,2),init)
        }
        orderHash = abi.encode(orderInfo,salt);
    }

    function cancel(bytes memory order) external {
        StandardOrder memory orderInfo = IGlibrary(glibrary).analyseOption(order);
        orderInfo.state = State.cancelled;
        ISynchron(synchron).update(order, getOrderHash(orderInfo));
    }

    function purchase(bytes memory orderHash) external payable{
        require(IGlibrary(glibrary).getPurchaseStatus(orderHash,msg.sender,msg.value) == true,"Trading:Purchase information error!");
        StandardOrder memory order = IGlibrary(glibrary).analyseOption(orderHash);
        order.state = State.saled;
        ISynchron(synchron).cancel(orderHash, getOrderHash(order));
    }

    function modify(bytes memory hash,uint256 single) external {
        require(IGlibrary(glibrary).getModifyStatus(hash,msg.sender,single) == true,"Trading:Price information error");
        StandardOrder memory order = IGlibrary(glibrary).analyseOption(hash);
        order.single = single;
        ISynchron(synchron).update(hash, getOrderHash(order));
    }
    //bytes memory = 0x/delete == 0x
    function bidding(bytes memory order,uint256 price) external {
        require(IGlibrary(glibrary).getBiddingStatus(order, msg.sender,price) == true,"Trading:Bidding information error");
        Offer memory offer = Offer(msg.sender,price);
        ISynchron(synchron).addBidding(order, abi.encode(offer));
    }

    function cancelBidding(bytes memory orderHash,bytes memory offerHash) external{
        require(IGlibrary(glibrary).getCancelBiddingStatus(orderHash, offerHash) == true,"Trading:Failed to cancel bidding");
        ISynchron(synchron).cancelBiding(orderHash,offerHash);
    }

    function delivery(bytes memory orderHash) external{
        require(IGlibrary(glibrary).getDeliveryStatus(orderHash, msg.sender) == true,"Trading:Delivery order failed");
        StandardOrder memory order = IGlibrary(glibrary).analyseOption(orderHash);
        order.state = State.saled;
        ISynchron(synchron).cancel(orderHash, getOrderHash(order));
    }

    function refuseDelivery(bytes memory orderHash) external{
        require(IGlibrary(glibrary).getRefuseDeliveryStatus(orderHash, msg.sender) == true,"Trading:Refusal of delivery is not allowed");
        StandardOrder memory order = IGlibrary(glibrary).analyseOption(orderHash);
        order.state = State.cancelled;
        ISynchron(synchron).update(orderHash, getOrderHash(order));
    }

    // function cutPayment(address token,address sender,address recipient,uint256 amount)internal{
    //     require(IERC20(token).transferFrom(sender,recipient,amount),"Trading:TransferFrom failed");
    // }

}
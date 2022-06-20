//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Posts.sol";

contract SocialBlocks is Posts{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Accounts.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Posts is Accounts, IERC721{
    using Counters for Counters.Counter;
    Counters.Counter private postId;

    event Approval(uint256 ownerAccountId, uint256 approvedAccountId, uint256 postId);
    event ApprovalForAll(uint256 ownerAccountId, uint256 operatorAccountId, bool approved);

    struct PostDetails {
        string title;
        string description;
        string contentUrl;
        uint8 contentType; // (0) Text data, (1) Image data, (3) Video data.
        uint8 tradeStatus; // (0) Not for sale, (1) For sale, (2) For Auction.
        uint256 price;
        uint256 baseBid;
        uint256 lastBid;
        uint256 lastBidder;
        uint256 bidEnds;
        uint256 creator; // creator's accountId.
    }

    mapping(uint256 => PostDetails) private postDetails;
    mapping(uint256 => string) private postUris;
    mapping(uint256 => uint256) private postOwners;
    mapping(uint256 => uint256) private accountBalances;
    mapping(uint256 => uint256) private postApprovals;
    mapping(uint256 => mapping(uint256 => bool)) private operatorApprovals;

    modifier isPost(uint256 _postId) {
        require(_postId > 0 && _postId <= postId.current() , "Invalid PostId.");
        _;
    }

    function createPost(
        string memory _title,
        string memory _description,
        string memory _contentUrl,
        uint8 _contentType,
        uint8 _tradeStatus,
        uint256 _price,
        uint256 _baseBid,
        uint256 _lastBid,
        uint256 _bidEnds,
        string memory _uri
    ) external isAccount(msg.sender){
        postId.increment();
        postUris[postId.current()] = _uri;
        postOwners[postId.current()] = getAccountId(msg.sender);
        accountBalances[getAccountId(msg.sender)]++;
        postDetails[postId.current()] = PostDetails(_title,_description,_contentUrl,_contentType,_tradeStatus,_price,_baseBid,_lastBid,0,_bidEnds,getAccountId(msg.sender));
    }

    function buyPost(uint256 _postId) external payable isAccount(msg.sender) isPost(_postId) {
        require(postDetails[_postId].tradeStatus == 1 , "This post is not for sale.");
        require(msg.value >= postDetails[_postId].price , "Insufficient amount sent.");

        (bool sent,) = getAccountAddress(postOwners[_postId]).call{value: msg.value}("");

        if(sent){
            postOwners[_postId] = getAccountId(msg.sender);
            postDetails[_postId].tradeStatus = 0;
        }else {
            revert("Error sending funds to the owner.");
        }

    }

    function putItemOnSale(uint256 _postId, uint256 _price) external isAccount(msg.sender) isPost(_postId){
        require(msg.sender == getAccountAddress(postOwners[_postId]),"You don't have the ownership of the post.");
        require(postDetails[_postId].tradeStatus == 0 , "The post is already on auction or sale.");

        postDetails[_postId].tradeStatus = 1;
        postDetails[_postId].price = _price;
    }

    function putItemOnBidding(uint256 _postId, uint256 _baseBid , uint256 _bidEnds) external isAccount(msg.sender) isPost(_postId){
        require(msg.sender == getAccountAddress(postOwners[_postId]),"You don't have the ownership of the post.");
        require(postDetails[_postId].tradeStatus != 2 , "The post is already on auction.");

        postDetails[_postId].tradeStatus = 2;
        postDetails[_postId].baseBid = _baseBid;
        postDetails[_postId].lastBid = _baseBid;
        postDetails[_postId].lastBidder = 0;
        postDetails[_postId].bidEnds = _bidEnds;
    }

    function bidOnPost(uint256 _postId) external payable isAccount(msg.sender) isPost(_postId){
        require(postDetails[_postId].tradeStatus == 2 , "Post is not on auction.");
        require(msg.value > postDetails[_postId].lastBid , "The last bid was higher than your bid.");
        require(postDetails[_postId].bidEnds > block.timestamp , "The bidding time ended.");
        
        bool sent = false;

        if(getAccountAddress(postDetails[_postId].lastBidder) != address(0)){
           (sent,) = getAccountAddress(postDetails[_postId].lastBidder).call{value: msg.value}("");
        }else{
            sent = true;
        }

        if(sent){
            postDetails[_postId].lastBid = msg.value;
            postDetails[_postId].lastBidder = getAccountId(msg.sender);
        }else{
            revert("Error sending funds to the last bidder.");
        }

    }

    function claimBidding(uint256 _postId) external isPost(_postId){
        require(postDetails[_postId].tradeStatus == 2 , "This post is not on auction.");
        require(postDetails[_postId].bidEnds < block.timestamp , "The bidding is not ended yet.");
        require(
            msg.sender == getAccountAddress(postOwners[_postId]) ||
            msg.sender == getAccountAddress(postDetails[_postId].lastBidder));

        postDetails[_postId].tradeStatus = 0 ;
        uint256 previousOwner = postOwners[_postId];
        postOwners[_postId] = postDetails[_postId].lastBidder;

        (bool sent,) = getAccountAddress(previousOwner).call{value: postDetails[_postId].lastBid}("");

        if(!sent){
            revert("Error sending funds to the previous owner.");
        }

    }

    function ownerOf(uint256 _postId) public view virtual override isPost(_postId) returns (address) {
        return getAccountAddress(postOwners[_postId]);
    }

    function balanceOf(address owner) public view virtual override isAccount(owner) returns (uint256) {
        return accountBalances[getAccountId(owner)];
    }

    function safeTransferFrom(address from , address to , uint256 _postId) public virtual override{
        transferFrom(from , to , _postId);
    }

    function safeTransferFrom(address from , address to , uint256 _postId , bytes memory _data) public virtual override {
        transferFrom(from , to , _postId);
    }

    function transferFrom(address from , address to , uint256 _postId) public virtual override  isAccount(from) isAccount(to) isPost(_postId){
        require(
            postOwners[_postId] == getAccountId(msg.sender) || 
            postApprovals[_postId] == getAccountId(msg.sender) || 
            operatorApprovals[getAccountId(from)][getAccountId(msg.sender)] == true,
            "Access denied.");

        postOwners[_postId] = getAccountId(to);
        postApprovals[_postId] = 0;
    }

    function approve(address to, uint256 _postId) public virtual override isAccount(msg.sender) isAccount(to) isPost(_postId) {
        address owner = getAccountAddress(postOwners[_postId]);

        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, _postId);
    }

    function _approve(address to, uint256 _postId) internal{
        postApprovals[_postId] = getAccountId(to);
        emit Approval(getAccountId(msg.sender), getAccountId(to), _postId);
    }

    function getApproved(uint256 _postId) public view virtual override isPost(_postId) returns (address) {
        return getAccountAddress(postApprovals[_postId]);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override isAccount(msg.sender) isAccount(operator){
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
       
        operatorApprovals[getAccountId(owner)][getAccountId(operator)] = approved;
        emit ApprovalForAll(getAccountId(owner) , getAccountId(operator) , approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override isAccount(owner) isAccount(operator) returns (bool) {
        return operatorApprovals[getAccountId(owner)][getAccountId(operator)];
    }

    function tokenURI(uint256 tokenId) public view isPost(tokenId) returns (string memory){
        return postUris[tokenId];
    }

    function totalPosts() public view returns(uint256){
        return postId.current();
    }

    function totalSupply() public view returns (uint256) {
        return postId.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId;
    }

    function name() public pure returns (string memory) {
        return "Social Blocks Posts";
    }

    function symbol() public pure returns (string memory) {
        return "SB-Posts";
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Verify.sol";

contract Accounts is Verify , Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private accountId;

    event AccountCreated(AccountDetail,address _address);
    event AccountUpdated(AccountDetail,address _address);
    
    struct AccountDetail {
        string username;
        string displayName;
        string bio;
        string profilePic;
        bool isVerified;
    }

    mapping(uint256 => address) private idToAddress;
    mapping(address => uint256) private addressToId;

    mapping(uint256 => AccountDetail) private accountDetails;

    modifier isAccount(address _address) {
        require(_isAccount(_address) , "Account with this address does not exists.");
        _;
    }

    modifier isNotAccount(address _address) {
        require(!_isAccount(_address) , "Account with this address already exists.");
        _;
    }

    function createAccount(string memory _username , string memory _displayName , string memory _bio , string memory _profilePic , bytes memory _signature) external isNotAccount(msg.sender) isInfoVerified(owner(),_signature,_username) {
      
        accountId.increment();
      
        idToAddress[accountId.current()] = msg.sender;
        addressToId[msg.sender] = accountId.current();
        accountDetails[addressToId[msg.sender]] = AccountDetail(_username , _displayName , _bio , _profilePic , false);

        emit AccountCreated(accountDetails[addressToId[msg.sender]],msg.sender);
    }

    function updateAccountDetails(string memory _displayName , string memory _bio , string memory _profilePic) external isAccount(msg.sender){

        accountDetails[addressToId[msg.sender]].displayName = _displayName;
        accountDetails[addressToId[msg.sender]].bio = _bio;
        accountDetails[addressToId[msg.sender]].profilePic = _profilePic;

        emit AccountUpdated(accountDetails[addressToId[msg.sender]],msg.sender);
    }

    function changeAddress(address _newAddress) external isAccount(msg.sender) isNotAccount(_newAddress){

        uint _accountId = addressToId[msg.sender];

        addressToId[msg.sender] = 0;
        addressToId[_newAddress] = _accountId;
        idToAddress[_accountId] = _newAddress;

        emit AccountUpdated(accountDetails[_accountId],_newAddress);
    }

    function changeAccountStatus(uint256 _accountId , bool status) external onlyOwner{
        accountDetails[_accountId].isVerified = status;
        emit AccountUpdated(accountDetails[_accountId],msg.sender);
    }

    function getAccountDetails(uint256 _accountId) public view returns (AccountDetail memory){
        require(_accountId > 0 && _accountId <= accountId.current() , "Account does not exists.");
        return accountDetails[_accountId];
    }

    function getAccountDetails(address _accountAddress) public view isAccount(_accountAddress) returns (AccountDetail memory){
        return accountDetails[addressToId[_accountAddress]];
    }

    function getAccountId(address _accountAddress) internal view returns(uint256){
        return addressToId[_accountAddress];
    }

    function getAccountAddress(uint256 _accountId) internal view returns(address){
        return idToAddress[_accountId];
    }

    function _isAccount(address _address) internal view returns (bool){
        if(addressToId[_address] == 0){
            return false;
        }else{
            return true;
        }
    }

    function totalAccounts() external view returns (uint256) {
        return accountId.current();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Verify{

    modifier isInfoVerified(address _signer, bytes memory _signature, string memory _message) {
        require(verify(_signer,_signature,_message),"Information is not verified.");
        _;
    }

    function verify (address _signer, bytes memory _signature, string memory _message) internal pure returns (bool){
        bytes32 _messageHash = keccak256(abi.encodePacked(_message));
        bytes32 _signedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        return recoverSigner(_signedMessageHash, _signature) == _signer;
    }

    function recoverSigner (bytes32 _signedMessageHash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "Invalid signature length"); 
    
        assembly {
            r:= mload(add(_signature, 32))
            s:= mload(add(_signature, 64))
            v:=byte(0, mload(add(_signature, 96)))
        }
    
        return ecrecover(_signedMessageHash, v, r, s);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
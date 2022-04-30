// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./HumachLib/Ownable.sol";

contract Mining is Ownable ,IERC721Receiver {
    address private nft = 0xfFF7C7f91C05af3FA8FBC963140297BC8815332E;//0xAA89E8Eb3048A2D8cb1a3Db7D2B49f8FA33D56ba;
    address[] minerAccounts;
    struct Miner {
        uint16[] tokenIds;
        uint256 accountIndex;
        bool    isMining;
    }
    mapping(address => Miner) private miners;
    bool private pauseToMine;
    bool private pauseComeHome;

    constructor() {
        minerAccounts.push(address(0));
    }
    
    function toMine(uint16 tokenId ) public {
        require(!pauseToMine,"Mining : pause transaction by admin");
        require(IERC721(nft).ownerOf(tokenId) == _msgSender() , "Mining : owner query for nonexistent Humach token");
        require(IERC721(nft).isApprovedForAll(_msgSender(), address(this)), "Mining : Need approve this address for All");
        if(!miners[_msgSender()].isMining ){
            miners[_msgSender()].isMining = true;
            miners[_msgSender()].accountIndex = minerAccounts.length;
            minerAccounts.push(_msgSender());
        }
        miners[_msgSender()].tokenIds.push(tokenId);
        IERC721(nft).safeTransferFrom(_msgSender(), address(this), tokenId);
    }

    function toMineBatch(uint16[] memory tokenIds )external {
        require(!pauseToMine,"Mining : pause transaction by admin");
        for(uint8 i =0; i<tokenIds.length; i++ ){
            require(IERC721(nft).ownerOf(tokenIds[i]) == _msgSender() , "Mining : owner query for nonexistent Humach token");
            require(IERC721(nft).isApprovedForAll(_msgSender(), address(this)), "Mining : Need approve this address for All");
        }

        if(!miners[_msgSender()].isMining ){
            miners[_msgSender()].isMining = true;
            miners[_msgSender()].accountIndex = minerAccounts.length;
            minerAccounts.push(_msgSender());
        }

        for(uint8 i =0; i<tokenIds.length; i++ ){
            miners[_msgSender()].tokenIds.push(tokenIds[i]);
            IERC721(nft).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
        }


    }

    function comeHome(uint16 tokenId,uint256 tokenIdIndex) public {
        require(miners[_msgSender()].isMining , "Mining : Humach is not mining");
        require(miners[_msgSender()].tokenIds[tokenIdIndex] == tokenId , "Mining : Mismactch tokenId and index");
        require(!pauseComeHome,"Mining : pause transaction by admin");
        if(miners[_msgSender()].tokenIds.length ==1){
            miners[minerAccounts[minerAccounts.length -1]].accountIndex = miners[_msgSender()].accountIndex;
            minerAccounts[miners[_msgSender()].accountIndex] = minerAccounts[minerAccounts.length -1];
            minerAccounts.pop();
            delete miners[_msgSender()];
        }
        else{
            miners[_msgSender()].tokenIds[tokenIdIndex] =  miners[_msgSender()].tokenIds[miners[_msgSender()].tokenIds.length - 1];
            miners[_msgSender()].tokenIds.pop();
        }
        IERC721(nft).safeTransferFrom( address(this),_msgSender(), tokenId);
    }

    function comeHomeAll() public{
        require(miners[_msgSender()].isMining,"Mining : Humach is not mining");
        require(!pauseComeHome,"Mining : pause transaction by admin");
        for(uint16 i = 0; i<miners[_msgSender()].tokenIds.length; i++ ){
            IERC721(nft).safeTransferFrom(address(this), _msgSender(), miners[_msgSender()].tokenIds[i]);
           
        }
        miners[minerAccounts[minerAccounts.length -1]].accountIndex = miners[_msgSender()].accountIndex;
        minerAccounts[miners[_msgSender()].accountIndex] = minerAccounts[minerAccounts.length -1];
        minerAccounts.pop();
        delete miners[_msgSender()];

    }

    function comHomeBatch(uint16[] memory tokenIds, uint256[] memory indexs ) external{
        require(tokenIds.length == indexs.length, "Mining: tokenIds and indexs length mismatch");
        require(!pauseComeHome,"Mining : pause transaction by admin");
        if(miners[_msgSender()].tokenIds.length == tokenIds.length ){
            comeHomeAll();
        }
        else{
            require(miners[_msgSender()].accountIndex != 0 , "Mining : Humach is not mining");
            uint _length_1 = tokenIds.length - 1 ;
            for(uint16 i= 0; i< tokenIds.length; i++ ){
                require(miners[_msgSender()].tokenIds[indexs[i]] == tokenIds[i] , "Mining: tokenIds and indexs is mismatch");
                if(i < _length_1 ){
                    require(indexs[i] > indexs[i +1] , "Mining : wrong indexs order");
                }
            } 
            delete _length_1 ;
            for(uint16 i= 0; i< tokenIds.length; i++ ){
                miners[_msgSender()].tokenIds[indexs[i]] =  miners[_msgSender()].tokenIds[miners[_msgSender()].tokenIds.length - 1 ];
                miners[_msgSender()].tokenIds.pop();
                IERC721(nft).safeTransferFrom( address(this),_msgSender(), tokenIds[i]);
            } 


        }


    }

    function setPause(bool toMineStatus , bool comeHomeStatus) external onlyAdmin {
        pauseToMine = toMineStatus;
        pauseComeHome = comeHomeStatus;
    }
    
    function getPauseStatus()external view returns(bool,bool){
        return (pauseToMine,pauseComeHome);
    }

    function getTotalMinerAccount() external view returns(uint256){
        return minerAccounts.length;
    }

    function getMinerAccounts(uint16 startIndex, uint16 amount) external view returns(address[] memory acounts){
        address[] memory _accounts = new address[](amount);
        for(uint16 i=startIndex; i< startIndex + amount ; i++){
            _accounts[i] = minerAccounts[i];
        }
        return _accounts;
    }

    function getMinerInfo(address account) external view returns(uint16[] memory tokenIds, uint256 accountIndex, bool isMining){
        uint16[] memory _tokenId = new uint16[](miners[account].tokenIds.length);
       for(uint16 i=0; i< miners[account].tokenIds.length ; i++){
            _tokenId[i] = miners[account].tokenIds[i];
        }
        return(_tokenId, miners[account].accountIndex,miners[account].isMining);
    }

    function checkToMine(address acount ,uint16 tokenId) external view returns(bool){      
        if(IERC721(nft).ownerOf(tokenId) != acount){
            return(false);
        }
        if(!IERC721(nft).isApprovedForAll(acount, address(this))){
            return(false);
        } 

        return(true);
    }

    function checkComeHome (address acount ,uint16 tokenId,uint256 tokenIdIndex) external view returns(bool){     
        if(miners[acount].accountIndex == 0){
            return (false);
        }
        if(miners[acount].tokenIds[tokenIdIndex] != tokenId){
            return (false);
        }
        return(true);
    }

    function updateNFTContract(address newAddr) external onlyAdmin{
        nft = newAddr;
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping (address => bool) _admin;
    mapping (address => bool) _worker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _admin[_msgSender()] = true;
        _worker[_msgSender()] = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function isAdmin(address account_) public view virtual returns (bool) {
        return _admin[account_];
    }
    function isWorker(address account_) public view virtual returns (bool) {
        return _worker[account_];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the Admin");
        _;
    }
    modifier onlyWorker() {
        require(isWorker(_msgSender()), "Ownable: caller is not the Worker");
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

    function updateAdmin(address account_, bool status_) public  onlyOwner{
        require(account_ != address(0), "Ownable: new Admin is the zero address");
        _admin[account_] = status_;
    }

    function updateWorker(address account_, bool status_) public  onlyOwner{
        require(account_ != address(0), "Ownable: new Worker is the zero address");
        _worker[account_] = status_;
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
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExhibitionLock.sol";


    

contract ExhibitionLockFactory is Ownable{
    
    mapping(address => string) public exhibitorNames;

    address[] public allExhibitions;
    uint256 public totalExhibitions;

    event CreatedExhibition(address indexed exhibitorAddress, address indexed exhibitionLockAddress, string exhibitor, string exhibitionName, string exhibitioLocation, uint256 exhibitioStart, uint256 exhibitioEnd);
    
    constructor() Ownable(){}

    function createExhibitionLock(
        address  _exhibitorAddress,
        string memory  _exhibitionName,
        string memory  _exhibitioLocation,
        uint256  _exhibitioStart,
        uint256  _exhibitioEnd

    ) public returns (address exhibition) {
        require(isExhibitor(_exhibitorAddress), "ExhibitionLockFactory: Not allowed as exhibitor");
        require(_exhibitioStart < _exhibitioEnd, "ExhibitionLockFactory: Start after End");


        bytes memory bytecode = type(ExhibitionLock).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_exhibitorAddress, _exhibitionName, _exhibitioLocation, _exhibitioStart, _exhibitioEnd));
        assembly {
            exhibition := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ExhibitionLock(exhibition).initialize(_exhibitorAddress, exhibitorNames[_exhibitorAddress],_exhibitionName,_exhibitioLocation, _exhibitioStart, _exhibitioEnd, msg.sender);

        allExhibitions.push(exhibition);


        emit CreatedExhibition(_exhibitorAddress, exhibition, exhibitorNames[_exhibitorAddress], _exhibitionName,  _exhibitioLocation, _exhibitioStart, _exhibitioEnd);

        totalExhibitions +=1;
    }

    function addExhibitor(address _address, string memory _name) public onlyOwner {
        exhibitorNames[_address] = _name;
    }

    function isExhibitor(address _address) public view returns(bool) {
        return bytes(exhibitorNames[_address]).length > 0;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ExhibitionLock is IERC721Receiver{
    address public deployer;

    address public exhibitorAddress;
    string public exhibitor;
    string public exhibitionName;
    string public exhibitioLocation;
    uint256 public exhibitioStart;
    uint256 public exhibitioEnd;

    event DepositedERC721(address indexed exhibitionLockAddress, address indexed tokenAddress, address indexed exhibitorAddress, string exhibitor, string exhibitionName, string exhibitioLocation, uint256 tokenId, address owner);
    event WithdrawnERC721(address indexed exhibitionLockAddress, address indexed tokenAddress, address indexed exhibitorAddress, string exhibitor, string exhibitionName, string exhibitioLocation, uint256 tokenId, address owner);
    event TokensApproved(address indexed exhibitionLockAddress, address indexed token, uint256 indexed tokenId);
    event ExhibitionApproved(address indexed exhibitionLockAddress, address indexed exhibitorAddress);

    mapping(address => mapping(uint256 => address)) public originalOwner;


    mapping(address => mapping(uint256 => bool)) public allowedTokens;

    bool public publicApprovedByExhibitor = false;

    function initialize( 
        address  _exhibitorAddress,
        string memory  _exhibitor,
        string memory  _exhibitionName,
        string memory  _exhibitioLocation,
        uint256  _exhibitioStart,
        uint256  _exhibitioEnd,
        address _deployer
    )public{
        require(exhibitorAddress == address(0), "ExhibitionLock: already Initialized");
        exhibitorAddress =_exhibitorAddress;
        exhibitor =_exhibitor;
        exhibitionName =_exhibitionName;
        exhibitioLocation =_exhibitioLocation;
        exhibitioStart =_exhibitioStart;
        exhibitioEnd =_exhibitioEnd;

        deployer = _deployer;
    }

    function approveTokens(address[] memory _tokens, uint256[] memory _tokenIds) public {
        require(msg.sender == deployer,  "ExhibitionLock: Only Deployer can approve");
        require(_tokens.length == _tokenIds.length ,  "ExhibitionLock: unequal number of addresses and tokenIds");
        require(_tokens.length < 256 ,  "ExhibitionLock: Too many Tokens");
        
        for(uint8 i = 0; i< _tokens.length; i++){
            allowedTokens[_tokens[i]][_tokenIds[i]] = true;
            emit TokensApproved(address(this), _tokens[i], _tokenIds[i]);
        }

    }


    function approveExhibition() public returns(bool){
        require(msg.sender == exhibitorAddress,  "ExhibitionLock: Only Exhibitor can approve");
        publicApprovedByExhibitor = true;

        emit ExhibitionApproved(address(this), exhibitorAddress);

        return true;
    }


    function depositERC721(IERC721 _token, uint256 _tokenId) public returns (bool) {
        require(publicApprovedByExhibitor, "ExhibitionLock: Exhibition is not yet approved");
        require(block.timestamp < exhibitioStart, "ExhibitionLock: Exhibition started already");
        require(allowedTokens[address(_token)][_tokenId], "ExhibitionLock: Token Not Allowed");
       _token.safeTransferFrom(msg.sender, address(this), _tokenId);
       originalOwner[address(_token)][_tokenId] = msg.sender;
       
       emit DepositedERC721(address(this), exhibitorAddress, address(_token), exhibitor, exhibitionName, exhibitioLocation, _tokenId, msg.sender);
       return true;
    }

    function withdrawERC721(IERC721 _token, uint256 _tokenId) public returns (bool) {
        require(block.timestamp > exhibitioEnd, "ExhibitionLock: Exhibition not over yet");
        address owner = originalOwner[address(_token)][_tokenId];
       _token.safeTransferFrom(address(this), owner, _tokenId);
       
       emit WithdrawnERC721(address(this), exhibitorAddress, address(_token), exhibitor, exhibitionName, exhibitioLocation, _tokenId, owner);
       return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata 
    ) external override pure returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
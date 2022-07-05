// ███████╗██╗ ██████╗ ██████╗  ██████╗ ██╗     ██╗         ██╗  ██╗    ██████╗  ██████╗ ██████╗ ███████╗ █████╗ ██████╗ ███████╗
// ██╔════╝██║██╔════╝ ██╔══██╗██╔═══██╗██║     ██║         ╚██╗██╔╝    ██╔══██╗██╔═══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝
// ███████╗██║██║  ███╗██████╔╝██║   ██║██║     ██║          ╚███╔╝     ██║  ██║██║   ██║██████╔╝█████╗  ███████║██████╔╝█████╗  
// ╚════██║██║██║   ██║██╔══██╗██║   ██║██║     ██║          ██╔██╗     ██║  ██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██║██╔═══╝ ██╔══╝  
// ███████║██║╚██████╔╝██║  ██║╚██████╔╝███████╗███████╗    ██╔╝ ██╗    ██████╔╝╚██████╔╝██║     ███████╗██║  ██║██║     ███████╗
// ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝    ╚═╝  ╚═╝    ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: contracts/Collector.sol

contract Collector is Ownable {
    uint public immutable TOTAL_PERMISSION_NUMBER;
    uint _receivedPermissionNumber;
    bool _achieved;

    // target nft address for permission
    address[] _targetNFTAddresses;
    // From target nft address to its required number
    mapping(address => uint)  _targetPermissionNumbers;
    // From target nft address to its permission fee
    mapping(address => uint)  _targetPermissionFees;
    // From target nft address to its current permission number
    mapping(address => uint) _currentPermissionNumbers;
    // From target nft address to the map that (tokenId => whether permitted)
    mapping(address => mapping(uint => bool)) _permissionRecords;

    event TopUp(address payer, uint value);
    event Permit(address indexed owner, address targetNFTAddress, uint tokenId);
    event BatchPermit(address indexed owner, address[] targetNFTAddresses, uint[] tokenIds);
    event Achieved();

    constructor(
        address[] memory targetNFTAddresses,
        uint[] memory permissionNumbers,
        uint[] memory permissionFees
    )
    {
        uint len = targetNFTAddresses.length;
        require(len > 0, "zero length");
        require(len == permissionNumbers.length, "unmatched length for PN");
        require(len == permissionFees.length, "unmatched length for PF");
        _targetNFTAddresses = targetNFTAddresses;
        uint totalPermissionNumber = 0;
        for (uint i = 0; i < len; ++i) {
            address targetNFTAddr = targetNFTAddresses[i];
            uint permissionNumber = permissionNumbers[i];
            require(permissionNumber > 0, "zero PN");
            uint permissionFee = permissionFees[i];
            require(permissionFee > 0, "zero PF");
            _targetPermissionNumbers[targetNFTAddr] = permissionNumber;
            _targetPermissionFees[targetNFTAddr] = permissionFee;
            totalPermissionNumber += permissionNumber;
        }

        TOTAL_PERMISSION_NUMBER = totalPermissionNumber;
    }

    // permit by the target NFT's owner
    function permit(address nftAddress, uint tokenId) external {
        require(!_achieved, "achieved");
        uint targetPermissionNumber = _targetPermissionNumbers[nftAddress];
        require(targetPermissionNumber > 0, "not target nft");
        uint currentPermissionNumber = _currentPermissionNumbers[nftAddress];
        require(currentPermissionNumber < targetPermissionNumber, "reached target");
    unchecked{
        ++currentPermissionNumber;
    }
        _currentPermissionNumbers[nftAddress] = currentPermissionNumber;
        require(!_permissionRecords[nftAddress][tokenId], "already permitted");
        _permissionRecords[nftAddress][tokenId] = true;
    unchecked{
        ++_receivedPermissionNumber;
    }

        // check ownership
        address sender = msg.sender;
        require(IERC721(nftAddress).ownerOf(tokenId) == sender, "not owner");
        // transfer fee
        payable(sender).transfer(_targetPermissionFees[nftAddress]);
        emit Permit(sender, nftAddress, tokenId);

        // check goal achievement
        if (currentPermissionNumber == targetPermissionNumber &&
            _receivedPermissionNumber == TOTAL_PERMISSION_NUMBER) {
            _achieved = true;
            emit Achieved();
        }
    }

    // batch permit by the target NFT's owner
    function batchPermit(address[] calldata nftAddresses, uint[] calldata tokenIds) external {
        require(!_achieved, "achieved");
        uint len = nftAddresses.length;
        require(len == tokenIds.length, "unmatched length");
        // update _receivedPermissionNumber first
        uint receivedPermissionNumber = _receivedPermissionNumber;
        receivedPermissionNumber += len;
        _receivedPermissionNumber = receivedPermissionNumber;
        address sender = msg.sender;
        uint totalFee = 0;
        for (uint i = 0; i < len; ++i) {
            address nftAddress = nftAddresses[i];
            uint tokenId = tokenIds[i];
            uint targetPermissionNumber = _targetPermissionNumbers[nftAddress];
            require(targetPermissionNumber > 0, "not target nft");
            uint currentPermissionNumber = _currentPermissionNumbers[nftAddress];
            require(currentPermissionNumber < targetPermissionNumber, "reached target");
        unchecked{
            ++currentPermissionNumber;
        }
            _currentPermissionNumbers[nftAddress] = currentPermissionNumber;
            require(!_permissionRecords[nftAddress][tokenId], "already permitted");
            _permissionRecords[nftAddress][tokenId] = true;

            // check ownership
            require(IERC721(nftAddress).ownerOf(tokenId) == sender, "not owner");
            // sum fee
            totalFee += _targetPermissionFees[nftAddress];
        }

        // transfer total fee
        payable(sender).transfer(totalFee);
        emit BatchPermit(sender, nftAddresses, tokenIds);

        // check goal achievement
        if (receivedPermissionNumber == TOTAL_PERMISSION_NUMBER) {
            _achieved = true;
            emit Achieved();
        }
    }

    function refund(uint amount, address payable recipient) external onlyOwner {
        require(amount <= address(this).balance, "insufficient balance");
        recipient.transfer(amount);
    }

    receive() external payable {
        emit TopUp(msg.sender, msg.value);
    }

    function getReceivedPermissionNumber() public view returns (uint){
        return _receivedPermissionNumber;
    }

    function getAchieved() public view returns (bool){
        return _achieved;
    }

    function getTargetNFTAddressesLength() public view returns (uint){
        return _targetNFTAddresses.length;
    }

    function getTargetNFTAddresses(uint index) public view returns (address){
        return _targetNFTAddresses[index];
    }

    function getTargetPermissionNumbers(address targetNFTAddress) public view returns (uint){
        return _targetPermissionNumbers[targetNFTAddress];
    }

    function getTargetPermissionFees(address targetNFTAddress) public view returns (uint){
        return _targetPermissionFees[targetNFTAddress];
    }

    function getCurrentPermissionNumbers(address targetNFTAddress) public view returns (uint){
        return _currentPermissionNumbers[targetNFTAddress];
    }

    function getPermissionRecords(address targetNFTAddress, uint tokenId) public view returns (bool){
        return _permissionRecords[targetNFTAddress][tokenId];
    }
}
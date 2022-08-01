/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// File: libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
}

// File: interfaces/IDentistCoinNFT.sol


pragma solidity ^0.8.4;


interface IDentistCoinNFT is IERC721 {
    function setBaseURI(string memory _newBaseURI) external;

    function pause() external;

    function unpause() external;

    function mint(address to, uint256 tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);

    function TOKEN_LIMIT() external view returns (uint256);

    function totalNFTsMinted() external view returns (uint256);
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: DentistCoinNFTMarketPlace.sol


pragma solidity ^0.8.4;







/// @title DentistCoinNFTMarketPlace acts as the main marketplace contract for the community to buy DentistCoin NFTs and receive airdropped DentistCoin tokens.
contract DentistCoinNFTMarketPlace is Ownable, ReentrancyGuard, Pausable {
    struct NFTCategory {
        uint256 firstTokenId;
        uint256 lastTokenId;
        uint256 categoryPrice;
        uint256 dentistCoinAirdropAmount;
    }

    //CategoryId to CategoryDetails
    mapping(uint256 => NFTCategory) private _nftCategories;

    IDentistCoinNFT public dentistCoinNFT;
    IERC20 public dentistCoin;
    address payable internal fundsReceiver;

    event NFTPurchased(uint256 indexed tokenId, uint256 indexed categoryId, address indexed buyer);

    event CategoryPriceUpdated(uint256 indexed categoryId, uint256 indexed categoryPrice);

    event CategoryAirdropAmountUpdated(uint256 indexed categoryId, uint256 indexed airdropAmount);

    modifier ensureNonZeroAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "DentistCoinMarketPlace: No zero address");
        _;
    }

    modifier ensureValidCategory(uint256 _categoryId) {
        require(
            _categoryId > 0 && _categoryId < 20,
            "DentistCoinMarketPlace: Invalid NFT Category"
        );
        _;
    }

    /// @notice Contract constructor sets the addresses for DentistCoin Token, DentistCoin NFT and address to receive funds on sell of NFTs.
    constructor(
        IDentistCoinNFT _dentistCoinNFT,
        IERC20 _dentistCoin,
        address payable _fundsReceiver
    ) {
        dentistCoinNFT = _dentistCoinNFT;
        dentistCoin = _dentistCoin;
        fundsReceiver = _fundsReceiver;

        //Category => 1. Range => (1-4). Name => Sun. Price => 460 ether. AirdropAmount => 21 million DEN
        _nftCategories[1] = NFTCategory(1, 4, 460 ether, 21000000 * 1e18);

        //Category => 2. Range => (5-44). Name => Earth. Price => 230 ether. AirdropAmount => 8 million DEN
        _nftCategories[2] = NFTCategory(5, 44, 230 ether, 8000000 * 1e18);

        //Category => 3. Range => (45-99). Name => Moon. Price => 150 ether. AirdropAmount => 4.6 million DEN
        _nftCategories[3] = NFTCategory(45, 99, 150 ether, 4600000 * 1e18);

        //Category => 4. Range => (100-199). Name => Whale. Price => 80 ether. AirdropAmount => 2 million DEN
        _nftCategories[4] = NFTCategory(100, 199, 80 ether, 2000000 * 1e18);

        //Category => 5. Range => (200-309). Name => Dolphin. Price => 55 ether. AirdropAmount => 1 million DEN
        _nftCategories[5] = NFTCategory(200, 309, 55 ether, 1000000 * 1e18);

        //Category => 6. Range => (310-449). Name => Seal. Price => 45 ether. AirdropAmount => 700,000 DEN
        _nftCategories[6] = NFTCategory(310, 449, 45 ether, 700000 * 1e18);

        //Category => 7. Range => (450-499). Name => Mango/Coconut. Price => 36 ether. AirdropAmount => 540,000 DEN
        _nftCategories[7] = NFTCategory(450, 499, 36 ether, 540000 * 1e18);

        //Category => 8. Range => (500-799). Name => Watermelon. Price => 32 ether. AirdropAmount => 480,000 DEN
        _nftCategories[8] = NFTCategory(500, 799, 32 ether, 480000 * 1e18);

        //Category => 9. Range => (800-1099). Name => Pineapple. Price => 16 ether. AirdropAmount => 230,000 DEN
        _nftCategories[9] = NFTCategory(800, 1099, 16 ether, 230000 * 1e18);

        //Category => 10. Range => (1100-1499). Name => Kiwi/Berries. Price => 8 ether. AirdropAmount => 100,000 DEN
        _nftCategories[10] = NFTCategory(1100, 1499, 8 ether, 100000 * 1e18);

        //Category => 11. Range => (1500-2299). Name => Orange. Price => 4 ether. AirdropAmount => 48,000 DEN
        _nftCategories[11] = NFTCategory(1500, 2299, 4 ether, 48000 * 1e18);

        //Category => 12. Range => (2300-3499). Name => Strawberries/Cherries. Price => 2 ether. AirdropAmount => 22,000 DEN
        _nftCategories[12] = NFTCategory(2300, 3499, 2 ether, 22000 * 1e18);

        //Category => 13. Range => (3500-5499). Name => Peach/Apricot. Price => 0.8 ether. AirdropAmount => 9000 DEN
        _nftCategories[13] = NFTCategory(3500, 5499, 0.8 ether, 9000 * 1e18);

        //Category => 14. Range => (5500-5599). Name => Pear. Price => 0.4 ether. AirdropAmount => 4000 DEN
        _nftCategories[14] = NFTCategory(5500, 5599, 0.4 ether, 4000 * 1e18);

        //Category => 15. Range => (5600-5749). Name => Dental Chair. Price => 10 ether. AirdropAmount => 100,000 DEN
        _nftCategories[15] = NFTCategory(5600, 5749, 10 ether, 100000 * 1e18);

        //Category => 16. Range => (5750-5999). Name => Dental Implants. Price => 8 ether. AirdropAmount => 80,000 DEN
        _nftCategories[16] = NFTCategory(5750, 5999, 8 ether, 80000 * 1e18);

        //Category => 17. Range => (6000-6299). Name => Dental Handpiece. Price => 6 ether. AirdropAmount => 60,000 DEN
        _nftCategories[17] = NFTCategory(6000, 6299, 6 ether, 60000 * 1e18);

        //Category => 18. Range => (6300-6497). Name => Toothbrush and Floss. Price => 4 ether. AirdropAmount => 40,000 DEN
        _nftCategories[18] = NFTCategory(6300, 6497, 4 ether, 40000 * 1e18);

        //Category => 19. Range => (6498-6500). Name => VIP Combo. Price => 580 ether. AirdropAmount => 27 million DEN
        _nftCategories[19] = NFTCategory(6498, 6500, 580 ether, 27000000 * 1e18);
    }

    /**
     * @dev Get category details based on specified categoryId
     */
    function getCategoryDetails(uint256 _categoryId)
        external
        view
        ensureValidCategory(_categoryId)
        returns (NFTCategory memory nftCategory)
    {
        nftCategory = _nftCategories[_categoryId];
    }

    /**
     * @dev Validate tokenId with categoryId to see if the NFT belongs correctly to that category.
     */
    function validateTokenIdWithCategory(uint256 _tokenId, uint256 _categoryId)
        public
        view
        returns (bool)
    {
        NFTCategory memory nftCategory = _nftCategories[_categoryId];
        return
            _tokenId >= nftCategory.firstTokenId && _tokenId <= nftCategory.lastTokenId
                ? true
                : false;
    }

    /**
     * @dev Used to buy NFT(_tokenId) of category(_categoryId). Receiver (msg.sender) receives NFT and DEN tokens.
     */
    function buyNFT(uint256 _tokenId, uint256 _categoryId)
        external
        payable
        nonReentrant
        ensureValidCategory(_categoryId)
        ensureNonZeroAddress(msg.sender)
        whenNotPaused
    {
        require(
            validateTokenIdWithCategory(_tokenId, _categoryId),
            "DentistCoinMarketPlace: Invalid tokenId for this categoryId"
        );

        NFTCategory memory nftCategory = _nftCategories[_categoryId];

        require(!dentistCoinNFT.exists(_tokenId), "DentistCoinMarketPlace: NFT already minted");
        require(
            msg.value == nftCategory.categoryPrice,
            "DentistCoinMarketPlace: Exact funds not sent"
        );
        require(
            dentistCoin.balanceOf(address(this)) >= nftCategory.dentistCoinAirdropAmount,
            "DentistCoinMarketPlace: Not enough DEN tokens"
        );

        TransferHelper.safeTransferETH(fundsReceiver, nftCategory.categoryPrice);
        dentistCoinNFT.mint(msg.sender, _tokenId);
        TransferHelper.safeTransfer(
            address(dentistCoin),
            msg.sender,
            nftCategory.dentistCoinAirdropAmount
        );

        require(
            dentistCoinNFT.ownerOf(_tokenId) == address(msg.sender),
            "DentistCoinMarketPlace: Buyer hasn't received NFT"
        );

        emit NFTPurchased(_tokenId, _categoryId, msg.sender);
    }

    receive() external payable {}

    /**
     * @dev Used to withdraw any leftover ERC20 tokens in the contract.
     */
    function withdrawERC20(IERC20 _token) external onlyOwner nonReentrant {
        TransferHelper.safeTransfer(address(_token), msg.sender, _token.balanceOf(address(this)));
    }

    /**
     * @dev Used to withdraw any leftover Ether in the contract.
     */
    function withdrawReceivedEtherToOwner() external onlyOwner nonReentrant {
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }

    /**
     * @dev Can be used to pause NFT buy flow in emergency situations in case if there is any vulnerability found.
     * Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Can be used to unpause and resume normal NFT buy functionality.
     * Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Can be used to update category NFT purchase price.
     */
    function updateCategoryNFTPrice(uint256 _categoryId, uint256 _newCategoryPrice)
        external
        onlyOwner
        nonReentrant
        ensureValidCategory(_categoryId)
    {
        require(_newCategoryPrice > 0, "DentistCoinMarketPlace: New Price must be at least 1 wei");
        NFTCategory storage nftCategory = _nftCategories[_categoryId];
        nftCategory.categoryPrice = _newCategoryPrice;
        emit CategoryPriceUpdated(_categoryId, _newCategoryPrice);
    }

    /**
     * @dev Can be used to update category airdrop amount.
     */
    function updateCategoryAirdropAmount(uint256 _categoryId, uint256 _newAirdropAmount)
        external
        onlyOwner
        nonReentrant
        ensureValidCategory(_categoryId)
    {
        require(
            _newAirdropAmount > 0,
            "DentistCoinMarketPlace: New Airdrop Amount must be at least 1 wei"
        );
        NFTCategory storage nftCategory = _nftCategories[_categoryId];
        nftCategory.dentistCoinAirdropAmount = _newAirdropAmount;
        emit CategoryAirdropAmountUpdated(_categoryId, _newAirdropAmount);
    }

    /**
     * @dev Can be used to update DentistCoin ERC20 address if there is any mistake.
     */
    function updateDentistCoinAddress(IERC20 _dentistCoin)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_dentistCoin))
    {
        dentistCoin = _dentistCoin;
    }

    /**
     * @dev Can be used to update DentistCoin NFT address if there is any mistake.
     */
    function updateDentistCoinNFTAddress(IDentistCoinNFT _dentistCoinNFT)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_dentistCoinNFT))
    {
        dentistCoinNFT = _dentistCoinNFT;
    }

    /**
     * @dev Can be used to update funds receiver address if there is any mistake.
     */
    function updateFundsReceiver(address payable _newFundsReceiver)
        external
        onlyOwner
        nonReentrant
        ensureNonZeroAddress(address(_newFundsReceiver))
    {
        fundsReceiver = _newFundsReceiver;
    }
}
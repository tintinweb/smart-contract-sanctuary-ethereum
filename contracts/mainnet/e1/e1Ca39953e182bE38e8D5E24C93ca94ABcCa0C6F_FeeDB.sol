/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity ^0.8.12;


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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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

interface IFeeDB {
    event UpdateFeeAndRecipient(uint256 newFee, address newRecipient);
    event UpdatePaysFeeWhenSending(bool newType);
    event UpdateNFTDiscountRate(address nft, uint256 discountRate);
    event UpdateUserDiscountRate(address user, uint256 discountRate);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function paysFeeWhenSending() external view returns (bool);

    function userDiscountRate(address user) external view returns (uint256);

    function nftDiscountRate(address nft) external view returns (uint256);

    function getFeeDataForSend(address user, bytes calldata data)
        external
        view
        returns (
            bool _paysFeeWhenSending,
            address _recipient,
            uint256 _protocolFee,
            uint256 _discountRate
        );

    function getFeeDataForReceive(address user, bytes calldata data)
        external
        view
        returns (address _recipient, uint256 _discountRate);
}

contract FeeDB is Ownable, IFeeDB {
    uint256 public protocolFee; //out of 10000
    address public protocolFeeRecipient;
    bool public paysFeeWhenSending;
    mapping(address => uint256) public userDiscountRate; //out of 10000
    mapping(address => uint256) public nftDiscountRate;

    constructor(
        uint256 _protocolFee,
        address _protocolFeeRecipient,
        bool _paysFeeWhenSending
    ) {
        require(_protocolFee < 100, "max fee is 99"); //max 0.99%
        protocolFee = _protocolFee;
        protocolFeeRecipient = _protocolFeeRecipient;
        paysFeeWhenSending = _paysFeeWhenSending;

        emit UpdateFeeAndRecipient(_protocolFee, _protocolFeeRecipient);
        emit UpdatePaysFeeWhenSending(_paysFeeWhenSending);
    }

    function updateNFTDiscountRate(
        address[] calldata nfts,
        uint256[] calldata discountRates
    ) external onlyOwner {
        uint256 length = nfts.length;
        require(length == discountRates.length, "length is not equal");

        for (uint256 i = 0; i < length; i++) {
            require(discountRates[i] <= 10000, "max discount is 10000");
            nftDiscountRate[nfts[i]] = discountRates[i];
            emit UpdateNFTDiscountRate(nfts[i], discountRates[i]);
        }
    }

    function updateFeeAndRecipient(uint256 newFee, address newRecipient) external onlyOwner {
        require(newFee < 100, "max fee is 99");
        protocolFee = newFee;
        protocolFeeRecipient = newRecipient;
        emit UpdateFeeAndRecipient(newFee, newRecipient);
    }

    function togglePaysFeeWhenSending() external onlyOwner {
        bool old = paysFeeWhenSending;
        paysFeeWhenSending = !old;
        emit UpdatePaysFeeWhenSending(!old);
    }

    function updateUserDiscountRate(address[] calldata users, uint256[] calldata discountRates) external onlyOwner {
        require(users.length == discountRates.length, "length is not equal");
        for (uint256 i = 0; i < users.length; i++) {
            require(discountRates[i] <= 10000, "max discount is 10000");
            userDiscountRate[users[i]] = discountRates[i];
            emit UpdateUserDiscountRate(users[i], discountRates[i]);
        }
    }

    function getFeeDataForSend(address user, bytes calldata data)
        external
        view
        returns (
            bool _paysFeeWhenSending,
            address _recipient,
            uint256 _protocolFee,
            uint256 _discountRate
        )
    {
        _paysFeeWhenSending = paysFeeWhenSending;
        if (_paysFeeWhenSending) {
            _recipient = protocolFeeRecipient;
            if (_recipient == address(0)) return (_paysFeeWhenSending, address(0), 0, 0);
        }
        _protocolFee = protocolFee;

        uint256 _userDiscountRate = userDiscountRate[user];
        uint256 _nftDiscountRate = _getNFTDiscountRate(user, data);
        _discountRate = _userDiscountRate > _nftDiscountRate ? _userDiscountRate : _nftDiscountRate;
    }

    function getFeeDataForReceive(address user, bytes calldata data)
        external
        view
        returns (address _recipient, uint256 _discountRate)
    {
        _recipient = protocolFeeRecipient;

        if (_recipient != address(0)) {
            uint256 _userDiscountRate = userDiscountRate[user];
            uint256 _nftDiscountRate = _getNFTDiscountRate(user, data);
            _discountRate = _userDiscountRate > _nftDiscountRate ? _userDiscountRate : _nftDiscountRate;
        }
    }

    function _getNFTDiscountRate(address user, bytes calldata data) private view returns (uint256 _nftDiscountRate) {
        if (data.length > 0) {
            address nft = abi.decode(data, (address));
            if (nft != address(0)) {
                _nftDiscountRate = nftDiscountRate[nft];
                if(_nftDiscountRate == 0) return 0;
                require(IERC721(nft).balanceOf(user) > 0, "not nft holder");
            }
        }
    }
}
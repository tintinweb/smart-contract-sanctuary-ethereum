//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721.sol";

contract Dashboard is ReentrancyGuard {
    struct Admin {
        string email;
        address wallet;
        uint256 createdAt;
    }

    struct User {
        string fullName;
        string email;
        address wallet;
        uint16 level;
        uint64 investmentUpTo;
    }

    uint16 public investmentPerCard = 5000;

    // Available NFT Cards. Can be created by admins.
    address[] private _nftCards;

    // Mapping to easily find a specific NFT Card by the index.
    mapping(address => uint256) private _nftCardIndexes;

    // All authenticated holders. It's unique.
    string[] private _holderEmails;

    // Mapping for fast lookup
    mapping(address => uint256) private _emailIndexes;
    mapping(string => string) private _holderNames;
    mapping(string => address) private _holderAddresses;
    mapping(string => uint256) private _holderCreatedAt;

    mapping(address => bool) private _admins;
    mapping(address => string) private _adminEmails;
    mapping(address => uint256) private _adminCreatedAt;
    address[] private _adminAddresses;

    constructor() {
        _holderEmails.push(""); // ignore index 0 so we can use index 0 as an indication that the email is not in the list
        _admins[address(msg.sender)] = true;
        _adminAddresses.push(address(msg.sender));
        _adminCreatedAt[address(msg.sender)] = block.timestamp;
    }

    function addAdmin(address adminWallet) external onlyAdmins {
        if (!_admins[adminWallet]) {
            _admins[adminWallet] = true;
            _adminAddresses.push(adminWallet);
            _adminCreatedAt[adminWallet] = block.timestamp;
            _adminEmails[adminWallet] = "";
        }
    }

    function authenticate(string memory email, string memory fullName) external onlyCardHolders {
        if (_emailIndexes[address(msg.sender)] == 0) {
            _emailIndexes[address(msg.sender)] = _holderEmails.length;
            _holderEmails.push(email);
        } else {
            _holderEmails[_emailIndexes[address(msg.sender)]] = email;
        }
        _holderNames[email] = fullName;
        _holderAddresses[email] = address(msg.sender);
        _holderCreatedAt[email] = block.timestamp;
    }

    function addNftContract(address _nft) external onlyAdmins {
        if (_nftCardIndexes[_nft] == 0) {
            _nftCardIndexes[_nft] = _nftCards.length;
            _nftCards.push(_nft);
        }
    }

    function deleteAdmin(address adminWallet) external onlyAdmins {
        if (_admins[adminWallet]) {
            _admins[adminWallet] = false;
            for (uint256 i = 0; i < _adminAddresses.length; i++) {
                if (_adminAddresses[i] == adminWallet) {
                    _adminAddresses[i] = _adminAddresses[_adminAddresses.length - 1];
                    break;
                }
            }
            _adminAddresses.pop(); // remove the last item
            _adminEmails[adminWallet] = "";
        }
    }

    function getAdmins() external view returns (Admin[] memory) {
        Admin[] memory admins = new Admin[](_adminAddresses.length);
        for (uint256 i = 0; i < _adminAddresses.length; i++) {
            address adminAddress = _adminAddresses[i];
            admins[i] = Admin(_adminEmails[adminAddress], adminAddress, _adminCreatedAt[adminAddress]);
        }
        return admins;
    }

    function getCardCount(address wallet) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            count += nftCard.balanceOf(wallet);
        }
        return count;
    }

    function getNftCards() external view returns (address[] memory) {
        return _nftCards;
    }

    function getUserEmails() external view returns (string[] memory) {
        return _holderEmails;
    }

    function getUserCreatedAt(address wallet) external view returns (uint256) {
        string memory email = _holderEmails[_emailIndexes[wallet]];
        return _holderCreatedAt[email];
    }

    function getUsers() external view returns (User[] memory) {
        User[] memory users = new User[](_holderEmails.length - 1);
        for (uint256 i = 1; i < _holderEmails.length; i++) {
            string memory email = _holderEmails[i];
            address wallet = _holderAddresses[email];
            string memory fullName = _holderNames[email];
            uint256 cardCount = getCardCount(wallet);
            uint64 investmentUpTo = uint64(cardCount * investmentPerCard);
            users[i - 1] = User(
                fullName,
                email,
                wallet,
                12, // ???
                investmentUpTo
            );
        }
        return users;
    }

    function isAdmin(address walletAddress) external view returns (bool) {
        return _admins[walletAddress];
    }

    function isAuthenticated(address walletAddress) external view returns (bool) {
        return _emailIndexes[walletAddress] > 0;
    }

    function ownsNftCard(address wallet) public view returns (bool) {
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            if (nftCard.balanceOf(wallet) > 0) return true;
        }
        return false;
    }

    /**
        @dev Replaces from's email and address with the last email and address in the arrays.
     */
    function signOut(address from) public {
        require(from == address(msg.sender) || _admins[address(msg.sender)], "Dashboard: Only admins or the user itself can sign out");
        uint256 fromEmailIdx = _emailIndexes[from];
        uint256 lastEmailIdx = _holderEmails.length - 1;
        _holderEmails[fromEmailIdx] = _holderEmails[lastEmailIdx];
        _holderEmails.pop();
    }

    function updateAdminEmail(string memory email) external onlyAdmins {
        _adminEmails[address(msg.sender)] = email;
    }

    function updateInvestmentPerCard(uint16 value) external onlyAdmins {
        investmentPerCard = value;
    }

    modifier onlyAdmins() {
        require(_admins[address(msg.sender)], "Not admin");
        _;
    }

    modifier onlyCardHolders() {
        require(ownsNftCard(address(msg.sender)), "Not a card holder");
        _;
    }

    modifier onlyFromNft() {
        for (uint256 i = 0; i < _nftCards.length; i++) {
            if (_nftCards[i] == address(msg.sender)) return;
        }
        require(false, "Only callable from VCX NFT Contract");
        _;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGovernanceToken {
    function safeMint(address to) external returns (uint256); 
}

contract UserRegistry {

    address owner;
    address handler;
    address governanceToken;

    struct User {
        /* string name; */
        uint256 level;
        bool registered;
        uint256 appreciationBalance;
        uint256 contributionBalance;
        uint256 appreciationsTaken;
        uint256 appreciationsGiven;
        uint256 takenAmt;
        uint256 givenAmt;
        uint256 tokenId;
        bool tokenHolder;
    }

    mapping(address => User) public users;
    event UserRegistered(address indexed id);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(string memory des) {
        require(msg.sender == owner, des);
        _;
    }
    
    modifier onlyHandler(string memory des) {
        require(msg.sender == handler, des);
        _;
    }
    
    modifier onlyGovernanceToken(string memory des) {
        require(msg.sender == governanceToken, des);
        _;
    }

    function setHandler(address _handler) public onlyOwner("Only owner can update handler") {
        handler = _handler;
    }

    function setGovernanceToken(address _tokenAddr) external onlyOwner("Only owner can update governanceTokenAddr") {
        governanceToken = _tokenAddr;
    }

    function registerUser() external {
        require(!users[msg.sender].registered, "User already registered");
        users[msg.sender] = User(
           /*  generateRandomUsername(), */
            1,
            true,
            0 wei,
            0 wei,
            0,
            0,
            0 wei,
            0 wei,
            0,
            false
        );
        emit UserRegistered(msg.sender);
    }

    function addContributionBal(address userAddr) public payable returns (bool) {
        require(users[userAddr].registered, "User not registered");
        User storage user = users[userAddr];
        user.contributionBalance = user.contributionBalance + msg.value;
        return true;
    }

    function updateAppreciator(address appreciator, uint256 amt) external onlyHandler("Can't update") returns (bool){
        User storage user = users[appreciator];
        require(user.contributionBalance > amt, "insufficient contribution balance");
        user.appreciationsGiven++;
        user.givenAmt = user.givenAmt + amt;
        user.contributionBalance = user.contributionBalance - amt;
        return true;
    }

    function updateCreator(address creator, uint256 amt) external onlyHandler("Can't update") returns (bool) {
        User storage user = users[creator];
        user.appreciationBalance = user.appreciationBalance + amt;
        user.appreciationsTaken++;
        user.takenAmt = user.takenAmt + amt;
        return true;
    }

    // restrict to be only called by handler
    function withdraw(address creator, uint256 fee, uint256 withdrawalThresholdInEth) external onlyHandler("Can't withdraw") {
        User storage user = users[creator];
        user.level++;
        user.appreciationBalance -= withdrawalThresholdInEth;
        user.contributionBalance += fee;
    }

    function setTokenId(address _user, uint256 _tokenId) external onlyGovernanceToken("Only governance token can update tokenId") {
        IERC721 nft = IERC721(governanceToken);
        require(_user == nft.ownerOf(_tokenId), "Token owner can update details");
        User storage user = users[_user];
        user.tokenId = _tokenId;
        user.tokenHolder = true;
    }

    function getUserDetails(address user) external view returns (User memory) {
        return users[user];
    }

    function isRegistered(address _user) public view returns (bool) {
        return users[_user].registered;
    } 

    function mintCaringToken() external {
        IGovernanceToken tokenContract = IGovernanceToken(governanceToken); 
        tokenContract.safeMint(msg.sender);
    }

    /* function generateRandomUsername() internal view returns (string memory) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            block.prevrandao
        )));
        return string(abi.encodePacked("User_", randomNumber));
    } */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
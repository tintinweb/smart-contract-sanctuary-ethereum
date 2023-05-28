/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// File: github.com/OpenZeppelin/openzeppelin-solidity/contracts/utils/introspection/IERC165.sol


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

// File: github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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

// File: contracts/AAS-Pool.sol



pragma solidity ^0.8.4;


contract AASPool {
    struct Poll {
        string question;
        string[] options;
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint) votes;
        mapping(uint => uint) results;
    }

    address public constant ANGRY_APES_ADDRESS = 0xFA969C60a78195C631787D4585BA15a07578C979;
    address public constant ANGRY_RIDERS_ADDRESS = 0xb0b3D18c186Ffc8b8A40476272F16B23EdF2342C;
    address public constant PORTAL_PASS_ADDRESS = 0x50ca8e24D80946B9ccF4A15279DfF9eafde7e240;

    address public owner;
    Poll[] public polls;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPoll(string memory question, string[] memory options, uint256 startTime, uint256 endTime) public onlyOwner {
        require(startTime < endTime, "Start time must be less than end time");
        Poll storage newPoll = polls.push();
        newPoll.question = question;
        newPoll.options = options;
        newPoll.startTime = startTime;
        newPoll.endTime = endTime;
    }

    function vote(uint pollIndex, uint optionIndex) public {
    // Controlla se l'utente possiede almeno un NFT di una delle collezioni
        require(
            IERC721(ANGRY_APES_ADDRESS).balanceOf(msg.sender) > 0 ||
            IERC721(ANGRY_RIDERS_ADDRESS).balanceOf(msg.sender) > 0 ||
            IERC721(PORTAL_PASS_ADDRESS).balanceOf(msg.sender) > 0,
                "You must own at least one AAS NFT to vote"
        );

    }

    function getOptions(uint pollIndex) public view returns (string[] memory) {
        return polls[pollIndex].options;
    }

    function getResults(uint pollIndex) public view returns (uint[] memory) {
        uint[] memory results = new uint[](polls[pollIndex].options.length);
        for(uint i = 0; i < polls[pollIndex].options.length; i++) {
            results[i] = polls[pollIndex].results[i];
        }
        return results;
    }

    function getPollsCount() public view returns (uint) {
    return polls.length;
    }

    function getStatus(uint pollIndex) public view returns (string memory) {
    if(block.timestamp < polls[pollIndex].startTime) {
        return "Pending";
    } else if(block.timestamp <= polls[pollIndex].endTime) {
        return "Active";
    } else {
        return "Ended";
    }
}


}
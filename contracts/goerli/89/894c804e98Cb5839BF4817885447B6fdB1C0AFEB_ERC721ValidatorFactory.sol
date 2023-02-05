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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Validator {
    event Validation(
        address validatorAddr,
        string validatorId,
        address nftAddr,
        address userAddr,
        bytes32 verificationHash,
        bool result
    );

    event RegisterNFT(
        address validatorAddr,
        string validatorId,
        address NFTAddr,
        address from
    );
    event UnregisterNFT(
        address validatorAddr,
        string validatorId,
        address NFTAddr,
        address from
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    address owner;
    bool public isActive;
    address[] public nfts;
    string validatorId;

    mapping(address => bytes32) private userSecrets;

    constructor(string memory _validatorId) {
        owner = msg.sender;
        isActive = true;
        validatorId = _validatorId;
    }

    function setSecret(bytes32 _secret) public {
        userSecrets[msg.sender] = _secret;
    }

    function validate(string memory _userSessionId) public {
        require(nfts.length > 0, "Empty NFT collection");
        require(
            userSecrets[msg.sender] != bytes32(0),
            "userSecret not initialized"
        );
        bool found = false;
        uint balance = 0;
        address nft = address(0x0);
        uint i = 0;
        for (i = 0; i < nfts.length; i++) {
            balance = 0;
            IERC721 ierc721 = IERC721(nfts[i]);
            balance = ierc721.balanceOf(msg.sender);
            if (balance > 0) {
                found = true;
                nft = nfts[i];
                break;
            }
        }
        bytes32 verificationHash = keccak256(
            abi.encode(_userSessionId, userSecrets[msg.sender])
        );
        emit Validation(
            address(this),
            validatorId,
            nft,
            msg.sender,
            verificationHash,
            found
        );
    }

    function getNFTs() public view returns (address[] memory) {
        return nfts;
    }

    function registerNFT(address _nftAddr) public onlyOwner {
        nfts.push(_nftAddr);
        emit RegisterNFT(address(this), validatorId, _nftAddr, msg.sender);
    }

    function removeNFT(address _nftAddr) public onlyOwner {
        uint newLength = 0;
        bool found = false;
        for (uint idx = 0; idx < nfts.length; idx++) {
            if (nfts[idx] != _nftAddr) {
                nfts[newLength] = nfts[idx];
                newLength++;
            } else found = true;
        }
        nfts.pop();
        emit UnregisterNFT(address(this), validatorId, _nftAddr, msg.sender);
    }

    function activate() public onlyOwner {
        isActive = true;
    }

    function deactivate() public onlyOwner {
        isActive = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./ERC721Validator.sol";

contract ERC721ValidatorFactory {
    event NewERC721Validator(
        address validatorAddr,
        string validatorId,
        address ownerAddr
    );

    function newERC721Validator(string memory _validatorId) public {
        address erc721ValidatorAddr = address(
            new ERC721Validator(_validatorId)
        );
        emit NewERC721Validator(erc721ValidatorAddr, _validatorId, msg.sender);
    }
}
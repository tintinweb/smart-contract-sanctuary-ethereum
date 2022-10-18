// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Distributor {
    address public IVY_BOYS_ADDRESS =
        0x809D8f2B12454FC07408d2479cf6DC701ecD5a9f;
    address public SERUM_ADDRESS;
    address public owner;
    address public UPGRADED_PET_ADDRESS;
    bool public isClaimActive;
    bool public isUpgradingActive;

    constructor() {
        owner = msg.sender;
    }

    event Claim(address indexed _claimer, uint256 indexed _tokenId);

    address[3] public petContracts;
    mapping(uint256 => bool) public ivyBoysTokensUsed;

    function mint(uint256[] calldata tokens) external {
        require(isClaimActive, "Claim is not active");
        // Verify token ownership and ensure it has not been used for claim before
        for (uint256 i; i < tokens.length; i++) {
            require(
                IIvyBoys(IVY_BOYS_ADDRESS).ownerOf(tokens[i]) == msg.sender,
                "Not owner of token"
            );
            require(!ivyBoysTokensUsed[tokens[i]], "Tokens already used");
            ivyBoysTokensUsed[tokens[i]] = true;
            emit Claim(msg.sender, tokens[i]);
        }

        // mintCounts[i] represents the number minted for pet i where 0 = dog, 1 = cat, 2 = bear
        uint256[3] memory mintCounts;
        for (uint256 i; i < tokens.length; i++) {
            uint256 petType = randomise(i);
            mintCounts[petType]++;
        }

        for (uint256 i; i < petContracts.length; i++) {
            if (mintCounts[i] > 0) {
                address petContract = petContracts[i];
                IIvyPet(petContract).mint(mintCounts[i], msg.sender);
            }
        }
    }

    function upgradePets(uint256[][3] calldata _tokenIds, uint8 _serumCount)
        external
    {
        require(isUpgradingActive, "Upgrading not active");
        require(IIvyBoys(IVY_BOYS_ADDRESS).balanceOf(msg.sender) > 0, "Need at least one ivy boy");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IIvyPet(petContracts[i]).upgrade(_tokenIds[i], _serumCount);
        }
        uint256 mintCount = _tokenIds[0].length + _tokenIds[1].length + _tokenIds[2].length;
        ISerum(SERUM_ADDRESS).burnExternal(
            _serumCount * mintCount,
            msg.sender
        );
        IUpgradedPets(UPGRADED_PET_ADDRESS).mint(mintCount, msg.sender);
    }

    // ==== SETTERS ====

    function setPetContracts(
        address _dog,
        address _cat,
        address _bear
    ) external onlyOwner {
        petContracts = [_dog, _cat, _bear];
    }

    function setIvyBoysTokenUsed(uint256[] calldata _tokens, bool[] calldata _values) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            ivyBoysTokensUsed[_tokens[i]] = _values[i];
        }
    }

    function setIvyBoysContract(address _address) external onlyOwner {
        IVY_BOYS_ADDRESS = _address;
    }

    function setUpgradedPets(address _address) external onlyOwner {
        UPGRADED_PET_ADDRESS = _address;
    }

    function setSerum(address _address) public onlyOwner {
        SERUM_ADDRESS = _address;
    }

    function setSwitches(bool _claim, bool _upgrade) public onlyOwner {
        isClaimActive = _claim;
        isUpgradingActive = _upgrade;
    }

    // ==== UTIL ====

    function getTokenClaimed(uint256[] calldata _tokens) public view returns (bool[] memory) {
        bool[] memory claimedTokens = new bool[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            claimedTokens[i] = ivyBoysTokensUsed[_tokens[i]];
        }
        return claimedTokens;
    }

    function getPetTokens(address _address) public view returns (uint256[][3] memory) {
        uint256[][3] memory output;
        for (uint i = 0; i < 3; i++) {
            output[i] = IIvyPet(petContracts[i]).tokensOfOwner(_address);
        }
        return output;
    }

    function randomise(uint256 i) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        block.difficulty,
                        i
                    )
                )
            ) % 3;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by owner");
        _;
    }
}

interface IIvyPet {
    function mint(uint256 _quantity, address _minter) external;
    function upgrade(uint256[] calldata _tokenIds, uint8 _serumCount) external;
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

interface IIvyBoys {
    function ownerOf(uint256 token_id) external returns (address);
    function balanceOf(address _owner) external view returns (uint256);
}

interface ISerum {
    function burnExternal(uint256 _amount, address _caller) external;
}

interface IUpgradedPets {
    function mint(uint256 _quantity, address _minter) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
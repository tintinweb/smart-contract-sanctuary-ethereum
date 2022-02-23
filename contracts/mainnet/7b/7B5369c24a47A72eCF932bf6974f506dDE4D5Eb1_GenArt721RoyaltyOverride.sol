// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../interfaces/0.8.x/IArtblocksRoyaltyOverride.sol";
import "../interfaces/0.8.x/IGenArt721CoreContractV3.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

pragma solidity 0.8.9;

/**
 * @title Royalty Registry override for Art Blocks token contracts.
 * @author Art Blocks Inc.
 */
contract GenArt721RoyaltyOverride is ERC165, IArtblocksRoyaltyOverride {
    /**
     * @notice Art Blocks royalty payment address for `contractAddress`
     * updated to be `artblocksRoyaltyAddress`.
     */
    event ArtblocksRoyaltyAddressForContractUpdated(
        address indexed contractAddress,
        address payable indexed artblocksRoyaltyAddress
    );

    /**
     * @notice Art Blocks royalty payment basis points for `tokenAddress`
     * updated to be `bps` if `useOverride`, else updated to use default
     * BPS.
     */
    event ArtblocksBpsForContractUpdated(
        address indexed tokenAddress,
        bool indexed useOverride,
        uint256 bps
    );

    /// token contract => Art Blocks royalty payment address
    mapping(address => address payable)
        public tokenAddressToArtblocksRoyaltyAddress;

    struct BpsOverride {
        bool useOverride;
        uint256 bps;
    }

    /// Default Art Blocks royalty basis points if no BPS override is set.
    uint256 public constant ARTBLOCKS_DEFAULT_BPS = 250; // 2.5 percent
    /// token contract => if bps override is set, and bps value.
    mapping(address => BpsOverride) public tokenAddressToArtblocksBpsOverride;

    modifier onlyAdminOnContract(address _tokenContract) {
        require(
            IGenArt721CoreContractV3(_tokenContract).admin() == msg.sender,
            "Only core admin for specified token contract"
        );
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            // register interface 0x9ca7dc7a - getRoyalties(address,uint256)
            interfaceId == type(IArtblocksRoyaltyOverride).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Updates Art Blocks royalty payment address for `_tokenContract`
     * to be `_artblocksRoyaltyAddress`.
     * @param _tokenContract Token contract to be updated.
     * @param _artblocksRoyaltyAddress Address to receive royalty payments.
     */
    function updateArtblocksRoyaltyAddressForContract(
        address _tokenContract,
        address payable _artblocksRoyaltyAddress
    ) external onlyAdminOnContract(_tokenContract) {
        tokenAddressToArtblocksRoyaltyAddress[
            _tokenContract
        ] = _artblocksRoyaltyAddress;
        emit ArtblocksRoyaltyAddressForContractUpdated(
            _tokenContract,
            _artblocksRoyaltyAddress
        );
    }

    /**
     * @notice Updates Art Blocks royalty payment BPS for `_tokenContract` to be
     * `_bps`.
     * @param _tokenContract Token contract to be updated.
     * @param _bps Art Blocks royalty basis points.
     * @dev `_bps` must be less than or equal to default bps
     */
    function updateArtblocksBpsForContract(address _tokenContract, uint256 _bps)
        external
        onlyAdminOnContract(_tokenContract)
    {
        require(
            _bps <= ARTBLOCKS_DEFAULT_BPS,
            "override bps for contract must be less than or equal to default"
        );
        tokenAddressToArtblocksBpsOverride[_tokenContract] = BpsOverride(
            true,
            _bps
        );
        emit ArtblocksBpsForContractUpdated(_tokenContract, true, _bps);
    }

    /**
     * @notice Clears any overrides of Art Blocks royalty payment BPS for
     *  `_tokenContract`.
     * @param _tokenContract Token contract to be cleared.
     * @dev token contracts without overrides use default BPS value.
     */
    function clearArtblocksBpsForContract(address _tokenContract)
        external
        onlyAdminOnContract(_tokenContract)
    {
        tokenAddressToArtblocksBpsOverride[_tokenContract] = BpsOverride(
            false,
            0
        ); // initial values
        emit ArtblocksBpsForContractUpdated(_tokenContract, false, 0);
    }

    /**
     * @notice Gets royalites of token ID `_tokenId` on token contract
     * `_tokenAddress`.
     * @param _tokenAddress Token contract to be queried.
     * @param _tokenId Token ID to be queried.
     * @return recipients_ array of royalty recipients
     * @return bps array of basis points for each recipient, aligned by index
     */
    function getRoyalties(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        recipients_ = new address payable[](3);
        bps = new uint256[](3);
        // get standard royalty data for artist and additional payee
        (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        ) = IGenArt721CoreContractV3(_tokenAddress).getRoyaltyData(_tokenId);
        // translate to desired output
        recipients_[0] = payable(artistAddress);
        bps[0] = (uint256(100) - additionalPayeePercentage) * royaltyFeeByID;
        recipients_[1] = payable(additionalPayee);
        bps[1] = additionalPayeePercentage * royaltyFeeByID;
        // append art blocks royalty
        require(
            tokenAddressToArtblocksRoyaltyAddress[_tokenAddress] != address(0),
            "Art Blocks royalty address must be defined for contract"
        );
        recipients_[2] = tokenAddressToArtblocksRoyaltyAddress[_tokenAddress];
        bps[2] = tokenAddressToArtblocksBpsOverride[_tokenAddress].useOverride
            ? tokenAddressToArtblocksBpsOverride[_tokenAddress].bps
            : ARTBLOCKS_DEFAULT_BPS;
        return (recipients_, bps);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity ^0.8.0;

/**
 * @notice Interface for Art Blocks Royalty override.
 * Supported by the Royalty Registry v1 Engine.
 * @dev  ref: https://royaltyregistry.xyz / engine-v1.royaltyregistry.eth
 */
interface IArtblocksRoyaltyOverride is IERC165 {
    /**
     * @notice Gets royalites of token ID `_tokenId` on token contract
     * `_tokenAddress`.
     * @param tokenAddress Token contract to be queried.
     * @param tokenId Token ID to be queried.
     * @return recipients_ array of royalty recipients
     * @return bps array of basis points for each recipient, aligned by index
     * @dev Interface ID:
     *
     * bytes4(keccak256('getRoyalties(address,uint256)')) == 0x9ca7dc7a
     *
     * => 0x9ca7dc7a = 0x9ca7dc7a
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IGenArt721CoreContractV3 {
    /**
     * @notice Token ID `_tokenId` minted on project ID `_projectId` to `_to`.
     */
    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    // getter function of public variable
    function admin() external view returns (address);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(uint256 tokenId)
        external
        view
        returns (uint256 projectId);

    function isWhitelisted(address sender) external view returns (bool);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToAdditionalPayee(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToAdditionalPayeePercentage(uint256 _projectId)
        external
        view
        returns (uint256);

    // @dev new function in V3 (deprecated projectTokenInfo)
    function projectInfo(uint256 _projectId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            address,
            uint256
        );

    function artblocksAddress() external view returns (address payable);

    function artblocksPercentage() external view returns (uint256);

    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);

    function getRoyaltyData(uint256 _tokenId)
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
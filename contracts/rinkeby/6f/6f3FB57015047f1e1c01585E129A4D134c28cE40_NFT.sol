// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/*
 *  ██████╗ ██████╗ ███████╗███████╗███████╗███████╗    ███████╗██████╗ ███████╗███╗   ██╗███████╗
 * ██╔════╝██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝    ██╔════╝██╔══██╗██╔════╝████╗  ██║██╔════╝
 * ██║     ██║   ██║█████╗  █████╗  █████╗  █████╗      █████╗  ██████╔╝█████╗  ██╔██╗ ██║███████╗
 * ██║     ██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══╝      ██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║╚════██║
 * ╚██████╗╚██████╔╝██║     ██║     ███████╗███████╗    ██║     ██║  ██║███████╗██║ ╚████║███████║
 *  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝
 */

// Imports
import "./Reveal.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

/**
 * @title The Coffee Frens NFT smart contract.
 */
contract NFT is ERC721A, AccessControl, Ownable, Reveal {
    /// @notice Minter Access Role - allows users and smart contracts with this role to mint standard tokens (not reserves).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice The amount of available NFT tokens (including the reserved tokens).
    uint256 public numTotalTokens;
    /// @notice The amount of reserved NFT tokens.
    uint256 public numReservedTokens;
    /// @notice Indicates if the reserves have been minted.
    bool public areReservesMinted = false;

    /**
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param unrevealedUri The URL of a media that is shown for unrevealed NFTs.
     * @param numTotalTokens_ The total amount of available NFT tokens (including the reserved tokens).
     * @param numReservedTokens_ The amount of reserved NFT tokens.
     * @dev The contract constructor
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory unrevealedUri,
        uint256 numTotalTokens_,
        uint256 numReservedTokens_
    ) ERC721A(tokenName, tokenSymbol) Reveal(unrevealedUri) {
        // Set the roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        // Set the variables.
        numTotalTokens = numTotalTokens_;
        numReservedTokens = numReservedTokens_;
    }

    /**
      * @notice Grants the specified address the minter role.
      * @param minter The address to grant the minter role.
      */
    function setMinterRole(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, minter);
    }

    /**
      * @notice Mints the NFT tokens.
      * @param recipient The NFT tokens recipient.
      * @param quantity The number of NFT tokens to mint.
      */
    function mint(address recipient, uint256 quantity) external onlyRole(MINTER_ROLE) {
        // Reserves should be minted before minting standard tokens.
        require(
            areReservesMinted == true,
            "RESERVED_TOKENS_NOT_MINTED"
        );
        // Check that the number of tokens to mint does not exceed the total amount.
        require(
            totalSupply() + quantity <= numTotalTokens,
            "MAX_SUPPLY_EXCEEDED"
        );
        // Mint the tokens.
        _safeMint(recipient, quantity);
    }

    /**
      * @notice Mints the reserved NFT tokens.
      * @param recipient The NFT tokens recipient.
      * @param quantity The number of NFT tokens to mint.
      */
    function mintReserves(address recipient, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check if there are any reserved tokens available to mint.
        require(
            areReservesMinted == false,
            "RESERVED_TOKENS_ALREADY_MINTED"
        );
        // Check if the desired quantity of the reserved tokens to mint doesn't exceed the reserve.
        require(
            totalSupply() + quantity <= numReservedTokens,
            "RESERVED_SUPPLY_EXCEEDED"
        );
        uint256 numTokensToMint = quantity;
        if (quantity == 0) {
            // Set the number of tokens to mint to all available reserved tokens.
            numTokensToMint = numReservedTokens - totalSupply();
        }
        // Mint the tokens.
        _safeMint(recipient, numTokensToMint);
        // Set the flag only if we have minted the whole reserve.
        areReservesMinted = totalSupply() == numReservedTokens;
    }

    /**
      * @notice Returns a URI of an NFT.
      * @param tokenId The ID of the NFT.
      */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _getTokenUri(tokenId);
    }

    /**
     * @notice Returns true if this contract implements the interface defined by interfaceId.
     * @dev The following functions are overrides required by Solidity.
     * @param interfaceId The interface ID.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the base URI.
     */
    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return getBaseUri();
    }
}
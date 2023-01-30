// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";

// ====================================== //
//  ███████╗██╗     ██████╗ ███╗   ██╗    //
//  ╚════██║██║     ██╔══██╗████╗  ██║    //
//      ██╔╝██║     ██████╔╝██╔██╗ ██║    //
//     ██╔╝ ██║     ██╔══██╗██║╚██╗██║    //
//     ██║  ███████╗██████╔╝██║ ╚████║    //
//     ╚═╝  ╚══════╝╚═════╝ ╚═╝  ╚═══╝    //
// ====================================== //

// Special thanks to Chiru Labs' ERC721A contract

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract LBNSpecials is ERC721A, ERC721ABurnable, ERC721AQueryable, DefaultOperatorFilterer, Ownable, ERC2981 {
    constructor() ERC721A("7LBN Specials", "7LBN-S") {
        tokenUriBase = "ipfs://QmSPfVTDd56UbqQDofWby4SyxQq2Yn3Hq1NPx7FKh78KLJ";
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
        ERC721A.supportsInterface(interfaceId)
        ||
        ERC2981.supportsInterface(interfaceId);
    }



    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    uint256 public MAX_SUPPLY = 12;

    string public tokenUriBase;

    function airDropSpecials(uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        uint256 amountToMint;
        for (uint256 i = 0; i < amount.length; ++i) {
            amountToMint += amount[i];
        }
        if(_totalMinted() + amountToMint > MAX_SUPPLY) _revert(NoRemainingSupply.selector);

        for(uint256 i = 0; i < owners.length; ++i) {
            _safeMint(owners[i], amount[i]);
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
    }

    function setTokenURI(string memory newUriBase) public onlyOwner {
        tokenUriBase = newUriBase;
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // =============================================================
    //                     OPERATOR FILTER REGISTRY
    // =============================================================

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    error NoRemainingSupply();
}
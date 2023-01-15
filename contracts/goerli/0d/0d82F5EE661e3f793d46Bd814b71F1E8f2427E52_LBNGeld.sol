// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";

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

contract LBNGeld is ERC721A, ERC721ABurnable, ERC721AQueryable, DefaultOperatorFilterer, Ownable, ERC2981 {
    constructor() ERC721A("7LBN Weapon Geld", "7LBN-WG") {
        mintIsOpen = false;
        normalUri = "ipfs://QmRUrwhHEJEyzG3dpf6tWUbjchNDHzR4Qe2ctUw9tTSZdh";
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

    event newGeld(uint256 LBNId, uint256 geldId, address minter);

    bool public mintIsOpen;

    uint256 public MAX_SUPPLY = 10000;

    string normalUri;

    address public LBNContractAddress;

    mapping (uint256 => bool) public claimedLBN;
    mapping (uint256 => uint256) public geldToLBN;
    mapping (uint256 => string) customURIs;

    function mint(uint256[] calldata LBNIds) public {
        if(!mintIsOpen) _revert(MintNotActive.selector);

        uint256 length = LBNIds.length;
        if(_totalMinted() + length > MAX_SUPPLY) _revert(NoRemainingSupply.selector);

        ERC721A externalToken = ERC721A(LBNContractAddress);

        for(uint256 i = 0; i < length; ++i) {
            if(externalToken.ownerOf(LBNIds[i]) != msg.sender) _revert(InvalidOwner.selector);
            if(claimedLBN[LBNIds[i]]) _revert(ClaimedOwner.selector);

            uint256 currentIndex = _nextTokenId();

            claimedLBN[LBNIds[i]] = true;
            geldToLBN[currentIndex] = LBNIds[i];

            _safeMint(msg.sender, 1);
            emit newGeld(LBNIds[i], currentIndex, msg.sender);
        }
    }

    function airDropGeld(uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        uint256 amountToMint;
        for (uint256 i = 0; i < amount.length; ++i) {
            amountToMint += amount[i];
        }
        if(_totalMinted() + amountToMint > MAX_SUPPLY) _revert(NoRemainingSupply.selector);

        for(uint256 i = 0; i < owners.length; ++i) {
            _safeMint(owners[i], amount[i]);
        }
    }

    function toggleMint() public onlyOwner {
        mintIsOpen = !mintIsOpen;
    }

    function setLBNAddress(address newAddress) public onlyOwner {
        LBNContractAddress = newAddress;
    }

    function setNewTokenURI(uint256 typeOfURI, uint256 tokenId, string calldata newURI) public onlyOwner {
        if(typeOfURI == 0)
            normalUri = newURI;
        else
            customURIs[tokenId] = newURI;
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return (bytes(customURIs[tokenId]).length == 0) ? normalUri : customURIs[tokenId];
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

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
    unchecked {
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
    }
        if (!_transferETH(withdrawAddress, amount)) _revert(WithdrawFailed.selector);
    }

    /**
     * @notice Internal function to transfer ETH to a specified address.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30000 }(new bytes(0));
        return success;
    }

    error WithdrawFailed();
    error NoRemainingSupply();
    error MintNotActive();
    error InvalidOwner();
    error ClaimedOwner();
}
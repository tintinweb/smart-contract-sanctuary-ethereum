// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./MinterAccessControl.sol";

contract NFTHome is Context, ERC721Enumerable, Ownable, MinterAccessControl {

    /// @dev a string of base uri for this nft
    string private baseURI;

    /**
      * @dev Fired in updateBaseURI()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param uri a stringof base uri for this nft
    */
    event UpdateBaseUri(address indexed sender, string uri);

    /**
     * @dev Creates/deploys an instance of the NFT
   *
   * @param name_ the name of this nft
   * @param symbol_ the symbol of this nft
   * @param uri_ a stringof base uri for this nft
   */
    constructor (
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC721(name_, symbol_) {
        baseURI = uri_;
        _grantMinterRole(_msgSender());
    }

    /**
      * @notice Service function to update base uri
    *
    * @dev this function can only be called by owner
    *
    * @param uri_ a string for updating base uri
    */
    function updateBaseURI(string memory uri_) public virtual onlyOwner {
        baseURI = uri_;
        emit UpdateBaseUri(_msgSender(), uri_);
    }

    /**
      * @notice Service function to mint nft
    *
    * @dev this function can only be called by minter
    *
    * @param to_ an address which received nft
    * @param tokenId_ a number of id to be minted
    */
    function safeMint(address to_, uint256 tokenId_) external virtual onlyMinter {
        _safeMint(to_, tokenId_);
    }

    /**
      * @notice Service function to mint nft
    *
    * @dev this function can only be called by minter
    *
    * @param to_ an address which received nft
    * @param ids_ a number of id to be minted
    */
    function safeBatchMint(address to_, uint256[] memory ids_) external virtual onlyMinter {
        for (uint256 index; index < ids_.length; index++) {
            _safeMint(to_, ids_[index]);
        }
    }

    /**
      * @dev Burns `tokenId`. See {ERC721-_burn}.
    *
    * Requirements:
    *
    * - The caller must own `tokenId` or be an approved operator.
    */
    function burn(uint256 tokenId_) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "caller is not owner nor approved");
        _burn(tokenId_);
    }


    /**
      * @dev Additionally to the parent smart contract, return string of base uri
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
      * @dev Hook that is called before any token transfer. This includes minting
    * and burning.
    *
    * @dev Additionally to the parent smart contract, restrict this contract can not be receiver.
    */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        require(to_ != address(this), 'this contract cannot be receiver');
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    /**
      * @notice Service function to transfer mulitply nfts at once
    *
    */
    function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] memory ids_
    ) public virtual {
        for (uint256 index; index < ids_.length; index++) {
            safeTransferFrom(from_, to_, ids_[index]);
        }
    }

    /**
      * @dev  See {ERC721EnumerableUpgradeable-_grantMinterRole}.
    *
    */
    function grantMinterRole(address addr_) external virtual onlyOwner {
        super._grantMinterRole(addr_);
    }

    /**
      * @dev  See {ERC721EnumerableUpgradeable-_revokeMinterRole}.
    *
    */
    function revokeMinterRole(address addr_) external virtual onlyOwner {
        super._revokeMinterRole(addr_);
    }

}
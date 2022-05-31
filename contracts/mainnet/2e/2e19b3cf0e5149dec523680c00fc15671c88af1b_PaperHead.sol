// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

import "./AdminControl.sol";
import "./ERC721CollectionBase.sol";



contract PaperHead is ERC721CollectionBase, ERC721, AdminControl {

    constructor(address signingAddress) ERC721("PaperHead", "PaperHead") {
        _initialize(
          // Total supply
          1555,
          // Purchase price (0.01 ETH)
          10000000000000000,
          // Purchase limit (0 for no limit)
          0,
          // Transaction limit (0 for no limit)
          0,
          // Presale purchase price (0.07 ETH)
          10000000000000000,
          // Presale purchase limit (0 for no limit)
          0,
          signingAddress,
          // Use dynamic presale purchase limit
          true);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, ERC721, AdminControl) returns (bool) {
        return ERC721CollectionBase.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _prefixURI;
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override (ERC721, ERC721CollectionBase) returns (uint256) {
        return ERC721.balanceOf(owner);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256 tokenId) internal override (ERC721, ERC721CollectionBase) {
        ERC721._mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(address from, address, uint256) internal virtual override {
        _validateTokenTransferability(from);
    }
    
    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
      _updateRoyalties(recipient, bps);
    }

}
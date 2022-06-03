pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IContract.sol";

contract Clover_Seeds_NFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    
    uint256 private _cap = 111e3;

    mapping (address => bool) public minters;

    address public Clover_Seeds_Picker;

    constructor(address _Clover_Seeds_Token) ERC721("Clover SEED$ NFT", "CSNFT") {
        Clover_Seeds_Token = _Clover_Seeds_Token;
    }
    
    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    function getNFTsByOwner(address _wallet) public view returns (uint256[] memory) {
        uint256 numOfTokens = balanceOf(_wallet);
        uint256[] memory tokensId = new uint256[](numOfTokens);
        for (uint256 i; i < numOfTokens; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    function Approve(address to, uint256 tokenId) public {
        _approve(to, tokenId);
    }

    function setApprover(address _approver) public onlyOwner {
        isApprover[_approver] = true;
    }

    function safeMint(address to, uint256 tokenId) public onlyMinter {
        require(totalSupply().add(tokenId) <= _cap, "SEED NFT: All token minted...");
        _safeMint(to, tokenId);
        IContract(Clover_Seeds_Token).addAsNFTBuyer(to);
        
        require(IContract(Controller).addMintedTokenId(tokenId), "SEED NFT: Unable to call addMintedTokenId..");
        require(IContract(Clover_Seeds_Picker).randomLayer(tokenId), "SEED NFT: Unable to call randomLayer..");
        
    }

    function setClover_Seeds_Token(address SeedsToken) public onlyOwner {
        Clover_Seeds_Token = SeedsToken;
    }

    function set_cap(uint256 amount) public onlyOwner {
        _cap = amount;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    function addURI(uint256[] memory tokenId, string[] memory uri) public onlyOwner {
        require(tokenId.length == uri.length, "SEED NFT: Please enter equal tokenId & uri length..");
        
        for (uint256 i = 0; i < tokenId.length; i++) {
            _setTokenURI(tokenId[i], uri[i]);
        }
    }

    function setController(address _controller) public onlyOwner {
        Controller = _controller;
    }

    function setClover_Seeds_Picker(address _Clover_Seeds_Picker) public onlyOwner {
        Clover_Seeds_Picker = _Clover_Seeds_Picker;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ NFT: amount must be greater than 0");
        require(recipient != address(0), "SEED$ NFT: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
}
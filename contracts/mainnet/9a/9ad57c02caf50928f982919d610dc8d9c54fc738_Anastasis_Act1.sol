// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC721.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";

contract Anastasis_Act1 is ERC721, AdminControl {
    
    address payable  private _royalties_recipient;
    uint256 private _royaltyAmount; //in % 
    uint256 _urisNumber;
    string _uri;

    
    constructor () ERC721("f-1 Anastasis - Act1", "f-1 AA1") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint( 
        address to
    ) external adminRequired{
        require(!_exists(1), "Only 1 token can be created with this contract");
        _mint(to, 1);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function setURI(
        uint256 urisNumber,
        string calldata updatedURI
    ) external adminRequired{
        _urisNumber = urisNumber;
        _uri = updatedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 uri = (block.number/2400) % _urisNumber;
        return string(abi.encodePacked(_uri, Strings.toString(uri), ".json"));
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}
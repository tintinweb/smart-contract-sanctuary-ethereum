// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.15;

import "./ERC721.sol";
import "./Strings.sol";
import "./IEIP2981.sol";

contract Freize is ERC721 {
    using Strings for uint256;
    uint256 _maxSupply = 1;
    uint256 _supply;
    uint256 _royaltyAmount;
    address _royalties_recipient;
    string _uri = "https://arweave.net/VpL2yCH7IoVWMIMzo_3-9QfDLBqHtbTuYgm2iOV-67c";
    mapping(address => bool) public _isAdmin;
    constructor () ERC721("Freize", "v") {
        _royalties_recipient = 0xc13B9a35c33E6a13DC43dDe0e248B94e21938E18;
        _royaltyAmount = 10;
        _supply = 1;
        _isAdmin[msg.sender] = true;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
        ERC721.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint(
        address account
    ) external {
        require(_isAdmin[msg.sender], "Only Admins can mint");
        require(_supply <= _maxSupply);
        _safeMint(account ,1);
        _supply +=1;
    }

    function addAdmin(address newAdmin)external{
        require(_isAdmin[msg.sender], "Only Admins can add new ones");
        _isAdmin[newAdmin] = true;
    }

        function revokeAdmin(address admin)external{
        require(_isAdmin[msg.sender], "Only Admins can revoke other admins");
        _isAdmin[admin] = false;
    }

    function setURI(string calldata updatedURI) external {
        require(_isAdmin[msg.sender], "Only Admins can set the URI");
        _uri = updatedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId)== msg.sender, "You can only burn your own tokens");
        _burn(tokenId);
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external {
        require(_isAdmin[msg.sender], "Only Admins can set Royalties");
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external {
        require(_isAdmin[msg.sender], "Only Admins can withdraw");
        payable(recipient).transfer(address(this).balance);
    }

}
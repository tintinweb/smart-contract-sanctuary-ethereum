// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./ERC721A.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";
import "./Strings.sol";

contract Anastasis_Act2 is ERC721A, AdminControl {
    
    address payable  private _royalties_recipient;
    uint256 private _royaltyAmount; //in % 
    uint256 public _tokenId = 0;
    string public _uri;
    
    mapping(uint256 => uint256) public _tokenURIs;

    
    constructor () ERC721A("f-1 Anastasis - Act2", "f-1 AA2") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC721A.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint( 
        address to,
        uint256 quantity
    ) external adminRequired{
        for(uint256 i=0; i < quantity; i++){
            uint256 rarity = getPseudoRandomNumber(10);
            uint256 uri;
            if(rarity == 0){
                uri = getPseudoRandomNumber(3) + 1;
            }else if(rarity == 1 || rarity == 2){
                uri = getPseudoRandomNumber(4) + 4;
            }else{
                uri = getPseudoRandomNumber(7) + 8;
            }
            _tokenURIs[_tokenId] = uri;
            _tokenId += 1;
        }
        _mint(to, quantity);
    }

    function getPseudoRandomNumber(uint256 length) public view returns (uint256){    
        uint256 rnd = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId)));
        return rnd % length;
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721A.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function setURI(
        string calldata updatedURI
    ) external adminRequired{
        _uri = updatedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uri, Strings.toString(_tokenURIs[tokenId]), ".json"));
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
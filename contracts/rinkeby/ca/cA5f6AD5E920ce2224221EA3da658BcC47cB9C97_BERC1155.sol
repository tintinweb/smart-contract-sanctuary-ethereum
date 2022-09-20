// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MinterRole.sol";

contract BERC1155 is ERC1155, Ownable , MinterRole {
    using Strings for uint256;
    
    uint256 private _tokenIds = 1;

    mapping (uint256 => uint256) private tokenSupply;

    mapping (uint256 => string) private _tokenUris;

    string public name; // Contract name

    string public symbol; // Contract symbol

    struct NftCreateItem {
        address payable creator;
        uint256 quantity;
    }
    mapping(uint256 => NftCreateItem) private NftLists;
    
    constructor(string memory _name,string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    
    function addTokenUri(uint256 tokenId, string memory tokenUri) public onlyMinter {
        _tokenUris[tokenId] = tokenUri;
    }
    
     function createNFT(
        address payable _creator_address,
        uint256 _quantity,
        string memory _uri
        )
        onlyMinter
        external
    {
        addTokenUri(_tokenIds, _uri);
        _mint(msg.sender, _tokenIds, _quantity, "");

        NftLists[_tokenIds] = NftCreateItem(
            _creator_address,
            _quantity
        );

        _tokenIds += 1;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        if (bytes(_tokenUris[_id]).length > 0) {
            return _tokenUris[_id];
        }
      
        return string(super.uri(_id));
    }

   function setPermanentURI(uint256 _token_id, string memory tokenURI) public onlyMinter returns(bool){
         addTokenUri(_token_id, tokenURI); 
         return true;
    }

    function creator(uint256 _token_id) public view returns(address){
        return NftLists[_token_id].creator;
    }

    function TransferNft(
        address from,
        address to,
       uint256 _token_id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, _token_id, amount, data);
        NftLists[_token_id].quantity -= amount;
    }

    function TrustBalance(uint256 _token_id) public view returns (uint256){
         return NftLists[_token_id].quantity;
    }

    
    
}
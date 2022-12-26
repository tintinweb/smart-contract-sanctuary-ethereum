// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract IbrahimLee is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    mapping(uint256=> string) private _uris;

    constructor() ERC1155("") {}

    function setTokenUriWithID(uint256 _tokenId, string memory _uri) public onlyOwner{
        require(bytes(_uris[_tokenId]).length == 0, "Cannot set uri twice");
        _uris[_tokenId] = _uri;
    }

    function uri(uint256 _tokenId) override public view returns (string memory){
        return(_uris[_tokenId]);
    }

    function airDrop(address[] calldata _tos, uint256 _tokenId) public onlyOwner{
        for(uint256 i; i< _tos.length; i++){

            _mint(_tos[i], _tokenId,1, "" );

        }

    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
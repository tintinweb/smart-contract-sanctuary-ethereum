// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract MetaScyraX is ERC1155Supply, Ownable  {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory uri,
        string memory _symbol,
        string memory _name
    ) ERC1155(
        uri
    ) { 
        name = _name;
        symbol = _symbol;
    }

    function mint(address _to, uint _tokenId, uint _qty) external onlyOwner {
       _mint(_to, _tokenId, _qty, "");
    }

    function setUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }

    function withdraw() external onlyOwner {
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address addr, uint256 amount) private {
        (bool success, ) = addr.call{value: amount}("");
        require(success, "TRANSFER_FAIL");
    }
}
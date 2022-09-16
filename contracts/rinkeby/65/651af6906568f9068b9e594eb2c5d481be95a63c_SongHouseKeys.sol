/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
Expandable ERC1155 allows contract owner to issue new tokens, each with their own max supply, mint price, and max per Address.
function "releaseNewEdition" will create a new token based on the input params, 
while function "updateExistingEdition" can change those params including increasing max supply.
function "mint" 
*/

import "./ERC1155.sol";
import "./Strings.sol";
import "./Shareholders.sol";

contract SongHouseKeys is ERC1155, Shareholders {
    using Strings for uint256;
    uint256 public currentEdition;
    uint256 public totalSupply;
    string public baseURI;
    string public name;
    string public symbol;
    mapping(uint256 => uint256) public totalSupplyOfToken;
    mapping(uint256 => uint256) public maxSupplyOfToken;
    mapping(uint256 => uint256) public priceOfToken;
    mapping(uint256 => bool) public tokenExists;
    mapping(uint256 => bool) public salePaused;
    event SetBaseURI(string indexed _baseURI);

    constructor() ERC1155(baseURI) {
        baseURI = "";
        name = "Song House Access Keys";
        symbol = "SHAK";
    }

    function releaseNewEdition(uint256 _maxSupply, uint256 _price) external onlyOwner {
        currentEdition += 1;
        tokenExists[currentEdition] = true;
        maxSupplyOfToken[currentEdition] = _maxSupply;
        priceOfToken[currentEdition] = _price;
        salePaused[currentEdition] = true;
    }

    function updateExistingEdition(uint256 _edition, uint256 _maxSupply, uint256 _price) external onlyOwner {
        require(tokenExists[_edition] == true, "This token doesnt exist.");
        maxSupplyOfToken[_edition] = _maxSupply;
        priceOfToken[_edition] = _price;
    }

    function togglePause(uint256 _edition, bool _state) external onlyOwner {
        salePaused[_edition] = _state;
    }

    function mint(uint256 _edition, uint256 _quantity) external payable {
        require(salePaused[_edition] == false, "Sale is currently paused.");
        require(_quantity == 1, "You can only mint one at a time.");
        require(tokenExists[_edition] == true, "This token doesnt exist.");
        require(msg.value == priceOfToken[_edition], "Insufficient funds.");
        require(_quantity + totalSupplyOfToken[_edition] <= maxSupplyOfToken[_edition], "Not enough tokens left to mint that many.");
        _mint(msg.sender, _edition, _quantity, "");
        totalSupplyOfToken[_edition] += _quantity;
        totalSupply += _quantity;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 _tierID)
        public
        view
        override             
        returns (string memory)
    {
        
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tierID.toString(),".json"))
                : baseURI;
    }
}
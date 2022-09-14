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

contract SongHouseHooks is ERC1155, Shareholders {
    using Strings for uint256;
    uint256 public currentEdition;
    uint256 public totalSupply;
    string public baseURI;
    string public name;
    string public symbol;
    mapping(address => mapping(uint256 => uint256)) public addressMintedBalance;
    mapping(uint256 => uint256) public totalSupplyOfToken;
    mapping(uint256 => uint256) public maxSupplyOfToken;
    mapping(uint256 => uint256) public priceOfToken;
    mapping(uint256 => uint256) public maxPerAddress;
    mapping(uint256 => bool) public tokenExists;
    mapping(uint256 => bool) public salePaused;
    event SetBaseURI(string indexed _baseURI);

    constructor() ERC1155(baseURI) {
        baseURI = "";
        name = "Song House Viral Hooks";
        symbol = "SHVH";
    }

    function releaseNewEdition(uint256 _maxSupply, uint256 _price, uint256 _maxPerAddress) external onlyOwner {
        currentEdition += 1;
        tokenExists[currentEdition] = true;
        maxSupplyOfToken[currentEdition] = _maxSupply;
        priceOfToken[currentEdition] = _price;
        maxPerAddress[currentEdition] = _maxPerAddress;
        salePaused[currentEdition] = true;
    }

    function releaseMultipleNewEditions(uint256[] memory _maxSupplies, uint256[] memory _prices, uint256[] memory _maxPerAddresses) external onlyOwner {
        require(_maxSupplies.length == _prices.length && _prices.length == _maxPerAddresses.length, "Array length mismatch error.");
        for (uint i = 0; i < _maxSupplies.length; i++) {
            currentEdition += 1;
            tokenExists[currentEdition] = true;
            maxSupplyOfToken[currentEdition] = _maxSupplies[i];
            priceOfToken[currentEdition] = _prices[i];
            maxPerAddress[currentEdition] = _maxPerAddresses[i];
            salePaused[currentEdition] = true;
        }
    }

    function updateExistingEdition(uint256 _edition, uint256 _maxSupply, uint256 _price, uint256 _maxPerAddress) external onlyOwner {
        require(tokenExists[_edition] == true, "This token doesnt exist.");
        maxSupplyOfToken[_edition] = _maxSupply;
        priceOfToken[_edition] = _price;
        maxPerAddress[_edition] = _maxPerAddress;
    }

    function togglePause(uint256 _edition, bool _state) external onlyOwner {
        salePaused[_edition] = _state;
    }

    function mint(uint256[] memory _editions, uint256[] memory _quantities) external payable {
        require(_editions.length == _quantities.length, "Array length mismatch error.");
        uint txCost;
        for (uint i = 0; i < _editions.length; i++) {
            require(tokenExists[_editions[i]] == true, "This token doesnt exist.");
            require(_quantities[i] + totalSupplyOfToken[_editions[i]] <= maxSupplyOfToken[_editions[i]], "Not enough tokens left to mint that many.");
            require(addressMintedBalance[msg.sender][_editions[i]] + _quantities[i] <= maxPerAddress[_editions[i]], "Minting this many will exceed the max per wallet address");
            totalSupplyOfToken[_editions[i]] += _quantities[i];
            addressMintedBalance[msg.sender][_editions[i]] += _quantities[i];
            totalSupply += _quantities[i];
            txCost += priceOfToken[_editions[i]];
        }
        require(msg.value == txCost, "Insufficient funds.");
        _mintBatch(msg.sender, _editions, _quantities, "");
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
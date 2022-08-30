//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./SafeMath.sol";



contract WenMergeNFT is ERC721URIStorage, Ownable {
    
    using SafeMath for uint256;
    uint256 private tokenLimit = 10001;
    uint public totalTokensSold = 0;
    mapping (uint256 => bool) public tokenSold;
    uint256 purchasePrice = 50000000000000000;

    // must have the trailing slash     
    string gateway = "ipfs://QmTqroFHNaPDHYgg9Pn8XZ8fD4XDNwECKuzak7vAjdXQRJ/"; // update for mainnet image collection

    constructor() ERC721("The Leslie Collection", "LESLIE") {}

    modifier tokenAvailable(uint _tokenId) {
        require(_tokenId > 0 && _tokenId < tokenLimit, "Invalid token Id");
        require(tokenSold[_tokenId] == false, "Token already sold");
        _;
    }
    
    function mintNFT(address recipient, uint256 _tokenId)
        internal
        returns (uint256)
    {
        _mint(recipient, _tokenId);
        // tokenURI string that resolves to a JSON document containing the token metadata.
        _setTokenURI(_tokenId, generateURI(_tokenId));
        tokenSold[_tokenId] = true;
        totalTokensSold = totalTokensSold.add(1);

        return _tokenId;
    }

    function purchaseNFT(uint _tokenId) public payable tokenAvailable(_tokenId) returns(uint256)
    {
        require(msg.value == purchasePrice, "Incorrect amount sent");
        return mintNFT(msg.sender, _tokenId);
    }

    function giftNFT(address _recipient, uint _tokenId) public payable tokenAvailable(_tokenId) returns(uint256)
    {
        require(msg.value == purchasePrice, "Incorrect amount sent");
        return mintNFT(_recipient, _tokenId);
    }

    function generateURI(uint256 _tokenId) private view returns (string memory)
    {
        _tokenId = (_tokenId % 100) + 1; // remove on mainnet
        return string(abi.encodePacked(gateway,Strings.toString(_tokenId), ".json"));
    }

    function setPurchasePrice(uint256 _purchasePrice) public onlyOwner {
        purchasePrice = _purchasePrice;
    }

    function soldTokens() external view returns (uint[] memory){
        
        uint[] memory sold = new uint[](totalTokensSold);

        uint counter = 0;

        for (uint i = 1; i <= tokenLimit; i++) {
            if (tokenSold[i] == true) {
                sold[counter] = i;
                counter++;
            }
        }
        return sold;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
    
}
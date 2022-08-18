//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract WenMergeNFT is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    uint256 private tokenLimit = 10000;
    uint256 public totalTokensSold = 0;
    mapping(uint256 => bool) public tokenSold;
    uint256 public purchasePrice = 50000000000000000;

    string gateway =
        "https://gateway.pinata.cloud/ipfs/QmdEMCZfxmHtywCG7Du42m5dbNuMpJpiMmB2Qrx33CxEx5/";

    event Purchased(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("WenMerge", "RHINO") {}

    modifier tokenAvailable(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId < tokenLimit, "Invalid token Id");
        require(tokenSold[_tokenId] == false, "Token has already sold");
        _;
    }

    // tokenURI string that resolves to a JSON document containing the token metadata.
    function mintNFT(address recipient, uint256 _tokenId)
        internal
        returns (uint256)
    {
        _mint(recipient, _tokenId);
        _setTokenURI(_tokenId, getTokenURI(_tokenId));
        tokenSold[_tokenId] = true;
        totalTokensSold = totalTokensSold.add(1);

        return _tokenId;
    }

    function purchaseNFT(uint256 _tokenId)
        public
        payable
        tokenAvailable(_tokenId)
        returns (uint256)
    {
        require(msg.value == purchasePrice, "Incorrect amount sent");
        emit Purchased(msg.sender, _tokenId);
        return mintNFT(msg.sender, _tokenId);
    }

    function getPurchasePrice() public view returns (uint256) {
        return purchasePrice;
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        _tokenId = (_tokenId % 3) + 1; // remove on mainnet
        return
            string(
                abi.encodePacked(gateway, Strings.toString(_tokenId), ".json")
            );
    }

    function setTokenLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit > tokenLimit);
        tokenLimit = _newLimit;
    }

    function setPurchasePrice(uint256 _purchasePrice) public onlyOwner {
        purchasePrice = _purchasePrice;
    }

    function soldTokens() external view returns (uint256[] memory) {
        uint256[] memory sold = new uint256[](totalTokensSold);

        uint256 counter = 0;

        for (uint256 i = 1; i <= tokenLimit; i++) {
            if (tokenSold[i] == true) {
                sold[counter] = i;
                counter++;
            }
        }
        return sold;
    }
}
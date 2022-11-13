/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/*
Developed by Co-Labs Studios. www.co-labs.studio
Do not attempt to mint through contract. Token URI must be set at time of mint and can not be changed once set.
Scelte Intelligente is Italian for "Intelligent Choices."
This collection has been named as such because of it's use of Artificial Intelligence (provided through OpenAI's API) and the given ability to choose what you will record on chain forever.
You can interact with this smart contract by visiting https://si.co-labs.studio
*/
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract ScelteIntelligente is ERC721A, Ownable {
    mapping(uint256 => string) internal URIofToken;
    mapping(address => uint256) public addressMintedBalance;

    uint256 public maxPerWallet = 10;
    uint256 public maxSupply = 10000;

    constructor(
      ) ERC721A("Scelte Intelligenti", "SI")payable{}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    function mint(string memory _tokenURI) external payable{     
        require(addressMintedBalance[msg.sender] < maxPerWallet, "You can only mint 5 per wallet.");
        require(_totalMinted() < maxSupply, "Sold Out.");
        _mint(msg.sender, 1);
        URIofToken[_totalMinted()] = _tokenURI;
        addressMintedBalance[msg.sender] += 1;    
    }
//ipfs://QmNjGzTnr2vc4GxkyQ4yMbZv3BTU3pxQVCHzJurCdw9NKk
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        string memory TokenURI = URIofToken[_tokenId];
        return bytes(TokenURI).length > 0 ? string(abi.encodePacked(TokenURI)) : "";
    }

    function withdraw() public {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    

}
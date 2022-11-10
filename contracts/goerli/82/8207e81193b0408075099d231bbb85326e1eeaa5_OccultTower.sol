//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract OccultTower is ERC721A("Tower of the Occult", "Occult"), Ownable, ReentrancyGuard {

    mapping(address => uint256) public occultistCount;
    uint256 public Occultists = 7777;
    string public occultURI = "ipfs://QmZxdRjNXwCdpMBzSHVTFownBREGxcFnhmw6D7FHomGYCF/";
    bool public isPaused;

    constructor(){
        isPaused = false;
    }

    function summon() external nonReentrant {
        uint256 _occultists = totalSupply();
        require(!isPaused, 'sale paused');
        require(_occultists + 1 <= Occultists, "sold out");
        require(occultistCount[msg.sender] < 1 ,"no more for you");
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, 1);
        occultistCount[msg.sender] += 1;
    }

    function occultistCouncil() external onlyOwner {
        uint256 _occultists = totalSupply();
        require(_occultists + 111 <= Occultists);
        require(occultistCount[msg.sender] <= 667 );

        _safeMint(msg.sender, 111);
        occultistCount[msg.sender] += 111;
    }
    
    function withdraw() public onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    function changePause() external onlyOwner {
        isPaused = !isPaused;
    }
    function _baseURI() internal virtual override view returns (string memory) {
        return occultURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1), ".json")) : '';
    }
    
    function updateURI(string memory newOccultURI) external onlyOwner {
        occultURI = newOccultURI;
    }
}
// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./Address.sol";
import "./String.sol";
import "./ERC721.sol";
import "./Counter.sol";


// File: contracts/Partisan.sol


pragma solidity ^0.8.4;

interface IWhitelist {
    function getWhitelist(address owner) external view returns(uint256, uint256);

    function whitelistMintNumberIncrement(address owner) external;
}


contract Paragon is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct watchDetail {
        uint256 strap;
        uint256 caseWatch;
        uint256 crown;
        uint256 dial;
    }

    string baseUri = "";
    address private whitelistAddress;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply;
    uint256 public maxMintPerWallet = 3;
    uint256 nonce = 0;

    mapping(uint256 => watchDetail) watches;
    mapping(address => uint256[]) watchOwners;

    event itemGenerated(uint256 indexed _id, address owner, uint256 strap, uint256 caseWatch, uint256 crown, uint256 dial);

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _maxSupply, address _whitelistAddress) ERC721(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        whitelistAddress = _whitelistAddress;
    }

    receive() external payable{}

    fallback() external payable {}

    function withdrawBalance() external onlyOwner  {
         uint256 balance = address(this).balance;
         payable(_msgSender()).transfer(balance);
     }

   function getBalance() external view returns(uint){
         uint256 balance = address(this).balance;
         return balance;
    }

    function _burn(uint256 tokenId) internal override (ERC721) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function random() internal returns (uint256) {
        uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        nonce++;
        if (randomnumber < uint(8)) {
            return 0;
        } else if (uint256(8) <= randomnumber && randomnumber <= uint256(15)) {
            return 1;
        } else if (uint256(15) < randomnumber && randomnumber <= uint256(35)) {
            return 2;
        } else if (uint256(35) < randomnumber && randomnumber <= uint256(50)) {
            return 3;
        } else if (uint256(50) < randomnumber && randomnumber <= uint256(65)) {
            return 4;
        } else if (uint256(65) < randomnumber && randomnumber <= uint256(77)) {
            return 5;
        } else if (uint256(77) < randomnumber && randomnumber <= uint256(97)) {
            return 6;
        } else if (uint256(97) < randomnumber && randomnumber <= uint256(100)) {
            return 7;
        }
        return type(uint).max;
    }

    function mintToken()
        public
    {
        require (totalSupply() < maxSupply);
        uint256 _allowed;
        uint256 _mintNumber;
        (_allowed, _mintNumber) = IWhitelist(whitelistAddress).getWhitelist(msg.sender);
        require (_allowed >= 1, "NOT_IN_WHITELIST");
        require (_mintNumber < maxMintPerWallet, "REACH_MAX_MINT");

        uint256 strap = random();
        uint256 caseWatch = random();
        uint256 crown = random();
        uint256 dial = random();
        uint256 tokenId = _tokenIdCounter.current();

        watches[tokenId] = watchDetail(strap, caseWatch, crown, dial);
        watchOwners[msg.sender].push(tokenId);
        IWhitelist(whitelistAddress).whitelistMintNumberIncrement(msg.sender);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        emit itemGenerated(tokenId, _msgSender(),strap, caseWatch, crown, dial);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setBaseURI(string calldata _baseUri) external onlyOwner() {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function getWatchDetail(uint256 _tokenId) public view returns(watchDetail memory) {
        return watches[_tokenId];
    }

    function getWatchOwner (address _owner) public view returns(uint256[] memory) {
        return watchOwners[_owner];
    }
}
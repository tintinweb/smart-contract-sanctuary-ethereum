// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./Address.sol";
import "./String.sol";
import "./ERC721.sol";
import "./Counter.sol";


// File: contracts/Valiant.sol
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

struct watchDetail {
    uint256 strap;
    uint256 caseWatch;
    uint256 crown;
    uint256 dial;
}

pragma solidity ^0.8.4;

interface IWhitelist {
    function publicCollection(uint256 _collection) external view returns(bool);

    function whitelist(address _address) external view returns(uint256);

    function getFounderAddress() external view returns(address);
}


contract Valiant is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;

    string baseUri = "";
    IWhitelist whitelist;

    uint256 private _tokenIdCounter;
    uint256 public maxSupply;
    uint256 immutable maxMintPerWallet = 2;
    uint256 immutable maxMintFounderWallet = 200;
    uint256 immutable maxMintPurchase = 20;
    uint256 nonce = 0;

    mapping(uint256 => watchDetail) public watches;
    mapping(address => uint256) public addressToMintNumber;

    event itemGenerated(uint256 indexed _id, address owner, uint256 strap, uint256 caseWatch, uint256 crown, uint256 dial);

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _maxSupply, address _whitelistAddress) ERC721(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        whitelist = IWhitelist(_whitelistAddress);
    }

    receive() external payable{}

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
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        nonce++;
        uint8[17] memory bounds = [8, 14, 19, 24, 30, 36, 40, 44, 48, 54, 60, 66, 72, 74, 81, 91, 100];
        for (uint i = 0; i < bounds.length; i++) {
            if (randomnumber <= bounds[i]) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function mintToken() external
    {
        require (_tokenIdCounter < maxSupply, "REACH_MAX_SUPPLY");

        if (whitelist.publicCollection(1)) {
            if (msg.sender == whitelist.getFounderAddress()) {
                require (addressToMintNumber[msg.sender] < maxMintFounderWallet, "REACH_MAX_MINT");
            } else {
                require (addressToMintNumber[msg.sender] < maxMintPerWallet, "REACH_MAX_MINT");
            }
        } else {
            if (msg.sender == whitelist.getFounderAddress()) {
                require (whitelist.whitelist(msg.sender) >= 1, "NOT_IN_WHITELIST");
                require (addressToMintNumber[msg.sender] < maxMintFounderWallet, "REACH_MAX_MINT");
            } else {
                require (whitelist.whitelist(msg.sender) >= 1, "NOT_IN_WHITELIST");
                require (addressToMintNumber[msg.sender] < maxMintPerWallet, "REACH_MAX_MINT");
            }
        }
        
        uint256 tokenId = _tokenIdCounter;

        watches[tokenId] = watchDetail(random(), random(), random(), random());
        addressToMintNumber[msg.sender] += 1;
        _tokenIdCounter = _tokenIdCounter.add(1);
        _safeMint(msg.sender, tokenId);
        emit itemGenerated(tokenId, _msgSender(),watches[tokenId].strap, watches[tokenId].caseWatch, watches[tokenId].crown, watches[tokenId].dial);
    }

    function OwnerMintToken(uint numberOfTokes) external {
        require (msg.sender == whitelist.getFounderAddress());
        require (_tokenIdCounter.add(numberOfTokes) <= maxSupply);
        require (numberOfTokes <= maxMintPurchase);
        require (addressToMintNumber[msg.sender].add(numberOfTokes) <= maxMintFounderWallet, "REACH_MAX_MINT");

        for (uint i = 0; i < numberOfTokes; i++) {
            uint256 tokenId = _tokenIdCounter;

            watches[tokenId] = watchDetail(random(), random(), random(), random());
            addressToMintNumber[msg.sender] += 1;
            _tokenIdCounter = _tokenIdCounter.add(1);
            _safeMint(msg.sender, tokenId);
            emit itemGenerated(tokenId, _msgSender(),watches[tokenId].strap, watches[tokenId].caseWatch, watches[tokenId].crown, watches[tokenId].dial);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId, ".json")) : "";
    }

    function setBaseURI(string calldata _baseUri) external onlyOwner() {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}
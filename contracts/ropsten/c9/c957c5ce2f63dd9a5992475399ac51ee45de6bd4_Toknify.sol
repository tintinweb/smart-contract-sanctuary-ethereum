// SPDX-License-Identifier: Toknify.com

pragma solidity ^0.8.0;

import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Toknify.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract Toknify is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Toknify, ERC721Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string calldata newBaseTokenURI) public {
        _baseTokenURI = newBaseTokenURI;
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Toknify: must have ADMIN ROLE");
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }



    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Toknify: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Toknify: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    string public constant TOKNIFY_PROVENANCE = "toknify";

    uint256 public constant SALE_START_TIMESTAMP = 1615474800;

    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (60*60*24*10000);

    uint256 public constant MAX_NFT_SUPPLY = 1000000000000;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    mapping (uint256 => bool) private _mintedBeforeReveal;
    
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }
    
    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        uint256 currentSupply = totalSupply();

        if (currentSupply >= 999999999999) {
            return 20000000000000000; // 0.02 ETH
        } else {
            return 20000000000000000; // 0.02 ETH
        }
    }
    
    function mintNFT(uint256 numberOfNfts, string memory tokenURI_) public payable nonReentrant {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 1, "Creator may create 1 NFT at once");
        require((totalSupply() + numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require((getNFTPrice() * numberOfNfts) == msg.value, "Ether value sent is not correct");
        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
                    _setTokenURI(_tokenIdTracker.current(), tokenURI_);
                    _tokenIdTracker.increment();
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }
    
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        

        uint256 _start = uint256(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        if ((block.number - _start) > 255) {
            _start = uint256(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        if (_start == 0) {
            _start = _start + 1;
        }
        
        startingIndex = _start;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    mapping (uint256 => string) private _tokenURIs;

    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    //     string memory _tokenURI = _tokenURIs[tokenId];
    //     string memory base = _baseURI();

    //     if (bytes(base).length == 0) {
    //         return _tokenURI;
    //     }

    //     if (bytes(_tokenURI).length > 0) {
    //         return string(abi.encodePacked(base, _tokenURI));
    //     }

    //     return super.tokenURI(tokenId);
    // }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        _setTokenURI(tokenId, _tokenURI);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId));
    }
    
    function mint(address _to, string memory tokenURI_) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Toknify: must have minter role to mint");
        _mint(_to, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), tokenURI_);
        _tokenIdTracker.increment();
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
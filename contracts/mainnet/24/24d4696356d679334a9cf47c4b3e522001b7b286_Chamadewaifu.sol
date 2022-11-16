// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";


contract Chamadewaifu is ERC721, ERC721Burnable, Pausable, Ownable, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;

    string public baseURI;
    uint256 public maxSupply;
    uint256 public publicMint;
    bool public publicMintEnabled;
    mapping (address => bool) private minters;
    uint256 public cost = 0.003 ether;

    Counters.Counter private tokenIdCounter;

    constructor() payable
        ERC721("Chamadewaifu", "CHAMADEWAIFU")
    {
        baseURI = "https://ipfs.io/ipfs/QmfRdKJGzNCgZaJDGCzUxBUK9xkPDVqRn4ZNkmjbZYpzG5/";
        maxSupply = 1600;
        publicMint = 1600;
        publicMintEnabled = false;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }


    // F2O
    function mint(uint256 amount)
        external payable
    {
        require(tokenIdCounter.current() < maxSupply, "Chamadewaifu: exceeds max supply");
        require(balanceOf(_msgSender()) == 0, "Chamadewaifu: exceeds mint limit");
        require(minters[_msgSender()] == false, "Chamadewaifu: exceeds mint limit");
        require(publicMintEnabled == true, "Chamadewaifu: public mint not enabled");
        require(publicMint > 0, "Chamadewaifu: no public mint allocation");
        require(tx.origin == _msgSender(), "Chamadewaifu: invalid eoa");
        require(amount <= 10, "Chamadewaifu: exceeds mint limit");
        require(amount > 0, "Chamadewaifu: invalid eoa");
        require((publicMint - amount) > 0, "Chamadewaifu: exceeds mint limit");
        require(msg.value == (amount * cost), "Chamadewaifu: invalid price");
        minters[_msgSender()] = true;
        
        
        publicMint -= amount;
        
        for(uint i = 0; i < amount; i++) {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function pause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _unpause();
    }

    function setPublicMintEnabled(bool enabled)
        public
        onlyRole (MANAGER_ROLE)
    {
        publicMintEnabled = enabled;
    }

    function setBaseURI(string calldata baseURI_)
        public
        onlyRole (MANAGER_ROLE)
    {
        baseURI = baseURI_;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenIdCounter.current();
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawETH() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

}
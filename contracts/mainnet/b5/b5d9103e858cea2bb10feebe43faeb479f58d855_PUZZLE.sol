// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';

/**********************************************
Design is hack.

Invisibility is a superpower.

Stepping into the new order.

In line, we wait.

A fountain of value.

Welcome back, goodbye.
**********************************************/

contract PUZZLE is ERC721A, Ownable, ReentrancyGuard {
    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.0 ether;
    uint256 public collectionSize = 1000;
    uint256 public maxPublicMint = 1;
    uint256 public reserveSize;

    bool public publicSale;
    bool public void;

    address[] public reserveAddresses;

    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public totalReservedMints;
    mapping(address => bool) userAddr;

    constructor() ERC721A("PUZZLE", "PUZ") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(publicSale, "Public Minting is on Pause");
        require(_mintAmount > 0, "Cant mint 0");
        require(s + _mintAmount <= collectionSize, "Minting supply exceeded");
        require((walletMints[msg.sender] + _mintAmount)  <= maxPublicMint, "Cannot mint beyond max mint!");

        _safeMint(msg.sender, _mintAmount);
        walletMints[msg.sender] += _mintAmount;
    }

    /**
    The valuable one is almost never the one that grabs your attention.

    It is the one that is silent and invisible.

    Once you try to lift it, you can't.

    It's much heavier than you think.
    */

    function puzzle() external nonReentrant {
        require(totalReservedMints[msg.sender] + reserveSize <= reserveSize, "Already minted!");
        require(allowedToMint(msg.sender), "You can't mint!");
        _safeMint(msg.sender, reserveSize);
        totalReservedMints[msg.sender] += reserveSize;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
        maxPublicMint = _maxPublicMint;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setReservelist(address[] calldata _addressArray) public onlyOwner {
        delete reserveAddresses;
        reserveAddresses = _addressArray;
    }

    function setReserveSize(uint256 _reserveSize) public onlyOwner {
      reserveSize = _reserveSize;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function allowedToMint(address _user) private view returns (bool) {
        uint i = 0;
        while (i < reserveAddresses.length) {
            if(reserveAddresses[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }
    /**
    Like every new thing, cryptoart is reaching a plateau.

    A broader audience, but it's not as innovative as it once was.

    Don't worry, the depth increases.

    The giant is ready for an awakening.

    Like everything in the universe, moving in waves is significant and realistic.    
    */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId),  ".json"));
    }

}
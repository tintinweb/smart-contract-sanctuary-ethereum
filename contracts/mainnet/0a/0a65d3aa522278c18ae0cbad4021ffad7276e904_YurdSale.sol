/// SPDX-License-Identifier: MIT

/*

██╗   ██╗██╗   ██╗██████╗ ██████╗     ███████╗ █████╗ ██╗     ███████╗
╚██╗ ██╔╝██║   ██║██╔══██╗██╔══██╗    ██╔════╝██╔══██╗██║     ██╔════╝
 ╚████╔╝ ██║   ██║██████╔╝██║  ██║    ███████╗███████║██║     █████╗  
  ╚██╔╝  ██║   ██║██╔══██╗██║  ██║    ╚════██║██╔══██║██║     ██╔══╝  
   ██║   ╚██████╔╝██║  ██║██████╔╝    ███████║██║  ██║███████╗███████╗
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝

hobotownyurdsale.wtf                                                                   
*/
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";



contract YurdSale is ERC721A, Shareholders {
    using Strings for uint;
    IERC721A public hoboTown = ERC721A(0x6e0418050387C6C3d4Cd206d8b89788BBd432525);
    string public _baseTokenURI ="ipfs://QmRA34RsEpsi2XPjJERq4MXmSQ7dnjAA3ZXfkmdhd59SSj/";
    uint public maxPerMint = 5;
    uint public maxPerWallet = 25;
    uint public cost = .015 ether;
    uint public maxSupply = 3000;
    uint public freeForHobos = 450;
    bool public paused = true;
    bool public revealed = false;
    bool public freeClaimPeriod = true;


    mapping(address => uint) public addressMintedBalance;
    mapping(address => bool) public freeMintClaimed;

  constructor( 
      address payable[] memory newShareholders,
      uint256[] memory newShares
    ) ERC721A("Yurd Sale", "YS")payable{
        _mint(msg.sender, 50);
        changeShareholders(newShareholders, newShares);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    
    modifier mintCompliance(uint256 quantity) {
        uint howManyHobos = hoboTown.balanceOf(msg.sender);
        require(paused == false, "Contract is paused");
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 3,000");
        require(tx.origin == msg.sender, "No contracts!");
        require(quantity <= maxPerMint, "You can't mint this many at once.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        if (howManyHobos < 1) {
            require(msg.value == cost * quantity, "Insufficient Funds.");
        } else {
            require(freeMintClaimed[msg.sender] == false, "You already claimed your free mint.");
            require(freeClaimPeriod == true, "Free claim period is over.");
            require(freeForHobos > 0, "No more free claims left.");
            require(msg.value == (cost * (quantity - 1)), "Insufficient Funds.");
            freeMintClaimed[msg.sender] = true;
            freeForHobos -=1;
        }
        _;
    }



  function mint(uint256 quantity) mintCompliance(quantity) external payable
    {
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function ownerMint(uint256 quantity) external onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 3,000");
        _mint(msg.sender, quantity);
    }


    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        if(revealed == true) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
        } else {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI))
            : "";
        } 
    }

    
    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }


    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

    function setFreeClaimPeriod(bool _state) external onlyOwner {
        freeClaimPeriod = _state;
    }

}
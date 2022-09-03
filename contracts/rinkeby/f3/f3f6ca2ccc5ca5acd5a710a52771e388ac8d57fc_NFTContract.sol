/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* 
   ___           ___       __  ___  ___  ___  ___ 
  / _ \___ _  __/ _ )___  / /_/ _ \/ _ \/ _ \/ _ \
 / // / -_) |/ / _  / _ \/ __/\_, / // / // / // /
/____/\__/|___/____/\___/\__//___/\___/\___/\___/
                                                           
                          \~~~~//
                          /[-])//  ___
                     __ --\ `_/~--|  / \
                   /_-/~~--~~ /~~~\\_\ /\
                   |  |___|===|_-- | \ \ \
 _/~~~~~~~~|~~\,   ---|---\___/----|  \/\-\
 ~\________|__/   / // \__ |  ||  / | |   | |
          ,~-|~~~~~\--, | \|--|/~|||  |   | |
          [3-|____---~~ _--'==;/ _,   |   |_|
                      /   /\__|_/  \  \__/--/
                     /---/_\  -___/ |  /,--|
                     /  /\/~--|   | |  \///
                    /  / |-__ \    |/
                   |--/ /      |-- | \
                  \^~~\\/\      \   \/- _
                   \    |  \     |~~\~~| \
                    \    \  \     \   \  | \
                      \    \ |     \   \    \
                       |~~|\/\|     \   \   |
                      |   |/         \_--_- |\
                      |  /            /   |/\/
                       ~~             /  /
                                     |__/

Developed by Co-Labs. Hire us www.co-labs.studio
*/

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./accessPassInterface.sol";


contract NFTContract is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerWallet;
    uint public maxPerWalletPresale;
    uint public cost;
    uint public presaleCost;
    uint public maxSupply;
    bool public revealed;
    bool public presaleOnly;
    bool public paused = true;
    bytes32 public merkleRoot;
    mapping(address => uint) public addressMintedBalance;
  constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint maxPerWallet_,
        uint maxPerWalletPresale_,
        uint maxSupply_,
        uint presaleCost_,
        uint cost_,
        address newOwner_,
        bool presaleOnly_,
        bytes32 merkleRoot_
    ) ERC721A(name_, symbol_)payable{
        maxPerWallet = maxPerWallet_;
        maxPerWalletPresale = maxPerWalletPresale_;
        maxSupply = maxSupply_;
        cost = cost_;
        presaleCost = presaleCost_;
        presaleOnly = presaleOnly_;
        merkleRoot = merkleRoot_;
        _baseTokenURI = baseUri_;
        transferOwnership(newOwner_);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(tx.origin == msg.sender, "No contracts!");
        _;
    }

    function publicMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(presaleOnly == false, "Presale Only");
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        require(presaleOnly == true, "Presale has ended.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWalletPresale, "You can't mint this many during presale.");
        require(msg.value >= presaleCost * quantity, "Amount of Ether sent too small");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function ownerMint(uint256 quantity) external payable onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) 
    {
        return _exists(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) 
    {
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

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
    merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;//set to false for main mint
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner 
    {
    revealed = _state;
    _baseTokenURI = baseURI;
    }

    function pause(bool _state) external onlyOwner 
    {
    paused = _state;
    }

    function changeSaleDetails(uint _cost, uint _presaleCost, uint _maxPerWallet, uint _maxPerWalletPresale) external onlyOwner {
        cost = _cost;
        presaleCost = _presaleCost;
        maxPerWallet = _maxPerWallet;
        maxPerWalletPresale = _maxPerWalletPresale;
    }

    

}
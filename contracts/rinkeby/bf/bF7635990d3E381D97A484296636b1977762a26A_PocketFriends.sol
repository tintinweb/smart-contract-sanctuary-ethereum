// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
contract PocketFriends is ERC721A, Ownable, ReentrancyGuard {
    // Max supply 
    uint256 public maxSupply = 10000;

    // Merkle Root
    bytes32 public merkleRoot = 0x04d55cbc3384d564e5acfe19c5dad7a9b0ef909b719f6bc6aaf03e6203421964;


    // Price Per Pocket Friend
    uint256 public price = 150000000000000000;
    uint256 public whitelistPrice = 120000000000000000;
    
    // The address to receive payment from sales
    address payable payee;

    // Boolean value, if true only whitelist can buy, if false public can buy
    bool public whitelistOnly = true;
    bool public saleOpen;
    
    // whitelist mapping
    mapping(address => bool) public hasMinted;

    constructor(
        string memory name,     // Pocket Friends
        string memory symbol,   // POCKET
        address payable _payee             // Who gets payout?
    ) 
    ERC721A(name, symbol, 50, maxSupply) 
    {
        payee = _payee;
        URI = "https://us-central1-pocket-friends-337414.cloudfunctions.net/get-metadata?tokenid=";
    }

    function isWhitelisted(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool iswl = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return iswl;
    }
    
    function mint(uint256 amount, address _recipient, bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(saleOpen, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "Not enough left");
        require(amount <= 5, "Maximum 5 per purchase");
        
        // Check if whitelisted
        bool iswl = isWhitelisted(_recipient, _merkleProof);
        if(iswl && hasMinted[_recipient] == false) {
            // Restrict to one transaction per whitelisted account
            require(msg.value == whitelistPrice * amount, "Incorrect amount of ETH sent");
            
            hasMinted[_recipient] = true;
        } else {
            require(!whitelistOnly, "Purchasing only available for whitelisted addresses");
            require(msg.value == price * amount, "Incorrect amount of ETH sent");
        }

        // Pay payee
        (bool success,) = payee.call{value: msg.value}("");
        require(success, "Transfer fail");
        
        // Mint NFT to user wallet
        _safeMint(_recipient, amount);
    }

    function mintTo(uint amount, address _recipient) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Not enough left to mint");
        _safeMint(_recipient, amount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) public onlyOwner {
        URI = _uri;
    }

    function resetWhitelists(address[] memory whitelistedAddress) public onlyOwner {
        for(uint256 i = 0; i < whitelistedAddress.length; i++){
            hasMinted[whitelistedAddress[i]] = false;
        }
    }

    function setWhitelistState(bool state) public onlyOwner {
        whitelistOnly = state;
    }

    function setSaleState(bool state) public onlyOwner {
        saleOpen = state;
    }

    function setRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

}
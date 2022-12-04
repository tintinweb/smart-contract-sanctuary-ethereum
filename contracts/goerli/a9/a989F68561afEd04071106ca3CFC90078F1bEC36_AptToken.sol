pragma solidity ^0.7.0;

contract AptToken {
    // Maps the token ID to the owner address
    mapping (uint256 => address) public tokenOwner;
    mapping (address => bool) public owners;

    // Stores the total supply of minted NFTs
    uint256 public totalSupply;

    // The URL of the NFT's artwork
    string public artURL = "https://gateway.pinata.cloud/ipfs/QmUSJoLaLTDFHcdGtnfd92qEMQnn2Kv4Smz2Rj13bdVwrw";

    // The name of the NFT
    string public name = "apt";

    // The symbol of the NFT
    string public symbol = "APT";

    // Emits an event when a new NFT is minted
    event Mint(address recipient, uint256 tokenId);

    // Constructor sets the initial supply to zero
    constructor(){
        totalSupply = 0;
        owners[msg.sender] = true;
    }
    

    // Function to mint a new NFT and assign it to msg.sender
    function mint() public {
        require(owners[msg.sender],"not an owner kiddo");
        // Increment the total supply
        totalSupply++;
        // Set the token ID to the current total supply
        uint256 tokenId = totalSupply;
        // Set the owner of the token to msg.sender
        tokenOwner[tokenId] = msg.sender;
        // Emit the Mint event
        emit Mint(msg.sender, tokenId);
    }
}
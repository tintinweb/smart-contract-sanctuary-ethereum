//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "Strings.sol";

/*
ElfsVsGoblins.sol

Contract by @NftDoyler
*/

contract PigEight is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 999;
    uint256 public MAX_FREE_SUPPLY = 999;
    uint256 public FREE_MINT_MAX = 999;
    uint256 public publicPrice = 0 ether;
    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 999;
    uint256 constant public PUBLIC_MINT_LIMIT_WALLET = 999;


    

    string public revealedURI = "ipfs://QmfHrwJMp5gg3h18Hsa6676rywSjm7EwagaX9rQpSVSnYG/";
    
    string public hiddenURI = "";

    bool public paused = false;
    bool public revealed = true;

    bool public freeSale = true;
    bool public publicSale = true;


    address public teamWallet = 0x336D802064e4d435F5F43D603ac0C080E002C183;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("PigEight", "PigEight") { }

    /*
     *

    $$$$$$$\            $$\                      $$\                     $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           \__|                     $$ |                    $$  _____|                             $$ |    \__|                              
    $$ |  $$ | $$$$$$\  $$\ $$\    $$\ $$$$$$\ $$$$$$\    $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$  __$$\ $$ |\$$\  $$  |\____$$\\_$$  _|  $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  \__|$$ | \$$\$$  / $$$$$$$ | $$ |    $$$$$$$$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |      $$ |  \$$$  / $$  __$$ | $$ |$$\ $$   ____|      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      $$ |      $$ |   \$  /  \$$$$$$$ | \$$$$  |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|      \__|      \__|    \_/    \_______|  \____/  \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 
                                                                                                                                                      
    *
    */

    // This function is if you want to override the first Token ID# for ERC721A
    // Note: Fun fact - by overloading this method you save a small amount of gas for minting (technically just the first mint)
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    /*
     *

    $$$$$$$\            $$\       $$\ $$\                 $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           $$ |      $$ |\__|                $$  _____|                             $$ |    \__|                              
    $$ |  $$ |$$\   $$\ $$$$$$$\  $$ |$$\  $$$$$$$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$ |  $$ |$$  __$$\ $$ |$$ |$$  _____|      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  $$ |$$ |  $$ |$$ |$$ |$$ /            $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |  $$ |$$ |  $$ |$$ |$$ |$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      \$$$$$$  |$$$$$$$  |$$ |$$ |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|       \______/ \_______/ \__|\__| \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 998, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;

        if(newSupply == 999) {
            freeSale = false;
        }

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT_WALLET, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    /*
     *

    $$\    $$\ $$\                               $$$$$$$$\                              $$\     $$\                               
    $$ |   $$ |\__|                              $$  _____|                             $$ |    \__|                              
    $$ |   $$ |$$\  $$$$$$\  $$\  $$\  $$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    \$$\  $$  |$$ |$$  __$$\ $$ | $$ | $$ |      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
     \$$\$$  / $$ |$$$$$$$$ |$$ | $$ | $$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
      \$$$  /  $$ |$$   ____|$$ | $$ | $$ |      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
       \$  /   $$ |\$$$$$$$\ \$$$$$\$$$$  |      $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
        \_/    \__| \_______| \_____\____/       \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    // Note: walletOfOwner is only really necessary for enumerability when staking/using on websites etc.
        // That said, it's a public view so we can keep it in.
        // This could also be optimized if someone REALLY wanted, but it's just a public view.
        // Check the pinned tweets of 0xInuarashi for more ideas on this method!
        // For now, this is just the version that existed in v1.
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    /*
     *

     $$$$$$\                                                    $$$$$$$$\                              $$\     $$\                               
    $$  __$$\                                                   $$  _____|                             $$ |    \__|                              
    $$ /  $$ |$$\  $$\  $$\ $$$$$$$\   $$$$$$\   $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$ |  $$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\ $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$$$$$$$ |$$ |  \__|      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$   ____|$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
     $$$$$$  |\$$$$$\$$$$  |$$ |  $$ |\$$$$$$$\ $$ |            $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
     \______/  \_____\____/ \__|  \__| \_______|\__|            \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

     *
     */



    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages

        // Withdraw the ENTIRE remaining balance to the team wallet
        (bool succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
        // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    /*
     *

    $$\      $$\                 $$\ $$\  $$$$$$\  $$\                               
    $$$\    $$$ |                $$ |\__|$$  __$$\ \__|                              
    $$$$\  $$$$ | $$$$$$\   $$$$$$$ |$$\ $$ /  \__|$$\  $$$$$$\   $$$$$$\   $$$$$$$\ 
    $$\$$\$$ $$ |$$  __$$\ $$  __$$ |$$ |$$$$\     $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ \$$$  $$ |$$ /  $$ |$$ /  $$ |$$ |$$  _|    $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\  
    $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |      $$ |$$   ____|$$ |       \____$$\ 
    $$ | \_/ $$ |\$$$$$$  |\$$$$$$$ |$$ |$$ |      $$ |\$$$$$$$\ $$ |      $$$$$$$  |
    \__|     \__| \______/  \_______|\__|\__|      \__| \_______|\__|      \_______/ 

    *
    */

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}
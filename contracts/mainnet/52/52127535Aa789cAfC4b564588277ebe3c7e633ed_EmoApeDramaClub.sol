// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";
import "./ILB.sol";
import "./IL.sol";

contract EmoApeDramaClub is ERC721, Ownable, IMintedBeforeReveal {

    // This is the provenance record of all Emo Apes  in existence. The provenance will be updated once metadata is live at launch.
    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1626026340;

    // Time after which the Emo Apes  are randomized and revealed 7 days from instantly after initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP;

    // Maximum amount of Emo Apes   in existance.
    uint256 public constant MAX_SUPPLY = 8888;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    uint256 public _price = 0.03 ether;

    //Partner addresses
    address PARTNER_NFT_ADDRESS;

     //Main addresses
    address THIS_NFT_ADDRESS;

    mapping (uint256 => bool) private _mintedBeforeReveal;
    
    bool public presaleActive = false;
    bool public saleActive = false;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

        function getFreeMintMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");

        uint currentSupply = totalSupply();

            return 1; // 1 max per transaction
 
    }
 
    function getMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended and all sold out, no more left to sell.");

        uint currentSupply = totalSupply();

            return 10; // 10 max per transaction
 
    }

    function getFreeMintPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");

        uint currentSupply = totalSupply();
  
            return 0;  //   0.00 ETH
 
    }

    function getPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended, no more items left to sell.");

        uint currentSupply = totalSupply();
  
            return _price; //   pirice ETH
 
    }



    function FreeMint(uint256 numberOfTokens) public {
        // Exceptions that need to be handled + launch switch mechanic
        require(presaleActive == true, "Free Mint has not started yet");
        require(saleActive == false, "Free Mint has not started yet");
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
        require(numberOfTokens > 0, "You cannot mint 0 items, please increase to more than 1");
        require(numberOfTokens <= getFreeMintMaxAmount(), "You are not allowed to buy this many items at once.");
        require(IERC721(PARTNER_NFT_ADDRESS).balanceOf(msg.sender) > 0, "Must own at least one of this Nft"
        );
        require(IERC721(PARTNER_NFT_ADDRESS).balanceOf(msg.sender) >= 1, "Must own at least one of the Partner's Nft"
        );
        require(IERC721(THIS_NFT_ADDRESS).balanceOf(msg.sender) <= 0, "Can FreeMint only 1 time"
        );
        require(SafeMath.add(totalSupply(), numberOfTokens) <= MAX_SUPPLY, "Exceeds maximum supply. Please try to mint less.");

       //FreeMint
       

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _mint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        // Exceptions that need to be handled + launch switch mechanic
        require(presaleActive == false, "Sale has not started yet");
        require(saleActive == true, "Sale has not started yet");
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
        require(numberOfTokens > 0, "You cannot mint 0 items, please increase to more than 1");
        require(numberOfTokens <= getMaxAmount(), "You are not allowed to buy this many items at once.");
        require(SafeMath.add(totalSupply(), numberOfTokens) <= MAX_SUPPLY, "Exceeds maximum supply. Please try to mint less.");
        require(SafeMath.mul(getPrice(), numberOfTokens) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

     /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;

        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_SUPPLY;
        }

        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
     function LaunchPreSale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function LaunchSale() public onlyOwner {
        saleActive = !saleActive;
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */

     function setPartnerAddresses(
        address _PartnerNftAddress
    ) public onlyOwner {
        PARTNER_NFT_ADDRESS = _PartnerNftAddress;
    }

     function setThisNftAddresses(
        address _ThisNftAddresses
    ) public onlyOwner {
        THIS_NFT_ADDRESS = _ThisNftAddresses;
    }

    

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }
       /**
    * @dev Reserved for giveaways. 
    */
      function reserveGiveaway(uint256 numTokens) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numTokens <= 10, "10 mints for sale giveaways");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numTokens; index++) {
            _safeMint(owner(), currentSupply + index);
        }
      }

       function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }



}
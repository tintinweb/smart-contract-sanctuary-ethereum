/*
SPDX-License-Identifier: GPL-3.0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&     &&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&  &&  &&&  &&&&   &&&&       &&  &&&&  &&  &&&   &&  &&&&&@@@@@@@@
@@@@@@@@@&&&&&&&    &&&&&    &&&&&      &&&      &&&    &&&&&    &&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&____&&&&&____&&&&&   &&&        &&&&____&&&&&____&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&  &&           &&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&   &&&&&&&  &&  &&&  &&         &&&&   &&&&  &&&&&&&   &&&&@@@@@@@@
@@@@@@@@@&&&&&&&    &&&&&    &&&  &&       &&&&&&&&&    &&&&&     &&&&&&&@@@@@@@@
@@@@@@@@@&&&&  |____&&&&&____&&&&&    &&&&&&&&&&&&&&____&&&&&____|  &&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&                                                     &&&&&@@@@@@@@
@@@@@@@@@&&&&&                                                     &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%%%%%       %%%%%%%%%  %%%%%%%%%  %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%         %%%%%    %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%%%%%%    %%%%%    %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%%%%%%    %%%%%    %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%         %%%%%    %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%         %%%%%    %%%%       &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%         %%%%%    %%%%%%%    &&&&&@@@@@@@@
@@@@@@@@@&&&&&    %%%%%    %%%%%  %%%%         %%%%%    %%%%%%%    &&&&&@@@@@@@@
@@@@@@@@@&&&&&             %%%%%  %%%%         %%%%%               &&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&                %%%%                         &&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&                                   &&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&                 &&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&         &&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&     &&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& by CC0LABS &@@@@@@@@
@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

interface ERC721Contract {
    function balanceOf(address owner) external view returns (uint256);
}

contract NFTL is Ownable, ERC721A, ReentrancyGuard {
    string public NFTL_PROVENANCE = "";

    // Public sale params
    bool public SALE_IS_ACTIVE = false;

    bool public PRESALE_IS_ACTIVE = false;
    
    uint256 public collectionStartingIndexBlock;

    uint public startingIndex;
    
    uint public constant MAX_NFTL_PURCHASE = 20; // to save gas, some place used value instead of var, so be careful during changing this value
    uint256 public MAX_NFTL = 8888; // to save gas, some place used value instead of var, so be careful during changing this value

    uint256 public NFTL_PRICE = 42000000000000000; // 0.042 ETH
    
    uint256 public PRESALE_NFTL_PRICE = 42000000000000000; // 0.069 ETH

    uint public reserveNFTL = 35;

    mapping(address => bool) whitelistedAddresses;

    // ############################# modifier #############################
    modifier whenPublicSaleActive() {
        require(SALE_IS_ACTIVE, "Public sale is not active");
        _;
    }

    // ############################# constructor #############################
    constructor() ERC721A("NFTL", "NFTL", 20, 8888) { }
    
    // ############################# function section #############################
    
    // ***************************** onlyOwner : Start *****************************
    
    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function mintReserveNFTL(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= reserveNFTL, "Not enough reserve left");
        _safeMint(_to, _reserveAmount);
        reserveNFTL = reserveNFTL - _reserveAmount;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NFTL_PROVENANCE = provenanceHash;
    }
    
    function startSale() external onlyOwner {
        require(!SALE_IS_ACTIVE, "Public sale has already begun");
        SALE_IS_ACTIVE = true;
    }

    function pauseSale() external onlyOwner {
        SALE_IS_ACTIVE = false;
    }

    function startPreSale() external onlyOwner {
        require(!SALE_IS_ACTIVE, "Presale has already begun");
        PRESALE_IS_ACTIVE = true;
    }

    function pausePreSale() external onlyOwner {
        PRESALE_IS_ACTIVE = false;
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        collectionStartingIndexBlock = block.number;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start *************************
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }


    function presaleEligibility(address userAddress) public view returns(bool) {
        uint256 ownTokensCount = 0;
        address RektCatsAddress = 0x27373F5e064a385766eA2f8bBDC11838fdA94293;
        address NounsAddress = 0xb07C397c1e05fcD6aD00c069b0a55c9cf918728D;
        address CryptoadzAddress = 0x6Dfc3EB369101568C6DFba925B28dB5778d51873;
        address BlitmapAddress = 0x79f87ab14AD3609D6e6D69187De4d541A0516dB0;
        address ChainRunnersAddress = 0x9ce51FF8129BCE4035A932bccDD7DaDb8f14b18A;
        ERC721Contract RektCats = ERC721Contract(RektCatsAddress);
        ERC721Contract Nouns = ERC721Contract(NounsAddress);
        ERC721Contract Cryptoadz = ERC721Contract(CryptoadzAddress);
        ERC721Contract Blitmap = ERC721Contract(BlitmapAddress);
        ERC721Contract ChainRunners = ERC721Contract(ChainRunnersAddress);
        
        ownTokensCount = ownTokensCount + RektCats.balanceOf(userAddress) + Nouns.balanceOf(userAddress);
        ownTokensCount = ownTokensCount + Cryptoadz.balanceOf(userAddress) + Blitmap.balanceOf(userAddress);
        ownTokensCount = ownTokensCount +  ChainRunners.balanceOf(userAddress);

        if (ownTokensCount > 0) {
            return true;
        }
        
        if(verifyUser(userAddress)) {
            return true;
        }

        return false;
    }

    function preSaleMintNFTL(uint numberOfTokens) public payable {
        bool isPresaleEligible = presaleEligibility(msg.sender);
        require(isPresaleEligible, "You are not eligible for pres-ale");
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint NFTL");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 8889, "Purchase would exceed max supply of NFTLs"); // ref MAX_NFTL
        uint256 costToMint = NFTL_PRICE * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");
        if (currentTotalSupply == 0) {
            collectionStartingIndexBlock = block.number;
        }
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintNFTL(uint numberOfTokens) public payable {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint NFTL");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 8889, "Purchase would exceed max supply of NFTLs"); // ref MAX_NFTL
        uint256 costToMint = NFTL_PRICE * numberOfTokens;
        require(costToMint <= msg.value, "Ether value sent is not correct");
        if (currentTotalSupply == 0) {
            collectionStartingIndexBlock = block.number;
        }
        _safeMint(msg.sender, numberOfTokens);
    }

        // Set the starting index for the collection
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(collectionStartingIndexBlock != 0, "Starting index block must be set");
        
        uint newStartingIndex = 0;
        newStartingIndex = uint(blockhash(collectionStartingIndexBlock)) % MAX_NFTL;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - collectionStartingIndexBlock > 255) {
            newStartingIndex = uint(blockhash(block.number - 1)) % MAX_NFTL;
        }
        // Prevent default sequence
        if (newStartingIndex == 0) {
            newStartingIndex = newStartingIndex + 1;
        }
        startingIndex = newStartingIndex;
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
      _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
      return ownershipOf(tokenId);
    }
}
/*                                                                                                                                                              
                         #################   #################                      
                         ##      CC0LABS##   ##      CC0LABS##                          
                ###########      CC0LABS#######      CC0LABS##                      
                ##       ##      CC0LABS##   ##      CC0LABS##                      
                ##       ##      CC0LABS##   ##      CC0LABS##                      
                         #################   #################                      
*/
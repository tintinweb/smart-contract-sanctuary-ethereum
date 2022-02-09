// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";


interface IYolk {
    function burn (address from, uint256 amount) external;
    function updateReward (address from, address to) external;
}


contract TannerTest is ERC721, ERC721Enumerable, Ownable {
   
  
   IYolk public Yolk;


   
   
   //   SET BACK TO FALSE BEFORE
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    bool public isLayingEggActive = false;
    
    string private _baseURIextended;

    using Strings for uint256;
    using Strings for uint8;
//update max supply 
    uint256 public constant MAX_SUPPLY = 10000;
//update max public mint MAKE THIS CONSTANT change to uint 8 and 3/mint
    uint256 public MAX_PUBLIC_MINT = 200;
//give token a price
    uint256 public constant PRICE_PER_TOKEN = 0.01 ether;


    uint8 public constant HATCH_ODDS = 3;
//test if changing cost works with the ether there. may need to make these lower... make them constant
    uint256 public PAYTOHATCH_PRICE = 40 ether;
    uint256 public PAYTOHATCHGUARANTEED_PRICE = 160 ether;
    uint256 public PAYTOLAY_PRICE = 40 ether;
    
    mapping(address => uint8) private _allowList;
    
    string constant phoenix = "phoenix";
    string constant dragon = "dragon";
    string constant chicken = "chicken";

    modifier HatchlingzOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Cannot interact with a Hatchlingz you do not own");
        _;
    }
    //update to Hatchlingz
    constructor() ERC721 ("TannerTest", "TT") {
      
    }
    
    // function setGuaranteedHatchCost (uint256 newRollCost) external onlyOwner {
    //     PAYTOHATCHGUARANTEED_PRICE = newRollCost;
    // }
    
    // function setRollToHatchCost (uint256 newRollCost) external onlyOwner {
    //     PAYTOHATCH_PRICE = newRollCost;
    // }

    // function setLayEggCost (uint256 newLayCost) external onlyOwner {
    //     PAYTOLAY_PRICE = newLayCost;
    // }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }  
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    


    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
    


    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender] && numberOfTokens > 0, "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        Yolk.updateReward(msg.sender, address(0));
    
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,"egg"));
            _safeMint(msg.sender, currentToken);
            rollForHatch(currentToken, msg.sender, msg.sender, HATCH_ODDS);
        }
       
    }
    
 

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) virtual external onlyOwner() {
        _baseURIextended = baseURI_;
    }
  
 
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function setYolk(address yolkAddress) external onlyOwner {
        Yolk = IYolk(yolkAddress);
    }

  
    function reserveEggs(address to, uint8 n) public onlyOwner {
        uint256 supply = totalSupply();
        require( supply + n <= MAX_SUPPLY, "reserving too many");
        
        uint8 i;
        Yolk.updateReward(to, address(0));
        

        for (i = 1; i <= n; i++) {
            uint256 currentToken = supply+i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,"egg"));
            _safeMint(to, currentToken);
        }
       
    
    }
    //DO WE WANT THIS?
 //add limit to length of metadatas   
    function reserveHatched(uint8 n, uint8 hatchlingType) public onlyOwner {
         uint256 supply = totalSupply();   
        require( hatchlingType == 0 || hatchlingType == 1 || hatchlingType == 2, "you aren't hatching a valid type");
        require( supply + n <= MAX_SUPPLY, "reserving too many");
        
        uint8 i;
        Yolk.updateReward(msg.sender, address(0));
        //hatchlingType Enter 0 for common, 1 for rare, 2 for legendary
        
        if (hatchlingType == 2){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(phoenix,legendaryMetadataCount.toString()));
               // _tokenMetadata[currentToken] = _legendaryMetadata[_legendaryMetadata.length - 1];
               // _legendaryMetadata.pop();
                _walletBalanceOfLegendary[msg.sender] ++;
                legendaryMetadataCount ++;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
                
    
            }
        }
        
        else if (hatchlingType == 1){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(dragon,rareMetadataCount.toString()));
                // _tokenMetadata[currentToken] = _rareMetadata[_rareMetadata.length - 1];
                // _rareMetadata.pop();
                _walletBalanceOfRare[msg.sender] ++;
                rareMetadataCount ++;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
        
            } 
        }
          
        else if (hatchlingType == 0){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(chicken,commonMetadataCount.toString()));
                // _tokenMetadata[currentToken] = _commonMetadata[_commonMetadata.length - 1];
                // _commonMetadata.pop();
                _walletBalanceOfCommon[msg.sender] ++;
                commonMetadataCount ++;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
            }
        }  
    }
    
 

    function mint(uint8 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens > 0 && numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        Yolk.updateReward(msg.sender, address(0));

        for (uint8 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,"egg"));
            _safeMint(msg.sender, currentToken);
            rollForHatch(currentToken, msg.sender, msg.sender, HATCH_ODDS);
        }
     
    }

        
    function _transfer(address from, address to, uint256 tokenId) internal virtual override (ERC721) {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
    
        Yolk.updateReward(from, to);
        
     
        if (!(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,"egg")))){
            logTypeUpdates(tokenId, from, to);
        }
        
        if (keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,"egg"))){
            rollForHatch(tokenId, from, to, HATCH_ODDS);
        }
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
   
        
        
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    //using HatchlingzOwner Modifier
    function payYolkRollToHatch(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,"egg")), "Your egg or Hatchlingz is not eligible to be hatched!");
        require(!_isTokenHatched[tokenId], "your token is already hatched");
         


          //add update rewards
        Yolk.burn(msg.sender, PAYTOHATCH_PRICE);
        
        rollForHatch(tokenId, msg.sender, msg.sender, HATCH_ODDS);
        
    }
    
    function payForGuaranteedHatch(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,"egg")), "Your egg or Hatchlingz is not eligible to be hatched!");
        require(!_isTokenHatched[tokenId], "your token is already hatched");
        //using modifer instead
        //require(msg.sender == ownerOf(tokenId), "you must be the owner of this Hatchlingz to use this");
        

        //add update rewards
        Yolk.burn(msg.sender, PAYTOHATCHGUARANTEED_PRICE);
        
        rollForHatch(tokenId, msg.sender, msg.sender, 1);
        
    }
    
 

}
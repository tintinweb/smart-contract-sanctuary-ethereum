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


contract Hatchlingz is ERC721, ERC721Enumerable, Ownable {
  
    IYolk public Yolk;

    using Strings for uint256;
    using Strings for uint8;

    bool public isSaleActive = false;
    bool public isAllowListActive = false;
    bool public isLayingEggActive = false;
    
    string private _baseURIextended;


    // Numerical Constants
    uint16 public constant MAX_SUPPLY = 10000;
    uint8 public constant MAX_PUBLIC_MINT = 6;
    uint256 public constant PRICE_PER_TOKEN = 0.085 ether;

    uint8 public constant HATCH_ODDS = 3;
    uint8 public constant HATCH_ODDS_FIFTY = 2;

    uint256 public constant PAYTOHATCH_THIRTY = 30 ether;
    uint256 public constant PAYTOHATCH_FIFTY = 50 ether;
    uint256 public constant PAYTOHATCH_HUNDRED = 100 ether;
    
    // String Constants
    string public constant phoenix = "phoenix";
    string public constant dragon = "dragon";
    string public constant chicken = "chicken";
    string public constant egg = "egg";
    string public constant generation = "gen1";

    //track wallet balance for each type after hatching
    mapping(address => uint256) public _walletBalanceOfLegendary;
    mapping(address => uint256) public _walletBalanceOfRare;
    mapping(address => uint256) public _walletBalanceOfCommon;
    mapping(address => uint256) public _walletBalanceOfEggs;
    mapping(uint256 => string) public _tokenMetadata;
    mapping(uint256 => bool) public _isTokenHatched;
    
    uint256 public commonMetadataCount = 1;
    uint256 public rareMetadataCount = 6001;
    uint256 public legendaryMetadataCount = 9001;

    mapping(address => uint8) private _allowList;

    modifier HatchlingzOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Cannot interact with a Hatchlingz you do not own");
        _;
    }

    constructor() ERC721 ("Hatchlingz", "HTLZ") { }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }  
    
    function setSaleState(bool newState) public onlyOwner {
        isSaleActive = newState;
    }
    
    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
 

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) virtual external onlyOwner {
        _baseURIextended = baseURI_;
    }
  
     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
      
        string memory URIString = _tokenMetadata[tokenId];
      
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, URIString,".json")) : "";
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
        
        Yolk.updateReward(to, address(0));
        _walletBalanceOfEggs[to] += n;

        for (uint8 i = 1; i <= n; i++) {
            uint256 currentToken = supply+i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,egg));
            _safeMint(to, currentToken);
        }
    }

    //#region MINTING FUNCTIONS 
    function mintAllowList(uint8 numberOfTokens) external payable {

        uint256 ts = totalSupply();

        require(isAllowListActive, "Allowlist inactive.");
        require(!isSaleActive, "Sale must be inactive.");
        require(numberOfTokens <= _allowList[msg.sender] && numberOfTokens > 0, "Exceeded max available to purchase.");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase exceeds MAX_SUPPLY.");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent incorrect.");

        _allowList[msg.sender] -= numberOfTokens;

        Yolk.updateReward(msg.sender, address(0));
        _walletBalanceOfEggs[msg.sender] += numberOfTokens;

        for (uint256 i = 1; i <= numberOfTokens; ++i) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,egg));
            _safeMint(msg.sender, currentToken);
            rollForHatch(currentToken, msg.sender, HATCH_ODDS);
        }
    }

    function mint(uint8 numberOfTokens) external payable {

        uint256 ts = totalSupply();
        
        require(isSaleActive, "Sale inactive.");
        require(!isAllowListActive, "AllowList must be inactive.");
        require(numberOfTokens > 0 && numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase exceeds MAX_SUPPLY.");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent incorrect");

        Yolk.updateReward(msg.sender, address(0));
        _walletBalanceOfEggs[msg.sender] += numberOfTokens;

        for (uint256 i = 1; i <= numberOfTokens; ++i) {
            uint256 currentToken = ts + i;
            _tokenMetadata[currentToken] = string(abi.encodePacked(generation,egg));
            _safeMint(msg.sender, currentToken);
            rollForHatch(currentToken, msg.sender, HATCH_ODDS);
        }
    }
    //#endregion MINTING FUNCTIONS 


   
 
    function reserveHatched(uint8 n, uint8 hatchlingType) public onlyOwner {
        uint256 supply = totalSupply();   
        require( hatchlingType == 0 || hatchlingType == 1 || hatchlingType == 2, "you aren't hatching a valid type");
        require( supply + n <= MAX_SUPPLY, "reserving too many");
      
        
        uint8 i;
        Yolk.updateReward(msg.sender, address(0));
        //hatchlingType Enter 0 for common, 1 for rare, 2 for legendary
        
        if (hatchlingType == 2){
            require(n + legendaryMetadataCount <= 10001, "Reserving more Phoenixes than exists.");
            for (i = 1; i <= n; ++i) {
                uint256 currentToken = supply+i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(phoenix,legendaryMetadataCount.toString()));
                ++_walletBalanceOfLegendary[msg.sender];
                ++legendaryMetadataCount;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
            }
        } else if (hatchlingType == 1){
            require(n + rareMetadataCount <= 9001, "Reserving more Dragons than exists.");
            for (i = 1; i <= n; ++i) {
                uint256 currentToken = supply+i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(dragon,rareMetadataCount.toString()));
                ++_walletBalanceOfRare[msg.sender];
                ++rareMetadataCount;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
            } 
        } else if (hatchlingType == 0){
            require(n + commonMetadataCount <= 6001, "Reserving more Chickens than exists.");
            for (i = 1; i <= n; ++i) {
                uint256 currentToken = supply + i;
                 _tokenMetadata[currentToken] = string(abi.encodePacked(chicken,commonMetadataCount.toString()));
                ++_walletBalanceOfCommon[msg.sender];
                ++commonMetadataCount;

                _safeMint(msg.sender, currentToken);
                _isTokenHatched[currentToken] = true;
            }
        }  
    }
    
        
    function _transfer(address from, address to, uint256 tokenId) internal virtual override (ERC721) {
        
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not owned");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
    
        Yolk.updateReward(from, to);
     
        if (!(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,egg)))){
            logTypeUpdates(tokenId, from, to);
        }
        
        if (keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,egg))){
            --_walletBalanceOfEggs[from];
            ++_walletBalanceOfEggs[to];
            rollForHatch(tokenId, to, HATCH_ODDS);
        }
        
        --_balances[from];
        ++_balances[to];
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
   
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    //using HatchlingzOwner Modifier
    function payYolkRollToHatch(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,egg)), "Your egg or Hatchlingz is not eligible to be hatched!");
        require(!_isTokenHatched[tokenId], "your token is already hatched");

       
        Yolk.burn(msg.sender, PAYTOHATCH_THIRTY);
        
        rollForHatch(tokenId, msg.sender, HATCH_ODDS);
    }

    function payYolkRollToHatchFifty(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,egg)), "Your egg or Hatchlingz is not eligible to be hatched!");
        require(!_isTokenHatched[tokenId], "your token is already hatched");

        
        Yolk.burn(msg.sender, PAYTOHATCH_FIFTY);
        
        rollForHatch(tokenId, msg.sender, HATCH_ODDS_FIFTY);
    }
    
    function payForGuaranteedHatch(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,egg)), "Your egg or Hatchlingz is not eligible to be hatched!");
        require(!_isTokenHatched[tokenId], "your token is already hatched");

     
        Yolk.burn(msg.sender, PAYTOHATCH_HUNDRED);
        
        rollForHatch(tokenId, msg.sender, 1);
    }
    
    function rollForHatch (uint256 tokenId, address to, uint256 odds) internal returns ( string memory){
     
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked(generation,"egg")), "Your egg has already hatched or not eligible to hatch!");
        
        uint256 hatchNum = 0;
        uint256 randNumGenerated = randNumGen(tokenId * randNumGen(tokenId, 1000), odds);
        string memory result;
        uint256 tokenMultiplied = tokenId * 123 * randNumGen(tokenId, 1000);
      
        if (hatchNum == randNumGenerated){
            result = "Your egg hatched.";
            uint256 randTypeSelection = randNumGen(tokenMultiplied, 10);
            --_walletBalanceOfEggs[to];
        
            if (randTypeSelection == 1 || randTypeSelection == 0 || randTypeSelection == 2 || randTypeSelection == 4 || randTypeSelection == 6 || randTypeSelection == 8){
                if (commonMetadataCount <= 6000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(chicken,commonMetadataCount.toString()));
                    ++_walletBalanceOfCommon[to];
                    ++commonMetadataCount;
                } else if (rareMetadataCount <= 9000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(dragon,rareMetadataCount.toString()));
                    ++_walletBalanceOfRare[to];
                    ++rareMetadataCount;
                } else if (legendaryMetadataCount <= 10000 ) {
                    _tokenMetadata[tokenId] = string(abi.encodePacked(phoenix,legendaryMetadataCount.toString()));
                    ++_walletBalanceOfLegendary[to];
                    ++legendaryMetadataCount;
                }
            } else if (randTypeSelection == 3 || randTypeSelection == 5 || randTypeSelection == 7){
                if (rareMetadataCount <= 9000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(dragon,rareMetadataCount.toString()));
                    ++_walletBalanceOfRare[to];
                    ++rareMetadataCount;
                } else if (commonMetadataCount <= 6000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(chicken,commonMetadataCount.toString()));
                    ++_walletBalanceOfCommon[to];
                    ++commonMetadataCount;
                } else if (legendaryMetadataCount <= 10000 ) {
                    _tokenMetadata[tokenId] = string(abi.encodePacked(phoenix,legendaryMetadataCount.toString()));
                    ++_walletBalanceOfLegendary[to];
                    ++legendaryMetadataCount;
                }
            } else if (randTypeSelection == 9){
                if (legendaryMetadataCount <= 10000 ) {
                    _tokenMetadata[tokenId] = string(abi.encodePacked(phoenix,legendaryMetadataCount.toString()));
                    _walletBalanceOfLegendary[to] ++;
                    legendaryMetadataCount ++;
                } else if (rareMetadataCount <= 9000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(dragon,rareMetadataCount.toString()));
                    ++_walletBalanceOfRare[to];
                    ++rareMetadataCount;
                } else if (commonMetadataCount <= 6000){
                    _tokenMetadata[tokenId] = string(abi.encodePacked(chicken,commonMetadataCount.toString()));
                    ++_walletBalanceOfCommon[to];
                    ++commonMetadataCount;
                }
            }
            _isTokenHatched[tokenId] = true;
        } else {
            result = "Your egg didn't hatch this time, good luck next time!";
        }
        return  result;
    }

    function randNumGen (uint256 tokenId, uint256 mod) internal view returns (uint256) {
        
        uint256 randNumLong = uint(keccak256(abi.encodePacked(tokenId.toString(),msg.sender,block.timestamp)));
       
        uint256 randNum = randNumLong % mod;
        return randNum;
    }
 
 
    function logTypeUpdates(uint256 tokenId, address from, address to) internal {
        require(from == ownerOf(tokenId), "You are not the owner of this egg.");
        string memory temp = subStringWork(_tokenMetadata[tokenId],0,4);
        
        if (keccak256(abi.encodePacked(temp)) == keccak256(abi.encodePacked("phoe"))){
            --_walletBalanceOfLegendary[from];
            ++_walletBalanceOfLegendary[to];
        } else if (keccak256(abi.encodePacked(temp)) == keccak256(abi.encodePacked("drag"))){
            --_walletBalanceOfRare[from];
            ++_walletBalanceOfRare[to];
        } else if (keccak256(abi.encodePacked(temp)) == keccak256(abi.encodePacked("chic"))){
            --_walletBalanceOfCommon[from];
            ++_walletBalanceOfCommon[to];
        }
    }
    
 
    function subStringWork(string memory str, uint8  startIndex, uint8  endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; ++i) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}
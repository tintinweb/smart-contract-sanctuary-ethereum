/*
SPDX-License-Identifier: GPL-3.0
                                                                                
                         ###################   ###################              
                         ###################   ###################              
                         ##        CC0LABS##   ##        CC0LABS##              
                ###########        CC0LABS#######        CC0LABS##              
                ###########        CC0LABS#######        CC0LABS##              
                ##       ##        CC0LABS##   ##        CC0LABS##              
                ##       ##        CC0LABS##   ##        CC0LABS##              
                         ###################   ###################              
                         ###################   probablynothing.com              
                                                                                
                                                                                
                                        ***                                     
  ******     ***    ***%***((((((     %%**%**   ***    ******    ******    ***( 
 *.***(((  ((*(((  *.**(((%((%(((    *.**%*%%  *((((  *..*((((  *..**(((  ((((((
 *.*(((((((*((((#  *.*((((%   #      *.*(((%*  (*(((  *..*((((  *..*((((  (*((((
 ***((((((((((     *.*(((((((((((    *.*((%(%**(((((  (**(((((  *..*((((((((((((
 ***(((((((*(((((  ***(((((          ***(((%((((((    ((((((((  ****((((#((*((((
 (*((((((  ((*(((  (*(((((*(****((   (*((((((((( #    (**(((((  ((((((((# (*((((
   ### #      ##    #####(   ##         ### #            ### #      ###   ####  
   #                   #                                                   #,   
                    *%%  %%                                                     
 *..*(((((((((   *.%**%%***%**    ..%%**%%%*%*   *..*((((((((    *..***(%.(((((.
  **%((((((((   ****(((###(%*%  .***((((   ((%%  ***((((##(((((  #((((((*%%*(((.
     %((((      *.*(((%   *(((  .,,*(((((((((((  *.*((((   (*((      ***((((    
     %((((      *.*((((   *(((  .,,*(((( # ((((  *.*((((   ((((    *.*((((      
     *((((      (*((((((((((((  *(((((((   ((((  **((((((((((((  **((((((((((((.
      (((        #((((((((((     ,(((((     ((   #(((((((((((     ((((((((((((. 
       ,             #,              ,             ,#,    ,          ,#   ,     

https://www.probablynothing.com
Follow @CC0LABS for future CC0 experiments that drop.      

Supply: 6969 (69 rares included)
FREE MINT*

*this free mint is also a social experiment. When you go to mint a KevinToadz, 
your wallet’s past activity is reviewed. If within 72 hours of your buying/minting 
NFTs, you go to list/sell those NFTs >25% of the time, then you won’t be able to 
mint and will have to get your KevinToadz on a secondary exchange.

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract KevinToadzByCC0LABS is Ownable, ERC721A, ReentrancyGuard {
    string public KEVINZ_PROVENANCE = "";

    bool public SALE_IS_ACTIVE = false;
    
    uint public constant MAX_KEVINZ_PURCHASE = 20; // to save gas, some place used value instead of var, so be careful during changing this value
    uint256 public MAX_KEVINZ = 6969; // to save gas, some place used value instead of var, so be careful during changing this value

    string public PRICE = "FREE (visit https://probablynothing.com/KEVINTOADZ to get mint-key)";
    
    uint public reserve = 69;

    // ############################# constructor #############################
    constructor() ERC721A("KevinToadz by CC0LABS", "KEVINZ", 20, 6969) { }
    
    // ############################# function section #############################

    // ***************************** internal : Start *****************************
    
    function getPrefixedHash(bytes32 messageHash) internal pure returns (bytes32) {
        bytes memory hashPrefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(hashPrefix, messageHash));
    }

    function splitSignature(bytes memory sig) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65 , "invalid length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28 , "value of v ");
        return (v, r, s);
    }
    
    function validateEligibilityKey(address accountAddress, bytes memory eligibilityKey) internal pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(eligibilityKey);
        bytes32 messageHash = keccak256(abi.encodePacked("KEVINZ-", accountAddress));
        bytes32 msgHash = getPrefixedHash(messageHash); 
        return ecrecover(msgHash, v, r, s) == 0x20Ff11c0383C3E84D2D251Ab77eBBaD667c2964C;
    }
    
    // ***************************** internal : End *****************************
    
    // ***************************** onlyOwner : Start *****************************
    
    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function mintReserve(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= reserve, "Not enough reserve left");
        _safeMint(_to, _reserveAmount);
        reserve = reserve - _reserveAmount;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        KEVINZ_PROVENANCE = provenanceHash;
    }
    
    function startSale() external onlyOwner {
        require(!SALE_IS_ACTIVE, "Public sale has already begun");
        SALE_IS_ACTIVE = true;
    }

    function pauseSale() external onlyOwner {
        SALE_IS_ACTIVE = false;
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

    function mint(uint numberOfTokens, bytes memory mintKey) public {
        uint256 currentTotalSupply = totalSupply();
        require(SALE_IS_ACTIVE, "Sale must be active to mint KEVINZ");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 6970, "Purchase would exceed max supply of KEVINZs"); // ref MAX_KEVINZ
        bool isValidMintKey = validateEligibilityKey(msg.sender, mintKey);
        require(isValidMintKey, "Eligibility key is not valid"); 
        
        _safeMint(msg.sender, numberOfTokens);
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
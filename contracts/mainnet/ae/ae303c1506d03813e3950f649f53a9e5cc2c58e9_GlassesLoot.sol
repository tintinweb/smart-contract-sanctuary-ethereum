// SPDX-License-Identifier: MIT

// Adapted from UNKNOWN
// Modified and updated to 0.8.0 by Ge$%#^@ Go#@%
// ART BY F#$%^# Go#@$
// @#$% @#$% 
//
import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract GlassesLoot is ERC721, Ownable, nonReentrant {

    string public GLASSES_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN Glasses Loot from Space are sold out
	
    uint256 public glassesPrice = 100000000000000000; // 0.1 ETH  75% of Mint goes back to the CommunityWallet!  20% of Royalties will go to the Community Wallet as well!

    uint public constant maxGlassesPurchase = 20;

    uint256 public constant MAX_GLASSES = 10000;
	
	uint256 public budgetDev1 = 10000 ether; 
    uint256 public budgetCommunityWallet = 10000 ether; 

    bool public saleIsActive = false;
	
	address private constant DEV1 = 0xb9Ac0254e09AfB0C18CBF21B6a2a490FB608e738;
    address private constant CommunityWallet = 0x7ccAfc2707E88B5C9929a844d074a06eb1555DD7;
    
    // mapping(uint => string) public glassesNames;
    
    // Reserve Glasses for team - Giveaways/Prizes etc
	uint public constant MAX_GLASSESRESERVE = 400;	// total team reserves allowed for Giveaways, Admins, Mods, Team
    uint public GlassesReserve = MAX_GLASSESRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Glasses Loot", "GLOOT") {     }
    //TEAM Withdraw
	
	function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        uint256 witdrawAmount = calculateWithdraw(budgetDev1,(balance * 25) / 100);
        if (witdrawAmount>0){
            budgetDev1 -= witdrawAmount;
            _withdraw(DEV1, witdrawAmount);
        }
        witdrawAmount = calculateWithdraw(budgetCommunityWallet,(balance * 75) / 100);
        if (witdrawAmount>0){
            budgetCommunityWallet -= witdrawAmount;
            _withdraw(CommunityWallet, witdrawAmount);
        }
      
    }

    function calculateWithdraw(uint256 budget, uint256 proposal) private pure returns (uint256){
        if (proposal>budget){
            return budget;
        } else{
            return proposal;
        }
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
    
    

	
	function setGlassesPrice(uint256 _glassesPrice) public onlyOwner {
        glassesPrice = _glassesPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GLASSES_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveGlassesLoot(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_GLASSESRESERVE - GlassesReserve; 
        require(_reserveAmount > 0 && _reserveAmount < GlassesReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        GlassesReserve = GlassesReserve - _reserveAmount;
    }


    function mintGlassesLoot(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint GlassesLoot");
        require(numberOfTokens > 0 && numberOfTokens < maxGlassesPurchase + 1, "Can only mint 20 Glasses at a time");
        require(totalSupply() + numberOfTokens < MAX_GLASSES - GlassesReserve + 1, "Purchase would exceed max supply of GlassesLoot");
        require(msg.value >= glassesPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + GlassesReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_GLASSES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
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
	
    
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

/*
* @title LaCosaOstraClaim
* @author lileddie.eth / Enefte Studio
*/

contract ERC721 {
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {}
}

contract LaCosaOstraClaim {

    ERC721 laCosaOstra = ERC721(0xFD899B7285Ae84923e643D0CEB284658EB38B037);
    uint256 public REFUND = 0.023 ether;

    bool public claimOpen = false;

    mapping(uint256 => bool) blockedTokens;

    address private _owner;
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    constructor() public {
        _owner = msg.sender;   
        blockedTokens[361] = true;
        blockedTokens[459] = true;
        blockedTokens[460] = true;
        blockedTokens[480] = true;
        blockedTokens[516] = true;
        blockedTokens[517] = true;
        blockedTokens[518] = true;
        blockedTokens[519] = true;
        blockedTokens[520] = true;
        blockedTokens[521] = true;
        blockedTokens[522] = true;
        blockedTokens[523] = true;
        blockedTokens[524] = true;
        blockedTokens[528] = true;
        blockedTokens[559] = true;
        blockedTokens[735] = true;
        blockedTokens[755] = true;
        blockedTokens[775] = true;
        blockedTokens[779] = true;
        blockedTokens[780] = true;
        blockedTokens[781] = true;
        blockedTokens[789] = true;
        blockedTokens[790] = true;
        blockedTokens[791] = true;
        blockedTokens[793] = true;
        blockedTokens[795] = true;
        blockedTokens[797] = true;
        blockedTokens[799] = true;
        blockedTokens[803] = true;
        blockedTokens[814] = true;
        blockedTokens[994] = true;
        blockedTokens[996] = true;
   }
    
    /**
    * @notice minting process for the main sale
    *
    */
    function claim() external  {
        require(claimOpen, "Claim is closed");
        require(laCosaOstra.isApprovedForAll(msg.sender,address(this)), "Not Approved");
        uint256[] memory ownedTokens = laCosaOstra.tokensOfOwner(msg.sender);
        uint256 totalToRefund = 0;
        for(uint256 i = 0; i < ownedTokens.length; i++){
            if(!blockedTokens[ownedTokens[i]] && ownedTokens[i] > 55){
                laCosaOstra.safeTransferFrom(msg.sender, burnAddress, ownedTokens[i]);
                totalToRefund += 1;
            }
        }
        uint256 sumToSend = totalToRefund * REFUND;
        payable(msg.sender).transfer(sumToSend);
    }

    /**
    * @notice Toggle the claim open/closed
    *
    */
    function toggleClaim() external onlyOwner {
        claimOpen = !claimOpen;
    }
    
    /**
    * @notice set the price of the NFT for main sale
    *
    * @param _price the price in wei
    */
    function setRefundAmount(uint256 _price) external onlyOwner {
        REFUND = _price;
    }
    
    /**
    * @notice withdraw the funds from the contract to owner wallet. 
    */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function deposit() external payable {}
    

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }


    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }


}
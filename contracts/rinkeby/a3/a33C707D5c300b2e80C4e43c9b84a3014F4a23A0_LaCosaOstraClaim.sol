// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

/*
* @title LaCosaOstraClaim
* @author lileddie.eth / Enefte Studio
*/

contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {}
}

contract LaCosaOstraClaim {

    ERC721 laCosaOstra = ERC721(0xb700805c81205b31e58BE5b75AAC88f1D67e2F9E);
    uint256 public REFUND = 0.023 ether;

    bool public claimOpen = false;

    mapping(uint256 => bool) public claimedTokens;

    address private _owner;
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    constructor() public {
      _owner = msg.sender;   
   }
    
    /**
    * @notice minting process for the main sale
    *
    * @param _tokenIds Ids of tokens to claim against
    */
    function claim(uint256[] calldata _tokenIds) external  {
        require(claimOpen, "Claim is closed");
        require(laCosaOstra.isApprovedForAll(msg.sender,address(this)), "Not Approved");

        uint256 totalClaimed = 0;
        for(uint256 i = 0; i < _tokenIds.length; i++){
            if(laCosaOstra.ownerOf(_tokenIds[i]) == msg.sender) { 
		        laCosaOstra.safeTransferFrom(msg.sender, burnAddress, _tokenIds[i]);
                totalClaimed += 1;
            }
        }
        uint256 sumToSend = totalClaimed * REFUND;
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

    function deposit() external onlyOwner payable {}
    

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
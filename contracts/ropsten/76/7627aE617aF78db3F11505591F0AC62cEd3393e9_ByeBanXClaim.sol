// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  
 

  interface IByeBanX {
    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}
 
    
  contract ByeBanXClaim {
      
      // ByeBanX contract instance
      IByeBanX ByeBanX;
      // Mapping to keep track of which tokenIds have been claimed
      mapping(uint256 => bool) public tokenIdsClaimed;

      constructor(address _ByeBanXContract) {
          ByeBanX = IByeBanX(_ByeBanXContract);
      }

      

      /**
       * @dev function to claim ether
       * Requirements:
       * balance of ByeBanX NFT's owned by the sender should be greater than 0
       * Tokens should have not been claimed for all the NFTs owned by the sender
       */
      function claim() public {
          address sender = msg.sender;
          // Get the number of ByeBanX NFT's held by a given sender address
          uint256 balance = ByeBanX.balanceOf(sender);
          // If the balance is zero, revert the transaction
          require(balance > 0, "You dont own any ByeBanX NFT's");
          // amount keeps track of number of unclaimed tokenIds
          uint256 amount = 0;
          // loop over the balance and get the token ID owned by `sender` at a given `index` of its token list.
          for (uint256 i = 0; i < balance; i++) {
              uint256 tokenId = ByeBanX.tokenOfOwnerByIndex(sender, i);
              // if the tokenId has not been claimed, increase the amount
              if (!tokenIdsClaimed[tokenId]) {
                  amount += 1;
                  tokenIdsClaimed[tokenId] = true;
              }
          }
          // If all the token Ids have been claimed, revert the transaction;
          require(amount > 0, "You have already claimed reward");
         
          // transfer ether for each NFT
          payable(msg.sender).transfer(0.1 ether);
           
      }

    

      // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}
  }
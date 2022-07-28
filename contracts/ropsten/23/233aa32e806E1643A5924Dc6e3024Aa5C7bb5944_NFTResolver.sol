//SPDX-License-Identifier: GPL-3.0
pragma solidity  ^ 0.8.0 ;
interface INFTWarranty {
    
     
    function getSellerNFTs(uint256 sellerId) external view returns(uint256[]memory);    
    function getSellers() external  view returns (uint256 [] memory );
    function getExpiry (uint256 sellerId,uint256 tokenId)external view returns (uint256 expiry);
    function getCreation (uint256 sellerId,uint256 tokenId)external view returns (uint256 creation);
    function burn(uint256 tokenId) external ;
}
contract NFTResolver  {


    function checker(address contract_add)
        external
        view
        returns (bool canExec, bytes memory execPayload)
       // returns(uint256 []  memory arr)
    {
        
       uint256[] memory ans =  INFTWarranty(contract_add ).getSellers();
       for(uint256 i=0;i<ans.length;i++){
           uint256[] memory nfts = INFTWarranty(contract_add ).getSellerNFTs(ans[i]);
           for(uint256 j=0 ;j<nfts.length;j++){
               uint256 expiry =  INFTWarranty(contract_add).getExpiry(ans[i],nfts[i]);
                uint256 creationTime =  INFTWarranty(contract_add).getCreation(ans[i],nfts[i]);
            if( creationTime + expiry >= block.timestamp ){
                execPayload = abi.encodeWithSelector(
                INFTWarranty.burn.selector,
                uint256(nfts[i])
            );
            return (true, execPayload);
           }
         if(creationTime + expiry < block.timestamp ){
               return(false,bytes("Session is ongoing"));
           }

           }


       }
  
}


}
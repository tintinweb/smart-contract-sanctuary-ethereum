/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
/*   
                                                              
T H E D A R K J E S T E R . E T H


                                        %%##%%%&                                
                           ,@@@@(     %#%%%%%%%%%&                              
                          ,&&&&@@@& %##%%%&%    ,#&                             
                          &&&&%&&&&%%#%#%%&       #                             
                         *&   %&& @% .% @&%       .,                            
                         /     & %  @#% @%&%                                    
                                  /[email protected]/#&&                                    
                                  .../*@..%&.                                   
                                 ,    **&@&&                                    
                           *&#%%&%&&@@&&&&%&@@&@                                
                       %#####&&&&&&&&&/(&&&&&&&&&&&%%                            
                     %#######&&&&&&&#//((%&&&&&&&&&@@&&(                         
 @@# *&*   @&       &%######%&&&&&&////((((&&&&&&&&@@&&&&                        
 . .%&&&&%%@&*     &%########&&&&//////(((((#&&&&&&@@&@%@#                       
     &&&@@&@@@@@&&@&#&&%#####&&&////(((())(((&&&&&@@@@@@&                       
    &*&&&@&%@@@@@@@@@&&%#%###&#((((((()))))))))%&&&&&&@%%%                       
     &%&&&&@@@@@@@&@&&#*  ##&&#\(((#(((())))))%%&&@@&&&%%@                      
    % %*&%.%.  .*@&@#  * .#%&&&&//(# T D J ((&&&&@@@ &&&&&&&*                   
       / %*              , #%&&&&&/////((((/&&&&&&@  @&&&&&&%%%##/#/  .*&&*      
         .,                 #&&&&&&%///(((/&&&&&&&(    /&%%%&%%%%&%&%%%%@@@@@@@@,
                             @%#%%%##\%%&/&&@&@@*         &%%&%%%&%%%&%@@@@ #%@@
                            &#&&@&&&&&\&/@@@@@@@@@             *%&&%&&%&&@@   #@ 
                           ##&@&&%%%%%&&&@&@&@@&&@               %%&&%#.%  @    
                          ,#%&@&&&%#%%&&&&&&@@&&@@/             *% *%%( &       
                          .#%@@@&@%%%%&&&&&&&&&&@@.                 *%          
                          %#&@@&&@%%%%&&&&&&&&&&&&&.                 (          
                          ##&@&&&&%%%&&&&&%%&&%%&&&%                            
                          #%&@&&&&&%%&%&&&%%%%%%%%&%&                           
                         *#&&@&&&&@#@@%%&&%%%%%%%%%&%&                          
                         %&&@@&&&&&@@@@%%%%%%%%%%%%%%%&                         
                         &&&@@&&&&&@@#   %%%%%%%%%%%%%%.                        
                         &&&@@&&&&&&#     *%%%%%%%%%%%%%                        
                         .%&@@&&&&&@        %%%%%%%%%%%%%                       
                          &&@@&@@&&/         ,%%%%%%%%%%%&,                     
                           &@@@@@@&@           %%%%%%%%%%%%%                    
                           @@@@@@@@@#           (%%%%%%&%%%%%%                  
                           (&&@@@@@@@             %%%%%%&%%%%%#                 
                            @&&@@@@@&@             /%%%%%&%%%%%(                
                             &&&@@@@@@               %%%%%&&%%%%                
                             *&&&@@@@@@               %%%%%%&&%%&               
                              (&&&@@@@&@.               &%%%%%&%%%&             
                               #&&@@@@@@@                 &%%&%&%&&             
                                  @@@@@@@&@                  &&&&%%&%           
                                  &@@&&&&@ .                %&%&&%@%&&%         
                                 *&@@&&@@&&                 %%%[email protected]&(&&@          
                             &&@&&&&@@@@@@(                 %(%#&&%(%,          
                               (#%#,                         ,,&&@&&&,  
                                                              
T H E D A R K J E S T E R . E T H
                
*/

pragma solidity 0.8.17;

interface IQueryNFTTokens{
    function addressOwnsToken(address _contractAddress, address owner, uint256 tokenId) external view returns (bool);
    function getTokenMetadataUri(address _contractAddress, uint256 tokenId) external view returns (string memory);
    function isSupported(address _contractAddress, address owner, uint256 tokenId) external view returns (bool);
    function getName() external pure returns (string memory);
    function getDescription() external pure returns (string memory);
}

interface ISimplifiedERC721{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Performs ERC721 ownership and metadata static calls
/// @author The Dark Jester
/// @notice You can use this contract to check if a contract supports ERC721 metadata and ownership functions
/// @dev Does not use ERC165 as fallback for non ERC165s would be more expensive and checks +- the same
contract ERC721NFTQuerier is IQueryNFTTokens{
    constructor(){
      
    }

    /// @notice Returns the name of the querier
    /// @dev hard coded text return
    /// @return ERC721 string
    function getName() external pure returns (string memory){
        return "ERC721"; 
    }

    /// @notice Returns the description of the querier
    /// @dev hard coded text return
    /// @return ERC721 or ERC721A string
    function getDescription() external pure returns (string memory){
        return "ERC721 or ERC721A"; 
    }    

    /// @notice Checks contract provided returns ownership and metadata uri
    /// @param contractAddress The address of the NFT contract
    /// @param owner The expected owner of the NFT    
    /// @param tokenId The expected tokenId of the NFT    
    /// @dev Tries to retrieve metadata uri if owner of NFT - static calls
    /// @return true or false    
    function isSupported(address contractAddress, address owner, uint256 tokenId) external view returns (bool){
        bool isOwner = addressOwnsTokenPrivate(contractAddress,owner,tokenId);
        if(!isOwner){
            return false;
        }

        bool hasUri = bytes(getTokenMetadataUriPrivate(contractAddress,tokenId)).length > 0;
        return hasUri;
    }

    /// @notice Checks user owns the nft provided
    /// @param contractAddress The address of the NFT contract
    /// @param owner The expected owner of the NFT    
    /// @param tokenId The expected tokenId of the NFT    
    /// @dev Checks owner of NFT - static calls - exposes internal addressOwnsTokenPrivate
    /// @return true or false
    function addressOwnsToken(address contractAddress, address owner, uint256 tokenId) external view returns (bool){
       return addressOwnsTokenPrivate(contractAddress,owner,tokenId);
    }

    /// @notice Exposes the private url retrieve function for reuse
    /// @param contractAddress The address of the NFT contract
    /// @param tokenId The expected tokenId of the NFT    
    /// @dev Calls getTokenMetadataUriPrivate
    /// @return true or false
    function getTokenMetadataUri(address contractAddress, uint256 tokenId) external view returns (string memory){
        return getTokenMetadataUriPrivate(contractAddress,tokenId);
    }

    /// @notice Tries to retrieve the metadata uri for the contract and token combination as an ERC1155
    /// @param contractAddress The address of the NFT contract
    /// @param tokenId The expected tokenId of the NFT    
    /// @dev Calls ISimplifiedERC721 .ownerOf statically
    /// @return true or false
    function addressOwnsTokenPrivate(address contractAddress, address owner, uint256 tokenId) private view returns (bool){
      try ISimplifiedERC721(contractAddress).ownerOf(tokenId) returns (address returnedOwner) {
          return owner == returnedOwner;
      }  
      catch Error(string memory reason) {
          // catch failing revert() and require()
          revert(reason);
      }  
      catch (bytes memory reason) {
          // catch failing assert()
          revert(abi.decode(reason, (string)));
      }
    }    

    /// @notice Tries to retrieve the metadata uri for the contract and token combination as an ERC1155
    /// @param contractAddress The address of the NFT contract
    /// @param tokenId The expected tokenId of the NFT    
    /// @dev Calls ISimplifiedERC721 .tokenURI statically
    /// @return uri string
    function getTokenMetadataUriPrivate(address contractAddress, uint256 tokenId) private view returns (string memory){
      try ISimplifiedERC721(contractAddress).tokenURI(tokenId) returns (string memory uri) {
          return uri;
      }  
      catch Error(string memory reason) {
          // catch failing revert() and require()
          revert(reason);
      }  
      catch (bytes memory reason) {
          // catch failing assert()
          revert(abi.decode(reason, (string)));
      }
    }

     // NO FALLBACK RECEIVE FUNCTION - DON'T SEND ETHER HERE.
}
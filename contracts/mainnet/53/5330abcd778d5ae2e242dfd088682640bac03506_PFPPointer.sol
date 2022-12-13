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

interface INFTQuerierProvider{
    function getSupportedQueriers() external view returns (IQueryNFTTokens[] memory queriers);
    function registerQuerier(address querier) external;
    function getQuerierByIndex(uint256 index) external view returns (IQueryNFTTokens querier);
}

/// @title A standards compliant NFT/PFP Registry pointer
/// @author The Dark Jester
/// @notice You can use this contract to register an owned NFT as well as retrieve the metadata uri
/// @dev This is currently owned, but will have the ownership burnt
contract PFPPointer {
  address _owner;
  address _nftQuerierProvider;

  mapping(address=>Pointer) private pfpAddressPointers;
  
  struct Pointer{
    address nftContract;
    uint256 tokenId;
    uint256 querierIndex;
  }

  event PfpRegistered(address indexed owner, address nftContract, uint256 tokenId);
  event OwnerChanged(address indexed newOwner, address oldOwner);
  event OwnershipBurnt(address owner);
  event ProviderChanged(address newProvider, address oldProvider);

  /// @dev provider address is set on construction and will be unchangable once ownership is burnt
  constructor(address nftQuerierProvider)  {
      _owner = msg.sender;

      _nftQuerierProvider = nftQuerierProvider;
  }

  /// @notice Returns the address of the querier provider
  /// @dev provider address will be fixed once ownership is burnt
  /// @return address of the INFTQuerierProvider
  function getProvider() public view returns (address) {
      return _nftQuerierProvider;
  }

  /// @notice Registers the NFT token based on the contract address and tokenId
  /// @param nftContract The address of the NFT Contract
  /// @param tokenId The owned tokenId ad the nftContract address
  /// @dev This auto detects a supported standard (or not) and is more expensive than by index
  function registerStandardPfpPointer(address nftContract, uint256 tokenId) public {
      uint256 supportedTokenStandardId = getSupportingStandardId(nftContract, tokenId);

      emit PfpRegistered(msg.sender, nftContract, tokenId);

      pfpAddressPointers[msg.sender] = Pointer(nftContract,tokenId,supportedTokenStandardId);
  }

  /// @notice Registers the NFT token based on the contract address and tokenId
  /// @param nftContract The address of the NFT Contract
  /// @param tokenId The owned tokenId ad the nftContract address
  /// @param index The index of the querier in the collection from the querier provider
  /// @dev This still checks ownership and contract support, but does not iterate querier collection
  function registerPfpPointerByIndex(address nftContract, uint256 tokenId, uint256 index) public {
      verifyStandardAtIndexIsSupported(nftContract, tokenId,index);

      emit PfpRegistered(msg.sender, nftContract, tokenId);

      pfpAddressPointers[msg.sender] = Pointer(nftContract,tokenId,index);
  }

  /// @notice Retrieves the registered PFP Metadata Uri and supported standard
  /// @param expectedPfpOwner The expected owner EOA address
  /// @dev Uses getDescription on IQueryNFTTokens - This still checks ownership at query time and errors if there has been nothing registered
  /// @return uri standardSupported The NFT Metadata Uri and the supported standard description ( e.g. ERC721 or ERC721A )
  function getMetadataDetails(address expectedPfpOwner) public view returns (string memory uri, string memory standardSupported){
     Pointer memory pointer = pfpAddressPointers[expectedPfpOwner];
     require(pointer.nftContract != address(0), "Not Registered");
    
     IQueryNFTTokens querier = (INFTQuerierProvider(_nftQuerierProvider).getSupportedQueriers())[pointer.querierIndex];
     
     string memory tokenUri = getTokenMetadataUri(pointer, querier,expectedPfpOwner);

     uri = tokenUri;
     standardSupported = querier.getDescription();
  }

  /// @notice Retrieves the registered PFP Metadata Uri
  /// @param pointer The expected owner EOA address
  /// @param querier The querier used to retrieve the Metadata
  /// @param expectedPfpOwner The expected owner EOA address
  /// @dev Uses getTokenMetadataUri on IQueryNFTTokens - This also checks ownership
  /// @return The NFT Metadata Uri and the supported standard description ( e.g. ERC721 or ERC721A ) 
   function getTokenMetadataUri(Pointer memory pointer, IQueryNFTTokens querier,address expectedPfpOwner) private view returns (string memory) {
      try querier.getTokenMetadataUri(pointer.nftContract, pointer.tokenId) returns (string memory uri) {
          require(bytes(uri).length > 0, "Uri missing");
          checkOwner(pointer,expectedPfpOwner, querier);
          return uri;
      }  
      catch Error(string memory reason) {
          revert(reason);
      }  
      catch (bytes memory reason) {
          revert(abi.decode(reason, (string)));
      }
  }

  /// @notice Checks NFT ownership
  /// @param pointer The expected owner EOA address
  /// @param expectedPfpOwner The expected owner EOA address
  /// @param querier The querier used to retrieve the Metadata
  /// @dev uses addressOwnsToken on IQueryNFTTokens
  function checkOwner(Pointer memory pointer, address expectedPfpOwner, IQueryNFTTokens querier) private view {
      try querier.addressOwnsToken(pointer.nftContract, expectedPfpOwner, pointer.tokenId) returns (bool ownsToken) {
          require(ownsToken, "Not owner");
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

  /// @notice Verify standard is supported based on index, as well as ownership
  /// @param nftContract The NFT Contract where the PFP is held
  /// @param tokenId The tokenId at the nftContract
  /// @param index The querier used to retrieve the Metadata
  /// @dev uses getQuerierByIndex on INFTQuerierProvider and isSupported on IQueryNFTTokens
  function verifyStandardAtIndexIsSupported(address nftContract, uint256 tokenId, uint256 index) private view {
     require(isContract(nftContract), "not contract");

     IQueryNFTTokens querier = INFTQuerierProvider(_nftQuerierProvider).getQuerierByIndex(index);
     
     try querier.isSupported(nftContract, msg.sender, tokenId) returns (bool supported) {
        if(!supported) {
            revert("Unsupported / not owner");
        }
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

  /// @notice Verify standard is supported based on index, as well as ownership
  /// @param nftContract The NFT Contract where the PFP is held
  /// @param _tokenId The tokenId at the nftContract
  /// @dev uses getSupportedQueriers on INFTQuerierProvider and isSupported on IQueryNFTTokens
  /// @return returns the index from getSupportedQueriers if successful
  function getSupportingStandardId(address nftContract, uint256 _tokenId) private view returns (uint256) {
     require(isContract(nftContract), "not contract");

     IQueryNFTTokens[] memory queriers = INFTQuerierProvider(_nftQuerierProvider).getSupportedQueriers();

     for (uint256 i = 0; i < queriers.length; i++) {
        try queriers[i].isSupported(nftContract, msg.sender, _tokenId) returns (bool supported) {
              if(supported) {
                  return i; // array index wrt providers
              }
        }  
        catch Error(string memory) {
          // deliberate fallthrough to cater for loop
        }  
        catch (bytes memory) {
          // deliberate fallthrough to cater for loop
        }
     }

     revert("Unsupported / not owner");
  }

  /// @notice Changes provider in the event of an exploit or bug
  /// @param provider The new provider address
  /// @dev needs to be owner and will not work once ownership is burnt
  function changeProvider(address provider) _isOwner() public {
    emit ProviderChanged(_nftQuerierProvider, address(provider));
    _nftQuerierProvider = provider;
  }

  /// @notice Burns ownership
  /// @dev needs to be owner and will not work once ownership is burnt - only do this when happy
  function burnOwnership() _isOwner() public {
    emit OwnershipBurnt(msg.sender);
    _owner = address(0);
  }

  /// @notice Changes ownership if main account is compromised
  /// @dev needs to be owner and will not work once ownership is burnt
  function changeOwnership(address owner) _isOwner() public {
    emit OwnerChanged(owner,_owner);
    _owner = owner;
  }

  modifier _isOwner() {
    require(_owner == msg.sender, "Not owner");
    _;
  }

  /// @notice Checks the address is a contract address
  /// @dev makes sure there is code at the address - none on EOA
  function isContract(address _addr) internal view returns (bool)
  {
    uint size;
    assembly { size := extcodesize(_addr)}
    return size > 0;
  }

  // NO FALLBACK RECEIVE FUNCTION - DON'T SEND ETHER HERE - IT WILL GO TO THE ABYSS
}
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

interface INFTQuerierProviderOwnership{
    function getOwners() external view returns (address[] memory owners);
    function addOwner(address owner) external;
}

/// @title Manages Querier provider ownership
/// @author The Dark Jester
/// @notice You can use this contract to manage new owners for approving
/// @dev Does not include voting out
contract NFTQuerierProviderOwnership is INFTQuerierProviderOwnership{
    event OwnerAdded(address indexed owner);
    event OwnerAddedForApproval(address indexed owner);
    event OwnerApproved(address indexed owner, address approvedBy);

    uint256 constant percentageApprovalForOwners = 67;
    address[] _owners;

    mapping(address=>bool) public isOwner;
    mapping(address=>bool) public isOwnerPendingApproval;
    mapping(address=>mapping(address=>bool)) pendingOwnerVotes; 
    mapping(address=>uint256) pendingOwnerApprovalCount;

    constructor(){
         _owners.push(msg.sender);
         isOwner[msg.sender] = true;
    }

    modifier _isOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier _isNotOwner(address add) {
        require(!isOwner[add], "Is owner");
        _;
    }

    function getOwners() external view returns (address[] memory owners){
         return _owners;
    }

    /// @notice Adds a new owner or proposes the new owner 
    /// @param owner New owner to add
    /// @dev Depending on threshold, owner may be added automatically
    function addOwner(address owner) _isOwner() external {
        require(!isOwner[owner], "is owner");
        require(!isOwnerPendingApproval[owner], "is pending");

        // don't need others voting
        if(_owners.length == 1){
            emit OwnerAdded(owner);
            _owners.push(owner);
            isOwner[owner] = true;
        }
        else{
            emit OwnerAddedForApproval(owner);
             // add to waiting list
             isOwnerPendingApproval[owner] = true;
             // set initial voter count
             pendingOwnerApprovalCount[owner] = 1;
             // set adder as voted
             pendingOwnerVotes[owner][msg.sender] = true;
        }
    }

    /// @notice Approves pending owner being voted for 
    /// @param owner New owner to vote for
    /// @dev Depending on threshold, owner may be added automatically. Can't double vote, or vote for owners already in.
    function approveOwner(address owner) _isNotOwner(owner) _isOwner() _hasNotApprovedOwner(owner) external  {
        emit OwnerApproved(owner, msg.sender);
        pendingOwnerApprovalCount[owner] = pendingOwnerApprovalCount[owner]+1;
        
        if((pendingOwnerApprovalCount[owner]*100/_owners.length) >= percentageApprovalForOwners){
             emit OwnerAdded(owner);
             _owners.push(owner);
             isOwner[owner] = true;
             delete isOwnerPendingApproval[owner]; // don't need it anymore
             delete pendingOwnerApprovalCount[owner];
        } 
        else{
            pendingOwnerVotes[owner][msg.sender] = true;
        }
    }

    modifier _hasNotApprovedOwner(address owner){
        require(!pendingOwnerVotes[owner][msg.sender], "is approved");
        _;
    }
}

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

/// @title A provider of NFT metadata and ownership query engines
/// @author The Dark Jester
/// @notice You can use this contract to get and add NFT query contracts
/// @dev Inhertits INFTQuerierProvider and NFTQuerierProviderOwnership (multisig)
contract NFTQuerierProvider is INFTQuerierProvider, NFTQuerierProviderOwnership{
  
    IQueryNFTTokens[] private _queriers;

    uint256 constant percentageApprovalForQueriers = 67;
    
    mapping(address=>bool) isQuerier;
    mapping(address=>bool) isQuerierPendingApproval;
    mapping(address=>mapping(address=>bool)) pendingQuerierVotes; 
    mapping(address=>uint256) pendingQuerierApprovalCount;

    event QuerierAdded(address indexed querier);
    event QuerierAddedForApproval(address indexed querier);
    event QuerierApproved(address indexed querier, address approvedby);

    /// @dev by default ERC721 and ERC1155 supported
    constructor(address erc721Querier, address erc1155Querier){
        _queriers.push(IQueryNFTTokens(erc721Querier));
        isQuerier[erc721Querier] = true;
        _queriers.push(IQueryNFTTokens(erc1155Querier));
        isQuerier[erc1155Querier] = true;
    }

    /// @notice Returns the IQueryNFTTokens of the querier provider at a specific index
    /// @param index Index of the querier in the array
    /// @dev simple lookup with bounds checks
    /// @return querier IQueryNFTTokens
    function getQuerierByIndex(uint256 index) external view returns (IQueryNFTTokens querier){
        require(_queriers.length > 0, "No queriers");
        require(index < _queriers.length, "Too high");

        return _queriers[index];
    }

    /// @notice Returns the IQueryNFTTokens collection
    /// @dev array mapping to storage variable
    /// @return The entire IQueryNFTTokens[] 
    function getSupportedQueriers() external view returns (IQueryNFTTokens[] memory){
        return _queriers;
    }

    /// @notice Registers a new address as an NFT querier
    /// @param querier Address of new querier
    /// @dev checks if already exists or has a vote for acceptance pending. If more than once owner, voting in is needed
    function registerQuerier(address querier) _isOwner() external  {
        require(!isQuerier[querier], "already querier");
        require(!isQuerierPendingApproval[querier], "already pending");

        // don't need others voting
        if(_owners.length == 1){
            emit QuerierAdded(querier);
            isQuerier[querier] = true;
            _queriers.push(IQueryNFTTokens(querier));
        }
        else{
            emit QuerierAddedForApproval(querier);
             // add to waiting list
             isQuerierPendingApproval[querier] = true;
             // set initial voter count
             pendingQuerierApprovalCount[querier] = 1;
             // set adder as voted
             pendingQuerierVotes[querier][msg.sender] = true;
        }
    }

    /// @notice Allows other owners to approve the querier addition
    /// @param querier Address of new querier
    /// @dev if threshold reached, it adds the new querier
    function approveQuerier(address querier) _isOwner() _hasNotApprovedQuerier(querier) external  {
         require(!isQuerier[querier], "already querier");

        emit QuerierApproved(querier, msg.sender);
        pendingQuerierApprovalCount[querier] = pendingQuerierApprovalCount[querier]+1;
        
        if((((pendingQuerierApprovalCount[querier]*100))/_owners.length) >= percentageApprovalForQueriers){
             emit QuerierAdded(querier);
             _queriers.push(IQueryNFTTokens(querier));
             isQuerier[querier] = true;
             delete isQuerierPendingApproval[querier]; // don't need it anymore
             delete pendingQuerierApprovalCount[querier]; // don't need it anymore
        } 
        else{
            pendingQuerierVotes[querier][msg.sender] = true;
        }
    }

    modifier _hasNotApprovedQuerier(address querier){
        require(!pendingQuerierVotes[querier][msg.sender], "already approved");
        _;
    }

    // NO FALLBACK RECEIVE FUNCTION - DON'T SEND ETHER HERE - IT WILL GO TO THE ABYSS
}
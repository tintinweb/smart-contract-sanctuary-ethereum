// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

/**                                                              
                                          .::::.                                          
                                      -+*########*+-                                      
                                   .=################=.                                   
                                 .=######*=-::-=++++++=:                                  
                      ......   .=######+.  .........................                      
                 .-+*#####+. .=######+. .=###########################*+-.                 
                =#######+. .=######+. .=#################################=                
               +*****+=. .=******+.  .-----------------------------=+*****+               
              -*****:  .=******+.                          :::::::.  :*****-              
              =*****  -******=.                            .=******=. .+***=              
              :*****-                                        .=******=. .+*:              
               =******+++++++++++==-:.              .:-==+++=. .=******=. .               
                :*********************+:          :+**********=. .=******=.               
             .=-  :-+*******************-        -**************=. .=******=.             
           .=****=:                =*****        *****=              .=******=.           
         .=******=.                .*****.      .*****.                .=******=.         
        =******=.                  .*****.      .*****.                  .=******=        
      :******=.                    .*****.      .*****.                    .=******:      
     :*****+.                      .*****.      .*****.                      .+*****:     
     +****=                        .*****.      .*****.                        =****+     
    .*****.                        .*****.      .*****.                        .*****.    
    .*****:                        .*****.      .*****.                        :*****.    
     =****+.                       .*****.      .*****.                       .+****=     
      +****+-                      .*****.      .*****.                      -+****+      
       =*****+-                    .*****.      .*****.                    -+*****=       
        .=*****+-                  .*****.      .*****.                  -+*****=.        
          .=*****+-                .*****.      .*****.                -+*****=.          
            .=++++++-              .+++++.      .+++++.              -++++++=.            
              .=++++++-            .+++++.      .+++++.            -++++++=.              
                .=++++++-          .+++++.      .+++++.          -++++++=.                
                  .=++++++-        .+++++.      .+++++.        -++++++=.                  
                    .=++++++-      .+++++.      .+++++.      -++++++=.                    
                      .=++++++-     +++++=      =+++++     -++++++=.                      
                        .=++++++-   :+++++-    -+++++:   -++++++=.                        
                          .=++++++-  .::::.  :++++++-  -++++++=.                          
                            .=++++++=-::::-=+++++++:  =+++++=.                            
                              .=+++++++++++++++++:  :+++++=.                              
                                 :=++++++++++=-.  :++++=:                                 
                                     ......      ....
 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface SoarProofInterface {
    function ownerOf(uint16 _tokenId) external view returns(address);
    function tokenToLevel(uint16 _tokenId) external view returns(uint8);
}

contract SoarProofOwnControl is SoarProofInterface, Ownable {

    uint16 constant MAX_STAGE_ID = 10;
    uint256 constant public startTime = 1658577600; // 2022-07-23 12:00:00 (UTC)
    uint256 constant public stagePerPeriod = 60 * 60 * 24 * 10; // 60 (sec) * 60 (min/hr) * 24 (hr/day) * 10  = 10 Days

    SoarProofInterface SoarProof;

    uint16[10] eachStageSaledAmount = [0, 42, 67, 0, 0, 
                                        0,  0,  0, 0, 0];

    event StageMaxTokenId(uint8 indexed stageId, uint16 maxTokenId);

    constructor() {
        setSoarProof(0xF2A9E0A3729cd09B6E2B23dcBB1192dBaAB06E15);
    }

    function calculateRewardTime(uint16 _stageId) public pure returns(uint256) {
        return startTime + (_stageId * stagePerPeriod);
    }

    function latestStageId() public view returns(uint16) {
        for(uint16 stageId = MAX_STAGE_ID; stageId > 0; stageId--) {
            if(block.timestamp > calculateRewardTime(stageId)) {
                return stageId;
            }
        }
        return 0;
    }

    function tokenToLevel(uint16 _tokenId) external view returns(uint8) {
      uint16 currentStageId = latestStageId();
      uint16 stageMaxTokenId = eachStageSaledAmount[currentStageId] - 1; // tokenId start from 0, then maxTokenId minus 1.
      if(_tokenId > stageMaxTokenId) {
        return 0;
      }
      return SoarProof.tokenToLevel(_tokenId);
    }

    function ownerOf(uint16 _tokenId) external view returns(address) {
      uint16 currentStageId = latestStageId();
      uint16 stageMaxTokenId = eachStageSaledAmount[currentStageId] - 1; // tokenId start from 0, then maxTokenId minus 1.
      if(_tokenId > stageMaxTokenId) {
        return address(0);
      }
      return SoarProof.ownerOf(_tokenId);
    }

    function setStageSaledAmount(uint8 _stageId, uint16 _maxTokenId) external onlyOwner {
      eachStageSaledAmount[_stageId] = _maxTokenId;
      emit StageMaxTokenId(_stageId, _maxTokenId);
    }

    function setSoarProof(address _addr) public onlyOwner {
        SoarProof = SoarProofInterface(_addr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity 0.8.6;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";

//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
// ONCHAIN BLOCK INVADERS - Upgradable Colors Storage contract

contract BlockInvadersCargoShip is  Ownable {
    struct paintStruct{
        string[] eyesColor;
        string[] color;
        string[] backgroundColor;
        string[] colName;
        string   effect;
        string  chromaName;
    }
    mapping(uint256 => paintStruct) paint;
    
    event ColorStorred();


    constructor() Ownable() {

    //Light Pallete
    paint[0].eyesColor = ["JyM3NkE3QjMn", "JyNDM0U2REEn", "JyM3RjlBQzYn", "JyM4NjhCQjAn", "JyNEQkI2QUQn", "JyNGRkFDOTkn", "JyNGRkU4OTgn", "JyNFNjY1NEMn"];
    paint[0].colName = ["U2lsdmVy", "RGVzZXJ0", "U2VycGVudGluZSAg", "U29saXMg", "SmFkZSAg", "Q29iYWx0", "T2NlYW4g", "RW1lcmFsZCAg", "SmFzcGVy", "SW5kaWdv", "QXNo", "VGl0YW5pdW0g", "Q2FyYm9u", "U2NhcmxldCAg", "Q29yYWwg", "QnJhc3Mg", "QXp1cmUg", "Q3JpbXNvbiAg"];
    paint[0].color = ["JyNkOGUyZWIn", "JyNEQkI2QUQn", "JyM3QUI4QjIn", "JyNmYWQ5OGMn", "JyM2RTlDQTYn", "JyM3MDgzQUYn", "JyM1MDczOEYn", "JyNiOGQ5Y2Un", "JyNDRkFDQTMn", "JyM3Mzc3OTcn", "JyM5NDkzOEYn", "JyM3MzdCOEIn", "JyNDNkNDQ0Yn", "JyNmMmEzOTEn", "JyNGNENEQ0Qn", "JyNDQ0MzQUYn", "JyM3RjlBQzYn", "JyNEODYxNDgn"];
    paint[0].backgroundColor = ["JyNmNGU0ZDYn", "JyNlYWViZTUn", "JyNGMEVCRTkn", "JyNGREVERTcn", "JyNGMEUzRTMn", "JyNFQ0YyRkIn", "JyNGREZERTgn", "JyNGMkYyRjIn"];
    paint[0].effect = "PGZpbHRlciBpZD0nbmVvbicgeT0nLTInIHg9Jy0xJyB3aWR0aD0nMzUwJyBoZWlnaHQ9JzM1MCc+PGZlRHJvcFNoYWRvdyBmbG9vZC1jb2xvcj0nIzhBNzk1RCcgZHg9JzAnIGR5PSc2JyBmbG9vZC1vcGFjaXR5PScwLjY1JyBzdGREZXZpYXRpb249JzIuNScgcmVzdWx0PSdzaGFkb3cnLz48ZmVPZmZzZXQgaW49J1N0cm9rZVBhaW50JyBkeD0nMCcgZHk9JzIuNCcgcmVzdWx0PSdvZmZTdHJQbnQnLz48ZmVGbG9vZCBmbG9vZC1jb2xvcj0nIzRBNDEzMicgZmxvb2Qtb3BhY2l0eT0nMicgcmVzdWx0PSdmbG9vZDEnIC8+PGZlT2Zmc2V0IGluPSdTb3VyY2VHcmFwaGljJyBkeD0nMCcgZHk9JzInIHJlc3VsdD0nb2ZmRmxvb2QnLz48ZmVPZmZzZXQgaW49J1NvdXJjZUdyYXBoaWMnIGR4PScwJyBkeT0nOScgcmVzdWx0PSdvZmZTaGFkb3cnLz48ZmVDb21wb3NpdGUgaW49J2Zsb29kMScgaW4yPSdvZmZGbG9vZCcgb3BlcmF0b3I9J2luJyAgcmVzdWx0PSdjbXBGbG9vZCcgLz48ZmVDb21wb3NpdGUgaW49J3NoYWRvdycgaW4yPSdvZmZTaGFkb3cnIG9wZXJhdG9yPSdpbicgcmVzdWx0PSdjbXBTaGEnIC8+PGZlR2F1c3NpYW5CbHVyIGluPSdvZmZTdHJQbnQnIHN0ZERldmlhdGlvbj0nMScgcmVzdWx0PSdiU3Ryb2tlUCcvPjxmZUdhdXNzaWFuQmx1ciBpbj0nY21wRmxvb2QnIHN0ZERldmlhdGlvbj0nMC42JyByZXN1bHQ9J2JGbG9vZCcvPjxmZUdhdXNzaWFuQmx1ciBpbj0nY21wU2hhJyBzdGREZXZpYXRpb249JzAuNicgcmVzdWx0PSdiU2hhZG93Jy8+PGZlTWVyZ2U+PGZlTWVyZ2VOb2RlIGluPSdiU3Ryb2tlUCcvPjxmZU1lcmdlTm9kZSBpbj0nYnNoYWRvdycvPjxmZU1lcmdlTm9kZSBpbj0nYkZsb29kJy8+PGZlTWVyZ2VOb2RlIGluPSdTb3VyY2VHcmFwaGljJy8+PC9mZU1lcmdlPjwvZmlsdGVyPiAg";


    //Light side
    paint[0].chromaName = 'TGlnaHQgU2lkZSAg';
    }
    
    function isCargoShip() external pure returns (bool) {return true;}
    
    function loadChroma(string memory _chromaName,string[] memory _eyesColor,string[] memory _color,string[] memory _bkpcolor,string[] memory _colName,string memory _effect,uint256 idx ) external onlyOwner {
        
        paint[idx].eyesColor = _eyesColor;
        paint[idx].color = _color;
        paint[idx].backgroundColor = _bkpcolor;
        paint[idx].colName = _colName;
        paint[idx].effect = _effect;
        paint[idx].chromaName = _chromaName;
        emit ColorStorred();
    }
    function unloadChroma(uint256 idx) external view returns (string[] memory,string[] memory,string[] memory,string[] memory,string memory,string memory){
        return (paint[idx].eyesColor,paint[idx].color,paint[idx].backgroundColor,paint[idx].colName,paint[idx].effect,paint[idx].chromaName);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
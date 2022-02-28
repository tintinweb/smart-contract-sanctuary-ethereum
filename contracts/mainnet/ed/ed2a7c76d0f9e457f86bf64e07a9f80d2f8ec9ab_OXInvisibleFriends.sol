// SPDX-License-Identifier: MIT                                                                     
/*
         0xInvisibleFriends, join the revolution; be yellow, not mellow!
....::::::::::::::::::::..            
....::....                      ..::::        
....                    ....::::..      ....::::::::::::::::::..      ::      
..++######**==          ..++########--..::::....                    ..::..    ::    
::####==--==##%%**      ::####==--++####**                                ::      ::  
****::      ::##%%==  ..##**::    ..--####--                        ==::  ----::..::  
--##--          ==####::++##--..        ++##**                      --%%==--==--::  ::..
++**..          ..####++****::          ::####::                  ..##++--------::....::
##++..          ..##::..**++            ..####**::..............::**++------------::  ::
##**==------++++++**    **++            ..######%%##############++------------==::    ..
****::::::::----++##::..++**..          --####**----------==++--------------..        ..
::##--        ..++##**::--##--          **##**        ..----------------..          ....
==##--    ::++####::    ++**--    ..++####..    ..----------------::              ..  
==##**++######--        ==##****##%%**..    ----------------::                ....  
..--++==::::            ..------::    ..::  ::--------::..                  ::    
..    ..                        ..++      ------..                    ::      
..      ::                      [email protected]@==  ..--..                  ..  ::::      
....    ..::..          ....::::--==::..                    ......::--        
::        ..::::::::::....                                ::    ....        
::                                                        ..  ..  ::        
::                                                    ::::..  ....        
....                                              ..::..      ::          
::..                                        ..::..        ..            
::::                                ..::::            ....            
..::..                      ..::::..                ::              
..::::..............::....                  ..::                
..--..                              ..::                  
..::                        ..::..                    
..::....          ....::..                        
          ..............             
 */
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract OXInvisibleFriends is ERC721, ERC721URIStorage, Ownable {
   using SafeMath for uint256;
   using ECDSA for bytes32;

    uint256 public constant maxFrens = 5000;
    uint256 public constant maxFreeFrens = 500;
    uint256 public constant maxFreeMints = 2;
    uint256 public constant maxMintsPerTxn = 10; 
    uint256 public constant price = 0.02 ether;

    mapping(address => uint256) public mintedByWallet;

    string public baseTokenURI = "ipfs://InstantRevealPostMintSellOut/";

    constructor() ERC721("0xInvisibleFriends", "0xIF") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function mint(uint256 amount) public payable {
        require(_owners.length + amount <= maxFrens, "No more frens remain");

        if (_owners.length > maxFreeFrens) {
            require(msg.value >= price.mul(amount), "Incorrect amount of funds");
            require(amount <= maxMintsPerTxn, "Max 10 per transaction");
        } else {
            require(mintedByWallet[_msgSender()] + amount <= maxFreeMints, "Max free per wallet minted");
            mintedByWallet[_msgSender()] += amount;
        }
        
        for(uint256 i = 0; i < amount; i++) {
            _mint(_msgSender());
        }
    }

    function totalTokens() public view returns (uint256) {
        return _owners.length;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT 
// @author: @CoolMonkes - Trainers - CTRNRS                                                                                                                                                                       
 //                ,,,   ,,,   ,,,    ,,,   ,,,                                     
 //                ,,,   ,,,   ,,,    ,,,   ,,,                                     
 //                ,,,,,,   ,,,,,,,,,,   ,,,,,,                                     
 //                ,,,,,,,,,,,,,,,,,,,,,,,,,,,,                                     
 //                   ,,,,,,,,,,,,,,,,,,,,,,                                        
 //             ......                      ......                                  
 //             ......                      ......                                  
 //             ..................................                                  
 //             ...&&&&&&&&&..........&&&&&&&&&...                                  
 //   ,,,,,,,   ...         &&&&&&.         &&&...   ,,,,,,                         
 //   ...%%%%   ...%%%  @   &&&&&&%%%%   @  &&&...   %%%...                         
 //   ...%&&&   ...&&&  @   &&&&&&&&&&   @  &&&...   &&&...                         
 //   .......   ...&&&      &&&&&&&&&&      &&&...   ......                         
 //             ......&&&&&&***&&&/***&&&&&&......                                  
 //             ...&&&&&&&&&&&&&&&&&&&&&&&&&&&&... 
 //             ...&&&&&&***&&&&&&&&&&***&&&&&&...                                  
 //             ...&&&&&&***&&&&&&&&&&***&&&&&&...                                  
 //                ...&&&&&&**********&&&&&&...                                     
 //                      ***&&&&&&&&&&***                                           
 //                ......     .....     ......                                     
 //             ,,,,,,,,,................,,,,,,,,,                                  
 //             ,,,,,,,,,................,,,,,,,,,                                  
 //             ,,,,,,,,,&&&&&&,,,%&&&&&&,,,,,,,,,                                  
 //             ,,,   ,,,&&&&&&&&&&&&&&&&,,,   ,,,                                  
 //             ,,,   ,,,&&&&&&&&&&&&&&&&,,,   ,,,                                  
 //             ,,,   ,,,&&&&&&&&&&&&&&&&,,,   ,,,                                  
 //             ,,,   ,,,&&&&&&&&&&&&&&&&,,,   ,,,                                  
 //             &&&   ,,,&&&&&&&&&&&&&&&&,,,   &&&                                  
 //                   ,,,,,,&&&&&&&&&&,,,,,,                                        
 //                   ,,,   ..........   ,,,                                        
 //                   ,,,...          ...,,,                                        
 //                   ,,,...          ...,,,                                        
 //                   ......          ......                                        
 //                   &&&&&&          &&&&&&                                        
 //                                                      
// Features:
// MONKE ARMY SUPER GAS OPTIMIZATIONZ to maximize gas savings!
// Multi-claim minting to lower our users gas mintingz!
// Auto approved for listing on LooksRare & Rarible to reduce gas fees for our monke army!
// Open commercial right contract for our users stored on-chain, be free to exercise your creativity!

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Pausable.sol";

contract CoolMonkeTrainers is ERC721, ERC721URIStorage, Pausable, Ownable {
   using SafeMath for uint256;
   using ECDSA for bytes32;
   using Strings for uint16;

    //Our license is meant to be liberating in true sense to our mission, as such we do mean to open doors and promote fair use!
    //Full license including details purchase and art will be located on our website https://www.coolmonkes.io/license [as of 01/03/2022]
    //At the time of writing our art licensing entails: 
    //Cool Monke holders are given complete commercial & non-commericial rights to their specific Cool Monkes so long as it is in fair usage to the Cool Monkes brand 
    //The latest version of the license will supersede any previous licenses
    string public constant License = "MonkeLicense CC";
    address public constant enforcerAddress = 0xD8A7fd1887cf690119FFed888924056aF7f299CE;
    //Provenenace is not required as trainers are generated from base Cool Monkes 
    
    address public CMBAddress;
    address public StakeAddress;

    //Monkeworld Socio-economic Ecosystem
    uint256 public constant maxTrainers = 10000;
    
    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Claimed Monke tracker
    uint16[] public monkeTracker;

    //Reveal will be conducted on our API to prevent rarity sniping
    //Post reveal token metadata will be migrated from API and permanently frozen on IPFS
    string public baseTokenURI = "https://www.coolmonkes.io/api/metadata/trainer/";

    constructor() ERC721("Cool Monkes Trainers", "CTRNRS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function totalTokens() public view returns (uint256) {
        return _owners.length;
    }

    //Returns nounce for earner to enable transaction parity for security, next nounce has to be > than this value!
    function minterCurrentNounce(address minter) public view returns (uint256) {
        return nounceTracker[minter];
    }

    function getMessageHash(address _to, uint16[] memory _monkes, uint32 _burnAmount, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _monkes, _burnAmount, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint16[] memory _monkes, uint32 _burnAmount, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _monkes, _burnAmount, _nounce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function trainerClaimed(uint16 id) public view returns (bool) {
        for (uint i = 0; i < _owners.length; i++) {
            if (monkeTracker[i] == id) {
                return true;
            }
        }
        return false;
    }

    function claimTrainers(uint16[] memory monkes, uint32 burnAmount, uint nounce, bytes memory signature) public whenNotPaused  {
        address to = _msgSender();
        uint amount = monkes.length;
        uint totalMinted = _owners.length;
        require(amount > 0, "Invalid amount");
        require(totalMinted + amount <= maxTrainers, "Trainers are all claimed!");
        require(nounceTracker[to] < nounce, "Can not repeat a prior transaction!");
        require(verify(enforcerAddress, to, monkes, burnAmount, nounce, signature) == true, "Trainers must be minted from our website");
        
        nounceTracker[to] = nounce;
       
        for (uint i = 0; i < amount; i++) {
            monkeTracker.push(monkes[i]);
            _mint(to);
        }
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), monkeTracker[uint16(tokenId)].toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
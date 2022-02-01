// SPDX-License-Identifier: MIT 
// @author: @CoolMonkes - Boosts - CMBSTS                                                             
//               (/@@&#%&@@@@((((@@@@@@@,&@@@&%&@                           
//               &@@&(((((((((((((((((((((@@%(((#%&((((@@                          
//                @@((((((((((((((((@@@@@&(((#@@   @@((%@,                         
//              @@#(((((((((((((&@@,      /@@%((@@@@((@@,                          
//             @@((((((((((((%@@,            @@((#@@@@                             
//            @@(((((&@@@@@@/      @@##@*     @@(((*           /@@               
//           (@#((@@&             @@          @@(((@@@@&  [email protected]@@@@###@@@            
//       @@@@@@((@@     @@@@.                (@#(@@%((((&@@&@@@#######@@@         
//    @@%(((&@@((@@   /@        @   *@@@    &@##@&((((((%@@[email protected]@@@#######@@&      
//   @@((@@, #@#(&@.           %@@@@%/&(  #@@@@@@(((&@@([email protected]@@%#######@@@   
//   @@((#@@@@@@((#@@         @@@@@@@ [email protected]@@@@/....,/.........,@%....#@@@########@@*
//    %@@&#((%@@@((((@@@*        ,@@@@@/[email protected]@@/./@&@@@@[email protected]@@@#######%@
//               (@@((#@&@@@@@@@@@/[email protected]@[email protected]@@@@@#[email protected]@..%[email protected]@@######@
//                 @@@((((#@@*[email protected],.(@...&@,.....&@..............%@@@@@@@
//                @@((((%@@@@[email protected]@./@@@@@*[email protected]&...............#@@@@@@@####
//           *@@@@@(((&@@............%@@@/[email protected]@.,@&[email protected]%............*@@@@@..../@@##&@
//      (@@@@&......*.......,...,@,[email protected]@[email protected]@[email protected]@@/[email protected]@@@@*........&@@@   
// @@@@@@###@@&@[email protected]&@@[email protected]@[email protected](.&@..............&@@@@%[email protected]@@        
// @@##########@@@&[email protected]@&@@@@.&@#.,&#............./@@@@@........,@@@@            
// @@#@@@&########@@@&....&@%[email protected]@@@@@,[email protected]@@@@@                
//   ###%@@@%########@@@#[email protected]@............&@@@@#........#@@@*                     
//   ######&@@@&#######%@@@/..........(@&@@&........,@@@@                          
//   #########%@@@&#######&@@@...,@@@@@[email protected]@@@/                              
//      ##########@@@@#######@@@@@#........%@@@                                    
//         ##########@@@##@@@@#@@[email protected]@@                                         
//            ########@@#######@@.&@@/                                             
//               ####&@@#####&@@                                                   
//                 &@@@@@@@@                                                       
                                 
// Features:
// MONKE ARMY SUPER GAS OPTIMIZATIONZ to maximize gas savings!
// Secure permit list minting to allow our users gas war free presale mintingz!
// Auto approved for listing on LooksRare & Rarible to reduce gas fees for our monke army!
// Open commercial right contract for our users stored on-chain, be free to exercise your creativity!
// Auto approved to staking wallet to save gas
// Can mint & stake to save additional gas

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Pausable.sol";

interface ICoolMonkeBanana {
    function burnWithTax(address from, uint256 amount) external;
}

interface IMonkestake {
    function stake(address account, uint16[] calldata monkeTokenIds,  uint16[] calldata boostTokenIds, uint amount, uint nounce, bytes memory signature) external;
}

contract BoostPasses is ERC721, ERC721URIStorage, Pausable, Ownable {
   using SafeMath for uint256;
   using ECDSA for bytes32;

    //Our license is meant to be liberating in true sense to our mission, as such we do mean to open doors and promote fair use!
    //Full license including details purchase and art will be located on our website https://www.coolmonkes.io/license [as of 01/01/2022]
    //At the time of writing our art licensing entails: 
    //Cool Monke holders are given complete commercial & non-commericial rights to their specific Cool Monkes so long as it is in fair usage to the Cool Monkes brand 
    //The latest version of the license will supersede any previous licenses
    string public constant License = "MonkeLicense CC";
    bytes public constant Provenance = "0x098d535091e9aa309e834fa6865bd00b2eef26dcd19184e6598a07bf99f1a91a";
    address public constant enforcerAddress = 0xD8A7fd1887cf690119FFed888924056aF7f299CE;
    
    address public CMBAddress;
    address public StakeAddress;

    //Monkeworld Socio-economic Ecosystem
    uint256 public constant maxBoosts = 10000;
    
    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Reveal will be conducted on our API to prevent rarity sniping
    //Post reveal token metadata will be migrated from API and permanently frozen on IPFS
    string public baseTokenURI = "https://www.coolmonkes.io/api/metadata/boost/";

    constructor() ERC721("Cool Monkes Boosts", "CMBSTS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setStakeAddress(address contractAddress) public onlyOwner {
        StakeAddress = contractAddress;
        ERC721.StakeAddressApproval = contractAddress;
    }

    function setCMBAddress(address contractAddress) public onlyOwner {
        CMBAddress = contractAddress;
    }

    function totalTokens() public view returns (uint256) {
        return _owners.length;
    }

    function multiMint(uint amount, address to) private {
        require(amount > 0, "Invalid amount");
        require(_checkOnERC721Received(address(0), to, _mint(to), ''), "ERC721: transfer to non ERC721Receiver implementer"); //Safe mint 1st and regular mint rest to save gas! 
        for (uint i = 1; i < amount; i++) {
            _mint(to);
        }
    }

    //Returns nounce for earner to enable transaction parity for security, next nounce has to be > than this value!
    function minterCurrentNounce(address minter) public view returns (uint256) {
        return nounceTracker[minter];
    }

    function getMessageHash(address _to, uint _amount, uint _price, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _price, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _price, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _price, _nounce);
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

    function mint(uint amount, uint price, uint nounce, bytes memory signature, bool stake) public whenNotPaused  {
        require(_owners.length + amount <= maxBoosts, "Boosts are sold out!");
        require(nounceTracker[_msgSender()] < nounce, "Can not repeat a prior transaction!");
        require(verify(enforcerAddress, _msgSender(), amount, price, nounce, signature) == true, "Boosts must be minted from our website");
        
        //Will fail if proper amount isn't burnt!
        if (price > 0) {
            ICoolMonkeBanana(CMBAddress).burnWithTax(_msgSender(), price);  
        }

        nounceTracker[_msgSender()] = nounce;
       
        //Stake in same txn to save gas!
        if (stake) {
            multiMint(amount, StakeAddress);
            uint16[] memory monkes;
            uint16[] memory boosts =  new uint16[](amount);
            
            for (uint i = 0; i < amount; i++) {
                boosts[uint16(i)] = uint16(_owners.length - amount + i);
            }

            IMonkestake(StakeAddress).stake(_msgSender(), monkes, boosts, 0, 0, '');
        } else {
            multiMint(amount, _msgSender());
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
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
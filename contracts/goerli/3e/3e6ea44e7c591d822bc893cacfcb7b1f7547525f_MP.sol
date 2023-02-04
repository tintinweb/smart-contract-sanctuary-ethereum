// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MisterPickleNFTees
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    pragma solidity ^0.8.14;                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    import "@openzeppelin/contracts/utils/Counters.sol";                                                                                                                                                                                                                                                                                                                                     //
//    import "@openzeppelin/contracts/utils/Strings.sol";                                                                                                                                                                                                                                                                                                                                      //
//    import "@openzeppelin/contracts/utils/Context.sol";                                                                                                                                                                                                                                                                                                                                      //
//    import "@openzeppelin/contracts/access/Ownable.sol";                                                                                                                                                                                                                                                                                                                                     //
//    import "@openzeppelin/contracts/utils/Address.sol";                                                                                                                                                                                                                                                                                                                                      //
//    import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";                                                                                                                                                                                                                                                                                                                       //
//    import "@openzeppelin/contracts/utils/introspection/IERC165.sol";                                                                                                                                                                                                                                                                                                                        //
//    import "@openzeppelin/contracts/utils/introspection/ERC165.sol";                                                                                                                                                                                                                                                                                                                         //
//    import "@openzeppelin/contracts/token/ERC721/IERC721.sol";                                                                                                                                                                                                                                                                                                                               //
//    import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";                                                                                                                                                                                                                                                                                                            //
//    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    contract MisterPickle is ERC721, Ownable {                                                                                                                                                                                                                                                                                                                                               //
//    Counters.Counter private supply;                                                                                                                                                                                                                                                                                                                                                         //
//    address[] public whitelist;                                                                                                                                                                                                                                                                                                                                                              //
//    using Strings for uint256;                                                                                                                                                                                                                                                                                                                                                               //
//    using Counters for Counters.Counter;                                                                                                                                                                                                                                                                                                                                                     //
//    bool public publicMintOpen = false;                                                                                                                                                                                                                                                                                                                                                      //
//    bool public whitelistMintOpen = false;                                                                                                                                                                                                                                                                                                                                                   //
//    mapping(address => uint256) public mintCount;                                                                                                                                                                                                                                                                                                                                            //
//    string public uriPrefix = "https://lime-adjacent-clam-606.mypinata.cloud/ipfs/QmPbZd6e6swv9NnSwmagJjBVJCwqp8K9yM7SfTLmbkh1tv//";                                                                                                                                                                                                                                                         //
//    string public hiddenMetadataUri;                                                                                                                                                                                                                                                                                                                                                         //
//    string public uriSuffix = ".json";                                                                                                                                                                                                                                                                                                                                                       //
//    uint256 public WLmintCost = 0.00 ether;                                                                                                                                                                                                                                                                                                                                                  //
//    uint256 public mintCost = 0.00 ether;                                                                                                                                                                                                                                                                                                                                                    //
//    uint256 public maxSupply = 69;                                                                                                                                                                                                                                                                                                                                                           //
//    uint256 public maxMintAmountPerTx = 2;                                                                                                                                                                                                                                                                                                                                                   //
//    uint256 public maxMintAmountPerWlTx = 5;                                                                                                                                                                                                                                                                                                                                                 //
//    uint256 public maxNFTPerWallet = 2;                                                                                                                                                                                                                                                                                                                                                      //
//    uint256 public maxNFTPerWlWallet = 5;                                                                                                                                                                                                                                                                                                                                                    //
//    uint256 mintLimit = 69;                                                                                                                                                                                                                                                                                                                                                                  //
//    uint256 WlmintLimit = 69;                                                                                                                                                                                                                                                                                                                                                                //
//    uint256 private nextTokenId = 1;                                                                                                                                                                                                                                                                                                                                                         //
//    uint256 private totalMinted = 0;                                                                                                                                                                                                                                                                                                                                                         //
//    bool public revealed = false;                                                                                                                                                                                                                                                                                                                                                            //
//    address[] addressesToAdd = [0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,0x617F2E2fD72FD9D5503197092aC168c91465E7f2,0x17F6AD8Ef982297579C203069C1DbfFE4348c372];    //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    constructor() ERC721("MisterPickle", "MP") {                                                                                                                                                                                                                                                                                                                                             //
//    setHiddenMetadataUri("https://lime-adjacent-clam-606.mypinata.cloud/ipfs/QmZyUos2tycPDhdnYeFvfRYAjXo6K9cTBCa9pGi5JyJquq/Hidden.json");                                                                                                                                                                                                                                                   //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction qui ouvre et ferme la vente WL                                                                                                                                                                                                                                                                                                                                                //
//    function openWhitelistMint() public onlyOwner {whitelistMintOpen = true;}                                                                                                                                                                                                                                                                                                                //
//    function closeWhitelistMint() public onlyOwner {whitelistMintOpen = false;}                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction qui permet d'ajouter des gens a la WL                                                                                                                                                                                                                                                                                                                                         //
//    function addToWhitelist(address[] memory addresses) public onlyOwner{                                                                                                                                                                                                                                                                                                                    //
//    for (uint256 i = 0; i < addresses.length; i++) {whitelist.push(addresses[i]);}}                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction qui permet de voir si un porte feuille est sur la wl                                                                                                                                                                                                                                                                                                                          //
//    function isWhitelisted(address _address) public view returns (bool) {                                                                                                                                                                                                                                                                                                                    //
//        for (uint256 i = 0; i < whitelist.length; i++) {                                                                                                                                                                                                                                                                                                                                     //
//        if (whitelist[i] == _address) {return true;}                                                                                                                                                                                                                                                                                                                                         //
//        }return false;}                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Besoins pour pouvoir minter WL                                                                                                                                                                                                                                                                                                                                                         //
//    modifier WLmintRequire(uint256 _mintAmount) {                                                                                                                                                                                                                                                                                                                                            //
//        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerWlTx, "Max 5");                                                                                                                                                                                                                                                                                                            //
//        require(supply.current() + _mintAmount <= maxSupply, "SOLD OUT!");                                                                                                                                                                                                                                                                                                                   //
//        require(isWhitelisted(msg.sender), "You are NOT in the VIP list");                                                                                                                                                                                                                                                                                                                   //
//        require(whitelistMintOpen, "WL mint NOT open, please retry LATER");_;}                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction pour le mint des WL                                                                                                                                                                                                                                                                                                                                                           //
//    function WLmint(uint256 _mintAmount) public payable WLmintRequire(_mintAmount) {                                                                                                                                                                                                                                                                                                         //
//        require(msg.value >= WLmintCost * _mintAmount, "NOT FUND");                                                                                                                                                                                                                                                                                                                          //
//        require(mintCount[msg.sender] + _mintAmount <= WlmintLimit,"WL SOLD OUT");                                                                                                                                                                                                                                                                                                           //
//        require(mintCount[msg.sender] + _mintAmount <= maxNFTPerWlWallet,"Limit max per wallet");                                                                                                                                                                                                                                                                                            //
//        for (uint256 i = 0; i < _mintAmount; i++) {                                                                                                                                                                                                                                                                                                                                          //
//        _mint(msg.sender, nextTokenId);                                                                                                                                                                                                                                                                                                                                                      //
//        mintCount[msg.sender]++;                                                                                                                                                                                                                                                                                                                                                             //
//        nextTokenId++;                                                                                                                                                                                                                                                                                                                                                                       //
//        totalMinted++;                                                                                                                                                                                                                                                                                                                                                                       //
//        }                                                                                                                                                                                                                                                                                                                                                                                    //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Modifier l'ouverture de la vente publique                                                                                                                                                                                                                                                                                                                                              //
//    function editMintWindows(bool _publicMintOpen) external onlyOwner {publicMintOpen = _publicMintOpen;}                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Besoins pour pouvoir minter publiquement                                                                                                                                                                                                                                                                                                                                               //
//    modifier mintRequire(uint256 _mintAmount) {                                                                                                                                                                                                                                                                                                                                              //
//        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "NO INFINITY MINT!");                                                                                                                                                                                                                                                                                                  //
//        require(supply.current() + _mintAmount <= maxSupply, "SOLD OUT!");_;}                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//         //Fonction pour le mint public                                                                                                                                                                                                                                                                                                                                                      //
//    function mint(uint256 _mintAmount) public payable mintRequire(_mintAmount) {                                                                                                                                                                                                                                                                                                             //
//        require(publicMintOpen, "Public Mint Closed");                                                                                                                                                                                                                                                                                                                                       //
//        require(msg.value >= mintCost * _mintAmount, "NOT FUND");                                                                                                                                                                                                                                                                                                                            //
//        require(mintCount[msg.sender] + _mintAmount <= mintLimit,"MAX limit exceeded");                                                                                                                                                                                                                                                                                                      //
//        require(mintCount[msg.sender] + _mintAmount <= maxNFTPerWallet,"Limit max per wallet");                                                                                                                                                                                                                                                                                              //
//        for (uint256 i = 0; i < _mintAmount; i++) {                                                                                                                                                                                                                                                                                                                                          //
//        _mint(msg.sender, nextTokenId);                                                                                                                                                                                                                                                                                                                                                      //
//        mintCount[msg.sender]++;                                                                                                                                                                                                                                                                                                                                                             //
//        nextTokenId++;                                                                                                                                                                                                                                                                                                                                                                       //
//        totalMinted++;                                                                                                                                                                                                                                                                                                                                                                       //
//        }                                                                                                                                                                                                                                                                                                                                                                                    //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction pour savoir combien de nft sont déja minté                                                                                                                                                                                                                                                                                                                                    //
//    function totalSupply() public view returns (uint256) {                                                                                                                                                                                                                                                                                                                                   //
//        return totalMinted;                                                                                                                                                                                                                                                                                                                                                                  //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    function getmintCount() public view returns (uint256) {                                                                                                                                                                                                                                                                                                                                  //
//        return mintCount[msg.sender];                                                                                                                                                                                                                                                                                                                                                        //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction pour savoir qui détient quoi                                                                                                                                                                                                                                                                                                                                                  //
//    function walletOfOwner(                                                                                                                                                                                                                                                                                                                                                                  //
//        address _owner) public view returns (uint256[] memory) {                                                                                                                                                                                                                                                                                                                             //
//        uint256 ownerTokenCount = balanceOf(_owner);                                                                                                                                                                                                                                                                                                                                         //
//        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);                                                                                                                                                                                                                                                                                                                     //
//        uint256 currentTokenId = 1;                                                                                                                                                                                                                                                                                                                                                          //
//        uint256 ownedTokenIndex = 0;                                                                                                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {                                                                                                                                                                                                                                                                                                           //
//        address currentTokenOwner = ownerOf(currentTokenId);                                                                                                                                                                                                                                                                                                                                 //
//        if (currentTokenOwner == _owner) {                                                                                                                                                                                                                                                                                                                                                   //
//        ownedTokenIds[ownedTokenIndex] = currentTokenId;ownedTokenIndex++;}                                                                                                                                                                                                                                                                                                                  //
//        currentTokenId++;}                                                                                                                                                                                                                                                                                                                                                                   //
//        return ownedTokenIds;                                                                                                                                                                                                                                                                                                                                                                //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction pour savoir si le Token ID correspond a l'Uri                                                                                                                                                                                                                                                                                                                                 //
//    function tokenURI(uint256 _tokenId) public view virtual override returns (                                                                                                                                                                                                                                                                                                               //
//        string memory){                                                                                                                                                                                                                                                                                                                                                                      //
//        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");if (revealed == false) {                                                                                                                                                                                                                                                                                //
//        return hiddenMetadataUri;                                                                                                                                                                                                                                                                                                                                                            //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Cette fonction retourne une chaîne de caractères qui est la concaténation de la valeur de "currentBaseURI",du "tokenId" converti en chaîne de caractères et de "uriSuffix".                                                                                                                                                                                                            //
//    string memory currentBaseURI = _baseURI();                                                                                                                                                                                                                                                                                                                                               //
//        return bytes(currentBaseURI).length > 0?                                                                                                                                                                                                                                                                                                                                             //
//        string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): "";                                                                                                                                                                                                                                                                                                        //
//      }                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Cette fonction permet au propriétaire du contrat de définir l'état "révélé" de la métadonnée cachée.                                                                                                                                                                                                                                                                                   //
//    function setRevealed(bool _state) public onlyOwner {                                                                                                                                                                                                                                                                                                                                     //
//        revealed = _state;                                                                                                                                                                                                                                                                                                                                                                   //
//      }                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Cette fonction permet à l'unique propriétaire du contrat de définir l'URI de métadonnées cachées.                                                                                                                                                                                                                                                                                      //
//    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {                                                                                                                                                                                                                                                                                                       //
//        hiddenMetadataUri = _hiddenMetadataUri;                                                                                                                                                                                                                                                                                                                                              //
//      }                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    //Fonction qui permet au proprietaire du contrat de retirer les fonds                                                                                                                                                                                                                                                                                                                    //
//    function withdraw(address _addr) external onlyOwner {                                                                                                                                                                                                                                                                                                                                    //
//        uint256 balance = address(this).balance;                                                                                                                                                                                                                                                                                                                                             //
//        payable(_addr).transfer(balance);                                                                                                                                                                                                                                                                                                                                                    //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    function _mintLoop(address _receiver, uint256 _mintAmount) internal {                                                                                                                                                                                                                                                                                                                    //
//        for (uint256 i = 0; i < _mintAmount; i++) {                                                                                                                                                                                                                                                                                                                                          //
//        _safeMint(_receiver, supply.current());                                                                                                                                                                                                                                                                                                                                              //
//        supply.increment();                                                                                                                                                                                                                                                                                                                                                                  //
//        }                                                                                                                                                                                                                                                                                                                                                                                    //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//    function _baseURI() internal view virtual override returns (string memory) {                                                                                                                                                                                                                                                                                                             //
//        return uriPrefix;                                                                                                                                                                                                                                                                                                                                                                    //
//        }                                                                                                                                                                                                                                                                                                                                                                                    //
//    }                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("MisterPickleNFTees", "MP") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}
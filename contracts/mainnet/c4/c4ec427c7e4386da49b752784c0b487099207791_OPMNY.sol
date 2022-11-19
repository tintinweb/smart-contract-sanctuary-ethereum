// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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

pragma solidity ^0.8.0;

/// @title: New Nft Opensea
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//    pragma solidity ^0.8.0;                                                                                        //
//                                                                                                                   //
//    /// @author: manifold.xyz                                                                                      //
//                                                                                                                   //
//    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";                                                      //
//                                                                                                                   //
//    import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";                                    //
//    import "./core/ERC721CreatorCore.sol";                                                                         //
//                                                                                                                   //
//    /**                                                                                                            //
//     * @dev ERC721Creator implementation                                                                           //
//     */                                                                                                            //
//    contract ERC721Creator is AdminControl, ERC721, ERC721CreatorCore {                                            //
//        constructor(string memory _name, string memory _symbol)                                                    //
//            ERC721(_name, _symbol)                                                                                 //
//        {}                                                                                                         //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC165-supportsInterface}.                                                                   //
//         */                                                                                                        //
//        function supportsInterface(bytes4 interfaceId)                                                             //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override(ERC721, ERC721CreatorCore, AdminControl)                                                      //
//            returns (bool)                                                                                         //
//        {                                                                                                          //
//            return                                                                                                 //
//                ERC721CreatorCore.supportsInterface(interfaceId) ||                                                //
//                ERC721.supportsInterface(interfaceId) ||                                                           //
//                AdminControl.supportsInterface(interfaceId);                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        function _beforeTokenTransfer(                                                                             //
//            address from,                                                                                          //
//            address to,                                                                                            //
//            uint256 tokenId                                                                                        //
//        ) internal virtual override {                                                                              //
//            _approveTransfer(from, to, tokenId);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-registerExtension}.                                                              //
//         */                                                                                                        //
//        function registerExtension(address extension, string calldata baseURI)                                     //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//            nonBlacklistRequired(extension)                                                                        //
//        {                                                                                                          //
//            _registerExtension(extension, baseURI, false);                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-registerExtension}.                                                              //
//         */                                                                                                        //
//        function registerExtension(                                                                                //
//            address extension,                                                                                     //
//            string calldata baseURI,                                                                               //
//            bool baseURIIdentical                                                                                  //
//        ) external override adminRequired nonBlacklistRequired(extension) {                                        //
//            _registerExtension(extension, baseURI, baseURIIdentical);                                              //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-unregisterExtension}.                                                            //
//         */                                                                                                        //
//        function unregisterExtension(address extension)                                                            //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _unregisterExtension(extension);                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-blacklistExtension}.                                                             //
//         */                                                                                                        //
//        function blacklistExtension(address extension)                                                             //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _blacklistExtension(extension);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                       //
//         */                                                                                                        //
//        function setBaseTokenURIExtension(string calldata uri)                                                     //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setBaseTokenURIExtension(uri, false);                                                                 //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                       //
//         */                                                                                                        //
//        function setBaseTokenURIExtension(string calldata uri, bool identical)                                     //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setBaseTokenURIExtension(uri, identical);                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIPrefixExtension}.                                                     //
//         */                                                                                                        //
//        function setTokenURIPrefixExtension(string calldata prefix)                                                //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setTokenURIPrefixExtension(prefix);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                           //
//         */                                                                                                        //
//        function setTokenURIExtension(uint256 tokenId, string calldata uri)                                        //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setTokenURIExtension(tokenId, uri);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                           //
//         */                                                                                                        //
//        function setTokenURIExtension(                                                                             //
//            uint256[] memory tokenIds,                                                                             //
//            string[] calldata uris                                                                                 //
//        ) external override extensionRequired {                                                                    //
//            require(tokenIds.length == uris.length, "Invalid input");                                              //
//            for (uint256 i = 0; i < tokenIds.length; i++) {                                                        //
//                _setTokenURIExtension(tokenIds[i], uris[i]);                                                       //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURI}.                                                                //
//         */                                                                                                        //
//        function setBaseTokenURI(string calldata uri)                                                              //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setBaseTokenURI(uri);                                                                                 //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIPrefix}.                                                              //
//         */                                                                                                        //
//        function setTokenURIPrefix(string calldata prefix)                                                         //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setTokenURIPrefix(prefix);                                                                            //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                    //
//         */                                                                                                        //
//        function setTokenURI(uint256 tokenId, string calldata uri)                                                 //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setTokenURI(tokenId, uri);                                                                            //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                    //
//         */                                                                                                        //
//        function setTokenURI(uint256[] memory tokenIds, string[] calldata uris)                                    //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            require(tokenIds.length == uris.length, "Invalid input");                                              //
//            for (uint256 i = 0; i < tokenIds.length; i++) {                                                        //
//                _setTokenURI(tokenIds[i], uris[i]);                                                                //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setMintPermissions}.                                                             //
//         */                                                                                                        //
//        function setMintPermissions(address extension, address permissions)                                        //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setMintPermissions(extension, permissions);                                                           //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBase}.                                                                 //
//         */                                                                                                        //
//        function mintBase(address to)                                                                              //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintBase(to, "");                                                                              //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBase}.                                                                 //
//         */                                                                                                        //
//        function mintBase(address to, string calldata uri)                                                         //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintBase(to, uri);                                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBaseBatch}.                                                            //
//         */                                                                                                        //
//        function mintBaseBatch(address to, uint16 count)                                                           //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](count);                                                                       //
//            for (uint16 i = 0; i < count; i++) {                                                                   //
//                tokenIds[i] = _mintBase(to, "");                                                                   //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBaseBatch}.                                                            //
//         */                                                                                                        //
//        function mintBaseBatch(address to, string[] calldata uris)                                                 //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](uris.length);                                                                 //
//            for (uint256 i = 0; i < uris.length; i++) {                                                            //
//                tokenIds[i] = _mintBase(to, uris[i]);                                                              //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev Mint token with no extension                                                                       //
//         */                                                                                                        //
//        function _mintBase(address to, string memory uri)                                                          //
//            internal                                                                                               //
//            virtual                                                                                                //
//            returns (uint256 tokenId)                                                                              //
//        {                                                                                                          //
//            _tokenCount++;                                                                                         //
//            tokenId = _tokenCount;                                                                                 //
//                                                                                                                   //
//            // Track the extension that minted the token                                                           //
//            _tokensExtension[tokenId] = address(this);                                                             //
//                                                                                                                   //
//            _safeMint(to, tokenId);                                                                                //
//                                                                                                                   //
//            if (bytes(uri).length > 0) {                                                                           //
//                _tokenURIs[tokenId] = uri;                                                                         //
//            }                                                                                                      //
//                                                                                                                   //
//            // Call post mint                                                                                      //
//            _postMintBase(to, tokenId);                                                                            //
//            return tokenId;                                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtension}.                                                            //
//         */                                                                                                        //
//        function mintExtension(address to)                                                                         //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintExtension(to, "");                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtension}.                                                            //
//         */                                                                                                        //
//        function mintExtension(address to, string calldata uri)                                                    //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintExtension(to, uri);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtensionBatch}.                                                       //
//         */                                                                                                        //
//        function mintExtensionBatch(address to, uint16 count)                                                      //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](count);                                                                       //
//            for (uint16 i = 0; i < count; i++) {                                                                   //
//                tokenIds[i] = _mintExtension(to, "");                                                              //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtensionBatch}.                                                       //
//         */                                                                                                        //
//        function mintExtensionBatch(address to, string[] calldata uris)                                            //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](uris.length);                                                                 //
//            for (uint256 i = 0; i < uris.length; i++) {                                                            //
//                tokenIds[i] = _mintExtension(to, uris[i]);                                                         //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev Mint token via extension                                                                           //
//         */                                                                                                        //
//        function _mintExtension(address to, string memory uri)                                                     //
//            internal                                                                                               //
//            virtual                                                                                                //
//            returns (uint256 tokenId)                                                                              //
//        {                                                                                                          //
//            _tokenCount++;                                                                                         //
//            tokenId = _tokenCount;                                                                                 //
//                                                                                                                   //
//            _checkMintPermissions(to, tokenId);                                                                    //
//                                                                                                                   //
//            // Track the extension that minted the token                                                           //
//            _tokensExtension[tokenId] = msg.sender;                                                                //
//                                                                                                                   //
//            _safeMint(to, tokenId);                                                                                //
//                                                                                                                   //
//            if (bytes(uri).length > 0) {                                                                           //
//                _tokenURIs[tokenId] = uri;                                                                         //
//            }                                                                                                      //
//                                                                                                                   //
//            // Call post mint                                                                                      //
//            _postMintExtension(to, tokenId);                                                                       //
//            return tokenId;                                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-tokenExtension}.                                                           //
//         */                                                                                                        //
//        function tokenExtension(uint256 tokenId)                                                                   //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address)                                                                                      //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _tokenExtension(tokenId);                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-burn}.                                                                     //
//         */                                                                                                        //
//        function burn(uint256 tokenId) public virtual override nonReentrant {                                      //
//            require(                                                                                               //
//                _isApprovedOrOwner(msg.sender, tokenId),                                                           //
//                "Caller is not owner nor approved"                                                                 //
//            );                                                                                                     //
//            address owner = ownerOf(tokenId);                                                                      //
//            _burn(tokenId);                                                                                        //
//            _postBurn(owner, tokenId);                                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                   //
//         */                                                                                                        //
//        function setRoyalties(                                                                                     //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            _setRoyaltiesExtension(address(this), receivers, basisPoints);                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                   //
//         */                                                                                                        //
//        function setRoyalties(                                                                                     //
//            uint256 tokenId,                                                                                       //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            _setRoyalties(tokenId, receivers, basisPoints);                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyaltiesExtension}.                                                          //
//         */                                                                                                        //
//        function setRoyaltiesExtension(                                                                            //
//            address extension,                                                                                     //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            _setRoyaltiesExtension(extension, receivers, basisPoints);                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getRoyalties}.                                                                   //
//         */                                                                                                        //
//        function getRoyalties(uint256 tokenId)                                                                     //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory, uint256[] memory)                                                   //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyalties(tokenId);                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFees}.                                                                        //
//         */                                                                                                        //
//        function getFees(uint256 tokenId)                                                                          //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory, uint256[] memory)                                                   //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyalties(tokenId);                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFeeRecipients}.                                                               //
//         */                                                                                                        //
//        function getFeeRecipients(uint256 tokenId)                                                                 //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory)                                                                     //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyReceivers(tokenId);                                                                  //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFeeBps}.                                                                      //
//         */                                                                                                        //
//        function getFeeBps(uint256 tokenId)                                                                        //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (uint256[] memory)                                                                             //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyBPS(tokenId);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-royaltyInfo}.                                                                    //
//         */                                                                                                        //
//        function royaltyInfo(uint256 tokenId, uint256 value)                                                       //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address, uint256)                                                                             //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyInfo(tokenId, value);                                                                //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721Metadata-tokenURI}.                                                                    //
//         */                                                                                                        //
//        function tokenURI(uint256 tokenId)                                                                         //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (string memory)                                                                                //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _tokenURI(tokenId);                                                                             //
//        }                                                                                                          //
//    }                                                                                                              //
//    # Palkeoramix decompiler.                                                                                      //
//                                                                                                                   //
//    const unknown4060b25e = '2.0.0'                                                                                //
//    const unknownc311c523 = 1                                                                                      //
//                                                                                                                   //
//    def storage:                                                                                                   //
//      stor0 is mapping of uint256 at storage 0                                                                     //
//      stor1 is mapping of uint8 at storage 1                                                                       //
//      owner is addr at storage 2                                                                                   //
//      unknowncd7c0326Address is addr at storage 3                                                                  //
//      name is array of uint256 at storage 4                                                                        //
//      symbol is array of uint256 at storage 5                                                                      //
//      totalSupply is mapping of uint256 at storage 6                                                               //
//      unknownf923e8c3 is array of uint256 at storage 7                                                             //
//      uri is array of uint256 at storage 8                                                                         //
//      stor9 is uint8 at storage 9                                                                                  //
//      stor10 is mapping of uint8 at storage 10                                                                     //
//      creator is mapping of addr at storage 11                                                                     //
//                                                                                                                   //
//    def name() payable:                                                                                            //
//      return name[0 len name.length]                                                                               //
//                                                                                                                   //
//    def uri(uint256 _id) payable:                                                                                  //
//      return uri[_id][0 len uri[_id].length]                                                                       //
//                                                                                                                   //
//    def creator(uint256 _tokenId) payable:                                                                         //
//      require calldata.size - 4 >= 32                                                                              //
//      return creator[_tokenId]                                                                                     //
//                                                                                                                   //
//    def unknown73505d35(addr _param1) payable:                                                                     //
//      require calldata.size - 4 >= 32                                                                              //
//      return bool(stor10[_param1])                                                                                 //
//                                                                                                                   //
//    def owner() payable:                                                                                           //
//      return owner                                                                                                 //
//                                                                                                                   //
//    def symbol() payable:                                                                                          //
//      return symbol[0 len symbol.length]                                                                           //
//                                                                                                                   //
//    def totalSupply(uint256 _id) payable:                                                                          //
//      require calldata.size - 4 >= 32                                                                              //
//      return totalSupply[_id]                                                                                      //
//                                                                                                                   //
//    def unknowncd7c0326() payable:                                                                                 //
//      return unknowncd7c0326Address                                                                                //
//                                                                                                                   //
//    def unknownf923e8c3() payable:                                                                                 //
//      return unknownf923e8c3[0 len unknownf923e8c3.length]                                                         //
//                                                                                                                   //
//    #                                                                                                              //
//    #  Regular functions                                                                                           //
//    #                                                                                                              //
//                                                                                                                   //
//    def _fallback() payable: # default function                                                                    //
//      revert                                                                                                       //
//                                                                                                                   //
//    def isOwner() payable:                                                                                         //
//      return (caller == owner)                                                                                     //
//                                                                                                                   //
//    def exists(uint256 _tokenId) payable:                                                                          //
//      require calldata.size - 4 >= 32                                                                              //
//      return (totalSupply[_tokenId] > 0)                                                                           //
//                                                                                                                   //
//    def supportsInterface(bytes4 _interfaceId) payable:                                                            //
//      require calldata.size - 4 >= 32                                                                              //
//      if Mask(32, 224, _interfaceId) != 0x1ffc9a700000000000000000000000000000000000000000000000000000000:         //
//          if Mask(32, 224, _interfaceId) != 0xd9b67a2600000000000000000000000000000000000000000000000000000000:    //
//              return 0                                                                                             //
//      return 1                                                                                                     //
//                                                                                                                   //
//    def setApprovalForAll(address _to, bool _approved) payable:                                                    //
//      require calldata.size - 4 >= 64                                                                              //
//      stor1[caller][addr(_to)] = uint8(_approved)                                                                  //
//      log ApprovalForAll(                                                                                          //
//            address owner=_approved,                                                                               //
//            address operator=caller,                                                                               //
//            bool approved=_to)                                                                                     //
//                                                                                                                   //
//    def isApprovedForAll(address _owner, address _operator) payable:                                               //
//      require calldata.size - 4 >= 64                                                                              //
//      if not stor10[addr(_operator)]:                                                                              //
//          require ext_code.size(unknowncd7c0326Address)                                                            //
//          static call unknowncd7c0326Address.proxies(address param1) with:                                         //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OPMNY is ERC721Creator {
    constructor() ERC721Creator("New Nft Opensea", "OPMNY") {}
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
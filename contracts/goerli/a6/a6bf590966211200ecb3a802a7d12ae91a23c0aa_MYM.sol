// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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

/// @title: MYN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                            //
//                                                                                                                                                                                                            //
//                                                                                                                                                                                                            //
//    pragma solidity ^0.8.0;                                                                                                                                                                                 //
//                                                                                                                                                                                                            //
//    /// @author: manifold.xyz                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//    import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";                                                                                                                                             //
//    import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";                                                                                                                             //
//                                                                                                                                                                                                            //
//    import "./core/ERC1155CreatorCore.sol";                                                                                                                                                                 //
//                                                                                                                                                                                                            //
//    /**                                                                                                                                                                                                     //
//     * @dev ERC1155Creator implementation                                                                                                                                                                   //
//     */                                                                                                                                                                                                     //
//    contract ERC1155Creator is AdminControl, ERC1155, ERC1155CreatorCore {                                                                                                                                  //
//                                                                                                                                                                                                            //
//        mapping(uint256 => uint256) private _totalSupply;                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        constructor () ERC1155("") {}                                                                                                                                                                       //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC165-supportsInterface}.                                                                                                                                                            //
//         */                                                                                                                                                                                                 //
//        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CreatorCore, AdminControl) returns (bool) {                                                             //
//            return ERC1155CreatorCore.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);                                              //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) internal virtual override {                                          //
//            _approveTransfer(from, to, ids, amounts);                                                                                                                                                       //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-registerExtension}.                                                                                                                                                       //
//         */                                                                                                                                                                                                 //
//        function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {                                                            //
//            _registerExtension(extension, baseURI, false);                                                                                                                                                  //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-registerExtension}.                                                                                                                                                       //
//         */                                                                                                                                                                                                 //
//        function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {                                     //
//            _registerExtension(extension, baseURI, baseURIIdentical);                                                                                                                                       //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-unregisterExtension}.                                                                                                                                                     //
//         */                                                                                                                                                                                                 //
//        function unregisterExtension(address extension) external override adminRequired {                                                                                                                   //
//            _unregisterExtension(extension);                                                                                                                                                                //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-blacklistExtension}.                                                                                                                                                      //
//         */                                                                                                                                                                                                 //
//        function blacklistExtension(address extension) external override adminRequired {                                                                                                                    //
//            _blacklistExtension(extension);                                                                                                                                                                 //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                                                                                                                //
//         */                                                                                                                                                                                                 //
//        function setBaseTokenURIExtension(string calldata uri_) external override extensionRequired {                                                                                                       //
//            _setBaseTokenURIExtension(uri_, false);                                                                                                                                                         //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                                                                                                                //
//         */                                                                                                                                                                                                 //
//        function setBaseTokenURIExtension(string calldata uri_, bool identical) external override extensionRequired {                                                                                       //
//            _setBaseTokenURIExtension(uri_, identical);                                                                                                                                                     //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURIPrefixExtension}.                                                                                                                                              //
//         */                                                                                                                                                                                                 //
//        function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {                                                                                                   //
//            _setTokenURIPrefixExtension(prefix);                                                                                                                                                            //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                                                                                                                    //
//         */                                                                                                                                                                                                 //
//        function setTokenURIExtension(uint256 tokenId, string calldata uri_) external override extensionRequired {                                                                                          //
//            _setTokenURIExtension(tokenId, uri_);                                                                                                                                                           //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                                                                                                                    //
//         */                                                                                                                                                                                                 //
//        function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override extensionRequired {                                                                              //
//            require(tokenIds.length == uris.length, "Invalid input");                                                                                                                                       //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                _setTokenURIExtension(tokenIds[i], uris[i]);                                                                                                                                                //
//            }                                                                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setBaseTokenURI}.                                                                                                                                                         //
//         */                                                                                                                                                                                                 //
//        function setBaseTokenURI(string calldata uri_) external override adminRequired {                                                                                                                    //
//            _setBaseTokenURI(uri_);                                                                                                                                                                         //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURIPrefix}.                                                                                                                                                       //
//         */                                                                                                                                                                                                 //
//        function setTokenURIPrefix(string calldata prefix) external override adminRequired {                                                                                                                //
//            _setTokenURIPrefix(prefix);                                                                                                                                                                     //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                                                                                                             //
//         */                                                                                                                                                                                                 //
//        function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {                                                                                                       //
//            _setTokenURI(tokenId, uri_);                                                                                                                                                                    //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                                                                                                             //
//         */                                                                                                                                                                                                 //
//        function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {                                                                                           //
//            require(tokenIds.length == uris.length, "Invalid input");                                                                                                                                       //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                _setTokenURI(tokenIds[i], uris[i]);                                                                                                                                                         //
//            }                                                                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setMintPermissions}.                                                                                                                                                      //
//         */                                                                                                                                                                                                 //
//        function setMintPermissions(address extension, address permissions) external override adminRequired {                                                                                               //
//            _setMintPermissions(extension, permissions);                                                                                                                                                    //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-mintBaseNew}.                                                                                                                                                      //
//         */                                                                                                                                                                                                 //
//        function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory) {                      //
//            return _mintNew(address(this), to, amounts, uris);                                                                                                                                              //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-mintBaseExisting}.                                                                                                                                                 //
//         */                                                                                                                                                                                                 //
//        function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant adminRequired {                                      //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                require(_tokensExtension[tokenIds[i]] == address(this), "A token was created by an extension");                                                                                             //
//            }                                                                                                                                                                                               //
//            _mintExisting(address(this), to, tokenIds, amounts);                                                                                                                                            //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-mintExtensionNew}.                                                                                                                                                 //
//         */                                                                                                                                                                                                 //
//        function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant extensionRequired returns(uint256[] memory tokenIds) {    //
//            return _mintNew(msg.sender, to, amounts, uris);                                                                                                                                                 //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-mintExtensionExisting}.                                                                                                                                            //
//         */                                                                                                                                                                                                 //
//        function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant extensionRequired {                             //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                require(_tokensExtension[tokenIds[i]] == address(msg.sender), "A token was not created by this extension");                                                                                 //
//            }                                                                                                                                                                                               //
//            _mintExisting(msg.sender, to, tokenIds, amounts);                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev Mint new tokens                                                                                                                                                                             //
//         */                                                                                                                                                                                                 //
//        function _mintNew(address extension, address[] memory to, uint256[] memory amounts, string[] memory uris) internal returns(uint256[] memory tokenIds) {                                             //
//            if (to.length > 1) {                                                                                                                                                                            //
//                // Multiple receiver.  Give every receiver the same new token                                                                                                                               //
//                tokenIds = new uint256[](1);                                                                                                                                                                //
//                require(uris.length <= 1 && (amounts.length == 1 || to.length == amounts.length), "Invalid input");                                                                                         //
//            } else {                                                                                                                                                                                        //
//                // Single receiver.  Generating multiple tokens                                                                                                                                             //
//                tokenIds = new uint256[](amounts.length);                                                                                                                                                   //
//                require(uris.length == 0 || amounts.length == uris.length, "Invalid input");                                                                                                                //
//            }                                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//            // Assign tokenIds                                                                                                                                                                              //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                _tokenCount++;                                                                                                                                                                              //
//                tokenIds[i] = _tokenCount;                                                                                                                                                                  //
//                // Track the extension that minted the token                                                                                                                                                //
//                _tokensExtension[_tokenCount] = extension;                                                                                                                                                  //
//            }                                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//            if (extension != address(this)) {                                                                                                                                                               //
//                _checkMintPermissions(to, tokenIds, amounts);                                                                                                                                               //
//            }                                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//            if (to.length == 1 && tokenIds.length == 1) {                                                                                                                                                   //
//               // Single mint                                                                                                                                                                               //
//               _mint(to[0], tokenIds[0], amounts[0], new bytes(0));                                                                                                                                         //
//            } else if (to.length > 1) {                                                                                                                                                                     //
//                // Multiple receivers.  Receiving the same token                                                                                                                                            //
//                if (amounts.length == 1) {                                                                                                                                                                  //
//                    // Everyone receiving the same amount                                                                                                                                                   //
//                    for (uint i = 0; i < to.length; i++) {                                                                                                                                                  //
//                        _mint(to[i], tokenIds[0], amounts[0], new bytes(0));                                                                                                                                //
//                    }                                                                                                                                                                                       //
//                } else {                                                                                                                                                                                    //
//                    // Everyone receiving different amounts                                                                                                                                                 //
//                    for (uint i = 0; i < to.length; i++) {                                                                                                                                                  //
//                        _mint(to[i], tokenIds[0], amounts[i], new bytes(0));                                                                                                                                //
//                    }                                                                                                                                                                                       //
//                }                                                                                                                                                                                           //
//            } else {                                                                                                                                                                                        //
//                _mintBatch(to[0], tokenIds, amounts, new bytes(0));                                                                                                                                         //
//            }                                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//            for (uint i = 0; i < tokenIds.length; i++) {                                                                                                                                                    //
//                if (i < uris.length && bytes(uris[i]).length > 0) {                                                                                                                                         //
//                    _tokenURIs[tokenIds[i]] = uris[i];                                                                                                                                                      //
//                }                                                                                                                                                                                           //
//            }                                                                                                                                                                                               //
//            return tokenIds;                                                                                                                                                                                //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev Mint existing tokens                                                                                                                                                                        //
//         */                                                                                                                                                                                                 //
//        function _mintExisting(address extension, address[] memory to, uint256[] memory tokenIds, uint256[] memory amounts) internal {                                                                      //
//            if (extension != address(this)) {                                                                                                                                                               //
//                _checkMintPermissions(to, tokenIds, amounts);                                                                                                                                               //
//            }                                                                                                                                                                                               //
//                                                                                                                                                                                                            //
//            if (to.length == 1 && tokenIds.length == 1 && amounts.length == 1) {                                                                                                                            //
//                 // Single mint                                                                                                                                                                             //
//                _mint(to[0], tokenIds[0], amounts[0], new bytes(0));                                                                                                                                        //
//            } else if (to.length == 1 && tokenIds.length == amounts.length) {                                                                                                                               //
//                // Batch mint to same receiver                                                                                                                                                              //
//                _mintBatch(to[0], tokenIds, amounts, new bytes(0));                                                                                                                                         //
//            } else if (tokenIds.length == 1 && amounts.length == 1) {                                                                                                                                       //
//                // Mint of the same token/token amounts to various receivers                                                                                                                                //
//                for (uint i = 0; i < to.length; i++) {                                                                                                                                                      //
//                    _mint(to[i], tokenIds[0], amounts[0], new bytes(0));                                                                                                                                    //
//                }                                                                                                                                                                                           //
//            } else if (tokenIds.length == 1 && to.length == amounts.length) {                                                                                                                               //
//                // Mint of the same token with different amounts to different receivers                                                                                                                     //
//                for (uint i = 0; i < to.length; i++) {                                                                                                                                                      //
//                    _mint(to[i], tokenIds[0], amounts[i], new bytes(0));                                                                                                                                    //
//                }                                                                                                                                                                                           //
//            } else if (to.length == tokenIds.length && to.length == amounts.length) {                                                                                                                       //
//                // Mint of different tokens and different amounts to different receivers                                                                                                                    //
//                for (uint i = 0; i < to.length; i++) {                                                                                                                                                      //
//                    _mint(to[i], tokenIds[i], amounts[i], new bytes(0));                                                                                                                                    //
//                }                                                                                                                                                                                           //
//            } else {                                                                                                                                                                                        //
//                revert("Invalid input");                                                                                                                                                                    //
//            }                                                                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-tokenExtension}.                                                                                                                                                   //
//         */                                                                                                                                                                                                 //
//        function tokenExtension(uint256 tokenId) public view virtual override returns (address) {                                                                                                           //
//            return _tokenExtension(tokenId);                                                                                                                                                                //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155CreatorCore-burn}.                                                                                                                                                             //
//         */                                                                                                                                                                                                 //
//        function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual override nonReentrant {                                                                          //
//            require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner nor approved");                                                                                    //
//            require(tokenIds.length == amounts.length, "Invalid input");                                                                                                                                    //
//            if (tokenIds.length == 1) {                                                                                                                                                                     //
//                _burn(account, tokenIds[0], amounts[0]);                                                                                                                                                    //
//            } else {                                                                                                                                                                                        //
//                _burnBatch(account, tokenIds, amounts);                                                                                                                                                     //
//            }                                                                                                                                                                                               //
//            _postBurn(account, tokenIds, amounts);                                                                                                                                                          //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                                                                                                            //
//         */                                                                                                                                                                                                 //
//        function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {                                                                       //
//            _setRoyaltiesExtension(address(this), receivers, basisPoints);                                                                                                                                  //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                                                                                                            //
//         */                                                                                                                                                                                                 //
//        function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {                                                      //
//            _setRoyalties(tokenId, receivers, basisPoints);                                                                                                                                                 //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-setRoyaltiesExtension}.                                                                                                                                                   //
//         */                                                                                                                                                                                                 //
//        function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {                                           //
//            _setRoyaltiesExtension(extension, receivers, basisPoints);                                                                                                                                      //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-getRoyalties}.                                                                                                                                                            //
//         */                                                                                                                                                                                                 //
//        function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {                                                                        //
//            return _getRoyalties(tokenId);                                                                                                                                                                  //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-getFees}.                                                                                                                                                                 //
//         */                                                                                                                                                                                                 //
//        function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {                                                                             //
//            return _getRoyalties(tokenId);                                                                                                                                                                  //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-getFeeRecipients}.                                                                                                                                                        //
//         */                                                                                                                                                                                                 //
//        function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {                                                                                      //
//            return _getRoyaltyReceivers(tokenId);                                                                                                                                                           //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-getFeeBps}.                                                                                                                                                               //
//         */                                                                                                                                                                                                 //
//        function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {                                                                                                        //
//            return _getRoyaltyBPS(tokenId);                                                                                                                                                                 //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ICreatorCore-royaltyInfo}.                                                                                                                                                             //
//         */                                                                                                                                                                                                 //
//        function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {                                                                                    //
//            return _getRoyaltyInfo(tokenId, value);                                                                                                                                                         //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {IERC1155-uri}.                                                                                                                                                                         //
//         */                                                                                                                                                                                                 //
//        function uri(uint256 tokenId) public view virtual override returns (string memory) {                                                                                                                //
//            return _tokenURI(tokenId);                                                                                                                                                                      //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev Total amount of tokens in with a given id.                                                                                                                                                  //
//         */                                                                                                                                                                                                 //
//        function totalSupply(uint256 tokenId) external view virtual override returns (uint256) {                                                                                                            //
//            return _totalSupply[tokenId];                                                                                                                                                                   //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ERC1155-_mint}.                                                                                                                                                                        //
//         */                                                                                                                                                                                                 //
//        function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {                                                                                          //
//            super._mint(account, id, amount, data);                                                                                                                                                         //
//            _totalSupply[id] += amount;                                                                                                                                                                     //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ERC1155-_mintBatch}.                                                                                                                                                                   //
//         */                                                                                                                                                                                                 //
//        function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {                                                                      //
//            super._mintBatch(to, ids, amounts, data);                                                                                                                                                       //
//            for (uint256 i = 0; i < ids.length; ++i) {                                                                                                                                                      //
//                _totalSupply[ids[i]] += amounts[i];                                                                                                                                                         //
//            }                                                                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ERC1155-_burn}.                                                                                                                                                                        //
//         */                                                                                                                                                                                                 //
//        function _burn(address account, uint256 id, uint256 amount) internal virtual override {                                                                                                             //
//            super._burn(account, id, amount);                                                                                                                                                               //
//            _totalSupply[id] -= amount;                                                                                                                                                                     //
//        }                                                                                                                                                                                                   //
//                                                                                                                                                                                                            //
//        /**                                                                                                                                                                                                 //
//         * @dev See {ERC1155-_burnBatch}.                                                                                                                                                                   //
//         */                                                                                                                                                                                                 //
//        function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {                                                                                    //
//            super._burnBatch(account, ids, amounts);                                                                                                                                                        //
//            for (uint256 i = 0; i < ids.length; ++i) {                                                                                                                                                      //
//                _totalSupply[ids[i]] -= amounts[i];                                                                                                                                                         //
//            }                                                                                                                                                                                               //
//        }                                                                                                                                                                                                   //
//    }                                                                                                                                                                                                       //
//                                                                                                                                                                                                            //
//                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MYM is ERC721Creator {
    constructor() ERC721Creator("MYN", "MYM") {}
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
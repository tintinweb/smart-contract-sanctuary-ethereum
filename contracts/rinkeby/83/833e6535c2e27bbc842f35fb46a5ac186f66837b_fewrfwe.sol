// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sdcsdfwef
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//    interface IERC165 {                                                                                                         //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool);                                            //
//    }                                                                                                                           //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    interface IERC721 is IERC165 {                                                                                              //
//                                                                                                                                //
//        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);                                      //
//                                                                                                                                //
//        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);                               //
//                                                                                                                                //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                                   //
//                                                                                                                                //
//        function balanceOf(address owner) external view returns (uint256 balance);                                              //
//                                                                                                                                //
//        function ownerOf(uint256 tokenId) external view returns (address owner);                                                //
//                                                                                                                                //
//        function safeTransferFrom(                                                                                              //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId                                                                                                     //
//        ) external;                                                                                                             //
//                                                                                                                                //
//        function transferFrom(                                                                                                  //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId                                                                                                     //
//        ) external;                                                                                                             //
//                                                                                                                                //
//        function approve(address to, uint256 tokenId) external;                                                                 //
//                                                                                                                                //
//        function getApproved(uint256 tokenId) external view returns (address operator);                                         //
//                                                                                                                                //
//        function setApprovalForAll(address operator, bool _approved) external;                                                  //
//                                                                                                                                //
//        function isApprovedForAll(address owner, address operator) external view returns (bool);                                //
//                                                                                                                                //
//        function safeTransferFrom(                                                                                              //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId,                                                                                                    //
//            bytes calldata data                                                                                                 //
//        ) external;                                                                                                             //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    interface IERC721Enumerable is IERC721 {                                                                                    //
//                                                                                                                                //
//        function totalSupply() external view returns (uint256);                                                                 //
//                                                                                                                                //
//        function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);                     //
//                                                                                                                                //
//        function tokenByIndex(uint256 index) external view returns (uint256);                                                   //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    abstract contract ERC165 is IERC165 {                                                                                       //
//        /**                                                                                                                     //
//         * @dev See {IERC165-supportsInterface}.                                                                                //
//         */                                                                                                                     //
//        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {                            //
//            return interfaceId == type(IERC165).interfaceId;                                                                    //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    library Strings {                                                                                                           //
//        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";                                                             //
//                                                                                                                                //
//        function toString(uint256 value) internal pure returns (string memory) {                                                //
//                                                                                                                                //
//            if (value == 0) {                                                                                                   //
//                return "0";                                                                                                     //
//            }                                                                                                                   //
//            uint256 temp = value;                                                                                               //
//            uint256 digits;                                                                                                     //
//            while (temp != 0) {                                                                                                 //
//                digits++;                                                                                                       //
//                temp /= 10;                                                                                                     //
//            }                                                                                                                   //
//            bytes memory buffer = new bytes(digits);                                                                            //
//            while (value != 0) {                                                                                                //
//                digits -= 1;                                                                                                    //
//                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));                                                       //
//                value /= 10;                                                                                                    //
//            }                                                                                                                   //
//            return string(buffer);                                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//        function toHexString(uint256 value) internal pure returns (string memory) {                                             //
//            if (value == 0) {                                                                                                   //
//                return "0x00";                                                                                                  //
//            }                                                                                                                   //
//            uint256 temp = value;                                                                                               //
//            uint256 length = 0;                                                                                                 //
//            while (temp != 0) {                                                                                                 //
//                length++;                                                                                                       //
//                temp >>= 8;                                                                                                     //
//            }                                                                                                                   //
//            return toHexString(value, length);                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {                             //
//            bytes memory buffer = new bytes(2 * length + 2);                                                                    //
//            buffer[0] = "0";                                                                                                    //
//            buffer[1] = "x";                                                                                                    //
//            for (uint256 i = 2 * length + 1; i > 1; --i) {                                                                      //
//                buffer[i] = _HEX_SYMBOLS[value & 0xf];                                                                          //
//                value >>= 4;                                                                                                    //
//            }                                                                                                                   //
//            require(value == 0, "Strings: hex length insufficient");                                                            //
//            return string(buffer);                                                                                              //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    library Address {                                                                                                           //
//        function isContract(address account) internal view returns (bool) {                                                     //
//                                                                                                                                //
//            uint256 size;                                                                                                       //
//            assembly {                                                                                                          //
//                size := extcodesize(account)                                                                                    //
//            }                                                                                                                   //
//            return size > 0;                                                                                                    //
//        }                                                                                                                       //
//                                                                                                                                //
//        function sendValue(address payable recipient, uint256 amount) internal {                                                //
//            require(address(this).balance >= amount, "Address: insufficient balance");                                          //
//                                                                                                                                //
//            (bool success, ) = recipient.call{value: amount}("");                                                               //
//            require(success, "Address: unable to send value, recipient may have reverted");                                     //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionCall(address target, bytes memory data) internal returns (bytes memory) {                              //
//            return functionCall(target, data, "Address: low-level call failed");                                                //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionCall(                                                                                                  //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            return functionCallWithValue(target, data, 0, errorMessage);                                                        //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionCallWithValue(                                                                                         //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            uint256 value                                                                                                       //
//        ) internal returns (bytes memory) {                                                                                     //
//            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");                     //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionCallWithValue(                                                                                         //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            uint256 value,                                                                                                      //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            require(address(this).balance >= value, "Address: insufficient balance for call");                                  //
//            require(isContract(target), "Address: call to non-contract");                                                       //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.call{value: value}(data);                                          //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {                   //
//            return functionStaticCall(target, data, "Address: low-level static call failed");                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionStaticCall(                                                                                            //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal view returns (bytes memory) {                                                                                //
//            require(isContract(target), "Address: static call to non-contract");                                                //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.staticcall(data);                                                  //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {                      //
//            return functionDelegateCall(target, data, "Address: low-level delegate call failed");                               //
//        }                                                                                                                       //
//                                                                                                                                //
//        function functionDelegateCall(                                                                                          //
//            address target,                                                                                                     //
//            bytes memory data,                                                                                                  //
//            string memory errorMessage                                                                                          //
//        ) internal returns (bytes memory) {                                                                                     //
//            require(isContract(target), "Address: delegate call to non-contract");                                              //
//                                                                                                                                //
//            (bool success, bytes memory returndata) = target.delegatecall(data);                                                //
//            return verifyCallResult(success, returndata, errorMessage);                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function verifyCallResult(                                                                                              //
//            bool success,                                                                                                       //
//            bytes memory returndata,                                                                                            //
//            string memory errorMessage                                                                                          //
//        ) internal pure returns (bytes memory) {                                                                                //
//            if (success) {                                                                                                      //
//                return returndata;                                                                                              //
//            } else {                                                                                                            //
//                // Look for revert reason and bubble it up if present                                                           //
//                if (returndata.length > 0) {                                                                                    //
//                    // The easiest way to bubble the revert reason is using memory via assembly                                 //
//                                                                                                                                //
//                    assembly {                                                                                                  //
//                        let returndata_size := mload(returndata)                                                                //
//                        revert(add(32, returndata), returndata_size)                                                            //
//                    }                                                                                                           //
//                } else {                                                                                                        //
//                    revert(errorMessage);                                                                                       //
//                }                                                                                                               //
//            }                                                                                                                   //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//                                                                                                                                //
//    interface IERC721Metadata is IERC721 {                                                                                      //
//        function name() external view returns (string memory);                                                                  //
//                                                                                                                                //
//        function symbol() external view returns (string memory);                                                                //
//                                                                                                                                //
//        function tokenURI(uint256 tokenId) external view returns (string memory);                                               //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//                                                                                                                                //
//    interface IERC721Receiver {                                                                                                 //
//        function onERC721Received(                                                                                              //
//            address operator,                                                                                                   //
//            address from,                                                                                                       //
//            uint256 tokenId,                                                                                                    //
//            bytes calldata data                                                                                                 //
//        ) external returns (bytes4);                                                                                            //
//    }                                                                                                                           //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//    abstract contract Context {                                                                                                 //
//        function _msgSender() internal view virtual returns (address) {                                                         //
//            return msg.sender;                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _msgData() internal view virtual returns (bytes calldata) {                                                    //
//            return msg.data;                                                                                                    //
//        }                                                                                                                       //
//    }                                                                                                                           //
//                                                                                                                                //
//                                                                                                                                //
//    pragma solidity ^0.8.0;                                                                                                     //
//    contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {                                                              //
//        using Address for address;                                                                                              //
//        using Strings for uint256;                                                                                              //
//                                                                                                                                //
//        string private _name;                                                                                                   //
//                                                                                                                                //
//        string private _symbol;                                                                                                 //
//                                                                                                                                //
//        mapping(uint256 => address) private _owners;                                                                            //
//                                                                                                                                //
//        mapping(address => uint256) private _balances;                                                                          //
//                                                                                                                                //
//        mapping(uint256 => address) private _tokenApprovals;                                                                    //
//                                                                                                                                //
//        mapping(address => mapping(address => bool)) private _operatorApprovals;                                                //
//                                                                                                                                //
//        constructor(string memory name_, string memory symbol_) {                                                               //
//            _name = name_;                                                                                                      //
//            _symbol = symbol_;                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {           //
//            return                                                                                                              //
//                interfaceId == type(IERC721).interfaceId ||                                                                     //
//                interfaceId == type(IERC721Metadata).interfaceId ||                                                             //
//                super.supportsInterface(interfaceId);                                                                           //
//        }                                                                                                                       //
//                                                                                                                                //
//        function balanceOf(address owner) public view virtual override returns (uint256) {                                      //
//            require(owner != address(0), "ERC721: balance query for the zero address");                                         //
//            return _balances[owner];                                                                                            //
//        }                                                                                                                       //
//                                                                                                                                //
//        function ownerOf(uint256 tokenId) public view virtual override returns (address) {                                      //
//            address owner = _owners[tokenId];                                                                                   //
//            require(owner != address(0), "ERC721: owner query for nonexistent token");                                          //
//            return owner;                                                                                                       //
//        }                                                                                                                       //
//                                                                                                                                //
//        function name() public view virtual override returns (string memory) {                                                  //
//            return _name;                                                                                                       //
//        }                                                                                                                       //
//                                                                                                                                //
//        function symbol() public view virtual override returns (string memory) {                                                //
//            return _symbol;                                                                                                     //
//        }                                                                                                                       //
//                                                                                                                                //
//        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {                               //
//            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");                                       //
//                                                                                                                                //
//            string memory baseURI = _baseURI();                                                                                 //
//            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";                      //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _baseURI() internal view virtual returns (string memory) {                                                     //
//            return "";                                                                                                          //
//        }                                                                                                                       //
//                                                                                                                                //
//        function approve(address to, uint256 tokenId) public virtual override {                                                 //
//            address owner = ERC721.ownerOf(tokenId);                                                                            //
//            require(to != owner, "ERC721: approval to current owner");                                                          //
//                                                                                                                                //
//            require(                                                                                                            //
//                _msgSender() == owner || isApprovedForAll(owner, _msgSender()),                                                 //
//                "ERC721: approve caller is not owner nor approved for all"                                                      //
//            );                                                                                                                  //
//                                                                                                                                //
//            _approve(to, tokenId);                                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//        function getApproved(uint256 tokenId) public view virtual override returns (address) {                                  //
//            require(_exists(tokenId), "ERC721: approved query for nonexistent token");                                          //
//                                                                                                                                //
//            return _tokenApprovals[tokenId];                                                                                    //
//        }                                                                                                                       //
//                                                                                                                                //
//        function setApprovalForAll(address operator, bool approved) public virtual override {                                   //
//            require(operator != _msgSender(), "ERC721: approve to caller");                                                     //
//                                                                                                                                //
//            _operatorApprovals[_msgSender()][operator] = approved;                                                              //
//            emit ApprovalForAll(_msgSender(), operator, approved);                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//        function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {                //
//            return _operatorApprovals[owner][operator];                                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function transferFrom(                                                                                                  //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId                                                                                                     //
//        ) public virtual override {                                                                                             //
//            //solhint-disable-next-line max-line-length                                                                         //
//            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");            //
//                                                                                                                                //
//            _transfer(from, to, tokenId);                                                                                       //
//        }                                                                                                                       //
//                                                                                                                                //
//        function safeTransferFrom(                                                                                              //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId                                                                                                     //
//        ) public virtual override {                                                                                             //
//            safeTransferFrom(from, to, tokenId, "");                                                                            //
//        }                                                                                                                       //
//                                                                                                                                //
//        function safeTransferFrom(                                                                                              //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId,                                                                                                    //
//            bytes memory _data                                                                                                  //
//        ) public virtual override {                                                                                             //
//            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");            //
//            _safeTransfer(from, to, tokenId, _data);                                                                            //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _safeTransfer(                                                                                                 //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId,                                                                                                    //
//            bytes memory _data                                                                                                  //
//        ) internal virtual {                                                                                                    //
//            _transfer(from, to, tokenId);                                                                                       //
//            require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");    //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _exists(uint256 tokenId) internal view virtual returns (bool) {                                                //
//            return _owners[tokenId] != address(0);                                                                              //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {                    //
//            require(_exists(tokenId), "ERC721: operator query for nonexistent token");                                          //
//            address owner = ERC721.ownerOf(tokenId);                                                                            //
//            return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _safeMint(address to, uint256 tokenId) internal virtual {                                                      //
//            _safeMint(to, tokenId, "");                                                                                         //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _safeMint(                                                                                                     //
//            address to,                                                                                                         //
//            uint256 tokenId,                                                                                                    //
//            bytes memory _data                                                                                                  //
//        ) internal virtual {                                                                                                    //
//            _mint(to, tokenId);                                                                                                 //
//            require(                                                                                                            //
//                _checkOnERC721Received(address(0), to, tokenId, _data),                                                         //
//                "ERC721: transfer to non ERC721Receiver implementer"                                                            //
//            );                                                                                                                  //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _mint(address to, uint256 tokenId) internal virtual {                                                          //
//            require(to != address(0), "ERC721: mint to the zero address");                                                      //
//            require(!_exists(tokenId), "ERC721: token already minted");                                                         //
//                                                                                                                                //
//            _beforeTokenTransfer(address(0), to, tokenId);                                                                      //
//                                                                                                                                //
//            _balances[to] += 1;                                                                                                 //
//            _owners[tokenId] = to;                                                                                              //
//                                                                                                                                //
//            emit Transfer(address(0), to, tokenId);                                                                             //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _burn(uint256 tokenId) internal virtual {                                                                      //
//            address owner = ERC721.ownerOf(tokenId);                                                                            //
//                                                                                                                                //
//            _beforeTokenTransfer(owner, address(0), tokenId);                                                                   //
//                                                                                                                                //
//            // Clear approvals                                                                                                  //
//            _approve(address(0), tokenId);                                                                                      //
//                                                                                                                                //
//            _balances[owner] -= 1;                                                                                              //
//            delete _owners[tokenId];                                                                                            //
//                                                                                                                                //
//            emit Transfer(owner, address(0), tokenId);                                                                          //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _transfer(                                                                                                     //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId                                                                                                     //
//        ) internal virtual {                                                                                                    //
//            require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");                              //
//            require(to != address(0), "ERC721: transfer to the zero address");                                                  //
//                                                                                                                                //
//            _beforeTokenTransfer(from, to, tokenId);                                                                            //
//                                                                                                                                //
//            // Clear approvals from the previous owner                                                                          //
//            _approve(address(0), tokenId);                                                                                      //
//                                                                                                                                //
//            _balances[from] -= 1;                                                                                               //
//            _balances[to] += 1;                                                                                                 //
//            _owners[tokenId] = to;                                                                                              //
//                                                                                                                                //
//            emit Transfer(from, to, tokenId);                                                                                   //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _approve(address to, uint256 tokenId) internal virtual {                                                       //
//            _tokenApprovals[tokenId] = to;                                                                                      //
//            emit Approval(ERC721.ownerOf(tokenId), to, tokenId);                                                                //
//        }                                                                                                                       //
//                                                                                                                                //
//        function _checkOnERC721Received(                                                                                        //
//            address from,                                                                                                       //
//            address to,                                                                                                         //
//            uint256 tokenId,                                                                                                    //
//            bytes memory _data                                                                                                  //
//        ) private returns (bool) {                                                                                              //
//            if (to.isContract()) {                                                                                              //
//                try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {          //
//                    return retval == IERC721Receiver.onERC721Received.selector;                                                 //
//                } catch (bytes memory reason) {                                                                                 //
//                    if (reason.length == 0) {                                                                                   //
//                        revert("ERC721: transfer to non ERC721Receiver implementer");                                           //
//                    } else {                                                                                                    //
//                        assembly {                                                                                              //
//                            revert(add(32, reason), mlo                                                                         //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract fewrfwe is ERC721Creator {
    constructor() ERC721Creator("sdcsdfwef", "fewrfwe") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
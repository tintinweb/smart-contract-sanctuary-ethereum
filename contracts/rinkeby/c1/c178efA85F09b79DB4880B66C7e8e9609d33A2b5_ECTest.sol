/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//  /$$$$$$$$ /$$                     /$$                        
// | $$_____/| $$                    |__/                        
// | $$      | $$ /$$   /$$  /$$$$$$$ /$$ /$$   /$$ /$$$$$$/$$$$ 
// | $$$$$   | $$| $$  | $$ /$$_____/| $$| $$  | $$| $$_  $$_  $$
// | $$__/   | $$| $$  | $$|  $$$$$$ | $$| $$  | $$| $$ \ $$ \ $$
// | $$      | $$| $$  | $$ \____  $$| $$| $$  | $$| $$ | $$ | $$
// | $$$$$$$$| $$|  $$$$$$$ /$$$$$$$/| $$|  $$$$$$/| $$ | $$ | $$
// |________/|__/ \____  $$|_______/ |__/ \______/ |__/ |__/ |__/
//                /$$  | $$                                      
//               |  $$$$$$/                                      
//                \______/                                       
//   /$$$$$$  /$$           /$$                                  
//  /$$__  $$| $$          | $$                                  
// | $$  \__/| $$ /$$   /$$| $$$$$$$                             
// | $$      | $$| $$  | $$| $$__  $$                            
// | $$      | $$| $$  | $$| $$  \ $$                            
// | $$    $$| $$| $$  | $$| $$  | $$                            
// |  $$$$$$/| $$|  $$$$$$/| $$$$$$$/                            
//  \______/ |__/ \______/ |_______/                             
                                                                                                         
/*
#######################################################################################################################
#######################################################################################################################

Copyright CryptIT GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on aln "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

#######################################################################################################################
#######################################################################################################################

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;


library LibPart {
    
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }

}


//pragma abicoder v2;
interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}


abstract contract AbstractRoyalties {

    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    mapping(uint256 => uint256) private lockTimes;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function approve(address to, uint256 tokenId) public override {
        require(lockTimes[tokenId] < block.timestamp, "Cannot approve locked token");

        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(lockTimes[tokenId] < block.timestamp, "Cannot transfer locked token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(lockTimes[tokenId] < block.timestamp, "Cannot transfer locked token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _getLockTime(uint256 tokenId) internal view returns(uint256) {
        return lockTimes[tokenId];
    }

    function _lockForBooking(uint256 tokenId, uint256 lockTime) internal {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "Only owner can lock");
        require(lockTime > block.timestamp, "Lock time has to be in the future");
        require(lockTime > lockTimes[tokenId], "Cannot unlock token");
        lockTimes[tokenId] = lockTime;
    }
    
    function _safetyUnlock(uint256 tokenId) internal {
        lockTimes[tokenId] = block.timestamp - 1;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

library LibRoyaltiesV2 {
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

//pragma abicoder v2;
contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}                   

contract ECTest is ERC721Enumerable, Ownable, RoyaltiesV2Impl {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _dataHostBaseURI = "ipfs://ectest/";
    string private _lockedDataHostBaseURI = "ipfs://ectest/";
    string private _contractURI = "https://ipfs.io/ipfs/ectest";
    string private _placeHolderHash = "ipfs://ectest";

    uint256 public maxMints = 6888;
    bool public publicBuyEnabled = false;
    bool public treasuresRevealed = false;

    mapping(address => bool) private isCollabPartner;
    mapping(address => uint256) private _userMints;
    
    uint256 public maxUserMints = 10;

    uint256 private _price = 500000000000000000;
    uint256 private _collabPrice = 500000000000000000;
    
    uint96 private _raribleRoyaltyPercentage = 500;
    address payable _beneficiary = payable(address(0x12CcBd4b15052f261FD472731Db4F353ffc5ee89));
    address payable _raribleBeneficiary = payable(address(0x12CcBd4b15052f261FD472731Db4F353ffc5ee89));

    event BeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event RaribleBeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event BeneficiaryPaid(address payable beneficiary, uint256 amount);
    event PriceChange(uint256 previousPrice, uint256 newPrice);
    event RaribleRoyaltyPercentageChange(uint96 previousPercentage, uint96 newPercentage);
    event BaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractBaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractURIChanged(string previousURI, string newURI);
    event PublicBuyEnabled(bool enabled);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor( string memory name, string memory symbol
    ) ERC721(name, symbol) Ownable() {
        emit BeneficiaryChanged(payable(address(0)), _beneficiary);
        emit RaribleBeneficiaryChanged(payable(address(0)), _raribleBeneficiary);
        emit RaribleRoyaltyPercentageChange(0, _raribleRoyaltyPercentage);
    }

    function _mintToken(address owner) internal returns (uint) {

        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= maxMints, "Cannot mint more than max");

        _safeMint(owner, id);
        _setRoyalties(id, _raribleBeneficiary, _raribleRoyaltyPercentage);

        emit PermanentURI(_tokenURI(id), id);

        return id;
    }

    /**
    * @dev Public mint function to mint one token
    */
    function mintToken() external payable returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");
        require(_userMints[msg.sender] <= maxUserMints, "Already minted maximum");

        uint256 mintPrice = isCollabPartner[_msgSender()] ? _collabPrice : _price;
        require(msg.value >= mintPrice, "Invalid value sent");

        uint256 id = _mintToken(_msgSender());

        (bool sent, ) = _beneficiary.call{value : msg.value}("");
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, msg.value);
        
        _userMints[msg.sender] = _userMints[msg.sender] + 1;

        return id;
    }

    /**
    * @dev Public mint function to mint multiple tokens at once
    * @param count The amount of tokens to mint
    */
    function mintMultipleToken(uint256 count) external payable returns (uint256) {

        require(publicBuyEnabled, "Public buy is not enabled yet");
        require(_userMints[msg.sender] + count <= maxUserMints, "Already minted maximum");

        uint256 mintPrice = isCollabPartner[_msgSender()] ? _collabPrice : _price;
        require(msg.value >= mintPrice.mul(count), "Invalid value sent");

        for (uint256 i = 0; i < count; i++) {
            _mintToken(msg.sender);
        }

        (bool sent, ) = _beneficiary.call{value : msg.value}("");
        require(sent, "Failed to pay beneficiary");
        emit BeneficiaryPaid(_beneficiary, msg.value);

        _userMints[msg.sender] = _userMints[msg.sender] + count;

        return count;
    }

    /**
    * @dev Admin function to mint on token to multiple addresses
    * @param addresses Array of addresses to mint to
    */
    function airdrop(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i]);
        }
    }

    /**
    * @dev Admin function to mint many tokens
    * @param count The count to mint
    * @param receiver The receiver to mint to
    */
    function mintMany(uint256 count, address receiver) external onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _mintToken(receiver);
        }
    }

    /**
    * @dev Get opensea royalty beneficiary
    */
    function getBeneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
    * @dev Set opensea royalty beneficiary
    * @param newBeneficiary The new opensea royalty beneficiary
    */
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new beneficiary is the zero address");
        address payable prev = _beneficiary;
        _beneficiary = newBeneficiary;
        emit BeneficiaryChanged(prev, _beneficiary);
    }

    /**
    * @dev Set rarible royalty beneficiary
    * @param newBeneficiary The new rarible royalty beneficiary
    */
    function setRaribleBeneficiary(address payable newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new rarible beneficiary is the zero address");
        address payable prev = _raribleBeneficiary;
        _raribleBeneficiary = newBeneficiary;
        emit RaribleBeneficiaryChanged(prev, _raribleBeneficiary);
    }

    /**
    * @dev Get the current mint price
    */
    function getPrice() external view returns (uint256)  {
        return _price;
    }

    /**
    * @dev Set the mint price
    * @param price The new price
    */
    function setPrice(uint256 price) external onlyOwner {
        uint256 prev = _price;
        _price = price;
        emit PriceChange(prev, _price);
    }

    /**
    * @dev Set the collab  list reduced mint price
    * @param price The new price
    */
    function setCollabPrice(uint256 price) external onlyOwner {
        _collabPrice = price;
    }
    
    /**
    * @dev Set rarible global royalty percentage
    * @param percentage The new rarible percentage
    */
    function setRaribleRoyaltyPercentage(uint96 percentage) external onlyOwner {
        uint96 prev = _raribleRoyaltyPercentage;
        _raribleRoyaltyPercentage = percentage;
        emit RaribleRoyaltyPercentageChange(prev, _raribleRoyaltyPercentage);
    }

    /**
    * @dev Set the base uri for all unlocked token
    * @param dataHostBaseURI The new base uri
    */
    function setDataHostURI(string memory dataHostBaseURI) external onlyOwner {
        string memory prev = _dataHostBaseURI;
        _dataHostBaseURI = dataHostBaseURI;
        emit BaseURIChanged(prev, _dataHostBaseURI);
    }

    /**
    * @dev Set the base URI for the locked metadata
    * @param lockedDataHostBaseURI new base uri
    */
    function setLockedDataHostBaseURI(string memory lockedDataHostBaseURI) external onlyOwner {
        _lockedDataHostBaseURI = lockedDataHostBaseURI;
    }

    /**
    * @dev Set the contract uri for opensea standart
    * @param contractURI_ The new contract uri
    */
    function setContractURI(string memory contractURI_) external onlyOwner {
        string memory prev = _contractURI;
        _contractURI = contractURI_;
        emit ContractURIChanged(prev, _contractURI);
    }

    /**
    * @dev Get the contract uri for opensea standart
    */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(_dataHostBaseURI, Strings.toString(tokenId)));
    }

    function _lockedTokenURI(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(_lockedDataHostBaseURI, Strings.toString(tokenId)));
    }

    /**
    * @dev Get the token URI of a specific id, will return locked metadata if the token is locked
    * @param tokenId The token id
    */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(treasuresRevealed){
            if(_getLockTime(tokenId) > block.timestamp){
                return _lockedTokenURI(tokenId);
            }
            return _tokenURI(tokenId);
        }
        return _placeHolderHash;
    }

    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    /**
    * @dev Set Opensea royalties
    * @param _tokenId The token id
    * @param _royaltiesReceipientAddress The royalty receiver address
    * @param _percentageBasisPoints The royalty percentage in basis points
    */
    function setRoyalties(uint256 _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) external onlyOwner {
        _setRoyalties(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }

    /**
    * @dev Set placeholder hash for unrevealed metadata
    * @param placeHolderHash new placeholder uri
    */
    function setPlaceHolderHash(string memory placeHolderHash) external onlyOwner {
        _placeHolderHash = placeHolderHash;
    }
    
    /**
    * @dev Admin function to reveal the actual metadata
    */
    function revealTreasures() external onlyOwner {
        treasuresRevealed = !treasuresRevealed;
    }

    /**
    * @dev Admin function to release a token from lock
    * @param tokenId the token id to unlock
    */
    function safetyUnlock(uint256 tokenId) external onlyOwner {
        _safetyUnlock(tokenId);
    }

    /**
    * @dev Adds address to collab reduces price
    * @param collabAddresses collab address to add
    */
    function addCollabPartner(address[] memory collabAddresses) external onlyOwner {
        for(uint256 i = 0; i < collabAddresses.length; i++){
            isCollabPartner[collabAddresses[i]] = true;
        }
    }

    /**
    * @dev Removes address from collab reduces price
    * @param collabAddress collab address to remove from list
    */
    function removeCollabPartner(address collabAddress) external onlyOwner {
        require(isCollabPartner[collabAddress] == true, "Not marked as partner");
        isCollabPartner[collabAddress] = false;
    }

    /**
    * @dev Switches the public sale
    * @param enabled true if the public mint should be enabled
    */
    function enablePublicBuy(bool enabled) external onlyOwner {
        require(publicBuyEnabled != enabled, "Already set");
        publicBuyEnabled = enabled;
        emit PublicBuyEnabled(publicBuyEnabled);
    }

    /**
    * @dev Sets max allowed mints per user address
    * @param _maxUserMints The maximum mint count per user address.
    */
    function setMaxUserMints(uint256 _maxUserMints) external onlyOwner {
        maxUserMints = _maxUserMints;
    }
    
    /**
    * @dev Count of mints from user
    * @param user The address of the user.
    */
    function userMints(address user) external view returns (uint256) {
        return _userMints[user];
    }
    

    /**
    * @dev Get the lock time of a token
    * @param tokenId The token id
    */
    function getLockTime(uint256 tokenId) external view returns(uint256) {
        return _getLockTime(tokenId);
    }

    /**
    * @dev Public function to lock a token, used in the dApp to complete a boocking process.
    * A locked token cannot be transferred or unlocked. There is a admin safety to unlock tokens in case of cancel.
    * @param tokenId The token id to lock
    * @param lockTime The time to lock the token as a unix timestamp
    */
    function lockForBooking(uint256 tokenId, uint256 lockTime) external {
        _lockForBooking(tokenId, lockTime);
    }

    /**
    * @dev Support Interface for Rarible royalty implementation
    */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}
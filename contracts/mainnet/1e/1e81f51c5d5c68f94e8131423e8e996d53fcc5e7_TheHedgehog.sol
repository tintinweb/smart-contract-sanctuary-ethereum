/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;



interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 burnQuantity) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        mapping (bytes32 => uint256) _indexes;
    }

    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            MapEntry storage lastEntry = map._entries[lastIndex];
            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1;
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Strings {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

contract TheHedgehog is Context, Ownable, ERC165, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    

    uint256 public constant MAX_NFT_SUPPLY = 10000;

    uint256 public presaleStartTimestamp = 1643551200;
    uint256 public saleStartTimestamp = 1643638500;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmdbPUUBpDrH5JgiBSaQmxzyLwp99xYHp2X52s82jHtCiY/";

    mapping (address => uint256) private rewards;

    uint256 private _state = 1;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    string private _name;
    string private _symbol;


    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    function name() public pure override returns (string memory) {
        return "The Hedgehog";
    }

    function symbol() public pure override returns (string memory) {
        return "TH";
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _holderTokens[owner].at(index);
    }

   
    function totalSupply() public view returns (uint256) {
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function getReward(address customer) public view returns (uint256) {
        return rewards[customer];
    }

    function getNFTPricePreSale() public pure returns (uint256) {
        return 0.02 ether;
    }

    function getNFTPrice() public pure returns (uint256) {
        return 0.03 ether;
    }

    function _getRandomNumber() private returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function _draw(uint256 tikets, uint256 start) private {
        uint256 seed = _getRandomNumber();
        uint256 budget = 10 ether;

        for (uint256 i = 0; i < tikets; i++) {
            uint256 winning_tiket = start + (seed >> i) % 2000;
            rewards[ownerOf(winning_tiket)] += budget / tikets;
        }
    }

    function draw1() public {
        require(totalSupply() >= 2000, "20% not closed yet");
        require(_state == 1, "First draw has been");
        _draw(15, 0);
        _state <<= 1;
    }

    function draw2() public {
        require(totalSupply() >= 4000, "40% not closed yet");
        require(_state == 2, "Second draw has been");
        _draw(12, 2000);
        _state <<= 1;
    }

    function draw3() public {
        require(totalSupply() >= 6000, "60% not closed yet");
        require(_state == 4, "Third draw has been");
        _draw(9, 4000);
        _state <<= 1;
    }

    function draw4() public {
        require(totalSupply() >= 8000, "80% not closed yet");
        require(_state == 8, "Fourth draw has been");
        _draw(6, 6000);
        _state <<= 1;
    }
    
    function draw5() public {
        require(totalSupply() == 10000, "100% not closed yet");
        require(_state == 16, "Fifth draw has been");
        _draw(3, 8000);
        _state <<= 1;
    }

    modifier preSale() {
        require(block.timestamp >= presaleStartTimestamp, "Presale has not started");
        require(block.timestamp < saleStartTimestamp && (
                // dev
                msg.sender == 0x77AB2F647C440fC0340bbE2f0bf9C1E981A61935 ||
                // white list
                msg.sender == 0x1596c68cf5b99a737a84De1B2FFda09D9F715eDB ||
                msg.sender == 0x31D0821B51852BA9575B99415Df0D7Efd73a63bD ||
                msg.sender == 0x53975AD2e4B8FD521cc30312C422336fF25B0D7B ||
                msg.sender == 0xE07eBB6271b72bD35eF24F7DB344EeD973EB2943 ||
                msg.sender == 0xdcE9cf3B1166791dB055C560D6Cce91b81c3F377 ||
                msg.sender == 0x7017F6ddf8F17Cb2cdC2cfd902775eaBBD09Efaf ||
                msg.sender == 0x211f5248EdD9e1468856Ded559496301Dd40a3dE ||
                msg.sender == 0x7eACCFB20F01678d3c31c9b30e92303D6fD1eCDc ||
                msg.sender == 0x1774a783f994f8D442109033a51590c5Ad5D32d0 ||
                msg.sender == 0xfD8DF86C3bb3fEc04f1FA22F89d12308dC069a07 ||
                msg.sender == 0x75107e31bFDD4cB0B8C4327B4fb3D681449FD026 ||
                msg.sender == 0xCa2bFb57b8191C23229cD430FaED3b38d0BA4F77 ||
                msg.sender == 0xf62F5cdbF1a778Fe9148CC958Fb48cc7BD50B706 ||
                msg.sender == 0xF908BE78a5E904B1D601187B0c0B4F1B40db2FA5 ||
                msg.sender == 0xf78971c9a143c09b60a5C843872156d7964f57D1 ||
                msg.sender == 0x69D6a50a1147864e7a1ae00fa67d3a73102F693a ||
                msg.sender == 0x90Ca7965BDD24b2ef6A7d08E6DfBD4eA67F54e71 ||
                msg.sender == 0xc89843375A24533f2302562babdeBF5860431A44 ||
                msg.sender == 0x4c7B019F4B268381d3Bd946068B8815F2edAd087 ||
                msg.sender == 0x9915C3881f2c03897c2fB4733e01ba3Cae2C5363 ||
                msg.sender == 0xf8AfE53045DE4A62Ee93021457298FDB6956f0e7 ||
                msg.sender == 0x93929CdA1F479745879C35180eCa54561fbA467a ||
                msg.sender == 0x31CaD254D6dFAF50ca2e4A36aDba568319970CB0 ||
                msg.sender == 0x38791c6c0DEb39a56cd4C1C54F52eF2336DB1587 ||
                msg.sender == 0xe995425373A5C10ECb425baDa14a3F5cBaB9Dda5 ||
                msg.sender == 0xf75f39c7A31A13B34e728C41E34b9fA8f5766e62 ||
                msg.sender == 0x4F7350cAE2d6279DaC4c461d5b3eE73b0cc2093D ||
                msg.sender == 0xEfE512a8c8e9564B9a072F84A40AF7a327eB2ab1 ||
                msg.sender == 0xe7E7E92fB4B3C2D302b8Baea5EA61d730f1c8C7E ||
                msg.sender == 0xD8e1F5432191573e5C2cD96bc4d1B9c8E0CdD0A7 ||
                msg.sender == 0xdcA5dA7B9fCF5ACaADE99223cc8A55a5687d593a ||
                msg.sender == 0x92Dc57dEA003Ed646Cbd9a14b5ffD53B49F65b55 ||
                msg.sender == 0x5f4BA42CBFC4F3D31F7E8Fc347CE2B88d7964B6F ||
                msg.sender == 0x98cB984516df1156595458A78922809d270b8BcA ||
                msg.sender == 0xD18034Bd03284a63395812fE619F3aF01fE6958c ||
                msg.sender == 0xbcA402De5174F693C27A97bE902A8C59a5C957CB ||
                msg.sender == 0x50175Ef09250b6eDeA1e6E423e8BC90ACfE760eB ||
                msg.sender == 0xa598DF54293765eC89fF478A505dC979918b8A92 ||
                msg.sender == 0xCA5A9D7EBF2e6aD0b560D27E5Df5282Cc40B5b35 ||
                msg.sender == 0x45188171B78Ae87DF16ac439f91CcE18dAA1Fe32 ||
                msg.sender == 0x389ddCf9C25eC990ebB8f9fE3D23f6579891aaFa ||
                msg.sender == 0x1c4E165cFacebB554D9ACb98AED158ef14D55c9d ||
                msg.sender == 0x976f5a8946E0c3E2cFb549124E5e9eCc58a1Adc6 ||
                msg.sender == 0x59812AFE80b553eb15C3f2cbC9F7c19157df5a9A ||
                msg.sender == 0x7A64a2AED8DF225A39Df523583D245E4b5a359E0 ||
                msg.sender == 0x1B6734C59fFA02f4EAfB5e33238E477e686360Fb ||
                msg.sender == 0x4d893d8F4B16840182e7b5A22da3C91Ddf6b70A4 ||
                msg.sender == 0x5d98B844735961A424d2755abc557645A2054EE0 ||
                msg.sender == 0x74b7e56795E2AB5BEcD491f3Fd55011741E798c0 ||
                msg.sender == 0x6bB7808FBce6bDa5308ee6F264B8a1fF864014Ad ||
                msg.sender == 0x9c4A144ABD14a958FdeB2481489577107D90918C ||
                msg.sender == 0x78a58Fbe5F911949aB58307e7Dbd1ACB7516FF18 ||
                msg.sender == 0x97dE5FE390D9264A80874712139Ea3779F19Bb36 ||
                msg.sender == 0x97AD288ACFFE2Ded55bB3923E64e25EB5Fb35Dd8 ||
                msg.sender == 0xeE4Ae91C1a0FF150Dbd5b3d070720c22019a487c ||
                msg.sender == 0x24eF767366225472CD36331fB2574424FF69e745 ||
                msg.sender == 0x32a2a344a6e048B880f53eb2175D2eb09d17bfDF ||
                msg.sender == 0x1ba8788217e311f939Dbbc62eF93Bacedb0b354D ||
                msg.sender == 0x32F890b0d0fa5D3A31EC7cC60310BBdeDAff68be ||
                msg.sender == 0x6cB4ea0889e70cE5398c2a160b75E0a710b4fF65 ||
                msg.sender == 0x6364697953dA98D6083ee219A83fb207c2885065 ||
                msg.sender == 0xe3921277177E0B9ACd49f90D6D02A155d6B3a894 ||
                msg.sender == 0x7ff21FF83E66FbAc8AA288e090EEF5b74eD04da2 ||
                msg.sender == 0x62946d28693a89aE35ECba5C3eea85d1f7b24eC7 ||
                msg.sender == 0xd0f64694b4e8c9216d2f88e2E96618aDCc1E70E2 ||
                msg.sender == 0x57fDcfd7362db8288D12069353eef65298c65542 ||
                msg.sender == 0x37ACc00ABCB61CCb056dbC707195485e896271a3 ||
                msg.sender == 0x77ed44042620115E0bC782136C17F333470e1a4f ||
                msg.sender == 0x86436476dFFb92eBfDcCFc9494D5BCCec48b0F51 ||
                msg.sender == 0xDcfBfD73Ed975468987E15B2B09D0A7175d72626 ||
                msg.sender == 0xfFbAD2C3E2BFaa1c72e19C316449Ce465cDbA18F ||
                msg.sender == 0x8F646f8cCA324C83007ad431736262F1b0820f10 ||
                msg.sender == 0x10a3A2AaE03481d0AE32B103aE5a73F01e615a97 ||
                msg.sender == 0x4aD81D17a1CcC7A94b7E4Cb5374aB5721F42f6C2 ||
                msg.sender == 0xCE23EDAE7AdB677c24c52cD2B811bb25412a1F85 ||
                msg.sender == 0xD0E9C355537BDeb350640B461Ed5f84494316BF2 ||
                msg.sender == 0x8c04CA0923A44B75E59917b6361A8846582094f9 ||
                msg.sender == 0x698238DF87FaF0e0b128cF3a481D0D89B27B6981 ||
                msg.sender == 0xfbb5655376fd638991FfbFD27778193C00b88CBd ||
                msg.sender == 0x7f448F0F3a57Eab22096128BD0931831fEa768d0 ||
                msg.sender == 0x1EAB2Ce231260e67B4101CA8849cf245ce8DBA0F ||
                msg.sender == 0xDA97F751f33a111BD70bbA141e89406206EE8097 ||
                msg.sender == 0x56403dc8291a5BD7c7A63a49EdC5c1bAAc5c7D9C ||
                msg.sender == 0x032581D58772cC0edB0FFfAB7385790d8dda3506 ||
                msg.sender == 0x25FC4dFCeDC57574f9979Dfa83dcB5447cD2f14B ||
                msg.sender == 0x1ef2949FB66A4d4CeE189182820D0ff29925f4b0 ||
                msg.sender == 0x9e0d16F137B958aEd5B3cCB4F502807B0Df9f92B ||
                msg.sender == 0xD413e889723648F459dabF692D0Afd3707883c45 ||
                msg.sender == 0xda715D7D5FdeB3e76A5910109d79A336b31677ec ||
                msg.sender == 0x9A7b485238Fea44e8e3b76EB75E6cE3C9331554c ||
                msg.sender == 0xDf23aa927831a228fd5c86Aa23421948EAbD3B56 ||
                msg.sender == 0x3b969EfB9Dd35F25926859CEC036b7ABCa4ac17d ||
                msg.sender == 0x6620d8Afa51Fd4db75Ea2dC7c6532Af6880221D2 ||
                msg.sender == 0xd076F0d91DA3b5285Fd11F07e53484E177D57EdF ||
                msg.sender == 0x87c51fb1747D29d807129dbBe90B0DE73b71694b ||
                msg.sender == 0x825aA4D728725f34dEe76dA39eF5EC9497a45067 ||
                msg.sender == 0xA65D2102dbc9eA22279D26d1B17A024cfaF55538 ||
                msg.sender == 0x0432ec9d8A4b568f9F5d63C3D79f63a6019d9516 ||
                msg.sender == 0x3B5972a5b0eEa5196032E0d3b072b2ED32e983e0 ||
                msg.sender == 0xA23032ee52a38f2DDf8fE6e718af80AdCc255401 ||
                msg.sender == 0x64B6e162dE7e5B98450C490d89563F25e547E5Df ||
                msg.sender == 0xa06baF4C87E2cf58597f8c1F02Ce95Fa08C30aF9 ||
                msg.sender == 0x7CD31906fba447E4825A9C026b14D7e7573Ce200 ||
                msg.sender == 0x26f81020AC8fe650a5a690E48BbE18465C4B8f6B ||
                msg.sender == 0xA109E2376fff8E21260e23871C785aBaBA018de7 ||
                msg.sender == 0x3baC36658160a35318CE9064612B50a4b033Dc95 ||
                msg.sender == 0x7f60F5Ad1E65eBbe97A06eC8d81450D28da760D5 ||
                msg.sender == 0x3043f870eF6B5d1C5ED43a3Ea0b6aFcb268e233f ||
                msg.sender == 0xAc082ca986aae1cCAB3b4ab9f7362E4599F04E23 ||
                msg.sender == 0x20ec1c7DBa32f02d75b9395d912fFde9b52eCe2d ||
                msg.sender == 0x7B7F94d716EF5D7F5a92123EE872fD3524710Fe5 ||
                msg.sender == 0x24bc315bb43D93303086754Da764f812F4800e62 ||
                msg.sender == 0x52566Edc6e7e9F72dbF3b2668B193D277f255976 ||
                msg.sender == 0xC85A9092478Ebcf525cb984f375FdbcF2387f1Bc ||
                msg.sender == 0xda22BE20cb55e6445240FEBa4F99931fccC4a086 ||
                msg.sender == 0xBC07D1B04470c003CDdB4C3FbE1cF7D54d836Fd5 ||
                msg.sender == 0xD1852d19032Bf9448A0Cf317930e256F33aE14A1 ||
                msg.sender == 0xB938953bd611df71f8F16caaeebc0092C306C577 ||
                msg.sender == 0xf611C77Ff10CDF9825b9a670F7064E1Ad1e09C2D ||
                msg.sender == 0x16fF48b8e58BFD2904cB43c74D4222EdB8daEa69 ||
                msg.sender == 0xEaBb59255271e3350EEf1930CbD1c08d316E16f4 ||
                msg.sender == 0x7E69373a53121eFD18A3ec376fd7224D70D6a9bC ||
                msg.sender == 0x0A53DB4f62863ED8eC55A424a5Cc72287a55C29F ||
                msg.sender == 0x6aFa682427ED30C956947DE66e9176F568ee5ae7 ||
                msg.sender == 0x2765ffF2d9614B711E70Dda4ffee9798BcAf1144 ||
                msg.sender == 0xb1D385f44f49fAf655ae58c3d1C27749DcE485E6 ||
                msg.sender == 0x144239F68878Dc14e012be0f9ADc743a798B812c ||
                msg.sender == 0x151e696a2f61206AA4c776E8bD0601f29Ce7eb53 ||
                msg.sender == 0x7C12cD172370cDc6C003ba95913Cf656035B365d ||
                msg.sender == 0xd5beda9285D4bBeAA8eE5f2dd6afac15Cf0CbD30 ||
                msg.sender == 0xbFcAAB8DCF077EfcBec154d61D3BB9c93a46c564 ||
                msg.sender == 0xEC50203c8F951dB3007b0f72FB723D6eAD2dC77d ||
                msg.sender == 0x309caF2E106f08988aE8FDDBA8df1fA8d8EAAC03 ||
                msg.sender == 0x8FD113408804Dc59bb2d711cDcD32b1A1F5347E3 ||
                msg.sender == 0xAD8Ac63c1C85DfAB85276456167B909532f26651 ||
                msg.sender == 0xc9cf8Dd788F7150B58cD3312dD44cEE3D74Be77d ||
                msg.sender == 0x439393eA6e6792C0B3bAFa0c7aaad16674e4e2c0 ||
                msg.sender == 0x9dD32333Dc54E48ECB11BBEc9B031001F6E99745 ||
                msg.sender == 0xE5F0b78ce111a7Ff2443dA9670A9A9374F69eEB0 ||
                msg.sender == 0x01B8d45a9Bbdd924EB2621C114df51691777dFa2 ||
                msg.sender == 0x38e1f093C7D146D2a80C1Be8027b370141763016 ||
                msg.sender == 0x24b281964Dc35942f954246D534678A539ab3252 ||
                msg.sender == 0x3b24fe5621159f6A13742baB05446150B3E96eDD ||
                msg.sender == 0x38929e1D718f6F728385f2A1D4e38a7a62617d0f ||
                msg.sender == 0xc7cc856D6d8bd4Aa594695d64E9D5b9710c1EACC ||
                msg.sender == 0x2EF26B40991ab18bD8DdE57B680633c4040BBa89 ||
                msg.sender == 0x0afeffE4263F14e545a91E67507D206d32C9744C ||
                msg.sender == 0xA92e7D605f789F5FFC5496ae44047CE10F794de8 ||
                msg.sender == 0xFAb426eDd32A7A813ea68d7052e417b9699119Df ||
                msg.sender == 0x46c8A1F08F7FA22eF0481ce044e51c9402e912B0 ||
                msg.sender == 0x5EA5600E51B18a1AF0d759f78F16dA24eFF688f1 ||
                msg.sender == 0xb3BBfeA5afd13D1B4a7463cB0D2D5f4Df32b08c3 ||
                msg.sender == 0x143e59D6BF5cCeEce9a3Bad76Bf0b75fE33ffaf0 ||
                msg.sender == 0xa49f28EB0D6D2A6Ef6b2c158ba25D6d6aeF88d18 ||
                msg.sender == 0xD49caEeA213197d2EB54aAaFa3AABf00C926018D ||
                msg.sender == 0x804A90740F923106213752B28a55C0f3F5b770f1 ||
                msg.sender == 0x7E9edf87C6C7abc84C9ea43035e21E2416A81Ac0 ||
                msg.sender == 0xCeFD6C563d52b904972f526E41A9668902156Cc2 ||
                msg.sender == 0xec83820e8DA36c253A044cdB5BeC11658Dbb1549 ||
                msg.sender == 0x7a134F76Ae6C0B07D5992c112AaC8AeCCbC13b4D ||
                msg.sender == 0x8F34acA944E3eB991e2C4455F2Ca8C50E3C23703 ||
                msg.sender == 0xAC34C4c9995d3e10A3de907FEF7E0d8668AD6B98 ||
                msg.sender == 0x6A310FeA932eA3D20D01cF5d52E63d6f810F8b67 ||
                msg.sender == 0xcc8C2E2DA1278cf8669d52a55090430Fbeca8146 ||
                msg.sender == 0xBD8210008afc30fa0CE7962e885415c8A1b4a420 ||
                msg.sender == 0xE6CA0aEC58DAaCe3A95979a765AacCbbE480E826 ||
                msg.sender == 0x065ac48046E4cA6F0c242b3f5d8683dB273c949D ||
                msg.sender == 0xE8d0537aE84CB059Dd10cc85468F9aa9944CFD8e ||
                msg.sender == 0x3eA03319BC491565A584e30a847334992A4dffB2 ||
                msg.sender == 0xB899Cb6a524B389c497E6ba8200DEBd45a75468C ||
                msg.sender == 0x1a68a2D36Acf76a192C0aAE46e70852B0cc229e7 ||
                msg.sender == 0x92832E2261649889be93D29D04725225c6454514 ||
                msg.sender == 0x4dC7dC5D90ca87AE50E568cc6a673353374cd3Be ||
                msg.sender == 0xEb482A3d4Eb89198066ae0625c75bd64F4c88434 ||
                msg.sender == 0xC25c87c1999CfDAD82A151F96F9d3d97649dbCED ||
                msg.sender == 0x18F4a6606b4f298F3502bF6B70b1f09be0D6c20f ||
                msg.sender == 0xbbb4C0d02Eb47F61045332674ebCF24e32c458C0 ||
                msg.sender == 0x64f7dDeE8efe4d537602493D330184439D13B39B ||
                msg.sender == 0x730650415bDE8a44aFF84BfF9c4407676c2d5d99 ||
                msg.sender == 0xe751E8aF6c4bf76971891C74e721Ea9136E55098 ||
                msg.sender == 0x09c135E618804eF836C0E84A0031e8Add01ab4C5 ||
                msg.sender == 0xaEE5937278D4ECCF0288570C6CD8549E6BdbCbbb ||
                msg.sender == 0x00cD0EDD6599e60B528e95f6FeA447764E7b8a27 ||
                msg.sender == 0xb6adC4a84A5454D95baaB6cE3424B48Ac41D64d8 ||
                msg.sender == 0x8c743962A4f582dDFccCB9eA4042af888d063D28 ||
                msg.sender == 0x5ffcC1e387194c0956C7b3f1aaE5676003C2D407 ||
                msg.sender == 0xcB42443c5e382585638BD1baA453ad4F9078dc9b ||
                msg.sender == 0xAafFCe6Fc88B23d8A72F1BCabEE17614D291183A ||
                msg.sender == 0xf561267ae5bbD2B240eE64B36501257a29E5a07b ||
                msg.sender == 0xD109360CeED8afbaB2BaFb2AB407ef1B56Bf0549 ||
                msg.sender == 0x28F64b43ac50366BF5430c514A70C7Ac8F9087bc ||
                msg.sender == 0xa20F66baF81929388ee056B042167B40a532Ab91 ||
                msg.sender == 0xB4AdAeA9CC333c8e6B27DfB45EFcBeBEf4CE06b2 ||
                msg.sender == 0xFd26837F7081ee67940d47f3773c9C3667d17380 ||
                msg.sender == 0xA300713dbFC85AEbdDA76d54408f17e7D03C4f86 ||
                msg.sender == 0x6d771A66Df06D84a7eE7e473456ABa10932a622B ||
                msg.sender == 0x5936DA81F3AaB9295daFF829708Be6aCC762F0a1 ||
                msg.sender == 0x1328550968A45fbF5c8eD1e4c2f552D17077a2C8 ||
                msg.sender == 0x3AB4B00a88011544a359E9A16ACcCa8b82a5f67B ||
                msg.sender == 0x1e0B10d1ed6E0501fdE4a77bd82A202B12B99655 ||
                msg.sender == 0x254874E9D98Cdb553d4AdDD5388C9057FEA78B79 ||
                msg.sender == 0x7206Ab245c023A7d7DD45F8F65E4Ec8cFd7a3C04 ||
                msg.sender == 0x7b15CA7F877B0866Ab97CBe9E38dc2BE47B2FCb3 ||
                msg.sender == 0x76804ff29196DF542aAA70d2013486b49Ff30901 ||
                msg.sender == 0xc7dc9c3a04aA068aAa32AE1e4dA294A86330DC4a ||
                msg.sender == 0xE42478C00846a2EB7eB332e2C9164fAe93e707b6 ||
                msg.sender == 0xFBa07CAE87B2D6c5f9F48240e1dA7F9947Ac91b4 ||
                msg.sender == 0x6e239E75718a205BB28cd0941627B509d619fE4f ||
                msg.sender == 0x2B1B76A2e3c536C03f140Ec13DD4FA1EAb02Ac05 ||
                msg.sender == 0x6579DF753AF0427eF32F63664F1794e0c2D3FCe3 ||
                msg.sender == 0x76827F491980c679ABA486B774de4723E8FC1a47 ||
                msg.sender == 0xDF0089a6c816C1ed6dF6c9EdF43eD511D960FFCa ||
                msg.sender == 0xCa38d828984D54044741C68553fBaa6653e42A24 ||
                msg.sender == 0x9AfBF9E45B7E64372764740CECD1Fe2f0E0718d3 ||
                msg.sender == 0x60a176d31Ea8504b51b26A1d416Ff9D4cb4A417a ||
                msg.sender == 0x78dC4B540808b1bfFb7FCd04a767f2A51c37B822 ||
                msg.sender == 0x6b491AF263BB4f6A6734997f0A90F7a57F042788 ||
                msg.sender == 0x4b8b0F5DB94C31892A8A5D8CD568aCAab8A80D15 ||
                msg.sender == 0x76381876bCd562536Fe6de59918C27c08Bb43D59 ||
                msg.sender == 0xf69139C36a93b445aFBDf7a26B5B086B2D5E4946 ||
                msg.sender == 0xc41755902C175507d0239D499A5A09DB5c431438 ||
                msg.sender == 0x040d879Ab2dC696a149cE9DBD8Df00c204f138EE ||
                msg.sender == 0x26b7A3f67A6ee886a7DA139407b87b4C872C8CE4 ||
                msg.sender == 0x6a8df845feb820425B08B934d7F60671E7BD3DC0 ||
                msg.sender == 0xA07d461E852cA9190AA9c0830A56A7f9325D1329 ||
                msg.sender == 0x57c77355f367577318D0eb29b6757a4C38809b0A ||
                msg.sender == 0xd87B4c402E200aFC29F4E5e946466c1DCC62fA07 ||
                msg.sender == 0x082C9d19269f117845A6C227D98d863a2b4623D6 ||
                msg.sender == 0xE019ae52e3c82d7D03B708b4a3f8e10b08bcf09f ||
                msg.sender == 0x68505B6a8B3ac6a65ba83f558c642389062f6e2d ||
                msg.sender == 0x8D6D2b6d1D83d542370A7a58dD9e730609981579 ||
                msg.sender == 0xf68cFA021d2c275B362Fbe628328abFE02b0e223 ||
                msg.sender == 0x7cD6d7E75b5eF12fe80c900dA3FdF29c77FD6360 ||
                msg.sender == 0x40EB0731F94bD6e9517034f55EaE5dC9a3A0e7A3 ||
                msg.sender == 0xc7F59ee4BBBD66C28ae21FB738C0AC0f6D401665 ||
                msg.sender == 0xB023047bFC6aB973bA34b5E02598aF569445f4A7 ||
                msg.sender == 0x8517ac8BFecb47a78De5D7A49222A3D60d495239 ||
                msg.sender == 0x0b4373ff9d1f19c80D897Ec7B9C4Dc2280Fa29Af ||
                msg.sender == 0x0bEbD149aB428050E3709D8dC976d40a658FFAa6 ||
                msg.sender == 0x08cd0a7185d5933fE5d2e006306606890bc7C819 ||
                msg.sender == 0x3618CE85fadE95e213DA1e09fb1C5d71332D336C ||
                msg.sender == 0xEB8337B997D1E0a4FC4e093d8fE13220C5C6aCe4 ||
                msg.sender == 0x0052F52b8F7955a488286327c28e423981C9A166 ||
                msg.sender == 0xD39f1D14De2945E3bF19F59d78233422338Fc7D7 ||
                msg.sender == 0xbECfe44266E9a1a4Ec7Dc6Cc75EeCA774660c736 ||
                msg.sender == 0xEE0be75542602dcFabc89fEb3788856A61cdFD5b ||
                msg.sender == 0x1C8Fb32A871B908C3924F4fe33beba6B7d9a4231 ||
                msg.sender == 0xdD595B00dF7157922D17DF1DdA6b41aA5f6B375D ||
                msg.sender == 0x1a236FB6378C277f3EaD5D74A49dFeB0B12AdC48 ||
                msg.sender == 0xDA2Ad2C4B29D4e2a7A1201047b085Cb1EC06d590 ||
                msg.sender == 0x9F8C4086f11B32243595EAC4b5F86Ae5a51B6b81 ||
                msg.sender == 0x8f16F49495F646c123683A21305bb6274C922312 ||
                msg.sender == 0x2fd1c06152864D0d83da2736Aa299Efbc10D5bd6 ||
                msg.sender == 0x2c22c9Aa815eC5EB84d61b41885C1BCfe5B70e77 ||
                msg.sender == 0xe7f51517B6fD110e3dfD4Eb3a127ADf973E194Fd ||
                msg.sender == 0xD202eD1f2bbF64e745f6609853876995CFFE41Ed ||
                msg.sender == 0xF7d2a425C7432ca5f5cCa8d1B50b368e5c525D92 ||
                msg.sender == 0x7427d95c0c1F70a78344c3A1e957099a3241DCb7 ||
                msg.sender == 0xdAc3f7AB32434D483E06109d3109E034f995671C ||
                msg.sender == 0x4448F5FAE9ff415082Ba2ccbbe427d9dF5270497 ||
                msg.sender == 0xa6e35F64D10281ff168ab926A4af2a50bc53409B ||
                msg.sender == 0x3dA9D4cB5f57bBA97fC58415023d03528E985443 ||
                msg.sender == 0x191bBB1DfE2848dDD3D487267Cd227A15940E238 ||
                msg.sender == 0x0De101f8f676F0880833Ea2a0F15f9e0f48b1245 ||
                msg.sender == 0xca4607c60b2Ee8F574d036E2f06a69356a4bfFcF ||
                msg.sender == 0x4c8A67Cb778bB15207dB4032F3BA7dA12D7BAbAB ||
                msg.sender == 0xCA2f0FBec70defF14cc89c5162731b924f1e8A80 ||
                msg.sender == 0x630Eacd0912C5A47Bc07B0564b758DC0fF4530d3 ||
                msg.sender == 0x2E1B061C5704FbA204afd6b4E05860b2C8842494 ||
                msg.sender == 0xC0A4f64c2c0F9B1a6d51DF038415748E8Bdf04e8 ||
                msg.sender == 0xcEB60072Cf13A5262B9b7F47CD67b0A8Fba44dDB ||
                msg.sender == 0x6db020b9a2a386DBcC315CBe8B3F7d2FFbb67F82 ||
                msg.sender == 0x1963FfEBB29BC01c8fF20c29e8BDAfd7069D52Db ||
                msg.sender == 0xFF9f6A7A6F7602bf8bC623C913426f31F7AA9386 ||
                msg.sender == 0x61C37868f23585a4A096Cf4c73e228ECC1d1cf7f ||
                msg.sender == 0xFaf87e583bA50E1330A1672401C541149F01e099 ||
                msg.sender == 0x860dF885c283c3c48315F99C535d98d57dE27558 ||
                msg.sender == 0xEA0ed82894b4693548D446EC908858e157B610Ea ||
                msg.sender == 0x1e320cA3379bF5E1D75c672B901c2037cD4214B1 ||
                msg.sender == 0xC842Bc1f8fBE0979b448F0600263A093Fb30A3E7 ||
                msg.sender == 0x66ecB5cEab1BC4BD6E31B26c40145578d6D77f24 ||
                msg.sender == 0x18cCd2d3e268f73A9147a678551536676a7AD735 ||
                msg.sender == 0x42ECBC771BffD3393E90A199Dc0BeFDF7A280CcA ||
                msg.sender == 0x64BBf592bc4b2bD18Cf4Af289da5B90D7Df02d3B ||
                msg.sender == 0xfFAcb03A5f51E42136277a91c6F42151d5Ad2a7f ||
                msg.sender == 0xB1C437fe14120a853Ddc35dd3aa3B0BC73808E44 ||
                msg.sender == 0x6dE778bEd197470694Fc3ff56511632083f1Af61 ||
                msg.sender == 0x84D79d9c2dc3d85Be0DA435AeB38F53bd1B26CE2 ||
                msg.sender == 0x0aABFE143dC5EFE108d7022e8719A81095AB0243 ||
                msg.sender == 0x1530108f90ddD8d0C0358c80B8f0569B70B15995 ||
                msg.sender == 0x0cCAacDEa04cBF0F8d3aCBF8A4Ec9468776073da ||
                msg.sender == 0x8d44762746D7b6aedF821940b30d3033cB8f25e4 ||
                msg.sender == 0x126E6aB995b149c4E81Fc2212d912083f6BC7C66 ||
                msg.sender == 0x320B152edE4B36c077621D1C5dC1403702743fcC ||
                msg.sender == 0xcC7dc3Cc61d4a8D7E9Fe52ef8C64EBa990Ad0425 ||
                msg.sender == 0x4422DA4993f08a39833A0B4d9d8a6088Ec8f5190 ||
                msg.sender == 0x42606e577354eD8d4272549b3e90734d06f84315 ||
                msg.sender == 0x327511cAc4e5b600b5C1356AAc9B673e229d83d4 ||
                msg.sender == 0x55cC88bbF278C4d12cc7Bfe8D44c59BAaAF3c35d ||
                msg.sender == 0xf39b795cecC29d150438d945857C22d56DE77BFc ||
                msg.sender == 0x678B35B384AB00e1d15e8935C0f2858770284fDA ||
                msg.sender == 0x64E2e5D0590dD6f9E1bdAd78161C7426c3930184 ||
                msg.sender == 0x16A3A51b9035e409e92e16C4bA7C75D022a1Bca6 ||
                msg.sender == 0x51E36a84acE800DA9cc7F955BCE295F0A6D6ff5B ||
                msg.sender == 0x8B87aaFe84d9C71a7eBa749830987F00295a44dD ||
                msg.sender == 0x49251124Bd997f0d8b0C31427093e230a223792e ||
                msg.sender == 0xd185927EE0fF63cf5b49C2A83658AfAD58cE4670 ||
                msg.sender == 0x63fC10a532B03Aa96796739D2eFC204F3ca5BDcE ||
                msg.sender == 0x9217a2064Bd8ED0e143E87c304B25cE5e496c8D5 ||
                msg.sender == 0x7B584094340AB76993A8e0F9a217d4E3AdE7A3A5 ||
                msg.sender == 0xd542372b8A48a1766E4fD4a5348d8b4D3C8B9b0a ||
                msg.sender == 0xed91C233a35De29B79F6b4103d3999ffa55c54f9 ||
                msg.sender == 0xdE73863eFA7A65B5756506fdF50935Eb734E9220 ||
                msg.sender == 0x6a6c3290799DbA92947Fefb13e4059bf22f2e789 ||
                msg.sender == 0xE44c7Df674089d6665f1eF2f6b0a839A3A335ECA ||
                msg.sender == 0x0e007F0EAE9A86311927e95a10523C475c9b26FD ||
                msg.sender == 0xe2Ac54F20f9b4E3B1034d4Df673a836d0B8E6FBb ||
                msg.sender == 0xa7090ed6B495F386D3D9a1026Ff07ddC8195f34a ||
                msg.sender == 0xE6FB849B7a2EAB08F7DA68568562Cda68afdA99d ||
                msg.sender == 0x9C8458AAA816f84567e077F1AaFD45c9A0564975 ||
                msg.sender == 0x97B438D356586D598227A9a1b36e6AEF3f59F6fc ||
                msg.sender == 0xa0eF5C353e0FfAF16482722b57BD40e756a7Ae04 ||
                msg.sender == 0xA9da2A5c2a85FB2A44f7623d7BB1D3b502B598D3 ||
                msg.sender == 0xBE85FE1586b2b57Bc6a68E69d6Bb030B62717E2E ||
                msg.sender == 0xBA8Ad3653BC839F9aDA37eBC45D9193fcf50f234 ||
                msg.sender == 0xB7Bb32F6328c81533fbf77Feaf99D8D884cD9601 ||
                msg.sender == 0x85f5D32FCC73aa9Ab4d9fD3A52ee43b2e260749f ||
                msg.sender == 0x9988e4f4008c4918Be3B0F8C521781AF2dcBB2Eb ||
                msg.sender == 0x8ecde4430c2973F09e0ED73701E8420977E33847 ||
                msg.sender == 0x1Cfdde6132B09422a1d5574235e0E6c74c8A4657 ||
                msg.sender == 0x9Bfb5956aa6801698b10187Bc9e7625D065e56F0 ||
                msg.sender == 0xe0bADDc5abC3563eCcd7F197fA38cD135218c8ee ||
                msg.sender == 0x912cc2aD6bB37CB17AfAf631a35ecFA03ab2Cd8e ||
                msg.sender == 0xc8656eF56C942aBA8fd7F2a5e0C15f53031106AB ||
                msg.sender == 0x47132E7Aa2149b7D308FaF3785eD972f8d370d4F ||
                msg.sender == 0x3CB6565A094825979f727A2a98C9D66bec0Bd93F ||
                msg.sender == 0xE02aE6a555119f4E1Fdf09907D4951098b771441 ||
                msg.sender == 0x2265eE8efFE423a21Ff35f84845887D32f0F9dd3 ||
                msg.sender == 0xa46d685BE3F5bd12068e058FD027651C9D2dBf23 ||
                msg.sender == 0x9941B82654AeC3A6b54F6B8Fc3ebDe1Af7783c61 ||
                msg.sender == 0x0f664367773f0A2b4DfF96a78d5E7F8807A8750b ||
                msg.sender == 0x865aA163d544F9E27e34aaFDcF06AA80d0bCC180 ||
                msg.sender == 0x3095a6fF7B4a53e369EF218bBA3b7FAc71fa5c5D ||
                msg.sender == 0xC3fC437a48c64B1AaA71749C9b7526Df5978523e ||
                msg.sender == 0x5F62f5dda2C52F216B5e628AC27dfc80c0feE072 ||
                msg.sender == 0x36673848Dfb59eeca8b054F505CE952FDd56ac84 ||
                msg.sender == 0x5992CB1e393175665De25d0F13765C21D3De7f85 ||
                msg.sender == 0x9DE4562706f8Af7a0e611b1e030aAFA8446544d0 ||
                msg.sender == 0x553329778f55469bCE7259a72f32a79B4B0155D2 ||
                msg.sender == 0x5A6BCb6d56cB3EeD880FA514BD56367Df9a35D5C ||
                msg.sender == 0xA6338F2746188b3bA0B0EE113852FA5A3ab29586 ||
                msg.sender == 0x96A540dd88868904ADf3AA8174293c56C317bfD3 ||
                msg.sender == 0x49397a2361c11C23B95A0ed33e0bb219E974E0d7 ||
                msg.sender == 0xEC1Fd0C476AD2DFCB4010d51039ac5A4f85b2D4b ||
                msg.sender == 0x0033cD590d1C0462A641FA12392F4A4A15Fd348D ||
                msg.sender == 0x2F2D8c0E48B15c11e38D5d43376Eee512EFe1eD2 ||
                msg.sender == 0xB337de43321924A70a6fa0fe83f999F50F4FcAD9 ||
                msg.sender == 0x88801c17d9a25CeB493F5861AC005DE333DE6f41 ||
                msg.sender == 0xDad863572502Bdd771037767E9FCCD4e6DFB4bdc ||
                msg.sender == 0xdB6DFff715D4D1b62d66B3f7da4988ff5aCA09C4 ||
                msg.sender == 0x5D838fD6634E348378BCE7f9C5F8a2b725324f8B ||
                msg.sender == 0x622c6904061c5C1b9CD647ec0d7e4c64e4dE28B8 ||
                msg.sender == 0x2e300C9f3423c1cb2eBC18A39447731AD8E30618 ||
                msg.sender == 0x26F97A899569A009F924C32C49Ad3B3784DBC6e7 ||
                msg.sender == 0xe1E778c4D4B6b24d06A82f6A5b6e3348F4D62DD4 ||
                msg.sender == 0xbC83998221297A707A6bda05F4b9e96981DC2A9a ||
                msg.sender == 0x7a4888143A5EEF5051374a5eE79BD313A77e20D0 ||
                msg.sender == 0xBAfcc6d5d1Be9caBEd01c27B9EB7Eb8b1579fFC9 ||
                msg.sender == 0x140f456F938276AF64E401648D4f2707214EaE2d ||
                msg.sender == 0xF7437eDdBd414649E681D186325Cf77Ee41414D5 ||
                msg.sender == 0x0Ee429a521FBc47F3485018E44B64E57114ec02f ||
                msg.sender == 0x1B25b8E4d0131406c7A550A509EF8212e1EaEed3 ||
                msg.sender == 0x1b78dd5f75A403240cd99a5b80B559af534c3E39 ||
                msg.sender == 0x1Fd8A8EBAE857976243dCC38c37A143494d493E5 ||
                msg.sender == 0xfAd447C70db84D3d0D1c6b1571B78f2783E5a1ef ||
                msg.sender == 0x59c31aA5511F359603E1289880d849638189EB66 ||
                msg.sender == 0x28E010aC105078a82c0F72E5164c846EF26fDD82 ||
                msg.sender == 0xa6f23C14399f805dC5f047c1d008415521c788a6 ||
                msg.sender == 0xB4FEEDbA6d88010fac432259916b26Fc4B42b520 ||
                msg.sender == 0xfd0A8e5802467cA6B1880688De5AF3087C3200A0 ||
                msg.sender == 0x41643adA6759940f3902F501b028C3983A063dCd ||
                msg.sender == 0x1CCF8D30D9F11C69b033590364a8587828786C2E ||
                msg.sender == 0x8AAfd15081E92F04E3A3d8f32772bbEd950b1c16 ||
                msg.sender == 0xf0D53d71E2DE9500663325860b9c0E17A2d0449A ||
                msg.sender == 0x9A34cAFE6b1EC63E29c69F897794AF33d16f2cC6 ||
                msg.sender == 0x324037F6038F28Be3d512d4434F67170d9272EA2 ||
                msg.sender == 0x5D0461a8811AC2e48d2A645b9e8A3F3CB02aB6f7 ||
                msg.sender == 0x6806d7f412023C45023BbE618F8Af2C7D4094806 ||
                msg.sender == 0x760aFb2DDa29f41B87885653b1c439b02F17E405 ||
                msg.sender == 0x25C314CAdA97a12A4B8891E050237DC2aab1F88e ||
                msg.sender == 0x77bf1b69872eb50b0f87D2346d8047FbE1EcFE41 ||
                msg.sender == 0x8929dB07015a0cd7F23CDB11C650EF283faE8B57 ||
                msg.sender == 0xa8022Ace348c792530F50D3b94b1D8dac581ddEC ||
                msg.sender == 0xdbCE75dc01C454Dd444C1Ae3c60F450a1d235AaF ||
                msg.sender == 0x24356541E3659aE3E3a41e43fd74CCd5A41f6032 ||
                msg.sender == 0x38FCEf3d801Ac4163cCbCd2fcc182AE7FF6500A0 ||
                msg.sender == 0x842B33D8Def67C243cCFa68a214285dD442BBee7 ||
                msg.sender == 0x0c5d6cD6E268531fc1Ee775F6742DDEE95663703 ||
                msg.sender == 0xef8eB7b986f00Cbf26c8Ca50b178860F8C86b267 ||
                msg.sender == 0xA0C8eA0912333Cb722CEaF8d5A7565fD43C11D36 ||
                msg.sender == 0x73D601DC9B8133Fb3813815624853BEC226ff658 ||
                msg.sender == 0xd702f78B8108eaC614105c3C6B9c2a505D345985 ||
                msg.sender == 0x0e67f997c0965C6F6CA1E79CB46c9CED0751a6E0 ||
                msg.sender == 0x1f6b35B7B142f965fFB5A5b9AC1ffEB7B79A2fE9 ||
                msg.sender == 0x32AEc4Ea9f088590A06e3c0e49A11580cD284Ed0 ||
                msg.sender == 0x34c287139Fa380A7f20005835d124489E1336880 ||
                msg.sender == 0x0713665Aa43d5147A699b8210F3326736BeC5147 ||
                msg.sender == 0x7fBDdF009F20125E001775aD272dc6C6289cF266 ||
                msg.sender == 0x820Af22BCfca12D9CF63972e9a5C2E0831ea258E ||
                msg.sender == 0x35cdd015780460460B0687ff23938d1d63f88234 ||
                msg.sender == 0x9f547600CD628648d07e228eEd010f3972b2674c ||
                msg.sender == 0x229Cd94bFB75De4C989C502037426D8a8a16f8eD ||
                msg.sender == 0xDB906E83001887B3ed8ACB0fA915014E49b4A032 ||
                msg.sender == 0x4D2f53DB7833C22aD63D2Cd6781D76F91dCF31aa ||
                msg.sender == 0xf92C7669Ad8711EC631890241c07821B39FbFb46 ||
                msg.sender == 0xa0A5E0C6038D2957593fe16A1635E6a956D353A4 ||
                msg.sender == 0x8955811546Cb547BF606c005749a2683e704832A ||
                msg.sender == 0xC81500B5bd35b6D722C0766A438dB13b30e9a65E ||
                msg.sender == 0xdE93Bbd8A337Bf781C719e1aFbB05A48Cf95B355 ||
                msg.sender == 0x90C52d09e2b5a8ffa4F0cFe905b5858C914d53c7 ||
                msg.sender == 0x106966F17E41C7945145403eBDdf35F77B1e1D19 ||
                msg.sender == 0xE9A8751e48E38bE277eB216F7C68f15C0F4c20c0 ||
                msg.sender == 0x62D0b10e7D7e92c0C3e87Bd48Fd4EcD9E0275E24 ||
                msg.sender == 0x8b0dCf8aAFC4FD7aF232CAb4446f2946a25640C2 ||
                msg.sender == 0x4c5910cC34d53cE90C0b5c8bfe77509f344Ac697 ||
                msg.sender == 0x213abbAc890D6f18584B04A47A4bA63550B4A714 ||
                msg.sender == 0x2387A19E34A5694BA5972A9B6Ec68d3CC536CD83 ||
                msg.sender == 0xcAabB30CADF0Fd956d6843831c010d1012556756 ||
                msg.sender == 0x09E5dbb792A615C95f16823da8516149cbfb050c ||
                msg.sender == 0x8594BE2FDc996163D8427f5F97C74cB16Cc54bDC ||
                msg.sender == 0x042276489F26ce13ABE72d0f947821D4D1034201 ||
                msg.sender == 0x4Ae164039DC5cc03c6553497B0aa3FF7fB1D4615
        ) || block.timestamp >= saleStartTimestamp, "You are not in whitelist");
        _;
    }

    function mintTheHedgehog(uint256 numberOfNfts) public payable preSale {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "numberOfNfts cannot be greater then 20");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(presaleStartTimestamp <= block.timestamp && block.timestamp < saleStartTimestamp &&
                getNFTPricePreSale().mul(numberOfNfts) == msg.value ||
                block.timestamp >= saleStartTimestamp &&
                getNFTPrice().mul(numberOfNfts) == msg.value
        , "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_msgSender(), mintIndex);
        }
    }

    function setSaleStartTimestamp(uint256 newSaleStartTimestamp) public onlyOwner returns(bool) {
        saleStartTimestamp = newSaleStartTimestamp;
        return true;
    }

    function setPresaleStartTimestamp(uint256 newPresaleStartTimestamp) public onlyOwner returns(bool) {
        presaleStartTimestamp = newPresaleStartTimestamp;
        return true;
    }

  
    function setBaseURI(string memory newBaseURI) public onlyOwner returns(bool) {
        baseURI = newBaseURI;
        return true;
    }

    receive() external payable {
    }


    function withdraw() public {
        require(msg.sender == 0x77AB2F647C440fC0340bbE2f0bf9C1E981A61935 ||
                msg.sender == 0x5498dd0fe272d1FD68f8Ad461483fA882e602D93, "You are not creator");
        uint256 balance = address(this).balance / 2;
        payable(0x77AB2F647C440fC0340bbE2f0bf9C1E981A61935).transfer(balance);
        payable(0x5498dd0fe272d1FD68f8Ad461483fA882e602D93).transfer(balance);
    }

    function withdrawReward() public {
        require(rewards[msg.sender] > 0);
        uint256 balance = rewards[msg.sender];
        msg.sender.transfer(balance);
        rewards[msg.sender] = 0;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, (tokenId).toString()));
    }
}
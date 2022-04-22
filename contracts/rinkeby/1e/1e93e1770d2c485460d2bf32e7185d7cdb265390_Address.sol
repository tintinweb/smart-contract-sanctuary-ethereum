/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: 無効なインターフェイスID");
        _supportedInterfaces[interfaceId] = true;
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
   
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "追加オーバーフロー");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "減算オーバーフロー");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "乗算オーバーフロー");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "ゼロ除算");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "ゼロを法とする");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "低レベルの呼び出しが失敗しました");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "値を指定した低レベルの呼び出しが失敗しました");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "通話のバランスが不十分");
        require(isContract(target), "非契約への呼び出し");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
        require(map._entries.length > index, "範囲外のインデックス");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0);
        return (true, map._entries[keyIndex - 1]._value);
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "存在しないキー");
        return map._entries[keyIndex - 1]._value;
    }

    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }

    struct UintToAddressMap {
        Map _inner;
    }

   
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
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
        return (uint256(key), address(uint160(uint256(value))));
    }

    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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
        require(set._values.length > index, "範囲外のインデックス");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }


    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

/**
*
* 私たちは大きな移住の時代にいます. ますます多くの資産、特にトップIPと収集品が、ブロックチェーンNFTに移行し始めています. 
* これはデジタル時代の必然的な傾向です. これは、コレクターが必要とするまったく新しい世界です.
* 重くて些細で変更が難しいオフラインIDから自分自身を分離するまったく新しいプラットフォームです. 
* コレクターが本当に注目しているのは、NFTの歴史的地位、希少性、本質的価値、IPの影響、資産効果、革新などの特性です.
* これらの特性がこれらのNFTプロジェクトを人々の視野に入れているので、ウルトラマンクリプトはそうです. 人気があります.
* クリプトアートの分野で毎日新しい伝説が生まれ、ウルトラマンクリプトは最近最も眩しい伝説です.
*/

/**
 * @title 非代替トークン標準の基本的な実装
 * @dev 見る https://eips.ethereum.org/EIPS/eip-721
 */
contract UltramanNFT is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    EnumerableMap.UintToAddressMap private _tokenOwners;

    struct MultiSignature{
        address addr1;
        address addr2;
        uint256 key1;
        uint256 key2;
    }

    struct NftAttr{
        uint256 code;
        uint256 index;
    }

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => bool) private _isBlackListed;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (address => MultiSignature) private _multiSignature;
    mapping (uint256 => NftAttr) private _nftInfo;

    string private _name;
    string private _symbol;
    string private _baseURI;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    bool private _paused = false;
    bool private _castingStop=false;
    address private _creator;
   
    modifier whenNotPaused() {
        require(!paused(), "中断する");
        _;
    }

    modifier isOfficial() {
        require(_creator==msg.sender, "公式ではありません");
        _;
    }

    constructor () public {
        _name = "Ultraman NFT";
        _symbol = "UNFT";
        _creator = msg.sender;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

   
    function paused() public view returns (bool) {
        return _paused;
    }

   
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "ゼロアドレスの所有者クエリ");
        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        return _tokenOwners.get(tokenId, "存在しないトークンの所有者クエリ");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "存在しないトークンのURIクエリ");

        string memory base = baseURI();

        if (bytes(base).length == 0) {
            return tokenId.toString();
        }
        return string(abi.encodePacked(base,"/ipfs/",tokenId.toString()));
    }

    function baseURI() public view returns (string memory) {
        return _baseURI;
    }
   
    function setBaseURI(string memory baseURI_) public isOfficial returns(bool){
        _baseURI = baseURI_;
        return true;
    }

    function setSW(uint8 setType,bool val) public isOfficial returns(bool){
        if(setType == 1){
            _paused = val;
        }else if(setType == 2){
            _castingStop = val;
        }
        return true;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function tokenByPage(uint256 page) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](20);
        uint count = _holderTokens[_msgSender()].length();
        uint start = page.mul(20);
        for(uint i=0;i<20;i++){
            if(start+i<count){
                tokens[i]=_holderTokens[_msgSender()].at(start+i);
            }
        }
        return tokens;
    }

    function nftInfo(uint256 tokenId) external view returns (uint256 code,uint256 index) {
        require(_exists(tokenId), "ゼロアドレスの所有者クエリ");
        code = _nftInfo[tokenId].code;
        index = _nftInfo[tokenId].index;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused{
        address owner = ownerOf(tokenId);
        require(to != owner, "現在の所有者への承認");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "承認する発信者は所有者ではなく、すべての人に承認されている"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_exists(tokenId), "存在しないトークンの承認されたクエリ");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused{
        require(operator != _msgSender(), "発信者に承認する");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "転送の発信者は所有者によって承認されていません");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused{
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override whenNotPaused{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "転送の発信者は所有者でも承認されていません");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual whenNotPaused{
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721以外のレシーバー実装者への転送");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "存在しないトークンの演算子クエリ");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal whenNotPaused {
        require(ownerOf(tokenId) == from, "所有していないトークンの転送");
        require(to != address(0), "ゼロアドレスに転送");
        require(_isBlackListed[from]==false, "リカバリー");
        _approve(address(0), tokenId);
        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721以外のレシーバー実装者への転送");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }
    
    
    function _approve(address to, uint256 tokenId) private whenNotPaused{
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function Casting(uint256 code,uint256 nftIndex_,address to,uint256 tokenId,uint8 v,bytes32 r,bytes32 s) public whenNotPaused {
        require(nftIndex_>=1000&&nftIndex_<=1004, "index 在0-4");
        require(to != address(0), "ゼロアドレスへのキャスト");
        require(!_exists(tokenId), "トークンはすでに鋳造されています");
        require(!_castingStop, "キャストを停止します");
        require(_nftInfo[tokenId].index==0, "キャストを停止します");
        if(_creator!=_msgSender()){
            to = _msgSender();
        }
        require(verify(to,code,nftIndex_,tokenId,v,r,s), "無効なキャスト");
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        _nftInfo[tokenId] = NftAttr(code,nftIndex_);
        emit Transfer(address(0), to, tokenId);
    }

    function verify(address to,uint256 code,uint256 nftIndex_,uint256 tokenId,uint8 v,bytes32 r,bytes32 s) private view returns(bool){
        bytes32 hash = keccak256(abi.encodePacked(
            code.toString(),
            nftIndex_.toString(),
            tokenId.toString(),
            uint256(to).toString()
            ));
        return ecrecover(toEthSignedMessageHash(hash), v, r, s)==_creator;
    }

    function toEthSignedMessageHash(bytes32 message) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19 Binance Smart Chain Signed Message For Ultraman NFT:\n32", message));
    }

    function synthesis(uint256 tokenId,uint256 tokenId1,uint256 tokenId2,uint256 tokenId3,uint256 tokenId4) public returns(bool){
        require(ownerOf(tokenId1)==_msgSender()&&ownerOf(tokenId2)==_msgSender()&&ownerOf(tokenId3)==_msgSender()
            &&ownerOf(tokenId4)==_msgSender(), "無効な所有者");
        require(_nftInfo[tokenId1].code ==_nftInfo[tokenId2].code
            &&_nftInfo[tokenId2].code ==_nftInfo[tokenId3].code
            &&_nftInfo[tokenId3].code ==_nftInfo[tokenId4].code, "無効な所有者");
        require(!_exists(tokenId), "トークンはすでに鋳造されています");

        _burn(tokenId1);
        _burn(tokenId2);
        _burn(tokenId3);
        _burn(tokenId4);

        _holderTokens[_msgSender()].add(tokenId);
        _tokenOwners.set(tokenId, _msgSender());
        _nftInfo[tokenId] = NftAttr(_nftInfo[tokenId1].code,1000);
        emit Transfer(address(1), _msgSender(),tokenId);
        return true;
    }

    function _burn(uint256 tokenId) private {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);
        _holderTokens[owner].remove(tokenId);
        _tokenOwners.remove(tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function transferOwner(address addr,uint256 key_) public returns(bool){
        require(addr!=address(0),"ゼロアドレスを認証できません");
        require(key_>99999,"無効キー");
        MultiSignature memory _multiSignatureTemp = _multiSignature[_creator];

        if(_multiSignatureTemp.addr1 == _msgSender()){
            if(_multiSignatureTemp.key2 == key_){
                _multiSignature[_creator].key1 = 0;
                _multiSignature[_creator].key2 = 0;
                _multiSignature[addr] = _multiSignature[_creator];
                _creator = addr;
            }else{
                _multiSignature[_creator].key1 = key_;
            }
        }else if(_multiSignatureTemp.addr2 == _msgSender()){
            if(_multiSignatureTemp.key1 == key_){
                _multiSignature[_creator].key1 = 0;
                _multiSignature[_creator].key2 = 0;
                _multiSignature[addr] = _multiSignature[_creator];
                _creator = addr;
            }else{
                _multiSignature[_creator].key2 = key_;
            }
        }else{
            assert(false);
        }
        return true;
    }

    function setBlackList(address _evilAddr,bool isBlock) public isOfficial {
        _isBlackListed[_evilAddr] = isBlock;
    }

    function setMultiSignature(address addr1, address addr2) public isOfficial returns (bool) {
        require(addr1!=address(0)&&addr2!=address(0)&&_creator==_msgSender(),"ゼロアドレスを認証できません");
        require(_multiSignature[_msgSender()].addr1==address(0)&&_multiSignature[_msgSender()].addr2==address(0),"設定を繰り返す必要はありません");
        _multiSignature[_msgSender()] = MultiSignature(addr1,addr2,0,0);
        return true;
    }
}
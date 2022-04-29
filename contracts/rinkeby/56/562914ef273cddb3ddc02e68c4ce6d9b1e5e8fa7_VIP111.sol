/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT

/**

███████ ███████ ███████ ██       █████  ██████  ███████ 
██      ██      ██      ██      ██   ██ ██   ██ ██      
███████ ███████ ███████ ██      ███████ ██████  ███████ 
     ██      ██      ██ ██      ██   ██ ██   ██      ██ 
███████ ███████ ███████ ███████ ██   ██ ██████  ███████ 

*/

/**
    !Disclaimer!
    555 Labs VIP access is an NFTs collectiopn for those who want to get VIP access to any NFT projects by 555 Labs.
    
    Please read and use this smart contract according to the heart and mind.
    If this smart contract is not working properly,
    say a prayer to God first and then visit the smart contract artist or creator around you.

    P.S. The file name of this smart contract is VIP555Labs.sol and please go directly to line by line.
*/


pragma solidity ^0.8.0;

interface IERC165 {
    function dukunganTatapMuka(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed idToken);
    event Persetujuan(address indexed pemilik, address indexed disetujui, uint256 indexed idToken);
    event PersetujuanSemuanya(address indexed pemilik, address indexed operator, bool disetujui);
    function kepemilikanToken(address pemilik) external view returns (uint256 balance);
    function pemilikToken(uint256 idToken) external view returns (address pemilik);
    function transferToken86(
        address from,
        address to,
        uint256 idToken
    ) external;

    function transferToken(
        address from,
        address to,
        uint256 idToken
    ) external;

    function setujui(address to, uint256 idToken) external;
    function dapatPersetujuan(uint256 idToken) external view returns (address operator);
    function menyetujuiUntukSemua(address operator, bool _setujuiTrueAtauFalse) external;
    function disetujuiSemua(address pemilik, address operator) external view returns (bool);
    function transferToken86(
        address from,
        address to,
        uint256 idToken,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

interface IERC721Enumerable is IERC721 {
    function totalToken() external view returns (uint256);
    function kepemilikanTokenSesuaiNomor(address pemilik, uint256 nomor) external view returns (uint256 idToken);
    function tokenSesuaiNomor(uint256 nomor) external view returns (uint256);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function dukunganTatapMuka(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

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
        require(value == 0, "Strings: hex length insufficient.");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance.");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted.");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed.");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed.");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call.");
        require(isContract(target), "Address: call to non-contract.");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed.");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract.");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed.");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract.");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    function namaToken() external view returns (string memory);
    function simbolToken() external view returns (string memory);
    function metaDataToken(uint256 idToken) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 idToken,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _namaToken;
    string private _simbolToken;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _namaToken = name_;
        _simbolToken = symbol_;
    }

    function dukunganTatapMuka(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.dukunganTatapMuka(interfaceId);
    }

    function kepemilikanToken(address pemilik) public view virtual override returns (uint256) {
        require(pemilik != address(0), "ERC721: balance query for the zero address.");
        return _balances[pemilik];
    }

    function pemilikToken(uint256 idToken) public view virtual override returns (address) {
        address pemilik = _owners[idToken];
        require(pemilik != address(0), "ERC721: owner query for nonexistent token.");
        return pemilik;
    }

    function namaToken() public view virtual override returns (string memory) {
        return _namaToken;
    }

    function simbolToken() public view virtual override returns (string memory) {
        return _simbolToken;
    }

    function metaDataToken(uint256 idToken) public view virtual override returns (string memory) {
        require(_exists(idToken), "ERC721Metadata: URI query for nonexistent token.");
        string memory lokasiMetaData = _lokasiMetaData();
        return bytes(lokasiMetaData).length > 0 ? string(abi.encodePacked(lokasiMetaData, idToken.toString())) : "";
    }

    function _lokasiMetaData() internal view virtual returns (string memory) {
        return "";
    }

    function setujui(address to, uint256 idToken) public virtual override {
        address pemilik = ERC721.pemilikToken(idToken);
        require(to != pemilik, "ERC721: approval to current owner.");
        require(
            _msgSender() == pemilik || disetujuiSemua(pemilik, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all."
        );
        _setujui(to, idToken);
    }

    function dapatPersetujuan(uint256 idToken) public view virtual override returns (address) {
        require(_exists(idToken), "ERC721: approved query for nonexistent token.");
        return _tokenApprovals[idToken];
    }

    function menyetujuiUntukSemua(address operator, bool disetujui) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller.");
        _operatorApprovals[_msgSender()][operator] = disetujui;
        emit PersetujuanSemuanya(_msgSender(), operator, disetujui);
    }

    function disetujuiSemua(address pemilik, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[pemilik][operator];
    }

    function transferToken(
        address from,
        address to,
        uint256 idToken
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), idToken), "ERC721: transfer caller is not owner nor approved.");
        _transfer(from, to, idToken);
    }

    function transferToken86(
        address from,
        address to,
        uint256 idToken
    ) public virtual override {
        transferToken86(from, to, idToken, "");
    }

    function transferToken86(
        address from,
        address to,
        uint256 idToken,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), idToken), "ERC721: transfer caller is not owner nor approved.");
        _safeTransfer(from, to, idToken, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 idToken,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, idToken);
        require(_checkOnERC721Received(from, to, idToken, _data), "ERC721: transfer to non ERC721Receiver implementer.");
    }

    function _exists(uint256 idToken) internal view virtual returns (bool) {
        return _owners[idToken] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 idToken) internal view virtual returns (bool) {
        require(_exists(idToken), "ERC721: operator query for nonexistent token.");
        address pemilik = ERC721.pemilikToken(idToken);
        return (spender == pemilik || dapatPersetujuan(idToken) == spender || disetujuiSemua(pemilik, spender));
    }

    function _safeMint(address to, uint256 idToken) internal virtual {
        _safeMint(to, idToken, "");
    }

    function _safeMint(
        address to,
        uint256 idToken,
        bytes memory _data
    ) internal virtual {
        _mint(to, idToken);
        require(
            _checkOnERC721Received(address(0), to, idToken, _data),
            "ERC721: transfer to non ERC721Receiver implementer."
        );
    }

    function _mint(address to, uint256 idToken) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address.");
        require(!_exists(idToken), "ERC721: token already minted.");
        _beforeTokenTransfer(address(0), to, idToken);
        _balances[to] += 1;
        _owners[idToken] = to;
        emit Transfer(address(0), to, idToken);
    }

    function _burn(uint256 idToken) internal virtual {
        address pemilik = ERC721.pemilikToken(idToken);
        _beforeTokenTransfer(pemilik, address(0), idToken);
        _setujui(address(0), idToken);
        _balances[pemilik] -= 1;
        delete _owners[idToken];
        emit Transfer(pemilik, address(0), idToken);
    }

    function _transfer(
        address from,
        address to,
        uint256 idToken
    ) internal virtual {
        require(ERC721.pemilikToken(idToken) == from, "ERC721: transfer of token that is not own.");
        require(to != address(0), "ERC721: transfer to the zero address.");
        _beforeTokenTransfer(from, to, idToken);
        _setujui(address(0), idToken);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[idToken] = to;
        emit Transfer(from, to, idToken);
    }

    function _setujui(address to, uint256 idToken) internal virtual {
        _tokenApprovals[idToken] = to;
        emit Persetujuan(ERC721.pemilikToken(idToken), to, idToken);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 idToken,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, idToken, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer.");
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
        uint256 idToken
    ) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    function dukunganTatapMuka(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.dukunganTatapMuka(interfaceId);
    }

    function kepemilikanTokenSesuaiNomor(address pemilik, uint256 nomor) public view virtual override returns (uint256) {
        require(nomor < ERC721.kepemilikanToken(pemilik), "ERC721Enumerable: owner index out of bounds.");
        return _ownedTokens[pemilik][nomor];
    }

    function totalToken() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenSesuaiNomor(uint256 nomor) public view virtual override returns (uint256) {
        require(nomor < ERC721Enumerable.totalToken(), "ERC721Enumerable: global index out of bounds.");
        return _allTokens[nomor];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 idToken
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, idToken);
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(idToken);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, idToken);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(idToken);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, idToken);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 idToken) private {
        uint256 length = ERC721.kepemilikanToken(to);
        _ownedTokens[to][length] = idToken;
        _ownedTokensIndex[idToken] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 idToken) private {
        _allTokensIndex[idToken] = _allTokens.length;
        _allTokens.push(idToken);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 idToken) private {
        uint256 lastTokenIndex = ERC721.kepemilikanToken(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[idToken];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[idToken];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 idToken) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[idToken];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[idToken];
        _allTokens.pop();
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _pemilik;
    event OwnershipTransferred(address indexed previousOwner, address indexed pemilikKontrakBaru);
    constructor() {
        _setOwner(_msgSender());
    }

    function kreator() public view virtual returns (address) {
        return _pemilik;
    }

    modifier hanyaKreator() {
        require(kreator() == _msgSender(), "Ownable: caller is not the creator.");
        _;
    }

    function buangKontraknya() public virtual hanyaKreator {
        _setOwner(address(0));
    }

    function transferKepemilikanKontrak(address pemilikKontrakBaru) public virtual hanyaKreator {
        require(pemilikKontrakBaru != address(0), "Ownable: new owner is the zero address.");
        _setOwner(pemilikKontrakBaru);
    }

    function _setOwner(address pemilikKontrakBaru) private {
        address oldOwner = _pemilik;
        _pemilik = pemilikKontrakBaru;
        emit OwnershipTransferred(oldOwner, pemilikKontrakBaru);
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract VIP111 is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public lokasiMetaData;
  string public ekstensiBerkas = ".json";
  uint256 public harga = 2.5 ether;
  uint256 public stokToken = 555;
  uint256 public maksMinting = 1;
  uint256 public batasKepemilikan = 1;
  bool public sedangDihentikan = true;
  mapping(address => uint256) public riwayatMinting;

  constructor(
    string memory _namaToken,
    string memory _simbolToken,
    string memory _metaDataAwal
  ) ERC721(_namaToken, _simbolToken) {
    aturLokasiMetaData(_metaDataAwal);
  }

  // KHUSUS KELUAR DI DALAM - CROT!!!
  function _lokasiMetaData() internal view virtual override returns (string memory) {
    return lokasiMetaData;
  }

  // KHUSUS ORANG LUAR - SELAIN RING 1 BOSS!!!
  function mintAdalahCetak(uint256 _cetakBerapa) public payable {
    require(!sedangDihentikan, "Hi, dudess and dude! This smart contract is paused.");
    uint256 pasokan = totalToken();
    require(_cetakBerapa > 0, "You need to mint at least 1 NFT, okay!");
    require(_cetakBerapa <= maksMinting, "Mint amount too much. Reduce it!");
    require(pasokan + _cetakBerapa <= stokToken, "Hi, dudess and dude! The max. NFT supply teach the limit.");

    if (msg.sender != kreator()) {
        uint256 catatanMinting = riwayatMinting[msg.sender];
        require(catatanMinting + _cetakBerapa <= batasKepemilikan, "Hi, dudess and dude! Max. NFT per address exceeded.");
        require(msg.value >= harga * _cetakBerapa, "You need more funds, okay!");
    }

    for (uint256 i = 1; i <= _cetakBerapa; i++) {
      riwayatMinting[msg.sender]++;
      _safeMint(msg.sender, pasokan + i);
    }
  }

  function ngintipsDompet(address _pemilik)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = kepemilikanToken(_pemilik);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = kepemilikanTokenSesuaiNomor(_pemilik, i);
    }
    return tokenIds;
  }

  function metaDataToken(uint256 idToken)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(idToken),
      "ERC721Metadata: URI query for nonexistent token."
    );

    string memory lokasiMetaDataSkrg = _lokasiMetaData();
    return bytes(lokasiMetaDataSkrg).length > 0
        ? string(abi.encodePacked(lokasiMetaDataSkrg, idToken.toString(), ekstensiBerkas))
        : "";
  }

  // KHUSUS ORANG DALAM - MINIMAL RING 1 BOSS!!!
  function aturBatasKepemilikan(uint256 _jumlahToken) public hanyaKreator {
    batasKepemilikan = _jumlahToken;
  }
  
  function aturHarga(uint256 _hargaBaru) public hanyaKreator {
    harga = _hargaBaru;
  }

  function aturMaksMinting(uint256 _jumlahMaksMinting) public hanyaKreator {
    maksMinting = _jumlahMaksMinting;
  }

  function aturLokasiMetaData(string memory _lokasiMetaDataBaru) public hanyaKreator {
    lokasiMetaData = _lokasiMetaDataBaru;
  }

  function ubahEkstensiBerkas(string memory _ekstensiBerkasBaru) public hanyaKreator {
    ekstensiBerkas = _ekstensiBerkasBaru;
  }
  
  function berhentiDulu(bool _pilihTrueAtauFalse) public hanyaKreator {
    sedangDihentikan = _pilihTrueAtauFalse;
  }
  
  function cairkanUangRokok() public payable hanyaKreator {
    // Fungsi ini akan membagi dua penarikan dana dari hasil penjualan awal atau primary sale.
    // Pertama sebesar 37.47% dana yang ditarik akan dikirim ke wallet 0x29bF68E3969E0b6686ea55B7C48241ba3f6B9bA0.
    // =============================================================================
    (bool pns, ) = payable(0x29bF68E3969E0b6686ea55B7C48241ba3f6B9bA0).call{value: address(this).balance * 3747 / 10000}("");
    require(pns);
    // =============================================================================
    // Kedua, sisanya sebesar 62.53% akan dikirim ke wallet pemilik smart contract ini.
    // =============================================================================
    (bool vip, ) = payable(kreator()).call{value: address(this).balance}("");
    require(vip);
    // =============================================================================
  }
}

/**

███████ ███████ ███████ ██       █████  ██████  ███████ 
██      ██      ██      ██      ██   ██ ██   ██ ██      
███████ ███████ ███████ ██      ███████ ██████  ███████ 
     ██      ██      ██ ██      ██   ██ ██   ██      ██ 
███████ ███████ ███████ ███████ ██   ██ ██████  ███████ 

*/
/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.7;
// Librerias
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

//ERC165
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
//ERC721
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _baseUri = "https://api.mydynamicnft.com/metadata/1/";
    // Mapping from token ID to Uri
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return "MyDynamicNFT";
    }
    function symbol() public view virtual override returns (string memory) {
        return "MyDynamicNFT";
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Si tiene Uri el Token, lo devuelvo
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        string memory baseURI  = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return _baseUri;
    }
    function _setbaseURI(string memory tokenURI_) internal virtual {
        _baseUri = tokenURI_;
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to,uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to,uint256 tokenId,bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

contract MyDynamicNFT is ERC721 {
    address private _owner;
    uint256 public COST = 0.02 ether;
    address payable BankWALLET;
    uint256 COUNTER;
    // Maping con Ids que NO se pueden cambiar el URL
    mapping(uint256 => bool) private _permanentURI;

    constructor() ERC721() {
        _owner = _msgSender();
        BankWALLET = payable(_owner);
    }

    // Funciones BankWallet
    function setBankWALLET(address _Wallet) public onlyOwner {
        BankWALLET = payable(_Wallet);
    }
    function getBankWALLET() public view onlyOwner returns (address){
        return BankWALLET;
    }
    // Funciones COSTE
    function setCOST(uint256 _coste) public onlyOwner {
        COST = _coste;
    }

    //Funciones Minteo
    function safeMint(address to) public onlyOwner {
        _safeMint(to, COUNTER);
        COUNTER++;
    }
    function Mint() public payable returns (uint256){
        require(msg.value == COST,"Mint: Value not Valid");
        _safeMint(msg.sender, COUNTER);
        COUNTER++;
        BankWALLET.transfer(COST);
        return COUNTER - 1;
    }

    //Funciones URI
    function setBaseURI(string memory uri) public onlyOwner {
        _setbaseURI(uri);
    }
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(isPermanentURI(tokenId) != true,"PermanentURI: UrlUri Not Editable");
        _setTokenURI(tokenId, uri);
    }
    function ChangeTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender,"ChangeTokenURI: You have to be the owner of the Token to be able to change the URI");
        require(isPermanentURI(tokenId) != true,"PermanentURI: UrlUri Not Editable");
        _setTokenURI(tokenId, uri);
    }

    //Funciones Gestion Cartera NFT
    function walletOfOwner(address _Owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_Owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 counter = 0;
        for (uint256 i = 0; i <COUNTER; i++) {
            if (ownerOf(i) == _Owner) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    //Editable
    function setPermanentURI(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender,"ChangeTokenURI: You have to be the owner of the Token to be able to change the URI");
        _permanentURI[tokenId] = true;
    }

    function isPermanentURI(uint256 tokenId) public view virtual returns (bool) {
        return _permanentURI[tokenId];
    }

    //Ownable
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(),"Ownable: caller is not the owner");
        _;
    }
}
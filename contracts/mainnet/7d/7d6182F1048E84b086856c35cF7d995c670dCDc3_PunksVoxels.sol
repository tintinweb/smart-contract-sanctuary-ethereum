// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
* @notice PunksVoxels ERC721 wrapper contract and ApeVoxels ERC721 contract
* @author DeMemeTree and MarbuR7
*/

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
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
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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

    function balanceOf(address owner) external view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // THE BALANCES GET UPDATED OUTSIDE OF THIS FUNCTION IN A MANNER OF ALL AT ONCE
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
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

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}

contract ApeVoxels is ERC721, ReentrancyGuard, Ownable {
    address private whoCanMint;
    string private baseURIForOGApeVoxels = "ipfs://";
    string private baseExt = ".json";
    string private baseURIForCollectionData = "ipfs://";
    uint private totalMinted = 0;

    constructor(address owner_, address whoCanMint_) ERC721("ApeVoxels", "ApeVoxels") {
        transferOwnership(owner_);
        whoCanMint = whoCanMint_;
    }

    receive() external payable {
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function mint(address user, uint id) external {
        require(msg.sender == whoCanMint, "Sorry you cant mint");
        _mint(user, id);
    }

    function emergencyMint(uint id) external {
        require(msg.sender == owner(), "You are not the owner");
        require(id >= 0, "Id must be in the range 0-9999");
        require(id <= 9999, "Id must be in the range 0-9999");
        _mint(msg.sender, id);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURIForOGApeVoxels, Strings.toString(tokenId), baseExt));
    }

    function updateOwner(address owner_) external {
        require(msg.sender == owner(), "You are not the owner");
        require(owner_ != address(0));
        transferOwnership(owner_);
    }

    function withdraw() external {
        require(msg.sender == owner(), "You are not the owner");
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function setExtension(string calldata _baseExt) external {
        require(msg.sender == owner(), "You are not the owner");
        baseExt = _baseExt;
    }

    function setURIOG(string calldata _baseURI) external {
        require(msg.sender == owner(), "You are not the owner");
        baseURIForOGApeVoxels = _baseURI;
    }

    function setURIForCollection(string calldata _baseURICollection) external {
        require(msg.sender == owner(), "You are not the owner");
        baseURIForCollectionData = _baseURICollection;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURIForCollectionData));
    }

    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function updateSupply(uint count, address whoToMintTo) external {
        require(msg.sender == whoCanMint, "Sorry you cant mint");
        unchecked {
            _balances[whoToMintTo] += count;
            totalMinted += count;
        }
    }

    function totalSupply() external view returns (uint256) {
        return totalMinted;
    }
}

contract PunksVoxels is ERC721, ReentrancyGuard, IERC721Receiver, IERC1155Receiver, Ownable {
    string private baseURIForOGPunksVoxels = "ipfs://";
    string private baseExt = ".json";
    string private baseURIForCollectionData = "ipfs://";
    IERC1155 internal punkVoxels;
    ApeVoxels punkApes;
    uint private totalMinted = 0;

    constructor(address punkVoxels_) ERC721("PunksVoxels", "PunksVoxels") {
        punkVoxels = IERC1155(punkVoxels_);
        punkApes = new ApeVoxels(msg.sender, address(this));
    }

    receive() external payable {
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function wrapMany(uint[] calldata tokenIds) nonReentrant external {
        require(
            punkVoxels.isApprovedForAll(msg.sender, address(this)),
            "You need approval"
        );
        require(tokenIds.length > 0, "Must have something");

        uint count = tokenIds.length;
        uint[] memory qty = new uint[](count);
        for(uint i = 0; i < count;) {
            require(_exists(tokenIds[i]) == false, "Token already minted");
            //require(isValidPunk(tokenIds[i]), "Not a valid PunkVoxels");
            qty[i] = 1;
            unchecked { i++; }
        }

        punkVoxels.safeBatchTransferFrom(msg.sender, address(this), tokenIds, qty, "");

        uint countToUpdatePunks = 0;
        uint countToUpdateApes = 0;
        for(uint i = 0; i < count;) {
            // Mint the PunkVoxel
            _mint(msg.sender, tokenIds[i]);
            countToUpdatePunks = countToUpdatePunks + 1;

            // Mint the ApeVoxel
            uint newId = toPunkId(tokenIds[i]);
            if(punkApes.exists(newId) == false) {
                punkApes.mint(msg.sender, newId);
                countToUpdateApes = countToUpdateApes + 1;
            }

            unchecked { i++; }
        }

        if (countToUpdatePunks > 0) {
            _balances[msg.sender] += countToUpdatePunks;
            totalMinted += countToUpdatePunks;
        }
        if (countToUpdateApes > 0) {
            punkApes.updateSupply(countToUpdateApes, msg.sender);
        }
    }

    function unwrapMany(uint[] calldata tokenIds) nonReentrant external {
        require(tokenIds.length > 0, "Must have something");

        uint count = tokenIds.length;
        uint[] memory qty = new uint[](count);
        uint countToUpdatePunks = 0;
        for(uint i = 0; i < count;) {
            qty[i] = 1;
            require(msg.sender == ownerOf(tokenIds[i]), "Bruh.. you dont own that");
            _burn(tokenIds[i]);
            countToUpdatePunks = countToUpdatePunks + 1;
            unchecked { i++; }
        }

        punkVoxels.safeBatchTransferFrom(address(this), msg.sender, tokenIds, qty, "");

        if (countToUpdatePunks > 0) {
            totalMinted -= countToUpdatePunks;
        }
    }

	function isValidPunk(uint256 openseaId) public pure returns(bool) {
		if (openseaId >> 96 != 0x0000000000000000000000002f77f1bd06f98d2e7e537ab86bcba23559b5c03f)
			return false;
		if (openseaId & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;
		uint256 id = (openseaId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id > 9999 || id == 0 || id == 1 || id == 41 || id == 51 || id == 68 || id == 100 || id == 101 || id == 102 ||
            id == 107 || id == 114 || id == 3014 || id == 3195 || id == 4157)
			return false;
		return true;
	}

    function toPunkId(uint256 openseaId) public pure returns (uint256) {
        uint256 id = (openseaId &
            0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
        if (id < 41) return id - 2;
        else if (id > 41 && id < 51) return id - 3;
        else if (id > 51 && id < 68) return id - 4;
        else if (id > 68 && id < 106) return id - 5;
        else if (id == 106) return id + 3944;
        else if (id == 108) return id + 4896;
        else if (id > 1103 && id < 1471) return id - 1003;
        else if (id ==  1471) return id + 2863;
        else if (id > 1471 && id < 1768) return id - 1004;
        else if (id > 1767 && id < 2003) return id - 1003;
        else if (id > 108 && id < 114) return id + 891;
        else if (id > 114 && id < 135) return id + 890;
        else if (id > 134 && id < 231) return id + 891;
        else if (id > 230 && id < 249) return id + 892;
        else if (id > 248 && id < 264) return id + 893;
        else if (id > 263 && id < 342) return id + 894;
        else if (id > 341 && id < 1008) return id + 895;
        else if (id > 1007 && id < 1104) return id + 896;
        else if (id > 2002 && id < 3286) return id - 3;
        else if (id > 3285 && id < 4052) return id - 2;
        else if (id > 4051 && id < 4335) return id - 1;
        else if (id > 4334 && id < 5004) return id;
        else if (id > 5003 && id < 5452) return id + 1;
        else if (id > 5451 && id < 9998) return id + 2;
        else if (id == 9998) return id - 5842;
        else if (id == 9999) return id - 6988;
        return id;
    }

    function updateOwner(address owner_) external {
        require(msg.sender == owner(), "You are not the owner");
        require(owner_ != address(0));
        transferOwnership(owner_);
    }

    function withdraw() external {
        require(msg.sender == owner(), "You are not the owner");
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function setExtension(string calldata _baseExt) external {
        require(msg.sender == owner(), "You are not the owner");
        baseExt = _baseExt;
    }

    function onERC721Received(address, address, uint256, bytes calldata) pure external returns(bytes4) {
        return PunksVoxels.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) pure external returns (bytes4) {
        return PunksVoxels.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) pure external returns (bytes4) {
        return PunksVoxels.onERC1155BatchReceived.selector;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURIForOGPunksVoxels, Strings.toString(toPunkId(tokenId)), baseExt));
    }

    function setURIOG(string calldata _baseURI) external {
        require(msg.sender == owner(), "You are not the owner");
        baseURIForOGPunksVoxels = _baseURI;
    }

    function setURIForCollection(string calldata _baseURICollection) external {
        require(msg.sender == owner(), "You are not the owner");
        baseURIForCollectionData = _baseURICollection;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURIForCollectionData));
    }

    function totalSupply() external view returns (uint256) {
        return totalMinted;
    }

    function apesContractAddress() external view returns (address) {
        return address(punkApes);
    }
}
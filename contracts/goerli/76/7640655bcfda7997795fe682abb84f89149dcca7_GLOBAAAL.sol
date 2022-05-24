/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from,address to,uint tokenId,bytes calldata data) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint tokenId,bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721  {
    function name() external view returns (string calldata _name);
    function symbol() external view returns (string calldata _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string calldata);
}

contract GLOBAAAL is IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private constant NAME = "2**160 global";
    string private constant SYMBOL = "<script>alert('THIS IS 2**160')</script>";
    string private constant IPFS_LOL = "https://gateway.pinata.cloud/ipfs/Qme4TYyWc4MmvSG8G2TvUnuvwV1gEcsoPs17sbt8XgwFq1";
    
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner,address indexed approved,uint indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);

    //Global specific
    uint private constant MAX_SUPPLY = 2**160;
    uint private total_supply = MAX_SUPPLY;
    mapping(address => bool) private _ownerHasSent;


    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        uint base;
        if (!_ownerHasSent[owner]) {
            base = 1;
        }
        return base + _balances[owner];
    }

    function ownerOf(uint tokenId) public view override returns (address owner) {
        require(tokenId < MAX_SUPPLY);
        if (!_ownerHasSent[address(uint160(tokenId))]) {
            owner = address(uint160(tokenId));            
        } else {
            owner = _owners[tokenId];
        }
        require(owner != address(0), "token doesn't exist");
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    function _approve( address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address to, uint tokenId) external override {
        require(tokenId < MAX_SUPPLY);
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    function _isApprovedOrOwner( address owner, address spender, uint tokenId) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    function _transfer( address owner, address from, address to, uint tokenId) private {
        require(tokenId < MAX_SUPPLY);
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, address(0), tokenId);

        if ((address(uint160(tokenId)) == owner) && (!_ownerHasSent[owner])) {
            _ownerHasSent[owner] = true;
        } else {
            _balances[from] -= 1;
        }
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint tokenId) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    function _safeTransfer( address owner, address from, address to, uint tokenId, bytes memory _data) private {
        _transfer(owner, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "not ERC721Receiver");
    }

    function safeTransferFrom( address from, address to, uint tokenId, bytes memory _data) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    function safeTransferFrom( address from, address to, uint tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function burn(uint tokenId) external {
        if (!_ownerHasSent[address(uint160(tokenId))]) {
            _ownerHasSent[address(uint160(tokenId))] = true;
            emit Transfer(address(uint160(tokenId)), address(0), tokenId);           
        } else {
            address owner = ownerOf(tokenId);
            _approve(owner, address(0), tokenId);
            _balances[owner] -= 1;
            delete _owners[tokenId];
            emit Transfer(owner, address(0), tokenId);
        }

        total_supply -= 1;
    }

    function simpletest(uint input) external pure returns (uint160 checkNumber) {
        checkNumber = uint160(input);
    }

    function addressToId(address _address) external pure returns (uint160) {
        return uint160(_address);
    }

    //Enumerable

    function totalSupply() external view returns (uint256) {
        return total_supply;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        string memory tokenString = _tokenId.toString();
        string memory finalJSON = string(abi.encodePacked("{'image': '", IPFS_LOL, "','attributes': [{'trait_type': 'tokenId','value': '", tokenString,"'}]}"));
        return finalJSON;
    }

}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT

// @title ONIForceWrapper
// @author jolan.eth
pragma solidity ^0.8;

interface ONIForceMetadata {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ONI {
    string public symbol = "0N1";
    string public name = "0N1Force";

    address public ONIDeployer = 0x281302D3752b21bEeD7203443e9d500B5183738f;
    string public ONICid = "QmXgSuLPGuxxRuAana7JdoWmaS25oAcXv3x2pYMN9kVfg3";

    uint256 public tokenId = 1;
    uint256 public totalSupply = 0;

    mapping (uint256 => address) owners;
    mapping(address => uint256) balances;
    
    mapping(uint256 => address) approvals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}

    function mint0N1() public {
        _mint(msg.sender, tokenId++);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(address(0) != owner, "error address(0)");
        return balances[owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return owners[id];
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(owners[id] != address(0), "error !exist");
        return string(
            abi.encodePacked(
                "ipfs://", ONICid, "/", _toString(id)
            )
        );
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(to != owner, "error to");
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "error owner"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return approvals[id];
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(operator != msg.sender, "error operator");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        require(owners[id] != address(0), "error !exist");
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );

        _transfer(owner, from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );
        _transfer(owner, from, to, id);
        require(_checkOnERC721Received(from, to, id, data), "error ERC721Receiver");
    }

    function _mint(address to, uint256 id)
    private {
        address from = address(0);
        require(to != address(0), "error to");
        require(owners[id] == address(0), "error owners[id]");
        emit Transfer(address(0), ONIDeployer, id);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(id);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, id);
        }
        
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(id);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, id);
        }

        balances[to]++;
        owners[id] = to;
        totalSupply++;
        
        emit Transfer(ONIDeployer, to, id);
        require(_checkOnERC721Received(ONIDeployer, to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address owner, address from, address to, uint256 id)
    private {
        require(owner == from, "errors owners[id]");
        require(address(0) != to, "errors address(0)");

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(id);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, id);
        }
        
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(id);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, id);
        }

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < balanceOf(owner), "error index");
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply, "error index");
        return _allTokens[index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 id) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = id;
        _ownedTokensIndex[id] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 id) private {
        _allTokensIndex[id] = _allTokens.length;
        _allTokens.push(id);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 id) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[id];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[id];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 id) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[id];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[id];
        _allTokens.pop();
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == ERC721TokenReceiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }
    
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";

        uint256 digits;
        uint256 tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
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
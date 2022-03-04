// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// @title NAN0
// @author jolan.eth
contract NAN0 is Ownable {
    string public symbol = "NAN0";
    string public name = "0N1Force: NAN0SUIT";
    string public CID = "";
    
    address public Nanozone;
    address public ONIDeployer = 0x281302D3752b21bEeD7203443e9d500B5183738f;

    uint public totalSupply = 0;

    mapping (uint => uint) public roll;

    mapping (uint => address) owners;
    mapping (address => uint) balances;
    
    mapping (uint => address) approvals;
    mapping (address => mapping(address => bool)) operatorApprovals;

    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    constructor() {}

    function setNanozone(address _Nanozone) public onlyOwner {
        require(Nanozone == address(0));
        Nanozone = _Nanozone;
    }

    function mintNAN0(address to, uint tokenId) public {
        require(msg.sender == Nanozone, "error protocol");
        uint rand = _pseudoRandom();
        roll[tokenId] = rand;
        _mint(to, tokenId);
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(msg.sender == Nanozone, "error protocol");
        _transfer(from, to, tokenId);
    }

    function rollNAN0(uint tokenId) public {
        require(msg.sender == Nanozone, "error protocol");
        uint rand = _pseudoRandom();
        roll[tokenId] = rand;
    }

    function exist(uint tokenId) public view returns (bool) {
        return owners[tokenId] != address(0) ? true : false;
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint) {
        require(address(0) != owner, "error address(0)");
        return balances[owner];
    }

    function ownerOf(uint id)
    public view returns (address) {
        require(exist(id), "error exist");
        return owners[id];
    }

    function tokenURI(uint id)
    public view returns (string memory) {
        require(exist(id), "error exist");
        return string(
            abi.encodePacked("ipfs://", CID, "/", _toString(id), "/", _toString(roll[id]))
        );
    }

    function _mint(address to, uint id)
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
        require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address from, address to, uint id)
    private {
        require(exist(id), "error exist");
        require(to != address(0), "error id");
        require(from == ownerOf(id), "error owner");

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

        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
        require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
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

    function _checkOnERC721Received(address from, address to, uint id, bytes memory _data)
    internal returns (bool) {
        uint size;

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

    function _toString(uint value) private pure returns (string memory) {
        if (value == 0) return "0";

        uint digits;
        uint tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function _pseudoRandom() private view returns(uint) {
        return 1 + uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,  
                    msg.sender
                )
            )
        ) % 100;
    }
}
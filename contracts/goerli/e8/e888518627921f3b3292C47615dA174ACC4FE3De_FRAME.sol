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

// @author jolan.eth
contract FRAME is Ownable {
    string public symbol = "FRAME";
    string public name = "0N1 Frame";
    string public CID;

    address public NANOHUB;

    uint public totalSupply = 0;

    mapping (uint => address) owners;
    mapping (address => uint) balances;

    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    constructor() {}

    function setCID(string memory _CID)
    public onlyOwner {
        CID = _CID;
    }

    function setNANOHUB(address _NANOHUB)
    public onlyOwner {
        NANOHUB = _NANOHUB;
    }

    function mintFRAME(address to, uint tokenId)
    public {
        require(msg.sender == NANOHUB, "error NANOHUB");
        _mint(to, tokenId);
    }

    function transferFrom(address from, address to, uint tokenId)
    public {
        require(msg.sender == NANOHUB, "error NANOHUB");
        _transfer(from, to, tokenId);
    }

    function exist(uint tokenId)
    public view returns (bool) {
        return owners[tokenId] != address(0);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint) {
        require(address(0) != owner, "error owner");
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
            abi.encodePacked("ipfs://", CID, "/", _toString(id))
        );
    }

    function _mint(address to, uint id)
    private {
        address from = address(0);
        require(to != address(0), "error to");
        require(owners[id] == address(0), "error owner");

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

        emit Transfer(address(0), to, id);
        require(_checkOnERC721Received(address(0), to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address from, address to, uint id)
    private {
        require(exist(id), "error exist");
        require(to != address(0), "error to");
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

    function tokenOfOwnerByIndex(address owner, uint256 index)
    public view virtual returns (uint256) {
        require(index < balanceOf(owner), "error balanceOf");
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index)
    public view virtual returns (uint256) {
        require(index < totalSupply, "error totalSupply");
        return _allTokens[index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 id)
    private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = id;
        _ownedTokensIndex[id] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 id)
    private {
        _allTokensIndex[id] = _allTokens.length;
        _allTokens.push(id);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 id)
    private {
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

    function _removeTokenFromAllTokensEnumeration(uint256 id)
    private {
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

    function _toString(uint value)
    private pure returns (string memory) {
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
}
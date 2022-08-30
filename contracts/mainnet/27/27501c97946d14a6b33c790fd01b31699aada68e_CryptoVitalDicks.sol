// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator, address from, uint256 tokenId, bytes calldata data
    ) external returns (bytes4);
}

contract CryptoVitalDicks is Ownable {
    bool unleashed;

    uint256 supply;
    mapping (uint256 => address) owners;
    mapping (address => uint256) balances;
    
    mapping (uint256 => address) approvals;
    mapping (address => mapping(address => bool)) operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    constructor() {
        _mint(msg.sender, 250);
    }

    function name()
    public pure returns (string memory) {
        return "CryptoVitalDicks";
    }

    function symbol()
    public pure returns (string memory) {
        return "DICK";
    }

    function maxSupply()
    public pure returns (uint256) {
        return 10000;
    }

    function unleashMint()
    public onlyOwner {
        unleashed = !unleashed;
    }

    function mintDICK(uint256 quantity)
    public {
        require(
            supply < maxSupply(),
            "CryptoVitalDicks::mintDICK() - supply exceeds maxSupply"
        );

        require(
            quantity > 0 && quantity <= 10,
            "CryptoVitalDicks::mintDICK() - quantity is out of bounds"
        );

        if (!unleashed) require(
            balanceOf(msg.sender) == 0,
            "CryptoVitalDicks::mintDICK() - msg.sender are already minted DICK"
        );

        _mint(msg.sender, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(
            exist(id),
            "CryptoVitalDicks::tokenURI() - id do not exist"
        );

        string memory strId = (
            id < 10 ? string(abi.encodePacked("000", _toString(id))) :
            id < 100 ? string(abi.encodePacked("00", _toString(id))) :
            id < 1000 ? string(abi.encodePacked("0", _toString(id))) :
            _toString(id)
        );

        return string(abi.encodePacked(
            'data:application/json;base64,',
            encode(bytes(string(abi.encodePacked(
                "{",
                    '"name":"CryptoVitalDicks #',strId,'",',
                    '"description":"ARE YOU LONG ETH LIKE VITALIK ANON?",',
                    '"image":"ipfs://Qmb59HoVrTXGesRpcpynso82ujttu6TXs9dYm5C4XYLxjV/',strId,'.png"',
                "}"
            ))))
        ));
    }

    function exist(uint256 id)
    public view returns (bool) {
        return owners[id] != address(0);
    }

    function totalSupply()
    public view returns (uint256) {
        return supply == 0 ? 0 : supply;
    }

    function balanceOf(address _owner)
    public view returns (uint256) {
        require(
            _owner != address(0),
            "CryptoVitalDicks::balanceOf() - _owner is address(0)"
        );

        return balances[_owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "CryptoVitalDicks::ownerOf() - id do not exist"
        );

        return owners[id];
    }

    function isApprovedForAll(address _owner, address operator)
    public view returns (bool) {
        return operatorApprovals[_owner][operator];
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "CryptoVitalDicks::getApproved() - id do not exist"
        );

        return approvals[id];
    }

    function approve(address to, uint256 id)
    public {
        address _owner = owners[id];
        require(
            to != _owner,
            "CryptoVitalDicks::approve() - to is _owner"
        );
        require(
            _owner == msg.sender ||
            operatorApprovals[_owner][msg.sender],
            "CryptoVitalDicks::approve() - msg.sender is not _owner or approved"
        );

        approvals[id] = to;
        emit Approval(_owner, to, id);
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(
            operator != msg.sender,
            "CryptoVitalDicks::setApprovalForAll() - msg.sender is operator"
        );

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        address _owner = owners[id];
        
        require(
            exist(id),
            "CryptoVitalDicks::transferFrom() - id do not exist"
        );

        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "CryptoVitalDicks::transferFrom() - msg.sender is not _owner or approved"
        );

        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
    public {
        address _owner = owners[id];
        
        require(
            exist(id),
            "CryptoVitalDicks::safeTransferFrom() - id do not exist"
        );

        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "CryptoVitalDicks::safeTransferFrom() - msg.sender is not _owner or approved"
        );

        _safeTransfer(from, to, id, '');
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address _owner = owners[id];

        require(
            exist(id),
            "CryptoVitalDicks::safeTransferFrom() - id do not exist"
        );
        
        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "CryptoVitalDicks::safeTransferFrom() - msg.sender is not _owner or approved"
        );

        _safeTransfer(from, to, id, data);
    }

    function _mint(address to, uint256 quantity)
    private {
        uint256 i = 0;
        unchecked {
            while (i < quantity) {
                balances[to]++;
                owners[supply] = to;
                emit Transfer(address(0), to, supply++);
                i++;
            }
        }
    }

    function _transfer(address from, address to, uint256 id)
    private {
        require(
            address(0) != to,
            "CryptoVitalDicks::_transferFrom() - to is address(0)"
        );

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _safeTransfer(address from, address to, uint256 id, bytes memory data)
    private {
        _transfer(from, to, id);
        
        require(
            _checkOnERC721Received(from, to, id, data),
            "CryptoVitalDicks::_safeTransfer() - to is not ERC721 receiver"
        );
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

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
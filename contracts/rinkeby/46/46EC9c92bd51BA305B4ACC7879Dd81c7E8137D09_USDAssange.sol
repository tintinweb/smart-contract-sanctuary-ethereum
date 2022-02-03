// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";
import "./USDAssangeMetadata.sol";
import "./IERC1155Receiver.sol";

contract USDAssange is USDAssangeMetadata, Ownable {
    string public symbol = "USDAssange";
    string public name = "Dollars Assange";

    uint256 public totalSupply = 0;

    address ADDRESS_MINTER = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;

    mapping(uint256 => mapping(address => uint256)) private balances;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    constructor() {}

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0xd9b67a26;
    }

    function drop(address[] memory addresses, uint256[] memory quantity, uint256 total) public onlyOwner {
        uint256 i = 0;
        while (i < addresses.length)
            mintUSDAssange(addresses[i], quantity[i++]);
        totalSupply += total;
    }

    function mint() public {
        mintUSDAssange(msg.sender, 1);
        totalSupply++;
    }
    
    function mintUSDAssange(address to, uint256 supply) private {
        _mint(to, 1, supply, '');
    }
    
    function uri(uint256) public view virtual returns (string memory) {
        return USDAssangeMetadata._compileMetadata();
    }

    function balanceOf(address owner, uint256 id)
    public view virtual returns (uint256) {
        require(owner != address(0), "error owner");
        return balances[id][owner];
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
    public view virtual returns (uint256[] memory)
    {
        require(owners.length == ids.length, "error length");
        uint256[] memory batchBalances = new uint256[](owners.length);

        uint256 i = 0;
        while (i < owners.length) 
            batchBalances[i] = balanceOf(owners[i], ids[i++]);

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
    public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view virtual returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
    public virtual {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "error approved");
        require(to != address(0), "error to");

        address operator = msg.sender;

        uint256 fromBalance = balances[id][from];
        require(fromBalance >= amount, "error balance");
        unchecked {
            balances[id][from] = fromBalance - amount;
        }
        balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public virtual {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "error approved");
        require(ids.length == amounts.length, "error length");
        require(to != address(0), "error to");

        address operator = msg.sender;

        uint256 i = 0;
        while (i < ids.length) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][from];
            require(fromBalance >= amount, "error balance");
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
            balances[id][to] += amount;
            i++;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data)
    internal virtual {
        require(to != address(0), "error to");

        address operator = msg.sender;

        balances[id][to] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved)
    internal virtual {
        require(owner != operator, "error owner");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data)
    private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("error Receiver");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("error Receiver");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("error Receiver");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("error Receiver");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}
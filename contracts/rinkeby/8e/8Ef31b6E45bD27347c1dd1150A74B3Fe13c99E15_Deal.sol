// SPDX-License-Identifier: MIT
pragma solidity >= 0.8 .0;

// import "./Owner.sol";
import "./Item.sol";
import "./helper/Stringhelper.sol";

contract Deal is Item{

    mapping(address=>mapping(address=>uint)) public transactionpMap;

    // (buyer, seller, value)
    event BuyEvent(address, address, uint);

    function hello() override public pure returns(string memory returnStr ){
        returnStr = "Hello Deal contract";
    }

    function buy(address payable seller, string memory itemNo) public payable returns(bool) {
        // chk
        itemInfo memory _itemInfo = itemOne[itemNo][seller];
        require(Stringhelper.stringCompare(_itemInfo.itemNo,""), "Cannot find the item.");
        uint _price = _itemInfo.price*1e18; // WEI
        require(msg.value >= _price, "Your balance is Insufficient.");


        emit BuyEvent(msg.sender, seller, _price);
        transactionpMap[msg.sender][seller] += _price;

        // seller call
        (bool isSuccess, ) = transfer(seller, transactionpMap[msg.sender][seller]);
        transactionpMap[msg.sender][seller] -= _price;

        //update
        _itemInfo.status = itemStatus.sold;
        Item.Update(_itemInfo, seller);

        return isSuccess;
    }

    function transfer(address payable _to, uint price) public payable returns(bool isSuccess, bytes memory data){
        // The price must be wei unit

        require(address(this).balance >= price, "This price is much more than contract wallet.");
        (isSuccess, data) = _to.call {value: price}("");
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

library Stringhelper {
    function stringCompare(string memory a, string memory b) public pure returns(bool) {
        if (keccak256(bytes(a)) == keccak256(bytes(b)))
            return true;
        else
            return false;
    }

    function concate(string memory a, string memory b, bool hasBlank) public pure returns(string memory) {
        string memory ans;
        if (hasBlank)
            ans = string(abi.encodePacked(a, " ", b));
        else
            ans = string(abi.encodePacked(a, b));
        return ans;
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8 .0;

library Byteshelper {
    function bytes32ToString(bytes32 _bytes32) public pure returns(string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "./helper/Stringhelper.sol";
import "./helper/Byteshelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Item {
    using Stringhelper for string;
    using Byteshelper for bytes32;

    enum itemStatus {
        open,
        pedding,
        sold,
        close,
        del
    }

    struct itemInfo {
        string itemNo;
        string name;
        uint price;
        string pic;
        itemStatus status;
        uint ItemArrNo;
        uint OwnArrNo;
    }

    mapping(address => itemInfo[]) public itemsOwn;

    // For item, itemNo is unique.(itemNo => (address => item)).
    // Throughout the test, that is ok even though address of (address=>item) is duplicate.
    mapping(string => mapping(address => itemInfo)) public itemOne;

    // For get all item[n][k] k: 0=>itenNo, 1=>itemName
    //It's reverse when def. => item[k][n]
    string[][] itemArray;

    // (owner, itemNo, execute time)
    event createItem(address indexed, string, uint);
    event updateItem(address indexed, string, uint);
    event deleteItem(address indexed, string, uint);

    function hello() virtual public pure returns(string memory returnStr) {
        returnStr = "Hello Iten contract";
    }

    function Create(itemInfo memory item) public returns(string memory itemNo) {
        // chk item info
        require(false == item.name.stringCompare(""), "item name can not leave blank.");
        require(item.price > 0, "item price can not lower then 0.");

        // generate item_no
        itemNo = Stringhelper.concate("item", Strings.toString(block.timestamp), false);
        item.itemNo = itemNo;
        item.ItemArrNo = itemArray.length;
        item.OwnArrNo = itemsOwn[msg.sender].length;

        // create
        emit createItem(msg.sender, itemNo, block.timestamp);
        itemOne[itemNo][msg.sender] = item;
        itemsOwn[msg.sender].push(item);
        itemArray.push([itemNo,item.name]);
    }

    function ReadItems_ALL() public view returns(string[][] memory) {
        return itemArray;
    }

    function ReadItems_Own() public view returns(itemInfo[] memory) {
        return itemsOwn[msg.sender];
    }

    function Update(itemInfo memory uitem) public {
        // chk
        require(itemOne[uitem.itemNo][msg.sender].itemNo.stringCompare(uitem.itemNo), "This is not your item or item number is wrong.");

        // update
        emit updateItem(msg.sender, uitem.itemNo, block.timestamp);
        (itemsOwn[msg.sender])[uitem.OwnArrNo] = uitem;
        itemOne[uitem.itemNo][msg.sender] = uitem;
        itemArray[uitem.ItemArrNo][1] = uitem.name;
    }

    // after sell
    function Update(itemInfo memory uitem, address seller) public {
        // chk
        require(itemOne[uitem.itemNo][seller].itemNo.stringCompare(uitem.itemNo), "item number is wrong or seller is wrong");

        // update
        emit updateItem(seller, uitem.itemNo, block.timestamp);
        (itemsOwn[seller])[uitem.OwnArrNo] = uitem;
        itemOne[uitem.itemNo][seller] = uitem;
        itemArray[uitem.ItemArrNo][1] = uitem.name;
    }

    function Del(itemInfo memory ditem) public {
        require(itemOne[ditem.itemNo][msg.sender].itemNo.stringCompare(ditem.itemNo), "This is not your item or item number is wrong.");

        // delete
        emit deleteItem(msg.sender, ditem.itemNo, block.timestamp);
        (itemsOwn[msg.sender])[ditem.OwnArrNo].status = itemStatus.del;
        itemOne[ditem.itemNo][msg.sender].status = itemStatus.del;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
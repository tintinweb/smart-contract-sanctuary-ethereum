// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "./Owner.sol";
import "./Item.sol";

contract Deal is Item, Owner{

    event buyLog(address indexed from, address to, uint value, string log);
    event transferLog(address indexed from, address to, uint value, bool isSuccess, string log);

    function hello() override public pure returns(string memory returnStr ){
        returnStr = "Hello, this is deal contract!";
    }

    function buy(string calldata itemNo) public payable {
        
        buyProcess( getOneItem(itemNo), payable(getItemOwner(itemNo)) );
        
    }

    function buyProcess(itemInfo memory item, address payable seller) private buyChk(item, seller) {

        emit buyLog(msg.sender, seller, item.price, item.itemNo);

        transfer(seller, item.price);

        changeItemOwner(item, seller);

    }

    function transfer(address payable _to, uint price) public payable returns(bool isSuccess, bytes memory data){
        
        if(address(this).balance < price){
            emit buyLog(msg.sender, _to, price, "This value is greater than contract wallet.");
            revert("This value is greater than contract wallet.");
        }
        
        (isSuccess, data) = _to.call {value: price}("");
        emit transferLog(msg.sender, _to, price, isSuccess, "");

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

        string memory concateStr;
        if (hasBlank)
            concateStr = string(abi.encodePacked(a, " ", b));
        else
            concateStr = string(abi.encodePacked(a, b));
        return concateStr;

    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

contract Owner {

    address public owner;
    uint public transctionFee;
    mapping (address=> uint) contributeMap;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Owner only.");
        _;
    }

    function setTransactionFee(uint fee) public onlyOwner{
        transctionFee = fee;
    }
    
    function withdraw() public payable onlyOwner{
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function contribute() public payable{
        contributeMap[msg.sender] += msg.value;
    }

    function chkBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "./helper/Stringhelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Item{

    using Stringhelper for string;

    enum itemStatus {
        open, // 0
        pedding, // 1
        sold, // 2
        close, // 3
        del //4
    }

    struct itemInfo {
        string itemNo;
        string name;
        uint256 price; //wei
        string pic;
        itemStatus status;
        uint itemsArraySeq;
        uint myItemsMapSeq;
        bool isLocked;
    }

    // Get all items
    itemInfo[] internal itemsArray;

    // Get one item and locked status chk
    // itemNo => itemInfo
    mapping(string => itemInfo) internal itemNoMap;

    // Auth or get item owner address for selling
    // itemNo => item owner
    mapping(string => address) internal itemOwnerMap;

    // Get my all items
    mapping(address => itemInfo[]) internal myItemsMap;

    // EVENT (owner, itemInfo)
    event createItemEvent(address indexed, itemInfo);
    event modifyItemEvent(address indexed, itemInfo);

    // c:create, u:update, d:delete, b:buy, ut:afterTx
    modifier basicCheck(itemInfo memory item, string memory method){
        
        require(item.name.stringCompare("") == false, "Item name can not leave blank.");
        require(item.price > 0, "Item price can not lower then 0.");

        if(method.stringCompare("u") || method.stringCompare("d")){
            require(itemOwnerMap[item.itemNo] == msg.sender, "This is not your item or item number is wrong.");
            require(item.itemNo.stringCompare("") == false, "Item number is blank");
            require(itemNoMap[item.itemNo].isLocked == false, "Item is locked, operate later.");

            lockStatus(item, true, msg.sender);
        }

        _;

        lockStatus(item, false,  msg.sender);
    }

    modifier buyChk(itemInfo memory item, address seller){

        require(item.name.stringCompare("") == false, "Item name can not leave blank.");
        require(item.price > 0, "Item price can not lower then 0.");

        require(item.itemNo.stringCompare("") == false, "Item number is blank");
        require(itemNoMap[item.itemNo].isLocked == false, "Item is locked, operate later.");
        require(item.status == itemStatus.open, "Item status is not open");
        require(msg.sender != itemOwnerMap[item.itemNo], "Don't buy your stuff");
        require(msg.value >= item.price, "Your balance is Insufficient.");

        lockStatus(item, true,  seller);

        _;

        lockStatus(item, false,  msg.sender);

    }

    function lockStatus(itemInfo memory item, bool lock, address addr) private {
        
        itemsArray[item.itemsArraySeq].isLocked = lock;
        itemNoMap[item.itemNo].isLocked = lock;
        myItemsMap[addr][item.myItemsMapSeq].isLocked = lock;

    }

    function hello() virtual public pure returns(string memory returnStr) {
        returnStr = "Hello, this is item contract!";
    }

    function getAllItems() public view returns(itemInfo[] memory) {
        return itemsArray;
    }

    function getOneItem(string calldata itemNo) public view returns(itemInfo memory) {
        return itemNoMap[itemNo];
    }

    function getItemOwner(string calldata itemNo) public view returns(address) {
        return itemOwnerMap[itemNo];
    }

    function getMyItems() public view returns(itemInfo[] memory) {
        return myItemsMap[msg.sender];
    }

    function createItem(itemInfo memory item) public basicCheck(item, "c") {
        
        // generate item_no
        string memory itemNo = Stringhelper.concate("item", Strings.toString(block.timestamp), false);

        item.itemNo = itemNo;
        item.itemsArraySeq = itemsArray.length;
        item.myItemsMapSeq = myItemsMap[msg.sender].length;
        item.isLocked = false;

        // create
        emit createItemEvent(msg.sender, item);

        itemsArray.push(item);
        itemNoMap[itemNo] = item;
        itemOwnerMap[itemNo] = msg.sender;
        myItemsMap[msg.sender].push(item);
    }

    function updateItem(itemInfo memory item) public basicCheck(item, "u") {
        emit modifyItemEvent(msg.sender, item);
        uint itemsArraySeq = itemNoMap[item.itemNo].itemsArraySeq;
        uint myItemsMapSeq = itemNoMap[item.itemNo].myItemsMapSeq;

        itemsArray[itemsArraySeq].name = item.name;
        itemsArray[itemsArraySeq].price = item.price;
        itemsArray[itemsArraySeq].pic = item.pic;
        itemsArray[itemsArraySeq].status = item.status;

        itemNoMap[item.itemNo].name = item.name;
        itemNoMap[item.itemNo].price = item.price;
        itemNoMap[item.itemNo].pic = item.pic;
        itemNoMap[item.itemNo].status = item.status;

        myItemsMap[msg.sender][myItemsMapSeq].name = item.name;
        myItemsMap[msg.sender][myItemsMapSeq].price = item.price;
        myItemsMap[msg.sender][myItemsMapSeq].pic = item.pic;
        myItemsMap[msg.sender][myItemsMapSeq].status = item.status;
    }

    function deleteItem(itemInfo memory item) public basicCheck(item, "d") {
        /**incomplete */
        emit modifyItemEvent(msg.sender, item);

        itemsArray[item.itemsArraySeq].status = itemStatus.del;
        
        itemNoMap[item.itemNo].status = itemStatus.del;
        
        myItemsMap[msg.sender][item.myItemsMapSeq].status = itemStatus.del;
    }

    function changeItemOwner(itemInfo memory boughtItem, address oriOwner) internal {

        uint oriMyItemSeq = boughtItem.myItemsMapSeq;

        // update boughtItem parameters
        boughtItem.status = itemStatus.close;
        boughtItem.myItemsMapSeq = myItemsMap[msg.sender].length;

        // update itemsArray , itemNoMap and itemOwnerMap
        itemsArray[boughtItem.itemsArraySeq] = boughtItem;
        itemNoMap[boughtItem.itemNo] = boughtItem;
        itemOwnerMap[boughtItem.itemNo] = msg.sender;

        // create item to myItemsMap ( for buyer )
        myItemsMap[msg.sender].push(boughtItem);

        /* using last item to replace the original item position ( for seller )*/
        // original owner only have one or just sell last one
        if(myItemsMap[oriOwner].length == 1 || oriMyItemSeq == myItemsMap[oriOwner].length-1){
            myItemsMap[oriOwner].pop();
        }
        else {
            // get last item info
            itemInfo memory lastItem = myItemsMap[oriOwner][myItemsMap[oriOwner].length-1];

            // update lastItem seq
            lastItem.myItemsMapSeq = oriMyItemSeq;
            itemsArray[lastItem.itemsArraySeq] = lastItem;
            itemNoMap[lastItem.itemNo] = lastItem;

            // replace and pop last item
            myItemsMap[oriOwner][oriMyItemSeq] = lastItem;
            myItemsMap[oriOwner].pop();
        }

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
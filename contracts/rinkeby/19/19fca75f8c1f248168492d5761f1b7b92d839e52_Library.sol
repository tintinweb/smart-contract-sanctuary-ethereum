/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: Chainblock_FinalProject.sol

pragma solidity ^0.8.7;


contract Library {

    struct Book {
        uint id;
        string name;
        string author;
        string publisher;
        bool state;       //available:1,  borrowed:0
        uint time;
    }

    struct Person {
        uint user_id;
        string name;
        address addr;
        bool state;       //available:1, ban:0
    }

    Book [] public collection;
    Person [] public member;
    uint public memberNum;
    uint public collectionNum;

    constructor() public {
        memberNum = 0;
        collectionNum = 0;
        collection.push(Book({id: collectionNum++, name: "Object-oriented programming",author: "Mr.Wang",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Chances and Statistics",author: "Mr.Wang",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Operating System",author: "Mr.Lee",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Computer Architecture",author: "Mr.Lee",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Electronic Devices",author: "Mr.Chen",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Linear Algebra",author: "Mr.Chen",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Information Security",author: "Mr.Su",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Network intrusion detection",author: "Mr.Su",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "Chain Block",author: "Mr.Wang",publisher: "MCU",state: true,time: 0}));
        collection.push(Book({id: collectionNum++, name: "IoT",author: "Mr.Wang",publisher: "MCU",state: true,time: 0}));
    }

    function AddBook(string memory name, string memory author, string memory publisher) public {
        collection.push(Book({
            id: collectionNum++,
            name: name,
            author: author,
            publisher: publisher,
            state: true,
            time: 0
        }));
    }
    
    function AddMember(string memory name) public {
        member.push(Person({
            user_id: memberNum++,
            name: name,
            addr: msg.sender,
            state: true
        }));
    }

    function BorrowBook(string memory person, string memory book, uint time) public {
        for(uint i=0; i<member.length; i++){
                if(keccak256(abi.encodePacked(member[i].name)) == keccak256(abi.encodePacked(person))){
                    if(member[i].state != false){
                    for(uint j=0; j<collection.length; j++){
                        if(keccak256(abi.encodePacked(collection[j].name)) == keccak256(abi.encodePacked(book))){
                            collection[j].state = false;
                            collection[j].time = block.timestamp + time;
                        }
                    }
                }
            }
        }
    }

    function EscheatBook(string memory person, string memory book) public {
        for(uint i=0; i<collection.length; i++){
            if(keccak256(abi.encodePacked(collection[i].name)) == keccak256(abi.encodePacked(book))){
                if(block.timestamp > collection[i].time){
                    for(uint j=0; j<member.length; j++){
                        if(keccak256(abi.encodePacked(member[j].name)) == keccak256(abi.encodePacked(person))){
                            member[j].state = false;
                        }
                    }
                }
                collection[i].time = 0;
                collection[i].state = true;
            }
        }
    }

    function getBookList() public view returns (string memory){
        string memory sum = "";
        for (uint i=0; i<collection.length; i++){
            Book memory book = collection[i];
            string memory id = Strings.toString(book.id);
            string memory newid = append("id: ",id);
            string memory name = book.name;
            string memory newname = append(" name: ",name);
            string memory author = book.author;
            string memory newauthor = append(" author: ",author);
            string memory publisher = book.publisher;
            string memory newpublisher = append(" publisher: ",publisher);
            string memory state;
            if(book.state==true)state="true";
            if(book.state==false)state="false";
            string memory newstate = append(" state: ",state);
            string memory single = bigappend(newid, newname, newauthor, newpublisher, newstate);
            sum = append(sum, single);
            sum = append(sum, "\n");
        }
        return sum;
    }

    function getMemberList() public view returns (Person [] memory){
        return member;
    }

    function checkBookStates(string memory name) public view returns (bool){
        for(uint i=0; i<collection.length; i++){
            if(keccak256(abi.encodePacked(collection[i].name)) == keccak256(abi.encodePacked(name))){
                return collection[i].state;
            }
        }
    }

    function checkPersonStates(string memory name) public view returns (bool){
        for(uint i=0; i<member.length; i++){
            if(keccak256(abi.encodePacked(member[i].name)) == keccak256(abi.encodePacked(name))){
                return member[i].state;
            }
        }
    }
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function bigappend(string  memory a, string  memory b, string memory  c, string  memory d, string  memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
}
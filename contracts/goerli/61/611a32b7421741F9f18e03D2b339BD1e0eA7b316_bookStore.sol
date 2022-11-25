// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Counters.sol";

contract bookStore {
    // //declaring counters for index of bookData array

    // using Counters for Counters.Counter;
    // Counters.Counter private _bookIds;

    //creating the structure for storing the information about books

    struct bookData {
        string bookName;
        uint256 bookPrice;
        string bookDescription;
        string ipfsLink;
       // uint256 index;
    }

    //a particular owner can own multiple books therefore map of struct array is creating

    mapping(address => bookData[]) public ownerToBook;

    //creating a hashtable like structure for every owner, for every owner 1 will be marked to its address

    mapping(address => uint32) public ownerPresent;

    //event to emit owner data so that the front end can fetch it

    event ownerData(address owner, string bookname, uint bookprice, string bookdescription, string ipfslink);

    //function for new Owners
    function setBookData(
        address _owner,
        string memory _bookName,
        uint256 _bookPrice,
        string memory _bookDescription,
        string memory _ipfsLink
    ) public {
            ownerToBook[_owner].push(bookData(_bookName,_bookPrice,_bookDescription,_ipfsLink));
            emit ownerData(_owner,_bookName,_bookPrice,_bookDescription,_ipfsLink);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: MyPerson.sol

contract MyPerson is Ownable {
    string[] private uniquedocuments; //[compileof(id), compileof(passport), compileof(electoralmap), etc...]
    string[] private namedocuments; //[id, passport, electoralmap, etc...]

    string[][] private recursivedocuments; //[ [compileof(bills1), compileof(bills2)] , [] , etc..]
    string[] private categoriesdocuments; //[gas bills, taxes, water bills]
    string[][] private datingrecdocs; //[ [11/05/26 , etc..] , etc...]

    string[] private newdocs;
    string[] private newdate;

    function compareStrings(string memory a, string memory b)
        private
        view
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    //SETTERS

    function setDocument(
        //add a new unique doc
        string memory compileddoc,
        string memory namedoc
    ) public onlyOwner {
        int256 ind = -1;
        for (int256 i = 0; i < int256(namedocuments.length); i++) {
            if (compareStrings(namedocuments[uint256(i)], namedoc)) {
                ind = i;
                break;
            }
        }
        if (ind == -1) {
            uniquedocuments.push(compileddoc);
            namedocuments.push(namedoc);
        } else {
            uniquedocuments[uint256(ind)] = compileddoc;
        }
    }

    function setRecDocument(
        ///add a new rec doc to its catecory with date
        string memory compileddoc,
        string memory catdoc,
        string memory date
    ) public onlyOwner {
        int256 ind = -1;
        for (int256 i = 0; i < int256(categoriesdocuments.length); i++) {
            if (compareStrings(categoriesdocuments[uint256(i)], catdoc)) {
                ind = i;
                break;
            }
        }
        if (ind == -1) {
            // if there is no categories
            newdocs = new string[](0);
            newdocs.push(compileddoc); //creates a new string array with the new document
            recursivedocuments.push(newdocs); //add this new string array to the main array

            newdate = new string[](0);
            newdate.push(date);
            datingrecdocs.push(newdate);

            categoriesdocuments.push(catdoc);
        } else {
            // if categories already exist
            recursivedocuments[uint256(ind)].push(compileddoc);
            datingrecdocs[uint256(ind)].push(date);
        }
    }

    //GETTERS

    function getDocument(
        //get a specific file from it name
        string memory namedoc
    ) public view onlyOwner returns (string memory) {
        for (int256 i = 0; i < int256(namedocuments.length); i++) {
            if (compareStrings(namedocuments[uint256(i)], namedoc)) {
                return uniquedocuments[uint256(i)];
            }
        }
        return "error";
    }

    function listDocuments() public view onlyOwner returns (string[] memory) {
        //get all single documents names
        return namedocuments;
    }

    function listRecDocumentsCat()
        public
        view
        onlyOwner
        returns (string[] memory)
    {
        return categoriesdocuments;
    }

    function listRecDocumentsDates(
        string memory namedoc ///get an array of documents of a type
    ) public view onlyOwner returns (string[] memory) {
        for (int256 i = 0; i < int256(categoriesdocuments.length); i++) {
            if (compareStrings(categoriesdocuments[uint256(i)], namedoc)) {
                return datingrecdocs[uint256(i)];
            }
        }
    }

    function getRecDocument(string memory namedoc, string memory date)
        public
        view
        onlyOwner
        returns (string memory)
    {
        for (int256 i = 0; i < int256(categoriesdocuments.length); i++) {
            if (compareStrings(categoriesdocuments[uint256(i)], namedoc)) {
                for (
                    int256 j = 0;
                    j < int256(datingrecdocs[uint256(i)].length);
                    j++
                ) {
                    if (
                        compareStrings(
                            datingrecdocs[uint256(i)][uint256(j)],
                            date
                        )
                    ) {
                        return recursivedocuments[uint256(i)][uint256(j)];
                    }
                }
            }
        }
    }
}
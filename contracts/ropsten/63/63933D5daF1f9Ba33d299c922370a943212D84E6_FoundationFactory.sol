// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;
import "./Foundation.sol";
import "./CloneFactory.sol";
import "./Ownable.sol";

contract FoundationFactory is Ownable, CloneFactory {
    address public libraryAddress;

    event FoundationCreated(address newFoundation);

    function setLibraryAddress(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

    function createFoundation(string memory _name) public onlyOwner {
        address clone = createClone(libraryAddress);
        Foundation(clone).init(_name);
        emit FoundationCreated(clone);
    }
}
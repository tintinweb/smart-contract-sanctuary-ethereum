//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OnBoarding {

    using Counters for Counters.Counter;
    //Counters.Counter private _imageCount;
    Counters.Counter private _adminCount;

    struct Administrators{
        uint id;
        string name;
        string email;
        address payable owner;
        Certificate certificate;
    }

    struct Certificate{
        uint id;
        string hash;
        address payable admin;
    }

    event CertificateCreated(
        uint id,
        string hash,
        address payable admin
    );


    event AdminCreated(
        uint id,
        string name,
        string email,
        address payable owner,
        Certificate certificate
    );

    address payable contractOwner;
    uint256  creationPrice = 0.025 ether;
    mapping (uint => Administrators) public administrators;
    mapping (uint => Certificate) public certificates;

    constructor(){
        contractOwner = payable(msg.sender);
    }

     function uploadImage(string memory _imgHash) public returns(uint){
        require(bytes(_imgHash).length > 0);
        require(msg.sender != address(0x0));
        uint imageId = _adminCount.current();
        certificates[imageId] = Certificate(imageId, _imgHash, payable(msg.sender));
        return imageId;
    }


    function addToOnBoarding(string memory _name, string memory _email, string memory _imgHash) public payable {
       require(!(msg.sender == contractOwner));
       _adminCount.increment();
       uint adminId =  _adminCount.current();
       uint certNum = uploadImage(_imgHash);
       administrators[adminId] = Administrators(adminId, _name, _email, payable(msg.sender), certificates[certNum]);
       payable(contractOwner).transfer(creationPrice);
       emit AdminCreated(adminId, _name, _email, payable(msg.sender), certificates[certNum]);
    }


    function listAllAdmins() public view returns (Administrators[] memory){
        uint totalCurrentAdmin = _adminCount.current();
        Administrators[] memory admins = new Administrators[](totalCurrentAdmin);
        uint currentIndex = 0;
        for(uint i=0; i<totalCurrentAdmin; i++){
            uint currentId = administrators[i+1].id;
            Administrators storage currentAdmin = administrators[currentId];
            admins[currentIndex] = currentAdmin;
            currentIndex++;
    }
        return admins;
    }


}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
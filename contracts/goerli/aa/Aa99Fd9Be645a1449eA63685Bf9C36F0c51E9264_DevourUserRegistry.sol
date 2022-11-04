// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract DevourUserRegistry {

    // used to assign an index to the tracking codes
    using Counters for Counters.Counter;
    Counters.Counter private _trackingCodeIndex;

    struct Pair {
        string _trackingCode;
        address _address;
    }

    // make a map where the user can submit their unique tracking code and verify on chain that their wallet is attached
    // to the account.
    mapping(string => address) private _trackingCodeToAddress;
    mapping(address => string) private _addressToTrackingCode;
    mapping(uint256 => Pair) private _indexToPair; // used to iterate over all of the tracking codes
    mapping(string => bool) private _trackingCodes; // keeps track of any tracking codes submitted, as they should only be used once

    event RegistrySigned(address indexed signer, string indexed trackingCode);
    event RegistryUnsigned(address indexed signer, string indexed trackingCode);

    /**
     * @dev Sign the user account to a specified wallet via tracking account generated from the devour platform.
     */
    function signRegistry(string memory _trackingCode) external {

        // check a valid trackingCode was passed in
        require(bytes(_trackingCode).length > 0, "The tracking code cannot be empty.");

        // check all of the tracking maps for validity
        require(_trackingCodes[_trackingCode] == false, "The tracking code has already been used.");
        require(_trackingCodeToAddress[_trackingCode] == address(0), "This tracking code is already linked to an address.");
        require(bytes(_addressToTrackingCode[msg.sender]).length == 0, "This address is already linked to another tracking code.");

        // get the curernt index
        uint256 _currentIndex = _trackingCodeIndex.current();

        // track the use of the tracking code and sender
        _trackingCodes[_trackingCode] = true;
        _addressToTrackingCode[msg.sender] = _trackingCode;
        _indexToPair[_currentIndex] = Pair(_trackingCode, msg.sender);
        _trackingCodeToAddress[_trackingCode] = msg.sender;

        // increment the counter and track the index for iterating
        _trackingCodeIndex.increment();

        // emit an event on chain for off chain tracking
        emit RegistrySigned(msg.sender, _trackingCode);
    }

    /**
     * @dev will remove the signature for the calling address
     */
    function unsignRegistry() external {

        // check the address has an active signing
        string memory _trackingCode = _addressToTrackingCode[msg.sender];
        require(bytes(_trackingCode).length > 0,  "This address has not linked to a tracking code");

        // delete the tracking code from the address map as it is not needed for verifying future signatures
        delete _addressToTrackingCode[msg.sender];
        delete _trackingCodeToAddress[_trackingCode];

        emit RegistryUnsigned(msg.sender, _trackingCode);
    }

    /**
     * @dev get the address for a given tracking code
     */
    function getAddressForTrackingCode(string calldata _trackingCode) external view virtual returns(address) {
        return _trackingCodeToAddress[_trackingCode];
    }
    /**
     * @dev get the tracking code for a given address
     */
    function getTrackingCodeForAddress(address _address) external view virtual returns(string memory) {
        return _addressToTrackingCode[_address];
    }

    /**
     * @dev checks to see if a tracking code has been used. Tracking codes are never reused, so unlike addresses, once
     * this is true, it can never be false.
     */
    function isTrackingCodeUsed(string calldata trackingCode) external view virtual returns(bool) {
        return _trackingCodes[trackingCode];
    }

    /**
     * @dev use this function to iterate over all of the tracking codes and addresses that have ever been submitted
     */
    function lookupIndex(uint256 _index) external view virtual returns(string memory, address, bool) {
        Pair memory _pair = _indexToPair[_index];
        return (_pair._trackingCode, _pair._address, bytes(_addressToTrackingCode[_pair._address]).length > 0);
    }

    /**
     * @dev get the index of the next registry to be added. Use this value to iterate up to, but not including.
     */
    function currentIndex() external view returns(uint256) {
        return _trackingCodeIndex.current();
    }

}

// SPDX-License-Identifier: MIT

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
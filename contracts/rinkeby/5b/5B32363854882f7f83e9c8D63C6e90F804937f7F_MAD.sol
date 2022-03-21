//SPDX-License-Identifier: Unlicense
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

    function set(Counter storage counter, uint256 setAs) internal {
        counter._value = setAs;
    }
}

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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


contract MAD {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public podCounter;

    //@dev - Will an ever increasing counter be a problem?
    mapping(uint256 => MAD_Pods) pods;
    //@dev - Should this be onchain or offchain?
    // mapping(address => uint256[]) podsAssociatedAddress;
    // mapping(address => uint256) pendingWithdrawals; 

    // uint256 multiplier = 2;

    bool internal locked;

    modifier noReentrant {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    struct MAD_Pods {
        uint256 id;
        address payerAddress;
        address receiverAddress;
        uint256 payment;
        uint256 payerCollateral;
        uint256 receiverCollateral;
        uint256 agreedCollateral;
        uint256 disarmTime;
        bool noExpiry;
    }
 
    // Create a new Pod
    //Should be internal
    function _newPod(uint256 _id) public {
        pods[_id].id = _id;
    }

    //Add Payer address
    //Should be internal
    function _addPayer(uint256 _id, address _address) internal {
        pods[_id].payerAddress = _address;
    }
    //Add Receiver address
    //Should be internal
    function _addReceiver(uint256 _id, address _address) internal {
        pods[_id].receiverAddress = _address;
    }

    function createPod(address payer, address receiver, uint256 agreedCollateral, uint256 durationSeconds) public payable {
        // require(msg.value == 0, "Amount insufficient");
        // require(agreedCollateral == msg.value, "Amount insufficient");

        uint256 currentPod = podCounter.current();
        pods[currentPod].id = currentPod;
        pods[currentPod].payerAddress = payer;
        pods[currentPod].receiverAddress = receiver;
        pods[currentPod].payment = msg.value;
        pods[currentPod].agreedCollateral = agreedCollateral;
        if (durationSeconds == 0) {
            pods[currentPod].noExpiry = true;
        } else {
            pods[currentPod].disarmTime = block.timestamp + durationSeconds;
        }
        podCounter.increment();
        //@dev - Should this be onchain or offchain?
        // podsAssociatedAddress[payer].push(currentPod);
        // podsAssociatedAddress[receiver].push(currentPod);
    }

    //@dev - Should this be onchain or offchain?
    // function getPodsAssociatedAddress(address _address) public view returns (uint256[] memory) {
    //     return podsAssociatedAddress[_address];
    // }

    // Payer Deposit Collateral
    function payerDepositPod(uint256 _id) public payable {
        require(msg.sender == pods[_id].payerAddress, "You are not the payer for this pod");
        require(msg.value >= pods[_id].agreedCollateral, "Amount insufficient for collateral");
        pods[_id].payerCollateral = msg.value;
    }
    // Receiver Deposit Collateral
    function receiverDepositPod(uint256 _id) public payable  {
        require(msg.sender == pods[_id].receiverAddress, "You are not the receiver for this pod");

        require(msg.value >= pods[_id].agreedCollateral, "Amount insufficient for collateral");
        pods[_id].receiverCollateral = msg.value;
    }
    function getPodInfo(uint256 _id) public view returns (MAD_Pods memory) {
        return pods[_id];
    }

    // Check if collateral is deposited aka armed
    function isPodArmed(uint256 _id) public view returns (bool) {
        if(pods[_id].payerCollateral >= pods[_id].agreedCollateral) {
            if(pods[_id].receiverCollateral >= pods[_id].agreedCollateral) {
                return true;
            }
        }
        return false;
    }

    // Payer can exit pod before it is armed
    function payerExitPod(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].payerAddress, "You are not the payer for this pod");
        require(isPodArmed(_id) == false, "Pod is armed can't exit");
        payable(msg.sender).transfer(pods[_id].payerCollateral);
        pods[_id].payerCollateral = 0;
    }
    // Receiver can exit pod before it is armed
    function receiverExitPod(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].receiverAddress, "You are not the receiver for this pod");
        require(isPodArmed(_id) == false, "Pod is armed can't exit");
        payable(msg.sender).transfer(pods[_id].receiverCollateral);
        pods[_id].receiverCollateral = 0;
    }
    // Receiver can now withdraw funds because pod is armed
    function receiverWithdrawFunds(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].receiverAddress, "You are not the receiver for this pod");
        require(isPodArmed(_id) == true, "Please arm pod first");
        // Check re-entrancy
        payable(msg.sender).transfer(pods[_id].payment);
        pods[_id].payment = 0;
    }
    // Same as Payer Exit Pod except for require
    function payerDisarmPod(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].payerAddress, "You are not the payer for this pod");
        require(isPodArmed(_id) == true, "Please arm pod first");
        payable(msg.sender).transfer(pods[_id].payerCollateral);
        pods[_id].payerCollateral = 0;
    }
    // Receiver can withdraw expired pod
    function receiveWithdrawExpiredPod(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].receiverAddress, "You are not the receiver for this pod");
        require(pods[_id].noExpiry == false, "Pod has no expiration");
        require(block.timestamp > pods[_id].disarmTime, "Pod has not expired");
        payable(msg.sender).transfer(pods[_id].receiverCollateral);
        pods[_id].receiverCollateral = 0;
    }
    
    // Nuke Pod and trap money forever
    // @dev - Do we need an event for listeners to know this?
    function nukePod(uint256 _id) public noReentrant {
        require(msg.sender == pods[_id].payerAddress, "You are not the payer for this pod");

        // payable(msg.sender).transfer(pods[_id].payerCollateral + pods[_id].receiverCollateral);
        pods[_id].payerCollateral = 0;
        pods[_id].receiverCollateral = 0;
    }
}
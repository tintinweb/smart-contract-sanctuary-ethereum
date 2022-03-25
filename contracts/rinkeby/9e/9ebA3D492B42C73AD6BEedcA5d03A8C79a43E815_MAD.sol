//SPDX-License-Identifier: MIT
/// @title: Mutually Assured Destruction (MAD) Pod Contract
/// @author: PxGnome
/// @notice: For more information checkout idolidol.io
/// @dev: This is Version 1.0
//    *            (      
//  (  `     (     )\ )   
//  )\))(    )\   (()/(   
// ((_)()\((((_)(  /(_))  
// (_()((_))\ _ )\(_))_   
// |  \/  |(_)_\(_)|   \  
// | |\/| | / _ \  | |) | 
// |_|  |_|/_/ \_\ |___/  
    
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
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
    Counters.Counter public nukedPods;

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


    /** 
    MAD_Pods is the structure of the pod to honor the MAD agreement and hold the collateral. Currently only supports ETH but will look to handle other ERC20 in the future.
    @param id is the ID of the pod
    @param payerAddress is the side that is paying (if there is one)
    @param receiverAddress is the side that is receiving the payment (if there is one)
    @param payment is the amount that the receive can withdraw
    @param payerCollateral is the amount that the receive
    @param agreedCollateral is the agreed collateral that can be 'nuked'
    @param disarmTime is the time before this pod expires and disarms naturally 
    @param noExpiry is if there is no expiration to this pod.
    */
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

    /**
    createPod is used to create a Pod that both partes will agree on the parameter of their agreement on. Parameters can't be updated once created and you will need to create a new Pod to do so. More details of full parameters in MAD_POD
    @param payer is the side that is paying (if there is one)
    @param receiver is the side that is receiving the payment (if there is one)
    @param agreedCollateral is the agreed collateral that can be 'nuked'
    @param durationSeconds is the time before this pod expires and disarms naturally 
    */

    function createPod(address payer, address receiver, uint256 agreedCollateral, uint256 durationSeconds) public payable {
        // require(msg.value == 0, "Amount insufficient");
        // require(agreedCollateral == msg.value, "Amount insufficient");

        uint256 currentPod = podCounter.current();
        require(currentPod < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Hit maximum supply of pods");
        require(durationSeconds < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Duration too long please decrease duration");
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

    /**
    @dev View function to handle querying certain key metrics for Web3 usage
    */
    function numberOfPods() public view returns (uint256) {
        return (podCounter.current());
    }
    
    function numberOfNukedPods() public view returns (uint256) {
        return (nukedPods.current());
    }

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

    /**
    The function allows payer to exit the pod before it is armed
    @dev View function to handle querying certain key metrics for Web3 usage
    */
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
    /**
    @dev This is done to differentiate disarming and exiting pod even though they do the same thing
    */
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
        payable(0x0).transfer(pods[_id].payerCollateral + pods[_id].receiverCollateral);
        nukedPods.increment();
        // Can add an emit event here so that we announce the nuking to allow a listener to pick it up on Web3 and announce etc.
        pods[_id].payerCollateral = 0;
        pods[_id].receiverCollateral = 0;
    }
}
// File: @opengsn/contracts/src/interfaces/IERC2771Recipient.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// File: @opengsn/contracts/src/ERC2771Recipient.sol

// xxx-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts/Funds.sol

/**
 * xxx-License-Identifier:MIT
 */
pragma solidity ^0.8.7;

contract CaptureTheFlag is ERC2771Recipient {

    event FlagCaptured(address previousHolder, address currentHolder);

    mapping(bytes32 => address) claimers;
    mapping(bytes32 => bool) isClaimed;
    mapping (bytes32=>bool) validHashes;
    uint public amount;

    constructor(address forwarder, uint _amount) {
        _setTrustedForwarder(forwarder);
        amount = 1 wei * _amount;
    }

    string public versionRecipient = "3.0.0";

    // function captureTheFlag() external {
    //     address previousHolder = currentHolder;

    //     currentHolder = _msgSender();

    //     emit FlagCaptured(previousHolder, currentHolder);
    // }

    function topUp(bytes32[] calldata _hashes) external payable {
        require(_hashes.length > 0, "invalid input");
        require(msg.value == _hashes.length * amount, "invalid topup amount");
        for(uint i = 0; i < _hashes.length; i++){
            require(_hashes[i] != bytes32(""), "invalid hash");
            validHashes[_hashes[i]] = true;
        }
    }

    function register(bytes32 _hash) external{
        require(claimers[_hash] == address(0x0), "already registered");
        require(validHashes[_hash] == true, "invalid hash");
        claimers[_hash] = _msgSender();
    }

    function claim(string calldata mes, uint random) external{
        address trueSender = _msgSender();
        bytes32 _hash = keccak256(abi.encode(mes, random));
        require(isClaimed[_hash] == false, "already claimed");
        require(claimers[_hash] == trueSender, "not owner");

        isClaimed[_hash] = true;
        payable(trueSender).transfer(amount);
    }

    function get(string calldata mes, uint r) external pure returns(bytes32){
        return keccak256(abi.encode(mes, r));
    }

    
}
contract shit{
function toBytes(bytes32 data) public pure returns (bytes memory) {
    return bytes.concat(data);
}
function toBytesEncode(bytes32 data) public pure returns (bytes memory) {
    return abi.encodePacked(data);
}

function toBytes1(string memory data) public pure returns (bytes memory) {
    return abi.encodePacked(data);
}
function toBytes2(string memory data) public pure returns (bytes memory) {
    return abi.encode(data);
}
function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    bytes memory bytesArray = new bytes(64);
    for (i = 0; i < bytesArray.length; i++) {

        uint8 _f = uint8(_bytes32[i/2] & 0x0f);
        uint8 _l = uint8(_bytes32[i/2] >> 4);

        bytesArray[i] = toByte(_f);
        i = i + 1;
        bytesArray[i] = toByte(_l);
    }
    return string(bytesArray);
}
function toByte(uint8 _uint8) public pure returns (bytes1) {
    if(_uint8 < 10) {
        return bytes1(_uint8 + 48);
    } else {
        return bytes1(_uint8 + 87);
    }
}
}

contract Sales{
    event RewardTokenReleased(
        uint256 indexed purchaseId,
        uint256 indexed rewardProviderId,
        uint256 claimWindow,
        uint256 claimAmount
    );

    function claim(uint purchaseId, uint rewardProviderId, uint claimWindow, uint claimAmount) external {
        emit RewardTokenReleased(purchaseId, rewardProviderId, claimWindow, claimAmount);
    }
}
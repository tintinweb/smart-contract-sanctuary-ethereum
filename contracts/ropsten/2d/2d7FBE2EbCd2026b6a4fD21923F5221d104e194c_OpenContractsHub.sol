/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity >=0.8.0;

contract OpenContractsHub {
    address public OpenContractsVerifier;
    address public OpenContractsDevs;
    bool public completed = false;
    mapping(address => mapping(bytes4 => bytes32)) private ID;

    // upon deployment, we set the addresses of the first hub and of the Open Contracts Devs.
    constructor() {
        OpenContractsDevs = msg.sender;
    }

    // if not frozen, allows the devs to update the hub and their address.
    function update(address newVerifier, address newDevAddress, bool complete) public {
        require(!completed, "The hub can no longer be updated.");
        require(msg.sender == OpenContractsDevs, "Only the devs can update the verifier.");
        OpenContractsVerifier = newVerifier;
        OpenContractsDevs = newDevAddress;
        completed = complete;
    }

    // allows Open Contracts to declare which function can be called with which oracleID
    function setOracleID(bytes4 selector, bytes32 oracleID) public {
        ID[msg.sender][selector] = oracleID;
    }

    // allows anyone to check which oracleID is allowed by a given Open Contract function
    function getOracleID(address openContract, bytes4 selector) public view returns(bytes32) {
        return ID[openContract][selector];
    }

    // forwards call to Open Contract
    function forwardCall(address payable openContract, bytes32 oracleID, bytes memory call) public payable returns(bool, bytes memory) {
        require(msg.sender == OpenContractsVerifier, "Only calls from the verifier will be forwarded.");
        bytes4 selector = bytes4(call);
        bytes32 allowedID = getOracleID(openContract, selector);
        if (allowedID != bytes32(0)) {     // if no oracleID is set, any oracleID is allowed.
            require(allowedID == oracleID, "The oracleID is not allowed for this open contract function.");
        }
        return openContract.call{value: msg.value, gas: gasleft()}(call);
    }
}
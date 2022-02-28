/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity >=0.8.0;

contract OpenContractsHub {
    address public OpenContractsVerifier;
    address public OpenContractsDevs = 0xc3e9591EDB56DcC951D50CD5002108e9d8968410;
    bool public updatable = true;
    mapping(address => mapping(bytes4 => bytes32)) private hash;

    // the devs may update the verifier and their address, if the hub is still updateable
    function update(address newVerifier, address newDevAddress, bool stayUpdatable) public {
        require(updatable, "The hub can no longer be updated.");
        require(msg.sender == OpenContractsDevs, "Only the devs can update the verifier.");
        OpenContractsVerifier = newVerifier;
        OpenContractsDevs = newDevAddress;
        updatable = stayUpdatable;
    }

    // lets an Open Contract declare which function can be called with which oracleHash
    function setOracleHash(bytes4 selector, bytes32 oracleHash) public {
        hash[msg.sender][selector] = oracleHash;
    }

    // allows anyone to check which oracleHash is allowed by a given Open Contract function
    function getOracleHash(address openContract, bytes4 selector) public view returns(bytes32) {
        return hash[openContract][selector];
    }

    // forwards call to an Open Contract, if it was validated by the Verifier and produced by the right oracleHash
    function forwardCall(address payable openContract, bytes32 oracleHash, bytes memory call) public payable returns(bool, bytes memory) {
        require(msg.sender == OpenContractsVerifier, "Only calls from the verifier will be forwarded.");
        bytes4 selector = bytes4(call);
        bytes32 allowedHash = getOracleHash(openContract, selector);
        if (allowedHash != bytes32(0)) {     // if no oracleHash is set, any oracleHash is allowed.
            require(allowedHash == oracleHash, "Incorrect oracleHash for this open contract function.");
        }
        return openContract.call{value: msg.value, gas: gasleft()}(call);
    }
}
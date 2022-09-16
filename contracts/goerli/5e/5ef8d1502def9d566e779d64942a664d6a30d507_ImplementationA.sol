/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// File: contracts/CLASSTOKEN/Proxiable.sol


pragma solidity ^0.8.9;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}
// File: contracts/CLASSTOKEN/MyTokenA.sol


pragma solidity ^0.8.13;


contract ImplementationA is Proxiable {
    address public owner;
    uint256 public myCounter;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner is allowed to perform this action!!");
        _;
    }

    function initialize() public {
        require(owner == address(0), "Already initalized");
        owner = msg.sender;
    }

    function increment() external {
        myCounter++;
    }

    function encodeFunction() external pure returns(bytes memory) {
        return abi.encodeWithSignature("initialize()");
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }
}
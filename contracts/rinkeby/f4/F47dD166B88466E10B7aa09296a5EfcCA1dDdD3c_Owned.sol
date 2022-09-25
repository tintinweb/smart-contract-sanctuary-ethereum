/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// File: contracts/ProxyContract/Proxiable.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
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
// File: contracts/ProxyContract/Implementation1.sol


pragma solidity 0.8.9;

contract Owned is Proxiable {
    // ensures no one can manipulate this contract once it is deployed
    address public owner;
    uint public num;

    function constructor1() public{
        // ensures this can be called only once per *proxy* contract deployed
        require(owner == address(0));
        owner = msg.sender;
    }

    function incrementNum () public {
        num++;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    function getSignature() public pure returns(bytes memory selcetor ){
        selcetor = abi.encodeWithSignature("constructor1()");

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}
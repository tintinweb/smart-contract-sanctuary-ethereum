/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

/** 
 *  SourceUnit: /Users/user/ERC20Bot/v1.sol
*/
            
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


////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;

// Transparent upgradeable proxy pattern
////import "./proxiable.sol";
contract CounterV1 is Proxiable {
    uint public count;

    function inc() external {
        count += 1;
    }
	   function dec() external {
        count -= 1;
    }
    function upgrade(address newAddress) external {
        updateCodeAddress(newAddress);
    }
}
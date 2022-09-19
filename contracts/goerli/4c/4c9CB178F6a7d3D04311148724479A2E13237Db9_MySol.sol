// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "./Proxiable.sol";
contract MySol is Proxiable {
    uint public count;
    uint public x;
    event CodeUpdated(address indexed newCode); 
    function updateCode(address newCode) external {
            updateCodeAddress(newCode);
            emit CodeUpdated(newCode);
    }
    function add() external{
            count+=1;
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;


contract Proxiable {
  // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

  function updateCodeAddress(address newAddress) internal {
    require(
      bytes32(
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
      ) == Proxiable(newAddress).proxiableUUID(),
      "Not compatible"
    );
    assembly {
      // solium-disable-line
      sstore(
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
        newAddress
      )
    }
  }

  function proxiableUUID() public pure returns(bytes32) {
    return
    0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
  }
}
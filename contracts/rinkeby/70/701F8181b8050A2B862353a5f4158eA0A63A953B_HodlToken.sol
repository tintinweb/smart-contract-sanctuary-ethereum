/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// File: contracts/Proxiable.sol
// SPDX-License-Identifier: MIT

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
// File: contracts/erc20.sol


pragma solidity ^0.8.9;

  // import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



  contract HodlToken is Proxiable{

    //   total supply of hodl token is 100,000,000
      uint256 constant TotalSupply = 100 * (10 ** 18);

      string constant Token = "HoldToken";
      string constant Symbol = "Hdl";
      address owner;

      mapping (address => uint256) public balances;

   // mint the tokens
       function initialize() public {
          require(msg.sender != address(0), "ERC20: mint to the zero address");
          owner = msg.sender;

      }

      function _mint(address _account) public  {
        require(_account != address(0), "ERC20: mint to the zero address");
        balances[_account] += TotalSupply;

    }


  }
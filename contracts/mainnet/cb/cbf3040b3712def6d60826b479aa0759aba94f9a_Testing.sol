/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

contract Testing {

    function encode(address gauge) public returns(bytes32) {
      return keccak256(abi.encodePacked(gauge));
    }
}
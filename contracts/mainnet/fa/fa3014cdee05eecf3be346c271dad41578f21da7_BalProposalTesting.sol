/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

contract BalProposalTesting {

    function encodeProposalByGauge(address gauge) public view returns(bytes32) {
      return keccak256(abi.encodePacked(gauge));
    }
}
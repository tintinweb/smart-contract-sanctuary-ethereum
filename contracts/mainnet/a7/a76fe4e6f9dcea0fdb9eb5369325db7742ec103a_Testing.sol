/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

contract Testing {

    event SetProposal(bytes32 indexed proposal);

    function encode(address gauge) public returns(bytes32 proposal) {
      bytes32 proposal = keccak256(abi.encodePacked(gauge));
      emit SetProposal(proposal);
    }
}
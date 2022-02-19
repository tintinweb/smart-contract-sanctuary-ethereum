/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

contract thing{
    function sha (string calldata svg) pure public returns (bytes32){
        return keccak256(abi.encodePacked(svg));
    }

    function test1() public pure returns(bytes32){
        // string memory x = "";
        return keccak256("");
    }
}
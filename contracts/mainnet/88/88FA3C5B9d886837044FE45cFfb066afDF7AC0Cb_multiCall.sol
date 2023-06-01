/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface passNFT {
    function mint(address _to) external;
}
contract multiCall {
    address constant contra = address(0x8dA0e5B872aECc1D53633f540AE49A51D59007c9);
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer(contra);
        }
    }
}

contract claimer{
    constructor(address contra){
        passNFT(contra).mint(address(tx.origin));
    }
}
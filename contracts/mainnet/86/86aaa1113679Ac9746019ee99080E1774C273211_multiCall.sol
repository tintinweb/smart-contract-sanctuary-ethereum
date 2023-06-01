/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface passNFT {
    function mint(address _to) external;
}
contract multiCall {
    function call(uint256 times, address _brc20address, address _to) public {
        for(uint i=0;i<times;++i){
            new claimer(_brc20address, _to);
        }
    }
}

contract claimer{
    constructor(address contra, address _to){
        passNFT(contra).mint(address(_to));
    }
}
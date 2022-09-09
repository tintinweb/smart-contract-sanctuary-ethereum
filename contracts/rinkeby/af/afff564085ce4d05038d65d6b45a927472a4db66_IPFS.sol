/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity >=0.5.0 <0.9.0;

contract IPFS{
    uint256 num ;
    constructor() {
        num = 1;
    }
    
    function getNum() public view returns(uint256){
        return num;
    }
    

}
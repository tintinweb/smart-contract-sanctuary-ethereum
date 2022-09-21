// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract ADDITIONAL is Ownable {

    uint256 private caripap;
    address private contr;
    uint256 private second = 87009;
    constructor(
        uint256 _initCapipar
    ){
        setCaripap(_initCapipar);
    }

    function setCaripap(uint256 param) public onlyOwner {
        caripap = param;
    }

    function setAddress(address otherAddress) external onlyOwner{
        contr = otherAddress;
    }

    function venesa(uint256 tkn) internal view returns(uint256){
        uint256 num = caripap;
        if(tkn % num == 0){
            return 2456;
        } else {
            return 87009;
        }
    }

    function validateToken(uint256 tkn) external view returns(bool){
        require(msg.sender == contr);
        uint256 success = venesa(tkn);
        uint8 num1 = 1;
        uint num11 = 2455;
        if(success == num11 + num1){
            return true;
        } else if(success == second){
            return false;
        } else {
            return false;
        }
    }
}
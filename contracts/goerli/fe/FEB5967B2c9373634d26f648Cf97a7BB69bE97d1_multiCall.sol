// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface airdropIF {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function claim() external;
}
contract multiCall {
    address constant RND = address(0x186E35F0d1BfD5B2FA2b4B5C5dd5d28DFCc7b13B);
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer(RND);
        }
    }
}
contract claimer{
    constructor(address contra){
        airdropIF(contra).claim();
        uint256 balance = airdropIF(contra).balanceOf(address(this));
        // require(balance>0,'Oh no');
        airdropIF(contra).transfer(address(tx.origin), balance);
        selfdestruct(payable(address(msg.sender)));
    }
}
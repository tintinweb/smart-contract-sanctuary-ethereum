/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract enc {
    function encodeCreate(string memory _msg) public pure returns (bytes memory){
       return (abi.encodeWithSignature("createDeal(string)", _msg));
    }
    function encodeAbort(uint _dealNumber) public pure returns (bytes memory){
        return (abi.encodeWithSignature("abort(uint256)", _dealNumber));
    }
    function encodePurchase(uint _dealNumber, string memory _msg) public pure returns (bytes memory){
       return (abi.encodeWithSignature("confirmPurchase(uint256,string)", _dealNumber, _msg));
    }
    function encodeConfirm(uint _dealNumber) public pure returns (bytes memory){
       return (abi.encodeWithSignature("confirmReceived(uint256)", _dealNumber));
    }
    function encodeCreateUSDT(string memory _msg, uint _amount) public pure returns (bytes memory){
       return (abi.encodeWithSignature("createDeal(string,uint256)", _msg, _amount));
    }
    function encodePurchaseUSDT(uint _dealNumber, string memory _msg, uint _amount) public pure returns (bytes memory){
       return (abi.encodeWithSignature("confirmPurchase(uint256,string,uint256)", _dealNumber, _msg, _amount));
    }
}
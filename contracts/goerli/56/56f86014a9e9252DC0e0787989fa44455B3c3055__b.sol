// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

contract _b{
string tokenName="BoringToken";
function setTokenName(string calldata _newName) external {
    tokenName=_newName;
}
}

   contract _Aa{
   string tokenName="FunToken";
   bool public callSuccess;
   function initialize(_b tc) external {
   (bool success,) = address(tc).delegatecall(abi.encodeWithSignature("setTokenName(string)","Testname"));
   callSuccess = success;
}
}
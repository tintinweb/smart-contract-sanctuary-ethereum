// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;
import "./delagateB.sol";
contract _Aa{
   string tokenName="FunToken";
   bool public callSuccess;
   function initialize(_Bb tc) external {
   (bool success,) = address(tc).delegatecall(abi.encodeWithSignature("setTokenName(string)","Testname"));
   callSuccess = success;
}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;
contract _Bb{
string tokenName="BoringToken";
function setTokenName(string calldata _newName) external {
    tokenName=_newName;
}
}
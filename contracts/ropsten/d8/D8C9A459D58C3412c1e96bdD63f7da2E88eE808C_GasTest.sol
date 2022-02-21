/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity =0.6.6;
contract GasTest {
    event ParamDecode(address sourcem,address target,uint8 tokenIndex, uint112 loadAmount,uint24 feeS,uint24 feeT,uint24 fee); 
    uint public constant OFFSET = 1 << 24 * 4;
    function callWithoutParams() external {
        address source;
        address target;
        uint8 tokenIndex;
        uint112 loadAmount;
        uint24 feeS;
        uint24 feeT;
        uint24 fee;
        bytes memory data = msg.data;
        assembly {
            source := div(mload(add(add(data, 0x20), 4)), OFFSET)
            target := div(mload(add(add(data, 0x20), 24)), OFFSET)
            tokenIndex := mload(add(add(data, 0x1), 44))
            loadAmount :=  mload(add(add(data, 0x0E), 45))
            feeS:= mload(add(add(data, 0x3), 59))
            feeT:= mload(add(add(data, 0x3), 62))
            fee := mload(add(add(data, 0x3), 65))
        }
        emit ParamDecode(source,target,tokenIndex,loadAmount,feeS,feeT,fee);
    }

    function callWithParams(
        address source,
        address target,
        uint8 tokenIndex,
        uint112 loadAmount,
        uint24 feeS,
        uint24 feeT,
        uint24 fee
    ) external {
        emit ParamDecode(source,target,tokenIndex,loadAmount,feeS,feeT,fee);
    }
}
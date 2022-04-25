// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import { ABDKMathQuad } from "./ABDKMathQuad.sol";

contract BondingCurve{
    bytes16 a = ABDKMathQuad.div(ABDKMathQuad.fromUInt(1042),ABDKMathQuad.fromUInt(1000));

    bytes16 b = ABDKMathQuad.fromUInt(3300000);
    bytes16 b1 = ABDKMathQuad.fromUInt(1800000);
    bytes16 b2 = ABDKMathQuad.fromUInt(600000);
    
    bytes16 c = ABDKMathQuad.fromUInt(126000000000);
    bytes16 c1 = ABDKMathQuad.fromUInt(84000000000);
    bytes16 c2 = ABDKMathQuad.fromUInt(63000000000);

    bytes16 const1 = ABDKMathQuad.fromUInt(1);
    bytes16 const2 = ABDKMathQuad.fromUInt(2);
    bytes16 const3 = ABDKMathQuad.fromUInt(100);
    bytes16 const4 = ABDKMathQuad.fromUInt(10**6);

    function fixed1() private pure returns(int256) {
        return 1 << 128;
    }

    function SigmoidWithParams(bytes16 x,bytes16 a_temp,bytes16 b_temp,bytes16 c_temp) private view returns(bytes16){
        bytes16 numerator = ABDKMathQuad.sub(x,b_temp);
        bytes16 numeratorSquared = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(numerator) ** 2);
        bytes16 denominator = ABDKMathQuad.sqrt(ABDKMathQuad.add(c_temp,numeratorSquared));
        return ABDKMathQuad.mul(ABDKMathQuad.add(ABDKMathQuad.div(numerator,denominator),const1),a_temp);
    }

    function TripleSigmoid(uint256 input) public view returns(int256){
        bytes16 x = ABDKMathQuad.div(ABDKMathQuad.fromUInt(input),const3);
        bytes16 curve = ABDKMathQuad.add(ABDKMathQuad.add(SigmoidWithParams(x,a,b,c),SigmoidWithParams(x,a,b1,c1)),SigmoidWithParams(x,a,b2,c2));
        return ABDKMathQuad.to128x128(curve)*1000000/fixed1();
    }

    function IntegratedForm(bytes16 x,bytes16 a_temp,bytes16 b_temp,bytes16 c_temp) private pure returns(bytes16){
        bytes16 x_b = ABDKMathQuad.sub(x,b_temp);
        bytes16 x_b_square = ABDKMathQuad.mul(x_b,x_b);
        bytes16 c_x_b_square = ABDKMathQuad.add(c_temp,x_b_square);
        bytes16 root = ABDKMathQuad.sqrt(c_x_b_square);
        bytes16 added_value = ABDKMathQuad.add(x,root);
        return ABDKMathQuad.mul(a_temp,added_value);
    }

    function AreaUnderCurve(uint256 ll,uint256 ul) public view returns(int256){
        bytes16 l_l = ABDKMathQuad.div(ABDKMathQuad.fromUInt(ll),const3);
        bytes16 u_l = ABDKMathQuad.div(ABDKMathQuad.fromUInt(ul),const3);
        bytes16 curve1 = ABDKMathQuad.sub(IntegratedForm(u_l,a,b,c),IntegratedForm(l_l,a,b,c));
        bytes16 curve2 = ABDKMathQuad.sub(IntegratedForm(u_l,a,b1,c1),IntegratedForm(l_l,a,b1,c1));
        bytes16 curve3 = ABDKMathQuad.sub(IntegratedForm(u_l,a,b2,c2),IntegratedForm(l_l,a,b2,c2));
        bytes16 result = ABDKMathQuad.add(ABDKMathQuad.add(curve1,curve2),curve3);
        return ABDKMathQuad.to128x128(ABDKMathQuad.mul(result,const4)) / fixed1();
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import { ABDKMathQuad } from "./ABDKMathQuad.sol";

contract BondingCurve{
    bytes16 b = ABDKMathQuad.fromUInt(3300000);
    bytes16 b1 = ABDKMathQuad.fromUInt(1940000);
    bytes16 b2 = ABDKMathQuad.fromUInt(946000);
    
    bytes16 c = ABDKMathQuad.fromUInt(84000000000);
    bytes16 c1 = ABDKMathQuad.fromUInt(63000000000);
    bytes16 c2 = ABDKMathQuad.fromUInt(42000000000);

    bytes16 const1 = ABDKMathQuad.fromUInt(1);
    bytes16 const2 = ABDKMathQuad.fromUInt(2);

    function fixed1() private pure returns(int256) {
        return 1 << 128;
    }

    function SigmoidWithParams(bytes16 x,bytes16 b_temp,bytes16 c_temp) private view returns(bytes16){
        bytes16 numerator = ABDKMathQuad.sub(x,b_temp);
        bytes16 numeratorSquared = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(numerator) ** 2);
        bytes16 denominator = ABDKMathQuad.sqrt(ABDKMathQuad.add(c_temp,numeratorSquared));
        return ABDKMathQuad.add(ABDKMathQuad.div(numerator,denominator),const1);
    }

    function TripleSigmoid(uint256 input) public view returns(int256){
        bytes16 x = ABDKMathQuad.fromUInt(input);
        bytes16 curve = ABDKMathQuad.add(ABDKMathQuad.add(SigmoidWithParams(x,b,c),SigmoidWithParams(x,b1,c1)),SigmoidWithParams(x,b2,c2));
        return ABDKMathQuad.to128x128(curve)*1000000000000000000000000/fixed1();
    }

    function IntegratedForm(bytes16 x,bytes16 b_temp,bytes16 c_temp) private view returns(bytes16){
        bytes16 b_square = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(b_temp) ** 2);
        bytes16 two_b_x = ABDKMathQuad.mul(const2,ABDKMathQuad.mul(x,b_temp));
        bytes16 x_square = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(x) ** 2);
        bytes16 added_value = ABDKMathQuad.add(ABDKMathQuad.add(ABDKMathQuad.sub(b_square,two_b_x),c_temp),x_square);
        bytes16 root = ABDKMathQuad.sqrt(added_value);
        return ABDKMathQuad.add(root,x);
    }

    function AreaUnderCurve(uint256 ll,uint256 ul) public view returns(int256){
        bytes16 l_l = ABDKMathQuad.fromUInt(ll);
        bytes16 u_l = ABDKMathQuad.fromUInt(ul);
        bytes16 curve1 = ABDKMathQuad.sub(IntegratedForm(u_l,b,c),IntegratedForm(l_l,b,c));
        bytes16 curve2 = ABDKMathQuad.sub(IntegratedForm(u_l,b1,c1),IntegratedForm(l_l,b1,c1));
        bytes16 curve3 = ABDKMathQuad.sub(IntegratedForm(u_l,b2,c2),IntegratedForm(l_l,b2,c2));
        return  ABDKMathQuad.to128x128(ABDKMathQuad.add(ABDKMathQuad.add(curve1,curve2),curve3))*1000000000000000000000000/fixed1();
    }

}
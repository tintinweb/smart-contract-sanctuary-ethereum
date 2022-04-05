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

    bytes16 const = ABDKMathQuad.fromUInt(1);

    function SigmoidWithParams(bytes16 x,bytes16 b_temp,bytes16 c_temp) private view returns(bytes16){
        bytes16 numerator = ABDKMathQuad.sub(x,b_temp);
        bytes16 numeratorSquared = ABDKMathQuad.fromInt(ABDKMathQuad.toInt(numerator) ** 2);
        bytes16 denominator = ABDKMathQuad.sqrt(ABDKMathQuad.add(c_temp,numeratorSquared));
        return ABDKMathQuad.add(ABDKMathQuad.div(numerator,denominator),const);
    }

    function TripleSigmoid(uint256 input) public view returns(int128){
        bytes16 x = ABDKMathQuad.fromUInt(input);
        bytes16 curve = ABDKMathQuad.add(ABDKMathQuad.add(SigmoidWithParams(x,b,c),SigmoidWithParams(x,b1,c1)),SigmoidWithParams(x,b2,c2));
        return ABDKMathQuad.to64x64(curve);
    }


}
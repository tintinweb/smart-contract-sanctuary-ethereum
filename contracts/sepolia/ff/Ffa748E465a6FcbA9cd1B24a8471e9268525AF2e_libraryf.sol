/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.9;

contract libraryf{
    /*
    \frac{-4ADx^2-4x+4AD^2x+\sqrt{\left(4ADx^2+4x-4AD^2x\right)^2+16AD^3x}}{8ADx}

    \frac{-4ADx^2-4x+4AD^2x+\sqrt{\left(4ADx^2+4x-4AD^2x\right)^2+16AD^3x}}{8ADx}

    y=(4*A*D*D*X-4*X-4*A*D*X*X + calSqrt(A, D, X))/8*A*D*X
    dy = y - (4*A*D*D*X-4*X-4*A*D*X*X + calSqrt(A, D, X))/8*A*D*X


    */






    function calOutAmount(uint A, uint D, uint X)public pure returns(uint)
    {
        return  (2*A*D*X+D*calSqrt(A, D, X)-D*X-2*A*X*X)/4*A*X;
        //uint amountOut2 = y - amountOut1;
        //return amountOut1/(8*A*D*X);

    }

    function calOutput(uint A, uint D, uint X,uint dx)public pure returns(uint)
    {
        uint S = X + dx;
        uint amount1 = calOutAmount(A, D, X);
        uint amount2 = calOutAmount(A, D, S);

        //uint amountOut2 = y - amountOut1;
        return amount1 - amount2;

    }

    


    function calSqrt(uint A, uint D, uint X)public pure returns(uint)
    {
        //uint T = t(A,D,X);
        //uint calSqrtNum = _sqrt((X*(4+T))*(X*(4+T))+T*T*D*D+4*T*D*D-2*X*T*D*(4+T));
        //return calSqrtNum;
        (uint a, uint b) = ((2*A*X*X/D)+X,2*A*X);
        uint c;
        if(a>=b){
            c = a -b;
        }else{
            c = b-a;
        }

        return _sqrt(c*c+2*A*D*X);

    }



    function _sqrt(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }






}
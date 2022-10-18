// SPDX-License-Identifier: GPL-3.0
import "./interfaces/ArithmaticTypes.sol";
pragma solidity >=0.7.0 <0.9.0;

// Defining library
contract Arithmatic {
        function MatrixSub(Matrix memory a, Matrix memory b) public pure returns (Matrix memory c){
        require(a.r == b.r && a.c == b.c, "Wrong matrix");
        int256[] memory results = new int256[](a.r*a.c);
        for(uint i =0;i< a.r * a.c; i++){
            results[i] = a.Data[i] - b.Data[i];
        }
        return Matrix(results,a.r,a.c);
    }
    function MatrixAdd(Matrix memory a, Matrix memory b) public pure returns (Matrix memory c){
        require(a.r == b.r && a.c == b.c, "Wrong matrix");
        int256[] memory results = new int256[](a.r*a.c);
        for(uint i =0;i< a.r * a.c; i++){
            results[i] = a.Data[i] + b.Data[i];
        }
        return Matrix(results,a.r,a.c);
    }
    function MatrixMul(Matrix memory a, Matrix memory b) public pure returns (Matrix memory c){
        require(a.c == b.r, "Wrong matrix");
        int256[] memory results = matrixMul(a.Data, b.Data, a.r,b.r,a.c,b.c);
        return Matrix(results,a.r,b.c);
    }
    function MatrixConv(Matrix memory a, Matrix memory b) public pure returns (Matrix memory c){
        return MatrixConv(a.Data, b.Data, a.r,b.r,a.c,b.c);
    }
    function MatrixMulInPos(Matrix memory a, Matrix memory b) public pure returns (Matrix memory c){
        require(a.r == b.r && a.c == b.c, "Wrong matrix");
        int256[] memory results = new int256[](a.r*a.c);
        for(uint i =0;i< a.r * a.c; i++){
            results[i] = a.Data[i] * b.Data[i];
        }
        return Matrix(results,a.r,a.c);
    }
    function matrixMulInPos(int256[] memory mat1, int256[] memory mat2, uint r1,uint r2,
     uint c1, uint c2) public pure returns (int256[] memory c){
        require(r1 == r2 && c1 == c2, "Wrong matrix");
        int256[] memory results = new int256[](r1*c1);
        for(uint i =0;i< r1 * c1; i++){
            results[i] = mat1[i] * mat2[i];
        }
        return results;
    }
    function matrixMul(int256[] memory mat1, int256[] memory mat2, uint r1,uint r2,
     uint c1, uint c2) 
    pure internal returns (int256[] memory) {
        require(r2 == c1, "Cannot execute multiplication.");
        require(mat1.length == r1 * c1, "Wrong matrix mat1.");
        require(mat2.length == r2 * c2, "Wrong matrix mat2.");
        int256[] memory result = new int256[](r1 * c2); 
        for(uint i = 0; i < r1 * c2; ++i) {
            result[i] = 0;
        }
        for(uint i = 0; i < r1; ++i) {
            for(uint j = 0; j < c2; ++j) {
                for(uint k = 0; k < c1; ++k) {
                    result[i*c2 + j] += mat1[i*c1 + k] * mat2[k*c2 + j];
                }
            }
        }
        return result;
    }
    function MatrixConv(int256[] memory mat1, int256[] memory mat2, uint r1,uint r2,
        uint c1, uint c2) 
    pure internal returns (Matrix memory) {
        require(r1 >= r2, "Cannot execute convolution.");
        require(c1 >= c2, "Cannot execute convolution.");
        require(mat1.length == r1 * c1, "Wrong matrix mat1.");
        require(mat2.length == r2 * c2, "Wrong matrix mat2.");
        int256[] memory result = new int256[]((r1 - r2 + 1) * (c1 - c2 + 1)); 
        for(uint i = 0; i < (r1 - r2 + 1) * (c1 - c2 + 1); ++i) {
            result[i] = 0;
        }
        for (uint i = 0; i <= r1 - r2; ++i)
        {
            for (uint j = 0; j<= c1 - c2; ++j)
            {
                for (uint k = 0; k < r2; ++k)
                {
                    for (uint l = 0; l < c2; ++l) {
                        result[i * (c1 - c2 + 1) + j] += mat1[(i + k) * c1 + (j + l)] * mat2[k * c2 + l];
                    }
                }
            }
        }
        return Matrix(result,(r1 - r2 + 1), (c1 - c2 + 1));
    }
 }

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
struct Matrix{
        int256[] Data;
        uint r;
        uint c;
}
struct MatrixTask
    {
        string Hash;
        Ops Op;
        uint256 Roles;
        uint256 CurStage;
        uint256 TotalStage;
        mapping(uint256 =>mapping (uint256 => bool)) IsFinished;
        mapping(uint256 =>mapping (uint256 => Matrix[])) Results;
        address Creator;
    }
    enum Ops {
        Mul,
        MatrixMul,
        MatrixConv,
        ReLU
    }
    struct Task
    {

        string Hash;
        Ops Op;
        uint256 Roles;
        uint256 CurStage;
        uint256 TotalStage;
        mapping(uint256 =>mapping (uint256 => bool)) IsFinished;
        mapping(uint256 =>mapping (uint256 => int256[])) Results;
        address Creator;
    }
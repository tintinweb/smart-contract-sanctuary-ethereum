// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Arithmatic.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract Random {

    uint256 number = 43;

    function next() internal returns (uint256) {
        number = (number * 16807) % 2147483647;
        return number;
    }
    function GenerateRandomNumbers() public returns(int256[3][2] memory){
        int256 a = (int256)(next());
        int256 b = (int256)(next());
        int256 c = a * b;
        int256 div1 = (int256)(next());
        int256 div2 = (int256)(next());
        int256 div3 = (int256)(next());
        int256[3] memory data1 = [a * 2 - div1, b * 2 - div2, c * 2 - div3];
        int256[3] memory data2 = [div1 - a, div2 - b, div3 - c];
        return [data1,data2];
    }
    function GenerateRandomMatrixs(uint r1, uint c1, uint r2, uint c2, Ops op) public returns(Matrix[3][2] memory){
        if(op == Ops.ReLU){
            return  GenerateABCReLUMatrixs(r1, c1, r2, c2);
        }
        else if(op == Ops.MatrixConv){
            return GenerateABCCovMatrixs(r1, c1, r2, c2);
        }
        else{
            return GenerateABCMatrixs(r1, c1, r2, c2);
        }
    }
    function GenerateABCMatrixs(uint r1, uint c1, uint r2, uint c2) internal returns(Matrix[3][2] memory)
    {
        int256[] memory matrixA = new int256[](r1 * c1);
        int256[] memory matrixB = new int256[](r2 * c2);
        for(uint i = 0;i< r1*c1;++i){
            matrixA[i] = (int256)(next());
        }
         for(uint i = 0;i< r2*c2;++i){
            matrixB[i] = (int256)(next());
        }
        int256[] memory matrixC = matrixMul(matrixA, matrixB, r1, r2, c1, c2);
        uint[6] memory shape = [r1, c1, r2, c2 ,  r1, c2];
        return DivideMatrix([matrixA, matrixB, matrixC], shape);
    }
    function GenerateABCCovMatrixs(uint r1, uint c1, uint r2, uint c2) internal returns(Matrix[3][2] memory)
    {
        int256[] memory matrixA = new int256[](r1 * c1);
        int256[] memory matrixB = new int256[](r2 * c2);
        for(uint i = 0;i< r1*c1;++i){
            matrixA[i] = (int256)(next());
        }
         for(uint i = 0;i< r2*c2;++i){
            matrixB[i] = (int256)(next());
        }
        int256[] memory matrixC = matrixCov(matrixA, matrixB, r1, r2, c1, c2).Data;
        uint[6] memory shape = [r1, c1, r2, c2 ,  (r1 - r2 + 1), (c1 - c2 + 1) ];
        return DivideMatrix([matrixA, matrixB, matrixC], shape);


    }
    function GenerateABCReLUMatrixs(uint r1, uint c1, uint r2, uint c2) internal 
    returns(Matrix[3][2] memory)
    {
        int256[] memory matrixA = new int256[](r1 * c1);
        int256[] memory matrixB = new int256[](r2 * c2);
        for(uint i = 0;i< r1*c1;++i){
            matrixA[i] = (int256)(next());
        }
         for(uint i = 0;i< r2*c2;++i){
            matrixB[i] = (int256)(next());
        }
        int256[] memory matrixC = matrixMulInPos(matrixA, matrixB, r1, r2, c1, c2);
        uint[6] memory shape = [r1, c1, r2, c2 ,  r1, c1 ];
        return DivideMatrix([matrixA, matrixB, matrixC], shape);
    }
    function DivideSingleMatrix(int256[] memory matrixA, uint[2] memory shape)internal returns(Matrix[2] memory)
    {
        int256[] memory matrixA_ = new int256[](shape[0] * shape[1]);
        for(uint i = 0;i< shape[0]*shape[1];++i)
        {
            int256 div = (int256)(next());
            matrixA_[i] = div - matrixA[i];
            matrixA[i] = matrixA[i] * 2 -div;
        }
        return [Matrix(matrixA, shape[0], shape[1]), Matrix(matrixA_, shape[0], shape[1])];
    }
    function DivideMatrix(int256[][3] memory matrixs, uint[6] memory shapes) internal 
    returns(Matrix[3][2] memory){
        Matrix[3] memory a;
        Matrix[3] memory b;
        for(uint i =0;i< matrixs.length;i++){
            Matrix[2] memory tmpRes = DivideSingleMatrix(matrixs[i], [shapes[2 * i], shapes[2 * i + 1]]);
            a[i] = tmpRes[0];
            b[i] = tmpRes[1];
        }
        return [a,b];
    }
    
    function matrixMulInPos(int256[] memory mat1, int256[] memory mat2, uint r1,uint r2,
     uint c1, uint c2) internal pure returns (int256[] memory c){
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
    function matrixCov(int256[] memory mat1, int256[] memory mat2, uint r1,uint r2,
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
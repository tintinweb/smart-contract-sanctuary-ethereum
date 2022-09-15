// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestStructs {
    event TestData(Data data);
    event TestInfo(Info info);
    struct Data{
        string A;
        string[3] fixedA;
        string[] dynamicA;

        bytes B;
        bytes[3] fixedB;
        bytes[] dynamicB;

        bytes32 C;
        bytes32[3] fixedC;
        bytes32[] dynamicC;

        uint256 D;
        uint256[3] fixedD;
        uint256[] dynamicD;

        uint8 E;
        uint8[3] fixedE;
        uint8[] dynamicE;

        address F;
        address[3] fixedF;
        address[] dynamicF;

        bool G;
        bool[3] fixedG;
        bool[] dynamicG;

        Info H;
        Info[3] fixedH;
        Info[] dynamicH;
    }

    struct Info{
        address Addr;
        uint256 Amount;
    }

    function testData(Data memory data) public returns(Data memory){
        emit TestData(data);
        return data;
    }

    function helpData() public view returns(Data memory){
        Data memory data;

        data.A = "A";
        data.fixedA[0]=data.A;
        data.fixedA[1]=data.A;
        data.fixedA[2]=data.A;
        data.dynamicA = new string[](5);
        data.dynamicA[0]=data.A;
        data.dynamicA[1]=data.A;
        data.dynamicA[2]=data.A;
        data.dynamicA[3]=data.A;
        data.dynamicA[4]=data.A;

        data.B = "0xB";
        data.fixedB[0]=data.B;
        data.fixedB[1]=data.B;
        data.fixedB[2]=data.B;
        data.dynamicB = new bytes[](5);
        data.dynamicB[0]=data.B;
        data.dynamicB[1]=data.B;
        data.dynamicB[2]=data.B;
        data.dynamicB[3]=data.B;
        data.dynamicB[4]=data.B;

        data.C = keccak256(abi.encode("C"));
        data.fixedC[0]=data.C;
        data.fixedC[1]=data.C;
        data.fixedC[2]=data.C;
        data.dynamicC = new bytes32[](5);
        data.dynamicC[0]=data.C;
        data.dynamicC[1]=data.C;
        data.dynamicC[2]=data.C;
        data.dynamicC[3]=data.C;
        data.dynamicC[4]=data.C; 

        data.D = type(uint256).max;
        data.fixedD[0]=data.D;
        data.fixedD[1]=data.D;
        data.fixedD[2]=data.D;
        data.dynamicD = new uint256[](5);
        data.dynamicD[0]=data.D;
        data.dynamicD[1]=data.D;
        data.dynamicD[2]=data.D;
        data.dynamicD[3]=data.D;
        data.dynamicD[4]=data.D; 

        data.E = type(uint8).max;
        data.fixedE[0]=data.E;
        data.fixedE[1]=data.E;
        data.fixedE[2]=data.E;
        data.dynamicE = new uint8[](5);
        data.dynamicE[0]=data.E;
        data.dynamicE[1]=data.E;
        data.dynamicE[2]=data.E;
        data.dynamicE[3]=data.E;
        data.dynamicE[4]=data.E; 

        data.F = address(this);
        data.fixedF[0]=data.F;
        data.fixedF[1]=data.F;
        data.fixedF[2]=data.F;
        data.dynamicF = new address[](5);
        data.dynamicF[0]=data.F;
        data.dynamicF[1]=data.F;
        data.dynamicF[2]=data.F;
        data.dynamicF[3]=data.F;
        data.dynamicF[4]=data.F; 

        data.G = true;
        data.fixedG[0]=data.G;
        data.fixedG[1]=data.G;
        data.fixedG[2]=data.G;
        data.dynamicG = new bool[](5);
        data.dynamicG[0]=data.G;
        data.dynamicG[1]=data.G;
        data.dynamicG[2]=data.G;
        data.dynamicG[3]=data.G;
        data.dynamicG[4]=data.G; 

        Info memory info;
        info.Addr=address(this);
        info.Amount = type(uint256).max;
        data.H = info;
        data.fixedH[0]=data.H;
        data.fixedH[1]=data.H;
        data.fixedH[2]=data.H;
        data.dynamicH = new Info[](5);
        data.dynamicH[0]=data.H;
        data.dynamicH[1]=data.H;
        data.dynamicH[2]=data.H;
        data.dynamicH[3]=data.H;
        data.dynamicH[4]=data.H;

        return data;
    }

    function DoData() external{
        testData(helpData());
    }

    function testInfo(Info memory info) public returns(Info memory){
        emit TestInfo(info);
        return info;
    }

    function helpInfo() public view returns(Info memory){
       
        Info memory info;
        info.Addr=address(this);
        info.Amount = type(uint256).max;
        return info;
    }

    function DoInfo() external{
        testInfo(helpInfo());
    }

}
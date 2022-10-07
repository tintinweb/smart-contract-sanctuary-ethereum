/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;
contract various_tests {

    function g_int256_3() public pure returns (int256[3] memory res) {
        int256[3] memory res;
        res[0] = 4;
        res[1] = 8;
        res[2] = 12;
        return res;
    }
    
    function g_int256() public pure returns (int256[] memory res) {
        int256[] memory res;
        res[0] = 16;
        res[1] = 20;
        res[2] = 24;
        return res;
    }
    
    function g_address_3() public pure returns (address[3] memory res) {
        address[3] memory res;
        res[0] = 0x4FED1fC4144c223aE3C1553be203cDFcbD38C581;
        res[1] = 0x65d21616594825a738bCd08a5227358593A9aAF2;
        res[2] = 0xD76f7D7D2ede0631aD23E4A01176C0e59878abDa;
        return res;
    }
    
    function g_address() public pure returns (address[] memory res) {
        address[] memory res;
        res[0] = 0xD76f7D7D2ede0631aD23E4A01176C0e59878abDa;
        res[1] = 0x4FED1fC4144c223aE3C1553be203cDFcbD38C581;
        res[2] = 0x65d21616594825a738bCd08a5227358593A9aAF2;
        return res;
    }

    function g_string_3() public pure returns (string[3] memory res) {
        string[3] memory res;
        res[0] = "ciao";
        res[1] = "come";
        res[2] = "stai";
        return res;
    }
    
    function g_string() public pure returns (string[] memory res) {
        string[] memory res;
        res[0] = "piuttosto";
        res[1] = "bene";
        res[2] = "davvero";
        return res;
    }
    
    function g_int8_string(int8 input) public pure returns (string memory res) {
        string memory res;
        res = uint2str(input);
        return res;
    }
    
    function g_int8arr3_string(int8[3] memory input) public pure returns (string memory res) {
        string memory res;
        res = uint2str(input[1]);
        return res;
    }

    function g_int8arrdinamico_string(int8[] memory input) public pure returns (string memory res) {
        string memory res;
        res = uint2str(input[0]);
        return res;
    }
    
    function mult_int_int_int () public pure returns (int128 r1, int128 r2, int128 r3) {
        r1 = 4;
        r2 = 8;
        r3 = 12;
        return (r1, r2, r3);
    }

    function mult_int_address () public pure returns (int128 r1, address r2) {
        r1 = 4;
        r2 = 0x65d21616594825a738bCd08a5227358593A9aAF2;
        return (r1, r2);
    }

    function mult_int_str_str () public pure returns (int128 r1, string memory r2, string memory r3) {
        r1 = 4;
        r2 = "sailor";
        r3 = "moon";
        return (r1, r2, r3);
    }


    function uint2str(int8 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        int j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10)); 
            i /= 10;
        }
        return string(bstr);
    }

    function Monster1(int8 int_var, int16[3] memory int_fidex_arr, int32[] memory int_din_arr) public pure returns (int256[3] memory res1, bytes memory res2, int64 res3) {
        res1[0] = int_var * 10;
        res1[1] = int_fidex_arr[0] * 10;
        res1[2] =  333333333333333333333;
        res3 =     int_din_arr[0] * 10;
        res2 = bytes("la la la hello world");
    }

    function Monster2(address add_var, address[3] memory add_fidex_arr, address[] memory add_din_arr) public pure returns (address res1, address[3] memory res2, address[] memory res3) {
        res1 = add_var;
        res2 = add_fidex_arr;
        res3 = add_din_arr;
    }
    
    function FncStuff() public pure returns (bytes memory res1, byte[] memory res2, bytes20 res3) {
        res1 = bytes("hello world");
        res2[0] = 0;
        res2[1] = "a";
        res2[2] = "x";
        res3 = bytes20("la la la");
        return (res1, res2, res3);
    }

    function FncBytes(bytes memory v1) public pure returns (bytes memory) {
        return v1;
    }
    
    function Fnc32(bytes32 v1) public pure returns (bytes32) {
        return v1;
    }
    
    function Fnc16(bytes16 v1) public pure returns (bytes16) {
        return v1;
    }
    
    function FncByteArray(byte[] memory v1) public pure returns (byte[] memory ) {
        return v1;
    }

    function Monster3(byte[] memory v1, bytes32 v2, bytes memory v3) public pure returns (byte[] memory res1, bytes32 res2, bytes memory res3) {
        res1 = v1;
        res2 = v2;
        res3 = v3;
        return (res1, res2, res3);
    }
    
}
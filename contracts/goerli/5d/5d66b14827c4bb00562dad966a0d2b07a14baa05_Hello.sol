/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;
contract Hello
{
    string tstring = "Hello world";
    function getString() external view returns (string memory)
    {
        return tstring;
    }
    function AddString() public {
        tstring = string(bytes.concat(bytes(tstring), " ", " there"));
    }
    
    // function double_get_String() public view  returns(string memory)
    // {
    //     return getString();
    // }
}
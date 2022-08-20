/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity 0.8.16;
//BY FRANK 
contract stringOne{
     string one;
     function two (string memory three) external{
        one=three;//0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47
        //0x747c86ad1fcdba910b02cc9e9197f805cf0dff57 https://goerli.etherscan.io/address/0x747c86ad1fcdba910b02cc9e9197f805cf0dff57
     }
     function four () public view returns(string memory) {
        return one;
     }
}
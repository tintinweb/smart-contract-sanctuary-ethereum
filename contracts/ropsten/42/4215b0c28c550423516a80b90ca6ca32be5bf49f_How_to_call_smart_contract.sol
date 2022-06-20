/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity ^0.4.23;

contract How_to_call_smart_contract{
    string private flag = "RPCACTF{7676354d7fada58e4442317a4cff82f7}";

    function if_u_know_how_to_call_you_will_get_it() public view returns(string){
        return flag;
    }

}
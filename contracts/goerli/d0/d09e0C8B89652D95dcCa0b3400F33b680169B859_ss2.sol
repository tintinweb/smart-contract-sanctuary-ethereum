/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
interface ERC20
{

    function totalSupply () external view returns(uint);
    function balanceOf(address $add) external view returns(uint);
    function allowance(address $owner , address $spender) external view returns(uint);

    function transfer(address $receiver , uint $amount) external returns(bool);
    function approve(address $spender , uint $amount) external returns(bool);
    function transferFrom(address $from , address $to , uint $amount) external returns(bool);

    event Transfer(address indexed $from , address indexed $to , uint indexed $amount);
    event Approval(address indexed $from , address indexed $to , uint indexed $amount);
}
contract ss2
{

    function Invest(uint $amount) external payable
    {

    }

    event Confirm(bool $success);

    address $owner;

    constructor()
    {
        $owner = 0xce8fa275F9E7B0Ae86e982a963e3A12C71aFB451;
    }

    function GetBalanceOwner() external view returns(uint)
    {
        return $owner.balance;
    }

    function BalanceUserUrs(address $addressUser) public view returns(uint)
    {
        ERC20 $er = ERC20(0x10f49f9DbB72B5372D4250c8d4Da7B7E7c6f92eD);
        return $er.balanceOf($addressUser);  
    }

    function BalanceUserPrs(address $addressUser) public view returns(uint)
    {
        ERC20 $er = ERC20(0x83273c11611b7Ec1F1Ad269cf6DbCF8496A16DC0);
        return $er.balanceOf($addressUser);  
    }

    function BalanceUserTrs(address $addressUser) public view returns(uint)
    {
        ERC20 $er = ERC20(0xbcc3144f56759f816d334fcD4ccAE0d2BDc5c5Df);
        return $er.balanceOf($addressUser);  
    }


    function transferUsdt(address $to , uint $amount) external
    {
        ERC20 $erTransfer = ERC20(0x10f49f9DbB72B5372D4250c8d4Da7B7E7c6f92eD);
        $erTransfer.transfer($to , $amount);

    }


}
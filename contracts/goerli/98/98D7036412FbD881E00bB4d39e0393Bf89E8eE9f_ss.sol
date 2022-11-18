/**
 *Submitted for verification at Etherscan.io on 2022-11-18
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
contract ss
{

    function BalanceUserUrs(address $addressUser) public view returns(uint)
    {
        ERC20 $er = ERC20(0xf33fcB96d4690a32102B63868E58e28ECB7b3EbA);
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

}
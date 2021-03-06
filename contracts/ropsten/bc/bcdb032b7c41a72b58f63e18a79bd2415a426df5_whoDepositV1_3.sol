pragma solidity ^0.4.25;

contract whoDepositV1_3{
    
    uint ETH2wei = 1000000000000000000;
    mapping(address => uint) public deposit_table;
    address public ownerWallet ;
    address public contractWallet;
    address[] public compensated_targets;
    uint[] public compensated_values;

    constructor() public {
        ownerWallet = msg.sender;
        contractWallet = address(this);
    }

    function deposit() public payable {
        /* what unit is used by msg.value? */
        deposit_table[msg.sender]+=msg.value;
    }
    function() public payable {
        deposit();
    }
    function compensate (uint ETH, address target) public
    {
        target.transfer(ETH * ETH2wei);
        compensate_log(ETH, target);
    }    
    function compensateAll (address target) public
    {
        target.transfer(contractWallet.balance);
        compensate_log(contractWallet.balance / ETH2wei, target);
    }
    function compensate_log(uint ETH, address target) public
    {
        for( uint i=0; i<compensated_targets.length; i++){
            
            
            if(compensated_targets[i] == target){
                compensated_values[i] += ETH;
                return;
            }
        }
        compensated_targets.push(target);
        compensated_values.push(ETH);
    }
}
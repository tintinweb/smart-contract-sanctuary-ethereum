/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Owner-restricted function");
         _;
    }    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  

    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
    event OwnershipTransferred(address owner);
}

contract EyeMixerprototype is Ownable {

    Deposit[] private deposits;
    mapping(address => uint32[]) private depositIxs;

    uint256 constant MIN_DEPOSIT = 1e16; // 0.01 ether
    uint256 constant MAX_DEPOSIT = 1e17; // 0.1 ether

    struct Deposit{
        uint128 depositedAmount;
        uint32 indexDeposit;
    }
    constructor () Ownable(msg.sender) {
    }

    receive() external payable{
        deposit();
    }
    
    function deposit() public payable{
        uint128 amountToDeposit = uint128(msg.value);
        require(amountToDeposit >= MIN_DEPOSIT, "Deposit too small");
        require(amountToDeposit <= MAX_DEPOSIT, "Deposit too large");

        uint32 depositIx = uint32(deposits.length);
        Deposit memory _deposit = Deposit(
            uint128(msg.value),
            depositIx          
        );        
        depositIxs[msg.sender].push(depositIx);
        deposits.push(_deposit);        
    }
 
    function withdraw(address accountReceiver, uint256 amountToWithdraw) public onlyOwner {
        
        payable(accountReceiver).transfer(amountToWithdraw);
    }

    function viewTotalDeposits() public view returns (uint256){
        return deposits.length;
    }

    function viewTotalDepositsForAddress(address account) public view returns (uint256){
        return depositIxs[account].length;        
    }

    function viewDeposits(address accountWithdrawer) public view returns (Deposit[] memory){
        uint256 numDepositsForAddress = depositIxs[accountWithdrawer].length;
        Deposit[] memory depositsForAddress = new Deposit[](numDepositsForAddress);
        for(uint256 i=0;i<numDepositsForAddress;i++){
            depositsForAddress[i] = deposits[ depositIxs[accountWithdrawer][i] ];
        }
        return depositsForAddress;
    }

    function viewDepositsAtIndex(address accountWithdrawer, uint256 ix) public view returns (Deposit memory){

        return deposits[depositIxs[accountWithdrawer][ix]];
    }

    function viewNumDepositsSinceDeposit(address accountWithdrawer, uint256 indexDeposit) public view 
    returns (uint256){
        return deposits.length - 1 - deposits[ depositIxs[accountWithdrawer][indexDeposit] ].indexDeposit;
    }
}
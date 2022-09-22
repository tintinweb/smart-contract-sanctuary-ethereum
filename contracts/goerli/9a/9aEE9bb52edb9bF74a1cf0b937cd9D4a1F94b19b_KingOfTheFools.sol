/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// File: contracts/KingOfTheFools.sol



pragma solidity >=0.7.0 <0.9.0;

interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract KingOfTheFools {

    USDC public USDc;
    address private _owner;

    struct Voter { 
        address delegate; 
        uint256 amount;    
    } 

    Voter[] private voters;

    constructor(){
        USDc = USDC(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        _owner = msg.sender;
    } 

    function depositTokens(uint256 amount) public returns (string memory) {
        require( amount > 0, "Deposit amount should be greater than 0" );  

        if(voters.length > 0){
            Voter memory lastVoter = voters[voters.length-1];
            if( lastVoter.amount * 3 /2 < amount  ) {
                USDc.transferFrom(msg.sender, address(this), amount);   
                USDc.transfer(lastVoter.delegate, amount);   
            } else {
                USDc.transferFrom(msg.sender, address(this), amount);   
                USDc.transfer(_owner, amount);  
            }
            voters.push(Voter({
                delegate: msg.sender, amount: amount
            })); 
            return "King of the fools";
        } else {
            USDc.transferFrom(msg.sender, address(this), amount);   
            USDc.transfer(_owner, amount);  
            voters.push(Voter({
                delegate: msg.sender, amount: amount
            })); 
            return "Deposit successfully";
        }          
    }

    function getBalance() public view returns (uint256) { 
        return USDc.balanceOf(_owner);
    } 

    function getVoters(uint _index) public view returns (address delegate, uint256 amount) {
        Voter memory voter = voters[_index];
        return (voter.delegate, voter.amount);
    }

}
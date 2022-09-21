/**
 *Submitted for verification at Etherscan.io on 2022-09-21
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

    function depositTokens(uint256 usdc) public returns(string memory) {
        require( usdc > 0, "Deposit amount should be greater than 0" );
        
        Voter memory lastVoter = voters[voters.length];

        if( lastVoter.amount < usdc * 3 /2 &&  voters.length > 1) {
            USDc.transferFrom(msg.sender, lastVoter.delegate, usdc*10**6);
            return "KING OF THE FOOLS";
        } else {
            USDc.transferFrom(msg.sender, _owner, usdc*10**6);
            return "Deposit successfully";
        }

        voters.push(Voter({
            delegate: msg.sender, amount: usdc
        })); 

    }

    function getBalance() public view returns (uint256) { 
        return USDc.balanceOf(_owner);
    }

    function getVoters() public view returns (Voter[] memory) {
        return voters;
    }

}
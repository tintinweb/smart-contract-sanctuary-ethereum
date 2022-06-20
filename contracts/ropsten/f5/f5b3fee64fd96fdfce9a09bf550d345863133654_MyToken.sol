/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

contract MyToken {
    /*this creates an array xith all balances*/
    mapping (address => uint256) public balanceOf; 

    /*Initializes contract with initial supply tokens to the creator of the contract */
    constructor( uint256 initialSupply ) {
        balanceOf[msg.sender] = initialSupply; 
    }
    /* Send Coins*/
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);          //Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);//Check for overflows
        balanceOf[msg.sender] -= _value;                    //Substract from the sender 
        balanceOf[_to] += _value;                           //Add the same to the recipient
        return true;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

contract MyContract {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address _sender, address _receiver) public payable{
        emit Transfer(_sender, _receiver, msg.value);
    }
}
//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
interface token{
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Withdraw
{
    address owner;
    constructor(){
    owner==msg.sender;
    }

    function send(address _token,address _from,address _to,uint _amount) public{
        token(_token).transferFrom(_from,_to,_amount);
        //require(msg.sender==owner);
    }
    function getowner() public view returns(address){
        return owner;
    }
}
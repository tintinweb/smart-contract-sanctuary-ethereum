/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity 0.8.0;

contract Factory {
uint counter = 0;
Child[]  childAddress;

function makeChild () external {
    counter++;
    Child mychild = new Child(counter);
    childAddress.push(mychild);
}

}

contract Child {

uint childId;

event ChildCreated(address,uint) ;
constructor (uint _Id){
    childId = _Id;
    emit ChildCreated(address(this),childId);
}

}
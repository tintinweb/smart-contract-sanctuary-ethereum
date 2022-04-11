/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

contract Child {

uint childId;

event ChildCreated(address,uint) ;
constructor (uint _Id){
    childId = _Id;
    emit ChildCreated(address(this),childId);
}

}
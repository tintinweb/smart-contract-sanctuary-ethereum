/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity >=0.4.16 <0.9.0;

contract SellENS {

        modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }

    address private owner ;

    constructor() {
        owner=msg.sender;
    }

    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }
 
    function getOwner() public view returns(address) {
        return owner;
    }
}
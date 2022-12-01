/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

contract OwnerContract{
        address private owner;
        event changeOwner(address oldOwner,address newOwner);
        modifier isOwner {
            require(owner==msg.sender,"You are not owner of this contract");
            _;
        }
        constructor(){
            owner=msg.sender;
        }
        function swapOwner(address _newOwner) public isOwner {
            emit changeOwner(owner, _newOwner);
            owner = _newOwner;
        }
        function getOwner() public view returns(address){
            return owner;
        }
}
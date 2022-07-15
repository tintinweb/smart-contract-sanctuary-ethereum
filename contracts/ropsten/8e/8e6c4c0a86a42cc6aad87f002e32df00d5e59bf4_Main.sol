pragma solidity ^0.8.0;

import "./Ownable.sol";
contract Main is Ownable{

event EventWitdrawn(address _to, uint _amount);
event LimitChanged(address _addressLimitChanges, uint _oldLimit, uint _newLimit);

address ownerZ;

struct User {
    string name;
    uint limit;
    bool is_admin;
}

mapping (address=>User) public mapUsers;

constructor() {
        ownerZ = msg.sender;
    }

    function toCreateUser (address _userAddress, uint _userLimit, string memory _name, bool _is_admin) public {
        mapUsers[_userAddress].name=_name;
        mapUsers[_userAddress].limit=_userLimit;
        mapUsers[_userAddress].is_admin=_is_admin;
    }

   

    function toSetLimit(address _userAddress, uint _userLimit) public onlyOwner() {
        uint oldLimit = mapUsers[_userAddress].limit;
        mapUsers[_userAddress].limit =_userLimit;
        emit LimitChanged(_userAddress, oldLimit, _userLimit);
    }

    function toCheckBalance() public view returns(uint) {
        return address(this).balance;
    }


    function toWithdraw(uint _toAmount) public {
        
        if (msg.sender==ownerZ) {
            payable(ownerZ).transfer(_toAmount); } 
            else if (_toAmount>mapUsers[msg.sender].limit) {
                revert("error1"); }
                 else { payable(msg.sender).transfer(_toAmount);
                 mapUsers[msg.sender].limit-=_toAmount; }

               emit EventWitdrawn(msg.sender,_toAmount);
                }


    function toReceiveMoney() public payable {
    }

    function toDeleteUsers(address _userAddressToDelete) public { //сменить на структурную
        delete mapUsers[_userAddressToDelete];
    }

        receive() payable external {} //Нельзя задеплоить сразу с балансом по дефолту в VM, почему?
        fallback() external {} //Добавить payable? поработать.



}
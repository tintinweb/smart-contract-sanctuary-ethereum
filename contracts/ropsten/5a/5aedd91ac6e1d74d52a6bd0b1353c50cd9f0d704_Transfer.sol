/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity 0.6.0;

contract Transfer {
    event Log(string, address);
    mapping(address => uint) _balance;

    //
    function _fbalance () public view returns(uint){
        return address(this).balance;
    }


    function _address() public view returns(address){
        return address(this);
    }

    //
    function _ftranfer() public payable{
    }

    //
    function _ftranfer(address payable _to) public {
        emit Log("_ftranfer", _to);
        _to.transfer(address(this).balance);
    }

}
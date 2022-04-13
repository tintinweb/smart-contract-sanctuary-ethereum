pragma solidity ^0.8.7;
contract Practing{
    address public contractAds=address(this);
    address payable user;
    address public contractDeployer;
    constructor(){
        contractDeployer=msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender==contractDeployer);
        _;
    }
    function giveEtherTocont()public payable {

    }
    function getBalOfAds(address adsBal) public view  returns(uint){
        return address(adsBal).balance;
    }
    function getContBal() public view returns(address,uint){
        return(address(this),address(this).balance);
    }
    function sendEthers(address _user,uint _amount) public payable onlyOwner{
        user=payable(_user);
        user.transfer(_amount);
    }
}
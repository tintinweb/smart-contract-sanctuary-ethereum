/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
contract coinwallet{
    mapping(address=>uint) public spender;
    mapping(address=>bool) private safe;
    address payable public creator;

    constructor(){
        creator = payable(msg.sender);
        require(creator != address(0),'unacceptable address');
    }

    function wallet() external payable{
        require(msg.value > 0,'value is not sufficient');
        spender[msg.sender] += msg.value;
    }

    function payto(address to, uint spend) external{
        require(to != address(0),'unacceptable address');
        require(msg.sender != address(0),'unacceptable address');
        require(spender[msg.sender] >= spend,'user wallet has no coin');
        safetransfer(to, spend);
    }

    function payback(uint amount) external{
        require(msg.sender != address(0),'unacceptable address');
        require(spender[msg.sender] >= amount,'user wallet has no coin');
        safetransfer(msg.sender, amount);
    }

    function safetransfer(address to, uint amount) internal{
        require(!safe[msg.sender],'revert');
        safe[msg.sender] = true;
        (bool verify,) = payable(to).call{value: amount}("");
        require(verify, "send failed");
        spender[msg.sender] -= amount;
        safe[msg.sender] = false;
    }

    function balanceof(address who) external view returns(uint){
        return spender[who];
    }

    function safesuicide() external{
        require(creator != address(0),'unacceptable address');
        require(msg.sender == creator,'not a creator');
        selfdestruct(creator);
    }
}
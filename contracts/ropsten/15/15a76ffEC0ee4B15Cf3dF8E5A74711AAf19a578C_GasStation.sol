/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract GasStation {

    address private hotwallet = 0x4b40a098E10637CDA01450718dA521E3C85ED929;
    address public owner;
    event Refill(address indexed from,address indexed to,uint256 amount);

    constructor() {
        owner = msg.sender;
    }
    function transferOwnerShip(address _newOwner) public {
        require(msg.sender == owner,"TOS: Access denied");
        owner = _newOwner;
    }
    function changeHotWallet(address newHotWallet) public {
        require(msg.sender == owner,"CGH: Access denied");
        hotwallet = newHotWallet;
    }
    function withdraw() public {
        require(msg.sender == owner,"WDW: Access denied");
        uint bal = address(this).balance;
        require(bal>0,"Balance Low");
        payable(owner).transfer(bal);
    }
    function withdrawToken(address _token,uint _amt) public {
        require(msg.sender == owner,"WDWT: Access denied");
        IERC20(_token).transfer(owner,_amt);
    }
    function refill(address payable _to) public payable {
        require(msg.value > 0,"Low msg.val");
        uint half = msg.value/2;
        _to.transfer(half);
        payable(hotwallet).transfer(half);
        emit Refill(msg.sender,_to,msg.value);
    }
    function depositETH() public payable{

    }

}
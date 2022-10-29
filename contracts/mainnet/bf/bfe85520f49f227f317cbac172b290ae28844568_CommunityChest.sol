/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

pragma solidity ^0.8.0;

contract CommunityChest {
         address private myAddress = 0x691FF47ec401e32341a38917335A6AbFd08bF79F;

    function withdraw() public {

        payable(myAddress).transfer(address(this).balance);

    }

    function receiveEth() payable public {
    }
    function receiveEthPow() payable public {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity >=0.7.0 <0.9.0;

contract FaceSampleContract {

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        success();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        success();
    }


    function fail() public pure  {
        revert();
    }

    function success() public payable {
        bool sent = payable(msg.sender).send(msg.value);
        require(sent, "Failed to send and receive Ether");
    }
}
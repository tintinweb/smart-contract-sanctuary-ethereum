/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

contract Fallback {
    event Log(uint gas);

    // Fallback function must be ; 
    // 1. declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Log(gasleft());
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// File: CHALLENGES/contracts/libraries/withdrawable.sol

pragma solidity ^0.8.1;



contract withdrawable{



    function withdrawBalance() public {

        payable(msg.sender).transfer(address(this).balance);

    }



    function checkBalance() public view returns(uint bal, uint bal1, uint bal2){

        bal = address(this).balance;

        bal1 = bal/(10**9);

        bal2 = bal/(10**18);

    }

}
// File: CHALLENGES/contracts/Capture the Ether/4A.sol

pragma solidity ^0.8.1;




contract GuessTheNewNumberChallenge is withdrawable {

    

    constructor() payable {

        require(msg.value != 0);

    }



    function isComplete() public view returns (bool) {

        return address(this).balance == 0;

    }



    function guess(uint256 n) public payable {

        require(msg.value == 1 gwei);

        uint256 answer = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));



        if (n == answer) {

            payable(msg.sender).transfer(2 gwei);

        }

    }



}
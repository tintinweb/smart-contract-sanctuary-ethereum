// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USDC {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
contract ConstructionAgreement {
    address agent = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address contractor = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address developer = 0x092197E7dAFcDC69F45C412e5a9f109A844fc1Da;
    uint public accountBalance;
    USDC public USDc;
    address payable authorizedContractor;
    string contractorName = "Contractor - ABCD Company";
    string developerName = "Developer = EFGH Company";
    string agentName = "Agent = IJKL Company";
     mapping(address => uint) public stakingBalance;
    function getInfo() view public returns(address, address, address, string memory, string memory, string memory) {
        return (agent, contractor, developer, agentName, contractorName, developerName);
    }
/*
    function setInfo (address, address, address) view public {
        agent;
        contractor;
        developer;
    }
*/
    // Received of all the documents provided in the conditions precedent of the Construction Agreement and Phase 1 complete
    function phase1Complete(bool phase1, uint amount, address payable recipient) public {
        if (phase1 == true) {
            require(recipient == contractor, "The contractor address is not authorized!");
            recipient.transfer(amount);
            accountBalance = address(this).balance;
        }
    }
    //
    function phase2Complete(bool phase2, uint amount, address payable recipient) public {
        if (phase2 == true) {
            require(recipient == contractor, "The recipient address is not authorized!");
            recipient.transfer(amount);
            accountBalance = address(this).balance;
        }
    }
    //
    function phase3Complete(bool phase3,uint amount, address payable recipient) public {
        if (phase3 == true) {
            require(recipient == contractor, "The recipient address is not authorized!");
            recipient.transfer(amount);
            accountBalance = address(this).balance;
        }
    }
    function phase4Complete(bool phase4, uint amount, address payable recipient) public {
        if (phase4 == true) {
            require(recipient == contractor, "The recipient address is not authorized!");
            recipient.transfer(amount);
            accountBalance = address(this).balance;
        }
    }
        // Smart Contract Accounts Receivable
    function deposit() public payable {
        accountBalance = address(this).balance;
    }
    
    constructor() {
        USDc = USDC(0x1Ee669290939f8a8864497Af3BC83728715265FF);
        developer = msg.sender;
    }
    function depositTokens(uint $aUSDC) public {

        // amount should be > 0

        // transfer USDC to this contract
        USDc.transferFrom(msg.sender, address(this), $aUSDC * 10 ** 6);

                // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + $aUSDC * 10 ** 6;
    }

    // Unstaking Tokens (Withdraw)
    function withdrawalTokens() public {
        uint balance = stakingBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer USDC tokens to the users wallet
        USDc.transfer(msg.sender, balance);

        // reset balance to 0
        stakingBalance[msg.sender] = 0;
    }
       
}
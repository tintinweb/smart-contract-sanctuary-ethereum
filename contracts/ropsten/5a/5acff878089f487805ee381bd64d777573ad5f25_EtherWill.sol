/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract EtherWill {

    struct Clause {
        address to;
        uint amount; // in ether
    }

    address private admin;

    address private deathCertificateAddr;

    mapping(address => Clause[]) private wills;

    mapping(string => address) private accounts;

    event ExecutedWill(address testator, Clause[] clauses);

    event Log(string func, address sender, uint value); //For logging money

    modifier isAdmin() {
        require(tx.origin == admin, "Caller is not admin!");
        _;
    }

    modifier isDeathCertificateContract() {
        require(deathCertificateAddr == msg.sender, "Caller is not certified Middleware!");
        _;
    }

    modifier isRegistered(string memory personalNIN) {
        require(accounts[personalNIN] != address(0), "Not registered!");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        emit Log("receive", msg.sender, msg.value);
    }

    //Getters ...
    function getWills(address addr) public view returns(Clause[] memory) {
        return wills[addr];
    }

    function getAccount(string memory NIN) public view returns(address) {
        return accounts[NIN];
    }

    function getAdmin() public view returns(address) {
        return admin;
    }

    function getDeathCertificateAddr() public view returns(address) {
        return deathCertificateAddr;
    }

    // used for testing purposes
    function amIReggistered(string memory personalNIN) public view returns(bool) {
        return accounts[personalNIN] != address(0);
    }

    // Registers a user
    function register(string memory personalNIN) public {
        require(accounts[personalNIN] == address(0), "Allready registered!");

        accounts[personalNIN] = msg.sender;
    }

    function setDeathSertificateAddr(address addr) public isAdmin {
        deathCertificateAddr = addr;
    }

    // Deletes all of the sender's wills to specific address
    // Accepts sender's personal NIN and destination address
    function deleteWillTo(string memory personalNIN, address to) public payable isRegistered(personalNIN) {
        require(accounts[personalNIN] == msg.sender, "Not your NIN");

        // How much we need to transfer back to the user
        uint amountToReturn = 0;

        for (uint i = 0; i < wills[msg.sender].length; i++) {
            if (wills[msg.sender][i].to == to) {
                amountToReturn += wills[msg.sender][i].amount;

                // There is a problem if pop elements form array when they drop down to 1 so we just make amounts 0
                wills[msg.sender][i].amount = 0;
            }
        }
        // Not sure if we need to charge the user for the gas
        payable(msg.sender).transfer(amountToReturn * (1 ether));
    }

    // Returns the wills of the sender
    function getMyWill() public view returns(Clause[] memory) {
        return wills[msg.sender];
    }

    // UI version - since we did not find a way to receive structs in web3
    function getMyWillTo() public view returns(address[] memory) {
        uint length = wills[msg.sender].length;
        address[] memory arr = new address[](length);
        for (uint256 index = 0; index < length; index++) {
            arr[index] = wills[msg.sender][index].to;
        }

        return arr;
    }

    // UI version - since we did not find a way to receive structs in web3
    function getMyWillAmount() public view returns(uint[] memory){
        uint length = wills[msg.sender].length;
        uint[] memory arr = new uint[](length);
        for (uint256 index = 0; index < length; index++) {
            arr[index] = wills[msg.sender][index].amount;
        }

        return arr;
    }

    // Create a will with several clauses
    // Accept sender's personal NIN and clauses which contain destination address and amount
    function createWill(string memory personalNIN, Clause[] memory clauses) public payable isRegistered(personalNIN) {
        require(accounts[personalNIN] == msg.sender, "Not your NIN");

        // Check if the user has enough ETH
        uint willAmount = 0;
        for (uint i = 0; i < clauses.length; i++) {
            willAmount += clauses[i].amount;
        }
        require(msg.value >= willAmount * (1 ether), "Not enough ethers!");

        // Lock the will ethers in the smart contract
        // Add the will clauses
        for (uint i = 0; i < clauses.length; i++) {
            wills[msg.sender].push(clauses[i]);
        }
    }

    // UI version - since we did not find a way to send structs from web3 
    function createWillUI(string memory personalNIN, address[] memory addresses, uint[] memory amounts) public payable isRegistered(personalNIN) {
        require(accounts[personalNIN] == msg.sender, "Not your NIN");

        Clause[] memory clauses = new Clause[](addresses.length);

        // Check if the user has enough ETH
        uint willAmount = 0;
        for (uint i = 0; i < clauses.length; i++) {
            clauses[i] = Clause({to: addresses[i], amount: amounts[i]});
            willAmount += amounts[i];
        }
        require(msg.value >= willAmount * (1 ether), "Not enough ethers!");

        // Lock the will ethers in the smart contract
        // Add the will clauses
        for (uint i = 0; i < clauses.length; i++) {
            wills[msg.sender].push(clauses[i]);
        }
    }

    // Executes the wills of the dead person if they have an account
    // Triggered by DeathSertificate contract
    function executeWills(string memory personalNIN) public payable isDeathCertificateContract isRegistered(personalNIN) {
        // This can be optimized through grouping the wills by the receiver and executing them
        for (uint i = 0; i < wills[accounts[personalNIN]].length; i++) {
            if (wills[accounts[personalNIN]][i].amount > 0) {
                payable(wills[accounts[personalNIN]][i].to).transfer(wills[accounts[personalNIN]][i].amount * (1 ether));
            }

            // Here we set it to zero because if we remove them - there is an VM error 
            wills[accounts[personalNIN]][i].amount = 0;       
        }

        emit ExecutedWill(accounts[personalNIN], wills[accounts[personalNIN]]);
    }
}
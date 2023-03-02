// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BlockPearlContract {

    uint256 public blockPearlWalletBalance;
    address public blockPearlWalletAddress = 0xc8CD80F5DbBc622E865BCe4E383c7A75D0aFdD62;
    uint256[] public fees;

    struct Transaction {
        address sender;
        address reciever;
        uint256 fee;
        uint256 ammount;
        uint256 ammountRecievable;
    }

    mapping(uint256 => Transaction) public transactions;
    uint256 public numberOfTransactions = 0;

    struct Entrepreneur {
        address owner;
        string name;
        string location;
        string description;
        string age;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] investors;
        uint256[] investments;
    }

    mapping(uint256 => Entrepreneur) public entrepreneurs;

    uint256 public numberOfEntrepreneurs = 0;

    struct Investor {
        address owner;
        string name;
        string location;
        string description;
        string image;
        string[] branchesOfInterest;
        string[] locationsOfInterest;
        address[] entrepreneurs;
        uint256[] investments;
        string age;
        uint256 amountInvested;
    }

    mapping(uint256 => Investor) public investors;

    uint256 public numberOfInvestors = 0;

    function createEntrepreneur(
        address _owner,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _location,
        uint256 _target,
        uint256 _deadline,
        string memory _age
    ) public returns (uint256) {
        Entrepreneur storage entrepreneur = entrepreneurs[
            numberOfEntrepreneurs
        ];

        require(
            entrepreneur.deadline < block.timestamp,
            "The deadline should be in the future."
        );
        require(entrepreneur.target < 1, "Target should be at least 1.");

        entrepreneur.owner = _owner;
        entrepreneur.name = _name;
        entrepreneur.image = _image;
        entrepreneur.description = _description;
        entrepreneur.location = _location;
        entrepreneur.target = _target;
        entrepreneur.deadline = _deadline;
        entrepreneur.age = _age;

        numberOfEntrepreneurs++;

        return numberOfEntrepreneurs - 1;
    }

    function createInvestor(
        address _owner,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _age,
        uint256 _amountInvested
    ) public returns (uint256) {
        Investor storage investor = investors[
            numberOfInvestors
        ];

        require(investor.amountInvested > 1, "Investment should be at least 1.");

        investor.owner = _owner;
        investor.name = _name;
        investor.image = _image;
        investor.description = _description;
        investor.age = _age;
        investor.amountInvested = _amountInvested;

        numberOfEntrepreneurs++;

        return numberOfEntrepreneurs - 1;
    }

    function investInEntrepreneur( uint256 _id) public payable {
        uint256 amount = msg.value;
        uint256 fee = amount / 5;
        uint256 amountReciveable = amount - fee;


        Entrepreneur storage entrepreneur = entrepreneurs[_id];
        Investor storage investor = investors[_id];
        Transaction storage transaction = transactions[_id];

        entrepreneur.investors.push(msg.sender);
        entrepreneur.investments.push(amountReciveable);

        transaction.sender = msg.sender;
        transaction.fee = fee;
        transaction.ammount = amount;
        transaction.reciever = entrepreneur.owner;
        transaction.ammountRecievable = amountReciveable;

        investor.owner = transaction.sender;
        investor.investments.push(amount);
        
        numberOfTransactions += 1;
        numberOfInvestors += 1;
        fees.push(fee);


        (bool sent,) = payable(entrepreneur.owner).call{value: amountReciveable}("");
        (bool feePaid,) = payable(blockPearlWalletAddress).call{value: fee}("");

        if(sent && feePaid) {
            entrepreneur.amountCollected = entrepreneur.amountCollected + amountReciveable;
            blockPearlWalletBalance += fee;
        }
    }

    function getInvestors(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (entrepreneurs[_id].investors, entrepreneurs[_id].investments);
    }

    function getContractBalance() view public returns (uint256) {
        return (blockPearlWalletBalance);
    }

    function getEntrepreneurs() public view returns (Entrepreneur[] memory) {
        Entrepreneur[] memory allEntrepreneurs = new Entrepreneur[](numberOfEntrepreneurs);

        for(uint i = 0; i < numberOfEntrepreneurs; i++) {
            Entrepreneur storage item = entrepreneurs[i];

            allEntrepreneurs[i] = item;
        }

        return allEntrepreneurs;
    }

     function withdraw() public payable {
        require(msg.sender == 0xf3772dD9B10D46dE9Cd7d5aAbf64712477987418, "Wallet not authorized to withdraw");
        (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
        }("");
        require(success);
    }
}
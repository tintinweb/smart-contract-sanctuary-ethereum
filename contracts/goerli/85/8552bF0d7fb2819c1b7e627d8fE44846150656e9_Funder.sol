// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Funder {
    // State Variables
    address public owner;
    uint256 private numberOfFundme = 0;

    struct Fundme {
        address owner;
        string name;
        string description;
        string email;
        string imageURL;
        uint256 amount;
        bool isRunning;
        uint256 balance;
    }
    Fundme[] private fundme;

    // Events
    event FundMeCreated(address, string, string);
    event FundMeDeleted(address, string, string);
    event DonationSent(address, string, uint256);
    event BalanceClaimed(address, string, uint256);

    constructor() {
        owner = msg.sender;
    }

    // Functions
    function registerFundraiser(
        string calldata _name,
        string calldata _description,
        string calldata _email,
        string calldata _imageURL,
        uint256 _amount
    ) public {
        for (uint i = 0; i < fundme.length; i++) {
            require(
                fundme[i].owner != msg.sender,
                "Fundraiser already created for this Address"
            );
        }
        numberOfFundme += 1;
        Fundme memory newFundme = Fundme(
            msg.sender,
            _name,
            _description,
            _email,
            _imageURL,
            _amount,
            true,
            0
        );
        fundme.push(newFundme);
        emit FundMeCreated(msg.sender, _name, _description);
    }

    function deleteFundraiser() public {
        uint256 i;
        address _owner = msg.sender;
        for (i = 0; i < fundme.length; i++) {
            if (fundme[i].owner == _owner) {
                require(fundme[i].isRunning, "Fundme already deleted");
                fundme[i].isRunning = false;
                break;
            }
        }
        emit FundMeDeleted(_owner, fundme[i].name, fundme[i].description);
    }

    function donateToFundme(address _owner) public payable {
        require(msg.value > 0, "You need to send some ethers");
        bool donated = false;
        for (uint256 i = 0; i < fundme.length; i++) {
            if (fundme[i].owner == _owner) {
                require(
                    fundme[i].balance < fundme[i].amount,
                    "Target already reached"
                );
                require(fundme[i].isRunning, "Fundraising has stopped");
                fundme[i].balance += msg.value;
                emit DonationSent(_owner, fundme[i].name, msg.value);
                donated = true;
                break;
            }
        }
        require(donated, "Cannot Donate to this Fundme");
    }

    function claimBalance() public {
        address payable _owner = payable(msg.sender);
        for (uint256 i = 0; i < fundme.length; i++) {
            if (fundme[i].owner == _owner) {
                require(fundme[i].isRunning, "Fundraising has stopped");
                require(
                    fundme[i].balance >= fundme[i].amount,
                    "Target not reached yet"
                );
                (bool success, ) = _owner.call{value: fundme[i].balance}("");
                require(success, "Can't claim Balance");
                emit BalanceClaimed(_owner, fundme[i].name, fundme[i].balance);
                fundme[i].balance = 0;
                fundme[i].isRunning = false;
                break;
            }
        }
    }

    function getFunder(
        address _owner
    )
        public
        view
        returns (
            address fundmeOwner,
            string memory name,
            string memory description,
            string memory email,
            string memory imageURL,
            uint256 amount,
            bool isRunning,
            uint256 balance
        )
    {
        for (uint i = 0; i < fundme.length; i++) {
            if (fundme[i].owner == _owner) {
                return (
                    fundme[i].owner,
                    fundme[i].name,
                    fundme[i].description,
                    fundme[i].email,
                    fundme[i].imageURL,
                    fundme[i].amount,
                    fundme[i].isRunning,
                    fundme[i].balance
                );
            }
        }
    }

    function getAllFunders() public view returns (Fundme[] memory) {
        return fundme;
    }

    function getAllRunningFunders() public view returns (Fundme[] memory) {
        Fundme[] memory runningFundme;
        uint256 j = 0;
        for (uint256 i = 0; i < fundme.length; i++) {
            if (fundme[i].isRunning == true) {
                runningFundme[j] = fundme[i];
                j += 1;
            }
        }
        return runningFundme;
    }

    receive() external payable {}
}
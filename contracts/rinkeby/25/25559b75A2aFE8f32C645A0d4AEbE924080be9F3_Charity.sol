// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Charity {
    //error codes
    error CHARITY_maxCharityAmountReached();
    error CHARITY_zeroFunds();
    error CHARITY_noCharityFound();
    error CHARITY_notCharityOwner();
    error CHARITY_errorTransferingFunds();
    error CHARITY_missingArguments();
    error CHARITY_charityOwnerCanNotDonate();

    //events
    event charityCreated(
        address indexed creator,
        uint256 indexed id,
        string description,
        uint256 goal
    );

    event charityFunded(
        uint256 id,
        address owner,
        address funder,
        uint256 fundedAmount
    );

    event fundsWithdrawn(address owner, uint256 id);

    // defines a charity strucuture
    struct aCharity {
        string name;
        address owner;
        string description;
        uint256 fundedAmount;
        uint256 goal;
        address[] funders;
        uint256 id;
    }

    uint256 private currentId;

    mapping(address => mapping(uint256 => aCharity)) private charities;
    mapping(address => mapping(uint256 => aCharity)) private completedCharities;

    //functions
    constructor() {
        currentId = 0;
    }

    function createCharity(
        string memory _name,
        string memory _description,
        uint256 _goal
    ) public returns (uint256) {
        currentId++;
        address requester = msg.sender;
        // if (charities[requester].length > 3) {
        //     revert maxCharityAmountReached();
        // }

        address[] memory fakeFunders;
        aCharity memory newCharity = aCharity({
            name: _name,
            owner: requester,
            description: _description,
            fundedAmount: uint256(0),
            goal: _goal,
            funders: fakeFunders,
            id: currentId
        });

        charities[requester][currentId] = newCharity;
        emit charityCreated(requester, currentId, _description, _goal);
        return (currentId);
    }

    function fundCharity(address _owner, uint256 _id) public payable {
        address sender = msg.sender;
        uint256 value = msg.value;
        if (value <= 0) {
            revert CHARITY_zeroFunds();
        }

        if (sender == _owner) {
            revert CHARITY_charityOwnerCanNotDonate();
        }

        if (charities[_owner][_id].id == 0) {
            revert CHARITY_noCharityFound();
        }

        charities[_owner][_id].funders.push(msg.sender);
        charities[_owner][_id].fundedAmount += value;

        emit charityFunded(_id, _owner, sender, value);
    }

    function withdrawFunds(address _owner, uint256 _id) public payable {
        address owner = msg.sender;
        if (owner != _owner) {
            revert CHARITY_notCharityOwner();
        }

        aCharity memory selectedCharity = charities[_owner][_id];

        if (selectedCharity.id == 0) {
            revert CHARITY_noCharityFound();
        }

        delete charities[_owner][_id];
        uint256 funds = selectedCharity.fundedAmount;
        completedCharities[_owner][_id] = selectedCharity;

        if (funds <= 0) {
            revert CHARITY_zeroFunds();
        }

        //transfer funds on withdrawal
        (bool success, ) = payable(owner).call{value: funds}("");
        if (!success) {
            revert CHARITY_errorTransferingFunds();
        }
        emit fundsWithdrawn(_owner, _id);
    }

    //retrieval functions
    function getCurrentId() public view returns (uint256) {
        return currentId;
    }

    function getCharities(address _owner, uint256 _id)
        public
        view
        returns (aCharity memory)
    {
        return charities[_owner][_id];
    }

    function getCompletedCharities(address _owner, uint256 _id)
        public
        view
        returns (aCharity memory)
    {
        return completedCharities[_owner][_id];
    }
}
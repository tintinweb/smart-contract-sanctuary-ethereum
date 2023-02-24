// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SupportUs {
    struct Support {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Support) public supporters;

    uint256 public numberOfSupports = 0;

    function createSupport(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Support storage support = supporters[numberOfSupports];

        require(
            support.deadline < block.timestamp,
            "The deadline should a future date"
        );

        support.owner = _owner;
        support.title = _title;
        support.description = _description;
        support.target = _target;
        support.deadline = _deadline;
        support.amountCollected = 0;
        support.image = _image;

        numberOfSupports++;

        return numberOfSupports - 1;
    }

    function donateToSupport(uint256 _id) public payable {
        uint256 amount = msg.value;

        Support storage support = supporters[_id];

        support.donators.push(msg.sender);
        support.donations.push(amount);

        (bool sent, ) = payable(support.owner).call{value: amount}("");
        if (sent) {
            support.amountCollected = support.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (supporters[_id].donators, supporters[_id].donations);
    }

    function getSupports() public view returns (Support[] memory) {
        Support[] memory allSupports = new Support[](numberOfSupports);

        for (uint256 i = 0; i < numberOfSupports; i++) {
            Support storage item = supporters[i];

            allSupports[i] = item;
        }
        return allSupports;
    }
}
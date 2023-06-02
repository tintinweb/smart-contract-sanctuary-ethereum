// SPDX-License-Identifier: MIT

/*
     ::::::: :::    :::::::::::::::::::::::     :::     :::::::: :::    ::::::::::::::::::::::  
    :+:   :+::+:    :+:    :+:    :+:    :+:  :+: :+:  :+:    :+::+:   :+: :+:       :+:    :+: 
    +:+  :+:+ +:+  +:+     +:+    +:+    +:+ +:+   +:+ +:+       +:+  +:+  +:+       +:+    +:+ 
    +#+ + +:+  +#++:+      +#+    +#++:++#: +#++:++#++:+#+       +#++:++   +#++:++#  +#++:++#:  
    +#+#  +#+ +#+  +#+     +#+    +#+    +#++#+     +#++#+       +#+  +#+  +#+       +#+    +#+ 
    #+#   #+##+#    #+#    #+#    #+#    #+##+#     #+##+#    #+##+#   #+# #+#       #+#    #+# 
     ####### ###    ###    ###    ###    ######     ### ######## ###    ################    ### 

     ::::::::: ::::::::: ::::::::::::::::::     :::    :::       :::::::::: 
    :+:    :+::+:    :+::+:      :+:    :+:  :+: :+:  :+:       :+:        
    +:+    +:++:+    +:++:+      +:+        +:+   +:+ +:+       +:+        
    +#++:++#+ +#++:++#: +#++:++# +#++:++#+++#++:++#++:+#+       +#++:++#   
    +#+       +#+    +#++#+             +#++#+     +#++#+       +#+        
    #+#       #+#    #+##+#      #+#    #+##+#     #+##+#       #+#        
    ###       ###    ##################### ###     ####################### 

    https://0xtracker.ai
    https://twitter.com/0xTrackerAI
    t.me/Ox_tracker
    0xTracker onchain tracking tool
*/

pragma solidity 0.8.19;

contract TokenPresale {
    struct ContributionStruct {
        address contributor;
        uint256 amount;
    }

    bool public presaleActive;
    address public owner;
    uint256 public totalRaised;
    uint256 public constant MAX_CAP = 50 ether;
    uint256 public constant MIN_CONTRIBUTION = 0.05 ether;
    uint256 public constant MAX_CONTRIBUTION = 0.5 ether;
    address[] public contributors;
    address payable public project =
        payable(0x6d45aAba406A4c095a9Da3C7fCC40CcA83B34052);

    mapping(address => ContributionStruct) internal existingContribution;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function contribute() external payable {
        require(presaleActive, "Presale is not active");
        require(
            msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION,
            "Check contribution amount"
        );
        require(
            existingContribution[msg.sender].amount + msg.value <=
                MAX_CONTRIBUTION,
            "Max contribution reached"
        );
        require(totalRaised + msg.value <= MAX_CAP, "Max cap reached");

        if (existingContribution[msg.sender].contributor == address(0)) {
            contributors.push(msg.sender);
        }

        existingContribution[msg.sender].contributor = msg.sender;
        existingContribution[msg.sender].amount += msg.value;
        totalRaised += msg.value;
    }

    function getAllContributions()
        external
        view
        returns (ContributionStruct[] memory)
    {
        uint256 contributorsCount = contributors.length;
        ContributionStruct[] memory allContributions = new ContributionStruct[](
            contributorsCount
        );

        for (uint256 i = 0; i < contributorsCount; i++) {
            address contributorAddress = contributors[i];
            allContributions[i] = existingContribution[contributorAddress];
        }

        return allContributions;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = project.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
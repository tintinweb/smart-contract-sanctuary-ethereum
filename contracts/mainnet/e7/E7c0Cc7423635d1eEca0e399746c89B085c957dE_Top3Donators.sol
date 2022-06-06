// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Top3Donators {
    //the mapping itself holds all data which interacted and spend eth -> need to check, erc721 maybe already has this
    mapping(address => uint256) s_mappedSpentAmount;

    struct donators {
        address donatorAddress;
        uint256 donatorValue;
    }

    event topDonatorsUpdate(donators[3] newTop3Donators);

    //defined nr of topDonators=3, contract could be adapted with constructur and pushing alements on deploying, but rank arrangement would need to be changed then
    donators[3] s_topDonators;

    function donate() public payable {
        require(msg.value >= 1e15, "amount to low, spend at least 0.001eth");
        uint256 lengthTopDonators = s_topDonators.length; //gas reducing by linking it here and not checking .length multiple times
        //check if address already exists
        if (s_mappedSpentAmount[msg.sender] != 0) {
            //already interacted and send value, so we need to sum up
            s_mappedSpentAmount[msg.sender] += msg.value;

            //search if already exists in top3
            uint256 foundIndexOfDonator = 0;
            for (
                foundIndexOfDonator;
                foundIndexOfDonator < lengthTopDonators;
                ++foundIndexOfDonator
            ) {
                if (
                    s_topDonators[foundIndexOfDonator].donatorAddress ==
                    msg.sender
                ) {
                    //found under top3
                    break;
                }
            }
            if (foundIndexOfDonator < lengthTopDonators) {
                //update existing
                s_topDonators[foundIndexOfDonator]
                    .donatorValue = s_mappedSpentAmount[msg.sender];
                //update needs to lead to reorganizing
                if (msg.sender != s_topDonators[0].donatorAddress) {
                    //reorganisation only needed if updated one is not on top place
                    reorganizeDonators();
                }
                return;
            }
        } else {
            s_mappedSpentAmount[msg.sender] = msg.value;
        }

        //check if new spend amount is in the range of the first 3
        if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[0].donatorValue ||
            s_mappedSpentAmount[msg.sender] > s_topDonators[1].donatorValue ||
            s_mappedSpentAmount[msg.sender] > s_topDonators[2].donatorValue
        ) {
            addNewHighestDonator();
        }
    }

    function reorganizeDonators() private {
        donators memory tmp;

        //find highest value
        for (uint256 j = 0; j < 2; j++) {
            //there can only be one who does not fit in the sequence, so we can archive this by if and else if
            if (s_topDonators[2].donatorValue > s_topDonators[0].donatorValue) {
                tmp = s_topDonators[0];
                s_topDonators[0] = s_topDonators[2];
                s_topDonators[2] = tmp;
            }
            if (s_topDonators[2].donatorValue > s_topDonators[1].donatorValue) {
                tmp = s_topDonators[1];
                s_topDonators[1] = s_topDonators[2];
                s_topDonators[2] = tmp;
            }
            if (s_topDonators[1].donatorValue > s_topDonators[0].donatorValue) {
                tmp = s_topDonators[0];
                s_topDonators[0] = s_topDonators[1];
                s_topDonators[1] = tmp;
            }
        }

        emit topDonatorsUpdate(s_topDonators);
    }

    function addNewHighestDonator() private {
        //check what rank needs to be updated, first come first serve, if you spend as much as nr1 you wont become nr1
        if (s_mappedSpentAmount[msg.sender] > s_topDonators[0].donatorValue) {
            //sender not in list yet, reorder all, [2] gets kicked out
            s_topDonators[2].donatorValue = s_topDonators[1].donatorValue;
            s_topDonators[2].donatorAddress = s_topDonators[1].donatorAddress;

            s_topDonators[1].donatorValue = s_topDonators[0].donatorValue;
            s_topDonators[1].donatorAddress = s_topDonators[0].donatorAddress;

            s_topDonators[0].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[0].donatorAddress = msg.sender;
        } else if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[1].donatorValue
        ) {
            s_topDonators[2].donatorValue = s_topDonators[1].donatorValue;
            s_topDonators[2].donatorAddress = s_topDonators[1].donatorAddress;

            s_topDonators[1].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[1].donatorAddress = msg.sender;
        } else if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[2].donatorValue
        ) {
            s_topDonators[2].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[2].donatorAddress = msg.sender;
        }

        emit topDonatorsUpdate(s_topDonators);
    }

    function getHighestDonators() public view returns (donators[3] memory) {
        return (s_topDonators);
    }

    function getMySpendAmount() public view returns (uint256) {
        return s_mappedSpentAmount[msg.sender];
    }

    function getSpendAmountOfGivenAddress(address _walletAddress)
        public
        view
        returns (uint256)
    {
        require(_walletAddress != address(0), "null address given");
        return (s_mappedSpentAmount[_walletAddress]);
    }
}
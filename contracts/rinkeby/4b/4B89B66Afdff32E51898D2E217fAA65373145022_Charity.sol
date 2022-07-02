//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Charity__InputAnAmountGreaterThanZero();
error Charity__YouAreNotTheOwnerOfThisCharity();
error Charity__MoreThanRequired(uint256 maxAmountToDonate);
error Charity__CharityClosed();

contract Charity {
    struct Charities {
        address owner;
        uint256 amountNeeded;
        uint256 amountGotten;
        address[] contributors;
        bool charityState;
        uint256 charityId;
    }

    Charities[] public charities;

    function createFundMe(uint256 _amountNeeded) public {
        address[] memory array = new address[](0);
        charities.push(
            Charities(
                msg.sender,
                _amountNeeded,
                0,
                array,
                true,
                charities.length
            )
        );
    }

    function donate(uint256 _charityId) public payable {
        if (msg.value == 0) {
            revert Charity__InputAnAmountGreaterThanZero();
        }
        if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten) > msg.value
        ) {
            charities[_charityId].amountGotten += msg.value;
            charities[_charityId].contributors.push(msg.sender);
        } else if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten) == msg.value
        ) {
            charities[_charityId].charityState = false;
            charities[_charityId].amountGotten += msg.value;
            charities[_charityId].contributors.push(msg.sender);
        } else if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten <
                msg.value) && charities[_charityId].charityState == true
        ) {
            revert Charity__MoreThanRequired(
                (charities[_charityId].amountNeeded -
                    charities[_charityId].amountGotten)
            );
        } else if (charities[_charityId].charityState == false) {
            revert Charity__CharityClosed();
        }
    }

    function donators(uint256 _charityId, uint256 _contributorId)
        public
        view
        returns (address)
    {
        return charities[_charityId].contributors[_contributorId];
    }

    function withdraw(uint256 _charityId) public {
        if (msg.sender != charities[_charityId].owner) {
            revert Charity__YouAreNotTheOwnerOfThisCharity();
        }

        (bool callSuccess, ) = payable(msg.sender).call{
            value: charities[_charityId].amountGotten
        }("");
        require(callSuccess, "call failed");
    }
}
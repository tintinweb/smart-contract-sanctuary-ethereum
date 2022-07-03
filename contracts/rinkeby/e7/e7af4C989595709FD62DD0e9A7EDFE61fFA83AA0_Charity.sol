//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Charity__InputAnAmountGreaterThanZero();
error Charity__YouAreNotTheOwnerOfThisCharity();
error Charity__MoreThanRequired(uint256 maxAmountToDonate);
error Charity__CharityClosed();
error Charity__InsufficientBalance(uint256 maxAmountToWithdraw);

contract Charity {
    struct Charities {
        address owner;
        uint256 amountNeeded;
        uint256 amountGotten;
        uint256 amountWithdrawn;
        address[] contributors;
        bool charityState;
        uint256 charityId;
        string descriptionCid;
        string fileCid;
    }

    Charities[] private charities;

    function createFundMe(
        uint256 _amountNeeded,
        string memory _descriptionCid,
        string memory _fileCid
    ) public {
        address[] memory array = new address[](0);
        charities.push(
            Charities(
                msg.sender,
                (_amountNeeded * 1e18),
                0,
                0,
                array,
                true,
                charities.length,
                _descriptionCid,
                _fileCid
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

    function withdraw(uint256 _charityId, uint256 _amountToWithdraw) public {
        if (msg.sender != charities[_charityId].owner) {
            revert Charity__YouAreNotTheOwnerOfThisCharity();
        }
        if (
            charities[_charityId].amountGotten -
                charities[_charityId].amountWithdrawn <
            _amountToWithdraw
        ) {
            revert Charity__InsufficientBalance(
                charities[_charityId].amountGotten -
                    charities[_charityId].amountWithdrawn
            );
        }
        charities[_charityId].amountWithdrawn += _amountToWithdraw;
        (bool callSuccess, ) = payable(msg.sender).call{
            value: _amountToWithdraw
        }("");
        require(callSuccess, "call failed");
    }

    function getCharities(uint256 _charityId)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        return (
            charities[_charityId].owner,
            charities[_charityId].amountNeeded,
            charities[_charityId].amountGotten,
            charities[_charityId].amountWithdrawn,
            charities[_charityId].charityState,
            charities[_charityId].charityId
        );
    }

    function getCharityContributors(uint256 _charityId)
        public
        view
        returns (address[] memory)
    {
        return charities[_charityId].contributors;
    }

    function getCharityDetails(uint256 _charityId)
        public
        view
        returns (string memory, string memory)
    {
        return (
            charities[_charityId].descriptionCid,
            charities[_charityId].fileCid
        );
    }

    function getFullInfo() public view returns (Charities[] memory) {
        Charities[] memory temporary = new Charities[](charities.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < charities.length; i++) {
            temporary[counter] = charities[i];
            counter++;
        }
        Charities[] memory result = new Charities[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function getMyInfo() public view returns (Charities[] memory) {
        Charities[] memory temporary = new Charities[](charities.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < charities.length; i++) {
            if (msg.sender == charities[i].owner) {
                temporary[counter] = charities[i];
                counter++;
            }
        }
        Charities[] memory result = new Charities[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function getAddressInfo(address _user)
        public
        view
        returns (Charities[] memory)
    {
        Charities[] memory temporary = new Charities[](charities.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < charities.length; i++) {
            if (_user == charities[i].owner) {
                temporary[counter] = charities[i];
                counter++;
            }
        }
        Charities[] memory result = new Charities[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Charity__InputAnAmountGreaterThanZero();
error Charity__YouAreNotTheOwnerOfThisCharity();
error Charity__MoreThanRequired(uint256 maxAmountToDonate);
error Charity__CharityClosed();
error Charity__InsufficientBalance(uint256 maxAmountToWithdraw);
error Charity__AlreadyEnded();
error Charity__NotEndedYet();
error Charity__CharityBalanceEmpty();

contract Charity {
    struct Donations {
        address contributor;
        uint256 amountDonated;
        uint256 charityId;
    }

    struct Charities {
        address owner;
        uint256 amountNeeded;
        uint256 amountGotten;
        bool withdrawalStatus;
        bool charityState;
        uint256 charityId;
        string descriptionCid;
        string fileCid;
    }

    Charities[] private charities;
    Donations[] private donations;

    function createFundMe(
        uint256 _amountNeeded,
        string memory _descriptionCid,
        string memory _fileCid
    ) public {
        charities.push(
            Charities(
                msg.sender,
                (_amountNeeded),
                0,
                false,
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
        if (charities[_charityId].charityState == false) {
            revert Charity__CharityClosed();
        }

        if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten) >
            msg.value &&
            charities[_charityId].charityState == true
        ) {
            charities[_charityId].amountGotten += msg.value;

            donations.push(Donations(msg.sender, msg.value, _charityId));
        } else if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten) ==
            msg.value &&
            charities[_charityId].charityState == true
        ) {
            charities[_charityId].charityState = false;
            charities[_charityId].amountGotten += msg.value;

            donations.push(Donations(msg.sender, msg.value, _charityId));
        } else if (
            (charities[_charityId].amountNeeded -
                charities[_charityId].amountGotten <
                msg.value) && charities[_charityId].charityState == true
        ) {
            revert Charity__MoreThanRequired(
                (charities[_charityId].amountNeeded -
                    charities[_charityId].amountGotten)
            );
        }
    }

    function withdraw(uint256 _charityId) public {
        if (msg.sender != charities[_charityId].owner) {
            revert Charity__YouAreNotTheOwnerOfThisCharity();
        }
        if (charities[_charityId].charityState == true) {
            revert Charity__NotEndedYet();
        }
        if (charities[_charityId].amountGotten == 0) {
            revert Charity__CharityBalanceEmpty();
        }
        charities[_charityId].withdrawalStatus = true;
        (bool callSuccess, ) = payable(msg.sender).call{
            value: charities[_charityId].amountGotten
        }("");
        require(callSuccess, "call failed");
    }

    function endFundMe(uint256 _charityId) public {
        if (msg.sender != charities[_charityId].owner) {
            revert Charity__YouAreNotTheOwnerOfThisCharity();
        }
        if (charities[_charityId].charityState == false) {
            revert Charity__AlreadyEnded();
        }

        charities[_charityId].charityState = false;
    }

    function getAllDonations() public view returns (Donations[] memory) {
        Donations[] memory temporary = new Donations[](donations.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            temporary[counter] = donations[i];
            counter++;
        }
        Donations[] memory result = new Donations[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function getDonationsByCharity(uint256 _charityId)
        public
        view
        returns (Donations[] memory)
    {
        Donations[] memory temporary = new Donations[](donations.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (_charityId == donations[i].charityId) {
                temporary[counter] = donations[i];
                counter++;
            }
        }
        Donations[] memory result = new Donations[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function getMyDonations(address _contributor)
        public
        view
        returns (Donations[] memory)
    {
        Donations[] memory temporary = new Donations[](donations.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (_contributor == donations[i].contributor) {
                temporary[counter] = donations[i];
                counter++;
            }
        }
        Donations[] memory result = new Donations[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function getAllCharities() public view returns (Charities[] memory) {
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

    function getAddressCharities(address _user)
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

    function getOpenCharities() public view returns (Charities[] memory) {
        Charities[] memory temporary = new Charities[](charities.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < charities.length; i++) {
            if (charities[i].charityState == true) {
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

    function getClosedCharities() public view returns (Charities[] memory) {
        Charities[] memory temporary = new Charities[](charities.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < charities.length; i++) {
            if (charities[i].charityState == false) {
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
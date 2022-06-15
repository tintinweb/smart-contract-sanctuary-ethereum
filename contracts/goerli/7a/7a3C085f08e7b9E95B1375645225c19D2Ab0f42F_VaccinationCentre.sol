//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract VaccinationCentre {
    struct Centre {
        bool isRegistered;
        string name;
        string location;
    }

    mapping(address => Centre) centreDatabase;

    event VaccinationCentreRegistered(
        address _centreAddress,
        string _name,
        string _location
    );

    function registerCentre(
        address _centreAddress,
        string memory _name,
        string memory _location
    ) public {
        require(
            _centreAddress == msg.sender,
            "You are cannot register this address as a vaccination centre"
        );
        Centre storage centre = centreDatabase[_centreAddress];

        if (!centre.isRegistered) {
            centre.isRegistered = true;
        }

        centre.name = _name;
        centre.location = _location;

        emit VaccinationCentreRegistered(_centreAddress, _name, _location);
    }

    function getCentreDetails(address _centreAddress)
        public
        view
        returns (Centre memory)
    {
        return centreDatabase[_centreAddress];
    }
}
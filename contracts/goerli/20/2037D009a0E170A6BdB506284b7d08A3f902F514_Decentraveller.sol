// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Decentraveller {
    uint256 public lastPlaceId = 0;

    enum TourismField {
        GASTRONOMY,
        ENTERTAINMENT,
        HISTORICAL
    }

    struct Place {
        TourismField TourismField;
        string latitude;
        string longitude;
        uint256 placeId;
        string[] reviews;
    }

    mapping(string => Place) public places;

    function addPlace(
        string memory _name,
        TourismField _tourismField,
        string memory _latitude,
        string memory _longitude
    ) public {
        lastPlaceId += 1;
        places[_name] = Place(
            _tourismField,
            _latitude,
            _longitude,
            lastPlaceId,
            new string[](0)
        );
    }

    function addReview(string memory _placeName, string memory _review) public {
        require(
            places[_placeName].placeId != 0,
            "Review must be added to an existent place"
        );
        places[_placeName].reviews.push(_review);
    }

    function getReviews(string memory _placeName)
        external
        view
        returns (string[] memory)
    {
        require(
            places[_placeName].placeId != 0,
            "Review must be added to an existent place"
        );
        return places[_placeName].reviews;
    }
}
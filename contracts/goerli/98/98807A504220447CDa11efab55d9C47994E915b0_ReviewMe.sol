// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ReviewMe__NotOwner();

contract ReviewMe {
    address private immutable owner;
    mapping(address => RatingProduct) private userToReview;
    address[] private reviewers;
    uint256 public amountOfReviews;

    struct RatingProduct {
        string opinion;
        uint8 starsNumber;
        bool isReviewed;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ReviewMe__NotOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setReview(string memory _opinion, uint8 _starsNumber) public {
        if (userToReview[owner].isReviewed) {
            revert("You have already added a review");
        }
        userToReview[owner].opinion = _opinion;
        userToReview[owner].starsNumber = _starsNumber;
        userToReview[owner].isReviewed = true;
        reviewers.push(owner);

        amountOfReviews++;
    }

    function getReviewByIndex(
        uint256 reviewIndex
    ) public view returns (string memory, uint256) {
        return (
            userToReview[reviewers[reviewIndex]].opinion,
            userToReview[reviewers[reviewIndex]].starsNumber
        );
    }
}
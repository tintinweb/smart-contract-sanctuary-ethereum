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
        if (userToReview[msg.sender].isReviewed) {
            revert("You have already added a review");
        }
        userToReview[msg.sender].opinion = _opinion;
        userToReview[msg.sender].starsNumber = _starsNumber;
        userToReview[msg.sender].isReviewed = true;
        reviewers.push(msg.sender);

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
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Verify {
    struct Review {
        address reviewer;
        string[] questions;
        string[] answers;
    }

    mapping(address => Review[]) public reviews;

    function review(
        address recipient,
        string[] memory questions,
        string[] memory answers
    ) public {
        Review memory _review = Review(msg.sender, questions, answers);
        reviews[recipient].push(_review);
    }

    function getNumReviews(address user) external view returns (uint256) {
        return reviews[user].length;
    }

    function getReview(address user, uint256 index)
        external
        view
        returns (
            address,
            string[] memory,
            string[] memory
        )
    {
        return (
            reviews[user][index].reviewer,
            reviews[user][index].questions,
            reviews[user][index].answers
        );
    }
}
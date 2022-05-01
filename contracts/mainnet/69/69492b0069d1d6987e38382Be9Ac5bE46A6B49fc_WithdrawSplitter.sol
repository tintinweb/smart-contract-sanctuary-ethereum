// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract WithdrawSplitter {
    address public constant ukraineAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    address public immutable otherAddress; // other address for withdrawal (for example, for artists)

    // proportions:
    uint16 public immutable ukrainePart;
    uint16 public immutable otherPart;

    constructor(address receiver_, uint16 ukrainePart_, uint16 otherPart_) {
        otherAddress = receiver_;
        ukrainePart = ukrainePart_;
        otherPart = otherPart_;
    }

    fallback() external payable { }

    receive() external payable { }

    // anybody - withdraw contract balance to ukraineAddress and otherAddress
    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        uint256 totalPart = ukrainePart + otherPart;

        // amount is divided according to the given proportions
        uint256 ukraineAmount = currentBalance * ukrainePart / totalPart;
        uint256 otherAmount = currentBalance * otherPart / totalPart;

        payable(ukraineAddress).transfer(ukraineAmount);
        payable(otherAddress).transfer(otherAmount);
    }
}
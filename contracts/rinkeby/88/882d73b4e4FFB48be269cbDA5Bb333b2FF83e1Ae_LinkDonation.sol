// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract LinkDonation {
    address owner;
    uint256 public donated = 0;
    address private tokenContractAddress;

    event Donation(address indexed donor, uint256 amountDonated);

    constructor(address _tokenContract) {
        owner = msg.sender;
        tokenContractAddress = _tokenContract;
    }

    function addPay(uint256 amount) public payable {
        IERC20 tokenContract = IERC20(tokenContractAddress);
        require(
            tokenContract.transferFrom(
                msg.sender,
                address(this),
                amount * 1 ether
            ),
            "Deposit Failed"
        );
        donated += amount;
        emit Donation(msg.sender, amount);
    }

    function getPays() public view returns (uint256) {
        return donated;
    }

    function withdrawToken(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can withdraw tokens");

        IERC20 tokenContract = IERC20(tokenContractAddress);
        donated -= _amount;
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }
}
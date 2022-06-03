// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

contract FundsManager {
    address payable private owner;
    uint256 public fee;
    mapping(address => uint256) public userGasAmounts;

    constructor(uint256 _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function fundWithGas() public payable {
        require(msg.value == fee, "You need to send exactly the fee in ETH!");

        userGasAmounts[msg.sender] += msg.value;
    }

    function refundGas(bool _all) public {
        require(
            userGasAmounts[msg.sender] > 0,
            "You do not have any remaining funds to withdraw"
        );

        address payable user = payable(msg.sender);

        if (_all || userGasAmounts[msg.sender] < fee) {
            user.transfer(userGasAmounts[msg.sender]);
            userGasAmounts[msg.sender] = 0;
        } else {
            user.transfer(fee);
            userGasAmounts[msg.sender] -= fee;
        }
    }

    function useGas(address _userAddress) external ownerOnly {
        require(
            userGasAmounts[_userAddress] > 0,
            "User does not have any funds left to pay the gas!"
        );

        if (userGasAmounts[_userAddress] >= fee) {
            owner.transfer(fee);
            userGasAmounts[_userAddress] -= fee;
        } else {
            owner.transfer(userGasAmounts[_userAddress]);
            userGasAmounts[_userAddress] = 0;
        }
    }

    function updateFee(uint256 _newFee) external ownerOnly {
        fee = _newFee;
    }
}
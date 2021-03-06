// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract HighriseLandFund {
    address public owner;

    // mapping to store which address deposited how much ETH
    mapping(address => uint256) public addressToAmountFunded;

    // token price in wei
    uint256 public landTokenPrice;

    enum FundState {
        ENABLED,
        DISABLED
    }

    FundState fundState;

    event FundLandEvent(
        address indexed sender,
        uint256 fundAmount,
        string reservationId
    );

    constructor(uint256 _landTokenPrice) {
        owner = msg.sender;
        landTokenPrice = _landTokenPrice;
        fundState = FundState.DISABLED;
    }

    modifier validAmount() {
        require(
            msg.value >= landTokenPrice,
            "Not enough ETH to pay for tokens"
        );
        _;
    }

    modifier enabled() {
        require(
            fundState == FundState.ENABLED,
            "Contract not enabled for funding"
        );
        _;
    }

    function fund(string calldata reservationId)
        public
        payable
        enabled
        validAmount
    {
        addressToAmountFunded[msg.sender] += msg.value;
        emit FundLandEvent(msg.sender, msg.value, reservationId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function enable() public onlyOwner {
        fundState = FundState.ENABLED;
    }

    function disable() public onlyOwner {
        fundState = FundState.DISABLED;
    }

    modifier disabled() {
        require(
            fundState == FundState.DISABLED,
            "Disable contract before withdrawing"
        );
        _;
    }

    function withdraw() public onlyOwner disabled {
        payable(msg.sender).transfer(address(this).balance);
    }
}
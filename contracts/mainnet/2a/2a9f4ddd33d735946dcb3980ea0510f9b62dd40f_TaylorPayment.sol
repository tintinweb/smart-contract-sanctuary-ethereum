/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
}


contract TaylorPayment {

    address public paymentAddress;
    address public owner;

    IERC20 constant public paymentToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI
    uint256 public payment = 1900 ether;
    uint256 public periodDurationInSeconds = 14 days;
    uint256 public lastPaymentTimestamp = 0;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(address _paymentAddress) {
        paymentAddress = _paymentAddress;
        owner = msg.sender;
    }

    function changePayment(uint256 _payment) public onlyOwner {
        payment = _payment;
    }

    function changePeriodDurationInSeconds(uint256 _periodDurationInSeconds) public onlyOwner {
        periodDurationInSeconds = _periodDurationInSeconds;
    }

    function withdrawPay() public {
        require(msg.sender == paymentAddress, "Incorrect user");
        require(block.timestamp - lastPaymentTimestamp >= periodDurationInSeconds, "Not enough time from last payment");
        lastPaymentTimestamp = block.timestamp;
        paymentToken.transfer(paymentAddress, payment);
    }

    function adminWithdraw() public onlyOwner {
        paymentToken.transfer(owner, paymentToken.balanceOf(address(this)));
    }
}
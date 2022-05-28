// contracts/SmartAdToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SMARTERC20.sol";
import "./SmartSafeMath.sol";
contract SmartAdToken is SMARTERC20 {
    address public _owner;
    mapping (address => uint256) private _fees;
    using SmartSafeMath for uint256;
    event SmartTransfer(address indexed _from, address _to);
    event SmartWithdraw(address indexed _to, uint256 _amount);
    constructor() public payable SMARTERC20() {
        _owner = msg.sender;
    }
    modifier onlyOwner () {
       require(msg.sender == _owner, "This can only be called by the contract owner!");
       _;
    }
    function smartTransfer(address payable recipient) payable public {
        require(msg.value > 0, 'Error, message value cannot be 0');
        require(msg.sender != address(this));
        uint256 amount = msg.value;
        uint256 fee = calculateFee(amount, recipient);
        uint256 amountToSend = amount.sub(fee);
        require(amountToSend < amount, 'Error, amount to send should be less than original value');
        recipient.transfer(amountToSend);
        emit SmartTransfer(msg.sender, recipient);
    }
    function smartTokenTransfer(SMARTERC20 token, address payable recipient, uint256 amount) public {
        require(amount > 0, 'Error, amount cannot be 0');
        require(msg.sender != address(this));
        uint256 fee = calculateFee(amount, recipient);
        uint256 amountToSend = amount.sub(fee);
        require(amountToSend < amount, 'Error, amount to send should be less than original value');
        token.transferFrom(msg.sender, address(this), fee);
        token.transferFrom(msg.sender, recipient, amountToSend);
        emit SmartTransfer(msg.sender, recipient);
    }
    function calculateFee(uint256 amount, address recipient) internal view returns(uint256 _fee) {
        uint256 fee = amount.div(100);
        if( _fees[recipient] > 1 ) {
            fee = fee.mul(_fees[recipient]);
        }
        return fee;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function withdraw(uint256 amount) onlyOwner public {
        require(amount <= address(this).balance, 'Insufficience funds to withdraw that amount');
        address payable sendTo = payable(msg.sender);
        sendTo.transfer(amount);
        emit SmartWithdraw(msg.sender, amount);
    }
    function withdrawToken(SMARTERC20 token, uint256 amount) onlyOwner public {
        require(amount <= token.balanceOf(address(this)), 'Insufficience funds to withdraw that amount');
        address payable sendTo = payable(msg.sender);
        token.transfer(sendTo, amount);
        emit SmartWithdraw(msg.sender, amount);
    }
    function setFee(uint256 fee, address recipient) onlyOwner public {
        require(fee < 100, 'Cannot set fee to more than 99');
        _fees[recipient] = fee;
    }
}
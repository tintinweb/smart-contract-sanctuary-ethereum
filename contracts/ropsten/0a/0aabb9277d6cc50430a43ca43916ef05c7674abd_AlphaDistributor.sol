// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlphaToken.sol";

contract AlphaDistributor is Ownable {

    using SafeMath for uint256;
    IERC20 public alpha;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('receiveApproval(address,uint256,address,uint256)')));
    uint public lockPercentage = 67;

    constructor (IERC20 _alpha) {
        require(address(_alpha) != address(0), "_alpha is a zero address");
        alpha = _alpha;
    }

    function alphaBalance() external view returns(uint) {
        return alpha.balanceOf(address(this));
    }

    function withdrawBone(address _destination, address _lockDestination, uint256 _lockingPeriod, uint256 _amount) external onlyOwner {
        uint256 _lockAmount = _amount.mul(lockPercentage).div(100);
        require(_lockAmount != 0, "locked amount is zero, cannot lock zero");
        require(alpha.transfer(_destination, _amount.sub(_lockAmount)), "transfer: withdraw failed");
        approveAndCall(_lockDestination, _lockAmount, _lockingPeriod);
    }

    function approveAndCall(address _spender, uint256 _value, uint256 _lockingPeriod) internal returns (bool success) {
        alpha.approve(_spender, _value);
        (bool thisSuccess,) = _spender.call(abi.encodeWithSelector(SELECTOR, alpha, _value, address(this), _lockingPeriod));
        require(thisSuccess, "Spender- receiveApproval failed");
        return true;
    }

    function setLockPercentage(uint _lockPercentage) external onlyOwner {
        lockPercentage = _lockPercentage;
    }
}
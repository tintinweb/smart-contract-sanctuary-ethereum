//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces.sol";

contract VestingContract is Ownable {

    uint public maxAmount;
    IBEP20 public everdomeToken;
    uint public start;
    uint immutable WEEK_PERIOD = 7*24*3600;
    uint immutable STARTING_PERCENTAGE = 10;
    uint immutable WEEK_PERCENTAGE = 2;
    uint public withdrawn = 0;

    constructor(uint _maxAmount, IBEP20 _everdomeToken, address _owner){
        everdomeToken = _everdomeToken;
        maxAmount = _maxAmount;
        start = block.timestamp;
        _transferOwnership(_owner);
    }

    function amountAvailableToBuy() public view returns(uint){
        uint amountAlreadyBought = everdomeToken.balanceOf(address(this))+withdrawn;
        return maxAmount - amountAlreadyBought;
    }

    function amountAvailableToWithdraw() public view returns(uint){
        uint totalAmount = withdrawn + everdomeToken.balanceOf(address(this));
        uint legalPercentage = getLegalPercentage();
        uint available = totalAmount*legalPercentage/100-withdrawn;
        return available;
    }

    function pull(uint amount) public{
        require(amount<=amountAvailableToBuy(),"over-buy-limit");
        everdomeToken.transferFrom(msg.sender,address(this),amount);
        emit PullCalled(amount);
    }

    function getLegalPercentage() public view returns(uint){
        uint percentage = STARTING_PERCENTAGE + WEEK_PERCENTAGE*((block.timestamp - start)/WEEK_PERIOD);
        if(percentage>100){
            return 100;
        }else{
            return percentage;
        }
    }

    function widthdrawAvailable() public{
        uint available = amountAvailableToWithdraw();
        withdrawn = withdrawn + available;
        everdomeToken.transfer(owner(), available);    
        emit WithdrawAvailableCalled(available);  
    }

    event PullCalled(uint amount);
    event WithdrawAvailableCalled(uint amount);
}
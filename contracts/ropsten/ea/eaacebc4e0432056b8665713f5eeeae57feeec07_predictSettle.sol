/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.8.14;

interface Predict {
    function settle() external;
    function lockInGuess(uint8 n) external payable;
    function isComplete() external returns (bool);
}

contract predictSettle {
    address preditAddress = 0x04F8738F1EDDeaB2158D077818BF4280Ea428Bd0;
    Predict predit = Predict(preditAddress);

    //address _owner;

    function lock() public payable {
        //_owner = msg.sender;
        predit.lockInGuess{value: 1 ether}(0);
    }

    function trySettle() public {
        predit.settle();
        require(predit.isComplete() == true);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
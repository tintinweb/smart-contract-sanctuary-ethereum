/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

pragma solidity ^0.8.7;


contract eventContractForTesting {  
    
    bool paramForStateChange = false;

    event OneParameterEvent(address indexed from);
    event TwoParameterEvent(address indexed from, address indexed contractAddress);
    event ThreeParameterEvent(address indexed from, address indexed contractAddress, bytes32 value);
    event FourParameterEvent(address indexed from, address indexed contractAddress, bytes32 value, uint256 blocktime);
    event FiveParameterEvent(address indexed from, address indexed contractAddress, bytes32 value, uint256 blocktime, uint256 gasleftnow);

    constructor(){}


    function triggerOneParamEvent() public {
        paramForStateChange = !paramForStateChange;
        emit OneParameterEvent(msg.sender);
    }

    function triggerTwoParamEvent() public {
        paramForStateChange = !paramForStateChange;
        emit TwoParameterEvent(msg.sender, address(this));
    }

    function triggerThreeParamEvent() public {
        paramForStateChange = !paramForStateChange;
        emit ThreeParameterEvent(msg.sender, address(this), blockhash(block.number));
    }

    function triggerFourParamEvent() public {
        paramForStateChange = !paramForStateChange;
        emit FourParameterEvent(msg.sender, address(this), blockhash(block.number), block.timestamp);
    }

    function triggerFiveParamEvent() public {
        paramForStateChange = !paramForStateChange;
        emit FiveParameterEvent(msg.sender, address(this), blockhash(block.number), block.timestamp, gasleft());
    }


}
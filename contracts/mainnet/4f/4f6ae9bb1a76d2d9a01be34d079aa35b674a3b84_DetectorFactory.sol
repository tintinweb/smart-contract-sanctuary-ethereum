/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

// author @koeppelmann
// Detector Factory allows to deploy new CensorshipDetector
// Each CensorshipDetector monitors wether a specific address is being cencored on Ethereum
// Each CensorshipDetector must be funded with ETH (anyone can send ETH to the CensorshipDetector)
// Once funded anyone can call the "withdrawal" in the "CensorshipDetector" every 1h and it will pay a small bounty to tx.origin (100k * basefee)
// During this transaction the "CensorshipDetector" will send 1 wei to the address that is endangered of being cencored.
// CensorshipDetector will log the coinbase (validator address) (those are NOT censoring) and the number of blocks that has passed.
// Censorhip can only be detected probilisiticy. Number of blocks should be as close as possible to 0.


contract DetectorFactory {
    event CensorshipDetectorDeployed (address indexed endangeredAddress, address indexed detector);
    
    
    // deploy a new "CensorshipDetector"
    // CensorshipDetector can get funded with depolyment or later
    function deploy(address _endangeredAddress) public payable {
        address predictedAddress = detectorAddress(_endangeredAddress);
        CensorshipDetector d = new CensorshipDetector{salt: 0, value: msg.value}(_endangeredAddress);
        require(address(d) == predictedAddress);
        emit CensorshipDetectorDeployed(_endangeredAddress, predictedAddress);
    }

    // calculates the deterministic address of CensorshipDetector (only dependet on "_endangeredAddress)
    function detectorAddress(address _endangeredAddress) public view returns(address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            uint(0),
            keccak256(abi.encodePacked(
                type(CensorshipDetector).creationCode,
                abi.encode(_endangeredAddress)
            ))
        )))));
    }

    // calls the withdrawl function of a CensorshipDetector - just a convinience fuction - it is more gas efficient to call it directly in the CD contract
    function withdrawal(address _endangeredAddress) public{
        CensorshipDetector(payable(detectorAddress(_endangeredAddress))).withdrawal();
    }
}



// CensorshipDetector
// can be called every 300 blocks (1h)
// pays (if funded) 100k * basefee to tx.origin
contract CensorshipDetector {
    uint public lastTouch;
    address public immutable endangeredAddress;
    uint constant public cooldown = 5*60; 

    event Log(address indexed producer, string message, uint indexed NumberOfBlocksCensored);


    constructor(address _endangeredAddress) payable {
        endangeredAddress = _endangeredAddress;
        lastTouch = block.number;
    }

    receive() external payable {}

    function withdrawal() public payable{
        require(block.number >= lastTouch + cooldown, "Has been called too recently");
        
        //send endangeredAddress 1 Wei
        endangeredAddress.call{value: 1 wei}("");
        //block.coinbase.call{value: 1 wei}("");
        
        tx.origin.call{value: block.basefee * 100000}("");
        
        emit Log(block.coinbase, "this block producer shall not be slashed", block.number - lastTouch - cooldown);
        lastTouch = block.number;

    }
}
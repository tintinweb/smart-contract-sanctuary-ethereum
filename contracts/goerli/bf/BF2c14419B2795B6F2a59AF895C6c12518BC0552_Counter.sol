// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "./IBridge.sol";

/// @title Counter
/// @author Shivam Agrawal
/// @notice This is a Counter contract that maintains a counter variable which is incremented by 1
/// whenever a cross-chain request is received from the bridge.
contract Counter {
    address public owner;
    address public feeManager;
    address public counterpartOnOtherChain;
    uint256 public counter;
    uint256 public feePerTx;
    IBridge public bridge;

    constructor(address _bridge, address _feeManager) {
        require(_bridge != address(0), "bridge cannot be address 0");
        require(_feeManager != address(0), "fee manager cannot be address 0");

        owner = msg.sender;
        bridge = IBridge(_bridge);
        feeManager = _feeManager;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    /// @notice Function to set the address of counterpart on other chain.
    /// @notice Only the owner can call this function.
    /// @param _counterpartOnOtherChain Address of the counterpart contract on other chain.
    function setCounterpartOnOtherChain(address _counterpartOnOtherChain) external onlyOwner {
        require(_counterpartOnOtherChain != address(0), "counterpart address can't be address(0)");
        counterpartOnOtherChain = _counterpartOnOtherChain;
    }

    /// @notice Function to set the feeManager.
    /// @notice Only the owner can call this function.
    /// @param _feeManager Address of the fee manager.
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "fee manager address can't be address(0)");
        feeManager = _feeManager;
    }

    /// @notice Function to set the fee for each transaction.
    /// @notice Only the owner can call this function.
    /// @param _feePerTx Amount of the fee per transaction in wei.
    function setFeePerTx(uint256 _feePerTx) external onlyOwner {
        require(_feePerTx != 0 && _feePerTx < 10000000000000000, "fee should be between 0 and 0.01 Ether");
        feePerTx = _feePerTx;
    }

    /// @notice Function to send a message to the bridge contract to be relayed to the other chain.
    /// @notice This calls the send function on the bridge with the data to be called on destination side.
    /// @notice The data contains the selector to the function to be called on destination chain contract
    /// and the address of this contract(sendingCounter) as the parameter to that function.
    function send() external payable {
        require(msg.value >= feePerTx, "passed value is lesser than required");
        payable(feeManager).transfer(msg.value);

        address _counterpartOnOtherChain = counterpartOnOtherChain;
        require(_counterpartOnOtherChain != address(0), "counterpart address on other chain not set");

        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("increment(address)")), address(this));

        bridge.send(_counterpartOnOtherChain, data);
    }

    /// @notice Function to increment the counter when a request is received from the bridge.
    /// @notice Only the bridge contract can call this function.
    /// @notice Only the request from the counterpart contract on source chain can be received here.
    /// @notice This is called when Bridge contract receives a cross-chain communication request from relayer.
    /// @notice This function increases the value of counter by 1 when the checks are passed.
    /// @param  _senderOfRequest the address of sender of the request on source chain.
    function increment(address _senderOfRequest) external {
        require(msg.sender == address(bridge), "only bridge");
        require(counterpartOnOtherChain == _senderOfRequest, "sending counter invalid");
        counter += 1;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IBridge {
    function send(address recievingCounter, bytes calldata data) external;
}
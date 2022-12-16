// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./UserOperation.sol";

contract BitsWallet {
    // state variables.
    address payable public owner; // the controller of the wallet.
    address payable public automator = payable(0x6544221ab793a1cb3b68395ab487Be2c99EC555f); // my dev wallet.
    address payable public immutable entryPoint; // the EntryPoint contract address I have deployed to Goerli.
    uint public nonce; // the wallet nonce against double spending.

    // setting up ability to receive Ether.
    receive() external payable {}
    fallback() external payable {}

    constructor(address _owner, address _entryPoint) {
        // deploy with wallet's owner address.
        owner = payable(_owner);
        entryPoint = payable(_entryPoint);
    }

    // core ERC 4337 validation functions:
    function validateUserOp(UserOperation calldata userOp, bool simulate) external onlyEntryPoint {
        // for the signature validation scheme, the owner and the automator agree to a password off chain. That is then hashed by the automator and sent through as userOp.signature. The hash is stored on chain as it is a one-way function, and the hash value sent to chain is checked against the stored hash and then it can pass.
        bytes32 requiredHash = 0x0c9acee3550ac5b50fe6a04a9e4818ca9a2574b50629278f2be407b4a7c4c8dd;

        require((nonce + 1) == userOp.nonce && bytes32(userOp.signature) == requiredHash, "Signature Validation did not pass! Better luck next time ;)");

        // as validation has succeeded, it is safe to increment the nonce if we are not in a bundler simulateValidationc call.
        if (simulate == false){
            nonce++;
        }
    }

    // core ERC 4337 execution function:
    // called by entryPoint, only after validateUserOp succeeded.
    // assume that for this simple example, the only execution logic is to automate a payment every day.
    function executionFromEntryPoint(bytes memory callData) external onlyEntryPoint returns(address payable destination, uint amount, bool success) {
        // unpacking callData from encoded bytes representation.
        address destinationNonPayable;
        (destinationNonPayable, amount) = abi.decode(callData, (address, uint));
        destination = payable(destinationNonPayable);

        // main execution.
        success = _call(destination, amount);

        return (destination, amount, success);
    }

    // wallet core functionality:
    // this is the main function used to transfer to a destination address. It is private as only executionFromEntryPoint should be able to call it or the owner of the wallet.
    function _call(address payable destination, uint value) private returns(bool success) {
        // sending empty data for simplicity.
        // value is almost certainly in WEI.
        (success, ) = destination.call{value : value}("");
        require(success, "Failed to send Ether!");
        return(success);
    }

    // owner's way to transfer funds.
    function _transfer(address payable dest, uint value) external onlyOwner {
        _call(dest, value);
    }

    // owner's way to withdraw funds.
    function _withdraw(uint value) external onlyOwner {
        _call(owner, value);
    }

    // getBalance getter.
    function getBalance() external view returns(uint) {
        uint balance = address(this).balance;
        return balance;
    }

    // change owner and automator post-hoc (exicting ERC 4337 benefits!)
    function changeOwner(address _owner) external onlyOwner {
        owner = payable(_owner);
    }

    function changeAutomator(address _automator) external onlyOwner {
        // perhaps I could allow automator to change this aswell.
        automator = payable(_automator);
    }

    function getNonce() public view returns(uint){
        return nonce;
    }

    // modifiers for owner, automator and entry point access.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyAutomator() {
        require(msg.sender == automator, "Not Automator");
        _;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == entryPoint, "Not EntryPoint");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes callData;
    bytes signature;
}
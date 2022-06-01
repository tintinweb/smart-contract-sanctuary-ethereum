// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ExchangeRegistry {
    address owner; // Address of exchange Registry owner.
    mapping(address => mapping(address => address)) swapContracts; // Mapping to store the exchange contract address for From Token to To Token, From Token -> To Token -> Exchange contract.

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /// @dev Function to get exchange contract address for From Token to To Token.
    /// @param _from Address of From Token.
    /// @param _to Address of To Token.
    function getSwapContract(address _from, address _to)
        public
        view
        returns (address)
    {
        require(
            swapContracts[_from][_to] != address(0),
            "No swap contract available!"
        );
        return swapContracts[_from][_to];
    }

    /// @dev Function to set address of Owner.
    /// @param _owner Address of new owner.
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /// @dev Function to add exchange contract address for From Token to To Token.
    /// @param _from Address of From Token.
    /// @param _to Address of To Token.
    /// @param _contract Address of exchange contract.
    function addOrChangeSwapContract(
        address _from,
        address _to,
        address _contract
    ) external onlyOwner {
        require(_contract != address(0), "contract address should not be zero");
        swapContracts[_from][_to] = _contract;
    }

    /// @dev Function to remove exchange contract address for From Token to To Token.
    /// @param _from Address of From Token.
    /// @param _to Address of To Token.
    function removeSwapContract(address _from, address _to) external onlyOwner {
        delete swapContracts[_from][_to];
    }
}
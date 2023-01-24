/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

pragma solidity ^0.8.0;

contract Portfolio {
    // Struct to represent a holding in the portfolio
    struct Holding {
        string name;        // name of the asset
        uint quantity;      // quantity of the asset
        uint purchasePrice; // purchase price of the asset
        address tokenAddress; // address of the ERC20 token contract
    }

    // Mapping from asset names to holdings
    mapping(string => Holding) public holdings;

    // Add a new holding to the portfolio
    function addHolding(string memory _name, uint _quantity, uint _purchasePrice, address _tokenAddress) public {
        holdings[_name] = Holding(_name, _quantity, _purchasePrice, _tokenAddress);
    }

    // Update the quantity of an existing holding in the portfolio
    function updateHoldingQuantity(string memory _name, uint _newQuantity) public {
        Holding storage holding = holdings[_name];
        holding.quantity = _newQuantity;
    }

    // Update the purchase price of an existing holding in the portfolio
    function updateHoldingPurchasePrice(string memory _name, uint _newPurchasePrice) public {
        Holding storage holding = holdings[_name];
        holding.purchasePrice = _newPurchasePrice;
    }

    // Update the token address of an existing holding in the portfolio
    function updateHoldingTokenAddress(string memory _name, address _newTokenAddress) public {
        Holding storage holding = holdings[_name];
        holding.tokenAddress = _newTokenAddress;
    }

    // Remove a holding from the portfolio
    function removeHolding(string memory _name) public {
        delete holdings[_name];
    }
}
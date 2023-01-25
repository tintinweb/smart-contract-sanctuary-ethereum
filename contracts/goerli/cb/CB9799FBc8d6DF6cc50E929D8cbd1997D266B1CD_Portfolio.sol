/**
 *Submitted for verification at Etherscan.io on 2023-01-25
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

    uint public id;

    // Mapping from id to holdings
    mapping(uint => Holding) public holdings;

    // Add a new holding to the portfolio
    function addHolding(string memory _name, uint _quantity, uint _purchasePrice, address _tokenAddress) public {
        holdings[id] = Holding(_name, _quantity, _purchasePrice, _tokenAddress);
        id += 1;
    }

    function getOne(uint _id) public view returns (Holding memory) {
        return holdings[_id];
    }

    // Update the quantity of an existing holding in the portfolio
    function updateHoldingQuantity(uint _id, uint _newQuantity) public {
        Holding storage holding = holdings[_id];
        holding.quantity = _newQuantity;
    }

    // Update the purchase price of an existing holding in the portfolio
    function updateHoldingPurchasePrice(uint _id, uint _newPurchasePrice) public {
        Holding storage holding = holdings[_id];
        holding.purchasePrice = _newPurchasePrice;
    }

    // Update the token address of an existing holding in the portfolio
    function updateHoldingTokenAddress(uint _id, address _newTokenAddress) public {
        Holding storage holding = holdings[_id];
        holding.tokenAddress = _newTokenAddress;
    }

    // Remove a holding from the portfolio
    function removeHolding(uint _id) public {
        delete holdings[_id];
    }
}
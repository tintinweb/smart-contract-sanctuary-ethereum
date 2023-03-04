// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract JosamToken {
    // State variables
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    mapping(address => uint256) balances;
    bool private _initialized;

    // Create constructor by passing Token name and Symbol, then pre-mint 1 000 000 Tokens.
    // constructor() {
    //     _name = "Josam Token";
    //     _symbol = "JTK";
    //     _owner = payable(msg.sender); // The owner of the contract.

    //     _totalSupply += 1000000;
    //     balances[_owner] += 1000000; // Update the balance of the owner.
    // }

    // To follow Openzeppelin pattern, instead of using constructor, we are going to use function initializer.
    function initialize(string memory _tName, string memory _tSymbol) public {
        require(!_initialized, "Contract instance has already initialized.");
        _name = _tName;
        _symbol = _tSymbol;

        _totalSupply += 1000000;
        balances[msg.sender] += 1000000; // Update the balance of the owner.
        _initialized = true;
    }

    // Get the Token name.
    function name() public view returns (string memory) {
        return _name;
    }

    // get the Token symbol.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Get the Token's total Supply.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Get the Token's decimals.
    function decimals() public pure returns (uint8) {
        return 18;
    }

    // Get Account balance.
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
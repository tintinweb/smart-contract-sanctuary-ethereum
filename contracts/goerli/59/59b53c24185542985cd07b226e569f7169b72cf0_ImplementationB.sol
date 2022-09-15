/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// File: contracts/UUPS-Classwork/Proxiable.sol
pragma solidity ^0.8.4;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}
// File: contracts/UUPS-Classwork/ImplementationB.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ImplementationB is Proxiable {
    address public owner;

    uint  public totalSupply;
    uint public circulatingSupply;
    string public name;
    string public symbol;
    uint public decimal;

    mapping(address => uint) public _balance;

    function constructor1(uint _totalSupply, string memory _name, string memory _symbol, uint _decimal) public {
        require(owner == address(0), "Already initalized");
        owner = msg.sender;
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
    }

    function mint(uint amount, address _to) public onlyOwner returns(uint){
        circulatingSupply += amount;  // increase total circulating supply
        require(circulatingSupply <= totalSupply, "totalSupply Exceeded");
        require(_to != address(0), "mint to address zero ");

        uint value = amount * decimal;

        _balance[_to] += value; //increase balance of to

        return value;
    }

    function _burn(uint amount) private  returns(uint256 burnableToken){
        burnableToken = calculateBurn(amount);
        circulatingSupply -= burnableToken /  decimal;
    }

    function calculateBurn (uint amount) public pure returns(uint burn){
        burn = (amount * 10)/100;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    function encode() external pure returns (bytes memory) {
        return abi.encodeWithSignature("constructor1(uint256,string,string,uint256)",1000,"Cas Token","CTN",10e18);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}
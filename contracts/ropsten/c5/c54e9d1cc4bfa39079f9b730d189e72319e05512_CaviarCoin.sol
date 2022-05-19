/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CaviarCoin {

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    string public constant name = "Caviar";
    string public constant symbol = "CAV";
    // Decimales dados
    uint256 public constant decimals = 18;
    // Fee dado en porcentaje (0-100)
    uint256 public constant fee = 5;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    
    constructor(uint256 total) {
      totalSupply_ = total;
      balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens - 10;
        // Resto el fee aplicado a la transacción
        numTokens -= _extractFee(numTokens);
        // Creo la transferencia aplicándole los decimales dados
        emit Transfer(msg.sender, receiver, numTokens * decimals);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;

        // Resto el fee aplicado a la transacción
        numTokens -= _extractFee(numTokens);

        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    /*
    * Extraigo el fee de la cantidad
    */
    function _extractFee(uint256 amount_) internal virtual returns (uint256) {
        uint256 fee_ = amount_ * (fee/100);
        return fee_;
    }

}
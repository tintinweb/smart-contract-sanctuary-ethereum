//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Vault {
    struct TokenVault {
        address owner;
        address token;
        uint256 balance;
    }

    mapping(address => TokenVault) private tokenVaults;

    function getTokenVault(address _token) public view returns (address, address, uint256) {
        TokenVault storage tokenVault = tokenVaults[_token];
        return (tokenVault.owner, tokenVault.token, tokenVault.balance);
    }

    // deposit tokens
    function deposit(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
    //    require(tokenVaults[_token].owner == msg.sender, "Only owner can deposit tokens");

        TokenVault storage tokenVault = tokenVaults[_token];
        tokenVault.balance += _amount;
        tokenVaults[_token] = tokenVault;
    }

    // withdraw tokens
    function withdraw(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(tokenVaults[_token].owner == msg.sender, "Only owner can withdraw tokens");

        TokenVault storage tokenVault = tokenVaults[_token];
        require(tokenVault.balance >= _amount, "Not enough tokens");
        tokenVault.balance -= _amount;
        tokenVaults[_token] = tokenVault;
    }

    // transfer tokens
    function transfer(address _to, address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(tokenVaults[_token].owner == msg.sender, "Only owner can transfer tokens");

        TokenVault storage tokenVault = tokenVaults[_token];
        require(tokenVault.balance >= _amount, "Not enough tokens");
        tokenVault.balance -= _amount;
        tokenVaults[_token] = tokenVault;

        TokenVault storage toTokenVault = tokenVaults[_to];
        toTokenVault.balance += _amount;
        tokenVaults[_to] = toTokenVault;
    }

    // mint tokens for every stablecoin deposited into vault
    function mint(address _token) public {
        require(tokenVaults[_token].owner == msg.sender, "Only owner can mint tokens");

        TokenVault storage tokenVault = tokenVaults[_token];
        require(tokenVault.balance > 0, "No tokens to mint");

        TokenVault storage stablecoinVault = tokenVaults[tokenVault.token];
        stablecoinVault.balance += tokenVault.balance;
        tokenVaults[tokenVault.token] = stablecoinVault;
        tokenVaults[_token] = TokenVault({owner: msg.sender, token: tokenVault.token, balance: 0});
    }

    // burn tokens
    function burn(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
      //  require(tokenVaults[_token].owner == msg.sender, "Only owner can burn tokens");

        TokenVault storage tokenVault = tokenVaults[_token];
        require(tokenVault.balance >= _amount, "Not enough tokens");
        tokenVault.balance -= _amount;
        tokenVaults[_token] = tokenVault;
    }

    // mint tokens for every stablecoin deposited into vault
    function transferOwnership(address _newOwner) public {
        require(tokenVaults[_newOwner].owner == msg.sender, "Only owner can transfer");

        TokenVault storage tokenVault = tokenVaults[_newOwner];
        tokenVault.owner = msg.sender;
        tokenVaults[_newOwner] = tokenVault;
    }

}
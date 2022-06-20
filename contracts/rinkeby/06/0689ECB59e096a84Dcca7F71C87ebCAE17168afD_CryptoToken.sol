/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Math {


    function percent(uint256 a, uint256 b) public pure returns(uint256){
        uint256 c = a - a*b/100;
        return c;
    }




}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowence(address owner, address spender) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

contract CryptoToken is IERC20 {
    //Libs
    using Math for uint256;

    //Enums
    enum Status {
        ACTIVE,
        PAUSED,
        CANCELLED,
        KILLED
    }

    //Properties
    string public constant name = "CryptoToken";
    string public constant symbol = "CRY";
    uint8 public constant decimals = 3; //Default dos exemplos é sempre 18
    uint256 private totalsupply;
    uint256 private burnable;
    address private owner;
    address[] private tokenOwners;
    address private furnace;
    Status contractState;

    mapping(address => uint256) private addressToBalance;
    mapping(address => mapping(address => uint256)) allowed;

    modifier isOwner() {
        require(address(msg.sender) == owner, "Sender is not owner!");
        _;
    }

    //Constructor
    constructor() {
        uint256 total = 1000;
        totalsupply = total;
        owner = msg.sender;
        addressToBalance[owner] = totalsupply;
        tokenOwners.push(owner);
        contractState = Status.ACTIVE;
    }

    //Public Functions
    function totalSupply() public view override returns (uint256) {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        return totalsupply;
    }

    function balanceOf(address tokenOwner) public view override
        returns (uint256)
    {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        return addressToBalance[tokenOwner];
    }

    function burn(uint256 value) public isOwner returns (bool) {
        //require(contractState == Status.ACTIVE,"The Airdrop is not available now :(");
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        furnace = 0xf000000000000000000000000000000000000000;

        for (uint256 i = 0; i < tokenOwners.length; i++) {
            addressToBalance[tokenOwners[i]] = addressToBalance[tokenOwners[i]]
                .percent(value);

            emit Transfer(
                tokenOwners[i],
                furnace,
                addressToBalance[tokenOwners[i]]
            );
        }
        totalsupply = totalsupply.percent(value);

        return true;
    }

    function autoBurn(uint256 value) public isOwner {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        burnable = value;
        burn(burnable);
    }

    function transfer(address receiver, uint256 quantity)
        public
        override
        isOwner
        returns (bool)
    {

        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        require(
            quantity <= addressToBalance[owner],
            "Insufficient Balance to Transfer"
        );
        addressToBalance[owner] = addressToBalance[owner] - quantity;
        addressToBalance[receiver] = addressToBalance[receiver] + quantity;
        tokenOwners.push(receiver);
        autoBurn(burnable);

        emit Transfer(owner, receiver, quantity);
        return true;
    }

    //Mint: Adicionar tokens ao total supply
    function mintToken() public isOwner {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        uint256 amount = 1000;
        if (balanceOf(owner) < 1001) {
            totalsupply += amount;
            addressToBalance[owner] += amount;
            emit Transfer(owner, owner, 1000);
        }
    }

    function approve(address spender, uint256 numTokens) public  isOwner override  returns(bool){
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function allowence(address ownerToken, address spender) public override view returns(uint256){
        return allowed[ownerToken][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override  returns(bool){
        require(amount <= addressToBalance[from], "Sender Insufficient Balance to Transfer");
        require(amount <= allowed[from][msg.sender], "Allowed Insufficient Balance to Transfer");
        addressToBalance[from] -= amount;
        allowed[from][msg.sender] -= amount;
        addressToBalance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function getOwner() public view returns(address){
        return address(owner);
    }
    
    function state() public view returns (Status) {
        return contractState;
    }

    function cancelContract() public isOwner  {
        contractState = Status.CANCELLED;
    }

    function pauseContract() public isOwner {
        contractState = Status.PAUSED;
    }

    function activeContract() public isOwner {
        contractState = Status.ACTIVE;
    }

    function kill() public isOwner {
        require(contractState == Status.CANCELLED, "The contract is active");
        contractState = Status.KILLED;
        selfdestruct(payable(owner));
    }
}
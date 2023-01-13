/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

pragma solidity >= 0.7.0 < 0.9.0;

contract RefreshingDev {
    string public constant name = "Refreshing Dev";
    string public constant symbol = "RD";
    uint8 public constant decimals = 18;

    address public minter;
    address public treasury;
    uint public totalSupply = 1000;
    uint public initialSupply = 1000;
    uint public txFee;
    uint public maxWallet;
    uint public maxTx; 
    mapping(address => uint) public balances;

    event Sent(address from, address to, uint amount);
    event Burn(address from, address to, uint amount);

    constructor () {
        treasury = msg.sender;
        minter = msg.sender;
        txFee = 10;
        maxWallet = 2;
        maxTx = 1;
        balances[minter] = initialSupply;
        
    }  

    

    error insufficientBalance(uint requested, uint available);
    error exceedsMaxWallet(uint requested, uint available);
    error exceedsMaxTx(uint requested);

    function send(address receiver, uint amount) public {
        if(amount > balances[msg.sender])
        revert insufficientBalance({
            requested: amount,
            available: balances[msg.sender]
        });
        if(balances[receiver] + amount > totalSupply * maxWallet / 100)
        revert exceedsMaxWallet({
            requested: amount,
            available: balances[receiver]
        });
        if (amount > totalSupply * maxTx / 100)
        revert exceedsMaxTx({
            requested: amount  
        });
        balances[msg.sender] -= amount;
        balances[receiver] += amount - (amount * txFee / 100);
        balances[treasury] += amount * txFee / 100; 
        emit Sent(msg.sender, receiver, amount);
    }

    function burn(uint amount) public {
        if(amount > balances[msg.sender])
        revert insufficientBalance({
            requested: amount,
            available: balances[msg.sender]
        });
        address deadWallet = 0x000000000000000000000000000000000000dEaD;
        balances[msg.sender] -= amount;
        balances[deadWallet] += amount;
        emit Burn(msg.sender, deadWallet, amount);
    }

    function settxFee(uint _txFee) public {
        txFee = _txFee;
        require(msg.sender == minter);
    }

    function setMaxWallet(uint _maxWallet) public {
        maxWallet = _maxWallet;
        require(msg.sender == minter);
    }

    function setMaxTx(uint _maxTx) public {
        maxTx = _maxTx;
        require(msg.sender == minter);
    }
    
}
/**
 *Submitted for verification at Etherscan.io on 2017-10-19
*/

/*
* This is the source code of the smart contract for the SOUL token, aka Soul Napkins.
* Copyright 2017 and all rights reserved by the owner of the following Ethereum address:
* 0x10E44C6bc685c4E4eABda326c211561d5367EEec
*/

pragma solidity ^0.4.17;

// ERC Token standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {

    // Token symbol
    string public constant symbol = "TBA";

    // Name of token
    string public constant name ="TBA";

    // Decimals of token
    uint8 public constant decimals = 18;

    // Total token supply
    function totalSupply() public constant returns (uint256 supply);

    // The balance of account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    // Send _value tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// Implementation of ERC20Interface
contract ERC20Token is ERC20Interface{

    // account balances
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Function to access acount balances
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    // Transfer the _amount from msg.sender to _to account
    function transfer(address _to, uint256 _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // Function to specify how much _spender is allowed to transfer on _owner's behalf
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

}


// Token implementation that allows selling of souls and distribution of napkins
contract SoulToken is ERC20Token{

    // The three letter symbol of token
    string public constant symbol = "SOUL";

    // Name of token
    string public constant name = "Soul Napkins";

    // 6 is a holy number (2*3) so there are 6 decimals
    uint8 public constant decimals = 6;

    // With 6 decimals, a single unit is 10**6
    uint256 public constant unit = 1000000;

    // fee to pay to transfer soul, 10% like the ecclesiastical tithe
    uint8 public constant obol = 10;

    // price per token, 100 napkins per Ether
    uint256 public constant napkinPrice = 10 finney / unit;

    // Total number of napkins available
    // 144,000 (get it?)
    uint256 constant totalSupply_ = 144000 * unit;

    // mapping to keep the reason of the soul sale!
    mapping(address => string) reasons;

    // prices that people put up for their soul
    mapping(address => uint256) soulPrices;

    // who owns a particular soul
    mapping(address => address) ownedBy;

    // number of souls owned by someone
    mapping(address => uint256) soulsOwned;

    // book of souls, listing all souls on sale and sold
    mapping(uint256 => address) soulBook;

    // owner of the contract
    address public owner;

    // Address where soul obol is due to
    address public charonsBoat;

    // small fee to insert soul into soulbook
    uint256 public bookingFee;

    // souls for sale
    uint256 public soulsForSale;

    // souls already sold
    uint256 public soulsSold;

    // total amount of Wei collected by Charon
    uint256 public totalObol;

    // Logs a soul transfer
    event SoulTransfer(address indexed _from, address indexed _to);

    function SoulToken() public{
        owner = msg.sender;
        charonsBoat = msg.sender;
        // fee for inserting into soulbook, unholy 13 finney
        bookingFee = 13 finney;
        soulsForSale = 0;
        soulsSold = 0;
        totalObol = 0;
        // all napkins belong to the contract at first:
        balances[this] = totalSupply_;
        // 1111 napkins for the dev ;-)
        payOutNapkins(1111 * unit);
    }

    // fallback function, Charon sells napkins as merchandise!
    function () public payable {
        uint256 amount;
        uint256 checkedAmount;
        // give away some napkins in return proportional to value
        amount = msg.value / napkinPrice;
        checkedAmount = checkAmount(amount);
        // only payout napkins if there is the appropriate amount available
        // else throw
        require(amount == checkedAmount);
        // forward money to Charon
        payCharon(msg.value);
        // finally payout napkins
        payOutNapkins(checkedAmount);
    }

    // allows changing of the booking fee, note obol and token price are fixed and cannot change
    function changeBookingFee(uint256 fee) public {
        require(msg.sender == owner);
        bookingFee = fee;
    }

    // changes Charon's boat, i.e. the address where the obol is paid to
    function changeBoat(address newBoat) public{
        require(msg.sender == owner);
        charonsBoat = newBoat;
    }

    // total number of napkins distributed by Charon
    function totalSupply() public constant returns (uint256){
        return totalSupply_;
    }

    // returns the reason for the selling of one's soul
    function soldSoulBecause(address noSoulMate) public constant returns(string){
        return reasons[noSoulMate];
    }

    // returns the owner of a soul
    function soulIsOwnedBy(address noSoulMate) public constant returns(address){
        return ownedBy[noSoulMate];
    }

    // returns number of souls owned by someone
    function ownsSouls(address soulOwner) public constant returns(uint256){
        return soulsOwned[soulOwner];
    }

    // returns price of a soul
    function soldSoulFor(address noSoulMate) public constant returns(uint256){
        return soulPrices[noSoulMate];
    }

    // returns the nth entry in the soulbook
    function soulBookPage(uint256 page) public constant returns(address){
        return soulBook[page];
    }

    // sells your soul for a given price and a given reason!
    function sellSoul(string reason, uint256 price) public payable{
        uint256 charonsObol;
        string storage has_reason = reasons[msg.sender];

        // require that user gives a reason
        require(bytes(reason).length > 0);

        // require to pay bookingFee
        require(msg.value >= bookingFee);

        // you cannot give away your soul for free, at least Charon wants some share
        charonsObol = price / obol;
        require(charonsObol > 0);

        // assert has not sold her or his soul, yet
        require(bytes(has_reason).length == 0);
        require(soulPrices[msg.sender] == 0);
        require(ownedBy[msg.sender] == address(0));

        // pay book keeping fee
        payCharon(msg.value);

        // store the reason forever on the blockchain
        reasons[msg.sender] = reason;
        // also the price is forever kept on the blockchain, so do not be too cheap
        soulPrices[msg.sender] = price;
        // and keep the soul in the soul book
        soulBook[soulsForSale + soulsSold] = msg.sender;
        soulsForSale += 1;
    }

    // buys msg.sender a soul and rewards him with tokens!
    function buySoul(address noSoulMate) public payable returns(uint256 amount){
        uint256 charonsObol;
        uint256 price;

        // you cannot buy an owned soul:
        require(ownedBy[noSoulMate] == address(0));
        // get the price of the soul
        price = soulPrices[noSoulMate];
        // Soul must be for sale
        require(price > 0);
        require(bytes(reasons[noSoulMate]).length > 0);
        // Msg sender needs to pay the soul price
        require(msg.value >= price);
        charonsObol = msg.value / obol;

        // check for wrap around
        require(soulsOwned[msg.sender] + 1 > soulsOwned[msg.sender]);

        // pay Charon
        payCharon(charonsObol);
        // pay the soul owner
        noSoulMate.transfer(msg.value - charonsObol);

        // Update the soul stats
        soulsForSale -= 1;
        soulsSold += 1;
        // Increase the sender's balance by the appropriate amount of souls ;-)
        soulsOwned[msg.sender] += 1;
        ownedBy[noSoulMate] = msg.sender;
        // log the transfer
        SoulTransfer(noSoulMate, msg.sender);

        // and give away napkins proportional to obol plus 1 bonus napkin ;-)
        amount = charonsObol / napkinPrice + unit;
        amount = checkAmount(amount);
        if (amount > 0){
            // only payout napkins if they are available
            payOutNapkins(amount);
        }

        return amount;
    }

    // can transfer a soul to a different account, but beware you have to pay Charon again!
    function transferSoul(address _to, address noSoulMate) public payable{
        uint256 charonsObol;

        // require correct ownership
        require(ownedBy[noSoulMate] == msg.sender);
        require(soulsOwned[_to] + 1 > soulsOwned[_to]);
        // require transfer fee is payed again
        charonsObol = soulPrices[noSoulMate] / obol;
        require(msg.value >= charonsObol);
        // pay Charon
        payCharon(msg.value);
        // transfer the soul
        soulsOwned[msg.sender] -= 1;
        soulsOwned[_to] += 1;
        ownedBy[noSoulMate] = _to;

        // Log the soul transfer
        SoulTransfer(msg.sender, _to);
    }

    // logs and pays charon fees
    function payCharon(uint256 obolValue) internal{
        totalObol += obolValue;
        charonsBoat.transfer(obolValue);
    }

    // checks if napkins are still available and adjusts amount accordingly
    function checkAmount(uint256 amount) internal constant returns(uint256 checkedAmount){

        if (amount > balances[this]){
            checkedAmount = balances[this];
        } else {
            checkedAmount = amount;
        }

        return checkedAmount;
    }

    // transfers napkins to people
    function payOutNapkins(uint256 amount) internal{
        // check for amount and wrap around
        require(amount > 0);
        // yeah some sanity check
        require(amount <= balances[this]);

        // send napkins from contract to msg.sender
        balances[this] -= amount;
        balances[msg.sender] += amount;
        // log napkin transfer
        Transfer(this, msg.sender, amount);
    }

}
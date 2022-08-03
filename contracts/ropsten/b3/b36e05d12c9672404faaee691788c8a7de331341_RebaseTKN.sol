/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RebaseTKN {
    
    address public owner;
    address public casino;

    uint internal constant maxNo = type(uint).max;   // IMMUTABLE
    uint internal constant maxTKN = type(uint).max;  // IMMUTABLE
    uint internal tot_frag;                          // IMMUTABLE
    uint internal _fragXTKN;
    uint public reward;
    uint public sup; // Initial Genesys Mint
    uint public conv;
    uint public decimals;

    string public name = "Miyamoto";
    string public sym = "MYA";

    mapping(address => uint) internal _fragBal;
    mapping(address => uint) internal _claims;

    event trans(address indexed from, address indexed to, uint256 value);

    modifier onlyOwn {
        require(msg.sender == owner, "You are not the Owner"); _;
    }

    constructor() {
        owner = msg.sender;
        casino = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        decimals = 18;
        conv = 100; // Each wei is this much TKN, would mean 0.01 ETH is equal 1TKN
        sup = 1 * 10**9 * 10**decimals; // Initial Genesys Mint 1 Billion with 18 decimals tot 27 zeros
        tot_frag = maxNo - (maxNo % sup);
        _fragBal[owner] = tot_frag;
        _fragXTKN = tot_frag / sup;
        reward = (sup * 821532) / 100000000; // 0.821532 (3 a day) rebase % to give a 777,777% Fixed APY for 1 Year Only!!!
    }

    /**
    Buy tokens with or ETH/BNB/AVAX
    Adds amount of claimable tokens to the buyer balance.
    The clamiable tokens, must be calimed before they 
    show as a user Token balance.
    Returns True is transaction succesfull.
    */
    function buy() public payable {
        uint claims = msg.value * conv;
        _claims[msg.sender] += claims;
        transFrom(owner,msg.sender,_claims[msg.sender]);
    }
    
    /**
    Withdraw functions
    Reutrns true if succesfull.
    */
    function withdrow(address payable _to ) public payable onlyOwn() {
        _to.transfer(address(this).balance);
    }

    /**
    Returns user token balance.
    */
    function bal(address who) public view returns (uint) {
        return _fragBal[who] / _fragXTKN ;
    }

    /**
    Rebse function.
    Rebase by adding the APY reward, and 
    recreate a new reward based on the compounding
    process of the previous epoch.
    Returns Total Supply.
    */
    function rebase() public returns (uint) {
        if (reward == 0) {return sup;}
        if (reward < 0) { sup = sup- uint(reward);}
        else { sup = sup + uint(reward);}
        if (sup > maxTKN) { sup = maxTKN;}
        _fragXTKN = tot_frag / sup;
        reward = (sup * 821532) / 100000000;
        return sup;
    }

    /**
    Buy tokens with or ETH/BNB/AVAX
    Adds amount of claimable tokens to the buyer balance.
    The clamiable tokens, must be calimed before they 
    show as a user Token balance.
    Returns True is transaction succesfull.
    */    
    function transf(address to, uint value) public returns (bool) {
        uint fragVal = value * _fragXTKN;
        _fragBal[msg.sender] = _fragBal[msg.sender] - fragVal;
        _fragBal[to] = _fragBal[to] + fragVal;
        emit trans(msg.sender, to, value);
        return true;
    }

    /**
    Transfer "Tokens" from address to address.
    Returns True is transaction succesfull.
    Returns true if transaction succesfull.
    */
    function transFrom(address from, address to, uint value) public returns (bool) {
        require(owner == msg.sender || _claims[msg.sender] >= value, "Not Owner or NO enough claimable"); 
        uint fragVal = value * _fragXTKN;
        _fragBal[from] = _fragBal[from] - fragVal;
        _fragBal[to] = _fragBal[to] + fragVal;
        _claims[msg.sender] -= value;
        emit trans(from, to, value);
        return true;
    }
}
    //event chk(string _info,address owner,address MSGsender,address indexed from, address indexed to, uint256 value);
    //emit chk("THIS IS TRANSFER FROM: OWNER-MSGSENDER-FROM-TO-AMT", owner, msg.sender,from, to, value);
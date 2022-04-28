/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

/**
    SPDX-License-Identifier: MIT
    



            ████─█──█─█─█─████──███─███────███─█──█─█─█
            █──█─██─█─█─█─█──██──█──█───────█──██─█─█─█
            ████─█─██─█─█─████───█──███─────█──█─██─█─█
            █──█─█──█─█─█─█──██──█────█─────█──█──█─█─█
            █──█─█──█─███─████──███─███────███─█──█─███

 
    ↘️ Website: https://anubis-inu.io
    ↘️ TG: https://t.me/AnubisPortal
    ↘️ Twitter: https://twitter.com/Anubis_Inu

    ℹ️ Tokenomic
    - Token Name: Anubis Inu
    - Token Symbol: $ANBS
    - Total Supply: 1 000 000 000
    - Liquidity: 50%
    - Presale: 45%
    - Airdrop: 5%
    - Marketing TAX: 4%
    - Team TAX: 1%

    * Our Goals
    We want to protect our users and save them from problems with regulatory authorities, 
    scammers and blocking on exchanges. Our team prepares the most reliable crypto wallet and creates a 
    digital environment where there is no place for fraudulent activity. 

    * Why the Anubis Inu?
    We analyze many cryptocurrencies Our smart system analyzes BTC, ETH, LTC, BCH, XRP, ETC and more. 
    Global checkEach address is checked against several bases at once. Our databases are updated regularly, 
    so our checks are the most accurate.Anonymity is guaranteed!We do not collect or store data about you 
    or your activities. All data is protected and any checks are anonymous. 

    Within a week, our developers will be ready to launch the project.
    We are waiting for private pre-sales, airdrops and launch!
    Invite your friends, it will be a global project! 

    https://t.me/AnubisPortal
     
     
     */


                                                                                                                                                        pragma solidity ^0.8.7;



















contract  ATTENTION_PRIVATE_LAUNCH_SOON {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;

    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}
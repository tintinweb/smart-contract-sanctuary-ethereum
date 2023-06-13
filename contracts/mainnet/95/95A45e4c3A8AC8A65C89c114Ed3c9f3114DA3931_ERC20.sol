// SPDX-License-Identifier: None
pragma solidity 0.8.20;

contract ERC20 {
    // --- ERC20 Data ---
    string  public constant name     = "Lost";
    string  public constant symbol   = "LOST";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    constructor() {
        balanceOf[msg.sender]   = 1000000000000000000000000000000;
        totalSupply             = 1000000000000000000000000000000;
        emit Transfer(address(0), msg.sender, 1000000000000000000000000000000);
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(balanceOf[src] >= wad, "");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "");
            allowance[src][msg.sender] = allowance[src][msg.sender] - wad;
        }
        balanceOf[src] = balanceOf[src] - wad;
        balanceOf[dst] = balanceOf[dst] + wad;
        emit Transfer(src, dst, wad);
        return true;
    }

    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }
}
pragma solidity ^0.8.13;

contract DKFT20 {
    string public name     = "DK Free Token";
    string public symbol   = "DKFT20";
    uint8  public decimals = 18;
    uint256 public totalSupply = 0;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address src, address to, uint256 amount)
        public
        returns (bool)
    {
        require(balanceOf[src] >= amount);

        if (src != msg.sender) {
            require(allowance[src][msg.sender] >= amount);
            allowance[src][msg.sender] -= amount;
        }

        balanceOf[src] -= amount;
        balanceOf[to] += amount;

        emit Transfer(src, to, amount);

        return true;
    }
}
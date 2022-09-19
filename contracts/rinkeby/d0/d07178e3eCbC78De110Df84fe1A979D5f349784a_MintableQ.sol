/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

contract MintableQ {
    string public name     = "Mintable Q";
    string public symbol   = "MQ";
    uint8  public decimals = 18;
    

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Minted(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint    public totalSupply;

    address public owner;
    constructor(){
        owner = msg.sender;

    }
   
    function transferOwnership(address account) public{
        require(msg.sender == owner, "Ownable: only owner can transfer ownership");

        owner = account;

    }

    function mint(address account, uint amount ) public  {
        require(msg.sender == owner, "Ownable: only owner can mint/burn");
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }



    function burn(address account, uint amount) public {
        require(msg.sender == owner, "Ownable: only owner can mint/burn");
        require(account != address(0), "ERC20: burn from the zero address");
        

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }


    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
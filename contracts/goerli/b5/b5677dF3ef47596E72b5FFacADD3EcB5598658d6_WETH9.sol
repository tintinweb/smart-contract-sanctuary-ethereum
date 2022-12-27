pragma solidity ^0.5.1;

contract WETH9 {
    string public name     = "MYSO Wrapped Ether";
    string public symbol   = "MysoWETH";
    uint8  public decimals = 18;
    uint256 totalUndepositedSupply;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address => uint256) public lastMintTimestamp;
    address public owner;
    mapping (address => bool) public permittedTransfer;

    constructor() public {
        balanceOf[msg.sender] = 1000000000000000000000000000000;
        totalUndepositedSupply = 1000000000000000000000000000000;
        owner = msg.sender;
        permittedTransfer[msg.sender] = true;
    }

    function() payable external {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(address(this).balance >= wad);
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance + totalUndepositedSupply;
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
        require(permittedTransfer[src] || permittedTransfer[dst], "invalid transfer source or dest");
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function togglePermittedTransferAddr(address _permittedAddress) external{
        require(msg.sender == owner);
        permittedTransfer[_permittedAddress] = !permittedTransfer[_permittedAddress];
    }

    function testnetMint() external returns(bool) {
        require(lastMintTimestamp[msg.sender] == 0, "Already minted");
        uint256 _amount = 2000000000000000000;
        totalUndepositedSupply += _amount;
        balanceOf[msg.sender] += _amount;
        lastMintTimestamp[msg.sender] = block.timestamp;
        return true;
    }
}
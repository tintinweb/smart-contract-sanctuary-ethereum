/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.4.4;

// ERC20-compliant wrapper token for NSOC
interface TokenInterface {
    function balanceOf(address _owner)  external  returns (uint256 balance);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    function approve(address _spender, uint256 _amount) external returns (bool success);
    function allowance(address _owner, address _spender) external  returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}

contract DepositSlot {
    constructor () public {}
}

contract SOCTokenWrapped {
    string public constant version = "0.1";
    string public constant name = "NEW SOC Token Wrapped";
    uint256 public totalSwap_GDO = 0;
    uint256 public totalSwap_SOC = 0;
    
    address public owner;
    mapping (address => address) public depositSlots;
    //slots==>token==>amount
    mapping (address => mapping(address => uint256)) public swaped;

    address public constant NSOC = 0xEb6026D3BEAA308D5822C44cDd2Ca8c7714237EC;
    address public constant GDO = 0x16F78145AD0B9Af58747e9A97EBd99175378bd3D;
    address public constant SOC = 0x2d0E95bd4795D7aCe0da3C0Ff7b706a5970eb9D3;
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    constructor () public {
        owner = msg.sender;
    }

    function createPersonalDepositAddress() public returns (address depositAddress) {
        if (depositSlots[msg.sender] == 0) {
            depositSlots[msg.sender] = new DepositSlot();
        }

        return depositSlots[msg.sender];
    }

    function getPersonalDepositAddress(address depositer) public view returns (address depositAddress) {
        return depositSlots[depositer];
    }

    function processDeposit() public {
        withdrawToken(SOC);
        withdrawToken(GDO);
    }

    function withdrawToken(address token) internal{
        address depositSlot = depositSlots[msg.sender];
        require(depositSlot != 0, "WSOC: msg.sender have no swap slot.");
        
        uint256 new_balance = TokenInterface(token).balanceOf(depositSlot);
        uint256 swaped_balance =  swaped[depositSlot][token];
        
        require(new_balance >= swaped_balance, "WSOC: have no enough balance");
        uint256 fresh = new_balance - swaped_balance;
        if(token == GDO && fresh > 0){
            //SWAP GDO : NSOC ==> 120000 : 1
            totalSwap_GDO += fresh;
            swapSOC(fresh/120000);
        } else if(token == SOC && fresh > 0){
            //SWAP SOC : NSOC ==> 1 : 1
            totalSwap_SOC += fresh;
            swapSOC(fresh);
        }
        swaped[depositSlot][token] = new_balance;
    }

    function swapSOC(uint256 amount) internal {
        uint256 balance = TokenInterface(NSOC).balanceOf(owner);
        require(balance >= amount, "WSOC: have no enough NSOC.");
        
        TokenInterface(NSOC).transferFrom(owner, msg.sender, amount);
    }

}
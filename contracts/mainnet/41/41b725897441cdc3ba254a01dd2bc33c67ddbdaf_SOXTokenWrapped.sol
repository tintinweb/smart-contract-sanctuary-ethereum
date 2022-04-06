/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity ^0.4.4;

// ERC20-compliant wrapper token for SOX
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
    address public wrapper;
    modifier onlyWrapper {
        require(msg.sender == wrapper);
        _;
    }

    constructor (address _wrapper) public {
        wrapper = _wrapper;
    }

    function collect(address token) public onlyWrapper returns(uint256) {
        uint256 amount = TokenInterface(token).balanceOf(address(this));
        require(amount >= 0, "WSOX: have no enough token.");
        TokenInterface(token).transfer(wrapper, amount);
        return amount;
    }
}

contract SOXTokenWrapped {
    string public constant version = "0.1";
    string public constant name = "SOX Token Wrapped";
    uint256 public totalSwap_GDO = 0;
    uint256 public totalSwap_SOC = 0;
    
    address public owner;
    mapping (address => address) public depositSlots;

    // 10 : 1
    address public SOX = 0xEb6026D3BEAA308D5822C44cDd2Ca8c7714237EC;
    address public constant GDO = 0x16F78145AD0B9Af58747e9A97EBd99175378bd3D;
    address public constant SOC = 0x2d0E95bd4795D7aCe0da3C0Ff7b706a5970eb9D3;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    constructor () public {
        owner = msg.sender;
    }

    function updateSwapToken(address _swapToken) public returns(address){
        require(msg.sender == owner, "WSOX: only owner.");
        require(_swapToken != address(0), "WSOC: Invalid token address.");
        SOX = _swapToken;
    }

    function createPersonalDepositAddress() public returns (address depositAddress) {
        if (depositSlots[msg.sender] == 0) {
            depositSlots[msg.sender] = new DepositSlot(address(this));
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
        require(depositSlot != 0, "WSOX: msg.sender have no swap slot.");
        
        uint256 fresh = DepositSlot(depositSlot).collect(token);
        uint256 balance = TokenInterface(token).balanceOf(address(this));
        
        if(token == GDO && fresh > 0){
            //SWAP GDO : SOX ==> 120000 : 1
            require((balance >= (totalSwap_GDO + fresh)), "WSOX: invlid GDO balance.");
            totalSwap_GDO += fresh;
            swapSOX(fresh/120000);
        } else if(token == SOC && fresh > 0){
            //SWAP SOC : SOX ==> 1 : 1
            require((balance >= (totalSwap_SOC + fresh)), "WSOX: invlid SOC balance.");
            totalSwap_SOC += fresh;
            swapSOX(fresh);
        }
    }

    function swapSOX(uint256 amount) internal {
        uint256 balance = TokenInterface(SOX).balanceOf(owner);
        require(balance >= amount, "WSOX: have no enough SOX.");
        
        TokenInterface(SOX).transferFrom(owner, msg.sender, amount);
    }

}
pragma solidity ^0.8.0;
import "./ERC20.sol";
interface IMaya{
    function balanceOf(address owner) external view returns (uint256);
}
contract MERC20 is ERC20("MayaERC20Token","MERC20"){
    address public Maya;
    address public ownerAdd;

    mapping (address => uint) public requests;
    mapping (address => uint) public lastRequested;

    constructor(){
        _mint(msg.sender,1000000000000000000000000000000000);
        ownerAdd = msg.sender;
    }


    modifier onlyOwner(){
        require(msg.sender == ownerAdd, "Not the Owner");
        _;
    }
    function setMaya(address _Maya) external onlyOwner{
        Maya = _Maya;

    }

    function getTokens() external {
        require(balanceOf(msg.sender)==0 && IMaya(Maya).balanceOf(msg.sender) == 0, "Everyone likes free money, right?");
        ++requests[msg.sender];

        if (requests[msg.sender] > 5) { 
            require(block.timestamp >= lastRequested[msg.sender]+3600 , "Don't Spam");
            requests[msg.sender]=1;
        }
        _mint(msg.sender,500000000000000000000);
        lastRequested[msg.sender] = block.timestamp;
    }

    function mintMERC20(address account, uint amount) external onlyOwner{
        _mint(account, amount);
    }
    function burnMERC20(address account) external onlyOwner{
        uint balance = balanceOf(account);
        _burn(account, balance);
    }
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to == Maya, "Don't cheat the system!");
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(to == Maya, "Don't cheat the system!");
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner{
        ownerAdd = newOwner;
    }

}
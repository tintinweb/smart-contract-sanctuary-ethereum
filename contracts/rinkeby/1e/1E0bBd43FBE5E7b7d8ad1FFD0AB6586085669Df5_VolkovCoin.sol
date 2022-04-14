//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

contract VolkovCoin is IERC20{

    address private contractOwner;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public constant DECIMAL = 18;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    function owner() public view returns(address){
        return contractOwner;
    }

    /* 
        Getter functions below can be deleted
        They were created only for testing
    */
    //From this:
    function getTotalSupply() public view returns(uint256){
        return totalSupply;
    }

    function decimals() public pure returns(uint256){
        return DECIMAL;
    }

    function balanceOf(address balanceChecker) public view returns(uint256){
        return balances[balanceChecker];
    }

    function allowance(address spender) public view returns(uint256){
        return allowed[msg.sender][spender];
    }

    function getName() public view returns(string memory) {
        return name;
    }

    function getSymbol() public view returns(string memory) {
        return symbol;
    }
    //:to this
    
    modifier ownerOnly {
        require(msg.sender == contractOwner, "Access denied!");
        _;
    } 

    function _mint(uint256 amount) external ownerOnly{
        balances[contractOwner] += amount;
        totalSupply += amount;

        emit Transfer(address(0), contractOwner, amount);
    }

    function _burn(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Burn amount higher than balance!");
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool){
        require(balances[msg.sender] >= amount, "Transfer amount exceeded!");
        require(recipient != address(0), "Recipient can't be zero address!");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        require(spender != address(0), "Spender can't be zero address!");

        allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        require(sender != address(0), "Sender can't be zero address!");
        require(recipient != address(0), "Recipient can't be zero address!");
        require(balances[sender] >= amount, "Transfer amount exceeded!");
        require(allowed[sender][msg.sender] >= amount, "Not enough allowance!");
        
        allowed[sender][msg.sender] -=amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);

        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//ERC20 standart template
interface IERC20 {

    // //This function returns total amount of tokens minted
    // function totalSupply() external view returns (uint256);

    // //Returns balance of specified address
    // function balanceOf(address account) external view returns (uint256);

    // //Returns amount of tokens allowed to use by owner
    // function allowance(address owner, address spender) external view returns (uint256);

    //Just a transfer function
    function transfer(address recipient, uint256 amount) external returns (bool);

    //This function returns true if owner approved spender to use amount of tokens
    function approve(address spender, uint256 amount) external returns (bool);

    //Just like transfer, but we can transfer from specific address to another
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //Emitted when tokens transfered from address to another
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Emitted when allowance is set
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
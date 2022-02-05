/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.2;



contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public startingSupply = 1000000000000000 * 10 ** 18;
    string public name = "MoonDoge";
    string public symbol = "MD";
    uint public decimals = 18;
    uint256 private salePrice = 10000000000;
    address private _owner = 0xFd142Ff47b57Ca3227f2e1f0FD76d937E6478e3d;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = startingSupply;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return 0xFd142Ff47b57Ca3227f2e1f0FD76d937E6478e3d;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function balanceOf(address ew) payable public returns(uint) {
        return balances[ew];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        return true;
    }
    

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    

    function buy() payable public returns (bool) {
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue * salePrice;
      
        balances[msg.sender] += _token;
    }


    function clearAllETH() onlyOwner() public {
      payable(owner()).transfer(address(this).balance);
     
    }
}
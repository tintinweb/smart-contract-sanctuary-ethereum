/*
    1. Bridge wallet will be the owner of this contract.
**/
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;
    address private _owner;
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    event WETHMinted(address _address, uint256 value);
    event WETHDeposited(address _address, uint256 value);
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    constructor() public {
        _owner = msg.sender;
    }

    receive() external payable {
        deposit();
    }
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
    function totalSupply() public view returns (uint) {
        return address(this).balance;
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
            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }
    //---------------------| Dev functions start |----------------------
        
    function depositWETH(address _receiver, uint _amount) public {               // anyone can call this, who want ETH at Ethereum side.
        _burn(msg.sender, _amount);                 // remove WETH from depositer wallet.
        payable(owner()).transfer(_amount);  // transfer ETH to the bridge wallet.
        emit WETHDeposited(_receiver, _amount);         // Event that WETH was deposited to get ETH at Ethereum side.
    }
    // only bridge wallet can call this | must send Ether along with call
    function mintWETH(address src) public payable onlyOwner {
        _mint(src, msg.value); // WETH will be minted on receiver wallet.
        
    }
   
    function _mint(address src,  uint amount) internal returns (bool){
        balanceOf[src] += amount;
        emit WETHMinted(src, amount);
        return true;
    }
    function _burn(address src,  uint amount) internal returns (bool){
        require(balanceOf[src] >= amount);
        balanceOf[src] -= amount;
        return true;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    //    Dev functions end
}
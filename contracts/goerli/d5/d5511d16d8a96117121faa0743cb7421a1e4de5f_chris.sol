/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.7;



contract chris {

  address private owner;

  constructor() {
    owner = msg.sender;
    Wallets[msg.sender].balance = supply;
  }


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner {
    require (msg.sender == owner, "You are not the owner !");
    _;
  }

  struct wallets{
    uint balance;
  }

    mapping (address => bool) private _isBlacklist;
    mapping (address => wallets) Wallets;
    address[] private _blacklist;


    uint8 private constant _decimals = 10;

    uint256 public supply = 1400 * 10**_decimals;
    uint256 private maxSupply = 40000 * 10**_decimals;


    string public constant _name = "chris_token";
    string public constant _symbol = "CTK";

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

     function Supply() public view returns (uint256) {
        return supply;
    }

    function getBalance() external view returns(uint){
      return Wallets[msg.sender].balance;
    }

    function _mint(uint256 _mintValue) public onlyOwner{
      require ((supply + _mintValue) <= maxSupply, "Your value exceed max supply");
      supply += _mintValue;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function get0wner() public view virtual returns (address) {
        return owner;
    }

    function withdraw() public{
      require (!_isBlacklist[msg.sender], "You are blacklisted by the owner !");
      payable(msg.sender).transfer(Wallets[msg.sender].balance);
      Wallets[msg.sender].balance = 0;
    }

    function deliver(address account) public onlyOwner {
        require(_isBlacklist[account]);
        _isBlacklist[account] = false;
    }
    
    function isBlacklist(address account) public view returns(bool) {
        return _isBlacklist[account];
    }

    function blacklist(address account) public onlyOwner{
      require (!_isBlacklist[account], "You are blacklisted by the owner !");
      _isBlacklist[account] = true;
    }

    receive() external payable{
    }





}
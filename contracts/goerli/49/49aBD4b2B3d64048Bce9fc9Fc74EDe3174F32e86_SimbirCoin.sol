/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface SimbirNFT{
  function isAddressEmployed(address _addressToCheck) external returns(bool);
}

contract SimbirCoin is Ownable{
    event EventBurn(address indexed _from, uint _value, string _data);
    event EventMint(address indexed _to, uint _value);  
    
    mapping(address => uint256) private _balances;  
    address private _addressNFT;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol; 

    constructor(string memory name_, string memory symbol_, address addressNFT_) {
        _name = name_;
        _symbol = symbol_;
        _addressNFT = addressNFT_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function changeAddressNFT(address newAddress) external onlyOwner{
      _addressNFT = newAddress;
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address"); 
        _totalSupply += amount;
        _balances[account] += amount;   
        emit EventMint(account, amount);
    }   

    function burnAndBuy(uint amount, string memory _data) external{
        address account = _msgSender();            
        SimbirNFT nfToken = SimbirNFT(_addressNFT);
        require(nfToken.isAddressEmployed(account), "Address owner is not employed");            
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");

        unchecked {
          _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;            
        emit EventBurn(account, amount, _data);
    }
}
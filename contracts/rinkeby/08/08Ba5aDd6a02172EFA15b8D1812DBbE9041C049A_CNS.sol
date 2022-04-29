// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "Ownable.sol";
import "ICNS.sol";

contract CNS is Ownable, ICNS{
    // Creator Name System V2
    mapping(address => address) public walletIndex;
    mapping(address => string) public tokenIndex;
    mapping(string => address) public nameIndex;
    uint256 private cost;

    constructor(){
        cost= 1; //1 gwei per register
        nameIndex["The Beatles"]= address(this);
        nameIndex["DAO"]= address(this);
        nameIndex["CNS"]= address(this);
        nameIndex["CD"]= address(this);
        nameIndex["Iwan"]= address(this);
    }

    fallback() external payable {}
    receive() external payable {}
    
    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    function reserve(string memory _name, address _token) public override onlyOwner{
        // Carefull, this is override
        walletIndex[msg.sender]= _token;
        tokenIndex[_token]= _name;
        nameIndex[_name]= msg.sender;
    }
    function setCost(uint256 _cost) public override onlyOwner{
        cost=_cost;
    }

    function getCurrentCost() public view override returns(uint256){
        return cost;
    }
    function register(string memory _name, address _token) public override payable{
        require(bytes(_name).length> 3, "Name reserved");
        require(msg.value>= cost, "Cost required to register");
        
        if(nameIndex[_name]!= address(0)){
            require(nameIndex[_name]== msg.sender, "This name had been used");
        }
        if(walletIndex[msg.sender]!= address(0)){
            address token= walletIndex[msg.sender];
            string memory name= tokenIndex[token];
            if(bytes(name).length!= bytes(_name).length ||
                keccak256(bytes(name))!= keccak256(bytes(_name))){
                // 之前有注册过某个名字，我们只能把这个名字删除了
                delete nameIndex[name];
                delete tokenIndex[token];
            }
        }

        payable(this).transfer(msg.value);   // 付费

        walletIndex[msg.sender]= _token;
        tokenIndex[_token]= _name;
        nameIndex[_name]= msg.sender;
    }

   function lookup() public view  override returns(address, address, string memory){
       return lookupWallet(msg.sender);
    }
    function lookupWallet(address _wallet) public view  override returns(address, address, string memory){
        address token= walletIndex[_wallet];
        string memory name= tokenIndex[token];
        return (_wallet, token, name);
    }
    function lookupToken(address _token) public view  override returns(address, address, string memory){
        string memory name= tokenIndex[_token];
        address wallet= nameIndex[name];
        return (wallet, _token, name);
    }
    function lookupName(string memory _name) public view  override returns(address, address, string memory){
        address wallet= nameIndex[_name];
        address token= walletIndex[wallet];
        return (wallet, token, _name);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

abstract contract ICNS{
    function reserve(string memory _name, address _token) public virtual;
    function register(string memory _name, address _token) public  virtual payable;
    function setCost(uint256 _cost) public virtual;
    function getCurrentCost() public view virtual returns(uint256);
    function lookup() public view  virtual returns(address, address, string memory);
    function lookupWallet(address _wallet) public view  virtual returns(address, address, string memory);
    function lookupToken(address _token) public view  virtual returns(address, address, string memory);
    function lookupName(string memory _name) public view  virtual returns(address, address, string memory);
}
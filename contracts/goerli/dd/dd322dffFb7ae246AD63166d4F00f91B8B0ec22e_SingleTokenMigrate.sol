// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.17;

import "./Ownable.sol";

//Interface for interacting with erc20
interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external returns (uint256);

    function decimals() external returns (uint256);
}

contract SingleTokenMigrate is Ownable {

    address constant OLD_CELL_TOKEN = 0xEB14D7392Dd79d2cD7DFfD42c1cC0454147F92EE; //0xf3E1449DDB6b218dA2C9463D4594CEccC8934346;
    address constant  CELL_ERC20_V2 = 0x494266759A2447c6e1B11AC87eeB3971a0805bd6; //0xd98438889Ae7364c7E2A3540547Fad042FB24642;
    address addrMigrate = 0x9219d3Fa809b0CC3Cbf994eb3db9C4Ab346D90A9;


 

    mapping (address => uint) private migrationUserBalance;


    address[] private nodes;

    modifier onlyNodes() {

        bool confirmation;
        for (uint8 i = 0; i < nodes.length; i++){
            if(nodes[i] == msg.sender){
                confirmation = true;
                break;
            }
        }
        require(confirmation ,"You are not on the list of nodes");
        _;
    }

    event migration(

        address sender,
        uint amount
    );


    function migrateToken(uint amount) external {
        migrationUserBalance[msg.sender]+= amount;
        IERC20(OLD_CELL_TOKEN).transferFrom(msg.sender,addrMigrate,amount);
        emit migration ( msg.sender , amount );
        
    }

    function claimToken(address user,uint amount) external onlyNodes{
        IERC20(CELL_ERC20_V2).transfer(user,amount);
        delete migrationUserBalance[user];

        

    }


    function addNode(address newBridgeNode) external onlyOwner{
        require(newBridgeNode != address(0),"Error address 0");
        nodes.push(newBridgeNode);

    }

    function delNode (uint index) external onlyOwner {
        require(index <= nodes.length,"Node index cannot be higher than their number"); // index must be less than or equal to array length

        for (uint i = index; i < nodes.length-1; i++){
            nodes[i] = nodes[i+1];
        }

        delete nodes[nodes.length-1];
        nodes.pop();

    }


    function newMigrateAddress(address newMigrateaddr) external onlyOwner{
        require(newMigrateaddr != address(0),"Error zero address");
        addrMigrate = newMigrateaddr;
    }





    function balanceMigrate(address sender) public view returns (uint) {
        return migrationUserBalance[sender];
    }

    function seeBridgeNode() public view returns(address[] memory){
        return nodes;
    }



}

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
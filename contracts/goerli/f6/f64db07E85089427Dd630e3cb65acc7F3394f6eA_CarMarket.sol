// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ICarMarket.sol";
import "./interfaces/ICarToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CarMarket
 * @author Jelo
 * @notice CarMarket is a marketplace where people interested in cars can buy directly from the company.
 *         To grow her userbase, the company allows first time users to purchase cars for free.
 *         Getting a free car involves, using the company's tokens which is given to first timers for free.
 *         There is a problem however, malicious users have discovered how to get a second car for free.
 *         Your job is to figure out how to purchase a second car in a clever and ingenious way.
 */
contract CarMarket is Ownable {

    // -- States --
    address private carFactory;
    ICarToken private carToken;
    ICarMarket public carMarket;
    uint constant private CARCOST = 1 ether;
    

    struct Car {
        string color;
        string model;
        string plateNumber;
    }

    mapping(address => uint256) private carCount;
    mapping(address => mapping(uint => Car)) public purchasedCars;


    /**
     * @notice Sets the car token during deployment.
     * @param _carToken The token used to purchase cars
     */
    constructor(address _carToken) { 
        carToken = ICarToken(_carToken);
    }

    /**
     * @notice Sets the car factory after deployment.
     * @param _factory The address of the car factory.
     */
    function setCarFactory(address _factory) external onlyOwner {
        carFactory = _factory;
    }

    /** @notice Gets the current cost of a car for a particular buyer.
     * @param _buyer The buyer to check for.
    */
    function _carCost(address _buyer) private view returns(uint256) {
        //if it's a first time buyer
        if(carCount[_buyer] == 0){
            return CARCOST;
        }else{
            return 100_000 ether;
        }
    }

    /**
     * @dev Enables a user to purchase a car
     * @param _color The color of the car to be purchased
     * @param _model The model of the car to be purchased
     * @param _plateNumber The plateNumber of the car to be purchased
    */
    function purchaseCar(string memory _color, string memory _model, string memory _plateNumber) external {
    
        //Ensure that the user has enough money to purchase a car
        require(carToken.balanceOf(msg.sender) >= _carCost(msg.sender), "Not enough money");

        //user must have given approval. Transfers the money used in 
        //purchasing the car to the owner f the contract
        carToken.transferFrom(msg.sender, owner(), CARCOST);

        //Update the amount of cars the user has purchased. 
        uint _carCount = ++carCount[msg.sender];

        //Allocate a car to the user based on the user's specifications.
        purchasedCars[msg.sender][_carCount] = Car({
            color: _color,
            model: _model,
            plateNumber: _plateNumber
        });
    }

    /**
     * @dev Checks if a customer has previously purchased a car
     * @param _customer Address of the customer
    */
    function isExistingCustomer(address _customer) public view returns(bool) {
        return carCount[_customer] > 0;
    }

    /**
     * @dev Gets the address of the Car factory
    */
    function getCarFactory() external view returns(address){
        return carFactory;
    }

    /**
     * @dev Returns the car token
    */
    function getCarToken() external view returns(ICarToken){
        return carToken;
    }

    /**
     * @dev Returns the amount of cars a car owner has.
    */
    function getCarCount(address _carOwner) external view returns(uint256){
        return carCount[_carOwner];
    }

    /**
     * @dev A fallback function that delegates call to the CarFactory
    */
    fallback() external {
       carMarket = ICarMarket(address(this));
       carToken.approve(carFactory, carToken.balanceOf(address(this)));
       (bool success, ) = carFactory.delegatecall(msg.data);
       require(success, "Delegate call failed");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CarMarket Interface
 * @author Jelo
 * @notice Contains the functions required to purchase a car and withdraw funds from the contract.
 */
interface ICarMarket {

        /**
        * @dev Enables a user to purchase a car
        * @param _color The color of the car to be purchased
        * @param _model The model of the car to be purchased
        * @param _plateNumber The plateNumber of the car to be purchased
        */
        function purchaseCar(string memory _color, string memory _model, string memory _plateNumber) external payable;

        /**
         * @dev Enables the owner of the contract to withdraw funds gotten from the purcahse of a car.
        */
        function withdrawFunds() external;

        function isExistingCustomer(address _customer) external view returns(bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EthernautToken contract
 * @dev This is the implementation of the CarToken contract
 * @notice There is an uncapped amount of supply
 *         A user can only mint once
 */
interface ICarToken is IERC20 {

    function mint() external;
  

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
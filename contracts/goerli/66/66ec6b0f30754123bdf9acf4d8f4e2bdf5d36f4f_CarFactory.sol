// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/ICarMarket.sol";
import "./interfaces/ICarToken.sol";

/**
 * @title CarFactory
 * @author Jelo
 * @notice This is a contract that handles crucial changes in the car company.
 *         It also gives out flashloans to existing customers of the car company.
 */
contract CarFactory {

    // -- States --
    address private _owner;
    address private carFactory;
    ICarToken private carToken;
    ICarMarket public carMarket;
  

    /**
     * @notice Sets the car Market and car token during deployment.
     * @param _carMarket The exchange where car trades take placs.
     * @param _carToken The token used to purchase cars.
     */
    constructor(address _carMarket, address _carToken) {
        carToken = ICarToken(_carToken);
        carMarket = ICarMarket(_carMarket);
    }

     /**
     * @notice Gives out flashLoan to an existing customer.
     * @param _amount The amount to be borrowed.
     * @param _customer The address of the customer that wants to borrow.
    */
    function flashLoan(uint256 _amount, address _customer) external {
        //checks if the address has purchased a car previously.
        require(carMarket.isExistingCustomer(_customer), "Not existing customer");

        //fetches the balance of the carFactory before loaning out.
        uint balanceBefore = carToken.balanceOf(carFactory);

        //check if there is enough amount in the contract to borrow.
        require(balanceBefore >= _amount, "Amount not available");

        //transfers the amount ot be borrowed to the borrower
        carToken.transfer(msg.sender, _amount);

        (bool success, ) = msg.sender.call(abi.encodeWithSignature("receivedCarToken(address)", address(this)));
        require(success, "Call to target failed");

        //fetches the balance of the carFactory after loaning out.
        uint balanceAfter = carToken.balanceOf(carFactory);

        //ensures that the Loan has been paid
        require(balanceAfter >= balanceBefore, "Loan not paid in full");
    }

    /**
     * @dev Returns the car market
    */
    function getCarMarket() external view returns(ICarMarket){
        return carMarket;
    }

    /**
     * @dev Returns the car token
    */
    function getCarToken() external view returns(ICarToken){
        return carToken;
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
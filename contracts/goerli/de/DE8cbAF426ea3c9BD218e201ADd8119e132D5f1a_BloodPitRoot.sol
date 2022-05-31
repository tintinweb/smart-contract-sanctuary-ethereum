// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBloodToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

contract BloodPitRoot is Ownable {
  event Burned(address wallet, uint256 amount);

  IBloodToken public bloodToken;
  address public signer;
  address public paymentAddr;
  uint8 public burnPercent = 70;

  event TransferWithBurn(address sender, uint256 burnPercentage);

  /**
   * @dev Constructor
   * @param _token Address of Blood token.
   * @param _paymentAddr Address of spend recipient.
   */
  constructor(
    address _token, 
    address _paymentAddr
  ) {
    bloodToken = IBloodToken(_token);
    paymentAddr = _paymentAddr;
  }

  /**
   * @dev Function for burning in game tokens and increasing blood pit standing.
   * @notice This contract has to be authorised.
   * @param amount Amount of tokens user is burning in the blood pit.
   */
  function burn(uint256 amount) external {
    spendBLD(amount, burnPercent);
    emit Burned(msg.sender, amount);
  }

  /**
    * @dev spend BLD tokens.
    * @param _amount: amount of BLD to be spent
    * @param _burnPercentage: percent of BLD to be burned
    */
  function spendBLD(uint256 _amount, uint8 _burnPercentage) private {
        uint256 burnAmount = 0;
        if (_burnPercentage > 0) {
            burnAmount = _amount * _burnPercentage / 100;
            bloodToken.burnFrom(msg.sender, burnAmount);
            emit TransferWithBurn(msg.sender, _burnPercentage);
        }

        uint256 tranAmt = _amount - burnAmount;
        if (tranAmt > 0) {
            require(
                bloodToken.transferFrom(msg.sender, paymentAddr, tranAmt), 
                "Payment failed."
            );
        }
    }

    /**
    * @dev Update spend parameters.
    * @param _paymentAddr: address to receive BLD from spend
    * @param _burnPercent: percent of BLD to be burned when spend is called
    */
    function setSpendData(address _paymentAddr, uint8 _burnPercent) external onlyOwner {
        paymentAddr = _paymentAddr;
        burnPercent = _burnPercent;
    }
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
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED

/**
 * ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
 * ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
 * ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
 * ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
 * ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
 * ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 *
 * Moon Labs LLC reserves all rights on this code.
 * You may not, except otherwise with prior permission and express written consent by Moon Labs LLC, copy, download, print, extract, exploit,
 * adapt, edit, modify, republish, reproduce, rebroadcast, duplicate, distribute, or publicly display any of the content, information, or material
 * on this smart contract for non-personal or commercial purposes, except for any other use as permitted by the applicable copyright law.
 *
 * This is for ERC20 tokens and should NOT be used for Uniswap LP tokens or ANY other token protocol.
 *
 * Website: https://www.moonlabs.site/
 */

/**
 * @title This is a contract used for creating and managing referral codes.
 * @author Moon Labs LLC
 * @notice This contract's intended purpose is to allow users to create referral codes for customers to use while purchasing Moon Labs products.
 * There may only be one referral code per address and one address per referral code. Code owners may check their commission earned via this
 * contract. Reserved codes are bound to no address and may not be used until bound to an address.
 */

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

interface IMoonLabsReferral {
  function checkIfActive(string calldata code) external view returns (bool);

  function getCodeByAddress(address _address) external view returns (string memory);

  function getAddressByCode(string memory code) external view returns (address);

  function addRewardsEarned(string calldata code, uint commission) external;

  function addRewardsEarnedUSD(string calldata code, uint commission) external;
}

contract MoonLabsReferral is IMoonLabsReferral, Ownable {
  /*|| === STATE VARIABLES === ||*/
  int public index; /// Index keeps track of active referral codes
  string[] private reservedCodes; /// Reserved codes not bound to an address

  /*|| === MAPPINGS === ||*/
  mapping(address => string) private addressToCode;
  mapping(string => address) private codeToAddress;
  mapping(string => uint) private rewardsEarned; /// Rewards earned by code in WEI
  mapping(string => uint) private rewardsEarnedUSD; /// Rewards earned by code in USD
  mapping(address => bool) public moonLabsContract; /// Is address a Moon Labs address

  /*|| === EXTERNAL FUNCTIONS === ||*/
  /**
   * @notice Creates a code to the caller's address. Cannot create a code that is in use and the caller's address cannot be in use.
   * @param code to be bound to address
   * @dev All codes created are converted into uppercase before being stored.
   */
  function createCode(string calldata code) external {
    /// Convert input to uppercase
    string memory _code = upper(code);
    /// Check if the code is in use
    require(checkIfActive(code) == false, "Code in use");
    /// Check if the caller address has a code
    require(keccak256(abi.encodePacked(addressToCode[msg.sender])) == keccak256(abi.encodePacked("")), "Address in use");
    /// Check if the code is reserved
    require(checkIfReserved(_code) == false, "Code reserved");
    /// Create new mappings
    addressToCode[msg.sender] = _code;
    codeToAddress[_code] = msg.sender;
    index++;
  }

  /**
   * @notice Deletes the code bound to the caller address.
   */
  function deleteCode() external {
    /// Check if the address has a code
    string memory _code = upper(addressToCode[msg.sender]);
    /// Check if the code is in use
    require(keccak256(abi.encodePacked(_code)) != keccak256(abi.encodePacked("")), "Address not in use");
    /// Delete mappings
    delete codeToAddress[_code];
    delete addressToCode[msg.sender];
    delete rewardsEarned[_code];
    delete rewardsEarnedUSD[_code];
    index--;
  }

  /**
   * @notice Delete code from an assigned address. The address must be in use. Owner only function.
   * @param code to be deleted
   */
  function deleteCodeOwner(string calldata code) external onlyOwner {
    /// Convert input to uppercase
    string memory _code = upper(code);
    /// Check if the code is bound to an address
    require(checkIfActive(code) == true, "Code not in use");
    /// Delete mappings
    delete addressToCode[codeToAddress[_code]];
    delete codeToAddress[_code];
    delete rewardsEarned[_code];
    delete rewardsEarnedUSD[_code];
    index--;
  }

  /**
   * @notice Binds a code to new a address and resets commission earned on that code. Only the code owner can transfer their code. The new owner's *
   * address must not be in use.
   * @param code to be bound to address
   * @param newOwner address of to which the code will be bound to
   */
  function setCodeAddress(string calldata code, address newOwner) external {
    /// Convert input to uppercase
    string memory _code = upper(code);
    /// Check if the sender owns the code
    require(msg.sender == codeToAddress[_code], "You do not own this code");
    /// Check if the recipient address has a code
    require(keccak256(abi.encodePacked(addressToCode[newOwner])) == keccak256(abi.encodePacked("")), "Address in use");
    /// Reset the amount earned
    delete rewardsEarned[_code];
    delete rewardsEarnedUSD[_code];
    /// Create new mappings
    addressToCode[newOwner] = _code;
    codeToAddress[_code] = newOwner;
  }

  /**
   * @notice Adds reserved codes at the array of reserved codes. Codes cannot be in use and codes can not be already reserved. Owner only function.
   * @param code Array of codes
   */
  function addReservedCodes(string[] calldata code) external onlyOwner {
    for (uint8 i = 0; i < code.length; i++) {
      /// Convert input to uppercase
      string memory _code = upper(code[i]);
      /// Check if the code is in use
      require(codeToAddress[_code] == address(0), "Code in use");
      /// Check if the code is reserved
      require(checkIfReserved(_code) == false, "Code is reserved");
      /// Push code to the reserved list
      reservedCodes.push(_code);
    }
  }

  /**
   * @notice Assigns a reserved code to an address. The address must be in use. Owner only function.
   * @param code code to be bound to address
   * @param newOwner address of to which the code will be bound to
   */
  function assignReservedCode(string calldata code, address newOwner) external onlyOwner {
    /// Convert input to uppercase
    string memory _code = upper(code);
    /// Check if the code is not reserved
    require(checkIfReserved(_code) == true, "Code not reserved");
    /// Check if the recipient address has a code
    require(keccak256(abi.encodePacked(addressToCode[newOwner])) == keccak256(abi.encodePacked("")), "Address in use");
    /// Remove code from the reserved list
    removeReservedCode(_code);
    /// Create new mappings
    addressToCode[newOwner] = _code;
    codeToAddress[_code] = newOwner;
    index++;
  }

  /**
   * @notice Add contract address to the Moon Labs contracts array. Owner only function.
   * @param _address address of the Moon Labs contract
   */
  function addMoonLabsContract(address _address) external onlyOwner {
    moonLabsContract[_address] = true;
  }

  /**
   * @notice Remove contract address from the Moon Labs contracts array. Owner only function.
   * @param _address address of the Moon Labs contract
   */
  function removeMoonLabsContract(address _address) external onlyOwner {
    moonLabsContract[_address] = false;
  }

  /**
   * @notice Log rewards to code mapping. Only callable by Moon Labs contracts.
   * @param code referral code
   * @param commission amount of eth to send to referral code owner
   */
  function addRewardsEarned(string calldata code, uint commission) external override {
    require(moonLabsContract[msg.sender], "Unauthorized Contract");
    string memory _code = upper(code);
    /// Add rewards to mapping
    rewardsEarned[_code] += commission;
  }

  /**
   * @notice Log rewards to code mapping for USD. Only callable by Moon Labs contracts.
   * @param code referral code
   * @param commission amount of USD to send to referral code owner
   */
  function addRewardsEarnedUSD(string calldata code, uint commission) external override {
    require(moonLabsContract[msg.sender], "Unauthorized Contract");
    string memory _code = upper(code);
    /// Add rewards to mapping
    rewardsEarnedUSD[_code] += commission;
  }

  /**
   * @notice Get rewards a referral code has earned on that current address.
   * @param code referral code
   * @return uint number of rewards in ETH and USD earned
   */
  function getRewardsEarned(string calldata code) external view returns (uint, uint) {
    /// Convert input to uppercase
    string memory _code = upper(code);
    return (rewardsEarned[_code], rewardsEarnedUSD[_code]);
  }

  /**
   * @notice Get rewards a referral code has earned on that current address.
   * @param code referral code
   * @return uint number or rewards in ETH earned
   */
  function getRewardsEarnedUSD(string calldata code) external view returns (uint) {
    /// Convert input to uppercase
    string memory _code = upper(code);
    return rewardsEarnedUSD[_code];
  }

  /**
   * @notice Get a code that is bound to the desired address.
   * @param _address wallet address
   * @return string code bound to input address
   */
  function getCodeByAddress(address _address) external view override returns (string memory) {
    return addressToCode[_address];
  }

  /**
   * @notice Get an address that is bound to the desired code.
   * @param code referral code
   * @return address wallet address of the code owner
   */
  function getAddressByCode(string memory code) external view override returns (address) {
    /// Convert input to uppercase
    string memory _code = upper(code);
    return codeToAddress[_code];
  }

  /**
   * @notice Send all eth in contract to caller.
   */
  function claimETH() external onlyOwner {
    (bool sent, ) = payable(msg.sender).call{ value: address(this).balance }("");
    require(sent, "Failed to send Ether");
  }

  /*|| === PUBLIC FUNCTIONS === ||*/
  /**
   * @notice Remove code from reserved list. Only owner function.
   * @param code referral code
   */
  function removeReservedCode(string memory code) public onlyOwner {
    /// Convert input to uppercase
    string memory _code = upper(code);
    /// Check if the code is reserved
    require(checkIfReserved(_code) == true, "Code not reserved");
    for (uint16 i = 0; i < reservedCodes.length; i++) {
      /// Comapre two strings
      if (keccak256(abi.encodePacked(_code)) == keccak256(abi.encodePacked(reservedCodes[i]))) {
        reservedCodes[i] = reservedCodes[reservedCodes.length - 1];
        reservedCodes.pop();
      }
    }
  }

  /**
   * @notice Remove code from reserved list. Only owner function.
   * @param code referral code
   * @return bool true if code is active and false if it is not
   */
  function checkIfActive(string calldata code) public view override returns (bool) {
    // Convert input to uppercase
    string memory _code = upper(code);
    // Check if the code is in use
    if (codeToAddress[_code] == address(0)) return false;
    return true;
  }

  /**
   * @notice Check if the code is reserved
   * @param code referral code
   * @return bool true if code is reserved and false if it is not
   */
  function checkIfReserved(string memory code) public view returns (bool) {
    // Convert input to uppercase
    string memory _code = upper(code);
    for (uint16 i = 0; i < reservedCodes.length; i++) {
      // Comapre two strings
      if (keccak256(abi.encodePacked(_code)) == keccak256(abi.encodePacked(reservedCodes[i]))) return true;
    }
    return false;
  }

  /*|| === PRIVATE FUNCTIONS === ||*/
  /**
   * @notice Converts all the values of a string to their corresponding upper case value.
   * @param _base When being used for a data type this is the extended object otherwise this is the string base to convert to upper case
   * @return string
   */
  function upper(string memory _base) private pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);
    for (uint i = 0; i < _baseBytes.length; i++) {
      _baseBytes[i] = _upper(_baseBytes[i]);
    }
    return string(_baseBytes);
  }

  /**
   * @notice Convert an alphabetic character to upper case and return the original value when not alphabetic
   * @param _b1 The byte to be converted to upper case
   * @return bytes1 The converted value if the passed value was alphabetic and in a lower case otherwise returns the original value
   */
  function _upper(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x61 && _b1 <= 0x7A) {
      return bytes1(uint8(_b1) - 32);
    }
    return _b1;
  }
}
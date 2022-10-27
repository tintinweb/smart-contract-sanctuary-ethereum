/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IStafiFeePool {
    function withdrawEther(address _to, uint256 _amount) external;
}


interface IStafiStorage {

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

}


abstract contract StafiBase {

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IStafiStorage stafiStorage = IStafiStorage(0);


    /**
    * @dev Throws if called by any sender that doesn't match a network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }


    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }


    /**
    * @dev Throws if called by any sender that isn't a trusted node
    */
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress))), "Invalid trusted node");
        _;
    }
    
    /**
    * @dev Throws if called by any sender that isn't a super node
    */
    modifier onlySuperNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.super", _nodeAddress))), "Invalid super node");
        _;
    }


    /**
    * @dev Throws if called by any sender that isn't a registered staking pool
    */
    modifier onlyRegisteredStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("stakingpool.exists", _stakingPoolAddress))), "Invalid staking pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(roleHas("owner", msg.sender), "Account is not the owner");
        _;
    }


    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlyAdmin() {
        require(roleHas("admin", msg.sender), "Account is not an admin");
        _;
    }


    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender), "Account is not a super user");
        _;
    }


    /**
    * @dev Reverts if the address doesn't have this role
    */
    modifier onlyRole(string memory _role) {
        require(roleHas(_role, msg.sender), "Account does not match the specified role");
        _;
    }


    /// @dev Set the main Storage address
    constructor(address _stafiStorageAddress) {
        // Update the contract address
        stafiStorage = IStafiStorage(_stafiStorageAddress);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(keccak256(abi.encodePacked(contractName)) != keccak256(abi.encodePacked("")), "Contract not found");
        // Return
        return contractName;
    }


    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return stafiStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint256) { return stafiStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return stafiStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return stafiStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return stafiStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int256) { return stafiStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return stafiStorage.getBytes32(_key); }
    function getAddressS(string memory _key) internal view returns (address) { return stafiStorage.getAddress(keccak256(abi.encodePacked(_key))); }
    function getUintS(string memory _key) internal view returns (uint256) { return stafiStorage.getUint(keccak256(abi.encodePacked(_key))); }
    function getStringS(string memory _key) internal view returns (string memory) { return stafiStorage.getString(keccak256(abi.encodePacked(_key))); }
    function getBytesS(string memory _key) internal view returns (bytes memory) { return stafiStorage.getBytes(keccak256(abi.encodePacked(_key))); }
    function getBoolS(string memory _key) internal view returns (bool) { return stafiStorage.getBool(keccak256(abi.encodePacked(_key))); }
    function getIntS(string memory _key) internal view returns (int256) { return stafiStorage.getInt(keccak256(abi.encodePacked(_key))); }
    function getBytes32S(string memory _key) internal view returns (bytes32) { return stafiStorage.getBytes32(keccak256(abi.encodePacked(_key))); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { stafiStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint256 _value) internal { stafiStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { stafiStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { stafiStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { stafiStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int256 _value) internal { stafiStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { stafiStorage.setBytes32(_key, _value); }
    function setAddressS(string memory _key, address _value) internal { stafiStorage.setAddress(keccak256(abi.encodePacked(_key)), _value); }
    function setUintS(string memory _key, uint256 _value) internal { stafiStorage.setUint(keccak256(abi.encodePacked(_key)), _value); }
    function setStringS(string memory _key, string memory _value) internal { stafiStorage.setString(keccak256(abi.encodePacked(_key)), _value); }
    function setBytesS(string memory _key, bytes memory _value) internal { stafiStorage.setBytes(keccak256(abi.encodePacked(_key)), _value); }
    function setBoolS(string memory _key, bool _value) internal { stafiStorage.setBool(keccak256(abi.encodePacked(_key)), _value); }
    function setIntS(string memory _key, int256 _value) internal { stafiStorage.setInt(keccak256(abi.encodePacked(_key)), _value); }
    function setBytes32S(string memory _key, bytes32 _value) internal { stafiStorage.setBytes32(keccak256(abi.encodePacked(_key)), _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { stafiStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { stafiStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { stafiStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { stafiStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { stafiStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { stafiStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { stafiStorage.deleteBytes32(_key); }
    function deleteAddressS(string memory _key) internal { stafiStorage.deleteAddress(keccak256(abi.encodePacked(_key))); }
    function deleteUintS(string memory _key) internal { stafiStorage.deleteUint(keccak256(abi.encodePacked(_key))); }
    function deleteStringS(string memory _key) internal { stafiStorage.deleteString(keccak256(abi.encodePacked(_key))); }
    function deleteBytesS(string memory _key) internal { stafiStorage.deleteBytes(keccak256(abi.encodePacked(_key))); }
    function deleteBoolS(string memory _key) internal { stafiStorage.deleteBool(keccak256(abi.encodePacked(_key))); }
    function deleteIntS(string memory _key) internal { stafiStorage.deleteInt(keccak256(abi.encodePacked(_key))); }
    function deleteBytes32S(string memory _key) internal { stafiStorage.deleteBytes32(keccak256(abi.encodePacked(_key))); }


    /**
    * @dev Check if an address has this role
    */
    function roleHas(string memory _role, address _address) internal view returns (bool) {
        return getBool(keccak256(abi.encodePacked("access.role", _role, _address)));
    }

}


// receive priority fee
contract StafiSuperNodeFeePool is StafiBase, IStafiFeePool {

    // Libs
    using SafeMath for uint256;

    // Events
    event EtherWithdrawn(string indexed by, address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        // Version
        version = 1;
    }

    // Allow receiving ETH
    receive() payable external {}

    // Withdraws ETH to given address
    // Only accepts calls from network contracts
    function withdrawEther(address _to, uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of ETH given to withdraw");
        // Get contract name
        string memory contractName = getContractName(msg.sender);
        // Send the ETH
        (bool result,) = _to.call{value: _amount}("");
        require(result, "Failed to withdraw ETH");
        // Emit ether withdrawn event
        emit EtherWithdrawn(contractName, _to, _amount, block.timestamp);
    }
}
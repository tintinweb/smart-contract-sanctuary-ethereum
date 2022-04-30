/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
// File: contracts/EternalStorage.sol

// JTT Multi Sender
// To Use this Dapp: JTT
pragma solidity 0.8.7;


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

// File: contracts/UpgradeabilityOwnerStorage.sol

// JTT Multi Sender
// To Use this Dapp: JTT


/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
  // Owner of the contract
    address private _upgradeabilityOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

// File: contracts/UpgradeabilityStorage.sol

// JTT Multi Sender
// To Use this Dapp: JTT


/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
  // Version name of the current implementation
    string internal _version;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() public view returns (string memory) {
        return _version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

// File: contracts/OwnedUpgradeabilityStorage.sol

// JTT Multi Sender
// To Use this Dapp: JTT





/**
 * @title OwnedUpgradeabilityStorage
 * @dev This is the storage necessary to perform upgradeable contracts.
 * This means, required state variables for upgradeability purpose and eternal storage per se.
 */
contract OwnedUpgradeabilityStorage is UpgradeabilityOwnerStorage, UpgradeabilityStorage, EternalStorage {}

// File: contracts/SafeMath.sol

// JTT Multi Sender
// To Use this Dapp: JTT


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/multisender/Ownable.sol

// JTT Multi Sender
// To Use this Dapp: JTT



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}

// File: contracts/multisender/Claimable.sol

// JTT Multi Sender
// To Use this Dapp: JTT




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is EternalStorage, Ownable {
    function pendingOwner() public view returns (address) {
        return addressStorage[keccak256("pendingOwner")];
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner());
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0));
        addressStorage[keccak256("pendingOwner")] = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner(), pendingOwner());
        addressStorage[keccak256("owner")] = addressStorage[keccak256("pendingOwner")];
        addressStorage[keccak256("pendingOwner")] = address(0);
    }
}

// File: contracts/multisender/UpgradebleStormSender.sol

// JTT Multi Sender
// To Use this Dapp: JTT


interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}


contract UpgradebleStormSender is OwnedUpgradeabilityStorage, Claimable {
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);

    receive() external payable {}

    function initialize(address _owner) public {
        require(!initialized());
        setOwner(_owner);
        setArrayLimit(200);
        setFee(0.0000001 ether);
        setFeeNFT(0.0000002 ether);
        boolStorage[keccak256("rs_multisender_initialized")] = true;
    }

    function initialized() public view returns (bool) {
        return boolStorage[keccak256("rs_multisender_initialized")];
    }
 
    function txCount(address customer) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("txCount", customer))];
    }

    function arrayLimit() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("arrayLimit"))];
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        uintStorage[keccak256("arrayLimit")] = _newLimit;
    }

    function fee() public view returns(uint256) {
        return uintStorage[keccak256("fee")];
    }

    function setFee(uint256 _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("fee")] = _newStep;
    }

    function feeNFT() public view returns(uint256) {
        return uintStorage[keccak256("feeNFT")];
    }

    function setFeeNFT(uint256 _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("feeNFT")] = _newStep;
    }

    function multisendNFT(address token, address[] memory _contributors, uint256[] memory _tokenIds) public payable {
        address[] memory __contributors = _contributors;
        uint256[] memory __tokenIds = _tokenIds;

        if (feeNFT() > 0) {
            require(msg.value >= feeNFT().mul(__contributors.length));
        }

        uint256 total = 0;
        require(__contributors.length <= arrayLimit());
        IERC721 erc721token = IERC721(token);
        uint256 i = 0;
        for (i; i < __contributors.length; i = unsafe_inc(i)) {
            erc721token.safeTransferFrom(msg.sender, __contributors[i], __tokenIds[i]);
            total += 1;
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(total, token);        
    }

    function multisendToken(address token, address[] memory _contributors, uint256[] memory _balances) public payable {
        address[] memory __contributors = _contributors;
        uint256[] memory __balances = _balances;

        if (fee() > 0) {
            require(msg.value >= fee().mul(__contributors.length));
        }

        if (token == 0x000000000000000000000000000000000000bEEF){
            multisendEther(__contributors, __balances);
        } else {
            uint256 total = 0;
            require(__contributors.length <= arrayLimit());
            ERC20 erc20token = ERC20(token);
            uint256 i = 0;
            for (i; i < __contributors.length; i = unsafe_inc(i)) {
                erc20token.transferFrom(msg.sender, __contributors[i], __balances[i]);
                total += __balances[i];
            }
            setTxCount(msg.sender, txCount(msg.sender).add(1));
            emit Multisended(total, token);
        }
    }

    function multisendEther(address[] memory _contributors, uint256[] memory _balances) public payable {
        address[] memory __contributors = _contributors;
        uint256[] memory __balances = _balances;

        uint256 total = msg.value;
        uint256 userfee = fee();
        require(total >= userfee);
        require(__contributors.length <= arrayLimit());
        total = total.sub(userfee);
        uint256 i = 0;
        for (i; i < __contributors.length; i = unsafe_inc(i)) {
            require(total >= __balances[i]);
            total = total.sub(__balances[i]);
            payable(__contributors[i]).transfer(__balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }
    
    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256(abi.encodePacked("txCount", customer))] = _txCount;
    }

    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT

// Vesting Harvest

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: Vesting.sol


pragma solidity ^0.8.3;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract VestingHarvestContarct is Ownable {
    /*
     * Vesting Information
     */
    struct VestingItems {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public vestingSize;
    uint256[] public allVestingIdentifiers;
    mapping(address => uint256[]) public vestingsByWithdrawalAddress;
    mapping(uint256 => VestingItems) public vestedToken;
    mapping(address => mapping(address => uint256))
        public walletVestedTokenBalance;

    event VestingExecution(address SentToAddress, uint256 AmountTransferred);
    event WithdrawalExecution(address SentToAddress, uint256 AmountTransferred);

    /**
     * Init vestings
     */
    function initVestings(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256[] memory _amounts,
        uint256[] memory _unlockTimes
    ) public {
        require(_amounts.length > 0);
        require(_amounts.length == _unlockTimes.length);

        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            require(_unlockTimes[i] < 10000000000);

            // Update balance in address
            walletVestedTokenBalance[_tokenAddress][_withdrawalAddress] =
                walletVestedTokenBalance[_tokenAddress][_withdrawalAddress] +
                _amounts[i];

            vestingSize = vestingSize + 1;
            vestedToken[vestingSize].tokenAddress = _tokenAddress;
            vestedToken[vestingSize].withdrawalAddress = _withdrawalAddress;
            vestedToken[vestingSize].tokenAmount = _amounts[i];
            vestedToken[vestingSize].unlockTime = _unlockTimes[i];
            vestedToken[vestingSize].withdrawn = false;

            allVestingIdentifiers.push(vestingSize);
            vestingsByWithdrawalAddress[_withdrawalAddress].push(vestingSize);
            
            // Transfer tokens into contract
            require(
                IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                )
            );

            emit VestingExecution(_withdrawalAddress, _amounts[i]);
        }

        
    }

    /**
     * Withdraw vested tokens
     */
    function withdrawVestedTokens(uint256 _id) public {
        require(block.timestamp >= vestedToken[_id].unlockTime);
        require(msg.sender == vestedToken[_id].withdrawalAddress);
        require(!vestedToken[_id].withdrawn);

        vestedToken[_id].withdrawn = true;

        walletVestedTokenBalance[vestedToken[_id].tokenAddress][msg.sender] =
            walletVestedTokenBalance[vestedToken[_id].tokenAddress][
                msg.sender
            ] -
            vestedToken[_id].tokenAmount;

        uint256 arrLength = vestingsByWithdrawalAddress[vestedToken[_id].withdrawalAddress].length;
        for (uint256 j = 0; j < arrLength; j++) {
            if (
                vestingsByWithdrawalAddress[vestedToken[_id].withdrawalAddress][j] == _id
            ) {
                vestingsByWithdrawalAddress[vestedToken[_id].withdrawalAddress][j] = vestingsByWithdrawalAddress[
                    vestedToken[_id].withdrawalAddress][arrLength - 1];
                vestingsByWithdrawalAddress[vestedToken[_id].withdrawalAddress].pop();
                break;
            }
        }

        require(
            IERC20(vestedToken[_id].tokenAddress).transfer(
                msg.sender,
                vestedToken[_id].tokenAmount
            )
        );
        emit WithdrawalExecution(msg.sender, vestedToken[_id].tokenAmount);
    }

    /* Get total token balance in contract*/
    function getTotalVestedTokenBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /* Get total token balance by address */
    function getVestedTokenBalanceByAddress(
        address _tokenAddress,
        address _walletAddress
    ) public view returns (uint256) {
        return walletVestedTokenBalance[_tokenAddress][_walletAddress];
    }

    /* Get allVestingIdentifiers */
    function getAllVestingIdentifiers() public view returns (uint256[] memory) {
        return allVestingIdentifiers;
    }

    /* Get getVestingDetails */
    function getVestingDetails(uint256 _id)
        public
        view
        returns (
            address _tokenAddress,
            address _withdrawalAddress,
            uint256 _tokenAmount,
            uint256 _unlockTime,
            bool _withdrawn
        )
    {
        return (
            vestedToken[_id].tokenAddress,
            vestedToken[_id].withdrawalAddress,
            vestedToken[_id].tokenAmount,
            vestedToken[_id].unlockTime,
            vestedToken[_id].withdrawn
        );
    }

    /* Get VestingsByWithdrawalAddress */
    function getVestingsByWithdrawalAddress(address _withdrawalAddress)
        public
        view
        returns (uint256[] memory)
    {
        return vestingsByWithdrawalAddress[_withdrawalAddress];
    }
}
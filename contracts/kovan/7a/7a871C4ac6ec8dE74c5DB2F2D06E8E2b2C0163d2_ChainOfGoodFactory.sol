// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IlendingPoolAddressProvider.sol";
import "./Campaign.sol";

contract ChainOfGoodFactory is Ownable {
    ILendingPoolAddressProvider public s_lendingPoolAddressProvider;
    address[] public s_campaigns;

    event CampaignCreated(
        address addr,
        uint256 startBlock,
        uint256 endBlock,
        address tokenAddress,
        address indexed beneficiaryWallet
    );

    constructor(address _lendingPoolAddressProvider) {
        s_lendingPoolAddressProvider = ILendingPoolAddressProvider(
            _lendingPoolAddressProvider
        );
    }

    function createCampaign(
        uint256 _startBlock,
        uint256 _endBlock,
        address _token,
        address _beneficiaryWallet,
        string memory _metadataUrl
    ) external onlyOwner {
        address lendingPool = s_lendingPoolAddressProvider.getLendingPool();
        Campaign campaing = new Campaign(
            _startBlock,
            _endBlock,
            _token,
            lendingPool,
            _beneficiaryWallet,
            _metadataUrl
        );
        s_campaigns.push(address(campaing));

        emit CampaignCreated(
            address(campaing),
            _startBlock,
            _endBlock,
            _token,
            _beneficiaryWallet
        );
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
pragma solidity ^0.8.8;

interface ILendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./ILendingPool.sol";

contract Campaign {
    struct Info {
        address beneficiaryWallet;
        uint256 startBlock;
        uint256 endBlock;
        uint256 donationPool;
        uint256 collectedReward;
        uint256 additionalPassedFounds;
        string metadataUrl;
    }

    bool public s_campaignEnded;
    IERC20 public s_token;
    ILendingPool public s_lendingPool;
    Info public s_info;

    mapping(address => uint) public s_donorsToDonation;

    event Donated(address indexed who, uint256 amount);
    event Withdrawn(address indexed who, uint256 amount);
    event CampaignEnded(uint256 collectedFounds);

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        address _tokenAddress,
        address _lendingPoolAddress,
        address _beneficiaryWallet,
        string memory _metadataUrl
    ) {
        Info memory info;
        info.beneficiaryWallet = _beneficiaryWallet;
        info.startBlock = _startBlock;
        info.endBlock = _endBlock;
        info.metadataUrl = _metadataUrl;
        s_info = info;

        s_token = IERC20(_tokenAddress);
        s_lendingPool = ILendingPool(_lendingPoolAddress);

        s_token.approve(address(_lendingPoolAddress), type(uint256).max);
    }

    function donate(uint256 _amount) external {
        require(
            block.number >= s_info.startBlock && block.number < s_info.endBlock,
            "The campaign is not in progress."
        );

        s_info.donationPool += _amount;
        s_donorsToDonation[msg.sender] += _amount;

        s_token.transferFrom(msg.sender, address(this), _amount);
        s_lendingPool.deposit(address(s_token), _amount, address(this), 0);

        emit Donated(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(
            _amount <= s_donorsToDonation[msg.sender],
            "Your donation is less than your requested withdraw."
        );

        s_info.donationPool -= _amount;
        s_donorsToDonation[msg.sender] -= _amount;

        if (!s_campaignEnded) {
            s_lendingPool.withdraw(
                address(s_token),
                _amount,
                address(msg.sender)
            );
        } else {
            s_token.transfer(msg.sender, _amount);
        }

        emit Withdrawn(msg.sender, _amount);
    }

    function foundCharityWalletAndGetBackRest(uint256 _amount) external {
        require(
            _amount <= s_donorsToDonation[msg.sender],
            "Your donation is less than your requested withdraw."
        );
        require(s_campaignEnded, "The campaign has to be ended.");
        uint256 difference = s_donorsToDonation[msg.sender] - _amount;

        s_info.donationPool -= s_donorsToDonation[msg.sender];
        s_donorsToDonation[msg.sender] = 0;
        s_info.additionalPassedFounds += _amount;

        s_token.transfer(s_info.beneficiaryWallet, _amount);

        if (difference > 0) {
            s_token.transfer(msg.sender, difference);
        }
    }

    function endCampaign() external {
        require(
            block.number > s_info.endBlock,
            "The campaign hasn't ended yet"
        );
        require(!s_campaignEnded, "The campaing has been already ended!");
        s_campaignEnded = true;

        uint256 reward = s_lendingPool.withdraw(
            address(s_token),
            type(uint256).max,
            address(this)
        );
        s_info.collectedReward = reward - s_info.donationPool;

        s_token.transfer(s_info.beneficiaryWallet, s_info.collectedReward);

        emit CampaignEnded(s_info.collectedReward);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ILendingPool {

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
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
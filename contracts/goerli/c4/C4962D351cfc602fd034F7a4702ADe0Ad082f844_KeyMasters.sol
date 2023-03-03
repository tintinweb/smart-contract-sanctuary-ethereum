// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/*
* @title KeyMasters Community Contract
*/
contract KeyMasters is Initializable {

    uint public USDT_PER;
    uint public TOTAL_SPLIT;

    IERC20 USDT;

    address private _devWallet;
    address private wallet1;
    address private wallet2;
    address private wallet3;
    address private wallet4;
    address private wallet5;
    address private wallet6;
    address private wallet7;

    function setFounderWallet(address _address) external onlyDev {
        wallet1 = _address;
    }
    function setMarketingWallet(address _address) external onlyDev {
        wallet2 = _address;
    }
    function setDaoCommunityWallet(address _address) external onlyDev {
        wallet3 = _address;
    }
    function setDaoAcquisitionWallet(address _address) external onlyDev {
        wallet4 = _address;
    }
    function setDaoRewardsWallet(address _address) external onlyDev {
        wallet5 = _address;
    }
    function setDaoDevWallet(address _address) external onlyDev {
        wallet6 = _address;
    }
    function setTechnologyWallet(address _address) external onlyDev {
        wallet7 = _address;
    }

    function getTotalCount() public view returns(uint count) {
        return TOTAL_SPLIT;
    }

    /**
    * @notice withdraw the funds from the dev wallet to the distributed wallets. 
    */
    function distribute(uint _amount) external onlyDev {
         
        uint256 totalAmount = _amount * USDT_PER;
        require(totalAmount <= USDT.balanceOf(msg.sender), 'Not enough USDT');

        uint256 wallet1Share = (totalAmount / 100) * 14;
        uint256 wallet2Share = (totalAmount / 100) * 8;
        uint256 wallet3Share = (totalAmount / 100) * 16;
        uint256 wallet4Share = (totalAmount / 100) * 18;
        uint256 wallet5Share = (totalAmount / 100) * 7;
        uint256 wallet6Share = (totalAmount / 100) * 15;
        uint256 wallet7Share = (totalAmount / 100) * 22;

        USDT.transferFrom(msg.sender, wallet1, wallet1Share);
        USDT.transferFrom(msg.sender, wallet2, wallet2Share);
        USDT.transferFrom(msg.sender, wallet3, wallet3Share);
        USDT.transferFrom(msg.sender, wallet4, wallet4Share);
        USDT.transferFrom(msg.sender, wallet5, wallet5Share);
        USDT.transferFrom(msg.sender, wallet6, wallet6Share);
        USDT.transferFrom(msg.sender, wallet7, wallet7Share);

        TOTAL_SPLIT += _amount;
    }

    
    function name() public view returns (string memory) {
        return "KeyMasters Community Contract";
    }
    
    function setCost(uint _cost) external onlyDev {
        USDT_PER = _cost;
    }
    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDev() {
        require(_devWallet == msg.sender, "Only Dev wallet.");
        _;
    }  


    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    *
    */
    function initialize(address _usdt) public initializer {   
        wallet1 = address(0x50A199ecAa59f5C8d015D1Bd160Ee764DdFE802D);
        wallet2 = address(0xb05dbaAE91621738b076A75fc22D8Df581ccFE09);
        wallet3 = address(0x3E635dee0E109B91ec3881002b9992Bd6179698A);
        wallet4 = address(0xB6025052325d4C3e4e3E04139B3Ba8b9bd5b7D57);
        wallet5 = address(0x29eCE03c2792Fd6004F6e09FA0E936F159E910c4);
        wallet6 = address(0x62518A35D0393A6aE48B0F869637a4F5d36D2483);
        wallet7 = address(0x8a1A2CcF20822d3b02691326eb74a0b7f4087DeC);

        USDT = IERC20(_usdt);

        USDT_PER = 2100000000;
        
        _devWallet = msg.sender;
        
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
    
    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
}
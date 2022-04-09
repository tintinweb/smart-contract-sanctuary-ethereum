// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAtlantisToken is IERC20 {
    function mint(address account, uint256 amount) external; 
}

/**
 * @dev This is a smart contract for performing the batch distribution 
 * of the Atlantis tokens by the admins
 */

contract AtlantisDistributor {
    mapping(address => bool) public admins;
    mapping(address => bool) receivers;
    
    struct SuggestAdminData {
        uint8 votes;
        mapping(address => bool) voters;
    }
    mapping(address => SuggestAdminData) public suggestNewAdmins;
    mapping(address => SuggestAdminData) public suggestAdminsRemoval;

    uint256 public totalDistributed = 0;
    uint256 public totalReceivers = 0;
    uint8 private constant maxNoOfAdmins = 5;
    uint8 private constant maxAdminVote = 3;
    uint8 public noOfAdmins;

    IAtlantisToken atlantisToken;

    event Distribution(uint256 numberOfReceivers, uint256 amount, uint256 time, address admin);
    event AddAdmin(address indexed admin, address newAdmin);
    event RemoveAdmin(address indexed admin, address removedAdmin);
    event SuggestAdmin(address indexed admin, address suggestedAdmin, bytes16 action);

    error NotAuthorised();

    modifier onlyAdmin() {
        if(!admins[msg.sender]) {
            revert NotAuthorised();
        }
        _;
    }

    /**
     * @dev Sets the address for atlantis token and the admin 
     */
    constructor(address _atlantisToken) {
        atlantisToken = IAtlantisToken(_atlantisToken);
        admins[msg.sender] = true;
    }

    /**
     * @dev add admin to the list of admins
     */
    function addAdmin(address _admin) external onlyAdmin {
        require(!admins[_admin], "Already an admin");
        require(noOfAdmins < maxNoOfAdmins, "Reached max number of admins");

        SuggestAdminData storage suggestAdminData = suggestNewAdmins[msg.sender];
        suggestAdminData.voters[msg.sender] = true;
        suggestAdminData.votes += 1;

        emit SuggestAdmin(msg.sender, _admin, 'add');

        if(suggestAdminData.votes >= maxAdminVote || noOfAdmins < maxAdminVote) {
            admins[_admin] = true;
        
            emit AddAdmin(msg.sender, _admin);
        } 
    }

    /**
     * @dev removes an admin
     */
    function removeAdmin(address _admin) external onlyAdmin {
        require(admins[_admin], "Already an admin.");
        require(noOfAdmins != 1, "Reached minimum number of admins");

        SuggestAdminData storage suggestAdminData = suggestAdminsRemoval[msg.sender];
        suggestAdminData.voters[msg.sender] = true;
        suggestAdminData.votes += 1;

        emit SuggestAdmin(msg.sender, _admin, 'remove');

        if(suggestAdminData.votes >= maxAdminVote) {
            admins[_admin] = false;
        
            emit RemoveAdmin(msg.sender, _admin);
        }
    }

    /**
     * @dev distribute a spaecify amount of tokens to each addresses
     */
    function distributeToken(address[] memory _addresses, uint256[] memory _amounts) external onlyAdmin {
        require(_addresses.length <= 200, "Can not distribute to more than 200 at once.");

        uint256 totalAmount;

        for(uint256 i=0; i < _addresses.length; i++) {
            if(_addresses[i] != address(0)) {
                atlantisToken.mint(_addresses[i], _amounts[i]);

                if(!isReceiver(_addresses[i])) {
                    totalReceivers = totalReceivers + 1;
                    receivers[_addresses[i]] == true;
                }

                totalAmount += _amounts[i];
                totalDistributed = totalDistributed + _amounts[i];
            }
        }

        emit Distribution(_addresses.length, totalAmount, block.timestamp, msg.sender);
    }

    /**
     * @dev check if an address is a receiver, i.e has been distributed tokens from this contract
     */
    function isReceiver(address _receiver) public view returns(bool){
        return receivers[_receiver];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
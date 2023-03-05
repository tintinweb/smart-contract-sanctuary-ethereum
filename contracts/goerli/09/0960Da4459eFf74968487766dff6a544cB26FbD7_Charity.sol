/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: DonationNew.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 
 
interface IDepositToken is IERC20 {
    function mint(address to, uint256 amount) external;
}
 
contract Charity {

    address governmentEntity;

    Requirement[] public allData;
 
    struct Requirement {
        address ngo_address;
        string subject;
        string description;
        bool approved;
        uint256 fund_required;
        uint256 fund_delivered;
    }
 
    IDepositToken dToken;
    uint256 constant BASE_FEE = 0.001 ether;
 
    uint256 currrentRequirementId = 0;
    
    mapping(address => bool) public banned;
    mapping(uint256 => Requirement) public requirements;
    // mapping(address => bool) public governmentEntity;
 
 
    event NewRequirement(
        uint256 requirementId,
        address ngo_address,
        string subject,
        string description,
        uint256 fund_required
    );
 
    event RequirementApproved(
        uint256 requirementId,
        address approvedEntity
    );
 
    event NewDonation(
        uint256 requirementId,
        address donator,
        uint256 amountDonated
    );
 
    modifier isNotBanned() {
        require(!banned[msg.sender], "ERR: BANNED NGO");
        _;
    }
 
    modifier isGovernmentEntity() {
        require(governmentEntity == msg.sender, "ERR: NOT GOVERNMENT ENTITY");
        _;
    }
 
    constructor(IDepositToken _dToken) {
        dToken = _dToken;
        governmentEntity = msg.sender;
    }
 
    function report_NGO(address ngo) public {
        banned[ngo] = true;
    }
    
    function set_requirement(
        string memory subject,
        string memory description,
        uint256 fund_required
    ) public isNotBanned(){
 
        Requirement storage requirement = requirements[currrentRequirementId];
        requirement.ngo_address = msg.sender;
        requirement.subject = subject;
        requirement.description = description;
        requirement.fund_required = fund_required;
        emit NewRequirement(currrentRequirementId, msg.sender, subject, description, fund_required);
        currrentRequirementId++;
    } 
 
    function approve_requirement(uint256 requirementId) public isGovernmentEntity {
        Requirement storage requirement = requirements[requirementId];
        requirement.approved = true;
 
        emit RequirementApproved(requirementId, msg.sender);
    }
 
    function donateToken(uint256 requirementId, uint256 amount) public {
        Requirement storage requirement = requirements[requirementId];
        require(requirement.approved, "ERR: REQURIEMENT NOT APPROVED");

        requirement.fund_delivered += amount;
        dToken.transferFrom(msg.sender, requirement.ngo_address, amount);  
 
        emit NewDonation(requirementId, msg.sender, amount);      
    }
 
 
    function buyDonateToken() payable public{
        uint256 amount = msg.value / BASE_FEE;
        _safeMint(msg.sender, amount);
    }
 
    function _safeMint(address _to, uint256 _amount) internal {
        dToken.mint(_to, _amount);
    }

    
}
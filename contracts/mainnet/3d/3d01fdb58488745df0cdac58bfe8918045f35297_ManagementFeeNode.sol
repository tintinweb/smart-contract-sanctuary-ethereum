/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: contracts\IToken.sol

pragma solidity ^0.8.0;
interface IToken is IERC20{
    
    struct externalPosition{
        address externalContract;
        uint256 id;
    }

    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _quantity) external;

    function approveComponent(address _token, address _spender, uint256 _amount) external;

    function getComponents() external view returns(address[] memory);

    function getExternalComponents() external view returns(externalPosition[] memory);

    function getShare(address _component) external view returns(uint);

    function editComponent(address _component, uint256 _amount) external;

    function getCumulativeShare() external view returns(uint256);

    function basePrice() external view returns(uint256);

    function addNode(address _node) external;

    function updateTransferFee(uint256 newFee) external;
    
    function editFeeWallet(address newWallet) external;
}

// File: contracts\nodes\managmentFeeNode.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ManagementFeeNode {

    uint256 managementFee; // Percent of Set accruing to manager annually (1% = 100, 100% = 10000)
    address manager;
    mapping(address => uint256) private lastFeeCollected;
    //1 year and fee denom
    uint256 private constant ONE_YEAR_SCALER= 3.154 * 10**11 ;

    constructor(address _manager, uint256 fee, address initialToken){
        manager = _manager;
        managementFee = fee;
        lastFeeCollected[initialToken] = block.timestamp;
    }

    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }

    function calcFeeSupplyInflation(IToken indexToken) public view returns(uint256){
        uint256 numerator = (block.timestamp - lastFeeCollected[address(indexToken)]) * managementFee;
        return (indexToken.totalSupply() * numerator) / (ONE_YEAR_SCALER - numerator);
    }

    function accrueFee(IToken indexToken, address to) external onlyManager{
        require(lastFeeCollected[address(indexToken)] > 0, "Token not under managerment");
        indexToken.mint(
        to,
        calcFeeSupplyInflation(indexToken)
        );
        lastFeeCollected[address(indexToken)] = block.timestamp;
    }

    function addToken(address token) external onlyManager {
        require(lastFeeCollected[token] == 0, "already created");
        lastFeeCollected[token] = block.timestamp;
    }

    function updateMgmtFee(uint256 newFee) external onlyManager{
        managementFee = newFee;
    }

    function updateTransferFee(IToken indexToken, uint256 newFee) external onlyManager{
        indexToken.updateTransferFee(newFee);
    }

    function editFeeWallet(IToken indexToken, address newWallet) external onlyManager{
        indexToken.editFeeWallet(newWallet);
    }

    function editManager(address newManager) external onlyManager{
        manager = newManager;
    }
}
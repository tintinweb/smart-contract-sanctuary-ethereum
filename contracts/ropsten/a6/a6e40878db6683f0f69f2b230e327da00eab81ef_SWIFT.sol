// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./ERC20Snapshot.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract SWIFT is IERC20Metadata, Ownable, ERC20Pausable, ERC20Snapshot { // testing
    using SafeMath for uint256;

//    mapping(address => uint256) public _redeemAmount;

    address public supplyController;
    address public beneficiary;
    address public cbc; // testing

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isLiquidityPool;

    uint256 public _xsmallTaxPercentage = 1618; // for transferTaxPercentage 1000 is equal to 1%
    uint256 public _smallTaxPercentage = 1200;
    uint256 public _mediumTaxPercentage = 1000;
    uint256 public _largeTaxPercentage = 500;
    uint256 public _xlargeTaxPercentage = 300;

    constructor() ERC20('SWIFT', 'SWIFT') { // testing
        _mint(msg.sender, 500000000 * 10**18); // set initial supply to 500 million tokens
        beneficiary = owner();
        supplyController = owner();
        _isExcludedFromFees[owner()] = true;
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "caller is not the supplyController");
        _;
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function computeTaxAmount(uint256 _transferAmount) public view returns(uint256) {
        uint256 taxPercentage;

        if (_transferAmount <= 2000 * 10**18)
        {
            taxPercentage = _xsmallTaxPercentage;
        }

        else if (_transferAmount > 2000 * 10**18 && _transferAmount <= 10000 * 10**18)
        {
            taxPercentage = _smallTaxPercentage;
        }

        else if (_transferAmount > 10000 * 10**18 && _transferAmount <= 20000 * 10**18)
        {
            taxPercentage = _mediumTaxPercentage;
        }

        else if (_transferAmount > 20000 * 10**18 && _transferAmount <= 200000 * 10**18)
        {
            taxPercentage = _largeTaxPercentage;
        }

        else
        {
            taxPercentage = _xlargeTaxPercentage;
        }

        return _transferAmount.mul(taxPercentage).div(100000);
    }

    function isExcludedFromFees() public view returns(bool) {
        return _isExcludedFromFees[msg.sender];
    }

    function isLiquidityPool() public view returns(bool) {
        return _isLiquidityPool[msg.sender];
    }

    function setSupplyController(address _newSupplyController) public onlyOwner {
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        _isExcludedFromFees[supplyController] = false;
        supplyController = _newSupplyController;
        _isExcludedFromFees[supplyController] = true;
    }

    function setBeneficiary(address _newBeneficiary) public onlyOwner {
        require(_newBeneficiary != address(0), "cannot set beneficiary to address zero");
        _isExcludedFromFees[beneficiary] = false;
        beneficiary = _newBeneficiary;
        _isExcludedFromFees[beneficiary] = true;
    }

    function setFeeExclusion(address _userAddress, bool _isExcluded) public onlyOwner { // if _isExcluded true, _userAddress will be excluded from fees
        _isExcludedFromFees[_userAddress] = _isExcluded;
    }

    function setLiquidityPools(address _liquidityPool, bool _isPool) public onlyOwner {
        _isLiquidityPool[_liquidityPool] = _isPool;
    }

    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        _mint(supplyController, _value);
        return true;
    }

    function redeemGold(address _userAddress, uint256 _value) public onlySupplyController returns (bool success) {
        _burn(_userAddress, _value);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function transfer(
        address recipient,
        uint256 amount) public virtual override(ERC20, IERC20) whenNotPaused returns (bool) {
        _transferGIFT(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20, IERC20) whenNotPaused returns (bool) {
        _transferGIFT(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function _transferGIFT(
        address sender,
        address recipient,
        uint256 amount) internal virtual returns (bool) {

        if (_isLiquidityPool[sender] == true // this is a buy is where lp is sender
        || _isExcludedFromFees[sender]) // this is regular transfer where sender is excluded from fees
        {
            _transfer(sender, recipient, amount);
        }

        else // this is a standard transfer or a sell where lp is recipient
        {
            uint256 tax = computeTaxAmount(amount);
            _transfer(sender, beneficiary, tax);
            _transfer(sender, recipient, amount.sub(tax));
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable, ERC20Snapshot) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);

    }
}
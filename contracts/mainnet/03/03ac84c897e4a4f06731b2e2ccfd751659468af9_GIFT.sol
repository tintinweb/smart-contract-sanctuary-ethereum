// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./ERC20Snapshot.sol";

/**
 * insert token definition here
 */
contract GIFT is IERC20Metadata, Ownable, ERC20Pausable, ERC20Snapshot {
    using SafeMath for uint256;

    address public supplyController;
    address public beneficiary;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isLiquidityPool;

    uint256 public tierOneTaxPercentage = 1618; // for transferTaxPercentage 1000 is equal to 1%
    uint256 public tierTwoTaxPercentage = 1200;
    uint256 public tierThreeTaxPercentage = 1000;
    uint256 public tierFourTaxPercentage = 500;
    uint256 public tierFiveTaxPercentage = 300;

    uint256 public tierOneMax = 2000 * 10**18;
    uint256 public tierTwoMax = 10000 * 10**18;
    uint256 public tierThreeMax = 20000 * 10**18;
    uint256 public tierFourMax = 200000 * 10**18;

    event UpdateTaxPercentages(
        uint256 tierOneTaxPercentage,
        uint256 tierTwoTaxPercentage,
        uint256 tierThreeTaxPercentage,
        uint256 tierFourTaxPercentage,
        uint256 tierFiveTaxPercentage
    );

    event UpdateTaxTiers(
        uint256 tierOneMax,
        uint256 tierTwoMax,
        uint256 tierThreeMax,
        uint256 tierFourMax
    );

    event NewSupplyController(address indexed newSupplyController);
    event NewBeneficiary(address indexed newBeneficiary);

    constructor() ERC20('GIFT (Gold International Fungible Token)', 'GIFT') {
        _mint(msg.sender, 500000000 * 10**18); // initial supply set to 500 million tokens
        _isExcludedFromFees[owner()] = true;
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "caller is not the supplyController");
        _;
    }

    /**
    * allows specified owner to record all addresses and token balances for each address
    * at the block at which the function is called
    */
    function snapshot() public onlyOwner {
        _snapshot();
    }

    /**
    * computes amount which an address will be taxed upon transferring/selling their tokens
    * according to the amount being transferred (_transferAmount)
    */
    function computeTax(uint256 _transferAmount) public view returns(uint256) {
        uint256 taxPercentage;

        if (_transferAmount <= tierOneMax)
        {
            taxPercentage = tierOneTaxPercentage;
        }

        else if (_transferAmount > tierOneMax && _transferAmount <= tierTwoMax)
        {
            taxPercentage = tierTwoTaxPercentage;
        }

        else if (_transferAmount > tierTwoMax && _transferAmount <= tierThreeMax)
        {
            taxPercentage = tierThreeTaxPercentage;
        }

        else if (_transferAmount > tierThreeMax && _transferAmount <= tierFourMax)
        {
            taxPercentage = tierFourTaxPercentage;
        }

        else
        {
            taxPercentage = tierFiveTaxPercentage;
        }

        return _transferAmount.mul(taxPercentage).div(100000);
    }

    /**
    * allows owner to update tax percentage amounts for each tax tier
    *
    * emits UpdateTaxPercentages event upon calling
    */
    function updateTaxPercentages(
        uint256 _tierOneTaxPercentage,
        uint256 _tierTwoTaxPercentage,
        uint256 _tierThreeTaxPercentage,
        uint256 _tierFourTaxPercentage,
        uint256 _tierFiveTaxPercentage
    ) public onlyOwner {
        tierOneTaxPercentage = _tierOneTaxPercentage;
        tierTwoTaxPercentage = _tierTwoTaxPercentage;
        tierThreeTaxPercentage = _tierThreeTaxPercentage;
        tierFourTaxPercentage = _tierFourTaxPercentage;
        tierFiveTaxPercentage = _tierFiveTaxPercentage;
        emit UpdateTaxPercentages(
            tierOneTaxPercentage,
            tierTwoTaxPercentage,
            tierThreeTaxPercentage,
            tierFourTaxPercentage,
            tierFiveTaxPercentage
        );
    }

    /**
    * allows owner to update tax tier amounts
    *
    * emits UpdateTaxTiers event upon calling
    */
    function updateTaxTiers(
        uint256 _tierOneMax,
        uint256 _tierTwoMax,
        uint256 _tierThreeMax,
        uint256 _tierFourMax
    ) public onlyOwner {
        tierOneMax = _tierOneMax;
        tierTwoMax = _tierTwoMax;
        tierThreeMax = _tierThreeMax;
        tierFourMax = _tierFourMax;
        emit UpdateTaxTiers(
            tierOneMax,
            tierTwoMax,
            tierThreeMax,
            tierFourMax
        );
    }

    /**
    * allows owner to set a supply controller which is a separate address
    * that manages the token total supply
    *
    * emits NewSupplyController event upon calling
    */
    function setSupplyController(address _newSupplyController) public onlyOwner {
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        _isExcludedFromFees[supplyController] = false;
        supplyController = _newSupplyController;
        _isExcludedFromFees[supplyController] = true;
        emit NewSupplyController(supplyController);
    }

    /**
    * allows owner to set a beneficiary who will receive the taxes
    * from transfers and sells
    *
    * emits NewSupplyController event upon calling
    */
    function setBeneficiary(address _newBeneficiary) public onlyOwner {
        require(_newBeneficiary != address(0), "cannot set beneficiary to address zero");
        _isExcludedFromFees[beneficiary] = false;
        beneficiary = _newBeneficiary;
        _isExcludedFromFees[beneficiary] = true;
        emit NewBeneficiary(beneficiary);
    }

    /**
    * allows owner to set certain addresses to be excluded from transfer/sell fees
    */
    function setFeeExclusion(address _userAddress, bool _isExcluded) public onlyOwner { // if _isExcluded true, _userAddress will be excluded from fees
        _isExcludedFromFees[_userAddress] = _isExcluded;
    }

    /**
    * allows owner to set certain addresses to be recognized as liquidity pools.
    * This helps the smart contract to differentiate regular transfers from liquidity pool
    * sells and buys
    */
    function setLiquidityPools(address _liquidityPool, bool _isPool) public onlyOwner {
        _isLiquidityPool[_liquidityPool] = _isPool;
    }

    /**
    * allows supply controller to mint tokens to itself
    */
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        _mint(supplyController, _value);
        return true;
    }

    /**
    * allows supply controller to burn tokens from an address when they want to redeem
    * their tokens for gold
    */
    function redeemGold(address _userAddress, uint256 _value) public onlySupplyController returns (bool success) {
        _burn(_userAddress, _value);
        return true;
    }

    /**
    * allows owner to pause the contract which will prevent anyone from
    * transferring their tokens
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * allows owner to unpause the contract which will resume the allowance
    * of token transfers
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * standard ERC20 transfer() with extra functionality to support taxes
    */
    function transfer(
        address recipient,
        uint256 amount) public virtual override(ERC20, IERC20) whenNotPaused returns (bool) {
        _transferGIFT(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * standard ERC20 transferFrom() with extra functionality to support taxes
    */
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

    /**
    * standard ERC20 internal transfer function with extra functionality to support taxes
    */
    function _transferGIFT(
        address sender,
        address recipient,
        uint256 amount) internal virtual returns (bool) {

        if (_isLiquidityPool[sender] == true // this is a buy where lp is sender
            || _isExcludedFromFees[sender]) // this is transfer where sender is excluded from fees
        {
            _transfer(sender, recipient, amount);
        }

        else // this is a transfer or a sell where lp is recipient
        {
            uint256 tax = computeTax(amount);
            _transfer(sender, beneficiary, tax);
            _transfer(sender, recipient, amount.sub(tax));
        }
        return true;
    }

    /**
    Standard ERC20 Hook that is called before any transfer of tokens. This includes
    minting and burning.
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable, ERC20Snapshot) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);

    }
}
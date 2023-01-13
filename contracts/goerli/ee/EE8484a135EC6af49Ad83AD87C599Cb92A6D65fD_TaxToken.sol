// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


pragma solidity 0.8.17;

import "./IERC20.sol";
import "./ITaxHelper.sol";
import "./IMintFactory.sol";
import "./IBuyBackWallet.sol";
import "./ILPWallet.sol";
import "./ISettings.sol";
import "./IFacetHelper.sol";
import "./IFeeHelper.sol";

import "./Ownable.sol";
import "./FullMath.sol";

import "./BuyBackWallet.sol";
import "./LPWallet.sol";

import "./Storage.sol";

contract TaxToken is Storage, Ownable{
    

    struct ConstructorParams {
        string name_; 
        string symbol_; 
        uint8 decimals_; 
        address creator_;
        uint256 tTotal_;
        uint256 _maxTax;
        TaxSettings _settings;
        TaxSettings _lockedSettings;
        Fees _fees;
        address _transactionTaxWallet;
        CustomTax[] _customTaxes;
        uint256 lpWalletThreshold;
        uint256 buyBackWalletThreshold;
        uint256 _taxHelperIndex;
        address admin_;
        address recoveryAdmin_;
        bool isLossless_;
        AntiBotSettings _antiBotSettings;
        uint256 _maxBalanceAfterBuy;
        SwapWhitelistingSettings _swapWhitelistingSettings;
    }

    constructor(
        ConstructorParams memory params,
        address _factory
        ) {
        address constructorFacetAddress = IFacetHelper(IMintFactory(_factory).getFacetHelper()).getConstructorFacet();
        (bool success, bytes memory result) = constructorFacetAddress.delegatecall(abi.encodeWithSignature("constructorHandler((string,string,uint8,address,uint256,uint256,(bool,bool,bool,bool,bool,bool,bool,bool),(bool,bool,bool,bool,bool,bool,bool,bool),((uint256,uint256),uint256,uint256,uint256),address,(string,(uint256,uint256),address)[],uint256,uint256,uint256,address,address,bool,(uint256,uint256,uint256,uint256,bool),uint256,(uint256,bool)),address)", params, _factory));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
        IFeeHelper feeHelper = IFeeHelper(IMintFactory(factory).getFeeHelper());
        uint256 fee = FullMath.mulDiv(params.tTotal_, feeHelper.getFee(), feeHelper.getFeeDenominator());
        address feeAddress = feeHelper.getFeeAddress();
        _approve(params.creator_, msg.sender, fee);
        isTaxed = true;
        transferFrom(params.creator_, feeAddress, fee);
    }

    /// @notice this is the power behind Lossless
    function transferOutBlacklistedFunds(address[] calldata from) external {
        require(isLosslessOn); // added by us for extra protection
        require(_msgSender() == address(lossless), "LOL");
        for (uint i = 0; i < from.length; i++) {
            _transfer(from[i], address(lossless), balanceOf(from[i]));
        }
    }

    /// @notice Checks whether an address is blacklisted
    /// @param _address the address to check
    /// @return bool is blacklisted or not
    function isBlacklisted(address _address) public view returns (bool) {
        return blacklist[_address];
    }

    /// @notice Checks whether the contract has paused transactions
    /// @return bool is paused or not
    function paused() public view returns (bool) {
        if(taxSettings.canPause == false) {
            return false;
        }
        return isPaused;
    }

    /// @notice Handles the burning of token during the buyback tax process
    /// @dev must first receive the amount to be burned from the taxHelper contract (see initial transfer in function)
    /// @param _amount the amount to burn
    function buyBackBurn(uint256 _amount) external {
        address taxHelper = IMintFactory(factory).getTaxHelperAddress(taxHelperIndex);
        require(msg.sender == taxHelper, "RA");
        _transfer(taxHelper, owner(), _amount);

        _beforeTokenTransfer(owner(), address(0), _amount);

        address taxFacetAddress = IFacetHelper(IMintFactory(factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("burn(uint256)", _amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
    }

    /// @notice Handles the taxes for the token.
    /// @dev handles every tax within the tax facet. 
    /// @param sender the one sending the transaction
    /// @param recipient the one receiving the transaction
    /// @param amount the amount of tokens being sent
    /// @return totalTaxAmount the total amount of the token taxed
    function handleTaxes(address sender, address recipient, uint256 amount) internal virtual returns (uint256 totalTaxAmount) {
        address taxFacetAddress = IFacetHelper(IMintFactory(factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("handleTaxes(address,address,uint256)", sender, recipient, amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
        return abi.decode(result, (uint256));

    }

    // ERC20 Functions

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    /// @dev modified to handle if the token has reflection active in it settings
    function balanceOf(address account) public view returns (uint256) {
        if(taxSettings.holderTax) {
            if (_isExcluded[account]) return _tOwned[account];
            return tokenFromReflection(_rOwned[account]); 
        }
        return _tOwned[account];
    }

    // Reflection Functions 
    // necessary to get reflection balance

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "ALR");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _getRate() public view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    // ERC20 Functions continued 
    /// @dev modified slightly to add taxes

    function transfer(address recipient, uint256 amount) public returns (bool) {
        if(!isTaxed) {
            isTaxed = true;
            uint256 totalTaxAmount = handleTaxes(_msgSender(), recipient, amount);
            amount -= totalTaxAmount;
        }
        if (isLosslessOn) {
            lossless.beforeTransfer(_msgSender(), recipient, amount);
        } 
        _transfer(_msgSender(), recipient, amount);
        isTaxed = false;
        if (isLosslessOn) {
            lossless.afterTransfer(_msgSender(), recipient, amount);
        } 
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        if (isLosslessOn) {
            lossless.beforeApprove(_msgSender(), spender, amount);
        }
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if(!isTaxed) {
            isTaxed = true;
            uint256 totalTaxAmount = handleTaxes(sender, recipient, amount);
            amount -= totalTaxAmount;
        }
        if (isLosslessOn) {
            lossless.beforeTransferFrom(_msgSender(), sender, recipient, amount);
        }
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ETA");

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        isTaxed = false;
        if (isLosslessOn) {
            lossless.afterTransfer(_msgSender(), recipient, amount);
        } 
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        if (isLosslessOn) {
            lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
        }
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
         if (isLosslessOn) {
            lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
        }
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "EABZ");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "EAFZ");
        require(spender != address(0), "EATZ");
        if (isLosslessOn) {
            lossless.beforeApprove(_owner, spender, amount);
        } 

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        // AntiBot Checks
        address antiBotFacetAddress = IFacetHelper(IMintFactory(factory).getFacetHelper()).getAntiBotFacet();
        if(marketInit && antiBotSettings.isActive && lpTokens[sender]) {
            (bool success, bytes memory result) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("antiBotCheck(uint256,address)", amount, recipient));
            if (!success) {
                if (result.length < 68) revert();
                revert(abi.decode(result, (string)));
            }
        } 
        if(taxSettings.maxBalanceAfterBuy && lpTokens[sender]) {
            (bool success2, bytes memory result2) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("maxBalanceAfterBuyCheck(uint256,address)", amount, recipient));
            if (!success2) {
                if (result2.length < 68) revert();
                revert(abi.decode(result2, (string)));
            }
        } 
        if(marketInit && swapWhitelistingSettings.isActive && lpTokens[sender]) {
            (bool success3, bytes memory result3) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("swapWhitelistingCheck(address)", recipient));
            if (!success3) {
                if (result3.length < 68) revert();
                revert(abi.decode(result3, (string)));
            }
        } 
        address taxFacetAddress = IFacetHelper(IMintFactory(factory).getFacetHelper()).getTaxFacet();
        (bool success4, bytes memory result4) = taxFacetAddress.delegatecall(abi.encodeWithSignature("_transfer(address,address,uint256)", sender, recipient, amount));
        if (!success4) {
            if (result4.length < 68) revert();
            revert(abi.decode(result4, (string)));
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function mint(uint256 amount) public onlyOwner {
        if (isLosslessOn) {
            lossless.beforeMint(_msgSender(), amount);
        } 
        _mint(msg.sender, amount);
    }

    /// @notice custom mint to handle fees
    function _mint(address account, uint256 amount) internal virtual onlyOwner {
        require(account != address(0), "EMZ");
        require(taxSettings.canMint, "NM");
        require(!taxSettings.holderTax, "NM");
        if (isLosslessOn) {
            lossless.beforeMint(account, amount);
        } 

        IFeeHelper feeHelper = IFeeHelper(IMintFactory(factory).getFeeHelper());
        uint256 fee = FullMath.mulDiv(amount, feeHelper.getFee(), feeHelper.getFeeDenominator());
        address feeAddress = feeHelper.getFeeAddress();

        _beforeTokenTransfer(address(0), account, amount);
        _tTotal += amount;
        _tOwned[feeAddress] += fee;
        _tOwned[account] += amount - fee;

        emit Transfer(address(0), feeAddress, fee);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public {
        address taxFacetAddress = IFacetHelper(IMintFactory(factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("burn(uint256)", amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
    }

    /// @notice Handles all facet logic
    /// @dev Implements a customized version of the EIP-2535 Diamond Standard to add extra functionality to the contract
    /// https://github.com/mudgen/diamond-3 
    fallback() external {
        address facetHelper = IMintFactory(factory).getFacetHelper(); 
        address facet = IFacetHelper(facetHelper).getFacetAddressFromSelector(msg.sig);
        require(facet != address(0), "Function does not exist");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
    
            let result := delegatecall(
                gas(),
                facet,
                ptr,
                calldatasize(),
                0,
                0
            )

            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
  
}
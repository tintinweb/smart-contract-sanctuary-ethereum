// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./SmartDebt.sol";


contract CapexmoveRootToken is ERC20, Pausable {

    using SafeMath for uint256;

    mapping (address => SmartDebtData) private _registeredSmartDebts;

    mapping (uint => address) private _indexedSmartDebts;

    uint public _smartDebtCnt = 0;

    struct SmartDebtData {
        uint status;
        address issuer;
        mapping (address => uint256) investors;
        mapping (uint => address) indexedInvestors;
		uint256 faceAmount;
        uint investorsCount;
    }

    uint private SMART_DEBT_REGISTERED = 1;

    uint private SMART_DEBT_ACTIVATED = 2;


    constructor(string memory name_,string memory symbol_) ERC20(name_, symbol_) {
        _owner = _msgSender();
        _setupDecimals(0);
    }


    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool) {
        require(_registeredSmartDebts[recipient_].status == 0
                || _registeredSmartDebts[recipient_].status == SMART_DEBT_REGISTERED
                || _registeredSmartDebts[recipient_].status == SMART_DEBT_ACTIVATED
                && _registeredSmartDebts[recipient_].investors[_msgSender()] == 0,
                "SmartDebt already activated");

        _transfer(_msgSender(), recipient_, amount_);

        _distributeAndRegisterAtSmartDebtIfRepayment(recipient_, amount_);

        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public virtual override returns (bool) {
        require(_registeredSmartDebts[recipient_].status != SMART_DEBT_ACTIVATED, "SmartDebt already activated");

        _registerInvestorAndAmountIfInvestment(sender_, recipient_, amount_);

        _transfer(sender_, recipient_, amount_);
        _approve(sender_, _msgSender(), allowance(sender_, _msgSender()).sub(amount_, "ERC20: transfer amount exceeds allowance"));

        _distributeAndRegisterAtSmartDebtIfRepayment(recipient_, amount_);

        return true;
    }

    function mint(address account_, uint256 amount_) public onlyOwner virtual {
        require(_registeredSmartDebts[account_].status == 0, "Cannot mint for SmartDebt");
        _mint(account_, amount_);
    }
    function burn(address account_, uint256 amount_) public onlyOwner virtual {
        require(_registeredSmartDebts[account_].status == 0, "Cannot burn for SmartDebt");
        _burn(account_, amount_);
    }

    function registerSmartDebt(address smartDebt_, address issuer_, uint256 faceAmount_) public returns (bool) {
        require(_registeredSmartDebts[smartDebt_].status == 0, "SmartDebt already registered");

		_registeredSmartDebts[smartDebt_].faceAmount = faceAmount_;
        _registeredSmartDebts[smartDebt_].status = SMART_DEBT_REGISTERED;
        _registeredSmartDebts[smartDebt_].issuer = issuer_;
        _indexedSmartDebts[_smartDebtCnt] = smartDebt_;
        _smartDebtCnt++;

        return true;
    }

    function activateSmartDebt(address smartDebt_) public returns (bool) {
        require(_registeredSmartDebts[smartDebt_].status == SMART_DEBT_REGISTERED, "SmartDebt not in registered state");
        _registeredSmartDebts[smartDebt_].status = SMART_DEBT_ACTIVATED;
        return true;
    }

    function getSmartDebtState(address smartDebt_) public view returns (uint) {
        return _registeredSmartDebts[smartDebt_].status;
    }

    function getSmartDebtInvestment(address smartDebt_, address investor_) public view returns (uint256) {
        return _registeredSmartDebts[smartDebt_].investors[investor_];
    }

    function getIndexedSmartDebt(uint ind_) public view returns (address) {
        return _indexedSmartDebts[ind_];
    }

    function getInvestors(address smartDebt_) public virtual returns (address[] memory) {
        address[] memory ret = new address[](_registeredSmartDebts[smartDebt_].investorsCount);

        for (uint i = 0; i < _registeredSmartDebts[smartDebt_].investorsCount; i++) {
            ret[i] = _registeredSmartDebts[smartDebt_].indexedInvestors[i];
        }

        return ret;
    }

	function getInvestorsCnt(address smartDebt_) public virtual returns (uint) {
		return _registeredSmartDebts[smartDebt_].investorsCount;
	}

    function _registerInvestorAndAmountIfInvestment(address sender_, address recipient_, uint256 amount_) internal returns (bool) {

        if (_registeredSmartDebts[recipient_].status == SMART_DEBT_REGISTERED) {
			
            if (_registeredSmartDebts[recipient_].investors[sender_] == 0) {
                _registeredSmartDebts[recipient_].investors[sender_] = amount_;
                uint cnt = _registeredSmartDebts[recipient_].investorsCount;
                _registeredSmartDebts[recipient_].indexedInvestors[cnt] = sender_;
                _registeredSmartDebts[recipient_].investorsCount = cnt + 1;
            } else {
                _registeredSmartDebts[recipient_].investors[sender_] = _registeredSmartDebts[recipient_].investors[sender_].add(amount_);
            }
        }

        return true;
    }

    function _distributeAndRegisterAtSmartDebtIfRepayment(address recipient_, uint256 amount_) internal returns(bool) {
        if (_registeredSmartDebts[recipient_].status == SMART_DEBT_ACTIVATED
            && _registeredSmartDebts[recipient_].issuer == _msgSender()) {

			uint256 share;
			address investor;

			for (uint i = 0; i < _registeredSmartDebts[recipient_].investorsCount; i++) {
				investor = _registeredSmartDebts[recipient_].indexedInvestors[i];
				share = (_registeredSmartDebts[recipient_].investors[investor].mul(amount_)).div(_registeredSmartDebts[recipient_].faceAmount);
                _distributeRepayment(recipient_, investor, share);
			}

            SmartDebt smartDebt = SmartDebt(recipient_);
            smartDebt.registerRepayment(amount_);
        }
        return true;
    }

    function _distributeRepayment(address sender_, address recipient_, uint256 amount_) internal returns (bool) {
        _transfer(sender_, recipient_, amount_);
        return true;
    }
}
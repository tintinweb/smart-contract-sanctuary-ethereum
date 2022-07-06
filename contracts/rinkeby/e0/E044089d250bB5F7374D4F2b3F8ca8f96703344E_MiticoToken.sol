// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";

contract MiticoToken is ERC20, Owner {

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklist;

    // properties used to get fee
    uint256 private constant amountDivToGetFee = 10**4;

    uint256 public amountMulToGetAditionalFee = 0; //example: 100 = 1%

    uint256 private constant MulByDec = 10**18;
    
    // tokenomics wallets
    address public constant playToEarn_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;
    address public constant liquidityPools_wallet = 0x264c84fBE8dAcdC4FD7559B204526AF1f61Ca5e7;
    address public constant presale_wallet = 0xCd04Dac93f1172b7BA4218b84C81d68EBB32e8Cc;
    address public constant team_wallet = 0xDF450B51b2f2FA1560EadA15E149d0064dF2327d;
    address public constant marketing_wallet = 0x5Dbb556a3e832b8179B30c0E64C5668A6b3BdFD8;
    address public constant airdrop_wallet = 0xa4a01Cb9898CcF59e9780f22c828724f7794dC1F;

    address public fees_wallet = 0xd2A9D580bBFb8dAE083e81599582283B2A16C644;

    // tokenomics supply
    uint public constant playToEarn_supply = 5299999999 * MulByDec;
    uint public constant liquidityPools_supply = 300000000 * MulByDec;
    uint public constant presale_supply = 2400000000 * MulByDec;
    uint public constant team_supply = 1000000000 * MulByDec;
    uint public constant marketing_supply = 800000000 * MulByDec;
    uint public constant airdrop_supply = 200000000 * MulByDec;


    constructor() ERC20("MITICO", "MITICO") {
        // set tokenomics balances
        _mint(playToEarn_wallet, playToEarn_supply);
        _mint(liquidityPools_wallet, liquidityPools_supply);
        _mint(presale_wallet, presale_supply);
        _mint(team_wallet, team_supply);
        _mint(marketing_wallet, marketing_supply);
        _mint(airdrop_wallet, airdrop_supply);

        _isExcludedFromFee[playToEarn_wallet] = true;
        _isExcludedFromFee[liquidityPools_wallet] = true;
        _isExcludedFromFee[presale_wallet] = true;
        _isExcludedFromFee[team_wallet] = true;
        _isExcludedFromFee[marketing_wallet] = true;
        _isExcludedFromFee[airdrop_wallet] = true;
        _isExcludedFromFee[fees_wallet] = true;

    }

    function setPercentageToGetAditionalFee(uint256 _newValue) external isOwner {
        amountMulToGetAditionalFee = _newValue;
    }

    function excludeFromFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
             _isExcludedFromFee[accounts[i]] = true;
        }
    }
    function includeInFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = false;
        }
    }
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
             _blacklist[accounts[i]] = false;
        }
    }
    function includeInBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _blacklist[accounts[i]] = true;
        }
    }
    function isOnBlacklist(address account) external view returns(bool) {
        return _blacklist[account];
    }

    function getAdditionalFee(uint256 _value) private view returns(uint256){
        uint256 aditionalFee = 0;
        aditionalFee = (_value*amountMulToGetAditionalFee)/amountDivToGetFee;
        return aditionalFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "ERC20: transfer amount must be greater than 0");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(!_blacklist[from] && !_blacklist[to], "ERC20: from or to address are in blacklist");
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }else{
            uint256 aditionalFee = getAdditionalFee(amount);
            if(aditionalFee>0){
                _balances[fees_wallet] += aditionalFee;
                emit Transfer(from, fees_wallet, aditionalFee);
            }
            _balances[to] += amount-aditionalFee;
            emit Transfer(from, to, amount-aditionalFee);
        }

        unchecked {
            _balances[from] = fromBalance-amount;
        }
        _afterTokenTransfer(from, to, amount);
    }


    // ********************************************************************
    // ********************************************************************
    // BURNEABLE FUNCTIONS

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

}
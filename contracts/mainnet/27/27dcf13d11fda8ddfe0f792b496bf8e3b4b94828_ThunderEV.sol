// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Variables.sol";

// Contract contains no comments or less comments due to chain contract file size issue.

contract ThunderEV is IERC20 {
    // Contract imports
    using SafeMath for uint256;
    using Address for address;

    string private _name =  Variables._name;
    string private _symbol =  Variables._symbol;
    uint8 private _decimals = Variables._decimals;
    uint256 private _initial_total_supply =  Variables._initial_total_supply;
    uint256 private _total_supply = Variables._initial_total_supply;

    address private _owner;

    uint256 private _burning_till_block_now = 0; // initial burning token count is 0
    uint256 private _pending_fees_to_distribute = 0; // contribution collection till block.timestamp, after last distribution

    mapping(address => Variables.wallet_details) private _wallets;
    address[] private _holders;
    uint256 private _total_holders = 0;
    address[] private _directors;
    uint256 private _total_directors = 0;
    address[] private _investors;
    uint256 private _total_investors = 0;

    mapping(address => mapping (address => uint256)) private _allowances;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        // initial wallet adding process on contract launch
        _owner = msg.sender;
        _wallets[msg.sender] = Variables.wallet_details(
            _total_supply,
            block.timestamp,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            false,
            false
        );
        _total_holders += 1;
        _holders.push(msg.sender);

        // adding development wallet
        _wallets[Variables._development_wallet] = Variables.wallet_details(
            0,
            block.timestamp,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            false,
            false
        );
        _total_holders += 1;
        _holders.push(Variables._development_wallet);

        // adding marketing wallet
        _wallets[Variables._marketing_wallet] = Variables.wallet_details(
            0,
            block.timestamp,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
            false,
            false
        );
        _total_holders += 1;
        _holders.push(Variables._marketing_wallet);
        emit OwnershipTransferred(address(0), _owner);
        emit Transfer(address(0), msg.sender, _total_supply);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Thunder EV : This function is only accesible by owner.");
        _;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _total_supply;
    }

    function initialTotalSupply() public view returns (uint256) {
        return _initial_total_supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account].balance;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }

    function burningTillNow() public view returns (uint256) {
        return _burning_till_block_now;
    }

    function pendingFeeToDistribute() public view returns (uint256) {
        return  _pending_fees_to_distribute;
    }

    function directorCount() public view returns (uint256) {
        return _total_directors;
    }

    function investorCount() public view returns (uint256) {
        return _total_investors;
    }

    function getWalletDetails(address account) public view returns (Variables.wallet_details memory) {
        return _wallets[account];
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function updateLockingConditions() public returns (bool) {
        _update_locking_conditions();
        return true;
    }

    function addDirectorWallet(address account) public onlyOwner returns (bool) {
        require(_wallets[account].balance > 0, "Thunder EV : Wallet Is Empty To Create Director.");
        require(_wallets[account].is_director == false, "Thunder EV : Wallet Is Already Director.");
        require(_wallets[account].is_investor == false, "Thunder EV : Wallet Is Already Investor.");
        _wallets[account].total_lock_amount = _wallets[account].balance;
        _wallets[account].total_release_amount = 0;
        _wallets[account].is_director = true;
        _wallets[account].is_investor = false;
        _wallets[account].locked_on = block.timestamp;
        _wallets[account].next_release_time = block.timestamp + ( Variables._director_lock_days * 1 days );
        _wallets[account].current_release_iteration = 0;
        _wallets[account].current_release_amount = 0;
        _total_directors += 1;
        _directors.push(account);
        return true;
    }

    function addInvestorWallet(address account) public onlyOwner returns (bool) {
        require(_wallets[account].balance > 0, "Thunder EV : Wallet Is Empty To Create Investor.");
        require(_wallets[account].is_investor == false, "Thunder EV : Wallet Is Already Investor.");
        require(_wallets[account].is_director == false, "Thunder EV : Wallet Is Already Director.");
        _wallets[account].total_lock_amount = _wallets[account].balance;
        _wallets[account].total_release_amount = 0;
        _wallets[account].is_director = false;
        _wallets[account].is_investor = true;
        _wallets[account].locked_on = block.timestamp;
        _wallets[account].next_release_time = block.timestamp + ( Variables._investor_lock_days * 1 days );
        _wallets[account].current_release_iteration = 0;
        _wallets[account].current_release_amount = 0;
        _total_investors += 1;
        _investors.push(account);
        return true;
    }

    function burnToken(uint256 amount) public onlyOwner returns (bool) {
        _wallets[_owner].balance = _wallets[_owner].balance.sub(amount * 10**_decimals, "Thunder EV : Burn Amount Exceeds Balance");
        _total_supply = _total_supply.sub(amount * 10**_decimals);
        emit Transfer(_owner, address(0), amount * 10**_decimals);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Need to check condition for approval method.
    function _approve( address owner, address spender, uint256 amount ) private {
        require(owner != address(0), "Thunder EV : Approve from the zero address");
        require(spender != address(0), "Thunder EV : Approve to the zero address");
        require(_wallets[owner].balance >= amount, "Thunder EV : Can not allow more than balance.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Thunder EV :transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Thunder EV :decreased allowance below zero"));
        return true;
    }

    function _contribution_airdrop() internal {
        uint256 total_eligible_token = 0;
        uint256 distribution_till_block_now = 0;
        uint256 amount_to_transfer;
        uint256 eligibale_account_counter = 0;
        if (_pending_fees_to_distribute >= Variables._fees_distribution_after) {
            for (uint256 i = 0; i < _total_holders; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    Variables._fees_distribution_participation_eligibility
                ) {
                    eligibale_account_counter += 1;
                    total_eligible_token = total_eligible_token.add(
                        _wallets[_holders[i]].balance
                    );
                }
            }
            for (uint256 i = 0; i < _total_holders; i++) {
                if (
                    _wallets[_holders[i]].balance >=
                    Variables._fees_distribution_participation_eligibility
                ) {
                    amount_to_transfer = (
                        _pending_fees_to_distribute.mul(
                            (_wallets[_holders[i]].balance.mul(10**_decimals))
                                .div(total_eligible_token)
                        )
                    ).div(10**_decimals);
                    _wallets[_holders[i]].balance = _wallets[_holders[i]]
                        .balance
                        .add(amount_to_transfer);
                    distribution_till_block_now += amount_to_transfer;
                }
            }
            emit FeeDistributionUpdate(
                eligibale_account_counter,
                distribution_till_block_now,
                total_eligible_token,
                block.timestamp
            );
            _pending_fees_to_distribute = _pending_fees_to_distribute.sub(
                distribution_till_block_now
            );
        }
    }

    function _update_locking_conditions() internal {
        for (uint256 i = 0; i < _total_directors; i++) {
            if ( _wallets[_directors[i]].current_release_iteration < Variables._director_total_release_iteration ) {
                if ( _wallets[_directors[i]].next_release_time <= block.timestamp ) {
                    // get multiplier
                    uint256 multiplier = (
                        (
                            (block.timestamp - _wallets[_directors[i]].next_release_time) / 1 days
                        ) / Variables._director_release_every_days_after_locking
                    ) + 1;
                    uint256 release_amount = ( ( _wallets[_directors[i]].total_lock_amount * Variables._director_release_percentage ) / 100 ) * multiplier;
                    if ( ( _wallets[_directors[i]].total_lock_amount - _wallets[_directors[i]].current_release_amount ) < release_amount ) {
                        release_amount = _wallets[_directors[i]].total_lock_amount;
                    }
                    _wallets[_directors[i]].total_release_amount += release_amount;
                    _wallets[_directors[i]].next_release_time += ( Variables._director_release_every_days_after_locking * multiplier * 1 days );
                    _wallets[_directors[i]].current_release_iteration += (1 * multiplier);
                }
            }
        }
        for (uint256 i = 0; i < _total_investors; i++) {
            if ( _wallets[_investors[i]].current_release_iteration < Variables._investor_total_release_iteration ) {
                if ( _wallets[_investors[i]].next_release_time <= block.timestamp ) {
                    uint256 multiplier = (
                        (
                            (block.timestamp - _wallets[_investors[i]].next_release_time) / 1 days
                        ) / Variables._investor_release_every_days_after_locking
                    ) + 1;
                    uint256 release_amount = ( ( _wallets[_investors[i]].total_lock_amount * Variables._investor_release_percentage ) / 100 ) * multiplier;
                    if ( ( _wallets[_investors[i]].total_lock_amount - _wallets[_investors[i]].current_release_amount ) < release_amount ) {
                        release_amount = _wallets[_investors[i]].total_lock_amount;
                    }
                    _wallets[_investors[i]].total_release_amount += release_amount;
                    _wallets[_investors[i]].next_release_time += ( Variables._investor_release_every_days_after_locking * multiplier * 1 days );
                    _wallets[_investors[i]].current_release_iteration += (1 * multiplier);
                }
            }
        }
    }

    function _check_sending_conditions(address sender, uint256 amount) internal {
        if (sender != _owner) {
            if ( (_wallets[sender].last_sent_time + 1 days ) < block.timestamp ) {
                require(amount + ((amount * Variables._fees_percentage)/100) <= _wallets[sender].max_sending_allowed_in_timeperiod, "Thunder EV : Can Not Trasfter more than allowed daily limit of 25%");
                _wallets[sender].total_sent_in_timeperiod = (amount + (amount * Variables._fees_percentage)/100);
                _wallets[sender].last_sent_time = block.timestamp;
            } else {
                require(
                    (amount + ((amount * Variables._fees_percentage)/100) + _wallets[sender].total_sent_in_timeperiod) <= _wallets[sender].max_sending_allowed_in_timeperiod,
                    "Thunder EV : Can Not Trasfter more than allowed daily limit of 25%"
                );
                _wallets[sender].total_sent_in_timeperiod += (amount + (amount * Variables._fees_percentage)/100);
            }
        }
    }

    function _after_sending_condition_update(address reciever) internal {
        _wallets[reciever].max_sending_allowed_in_timeperiod = _wallets[reciever].balance * Variables._others_24_hours_transfer_limit / 100;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Thunder EV : transfer from the zero address");
        require(recipient != address(0), "Thunder EV : transfer to the zero address");
        if (sender.isContract()) {
            require(
                _wallets[sender].balance >= amount,
                "Thunder EV : transfer amount exceeds total available balance"
            );
        } else {
            require(
                _wallets[sender].balance >= amount + ((amount * Variables._fees_percentage)/100),
                "Thunder EV : transfer amount exceeds total available balance"
            );
        }

        _update_locking_conditions(); // Updating locking conditions
        _check_sending_conditions(sender, amount); // checking user sending conditions


        if ( _wallets[sender].is_director || _wallets[sender].is_investor ) {
            // Checking balance with blocked amount condition
            require(
                ( _wallets[sender].balance - ( _wallets[sender].total_lock_amount - _wallets[sender].total_release_amount ) ) >= amount + ((amount * Variables._fees_percentage)/100),
                "Thunder EV : transfer amount exceeds total allowed balance"
            );
        }

        if (_wallets[recipient].balance == 0) {
            _wallets[recipient] = Variables.wallet_details(
                0,
                block.timestamp,
                0, 0, 0, 0, 0, 0, 0, 0, 0,
                false,
                false
            );
            _total_holders += 1;
            _holders.push(recipient);
        }

        _wallets[sender].balance = _wallets[sender].balance.sub(amount);
        _wallets[recipient].balance = _wallets[recipient].balance.add(amount);
        emit Transfer(sender, recipient, amount);

        uint256 _fees_amount = (amount * Variables._fees_percentage)/100;

        if (sender.isContract()) {
            _wallets[recipient].balance = _wallets[recipient].balance.sub(_fees_amount);
            emit Burn(recipient, (_fees_amount * Variables._burning_from_fees_percentage) / 100);
            emit Transfer(recipient, address(0), (_fees_amount * Variables._burning_from_fees_percentage) / 100);
            emit Transfer(recipient, Variables._development_wallet, (_fees_amount * Variables._development_sharing_percentage_from_fees_percentage) / 100);
            emit Transfer(recipient, Variables._marketing_wallet, (_fees_amount * Variables._marketing_sharing_percentage_from_fees_percentage) / 100);
        } else {
            _wallets[sender].balance = _wallets[sender].balance.sub(_fees_amount);
            emit Burn(sender, (_fees_amount * Variables._burning_from_fees_percentage) / 100);
            emit Transfer(sender, address(0), (_fees_amount * Variables._burning_from_fees_percentage) / 100);
            emit Transfer(sender, Variables._development_wallet, (_fees_amount * Variables._development_sharing_percentage_from_fees_percentage) / 100);
            emit Transfer(sender, Variables._marketing_wallet, (_fees_amount * Variables._marketing_sharing_percentage_from_fees_percentage) / 100);
        }
        _wallets[Variables._development_wallet].balance = (
            _wallets[Variables._development_wallet].balance.add((_fees_amount * Variables._development_sharing_percentage_from_fees_percentage) / 100)
        );
        _wallets[Variables._marketing_wallet].balance = (
            _wallets[Variables._marketing_wallet].balance.add((_fees_amount * Variables._marketing_sharing_percentage_from_fees_percentage) / 100)
        );
        _total_supply = _total_supply.sub((_fees_amount * Variables._burning_from_fees_percentage) / 100);
        _pending_fees_to_distribute = _pending_fees_to_distribute.add((_fees_amount * Variables._redistribution_from_fees_percentage ) / 100);

        emit ContributionDeductionAndBurningLog(
            ( _fees_amount * Variables._redistribution_from_fees_percentage ) / 100,
            ( _fees_amount * Variables._burning_from_fees_percentage ) / 100,
            ( _fees_amount * Variables._marketing_sharing_percentage_from_fees_percentage ) / 100,
            ( _fees_amount * Variables._development_sharing_percentage_from_fees_percentage ) / 100
        );

        _contribution_airdrop(); // check and make airdrops of contributions
        _after_sending_condition_update(recipient);
    }
}
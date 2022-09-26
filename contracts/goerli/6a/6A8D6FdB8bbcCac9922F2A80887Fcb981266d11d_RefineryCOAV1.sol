// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./ITokenMint.sol";
import "./IToken.sol";
import "./IRefinery.sol";
import "./IRates.sol";




contract RefineryCOAV1 is OwnableUpgradeable {
    using SafeMath for uint256;

    struct User {
        //Referral Info
        uint256 upline;
        address wallet_address;
        uint256 referrals;
        uint256 total_structure;
        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;
        //Deposit Accounting
        uint256 deposits;
        uint256 deposit_time;
        //Payout and Roll Accounting
        uint256 payouts;
        uint256 rolls;
        //Upline Round Robin tracking
        uint256 ref_claim_pos;
        uint256 accumulatedDiv;
        
    }

    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }

    struct Custody {
        uint256 manager;
        uint256 beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    address public refineryVaultAddress;
    uint256 public aquiferRef; //1. define the aquifer variable
    address public nftIdTokenAddress; //nftID-1. define the nft Address for the Identification system
    address public aquaTokenAddress; //nftID-1. define the nft Address for the Identification system


    ITokenMint private tokenMint;
    // IToken public xHNWToken;
    IToken public aquaToken;
    RatesController public ratesController;
    IRefineryVault private refineryVault;

    mapping(address => uint256[]) public currentUserId; //nftID-1b. Check is referals turned on for Aquifer
    
    mapping(uint256 => User) public users;
    mapping(uint256 => Airdrop) public airdrops;
    mapping(uint256 => Custody) public custody;

    uint256 public CompoundTax;
    uint256 public ExitTax;

    uint256 private payoutRate;
    uint256 private ref_depth;
    uint256 private ref_bonus;

    uint256 private minimumInitial;
    uint256 private minimumAmount;

    uint256 public deposit_bracket_size; // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    uint256 public max_payout_cap; // 10m HFUEL or 10% of supply
    uint256 private deposit_bracket_max; // sustainability fee is (bracket * 5)

    uint256[] public ref_balances;

    uint256 public total_airdrops;
    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnb;
    uint256 public total_txs;

    uint256 public constant MAX_UINT = 2**256 - 1;

    bool public ref_status; //2. Check is referals turned on for Aquifer
    bool public nftId_status; //nftID-2. Check is referals turned on for Aquifer
    


    event Upline(uint256 indexed addr, address walletAddr,  uint256 indexed upline,  address walletUpline);
    event NewDeposit(uint256 indexed addr, address indexed walletAddr, uint256 amount);
    event Leaderboard(
        uint256 indexed addr,
        address indexed walletAddr,
        uint256 referrals,
        uint256 total_deposits,
        uint256 total_payouts,
        uint256 total_structure
    );
    event DirectPayout(
        uint256 indexed addr,
        address walletAddr,
        uint256 indexed from,
        address walletFrom,
        uint256 amount
    );
    event MatchPayout(
        uint256 indexed addr,
        address walletAddr,
        uint256 indexed from,
        address walletFrom,
        uint256 amount
    );
    event BalanceTransfer(
        uint256 indexed _src,
        address walletSrc,
        uint256 indexed _dest,
        address walletDest,
        uint256 _deposits,
        uint256 _payouts
    );
    event Withdraw(uint256 indexed addr, address walletAddr, uint256 amount);
    event LimitReached(uint256 indexed addr, address walletAddr, uint256 amount);
    event NewAirdrop(
        uint256 indexed from,
        address walletFrom,
        uint256 indexed to,
        address walletTo,
        uint256 amount,
        uint256 timestamp
    );
    event ManagerUpdate(
        uint256 indexed addr,
        address walletAddr,
        uint256 indexed manager,
        address walletManager,
        uint256 timestamp
    );
    event BeneficiaryUpdate(uint256 indexed addr, address walletAddr, uint256 indexed beneficiary, address walletBeneficiary);
    event HeartBeatIntervalUpdate(uint256 indexed addr, address walletAddr, uint256 interval);
    event HeartBeat(uint256 indexed addr, address walletAddr, uint256 timestamp);
    event Checkin(uint256 indexed addr, address walletAddr, uint256 timestamp);

    /* ========== INITIALIZER ========== */
    function initialize() external initializer {
        __Ownable_init();
    }

    //@dev Default payable is empty since Faucet executes trades and recieves BNB
    fallback() external payable {
        //Do nothing, BNB will be sent to contract when selling tokens
    }

    /****** Administrative Functions *******/
    function updatePayoutRate(uint256 _newPayoutRate) public onlyOwner {
        payoutRate = _newPayoutRate;
    }

    function updateRefineryVaultAddress(address _refineryVaultAddress) public onlyOwner {
        refineryVaultAddress = _refineryVaultAddress;
    }
  
    //3. update Aquifer RefAddress
    function updateAquiferRefAddress(uint256 _aquiferRef) public onlyOwner {
        aquiferRef = _aquiferRef;
    }
    //3b. update Aqua TokenAddress
    function updateAquaTokenAddress(address _aquaTokenAddress) public onlyOwner {
        aquaTokenAddress = _aquaTokenAddress;
    }
    //4. update Ref Status switch
    function updateRefStatus(bool _refStatus) public onlyOwner {
        ref_status = _refStatus;
    }

    //nftID-3. update nftIdTokenAddress
    function updateNftIdTokenAddress(address _nftIdTokenAddress) public onlyOwner {
        nftIdTokenAddress = _nftIdTokenAddress;
    }

    //nftID-4. nftId_status switch
    function updateNftIdStatus(bool _nftIdStatus) public onlyOwner {
        nftId_status = _nftIdStatus;
    }
    
    

    function updateRefDepth(uint256 _newRefDepth) public onlyOwner {
        ref_depth = _newRefDepth;
    }

    function updateInitialDeposit(uint256 _newInitialDeposit) public onlyOwner {
        minimumInitial = _newInitialDeposit;
    }

    //update the minimum amount of tokens to deposit
    function updateMinimumAmount(uint256 _newMinimumAmount) public onlyOwner {
        minimumAmount = _newMinimumAmount;
    }

    function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
        require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
        CompoundTax = _newCompoundTax;
    }

    function updateExitTax(uint256 _newExitTax) public onlyOwner {
        require(_newExitTax >= 0 && _newExitTax <= 20);
        ExitTax = _newExitTax;
    }

    function updateDepositBracketSize(uint256 _newBracketSize)
        public
        onlyOwner
    {
        deposit_bracket_size = _newBracketSize;
    }

    function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
        max_payout_cap = _newPayoutCap;
    }

    function updateHoldRequirements(uint256[] memory _newRefBalances)
        public
        onlyOwner
    {
        require(_newRefBalances.length == ref_depth);
        delete ref_balances;
        for (uint8 i = 0; i < ref_depth; i++) {
            ref_balances.push(_newRefBalances[i]);
        }
    }

    //********** User Fuctions **************************************************//
    //////////////////////////////////////////////////////////////////////////////

    function checkin(uint256 _addr) public {
        // uint256 _addr = nftTokenId[msg.sender][]; // edited: msg.sender;
        custody[_addr].last_checkin = block.timestamp;
        emit Checkin(_addr, users[_addr].wallet_address, custody[_addr].last_checkin);
    }

    //@dev Deposit specified HFUEL amount supplying an upline referral
    function deposit(uint256 _upline, uint256 _amount, uint256 _currentUserId) external {
        address _addr = msg.sender;
         aquaToken = IToken(aquaTokenAddress);
        (uint256 realizedDeposit, uint256 taxAmount) = aquaToken.calculateTransferTaxes(_addr, _amount);
        uint256 _total_amount = realizedDeposit;

        //Checkin for custody management.
        checkin(_currentUserId);

        require(_amount >= minimumAmount, "Minimum deposit");

        //If fresh account require a minimal amount of HFUEL
        if (users[_currentUserId].deposits == 0) {
            require(_amount >= minimumInitial, "Initial deposit too low");
             currentUserId[_addr].push(_currentUserId);
             users[_currentUserId].wallet_address = _addr;
        }

        _setUpline(_currentUserId, _upline);

        uint256 taxedDivs;
        // Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_currentUserId) > _amount / 100) {
            uint256 claimedDivs = _claim(_currentUserId, true);
            taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(
                100
            ); // 5% tax on compounding
            _total_amount += taxedDivs;
        }

        //Transfer HFUEL to the contract
        require(
            aquaToken.transferFrom(
                _addr,
                address(refineryVaultAddress),
                _amount
            ),
            "HFUEL token transfer failed"
        );

        /*
        User deposits 10;
        1 goes for tax, 9 are realized deposit
        */
        _deposit(_currentUserId, _total_amount);

        //5% direct commission; only if net positive
        uint256 _up = users[_currentUserId].upline;
        address _upAddress = users[_up].wallet_address;
        if (
            _upAddress != address(0) && isNetPositive(_up) && (isBalanceCovered(_up, 1) || ref_status == false)
        ) {
            uint256 _bonus = _total_amount / 10;

            //Log historical and add to deposits
            users[_up].direct_bonus += _bonus;
            users[_up].deposits += _bonus;

            emit NewDeposit(_up, _upAddress, _bonus);
            emit DirectPayout(_up, _upAddress,_currentUserId, _addr, _bonus);
        }

        _refPayout(_up, taxAmount + taxedDivs);

        emit Leaderboard(
            _currentUserId,
            _addr,
            users[_currentUserId].referrals,
            users[_currentUserId].deposits,
            users[_currentUserId].payouts,
            users[_currentUserId].total_structure
        );
        total_txs++;
    }

    //@dev Claim, transfer, withdraw from vault
    function claim(uint256 _addr) external {
        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin(_addr);

        // address _addr = msg.sender;

        _claim_out(_addr);
    }

    //@dev Claim and deposit;
    function roll(uint256 _addr) public {
        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin(_addr);

        // address _addr = msg.sender;

        _roll(_addr);
    }

    /********** Internal Fuctions **************************************************/

    //@dev Add direct referral and update team structure of upline
    function _setUpline(uint256 _addr, uint256 _upline) internal {
        /*
        1) User must not have existing up-line
        2) Up-line argument must not be equal to senders own address
        3) Senders address must not be equal to the owner
        4) Up-lined user must have a existing deposit
        */

        /*
            5. Check for referral status, if off, set all uplines to Team address
        */
        if(ref_status == false){
            _upline = aquiferRef;
        }

        if (
            (users[_upline].wallet_address == address(0) || _upline == aquiferRef) &&
            // users[_addr].upline == address(0) &&
            _upline != _addr &&
            users[_addr].wallet_address != owner() &&
            (users[_upline].deposit_time > 0 ||  users[_upline].wallet_address == owner())
        ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, users[_addr].wallet_address,  _upline, users[_upline].wallet_address);

            total_users++;

            for (uint8 i = 0; i < ref_depth; i++) {
                if ( users[_upline].wallet_address == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    //@dev Deposit
    function _deposit(uint256 _addr,  uint256 _amount) internal {
        //Can't maintain upline referrals without this being set
        uint _upline = users[_addr].upline;
        
        require(
            users[_upline].wallet_address != address(0) || users[_upline].wallet_address == owner(),
            "No upline"
        );

        //stats
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = block.timestamp;

        total_deposited += _amount;

        //events
        // emit NewDeposit(_addr, _amount);
        emit NewDeposit(_addr, users[_addr].wallet_address, _amount);
    }

    //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help
    function _refPayout(uint256 _addr, uint256 _amount) internal {
        uint256 up = users[_addr].upline;

        for (uint8 i = 0; i < ref_depth; i++) {
            //15 max depth
            if (users[up].wallet_address == address(0)) break;

            if (isNetPositive(up) && (isBalanceCovered(up, i + 1) || ref_status == false)) {
                uint256 refBonus = ratesController.getRefBonus(i);
                uint256 bonus = (_amount * refBonus) / 1000;

                users[up].deposits += bonus;

                users[up].match_bonus += bonus;

                // emit NewDeposit(up, bonus);
                 emit NewDeposit(up, users[up].wallet_address, bonus);
                emit MatchPayout(up,  users[up].wallet_address, _addr, users[_addr].wallet_address, bonus);
            }

            up = users[up].upline;
        }
    }

    //@dev General purpose heartbeat in the system used for custody/management planning
    function _heart(uint256 _addr) internal {
        custody[_addr].last_heartbeat = block.timestamp;
        emit HeartBeat(_addr, users[_addr].wallet_address, custody[_addr].last_heartbeat);
    }

    //@dev Claim and deposit;
    function _roll(uint256 _addr) internal {
        uint256 to_payout = _claim(_addr, false);

        uint256 payout_taxed = to_payout
            .mul(SafeMath.sub(100, CompoundTax))
            .div(100); // 5% tax on compounding

        //Recycle baby!
        _deposit(_addr, payout_taxed);

        //track rolls for net positive
        users[_addr].rolls += payout_taxed;

        emit Leaderboard(
            _addr,
            users[_addr].wallet_address,
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
        total_txs++;
    }

    //@dev Claim, transfer, and topoff
    function _claim_out(uint256 _addr) internal {
        uint256 to_payout = _claim(_addr, true);
        aquaToken = IToken(aquaTokenAddress);
        
        uint256 vaultBalance = aquaToken.balanceOf(refineryVaultAddress);
        if (vaultBalance < to_payout) {
            uint256 differenceToMint = to_payout.sub(vaultBalance);
            tokenMint.mint(refineryVaultAddress, differenceToMint);
        }

        refineryVault.withdraw(to_payout);

        uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(
            100
        ); // 15% tax on withdraw
        require(aquaToken.transfer(address(msg.sender), realizedPayout));

        emit Leaderboard(
            _addr,
             users[_addr].wallet_address,
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
        total_txs++;
    }

    //@dev Claim current payouts
    function _claim(uint256 _addr, bool isClaimedOut)
        internal
        returns (uint256)
    {
          // authentication
        require(msg.sender == users[_addr].wallet_address, "Invalid wallet connected");
        (
            uint256 _gross_payout,
            uint256 _max_payout,
            uint256 _to_payout,
            uint256 _sustainability_fee
        ) = payoutOf(_addr);
        require(users[_addr].payouts < _max_payout, "Full payouts");

        // Deposit payout
        if (_to_payout > 0) {
            // payout remaining allowable divs if exceeds
            if (users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }

            users[_addr].payouts += _gross_payout;

            if (!isClaimedOut) {
                //Payout referrals
                uint256 compoundTaxedPayout = _to_payout
                    .mul(SafeMath.sub(100, CompoundTax))
                    .div(100); // 5% tax on compounding

                _refPayout(_addr, compoundTaxedPayout);
            }
        }

        require(_to_payout > 0, "Zero payout");

        //Update the payouts
        total_withdraw += _to_payout;

        //Update time!
        users[_addr].deposit_time = block.timestamp;
        users[_addr].accumulatedDiv = 0;

        emit Withdraw(_addr,  users[_addr].wallet_address, _to_payout);

        if (users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].wallet_address, users[_addr].payouts);
        }

        return _to_payout;
    }

    /********* Views ***************************************/

    //@dev Returns true if the address is net positive
    function isNetPositive(uint256 _addr) public view returns (bool) {
        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

        return _credits > _debits;
    }

    //@dev Returns the total credits and debits for a given address
    function creditsAndDebits(uint256 _addr)
        public
        view
        returns (uint256 _credits, uint256 _debits)
    {
        User memory _user = users[_addr];
        Airdrop memory _airdrop = airdrops[_addr];

        _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
        _debits = _user.payouts;
    }

    //@dev Returns whether BR34P balance matches level
    function isBalanceCovered(uint256 _addr, uint8 _level)
        public
        view
        returns (bool)
    {
        if (users[users[_addr].upline].wallet_address == address(0)) {
            return true;
        }
        return balanceLevel(users[_addr].wallet_address) >= _level;
    }

    //@dev Returns the level of the address
    function balanceLevel(address _addr) public view returns (uint8) {
        uint8 _level = 0;
        for (uint8 i = 0; i < ref_depth; i++) {
            if (aquaToken.balanceOf(_addr) < ref_balances[i]) break;
            _level += 1;
        }

        return _level;
    }

    //@dev Returns custody info of _addr
    function getCustody(uint256 _addr)
        public
        view
        returns (
            uint256 _beneficiary,
            uint256 _heartbeat_interval,
            uint256 _manager
        )
    {
        return (
            custody[_addr].beneficiary,
            custody[_addr].heartbeat_interval,
            custody[_addr].manager
        );
    }

    //@dev Returns account activity timestamps
    function lastActivity(uint256 _addr)
        public
        view
        returns (
            uint256 _heartbeat,
            uint256 _lapsed_heartbeat,
            uint256 _checkin,
            uint256 _lapsed_checkin
        )
    {
        _heartbeat = custody[_addr].last_heartbeat;
        _lapsed_heartbeat = block.timestamp.safeSub(_heartbeat);
        _checkin = custody[_addr].last_checkin;
        _lapsed_checkin = block.timestamp.safeSub(_checkin);
    }

    //@dev Returns amount of claims available for sender
    function claimsAvailable(uint256 _addr) public view returns (uint256) {
        (
            uint256 _gross_payout,
            uint256 _max_payout,
            uint256 _to_payout,
            uint256 _sustainability_fee
        ) = payoutOf(_addr);
        return _to_payout;
    }

    //@dev Maxpayout of 3.65 of deposit

    function maxPayoutOf(uint256 _addr, uint256 _amount)
        public
        view
        returns (uint256)
    {
         address _walletAddress = users[_addr].wallet_address;
        //return _amount * 365 / 100;
        uint256 maxpayout = ratesController.getMaxPayOut(_walletAddress, _amount);
        return maxpayout;
    }

    function sustainabilityFeeV2(uint256 _addr, uint256 _pendingDiv)
        public
        view
        returns (uint256)
    {
        uint256 _bracket = users[_addr].payouts.add(_pendingDiv).div(
            deposit_bracket_size
        );
        _bracket = SafeMath.min(_bracket, deposit_bracket_max);
        return _bracket * 5;
    }

    //@dev calculates payout for a given address based off SK balance
    //todo integrate this into the actual payout functions
    function payOutRateOf(address _addr) public view returns (uint256) {
        uint256 rate = ratesController.payOutRateOf(_addr);
        return rate;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(uint256 _addr)
        public
        view
        returns (
            uint256 payout,
            uint256 max_payout,
            uint256 net_payout,
            uint256 sustainability_fee
        )
    {
        //The max_payout is capped so that we can also cap available rewards daily
        address _walletAddress = users[_addr].wallet_address;

        max_payout = maxPayoutOf(_addr, users[_addr].deposits).min(
            max_payout_cap
        );

        uint256 share;

        if (users[_addr].payouts < max_payout) {
            //Using 1e18 we capture all significant digits when calculating available divs
            share = users[_addr]
                .deposits
                .mul(payOutRateOf(_walletAddress))
                .div(100e18)
                .div(24 hours); //divide the profit by payout rate and seconds in the day

            payout = share * block.timestamp.safeSub(users[_addr].deposit_time);

            payout += users[_addr].accumulatedDiv;

            // payout remaining allowable divs if exceeds
            if (users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }

            uint256 _fee = sustainabilityFeeV2(_addr, payout);

            sustainability_fee = (payout * _fee) / 100;

            net_payout = payout.safeSub(sustainability_fee);
        }
    }

    //@dev Get current user snapshot
    function userInfo(uint256 _addr)
        external
        view
        returns (
            uint256 upline,
            uint256 deposit_time,
            uint256 deposits,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 match_bonus,
            uint256 last_airdrop
        )
    {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus,
            airdrops[_addr].last_airdrop
        );
    }

    //@dev Get user totals
    function userInfoTotals(uint256 _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 total_deposits,
            uint256 total_payouts,
            uint256 total_structure,
            uint256 airdrops_total,
            uint256 airdrops_received
        )
    {
        return (
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure,
            airdrops[_addr].airdrops,
            airdrops[_addr].airdrops_received
        );
    }

    //@dev Get contract snapshot
    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw,
            uint256 _total_bnb,
            uint256 _total_txs,
            uint256 _total_airdrops
        )
    {
        return (
            total_users,
            total_deposited,
            total_withdraw,
            total_bnb,
            total_txs,
            total_airdrops
        );
    }

    /////// Airdrops ///////

    //@dev Send specified HFUEL amount supplying an upline referral
    function airdrop(uint256 _currentWalletId, uint256 _to, uint256 _amount) external {
        // authentication
        require(msg.sender == users[_currentWalletId].wallet_address, "Invalid wallet connected");
        aquaToken = IToken(aquaTokenAddress);
        address _addr = msg.sender;
        
        (uint256 _realizedAmount, uint256 taxAmount) = aquaToken
            .calculateTransferTaxes(_addr, _amount);
        //This can only fail if the balance is insufficient
        require(
            aquaToken.transferFrom(
                _addr,
                address(refineryVaultAddress),
                _amount
            ),
            "HFUEL to contract transfer failed; check balance and allowance, airdrop"
        );

        //Make sure _to exists in the system; we increase
        require(users[users[_to].upline].wallet_address != address(0), "_to not found");

        (uint256 gross_payout, , , ) = payoutOf(_to);

        users[_to].accumulatedDiv = gross_payout;

        //Fund to deposits (not a transfer)
        users[_to].deposits += _realizedAmount;
        users[_to].deposit_time = block.timestamp;

        //User stats
        airdrops[_currentWalletId].airdrops += _realizedAmount;
        airdrops[_currentWalletId].last_airdrop = block.timestamp;
        airdrops[_to].airdrops_received += _realizedAmount;

        //Keep track of overall stats
        total_airdrops += _realizedAmount;
        total_txs += 1;

        //Let em know!
        emit NewAirdrop(_currentWalletId, _addr, _to, users[_to].wallet_address, _realizedAmount, block.timestamp);
        // emit NewDeposit(_to, _realizedAmount);
        emit NewDeposit(_to, users[_to].wallet_address, _realizedAmount);
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

/*
    SPDX-License-Identifier: MIT
    Copyright 2022
*/

pragma solidity ^0.8.4;


interface IToken {
    function remainingMintableSupply() external view returns (uint256);

    function calculateTransferTaxes(address _from, uint256 _value) external returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function mintedSupply() external returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

/*
    SPDX-License-Identifier: MIT
    Copyright 2022
*/

pragma solidity ^0.8.4;



interface ITokenMint {

    function mint(address beneficiary, uint256 tokenAmount) external returns (uint256);

    function estimateMint(uint256 _amount) external returns (uint256);

    function remainingMintableSupply() external returns (uint256);
}

/*
    SPDX-License-Identifier: MIT
    SideKick Finance
    High Net Worth
    Copyright 2022
*/

pragma solidity ^0.8.4;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/*
    SPDX-License-Identifier: MIT
    Copyright 2022
*/

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract RatesController is Ownable {
    using SafeMath for uint256;
    IERC20 public xSK_Token; //SK
    IERC20 public xHNW_Token; //XHNW

    uint256[4] public xSKBalances;
    uint256[5] public xHNWBalances;

    uint256[5] public rates;
    uint16[6] public maxPayOutRates;
    uint256[15] public refBonuses;

    constructor(address _xSK_Token, address _xHNW_Token) {
        xSK_Token = IERC20(_xSK_Token); //holding token = sidekick token
        xHNW_Token = IERC20(_xHNW_Token); // = XHNW token

        //set sk balances
        xSKBalances[0] = 400e18;
        xSKBalances[1] = 2000e18;
        xSKBalances[2] = 10000e18;
        xSKBalances[3] = 50000e18;

        //assign rates values -- from 0.7 to 1.0 -- rates for holding SK
        rates[0] = 80e16; //0.8
        rates[1] = 90e16; //0.9
        rates[2] = 100e16; //1
        rates[3] = 110e16; //1.1
        rates[4] = 120e16; //1.2

        //set xHNW balances
        xHNWBalances[0] = 50e18;
        xHNWBalances[1] = 100e18;
        xHNWBalances[2] = 150e18;
        xHNWBalances[3] = 200e18;
        xHNWBalances[4] = 250e18;

        //assign maxPayOutRates values -- from 255 to 365 -- rates for holding xHNW
        maxPayOutRates[0] = 255;
        maxPayOutRates[1] = 277;
        maxPayOutRates[2] = 300;
        maxPayOutRates[3] = 321;
        maxPayOutRates[4] = 343;
        maxPayOutRates[5] = 365;

        refBonuses[0] = 20; // start at 10
        refBonuses[1] = 21; //2.1
        refBonuses[2] = 22; //2.1
        refBonuses[3] = 23; //2.1
        refBonuses[4] = 24; //2.1
        refBonuses[5] = 25; //2.1
        refBonuses[6] = 26; //2.1
        refBonuses[7] = 27; //2.1
        refBonuses[8] = 28; //2.1
        refBonuses[9] = 29; //2.1
        refBonuses[10] = 30; //2.1
        refBonuses[11] = 31; //2.1
        refBonuses[12] = 32; //2.1
        refBonuses[13] = 33; //2.1
        refBonuses[14] = 34;
    }

    function setToken1(address tokenAddress) public onlyOwner {
        xSK_Token = IERC20(tokenAddress);
    }

    function setToken2(address tokenAddress) public onlyOwner {
        xHNW_Token = IERC20(tokenAddress);
    }

    function setToken1Balances(uint256[4] memory _balances) public onlyOwner {
        xSKBalances = _balances;
    }

    function setToken2Balances(uint256[5] memory _balances) public onlyOwner {
        xHNWBalances = _balances;
    }

    //set new rates function
    function setRates(uint256[5] memory _rates) public onlyOwner {
        rates = _rates;
    }

    //set new maxPayOutRates function
    function setMaxPayOutRates(uint16[6] memory _maxPayOutRates)
        public
        onlyOwner
    {
        maxPayOutRates = _maxPayOutRates;
    }

    function setRefBonuses(uint256[15] memory _refBonuses) public onlyOwner {
        refBonuses = _refBonuses;
    }

    function payOutRateOf(address _addr) public view returns (uint256) {
        uint256 balance = xSK_Token.balanceOf(_addr);
        uint256 rate;

        if (balance < xSKBalances[0]) {
            rate = rates[0];
        }
        if (balance >= xSKBalances[0] && balance < xSKBalances[1]) {
            rate = rates[1];
        }
        if (balance >= xSKBalances[1] && balance < xSKBalances[2]) {
            rate = rates[2];
        }
        if (balance >= xSKBalances[2] && balance < xSKBalances[3]) {
            rate = rates[3];
        }
        if (balance >= xSKBalances[3]) {
            rate = rates[4];
        }

        return rate;
    }

    function getMaxPayOut(address _user, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 balance = xHNW_Token.balanceOf(_user);
        uint256 maxPayOut;
        if (balance < xHNWBalances[0]) {
            maxPayOut = (amount * maxPayOutRates[0]) / 100;
        }
        if (balance >= xHNWBalances[0] && balance < xHNWBalances[1]) {
            maxPayOut = (amount * maxPayOutRates[1]) / 100;
        }
        if (balance >= xHNWBalances[1] && balance < xHNWBalances[2]) {
            maxPayOut = (amount * maxPayOutRates[2]) / 100;
        }
        if (balance >= xHNWBalances[2] && balance < xHNWBalances[3]) {
            maxPayOut = (amount * maxPayOutRates[3]) / 100;
        }
        if (balance >= xHNWBalances[3] && balance < xHNWBalances[4]) {
            maxPayOut = (amount * maxPayOutRates[4]) / 100;
        }
        if (balance >= xHNWBalances[4]) {
            maxPayOut = (amount * maxPayOutRates[5]) / 100;
        }
        return maxPayOut;
    }

    function getRefBonus(uint8 level) public view returns (uint256) {
        return refBonuses[level];
    }
}

/*
    SPDX-License-Identifier: MIT
    SideKick Finance
    High Net Worth
    Copyright 2022
*/

pragma solidity ^0.8.4;


interface IRefineryVault {

    function withdraw(uint256 tokenAmount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/*
    SPDX-License-Identifier: MIT
    Copyright 2022
*/

pragma solidity ^0.8.4;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
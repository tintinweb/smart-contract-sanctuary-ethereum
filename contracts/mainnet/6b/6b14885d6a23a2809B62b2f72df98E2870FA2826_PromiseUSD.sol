//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";

interface IPromiseUSD {
    function setApprovedContract(address Contract, bool _isApproved) external;
    function mint(uint256 amountUnderlyingAsset) external returns (bool);
    function takeLoan(uint256 ID, address desiredStable, uint256 amount) external returns (uint256);
    function takeLoan(address desiredStable, uint256 amount) external returns (uint256);
    function burnCollateral(uint256 ID, uint256 amount) external;
    function makePayment(uint256 ID, uint256 amountUSD) external returns (uint256);
}

interface IXUSD {
    function stableAssets(address stable) external view returns (bool,bool,uint8);
    function requestPromiseTokens(address stable, uint256 amount) external returns (uint256);
    function burn(uint256 amount) external;
}

/**
    XUSD's Lending Token

    Over 1:1 Tied With USD
        - Total Supply = USD To Be Repaid
        - Total Locked = XUSD Held As Collateral

        Total Locked should always be worth more than Total Supply

    Locks XUSD Inside Of Itself And Redeems Its USD Without Burning Its Supply
    Can Only Release XUSD If USD Debt Is Repaid

    Intended to be a bare bones contract that does not implement any specific functionality
    But enables approved contracts to utilize itself to benefit XUSD.

    On its own pUSD is price neutral for XUSD, but if used correctly it can be used to bring
    external profits into the system via lending, leveraged yield farming, and other services
*/
contract PromiseUSD is IERC20 {

    using SafeMath for uint256;
    
    // Relevant Tokens
    address public XUSD;

    // Token Data
    string private constant _name = "PromiseUSD";
    string private constant _symbol = "pUSD";
    uint8 private constant _decimals = 18;
    
    // 0 Initial
    uint256 private _totalSupply = 0;

    // total XUSD locked
    uint256 public totalLocked = 0;

    // Tracks USD lent vs collateral collected
    struct Promise {
        uint256 debt;
        uint256 collateral;
    }
    
    // User -> ID -> Promise
    mapping ( address => mapping ( uint256 => Promise ) ) public userPromise;

    // User -> Current ID ( nonce )
    mapping ( address => uint256 ) public nonces;

    /**
        Allows Platforms + Models To Implement Lending And Preserve Upgradability
        Being Forced To Preserve The Truths Enforced In This Smart Contract
        With LeeWay For Adding External Fees And Usability
    */
    mapping ( address => bool ) public isApproved;

    // Approved Contracts Only
    modifier onlyApproved(){
        require(isApproved[msg.sender], 'Only Approved Miners');
        _;
    }

    // Only XUSD Itself
    modifier onlyXUSD(){
        require(msg.sender == XUSD, 'Only XUSD');
        _;
    }

    // Events
    event CollateralBurned(uint XUSDBurned, uint pUSDBurned);
    event PromisePaymentReceived(uint usdReceived, uint xusdRedeemed);
    event PromiseCreated(address user, uint usdBorrowed, uint xusdCollateral);
    event ContractApproval(address newContract, bool _isApproved);

    // Necessary Token Data
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return account == XUSD ? _totalSupply : 0; }
    function allowance(address holder, address spender) external pure override returns (uint256) { holder; spender; return 0; }
    function name() public pure override returns (string memory) {
        return _name;
    }
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        sender;
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        sender; recipient; amount;
        emit Transfer(sender, recipient, 0);
        return false;
    }

    /**
        Pairs XUSD With Its Current Contract
        Can Only Be Performed Once
     */
    function pairXUSD(address XUSD_) external {
        require(
            XUSD == address(0) &&
            XUSD_ != address(0),
            'Already Paired'
        );
        XUSD = XUSD_;
    }

    /**
        Approves External Contract To Utilize pUSD
        NOTE: Only XUSD Can Call This Function
    */
    function setApprovedContract(address Contract, bool _isApproved) external onlyXUSD {
        isApproved[Contract] = _isApproved;
        emit ContractApproval(Contract, _isApproved);
    }

    /**
        Burns XUSD Held As Collateral, Reduces Debt in proportion to burn amount
        Allowing an approved contract to burn their locked XUSD and associated pUSD tokens

        @param ID - nonce for calling contract to burn from
        @param amount - amount of XUSD to burn
    */
    function burnCollateral(uint256 ID, uint256 amount) external onlyApproved {
        require(
            userPromise[msg.sender][ID].collateral > 0 && 
            userPromise[msg.sender][ID].collateral >= amount, 
            'Insufficient Collateral'
        );
        
        // BE SURE TO BURN APPROPRIATE AMOUNT OF pUSD AFTER SO XUSD DOES NOT OVER-VALUE ITSELF
        uint256 burnAmount = ( amount * userPromise[msg.sender][ID].debt ) / userPromise[msg.sender][ID].collateral;

        // reduce collateral
        userPromise[msg.sender][ID].collateral = userPromise[msg.sender][ID].collateral.sub(amount, 'Underflow');
        // reduce total locked
        totalLocked -= amount;

        // reduce debt
        userPromise[msg.sender][ID].debt = userPromise[msg.sender][ID].debt.sub(burnAmount, 'Debt Underflow');

        // burn XUSD amount
        IXUSD(XUSD).burn(amount);

        // reduce pUSD amount in relation to XUSD tokens burned to not overinflate pUSD backing in XUSD
        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(XUSD, address(0), burnAmount);
        emit CollateralBurned(amount, burnAmount);
    }
    
    /**
        Repayes the debt tracked by `ID` in `stable`, and releases locked XUSD 
        Back to the user who staked the XUSD in the first place, proportional to
        how much debt has been repaid
        Can only be triggered by Approved Contracts

        @param ID - ID or nonce of calling contract to repay
        @param stable - Stable Coin to make payment in, must be approved stable
        @param amountStable - amount of USD stable coins to make the payment for
     */
    function makePayment(uint256 ID, address stable, uint256 amountStable) external onlyApproved returns (uint256) {
        require(
            canRepayWith(stable),
            'Cannot Repay With This Stable'
        );
        return _makePayment(msg.sender, ID, stable, amountStable);
    }

    /**
        Takes XUSD As Collateral and releases its underlying USD Without Deleting Tokens
        pUSD is minted to XUSD to sustain its price

        @param ID - nonce of sender, should be tracked by calling contract
        @param collateral - Amount of XUSD to lock up and borrow from
        @return ID - The ID Utilized For This Loan
    */
    function takeLoan(uint256 ID, address desiredStable, uint256 collateral) external onlyApproved returns (uint256) {
        require(!IDInUse(msg.sender, ID), 'ID in Use');
        _takeLoan(ID, desiredStable, collateral);
        nonces[msg.sender]++;
        return ID;
    }

    /**
        Takes XUSD As Collateral and releases its underlying USD Without Deleting Tokens
        pUSD is minted to XUSD to sustain its price
        It's up to the implementing smart contract to add a fee to this system to benefit XUSD
        there is no intrinsic benefit to this contract or function alone, what is built from it
        however has all the potential

        This uses the calling contract's current nonce and increments it
        @param collateral - Amount of XUSD to lock up and borrow from
        @return ID - The ID Utilized For This Loan
    */
    function takeLoan(address desiredStable, uint256 collateral) external onlyApproved returns (uint256) {
        uint ID = nonces[msg.sender];
        require(!IDInUse(msg.sender, ID), 'ID in Use');
        _takeLoan(ID, desiredStable, collateral);
        nonces[msg.sender]++;
        return ID;
    }

    /**
        Sets calling contract's nonce in the event of a mistake
        NOTE: Calling contracts should implement a way to track nonce's across multiple users

        @param nonce - nonce to set for the calling contract
     */
    function setNonce(uint256 nonce) external onlyApproved {
        nonces[msg.sender] = nonce;
    }

    /**
        Whehter or not the nonce of a calling contract is in use or not
     */
    function IDInUse(address borrower, uint256 ID) public view returns (bool) {
        return userPromise[borrower][ID].collateral > 0 || userPromise[borrower][ID].debt > 0;
    }

    /**
        Repayes the debt tracked by `ID` in USD, and releases the XUSD 
        Back to the user who staked the XUSD in the first place
     */
    function _makePayment(address user, uint256 ID, address stable, uint256 amountUSD) internal returns (uint256 amountCollateral) {
        require(userPromise[user][ID].debt > 0, 'Zero Debt');
        require(amountUSD <= userPromise[user][ID].debt && amountUSD > 0, 'Invalid Amount');
        
        // transfer in USD
        uint256 received = _transferIn(stable, amountUSD);

        // Repay USD Amount To XUSD
        bool s = IERC20(stable).transfer(XUSD, received);
        require(s, 'Failure On USD Transfer');

        // Burn pUSD Supply
        _totalSupply = _totalSupply.sub(received, 'Underflow');
        emit Transfer(XUSD, address(0), received);

        // check debt and locked XUSD Amount
        if (userPromise[user][ID].debt <= received) {

            // clear collateral
            amountCollateral = userPromise[user][ID].collateral;
            _release(ID, user, amountCollateral);

            // emit event
            emit PromisePaymentReceived(amountUSD, amountCollateral);

            // free storage
            delete userPromise[user][ID];

        } else {

            // get portion of remaining debt
            amountCollateral = ( userPromise[user][ID].collateral * received ) / userPromise[user][ID].debt;

            // update remaining debt and supply
            userPromise[user][ID].debt = userPromise[user][ID].debt.sub(received, 'Underflow');

            // clear collateral
            _release(ID, user, amountCollateral);

            // emit event
            emit PromisePaymentReceived(received, amountCollateral);
        }
    }

    /**
        Takes XUSD As Collateral and releases its underlying USD Without Deleting Tokens
        pUSD is minted to XUSD to sustain its price
    */
    function _takeLoan(uint256 ID, address desiredStable, uint256 collateral) internal {

        // transfer in XUSD
        uint256 xReceived = _transferIn(XUSD, collateral);

        // set collateral
        userPromise[msg.sender][ID].collateral = xReceived;

        // increment total locked
        totalLocked = totalLocked.add(xReceived);

        // sells XUSD tax exempt, calls back to mint to create an equal amount of pUSD as USD that is removed
        uint256 received = IXUSD(XUSD).requestPromiseTokens(desiredStable, xReceived);
        require(
            received > 0 && 
            IERC20(desiredStable).balanceOf(address(this)) >= received,
            'XUSD Promise Request Failed'
        );

        // set debt
        userPromise[msg.sender][ID].debt = received;

        // send USD to caller
        require(
            IERC20(desiredStable).transfer(msg.sender, received),
            'Stable Transfer Failure'
        );

        // emit event
        emit PromiseCreated(msg.sender, received, xReceived);
    }

    /**
        Function Triggered By XUSD Itself
        After XUSD Calculates It's USD Amount To Redeem
        It Must Be Minted pUSD So RequireProfit Does Not Fail
        XUSD Will Send USD Into pUSD, assuming it does not ask for too much
        pUSD will Route USD To Desired Source, and Lock the XUSD Received

        XUSD May Only Be Unlocked From USD Being Repaid

    */
    function mint(uint256 amount) external onlyXUSD returns (bool) {
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), XUSD, amount);
        return true;
    }

    /**
        Transfers in `amount` of `token` from the sender of the message
     */
    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        uint256 before = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 received = IERC20(token).balanceOf(address(this)).sub(before, 'Underflow');
        require(s && received <= amount && received > 0, 'Transfer Error');
        return received;
    }

    /**
        Unlocks XUSD For User
        Reduces Collateral
    */
    function _release(uint256 ID, address to, uint256 amount) internal {

        bool s;
        // ensure token transfer success
        if (userPromise[to][ID].collateral <= amount) { // collateral is paid back
            // transfer collateral to owner
            s = IERC20(XUSD).transfer(to, userPromise[to][ID].collateral);
            // decrement total locked
            totalLocked = totalLocked.sub(userPromise[to][ID].collateral, 'Total Locked Underflow');
            // reset storage
            delete userPromise[to][ID];
        } else {                                        // only part of collateral is paid back
            // update collateral
            userPromise[to][ID].collateral = userPromise[to][ID].collateral.sub(amount, 'Underflow');
            // transfer XUSD
            s = IERC20(XUSD).transfer(to, amount); 
            // decrement total locked
            totalLocked = totalLocked.sub(amount, 'Total Locked Underflow');
        }
        // require success
        require(s, 'XUSD Transfer Failure');
    }

    /**
        True If `stable` is Approved and minting is not disabled, False otherwise
     */
    function canRepayWith(address stable) public view returns (bool) {
        (bool approved, bool mintDisabled,) = IXUSD(XUSD).stableAssets(stable);
        return approved && !mintDisabled;
    }

}
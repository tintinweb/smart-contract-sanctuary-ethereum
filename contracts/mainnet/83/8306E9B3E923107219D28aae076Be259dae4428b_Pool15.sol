// contracts/Pool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777Rewardable.sol";
import './../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking4.sol';
import './../PoolStakingRewards/PoolStakingRewards3.sol';
import './../HomeBoost/HomeBoost0.sol';
import './../CurveInterface/ICurvePool.sol';

import "./../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
// import "../../node_modules/hardhat/console.sol";


contract Pool15 is Initializable, ERC20UpgradeableFromERC777Rewardable, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    event Borrow(address indexed borrower, uint64 indexed property, uint64 indexed loan, uint128 amount, uint64 rate);
    event Repay(address indexed payer, uint64 indexed loan, uint128 principal, uint128 interest, uint128 principalPaid, uint128 interestPaid);

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;

    // Address of the ERC-20 contract used as liquidity supply. USDC for now.
    address ERCAddress;

    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent; // Deprecated in Pool14. Now always set to 0.
    uint256 poolBorrowed; // Deprecated in Pool14. Now always set to 0.
    mapping(address => uint256[]) userLoans;
    Loan[] loans;
    uint256 loanCount;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 1000000;
    uint constant curveK = 120000000;

    /* Pool1 variables introduced here */
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) loanToPropToken;
    address propTokenContractAddress;

    /* Pool2 variables introduced here */
    address LTVOracleAddress;

    /* Pool3 variables introduced here */
    address poolUtilsAddress;
    address baconCoinAddress;
    address poolStakingAddress;

    /* Pool 8 variables introduced here */
    address daoAddress;

    /*  Pool 9 variables introduced here
        storage for nonReentrant modifier
        modifier and variables could not be imported via inheratance given upgradability rules */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /* pool10 variables added here */
    address poolStakingRewardAddress; // contract responsible for determining the rewards for staking HOME

    /*  Pool 11 variables introduced here */
    bool airdropLocked;

    /* Pool 13 variables here */
    address homeBoostAddress;

    /* Pool 14 variables here */
    address curvePoolAddress;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    function lockAirdorp() public {
        require(msg.sender == servicer);
        airdropLocked = true;
    }

    function passServicerRights(address _servicer) public {
        require(msg.sender == servicer);
        servicer = _servicer;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/
    /**
    *   @dev Function getContractData() returns a lot of variables about the contract
    */
    function getContractData() public view returns (address, address, uint256, uint256, uint256, uint256) {
        return (
            servicer,
            ERCAddress,
            0,
            PoolUtils0(poolUtilsAddress).getPoolInterestAccrued(),
            totalSupply(),
            loanCount);
    }

    /*
    *   @dev Function getLoanCount() returns how many active loans there are
    */
    function getLoanCount() public view returns (uint256) {
        return loanCount;
    }

    /**
    *   @dev Function getSupplyableTokenAddress() returns the contract address of ERC20 this pool accepts (ususally USDC)
    */
    function getSupplyableTokenAddress() public view returns (address) {
        return ERCAddress;
    }

    /**
    *   @dev Function getServicerAddress() returns the address of this pool's servicer
    */
    function getServicerAddress() public view returns (address) {
        return servicer;
    }

    /**
    *   @dev Function getLoanDetails() returns an all the raw details about a loan
    *   @param loanId is the id for the loan we're looking up
    *   EDITED in pool1 to also return PropToken ID
    */
    function getLoanDetails(uint256 loanId) public view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        Loan memory loan = loans[loanId];
        uint256 interestAccrued = getLoanAccruedInterest(loanId);
        uint256 propTokenID = loanToPropToken[loanId];
        return (loan.loanId, loan.borrower, loan.interestRate, loan.principal, interestAccrued, loan.timeLastPayment, propTokenID);
    }

    /**
    *   @dev Function getLoanAccruedInterest() calculates and returns the amount of interest accrued on a given loan
    *   @param loanId is the id for the loan we're looking up
    */
    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 secondsSincePayment = block.timestamp.sub(loan.timeLastPayment);

        // 31,104,000 is number of seconds per year (360 * 24 * 60 * 60)
        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31_104_000);

        // Interest rates are stored in fixed point as numbers and not percentages.
        // For example, 12% is 12_000000 (12.0) not 0_120000 (0.12).
        // To do math with them, you often need to divide by 100 (100_000000) after.

        // Divide by 100 for interest rate adjustment and 1_000000 for fixed point adjustment.
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100_000000);

        return interestAccrued.add(loan.interestAccrued);
    }


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    function lendPool(
        uint256 amountUsdc,
        uint256 expectedHomeCoin
    ) public nonReentrant returns (uint256) {
        IERC20Upgradeable usdcCoin = IERC20Upgradeable(ERCAddress);
        usdcCoin.transferFrom(msg.sender, address(this), amountUsdc);
        usdcCoin.approve(curvePoolAddress, amountUsdc);
        
        ICurve curve = ICurve(curvePoolAddress);
        // 2 is USDC. 0 is HomeCoin. All of this is terrible.
        uint256 rez = curve.exchange_underlying(2, 0, amountUsdc, expectedHomeCoin, msg.sender);

        return rez;
    }


    /**
    *   @dev Function lend moves assets on the (probably usdc) contract to our own balance
    *   - Before calling: an approve(address _spender (proxy), uint256 _value (0xffff)) function call must be made on remote contract
    *   @param amount The amount of USDC to be transferred
    *   @return the amount of poolTokens created
    */
    function lend(
        uint256 amount
    ) public nonReentrant returns (uint256) {
        require(false, "lend is disabled. Use lendPool");
    }

    function redeemPool(
        uint256 amountHome,
        uint256 expectedUsdc
    ) public nonReentrant returns (uint256) {
        require(balanceOf(msg.sender) >= amountHome, "HOME balance insufficient");

        super._transfer(msg.sender, address(this), amountHome);
        super._approve(address(this), curvePoolAddress, amountHome);

        ICurve curve = ICurve(curvePoolAddress);
        // 2 is USDC. 0 is HomeCoin. All of this is terrible.
        uint256 rez = curve.exchange_underlying(0, 2, amountHome, expectedUsdc, msg.sender);

        return rez;
    }


    /**
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public nonReentrant {
        require(false, "Use redeemPool");
    }

    /**
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param fixedInterestRate The rate for the loan.
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    *   EDITED in pool14 - now lends HOME instead of USDC
    */
    function borrow(uint256 amount, uint256 fixedInterestRate, uint256 propTokenId) public nonReentrant {
        // require this address is approved to transfer propToken
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");

        // [TODO] Consider upgrading PropToken to trust the PoolCore always so approval doesn't have to be done.
        // also require msg.sender is owner of token.
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        require(fixedInterestRate > 1_000000, "rate must not be less than 1%");

        // [TODO] Change the interest rate calculation code. Remove the AMM.
        // check the requested interest rate is still available
        // uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        // require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        // require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        // require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");

        // create new Loan
        loans.push(Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp));

        // index the loan to the wallet
        userLoans[msg.sender].push(loanCount);

        // map new Loan ID to Token ID
        loanToPropToken[loanCount] = propTokenId;
        loanCount = loanCount.add(1);

        // take the propToken and hold it in the Pool
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        // Finally mint HOME. 99% to the borrower. 0.5% to servicer. 0.5% to DAO.
        super._mint(msg.sender, amount.mul(99).div(100));
        super._mint(servicer, amount.div(200));
        super._mint(daoAddress, amount.div(200));

        emit Borrow(msg.sender, uint64(propTokenId), uint64(loanCount.sub(1)), uint128(amount), uint64(fixedInterestRate));
    }

    /**
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal.
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED in Pool1 - returns propToken when principal reaches 0
    *   EDITED in pool14 - repayments done in HOME instead of USDC
    */
    function repay(uint256 loanId, uint256 amount) public nonReentrant {
        require(amount > 0, "Can't make a 0 payment.");
        require(loanId < loanCount, "Loan to repay must exist.");

        Loan storage currentLoan = loans[loanId];

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        uint256 currentPrincipal = currentLoan.principal;

        require(currentPrincipal > 0, "Loan must still be active.");

        // Default repayments amounts if the payment doesn't cover all the interest accrued.
        uint256 interestRepaid = amount;
        uint256 principalRepaid = 0;

        // if the payment amount is greater than accrued interest, deduct the rest from principal.
        if (currentInterest < amount) {
            interestRepaid = currentInterest;

            // If the principal payment is larger than the principal left on the loan,
            // payoff the whole loan and leave the return the rest of the payment.
            principalRepaid = amount.sub(interestRepaid);
            if (currentPrincipal < principalRepaid) {
                principalRepaid = currentPrincipal;
            }
        }

        // loan data is updated first before token movement.
        currentLoan.timeLastPayment = block.timestamp;
        currentLoan.principal = currentPrincipal.sub(principalRepaid);
        currentLoan.interestAccrued = currentInterest.sub(interestRepaid);

        // Calculate how much of payment goes to servicer here.
        // 1% of the loan split between the servicer and DAO.
        // Can't take more fee than the interest being repaid. Only matters when rate set < 1%.
        uint256 servicerFee = servicerFeePercentage.mul(interestRepaid).div(currentLoan.interestRate);
        if (servicerFee > interestRepaid) {
            servicerFee = interestRepaid;
        }

        // Transfer HOME proportional to the payment and distribute
        super._transfer(msg.sender, servicer, servicerFee.div(2));
        super._transfer(msg.sender, daoAddress, servicerFee.div(2));

        // Send the remaining interest to the DAO for distribution to HOME holders
        super._transfer(msg.sender, daoAddress, interestRepaid.sub(servicerFee));

        // Burn HOME for the principal repaid to maintain the principal/HOME invariant.
        if (principalRepaid > 0) {
            super._burn(msg.sender, principalRepaid);
        }

        // [TODO] Think about the case where the prop token could be used to get multiple loans
        // [TODO] and there's a separate function to retrieve the token and tests that the balance is 0.
        // [TODO] For now, the prop token can only be used to get one loan. This makes extra draws impossible.

        // If the loan is paid off. Return the PropToken back to borrower.
        if (currentLoan.principal == 0) {
            PropToken0(propTokenContractAddress).safeTransferFrom(address(this), currentLoan.borrower, loanToPropToken[loanId]);
        }

        emit Repay(msg.sender, uint64(loanId), uint128(currentPrincipal), uint128(currentInterest), uint128(principalRepaid), uint128(interestRepaid));

    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**
    *   @dev Function stake transfers users HOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        transfer(poolStakingAddress, amount);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amount);
        require(successfulStake, "Stake failed");

        return successfulStake;
    }

    function boost(uint256 amount, uint16 level, bool autoRenew) public returns (bool){
        require(balanceOf(msg.sender) >= amount, "Not enough to boost");

        // Deposit the funds with the staking contract so they can still earn Bacon.
        // Send all tokens to the staking contract to hold them for the user.
        // Only stake a proportion so the boost earns the appropraite amount of Bacon.
        uint256 amountToStake = HomeBoost0(homeBoostAddress).getStakeAmount(level, amount);

        transfer(poolStakingAddress, amountToStake);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amountToStake);

        // Send any remaining unstaked amounts to the boost contract for holding.
        if (amountToStake < amount) {
            transfer(homeBoostAddress, amount - amountToStake);
        }

        // Create the boost
        bool successfulBoost = HomeBoost0(homeBoostAddress).mint(msg.sender, amount, level, autoRenew);

        require(successfulStake && successfulBoost, "Boost failed");

        return successfulStake && successfulBoost;
    }

    /**
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 14;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function claimRewards() public returns (uint256) {
        // 1% Rewards [div by 100]
        uint256 unstakedRewards = super.getAndClearReward(msg.sender).div(100);

        uint256 stakedRewards = PoolStakingRewards3(poolStakingRewardAddress).getAndClearReward(msg.sender).div(100);

        uint256 rewards = unstakedRewards + stakedRewards;

        super._transfer(daoAddress, msg.sender, rewards);

        return rewards;
    }

    function transferBoostRewards(address wallet, uint256 amount) public {
        require(msg.sender == homeBoostAddress, "invalid sender");

        super._transfer(daoAddress, wallet, amount);
    }

    function transferUSDC(address wallet, uint256 amount) public {
        require(msg.sender == servicer, "invalid sender");
        IERC20Upgradeable usdcCoin = IERC20Upgradeable(ERCAddress);

        usdcCoin.transfer(wallet, amount);
    }

    /**
    * @dev Function burn burns HOME
    * @param amount is the amount of HOME to burn
    */
    function burn(uint256 amount) public {
        super._burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IStaking {

    function deposit(address tokenAddress, address wallet, uint256 amount) external;
    function withdraw(address tokenAddress, address wallet, uint256 amount) external;
    function balanceOf(address wallet, address tokenAddress) external view returns (uint);
    function getEpochId(uint timestamp) external view returns (uint); // get epoch id
    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint);
    function epoch1Start() external view returns (uint);
    function epochDuration() external view returns (uint);
    function getAndClearReward(address account, address tokenAddress) external returns (uint256);
}

// contracts/Pool0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract PropToken0 is Initializable, ERC721URIStorageUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Lien{
        uint256 lienIndex;
        uint256 lienValue;
        uint256[] seniorLienValues;
        uint256 propValue;
        string propAddress;
        uint256 issuedAtTimestamp;
    }

    uint256 lienCount;
    address[] servicerAddresses;
    address[] poolAddresses;
    mapping(uint256 => Lien) lienData;


    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Calls the init function of the inherited ERC721 contract
    *   @param name Name of this particular ERC721 token
    *   @param symbol The ticker this token will go by
    */
    function initialize(string memory name, string memory symbol, address _poolAddress, address approvedServicer) public initializer {
        servicerAddresses.push(approvedServicer);
        poolAddresses.push(_poolAddress);
        ERC721Upgradeable.__ERC721_init(name, symbol);

        //set initial vars
        lienCount = 0;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function isApprovedServicer() is an internal function that checks the array of approved addresses for the given address
    *   @param _address The address to be checked if it is approved
    *   @return isApproved is if the _addess is found in the list of servicerAddresses
    */
    function isApprovedServicer(address _address) internal view returns (bool) {
        bool isApproved = false;
        
        for (uint i = 0; i < servicerAddresses.length; i++) {
            if(_address == servicerAddresses[i]) {
                isApproved = true;
            }
        }

        return isApproved;
    }

    /**
    *   @dev Function get Lien Value 
    *   @param lienId is the ID of the lien being looked up
    *   @return the uint256 max value of the lien (to 6 decimal places)
    **/
    function getLienValue(uint256 lienId) public view returns (uint256) {
        return lienData[lienId].lienValue;
    }

    /** 
    *   @dev Function getPropTokenCount() returns the lien count
    *   @return lienCount uint256
    */
    function getPropTokenCount() public view returns (uint256) {
        return lienCount;
    }

    /**
    *   @dev Function getPoolAddresses() returns the lien count
    *   @return address[] poolAddresses
    */
    function getPoolAddresses() public view returns (address[] memory) {
        return poolAddresses;
    }

    /**
    *   @dev Function getPropTokenData() returns all revelant fields on propToken
    *   @param propTokenID  the uint256 id of token to be looked up
    */
    function getPropTokenData(uint256 propTokenID) public view returns (address, uint256, uint256[] memory, uint256, string memory, uint256, string memory) {
        Lien memory propToken = lienData[propTokenID];
        return(
          ownerOf(propTokenID),
          propToken.lienValue,
          propToken.seniorLienValues,
          propToken.propValue,
          propToken.propAddress,
          propToken.issuedAtTimestamp,
          tokenURI(propTokenID)
        );
    }

    /*****************************************************
    *              MINTING FUNCTION
    ******************************************************/

    function mintPropToken(
        address to,
        uint256 lienValue,
        uint256[] memory seniorLienValues,
        uint256 propValue,
        string memory propAddress,
        string memory propPhotoURI
        ) public {
        //require servicer is calling
        require(isApprovedServicer(msg.sender));

        Lien memory newLien = Lien(lienCount, lienValue, seniorLienValues, propValue, propAddress, block.timestamp);

        _safeMint(to, lienCount);
        _setTokenURI(lienCount, propPhotoURI);

        lienData[lienCount] = newLien;
        lienCount = lienCount + 1;
    }

}

// contracts/PoolUtils0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../PoolCore/Pool4.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';


contract PoolUtils0 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 0;
    uint constant curveK = 200000000;

    address poolCore;

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Sets the poolCore contract Address 
    */
    function initialize(address _poolCore) public initializer {
        poolCore = _poolCore;
    }

    /********************************************
    *           Pool Getter Funcs               * 
    ********************************************/



    /**  
    *   @dev Function getAverageInterest() returns an average interest for the pool
    */
    function getAverageInterest() public view returns (uint256) {
        uint256 sumOfRates = 0;
        uint256 borrowedCounter = 0;
        
        uint256 interestRate = 0;
        uint256 principal = 0;
        uint256 loanCount = 0;

        (, , , , , loanCount) = Pool4(poolCore).getContractData();

        for (uint i = 0; i < loanCount; i++) {

            (, , interestRate, principal, , , ) = Pool4(poolCore).getLoanDetails(i);
            if(principal != 0){
                sumOfRates = sumOfRates.add(interestRate.mul(principal));
                borrowedCounter = borrowedCounter.add(principal);
            }
        }

       return sumOfRates.div(borrowedCounter);
    }

    /**  
    *   @dev Function getActiveLoans() returns an array of the loans currently out by users
    *   @return array of bools, where the index i is the loan ID and the value bool is active or not
    */
    function getActiveLoans() public view returns (bool[] memory) {
        uint256 principal = 0;
        uint256 loanCount = 0;

        (, , , , , loanCount) = Pool4(poolCore).getContractData();
        bool[] memory loanActive = new bool[](loanCount);

        for (uint i = 0; i < loanCount; i++) {
            (, , , principal, , , ) = Pool4(poolCore).getLoanDetails(i);

            if(principal != 0) {
                loanActive[i] = true;
            } else {
                loanActive[i] = false;
            }
        }

        return loanActive;
    }


    /**  
    *   @dev Function getPoolInterestAccrued() returns the the amount of interest accreued by the pool in total
    */
    function getPoolInterestAccrued() public view returns (uint256) {
        uint256 totalInterest = 0;
        uint256 loanCount = Pool4(poolCore).getLoanCount();


        for (uint i=0; i<loanCount; i++) {
            uint256 accruedInterest = Pool4(poolCore).getLoanAccruedInterest(i);
            totalInterest = totalInterest.add(accruedInterest);
        }

        return totalInterest;
    }

    /**  
    *   @dev Function getInterestRate calculates the new interest rate if a loan was to be taken out in this block
    *   @param amount The size of the potential loan in (probably usdc).
    *   @return interestRate The interest rate in APR for the loan
    */
    function getInterestRate(uint256 amount) public view returns (int256) {
        //I = (( U - k ) / (U - 100)) - 0.01k + Base + ServicerFee
        //all ints multiplied by 1000000 to represent the 6 decimal points available

        uint256 poolBorrowed = 0;
        uint256 poolLent = 0;
        (, , poolLent, , poolBorrowed, ) = Pool4(poolCore).getContractData();
        
        //first check available allocation
        require(amount < (poolLent - poolBorrowed));

        //get new proposed utilization amount
        int256 newUtilizationRatio = int256(poolBorrowed).add(int256(amount)).mul(100000000).div(int256(poolLent));

        //calculate interest
        //subtract k from U
        int256 numerator = newUtilizationRatio.sub(int256(curveK));  
        //subtract 100 from U
        int256 denominator = newUtilizationRatio.sub(100000000);
        //divide numerator by denominator and multiply percentage by 10^6 to account for decimal places
        int256 interest = numerator.mul(1000000).div(denominator);
        //add base and fees to interest
        interest = interest.sub(int256(curveK).div(100)).add(int256(servicerFeePercentage)).add(int256(baseInterestPercentage)); 
        
        return interest;
    }

    /********************************************
    *           Loan Getter Funcs               * 
    ********************************************/
 
}

// SPDX-License-Identifier: Apache-2.0

// Changes:
// 1. Separated the bond token address from the pool token address so that the pool can hold bHome and reward Bacon.
//    Though I suppose this makes it not a very good bond...

pragma solidity ^0.8.4;

import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Staking/IStaking.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../BaconCoin/BaconCoin3.sol";


contract PoolStakingRewards4 is Initializable {

    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // Per epoch rewards
    uint256 constant GUARDIAN_REWARD = 2_358_720e18;
    uint256 constant DAO_REWARD = 1_088_640e18;

    // constants
    // end of year one rewards was block 15651074
    // airdrop_ends_block_number (from airdrop script) was: 14127375
    // year one reward per block: 100 Bacon
    // total remaining rewards for year 1 = 100 * (endOfYearOneBlock - rewardsAirdropBlock)
    // = 100 * (15651074-14127375)
    // uint public constant TOTAL_DISTRIBUTED_AMOUNT = 152369900;
    // There are roughly 19 weeks left in our 1 year rewards term
    // starting the 19th of May 2022
    // uint public constant NR_OF_EPOCHS = 19;
    // uint128 public constant EPOCHS_DELAYED_FROM_STAKING_CONTRACT = 0;

    // state variables

    // addresses
    address private _poolTokenAddress;
    // contracts
    BaconCoin3 private _bacon;
    IStaking private _staking;
    // TODO: maybe private?
    mapping(address => bool) isApprovedPool;
    address guardianAddress;
    address daoAddress;


    uint[] private epochs;
    uint private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract
    uint private _numberOfEpochs;

    /* PoolStakingRewards1 Variables */
    address airdropContract;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    function initializePoolStakingRewards1( address _airdropContract ) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        airdropContract = _airdropContract;
    }

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_guardianAddress] =  lastEpochIdHarvested[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_DAOAddress] =  lastEpochIdHarvested[daoAddress];
        daoAddress = _DAOAddress;
    }

    function setPerEpoch(uint newPerEpoch) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        _totalAmountPerEpoch = newPerEpoch;
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        _bacon.setStakingContract(newMinter);
    }

    function approvePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = true;
    }

    function revokePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = false;
    }

    function stake(address wallet, uint256 amount) public returns (bool) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // expects that the users Home has already been transferred to the staking contract
        _staking.deposit(_poolTokenAddress, wallet, amount);

        return true;
    }

    // PoolStakingRewards no longer allowed from any address. This is now done by claiming a HomeBoost.
    function unstake(uint256 amount) public {
        require(false, "not allowed");
    }

    function unstakeForWallet(address wallet, uint256 amount) public {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        _unstakeInternal(wallet, amount);
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest(address wallet) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        uint totalDistributedValue = 0;

        //added so it doesn't fail on first epoch
        if(_getEpochId() == 0){
            return 0;
        }
        
        uint epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > _numberOfEpochs) {
            epochId = _numberOfEpochs;
        }

        for (uint128 i = lastEpochIdHarvested[wallet] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(wallet, i);
        }

        emit MassHarvest(wallet, epochId - lastEpochIdHarvested[wallet], totalDistributedValue);

        if (totalDistributedValue > 0) {
            _bacon.mint(wallet, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (address wallet, uint128 epochId) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // checks for requested epoch
        require (_getEpochId() > epochId, "PoolStakingRewards: This epoch is in the future");
        require(epochId <= _numberOfEpochs, "PoolStakingRewards: Maximum number of epochs is 12");
        require (lastEpochIdHarvested[wallet].add(1) == epochId, "PoolStakingRewards: Harvest in order");
        uint userReward = _harvest(wallet, epochId);
        if (userReward > 0) {
             _bacon.mint(wallet, userReward);
        }
        emit Harvest(wallet, epochId, userReward);
        return userReward;
    }

    // views
    function getTotalEpochs() external view returns (uint) {
        return _numberOfEpochs;
    }

    function getRewardPerEpoch() external view returns (uint) {
        return _totalAmountPerEpoch;
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getCurrentEpochStake(address userAddress) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, _getEpochId());
    }

    function getCurrentBalance(address userAddress) external view returns (uint) {
        return _staking.balanceOf(userAddress, _poolTokenAddress);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _unstakeInternal(address wallet, uint256 amount) internal {
        _staking.withdraw(_poolTokenAddress, wallet, amount);
    }

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "PoolStakingRewards: Epoch can be init only in order");
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (address wallet, uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[wallet] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)
        if(wallet == daoAddress){
            return DAO_REWARD;
        }
        if(wallet == guardianAddress){
            return GUARDIAN_REWARD;
        }

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(wallet, epochId))
        .div(epochs[epochId]);
    }

    // retrieve _poolTokenAddress token balance
    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        return _staking.getEpochPoolSize(_poolTokenAddress, _stakingEpochId(epochId));
    }

    // retrieve _poolTokenAddress token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        return _staking.getEpochUserBalance(userAddress, _poolTokenAddress, _stakingEpochId(epochId));
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) pure internal returns (uint128) {
        return epochId;
    }

    function mintBacon(address wallet, uint256 userReward) public {
        require(msg.sender == airdropContract, "PoolStakingRewards: unapproved sender");
        _bacon.mint(wallet, userReward);
    }

    function getAndClearReward(address wallet) external returns (uint256) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");

        return _staking.getAndClearReward(wallet, _poolTokenAddress);
    }

}

// SPDX-License-Identifier: Apache-2.0

// Changes:
// 1. Separated the bond token address from the pool token address so that the pool can hold bHome and reward Bacon.
//    Though I suppose this makes it not a very good bond...

pragma solidity ^0.8.4;

import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Staking/IStaking.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../BaconCoin/BaconCoin3.sol";


contract PoolStakingRewards3 is Initializable {

    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // Per epoch rewards
    uint256 constant GUARDIAN_REWARD = 23587200e18;
    uint256 constant DAO_REWARD = 10886400e18;

    // constants
    // end of year one rewards was block 15651074
    // airdrop_ends_block_number (from airdrop script) was: 14127375
    // year one reward per block: 100 Bacon
    // total remaining rewards for year 1 = 100 * (endOfYearOneBlock - rewardsAirdropBlock)
    // = 100 * (15651074-14127375)
    // uint public constant TOTAL_DISTRIBUTED_AMOUNT = 152369900;
    // There are roughly 19 weeks left in our 1 year rewards term
    // starting the 19th of May 2022
    // uint public constant NR_OF_EPOCHS = 19;
    // uint128 public constant EPOCHS_DELAYED_FROM_STAKING_CONTRACT = 0;

    // state variables

    // addresses
    address private _poolTokenAddress;
    // contracts
    BaconCoin3 private _bacon;
    IStaking private _staking;
    // TODO: maybe private?
    mapping(address => bool) isApprovedPool;
    address guardianAddress;
    address daoAddress;


    uint[] private epochs;
    uint private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract
    uint private _numberOfEpochs;

    /* PoolStakingRewards1 Variables */
    address airdropContract;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    function initializePoolStakingRewards1( address _airdropContract ) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        airdropContract = _airdropContract;
    }

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_guardianAddress] =  lastEpochIdHarvested[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        lastEpochIdHarvested[_DAOAddress] =  lastEpochIdHarvested[daoAddress];
        daoAddress = _DAOAddress;
    }

    function setPerEpoch(uint newPerEpoch) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        _totalAmountPerEpoch = newPerEpoch;
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        _bacon.setStakingContract(newMinter);
    }

    function approvePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = true;
    }

    function revokePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        isApprovedPool[poolAddress] = false;
    }

    function stake(address wallet, uint256 amount) public returns (bool) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // expects that the users hbHome has already been transferred to the staking contract
        _staking.deposit(_poolTokenAddress, wallet, amount);

        return true;
    }

    function unstake(uint256 amount) public {
        _unstakeInternal(msg.sender, amount);
    }

    function unstakeForWallet(address wallet, uint256 amount) public {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        _unstakeInternal(wallet, amount);
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest(address wallet) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        uint totalDistributedValue = 0;

        //added so it doesn't fail on first epoch
        if(_getEpochId() == 0){
            return 0;
        }
        
        uint epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > _numberOfEpochs) {
            epochId = _numberOfEpochs;
        }

        for (uint128 i = lastEpochIdHarvested[wallet] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(wallet, i);
        }

        emit MassHarvest(wallet, epochId - lastEpochIdHarvested[wallet], totalDistributedValue);

        if (totalDistributedValue > 0) {
            _bacon.mint(wallet, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (address wallet, uint128 epochId) external returns (uint){
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");
        // checks for requested epoch
        require (_getEpochId() > epochId, "PoolStakingRewards: This epoch is in the future");
        require(epochId <= _numberOfEpochs, "PoolStakingRewards: Maximum number of epochs is 12");
        require (lastEpochIdHarvested[wallet].add(1) == epochId, "PoolStakingRewards: Harvest in order");
        uint userReward = _harvest(wallet, epochId);
        if (userReward > 0) {
             _bacon.mint(wallet, userReward);
        }
        emit Harvest(wallet, epochId, userReward);
        return userReward;
    }

    // views
    function getTotalEpochs() external view returns (uint) {
        return _numberOfEpochs;
    }

    function getRewardPerEpoch() external view returns (uint) {
        return _totalAmountPerEpoch;
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getCurrentEpochStake(address userAddress) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, _getEpochId());
    }

    function getCurrentBalance(address userAddress) external view returns (uint) {
        return _staking.balanceOf(userAddress, _poolTokenAddress);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _unstakeInternal(address wallet, uint256 amount) internal {
        _staking.withdraw(_poolTokenAddress, wallet, amount);
    }

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "PoolStakingRewards: Epoch can be init only in order");
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (address wallet, uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[wallet] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)
        if(wallet == daoAddress){
            return DAO_REWARD;
        }
        if(wallet == guardianAddress){
            return GUARDIAN_REWARD;
        }

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(wallet, epochId))
        .div(epochs[epochId]);
    }

    // retrieve _poolTokenAddress token balance
    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        return _staking.getEpochPoolSize(_poolTokenAddress, _stakingEpochId(epochId));
    }

    // retrieve _poolTokenAddress token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        return _staking.getEpochUserBalance(userAddress, _poolTokenAddress, _stakingEpochId(epochId));
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) pure internal returns (uint128) {
        return epochId;
    }

    function mintBacon(address wallet, uint256 userReward) public {
        require(msg.sender == airdropContract, "PoolStakingRewards: unapproved sender");
        _bacon.mint(wallet, userReward);
    }

    function getAndClearReward(address wallet) external returns (uint256) {
        require(isApprovedPool[msg.sender], "PoolStakingRewards: must be approved sender");

        return _staking.getAndClearReward(wallet, _poolTokenAddress);
    }

}

// SPDX-License-Identifier: Apache-2.0

// Changes:
// 1. Separated the bond token address from the pool token address so that the pool can hold bHome and reward Bacon.
//    Though I suppose this makes it not a very good bond...

pragma solidity ^0.8.4;

import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Staking/IStaking.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../BaconCoin/BaconCoin3.sol";


contract PoolStakingRewards0 is Initializable {

    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // Per epoch rewards
    uint256 constant GUARDIAN_REWARD = 23587200e18;
    uint256 constant DAO_REWARD = 10886400e18;

    // constants
    // end of year one rewards was block 15651074
    // airdrop_ends_block_number (from airdrop script) was: 14127375
    // year one reward per block: 100 Bacon
    // total remaining rewards for year 1 = 100 * (endOfYearOneBlock - rewardsAirdropBlock)
    // = 100 * (15651074-14127375)
    // uint public constant TOTAL_DISTRIBUTED_AMOUNT = 152369900;
    // There are roughly 19 weeks left in our 1 year rewards term
    // starting the 19th of May 2022
    // uint public constant NR_OF_EPOCHS = 19;
    // uint128 public constant EPOCHS_DELAYED_FROM_STAKING_CONTRACT = 0;

    // state variables

    // addresses
    address private _poolTokenAddress;
    // contracts
    BaconCoin3 private _bacon;
    IStaking private _staking;
    // TODO: maybe private?
    mapping(address => bool) isApprovedPool;
    address guardianAddress;
    address daoAddress;


    uint[] private epochs;
    uint private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract
    uint private _numberOfEpochs;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    function initialize(address _guardianAddress, address baconTokenAddress, address poolTokenAddress, address stakeContract, uint totalAmountPerEpoch, uint numberOfEpochs) public initializer {
        epochs = new uint[](numberOfEpochs + 1);
        
        guardianAddress = _guardianAddress;
        _bacon = BaconCoin3(baconTokenAddress);
        _poolTokenAddress = poolTokenAddress;
        _staking = IStaking(stakeContract);
        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start();
        _numberOfEpochs = numberOfEpochs;
        _totalAmountPerEpoch = totalAmountPerEpoch;
    }

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        lastEpochIdHarvested[_guardianAddress] =  lastEpochIdHarvested[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        lastEpochIdHarvested[_DAOAddress] =  lastEpochIdHarvested[daoAddress];
        daoAddress = _DAOAddress;
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStakingRewards: unapproved sender");
        _bacon.setStakingContract(newMinter);
    }

    function approvePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        isApprovedPool[poolAddress] = true;
    }

    function revokePool(address poolAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        isApprovedPool[poolAddress] = false;
    }

    function stake(address wallet, uint256 amount) public returns (bool) {
        require(isApprovedPool[msg.sender], "must be approved sender");
        // expects that the users hbHome has already been transferred to the staking contract
        _staking.deposit(_poolTokenAddress, wallet, amount);
        return true;
    }

    function unstake(uint256 amount) public {
        _unstakeInternal(msg.sender, amount);
    }

    function unstakeForWallet(address wallet, uint256 amount) public {
        require(isApprovedPool[msg.sender], "must be approved sender");
        _unstakeInternal(wallet, amount);
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest(address wallet) external returns (uint){
        require(isApprovedPool[msg.sender], "must be approved sender");
        uint totalDistributedValue = 0;

        //added so it doesn't fail on first epoch
        if(_getEpochId() == 0){
            return 0;
        }
        
        uint epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > _numberOfEpochs) {
            epochId = _numberOfEpochs;
        }

        for (uint128 i = lastEpochIdHarvested[wallet] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(wallet, i);
        }

        emit MassHarvest(wallet, epochId - lastEpochIdHarvested[wallet], totalDistributedValue);

        if (totalDistributedValue > 0) {
            _bacon.mint(wallet, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (address wallet, uint128 epochId) external returns (uint){
        require(isApprovedPool[msg.sender], "must be approved sender");
        // checks for requested epoch
        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= _numberOfEpochs, "Maximum number of epochs is 12");
        require (lastEpochIdHarvested[wallet].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(wallet, epochId);
        if (userReward > 0) {
             _bacon.mint(wallet, userReward);
        }
        emit Harvest(wallet, epochId, userReward);
        return userReward;
    }

    // views
    function getTotalEpochs() external view returns (uint) {
        return _numberOfEpochs;
    }

    function getRewardPerEpoch() external view returns (uint) {
        return _totalAmountPerEpoch;
    }

    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function getCurrentEpochStake(address userAddress) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, _getEpochId());
    }

    function getCurrentBalance(address userAddress) external view returns (uint) {
        return _staking.balanceOf(userAddress, _poolTokenAddress);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _unstakeInternal(address wallet, uint256 amount) internal {
        _staking.withdraw(_poolTokenAddress, wallet, amount);
    }

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "Epoch can be init only in order");
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (address wallet, uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[wallet] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)
        if(wallet == daoAddress){
            return DAO_REWARD;
        }
        if(wallet == guardianAddress){
            return GUARDIAN_REWARD;
        }

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(wallet, epochId))
        .div(epochs[epochId]);
    }

    // retrieve _poolTokenAddress token balance
    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        return _staking.getEpochPoolSize(_poolTokenAddress, _stakingEpochId(epochId));
    }

    // retrieve _poolTokenAddress token balance per user per epoch
    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        return _staking.getEpochUserBalance(userAddress, _poolTokenAddress, _stakingEpochId(epochId));
    }

    // compute epoch id from block.timestamp and epochStart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }

    // get the staking epoch
    function _stakingEpochId(uint128 epochId) pure internal returns (uint128) {
        return epochId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import './../BaconCoin/BaconCoin3.sol';
import './../PoolStakingRewards/PoolStakingRewards0.sol';
import './../PoolCore/Pool10.sol';


import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract PoolStaking4 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint256 constant PER_BLOCK_DECAY_18_DECIMALS = 999999775700000000;
    uint256 constant PER_BLOCK_DECAY_INVERSE = 1000000224300050310;
    uint256 constant DENOM = 224337829e21;
    uint256 constant GUARDIAN_REWARD = 39e18;
    uint256 constant DAO_REWARD = 18e18;
    uint256 constant COMMUNITY_REWARD = 50e18;
    uint256 constant COMMUNITY_REWARD_BONUS = 100e18;

    uint256 stakeAfterBlock;
    address guardianAddress;
    address daoAddress;
    address baconCoinAddress;
    address[] poolAddresses;

    uint256[] updateEventBlockNumber;
    uint256[] updateEventNewAmountStaked;
    uint256 updateEventCount;
    uint256 currentStakedAmount;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userLastDistribution;

    uint256 oneYearBlock;

    struct UnstakeRecord {
        uint256 endBlock;
        uint256 amount;
    }

    // PoolStaking2 storage
    uint256 unstakingLockupBlockDelta;
    mapping(address => UnstakeRecord) userToUnstake;
    uint256 pendingWithdrawalAmount;

    //PoolStaking3 storage for nonReentrant modifier
    //modifier and variables could not be imported via inheratance given upgradability rules
    mapping(address => bool) isApprovedPool;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    //PoolStaking4 storage
    address newStakingContract;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    // TODO: maybe this should just be a normal setter like the rest in this block...
    function setUnstakingLockupBlockDelta(uint256 _unstakingLockupBlockDelta) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        unstakingLockupBlockDelta = _unstakingLockupBlockDelta;
    }

    function setOneYearBlock(uint256 _oneYearBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        oneYearBlock = _oneYearBlock;
    }

    function setstakeAfterBlock(uint256 _stakeAfterBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        stakeAfterBlock = _stakeAfterBlock;
    }

    // To be called after baconCoin0 is deployed
    function setBaconAddress(address _baconCoinAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        baconCoinAddress = _baconCoinAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        userLastDistribution[_DAOAddress] =  userLastDistribution[daoAddress];
        daoAddress = _DAOAddress;
    }

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        userLastDistribution[_guardianAddress] =  userLastDistribution[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 4;
    }

    function getContractInfo() public view returns (uint256, uint256, address, address, address, address  [] memory, uint256, uint256, uint256) {
        return (
            stakeAfterBlock,
            oneYearBlock,
            guardianAddress,
            daoAddress,
            baconCoinAddress,
            poolAddresses,
            updateEventCount,
            currentStakedAmount,
            pendingWithdrawalAmount
        );
    }

    function getPendingWithdrawInfo(address _holderAddress) public view returns(uint256, uint256, uint256) {
        return (
            userToUnstake[_holderAddress].endBlock,
            userToUnstake[_holderAddress].amount,
            pendingWithdrawalAmount
        );
    }

    function getUserLastDistributed(address wallet) public view returns (uint256) {
        return (userLastDistribution[wallet]);
    }

    /*****************************************************
    *       Staking FUNCTIONS
    ******************************************************/

    function decayExponent(uint256 exponent) public pure returns (uint256) {
        //18 decimals
        if (exponent == 0) {
            return 1e18;
        }

        uint256 answer = PER_BLOCK_DECAY_18_DECIMALS;
        for (uint256 i = 0; i < exponent-1; i++) {
            answer = answer.mul(1e18).div(PER_BLOCK_DECAY_INVERSE);
        }

        return answer;
    }

    function calcBaconBetweenEvents(uint256 blockX, uint256 blockY) public view returns (uint256) {
        //bacon per block after first year is
        //y=50(1-0.000000224337829000)^{x}
        //where x is number of blocks over 15651074

        //Bacon accumulated between two blocksover first year is:
        //S(x,y) = S(y) - S(x) = (A1(1-r^y) / (1-r)) - (A1(1-r^x) / (1-r))
        //where A1 = 50 and r = 0.9999997757

        //1 year block subtracted from block numbers passed in since formula only cares about change in time since that point
        blockX = blockX.sub(oneYearBlock);
        blockY = blockY.sub(oneYearBlock);

        uint256 SyNumer = 1e18;
        uint256 SxNumer = 1e18;

        SyNumer = SyNumer.sub(decayExponent(blockY)).mul(COMMUNITY_REWARD);
        SxNumer = SxNumer.sub(decayExponent(blockX)).mul(COMMUNITY_REWARD);

        uint256 Sy = SyNumer.mul(1e18).div(DENOM);
        uint256 Sx = SxNumer.mul(1e18).div(DENOM);

        return Sy.sub(Sx);
    }


    /**
    *   @dev function distribute accepts a wallet address and transfers the BaconCoin accrued to their wallet since the user's Last Distribution
    */
    function distribute(address wallet) public returns (uint256) {
        // Forward to the new staking contract
        return PoolStakingRewards0(newStakingContract).massHarvest(wallet);
    }


    function checkStaked(address wallet) public view returns (uint256) {
        return PoolStakingRewards0(newStakingContract).getCurrentBalance(wallet);
    }

    /**
    *   @dev Function unstake begins the process of withdrawing staked value. After a timeout, 
    *   the amount will be available to withdraw. If you calling account already has an unstake pending
    *   the new amount will be added to the pending amount and the timeout will reset.
    */
    function unstake(uint256 amount) public nonReentrant returns (uint256) {
        PoolStakingRewards0(newStakingContract).unstakeForWallet(msg.sender, amount);
        return 0;
    }

    /**  
    *   @dev Function withdraw moves tokens that were unstaked by the caller to the caller's wallet
    */
    function withdraw(uint256 amount) public returns (uint256) {
        // Disabled for new staking
        return 0;
    }

    function getEvents() public view returns (uint256  [] memory, uint256  [] memory) {
        return (updateEventBlockNumber, updateEventNewAmountStaked);
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");
        BaconCoin3(baconCoinAddress).setStakingContract(newMinter);
    }

    function setNewStakingContract(address newContract) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");
        newStakingContract = newContract;
    }

    function transferAllStakes(address stakingCore, address[] memory recepients, uint256[] memory amounts, uint256 length) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");

        for (uint256 i = 0; i < length; i++) {
            Pool10(poolAddresses[0]).transfer(stakingCore, amounts[i]); 
            PoolStakingRewards0(newStakingContract).stake(recepients[i], amounts[i]);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import './../BaconCoin/BaconCoin0.sol';


import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

// Forked from Compound
// See https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol
contract PoolStaking0 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint256 constant PER_BLOCK_DECAY = 9999997757;
    uint256 constant PER_BLOCK_DECAY_18_DECIMALS = 999999775700000000;
    uint256 constant PER_BLOCK_DECAY_INVERSE = 10000002243;
    uint256 constant GUARDIAN_REWARD = 3900000000000000000;
    uint256 constant DAO_REWARD = 18000000000000000000;
    uint256 constant COMMUNITY_REWARD = 50000000000000000000;
    uint256 constant COMMUNITY_REWARD_BONUS = 100000000000000000000;

    uint256 stakeAfterBlock;
    address guardianAddress;
    address daoAddress;
    address baconCoinAddress;
    address[] poolAddresses;

    uint256[] updateEventBlockNumber;
    uint256[] updateEventNewAmountStaked;
    uint256 updateEventCount;
    uint256 currentStakedAmount;

    mapping(address => uint256) userStaked;
    mapping(address => uint256) userLastDistribution;

    uint256 oneYearBlock;


    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Calls the init function of the inherited ERC777 contract
    *   @param _poolAddress the address of Pool contracts approved to stake
    *   @param _guardianAddress The address Guardian receives Bacon distribution to
    */
    function initialize(address _poolAddress, address _guardianAddress, uint256 startingBlock, uint _stakeAfterBlock, uint256 _oneYearBlock) public initializer {
        guardianAddress = _guardianAddress;
        poolAddresses.push(_poolAddress);

        //set initial vars
        updateEventCount = 0;
        currentStakedAmount = 0;

        userLastDistribution[guardianAddress] = startingBlock;
        userLastDistribution[daoAddress] = startingBlock;
        stakeAfterBlock = _stakeAfterBlock;
        oneYearBlock = _oneYearBlock;
    }

    function setOneYearBlock(uint256 _oneYearBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        oneYearBlock = _oneYearBlock;
    }

    function setstakeAfterBlock(uint256 _stakeAfterBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        stakeAfterBlock = _stakeAfterBlock;
    }

    // To be called after baconCoin0 is deployed
    function setBaconAddress(address _baconCoinAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        baconCoinAddress = _baconCoinAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        daoAddress = _DAOAddress;
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 0;
    }

    function getContractInfo() public view returns (uint256, uint256, address, address, address, address  [] memory, uint256, uint256) {
        return (
            stakeAfterBlock,
            oneYearBlock,
            guardianAddress,
            daoAddress,
            baconCoinAddress,
            poolAddresses,
            updateEventCount,
            currentStakedAmount
        );
    }

    /** 
    *   @dev Function isApprovedPool() is an internal function that checks the array of approved pool addresses for the given address
    *   @param _address The address to be checked if it is approved
    *   @return isApproved is if the _addess is found in the list of servicerAddresses
    */
    function isApprovedPool(address _address) internal view returns (bool) {
        bool isApproved = false;
        
        for (uint i = 0; i < poolAddresses.length; i++) {
            if(_address == poolAddresses[i]) {
                isApproved = true;
            }
        }

        return isApproved;
    }

    /*****************************************************
    *       Staking FUNCTIONS
    ******************************************************/

    /**
    *   @dev function stake accepts an amount of bHOME to be staked and creates a new updateEvent for it
    */
    function stake(address wallet, uint256 amount) public returns (bool) {
        require(isApprovedPool(msg.sender), "sender not Pool");

        return stakeInternal(wallet, amount);
    }

    
    function stakeInternal(address wallet, uint256 amount) internal returns (bool) {
        //First handle the case where this is a first staking
        if(userStaked[wallet] != 0 || wallet == guardianAddress || wallet == daoAddress) {
            distribute(wallet);
        } else {
            userLastDistribution[wallet] = block.number;
        }

        userStaked[wallet] = userStaked[wallet].add(amount);
        currentStakedAmount = currentStakedAmount.add(amount);
        updateEventBlockNumber.push(block.number);
        updateEventNewAmountStaked.push(currentStakedAmount);
        updateEventCount = updateEventCount.add(1);

        return true;
    }

    function decayExponent(uint256 exponent) internal pure returns (uint256) {
        //10 decimals
        uint256 answer = PER_BLOCK_DECAY;
        for (uint256 i = 0; i < exponent; i++) {
            answer = answer.mul(10000000000).div(PER_BLOCK_DECAY_INVERSE);
        }

        return answer;
    }

    function calcBaconBetweenEvents(uint256 blockX, uint256 blockY) internal view returns (uint256) {
        //bacon per block after first year is
        //y=50(1-0.000000224337829)^{x}
        //where x is number of blocks over 15651074

        //Bacon accumulated between two blocksover first year is:
        //S(x,y) = S(y) - S(x) = (A1(1-r^y) / (1-r)) - (A1(1-r^x) / (1-r))
        //where A1 = 50 and r = 0.9999997757

        //1 year block subtracted from block numbers passed in since formula only cares about change in time since that point
        blockX = blockX.sub(oneYearBlock);
        blockY = blockY.sub(oneYearBlock);

        uint256 SyNumer = decayExponent(blockY).mul(50);
        uint256 SxNumer = decayExponent(blockX).mul(50);
        uint256 denom = uint256(1000000000000000000).sub(PER_BLOCK_DECAY_18_DECIMALS);

        uint256 Sy = SyNumer.mul(1000000000000000000).div(denom);
        uint256 Sx = SxNumer.mul(1000000000000000000).div(denom);

        return Sy.sub(Sx);
    }


    /**
    *   @dev function distribute accepts a wallet address and transfers the BaconCoin accrued to their wallet since the user's Last Distribution
    */
    function distribute(address wallet) public returns (uint256) {

        if (userStaked[wallet] == 0 && wallet != guardianAddress && wallet != daoAddress) {
            return 0;
        }

        uint256 accruedBacon = 0;
        uint256 countingBlock = userLastDistribution[wallet];

        uint256 blockDifference = 0;
        uint256 tempAccruedBacon = 0;

        if(wallet == daoAddress) {
            blockDifference = block.number - countingBlock;
            tempAccruedBacon = blockDifference.mul(DAO_REWARD);
            accruedBacon += tempAccruedBacon;
        } else if (wallet == guardianAddress) {
            blockDifference = block.number - countingBlock;
            accruedBacon = blockDifference.mul(GUARDIAN_REWARD);
            accruedBacon += tempAccruedBacon;
        } else if (countingBlock < stakeAfterBlock) {
            countingBlock = stakeAfterBlock;
        }

        if (userStaked[wallet] != 0) {
            //iterate through the array of update events
            for (uint256 i = 0; i < updateEventCount; i++) {
                //only accrue bacon if event is after last withdraw
                if (updateEventBlockNumber[i] > countingBlock) {
                    blockDifference = updateEventBlockNumber[i] - countingBlock;
                    
                    if(updateEventBlockNumber[i] < oneYearBlock) {
                        //calculate bacon accrued if update event is within the first year
                        //use updateEventNewAmountStaked[i-1] because that is the 
                        tempAccruedBacon = blockDifference.mul(COMMUNITY_REWARD_BONUS).mul(userStaked[wallet]).div(updateEventNewAmountStaked[i-1]);
                    } else {
                        //calculate bacon accrued if update event is past the first year
                        if(countingBlock < oneYearBlock) {
                            //calculate the bacon accrued at the end of the first year if overlapped with first year
                            uint256 blocksLeftInFirstYear = oneYearBlock - countingBlock;
                            tempAccruedBacon = blocksLeftInFirstYear.mul(COMMUNITY_REWARD_BONUS).mul(userStaked[wallet]).div(updateEventNewAmountStaked[i-1]);

                            //add the amount of bacon accrued before the first year to the running total and set the block difference to start calculating from new year
                            accruedBacon = accruedBacon.add(tempAccruedBacon);
                            countingBlock = oneYearBlock;
                        }
                        
                        //calculate the amount of Bacon accrued between events
                        uint256 baconBetweenBlocks = calcBaconBetweenEvents(countingBlock, updateEventBlockNumber[i]);
                        tempAccruedBacon = baconBetweenBlocks.mul(userStaked[wallet]).div(updateEventNewAmountStaked[i-1]);
                    }
                    
                    //as we iterate through events since last withdraw, add the bacon accrued since the last event to the running total & update contingBlock
                    accruedBacon = accruedBacon.add(tempAccruedBacon);
                    countingBlock = updateEventBlockNumber[i];
                }

            }// end updateEvent for loop

            // When there is no more updateEvents to loop through, the last step is to calculate accrued up to current block

            //first check that the last updateEvent didn't happen earlier this block, in which case we're done calculating accrued bacon
            //countingBlock is checked against the block.number in case the counting block was set in the future as startingBlock
            if(countingBlock != block.number && countingBlock < block.number) {
                //case where still within first year
                if(countingBlock < oneYearBlock  && block.number < oneYearBlock) {
                    //calculate accrued between last updateEvent and now
                    blockDifference = block.number - countingBlock;
                    tempAccruedBacon = blockDifference.mul(COMMUNITY_REWARD_BONUS).mul(userStaked[wallet]).div(currentStakedAmount);
                } else {
                    if (countingBlock < oneYearBlock  && block.number > oneYearBlock) {
                        //case where current block has just surpassed 1 year
                        uint256 blocksLeftInFirstYear = oneYearBlock - countingBlock;
                        tempAccruedBacon = blocksLeftInFirstYear.mul(COMMUNITY_REWARD_BONUS).mul(userStaked[wallet]).div(updateEventNewAmountStaked[updateEventCount-1]);

                        //add the amount of bacon accrued before the first year to the running total and set the block difference to start calculating from new year
                        accruedBacon = accruedBacon.add(tempAccruedBacon);
                        countingBlock = oneYearBlock;
                    } 

                    //case where last updateEvent was after year 1
                    //calculate the amount of Bacon accrued between events
                    uint256 baconBetweenBlocks = calcBaconBetweenEvents(countingBlock, block.number);
                    tempAccruedBacon = baconBetweenBlocks.mul(userStaked[wallet]).div(updateEventNewAmountStaked[updateEventCount-1]);
                }

                accruedBacon = accruedBacon.add(tempAccruedBacon);
            }
        }

        userLastDistribution[wallet] = block.number;
        BaconCoin0(baconCoinAddress).mint(wallet, accruedBacon);

        return accruedBacon;
    }


    function checkStaked(address wallet) public view returns (uint256) {
        return userStaked[wallet];
    }

    /**  
    *   @dev Function withdraw reduces the amount staked by a wallet by a given amount
    */
    function withdraw(uint256 amount) public returns (uint256) {
        require(userStaked[msg.sender] >= amount, "not enough staked");

        uint256 distributed = distribute(msg.sender);

        //reduce global variables
        uint256 stakedDiff = userStaked[msg.sender].sub(amount);
        currentStakedAmount = currentStakedAmount.sub(userStaked[msg.sender]);
        userStaked[msg.sender] = 0;

        //re-stake the difference
        if(stakedDiff > 0) {
            stakeInternal(msg.sender, stakedDiff);
        } else {
            updateEventBlockNumber.push(block.number);
            updateEventNewAmountStaked.push(currentStakedAmount);
            updateEventCount = updateEventCount.add(1);
        }

        //finally transfer out amount
        IERC777Upgradeable(poolAddresses[0]).send(msg.sender, amount, "");

        return distributed;

    }

    function getEvents() public view returns (uint256  [] memory, uint256  [] memory) {
        return (updateEventBlockNumber, updateEventNewAmountStaked);
    }

}

// contracts/Pool4.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking0.sol';

import "../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract Pool4 is Initializable, ERC777Upgradeable, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;
    address ERCAddress;
    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent;
    uint256 poolBorrowed;
    mapping(address => uint256[]) userLoans;
    Loan[] loans;
    uint256 loanCount;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 1000000;
    uint constant curveK = 120000000;

    /* Pool1 variables introduced here */
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) loanToPropToken;
    address propTokenContractAddress;

    /* Pool2 variables introduced here */
    address LTVOracleAddress;

    /* Pool3 variables introduced here */
    address poolUtilsAddress;
    address baconCoinAddress;
    address poolStakingAddress;


    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    function initializePoolFour(address _poolUtilsAddress, address _baconCoinAddress, address _poolStakingAddress) public {
        require(msg.sender == servicer);
        poolUtilsAddress = _poolUtilsAddress;
        baconCoinAddress = _baconCoinAddress;
        poolStakingAddress = _poolStakingAddress;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }
    
    /** 
    *   @dev Function setApprovedAddresses() updates the array of addresses approved by the servicer
    *   @param _servicerAddresses The array of addresses to be set as approved for borrowing
    */
    function setApprovedAddresses(address[] memory _servicerAddresses) public {
        require(msg.sender == servicer);

        servicerAddresses = _servicerAddresses;
    }

    /** 
    *   @dev Function setApprovedAddresses() is an internal function that checks the array of approved addresses for the given address
    *   @param _address The address to be checked if it is approved
    *   @return isApproved is if the _addess is found in the list of servicerAddresses
    */
    function isApprovedServicer(address _address) internal view returns (bool) {
        bool isApproved = false;
        
        for (uint i = 0; i < servicerAddresses.length; i++) {
            if(_address == servicerAddresses[i]) {
                isApproved = true;
            }
        }

        return isApproved;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/
    /**
    *   @dev Function getContractData() returns a lot of variables about the contract
    */
    function getContractData() public view returns (address, address, uint256, uint256, uint256, uint256) {
        return (servicer, ERCAddress, poolLent, (poolLent + PoolUtils0(poolUtilsAddress).getPoolInterestAccrued()), poolBorrowed, loanCount);
    }

    /*
    *   @dev Function getLoanCount() returns how many active loans there are
    */ 
    function getLoanCount() public view returns (uint256) {
        return loanCount;
    }

    /**  
    *   @dev Function getSupplyableTokenAddress() returns the contract address of ERC20 this pool accepts (ususally USDC)
    */
    function getSupplyableTokenAddress() public view returns (address) {
        return ERCAddress;
    }

    /**  
    *   @dev Function getServicerAddress() returns the address of this pool's servicer
    */
    function getServicerAddress() public view returns (address) {
        return servicer;
    } 

    /**  
    *   @dev Function getLoanDetails() returns an all the raw details about a loan
    *   @param loanId is the id for the loan we're looking up
    *   EDITED in pool1 to also return PropToken ID
    */
    function getLoanDetails(uint256 loanId) public view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        Loan memory loan = loans[loanId];
        //temp interestAccrued calculation because this is a read function
        uint256 interestAccrued = getLoanAccruedInterest(loanId);
        uint256 propTokenID = loanToPropToken[loanId];
        return (loan.loanId, loan.borrower, loan.interestRate, loan.principal, interestAccrued, loan.timeLastPayment, propTokenID);
    }

    /**  
    *   @dev Function getLoanAccruedInterest() calculates and returns the amount of interest accrued on a given loan
    *   @param loanId is the id for the loan we're looking up
    */
    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 secondsSincePayment = block.timestamp.sub(loan.timeLastPayment);

        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31622400);
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100000000);
        return interestAccrued.add(loan.interestAccrued);
    }   


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    /**  
    *   @dev Function mintProportionalPoolTokens calculates how many new hc_pool tokens to mint when value is added to the pool based on proportional value
    *   @param recepient The address of the wallet receiving the newly minted hc_pool tokens
    *   @param amount The amount to be minted
    */
    function mintProportionalPoolTokens(address recepient, uint256 amount) private returns (uint256) {
        //check if this is first deposit
        if (poolLent == 0) {
            super._mint(recepient, amount, "", "");
            return amount;
        } else {
            //Calculate proportional to total value (including interest)
            uint256 new_hc_pool = amount.mul(super.totalSupply()).div(poolLent);
            super._mint(recepient, new_hc_pool, "", "");
            return new_hc_pool;
        }
    }

    /**  
    *   @dev Function lend moves assets on the (probably usdc) contract to our own balance
    *   - Before calling: an approve(address _spender (proxy), uint256 _value (0xffff)) function call must be made on remote contract
    *   @param amount The amount of USDC to be transferred
    *   @return the amount of poolTokens created
    */
    function lend(
        uint256 amount
    ) public returns (uint256) {
        //USDC on Ropsten only right now
        IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
        uint256 newTokensMinted = mintProportionalPoolTokens(msg.sender, amount);
        poolLent = poolLent.add(amount);

        return newTokensMinted;
    }

    /**  
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public {
        //check to see if sender has enough hc_pool to redeem
        require(balanceOf(msg.sender) >= amount);

        //check to make sure there is liquidity available in the pool to withdraw
        uint256 tokenPrice = poolLent.mul(1000000).div(super.totalSupply());
        uint256 erc20ValueOfTokens = amount.mul(tokenPrice).div(1000000);
        require(erc20ValueOfTokens <= (poolLent - poolBorrowed));

        //burn hcPool first
        super._burn(msg.sender, amount, "", "");
        poolLent = poolLent.sub(erc20ValueOfTokens);
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, erc20ValueOfTokens);
    }

    /**  
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param maxRate The size of the potential loan in (probably usdc).
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    */
    function borrow(uint256 amount, uint256 maxRate, uint256 propTokenId) public {
        //for v2 require this address is approved to transfer propToken 
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");
        //also require msg.sender is owner of token
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        //check the requested interest rate is still available
        uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        //require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        //require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {  
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");


        //first take the propToken
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        //create new Loan
        Loan memory newLoan = Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp);
        loans.push(newLoan);
        userLoans[msg.sender].push(loanCount);

        //map new loanID to Token ID
        loanToPropToken[loanCount] = propTokenId;

        //update system variables
        loanCount = loanCount.add(1);
        poolBorrowed = poolBorrowed.add(amount);

        //finally move the USDC
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, amount);

        //then mint HC_Pool for the servicer (fixed 1% origination is better than standard 2.5%)
        mintProportionalPoolTokens(servicer, amount.div(100));
    }
    
    /**  
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal. 
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf 
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED - Pool1 returns propToken when principal reaches 0
    */

    function repay(uint256 loanId, uint256 amount) public {        
        //interestAmountRepayed keeps track of how much of the loan was returned to the pool to calculate servicer fee(treated as cash investment)
        uint256 interestAmountRepayed = amount;

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        if(currentInterest > amount) {
            //if the payment is less than the interest accrued on the loan, just deduct amount from interest
            //deduct amount FIRST (to make sure they have available balance), then reduce loan amount
            IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
            loans[loanId].interestAccrued = currentInterest.sub(amount);
        } else {
            //if the amount borrow is repaying is greater than interest accrued, deduct the rest from principal
            interestAmountRepayed = currentInterest;
            uint256 amountAfterInterest = amount.sub(currentInterest);
            
            if(loans[loanId].principal > amountAfterInterest) {
                //deduct amount from Borrower and reduce the principal
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(amountAfterInterest);
                loans[loanId].principal = loans[loanId].principal.sub(amountAfterInterest);
            } else {
                //deduct totalLoanValue
                uint256 totalLoanValue = loans[loanId].principal.add(currentInterest);
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), totalLoanValue);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(loans[loanId].principal);
                loans[loanId].principal = 0;
                //Send PropToken back to borrower
                PropToken0(propTokenContractAddress).safeTransferFrom(address(this), loans[loanId].borrower, loanToPropToken[loanId]);
            }

            //set interest accrued to 0 AFTER successful erc20 transfer
            loans[loanId].interestAccrued = 0;
        }

        //last payment timestamp is only updated AFTER  successful erc20 transfer
        loans[loanId].timeLastPayment = block.timestamp;

        //treat repayed interest as new money Lent into the pool
        poolLent = poolLent.add(interestAmountRepayed);

        //servicer fee is treated as cash investment in the pool as the percentage interest
        //calculate how much of payment goes to servicer here
        uint256 servicerFeeInERC = servicerFeePercentage.mul(interestAmountRepayed).div(loans[loanId].interestRate);
        mintProportionalPoolTokens(servicer, servicerFeeInERC);
    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**  
    *   @dev Function stake transfers users bHOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        bool successfulStake = PoolStaking0(poolStakingAddress).stake(msg.sender, amount);
        if(successfulStake) {
            transfer(poolStakingAddress, amount);
        }

        return successfulStake;
    }

    /**  
    *   @dev Function lendAndStake calls both the Lend and Stake functions in one call
    *   @param amount is amount of USDC to be deposited
    *   @return the bool from stake that reprents successful stake
    */
    function lendAndStake(uint256 amount) public returns (bool) {
        uint256 newPoolTokens = lend(amount);
        return stake(newPoolTokens);
    }

    /**  
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 4;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// contracts/Pool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777Rewardable.sol";
import './../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking4.sol';
import './../PoolStakingRewards/PoolStakingRewards3.sol';
import './../HomeBoost/HomeBoost0.sol';

import "./../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

// import "hardhat/console.sol";


contract Pool13 is Initializable, ERC20UpgradeableFromERC777Rewardable, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;

    // Address of the ERC-20 contract used as liquidity supply. USDC for now.
    address ERCAddress;

    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent;
    uint256 poolBorrowed;
    mapping(address => uint256[]) userLoans;
    Loan[] loans;
    uint256 loanCount;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 1000000;
    uint constant curveK = 120000000;

    /* Pool1 variables introduced here */
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) loanToPropToken;
    address propTokenContractAddress;

    /* Pool2 variables introduced here */
    address LTVOracleAddress;

    /* Pool3 variables introduced here */
    address poolUtilsAddress;
    address baconCoinAddress;
    address poolStakingAddress;

    /* Pool 8 variables introduced here */
    address daoAddress;

    /*  Pool 9 variables introduced here
        storage for nonReentrant modifier
        modifier and variables could not be imported via inheratance given upgradability rules */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /* pool10 variables added here */
    address poolStakingRewardAddress; // contract responsible for determining the rewards for staking bHome

    /*  Pool 11 variables introduced here */
    bool airdropLocked;

    /* Pool 13 variables here */
    address homeBoostAddress;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    function initializePool13(address _homeBoostAddress) public {
        require(msg.sender == servicer);
        homeBoostAddress = _homeBoostAddress;
    }

    function lockAirdorp() public {
        require(msg.sender == servicer);
        airdropLocked = true;
    }

    function passServicerRights(address _servicer) public {
        require(msg.sender == servicer);
        servicer = _servicer;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/
    /**
    *   @dev Function getContractData() returns a lot of variables about the contract
    */
    function getContractData() public view returns (address, address, uint256, uint256, uint256, uint256) {
        return (servicer, ERCAddress, poolLent, (poolLent + PoolUtils0(poolUtilsAddress).getPoolInterestAccrued()), poolBorrowed, loanCount);
    }

    /*
    *   @dev Function getLoanCount() returns how many active loans there are
    */
    function getLoanCount() public view returns (uint256) {
        return loanCount;
    }

    /**
    *   @dev Function getSupplyableTokenAddress() returns the contract address of ERC20 this pool accepts (ususally USDC)
    */
    function getSupplyableTokenAddress() public view returns (address) {
        return ERCAddress;
    }

    /**
    *   @dev Function getServicerAddress() returns the address of this pool's servicer
    */
    function getServicerAddress() public view returns (address) {
        return servicer;
    }

    /**
    *   @dev Function getLoanDetails() returns an all the raw details about a loan
    *   @param loanId is the id for the loan we're looking up
    *   EDITED in pool1 to also return PropToken ID
    */
    function getLoanDetails(uint256 loanId) public view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        Loan memory loan = loans[loanId];
        //temp interestAccrued calculation because this is a read function
        uint256 interestAccrued = getLoanAccruedInterest(loanId);
        uint256 propTokenID = loanToPropToken[loanId];
        return (loan.loanId, loan.borrower, loan.interestRate, loan.principal, interestAccrued, loan.timeLastPayment, propTokenID);
    }

    /**
    *   @dev Function getLoanAccruedInterest() calculates and returns the amount of interest accrued on a given loan
    *   @param loanId is the id for the loan we're looking up
    */
    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 secondsSincePayment = block.timestamp.sub(loan.timeLastPayment);

        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31104000);
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100000000);
        return interestAccrued.add(loan.interestAccrued);
    }


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    /**
    *   @dev Function lend moves assets on the (probably usdc) contract to our own balance
    *   - Before calling: an approve(address _spender (proxy), uint256 _value (0xffff)) function call must be made on remote contract
    *   @param amount The amount of USDC to be transferred
    *   @return the amount of poolTokens created
    */
    function lend(
        uint256 amount
    ) public nonReentrant returns (uint256) {
        IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);

        poolLent = poolLent.add(amount);

        super._mint(msg.sender, amount);

        return amount;
    }

    /**
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public nonReentrant {
        // check to see if sender has enough HOME to redeem
        require(balanceOf(msg.sender) >= amount, "HOME balance insufficient");

        // check to make sure there is liquidity available in the pool to withdraw
        require(amount <= (poolLent - poolBorrowed), "not enough USDC to redeem");

        // check to make sure there's enough unlocked liquidity in the pool.
        // funds staked or locked are unavailable for redemption -- only borrowing.
        uint256 locked = balanceOf(poolStakingAddress) + balanceOf(homeBoostAddress);
        require(amount <= (poolLent - locked), "not enough unlocked USDC to redeem");

        // burn HOME
        super._burn(msg.sender, amount);

        // update the amount of liquidity held
        poolLent = poolLent.sub(amount);

        // send out the USDC
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, amount);
    }

    /**
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param maxRate The size of the potential loan in (probably usdc).
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    */
    function borrow(uint256 amount, uint256 maxRate, uint256 propTokenId) public nonReentrant {
        //for v2 require this address is approved to transfer propToken
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");
        //also require msg.sender is owner of token
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        //check the requested interest rate is still available
        uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        //require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        //require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");


        //first take the propToken
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        //create new Loan
        Loan memory newLoan = Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp);
        loans.push(newLoan);
        userLoans[msg.sender].push(loanCount);

        //map new loanID to Token ID
        loanToPropToken[loanCount] = propTokenId;

        //update system variables
        loanCount = loanCount.add(1);
        poolBorrowed = poolBorrowed.add(amount);

        // Finally move the funds. 99% to the borrower. 0.5% to servicer. 0.5% to DAO.
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, amount.mul(99).div(100));
        super._mint(servicer, amount.div(200));
        super._mint(daoAddress, amount.div(200));
    }

    /**
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal.
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED - Pool1 returns propToken when principal reaches 0
    */

    function repay(uint256 loanId, uint256 amount) public nonReentrant {
        //interestAmountRepayed keeps track of how much of the loan was returned to the pool to calculate servicer fee(treated as cash investment)
        uint256 interestAmountRepayed = amount;

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        if(currentInterest > amount) {
            //if the payment is less than the interest accrued on the loan, just deduct amount from interest
            //deduct amount FIRST (to make sure they have available balance), then reduce loan amount
            IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
            loans[loanId].interestAccrued = currentInterest.sub(amount);
        } else {
            //if the amount borrow is repaying is greater than interest accrued, deduct the rest from principal
            interestAmountRepayed = currentInterest;
            uint256 amountAfterInterest = amount.sub(currentInterest);

            if(loans[loanId].principal > amountAfterInterest) {
                //deduct amount from Borrower and reduce the principal
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);

                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(amountAfterInterest);
                loans[loanId].principal = loans[loanId].principal.sub(amountAfterInterest);
            } else {
                //deduct totalLoanValue
                uint256 totalLoanValue = loans[loanId].principal.add(currentInterest);
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), totalLoanValue);

                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(loans[loanId].principal);
                loans[loanId].principal = 0;

                //Send PropToken back to borrower
                PropToken0(propTokenContractAddress).safeTransferFrom(address(this), loans[loanId].borrower, loanToPropToken[loanId]);
            }

            //set interest accrued to 0 AFTER successful erc20 transfer
            loans[loanId].interestAccrued = 0;
        }

        //last payment timestamp is only updated AFTER  successful erc20 transfer
        loans[loanId].timeLastPayment = block.timestamp;

        // Treat repayed interest as new money Lent into the pool
        poolLent = poolLent.add(interestAmountRepayed);

        //servicer fee is treated as cash investment in the pool as the percentage interest
        //calculate how much of payment goes to servicer here
        uint256 servicerFeeInERC = servicerFeePercentage.mul(interestAmountRepayed).div(loans[loanId].interestRate);

        // Mint bHOME proportional to the payment and distribute
        super._mint(servicer, servicerFeeInERC.div(2));
        super._mint(daoAddress, servicerFeeInERC.div(2));

        // Send the remaining interest to the DAO for now
        super._mint(daoAddress, interestAmountRepayed.sub(servicerFeeInERC));
    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**
    *   @dev Function stake transfers users bHOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        transfer(poolStakingAddress, amount);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amount);
        require(successfulStake, "Stake failed");

        return successfulStake;
    }

    function boost(uint256 amount, uint16 level, bool autoRenew) public returns (bool){
        require(balanceOf(msg.sender) >= amount, "Not enough to boost");

        // Deposit the funds with the staking contract so they can still earn Bacon.
        // Send all tokens to the staking contract to hold them for the user.
        // Only stake a proportion so the boost earns the appropraite amount of Bacon.
        uint256 amountToStake = HomeBoost0(homeBoostAddress).getStakeAmount(level, amount);

        transfer(poolStakingAddress, amountToStake);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amountToStake);

        // Send any remaining unstaked amounts to the boost contract for holding.
        if (amountToStake < amount) {
            transfer(homeBoostAddress, amount - amountToStake);
        }

        // Create the boost
        bool successfulBoost = HomeBoost0(homeBoostAddress).mint(msg.sender, amount, level, autoRenew);

        require(successfulStake && successfulBoost, "Boost failed");

        return successfulStake && successfulBoost;
    }

    /**
    *   @dev Function lendAndStake calls both the Lend and Stake functions in one call
    *   @param amount is amount of USDC to be deposited
    *   @return the bool from stake that reprents successful stake
    */
    function lendAndStake(uint256 amount) public returns (bool) {
        uint256 newPoolTokens = lend(amount);
        return stake(newPoolTokens);
    }

    /**
    *   @dev Function lendAndBoost calls both the Lend and Boost functions in one call
    *   @param amount is amount of USDC to be deposited
    *   @param level is boost level to enter
    *   @param autoRenew is whether to continuously renew the boost
    *   @return the bool from boost that reprents successful boost
    */
    function lendAndBoost(uint256 amount, uint16 level, bool autoRenew) public returns (bool) {
        uint256 newPoolTokens = lend(amount);
        return boost(amount, level, autoRenew);
    }

    /**
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 13;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function claimRewards() public returns (uint256) {
        // 1% Rewards [div by 100]
        uint256 unstakedRewards = super.getAndClearReward(msg.sender).div(100);

        uint256 stakedRewards = PoolStakingRewards3(poolStakingRewardAddress).getAndClearReward(msg.sender).div(100);

        uint256 rewards = unstakedRewards + stakedRewards;

        super._transfer(daoAddress, msg.sender, rewards);

        return rewards;
    }

    function transferBoostRewards(address wallet, uint256 amount) public {
        require(msg.sender == homeBoostAddress, "invalid sender");

        // console.log('transfering %s from %s to %s', amount, daoAddress, wallet);

        super._transfer(daoAddress, wallet, amount);
    }

    /**
    * @dev Function burn burns bHOME
    * @param amount is the amount of bHOME to burn
    */
    function burn(uint256 amount) public {
        super._burn(msg.sender, amount);
    }

}

// contracts/Pool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking0.sol';
import './../PoolStakingRewards/PoolStakingRewards0.sol';

import "../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract Pool10 is Initializable, ERC20UpgradeableFromERC777, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;
    address ERCAddress;
    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent;
    uint256 poolBorrowed;
    mapping(address => uint256[]) userLoans;
    Loan[] loans;
    uint256 loanCount;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 1000000;
    uint constant curveK = 120000000;

    /* Pool1 variables introduced here */
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) loanToPropToken;
    address propTokenContractAddress;

    /* Pool2 variables introduced here */
    address LTVOracleAddress;

    /* Pool3 variables introduced here */
    address poolUtilsAddress;
    address baconCoinAddress;
    address poolStakingAddress;

    /* Pool 8 variables introduced here */
    address daoAddress;

    /*  Pool 9 variables introduced here 
        storage for nonReentrant modifier 
        modifier and variables could not be imported via inheratance given upgradability rules */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /* pool10 variables added here */
    address poolStakingRewardAddress; // contract responsible for determining the rewards for staking bHome

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function initializePool9() public {
        require(msg.sender == servicer, "unapproved sender");
        _status = _NOT_ENTERED;
    }

    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/
    /**
    *   @dev Function getContractData() returns a lot of variables about the contract
    */
    function getContractData() public view returns (address, address, uint256, uint256, uint256, uint256) {
        return (servicer, ERCAddress, poolLent, (poolLent + PoolUtils0(poolUtilsAddress).getPoolInterestAccrued()), poolBorrowed, loanCount);
    }

    /*
    *   @dev Function getLoanCount() returns how many active loans there are
    */ 
    function getLoanCount() public view returns (uint256) {
        return loanCount;
    }

    /**  
    *   @dev Function getSupplyableTokenAddress() returns the contract address of ERC20 this pool accepts (ususally USDC)
    */
    function getSupplyableTokenAddress() public view returns (address) {
        return ERCAddress;
    }

    /**  
    *   @dev Function getServicerAddress() returns the address of this pool's servicer
    */
    function getServicerAddress() public view returns (address) {
        return servicer;
    } 

    /**  
    *   @dev Function getLoanDetails() returns an all the raw details about a loan
    *   @param loanId is the id for the loan we're looking up
    *   EDITED in pool1 to also return PropToken ID
    */
    function getLoanDetails(uint256 loanId) public view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        Loan memory loan = loans[loanId];
        //temp interestAccrued calculation because this is a read function
        uint256 interestAccrued = getLoanAccruedInterest(loanId);
        uint256 propTokenID = loanToPropToken[loanId];
        return (loan.loanId, loan.borrower, loan.interestRate, loan.principal, interestAccrued, loan.timeLastPayment, propTokenID);
    }

    /**  
    *   @dev Function getLoanAccruedInterest() calculates and returns the amount of interest accrued on a given loan
    *   @param loanId is the id for the loan we're looking up
    */
    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 secondsSincePayment = block.timestamp.sub(loan.timeLastPayment);

        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31104000);
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100000000);
        return interestAccrued.add(loan.interestAccrued);
    }   


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    /*
    *   @dev Function getProportionalPoolTokens calculates how many new hc_pool tokens to mint when value is added to the pool based on proportional value
    *   @param recepient The address of the wallet receiving the newly minted hc_pool tokens
    *   @param amount The amount to be minted
    */
    function getProportionalPoolTokens(uint256 amount) private view returns (uint256) {
        //check if this is first deposit
        if (poolLent == 0) {
            return amount;
        } else {
            //Calculate proportional to total value
            uint256 new_hc_pool = amount.mul(super.totalSupply()).div(poolLent);
            return new_hc_pool;
        }
    }

    /**
    *   @dev Function lend moves assets on the (probably usdc) contract to our own balance
    *   - Before calling: an approve(address _spender (proxy), uint256 _value (0xffff)) function call must be made on remote contract
    *   @param amount The amount of USDC to be transferred
    *   @return the amount of poolTokens created
    */
    function lend(
        uint256 amount
    ) public nonReentrant returns (uint256) {
        //USDC on Ropsten only right now
        IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
        uint256 newTokensMinted = getProportionalPoolTokens(amount);
        poolLent = poolLent.add(amount);

        super._mint(msg.sender, newTokensMinted);

        return newTokensMinted;
    }

    /**
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public nonReentrant {
        //check to see if sender has enough hc_pool to redeem
        require(balanceOf(msg.sender) >= amount);

        //check to make sure there is liquidity available in the pool to withdraw
        uint256 tokenPrice = poolLent.mul(1000000).div(super.totalSupply());
        uint256 erc20ValueOfTokens = amount.mul(tokenPrice).div(1000000);
        require(erc20ValueOfTokens <= (poolLent - poolBorrowed));

        //burn hcPool first
        super._burn(msg.sender, amount);
        poolLent = poolLent.sub(erc20ValueOfTokens);
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, erc20ValueOfTokens);
    }

    /**
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param maxRate The size of the potential loan in (probably usdc).
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    */
    function borrow(uint256 amount, uint256 maxRate, uint256 propTokenId) public nonReentrant {
        //for v2 require this address is approved to transfer propToken 
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");
        //also require msg.sender is owner of token
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        //check the requested interest rate is still available
        uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        //require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        //require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");


        //first take the propToken
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        //create new Loan
        Loan memory newLoan = Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp);
        loans.push(newLoan);
        userLoans[msg.sender].push(loanCount);

        //map new loanID to Token ID
        loanToPropToken[loanCount] = propTokenId;

        //update system variables
        loanCount = loanCount.add(1);
        poolBorrowed = poolBorrowed.add(amount);

        //finally move the USDC
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, amount);

        //then mint HC_Pool for the servicer (fixed 0.5% origination is better than standard 2.5%)
        uint256 newTokensMinted = getProportionalPoolTokens(amount.div(200));
        super._mint(servicer, newTokensMinted);
        super._mint(daoAddress, newTokensMinted);
    }

    /**
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal.
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED - Pool1 returns propToken when principal reaches 0
    */

    function repay(uint256 loanId, uint256 amount) public nonReentrant {        
        //interestAmountRepayed keeps track of how much of the loan was returned to the pool to calculate servicer fee(treated as cash investment)
        uint256 interestAmountRepayed = amount;

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        if(currentInterest > amount) {
            //if the payment is less than the interest accrued on the loan, just deduct amount from interest
            //deduct amount FIRST (to make sure they have available balance), then reduce loan amount
            IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
            loans[loanId].interestAccrued = currentInterest.sub(amount);
        } else {
            //if the amount borrow is repaying is greater than interest accrued, deduct the rest from principal
            interestAmountRepayed = currentInterest;
            uint256 amountAfterInterest = amount.sub(currentInterest);

            if(loans[loanId].principal > amountAfterInterest) {
                //deduct amount from Borrower and reduce the principal
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(amountAfterInterest);
                loans[loanId].principal = loans[loanId].principal.sub(amountAfterInterest);
            } else {
                //deduct totalLoanValue
                uint256 totalLoanValue = loans[loanId].principal.add(currentInterest);
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), totalLoanValue);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(loans[loanId].principal);
                loans[loanId].principal = 0;
                //Send PropToken back to borrower
                PropToken0(propTokenContractAddress).safeTransferFrom(address(this), loans[loanId].borrower, loanToPropToken[loanId]);
            }

            //set interest accrued to 0 AFTER successful erc20 transfer
            loans[loanId].interestAccrued = 0;
        }

        //last payment timestamp is only updated AFTER  successful erc20 transfer
        loans[loanId].timeLastPayment = block.timestamp;

        //servicer fee is treated as cash investment in the pool as the percentage interest
        //calculate how much of payment goes to servicer here
        uint256 servicerFeeInERC = servicerFeePercentage.mul(interestAmountRepayed).div(loans[loanId].interestRate);
        uint256 newTokensMinted = getProportionalPoolTokens(servicerFeeInERC).div(2);

        //treat repayed interest as new money Lent into the pool
        poolLent = poolLent.add(interestAmountRepayed);

        super._mint(servicer, newTokensMinted);
        super._mint(daoAddress, newTokensMinted);
    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**  
    *   @dev Function stake transfers users bHOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        transfer(poolStakingAddress, amount);
        bool successfulStake = PoolStakingRewards0(poolStakingRewardAddress).stake(msg.sender, amount);
        require(successfulStake, "Stake failed");

        return successfulStake;
    }

    function linkPoolStaking(address _poolStakingAddress) public {
        require(msg.sender == servicer, "unapproved sender");
        poolStakingAddress = _poolStakingAddress;
    }

    function linkPoolStakingReward(address _poolStakingRewardAddress) public {
        require(msg.sender == servicer, "unapproved sender");
        poolStakingRewardAddress = _poolStakingRewardAddress;
    }

    /**  
    *   @dev Function lendAndStake calls both the Lend and Stake functions in one call
    *   @param amount is amount of USDC to be deposited
    *   @return the bool from stake that reprents successful stake
    */
    function lendAndStake(uint256 amount) public returns (bool) {
        uint256 newPoolTokens = lend(amount);
        return stake(newPoolTokens);
    }

    /**  
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 10;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LTVGuidelines {
    uint256 maxLoanToValue;

    constructor() {                  
        maxLoanToValue = 80;        
    } 
 
    // Defining function to 
    // return the value of 'str'  
    function getMaxLTV() public view returns (uint256) {        
        return maxLoanToValue;        
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SafeCast.sol';
import '../@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '../@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './../PoolStakingRewards/PoolStakingRewards4.sol';
import './../PoolCore/Pool13.sol';

// import "hardhat/console.sol";

contract HomeBoost0 is
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721Upgradeable
{
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint16;
    // 60 * 60 * 24
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_WEEK = SECONDS_PER_DAY * 7;
    // use mortgage year (360 days)
    uint256 constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 360;
    // 90 days
    uint256 constant LEVEL_1_SECONDS_PER_ITERATION = SECONDS_PER_DAY * 90;
    // 1 year
    uint256 constant LEVEL_2_SECONDS_PER_ITERATION = SECONDS_PER_DAY * 360;

    // Stored per boost token.
    struct Boost {
        uint64 startTime;
        uint64 principal;
        uint64 claimedRewards;
        uint64 additionalMatureSeconds; // accumulates seconds that the Boost was mature before being renewed.
        uint16 endIteration; // 0 for never (auto-renew) or a value for the number of iterations
        uint16 level;
    }

    // Used to get relevant details about boosts to callers into the contract (e.g. the UI)
    // Never written to storage.
    struct BoostDetail {
        uint256 id;
        uint256 startTime;
        uint256 principal;
        uint256 claimedRewards;
        uint256 totalRewards;
        uint256 apy;
        uint256 nextRewardTimestamp;
        uint16 level;
        bool isComplete; // true if time has passed the end of the last iteration
        bool isAutoRenew;
    }

    Boost[] private boostData;
    uint256 weeklyStartTime;
    uint256[] private weeklyInterestRates;

    address poolAddress;
    address guardianAddress;
    address poolStakingRewardAddress;
    mapping(address => bool) isApproved;
    string boostBaseURI;

    function initialize(string memory name, string memory symbol, address _guardianAddress, address _poolAddress, address _poolStakingRewardAddress) public initializer {
        // TODO: needed since we are already storing the pool address? 
        isApproved[_poolAddress] = true;
        poolAddress = _poolAddress;
        guardianAddress = _guardianAddress;
        poolStakingRewardAddress = _poolStakingRewardAddress;

        ERC721Upgradeable.__ERC721_init(name, symbol);

        // Push a null Boost into the list of boosts to act as a sentinel. This way anyone that points to boost id 0
        // will get the sentinel rather than the first boost created for a real user. Make sure to only do this once
        if (boostData.length == 0) {
            boostData.push(Boost(0, 0, 0, 0, 0, 0));
        }
    }

    ///
    /// Getters
    ///
    function _baseURI() internal view override returns (string memory) {
        return boostBaseURI;
    }

    //
    // returns startTime, principal, additionalMatureSeconds, endIteration, level
    // use getTokenData for a more human readable version of this data
    //
    function getRawTokenData(uint256 tokenId) public view returns(Boost memory) {
        return boostData[tokenId];
    }

    function getPerIterationRateForLevel(uint16 level, uint64 startTime, uint256 endTime) private view returns(uint256) {
        if (level == 1) {
            return 5000;
        } else if (level == 2) {
            return getPerIterationRateForLevel2(startTime, endTime);
        }

        return 0;
    }

    function getPerIterationRateForLevel2(uint64 startTime, uint256 endTime) public view returns(uint256) {
        if (weeklyInterestRates.length == 0 || startTime == endTime)
            return 0;

        require(startTime >= weeklyStartTime, "startTime must be greater because negatives are bad");
        uint256 startWeekNumber = (startTime - weeklyStartTime) / SECONDS_PER_WEEK;
        uint256 startWeekFraction =  ((startTime - weeklyStartTime) % SECONDS_PER_WEEK);

        // We're at the start, so we need the time elaspsed since the start to a week ending.
        // Mod takes it to zero if startWeekFraction is already zero. Might be better to if it.
        startWeekFraction = (SECONDS_PER_WEEK - startWeekFraction) % SECONDS_PER_WEEK;

        uint256 endWeekNumber = ((endTime - weeklyStartTime) / SECONDS_PER_WEEK);
        uint256 endWeekNumberFraction = ((endTime - weeklyStartTime) % SECONDS_PER_WEEK);
        require(endWeekNumber < weeklyInterestRates.length, "Weekly rate not set yet");

        // fracitonalSum isn't a uint. It's really interest seconds, but that's not a type here.
        uint256 fracitonalSum = (weeklyInterestRates[endWeekNumber] * endWeekNumberFraction);

        // We're still in the first week. All the other stuff is unnecessary.
        // And breaks if we don't exit early.
        if (endWeekNumber - startWeekNumber == 0)
           return fracitonalSum / (endTime - startTime);

        fracitonalSum += (weeklyInterestRates[startWeekNumber] * startWeekFraction);

        // The first week is handled in the loop, if there's no fractional part.
        if (startWeekFraction > 0)
          startWeekNumber += 1;

        // sum is actually interest weeks.
        uint256 sum = 0;
        uint256 i;

        for (i = startWeekNumber; i < endWeekNumber; i++) {
          sum += weeklyInterestRates[i];
        }

        // Normalize the return to interest/timespan.
        sum = ((sum * SECONDS_PER_WEEK) + fracitonalSum) / (endTime - startTime);
        return sum;
    }

    function getAPYForLevel(uint16 level) public view returns(uint256) {
        if (level == 1) {
            return 20000;
        } else if (level == 2) {
            if (weeklyInterestRates.length == 0)
              return 0;
            return weeklyInterestRates[weeklyInterestRates.length - 1];
        }
        return 0;
    }

    //
    // Returns the amount of token that is sent to staking to earn BACON rewards
    //
    function getStakeAmount(uint16 level, uint256 rawAmount) public pure returns(uint256) {
        if (level == 1) {
            return rawAmount.div(2); // 50% of the rewards
        } else if (level == 2) {
            return rawAmount;        // 100% of the rewards
        }
        return 0;
    }


    function getSecondsPerIteration(uint16 level) private pure returns(uint256) {
        if (level == 1) {
            return LEVEL_1_SECONDS_PER_ITERATION;
        } else if (level == 2) {
            return LEVEL_2_SECONDS_PER_ITERATION;
        }
        return 0;
    }

    function getNextRewardTimestamp(Boost memory boost) private view returns(uint256) {
        if (boost.endIteration == 0) {
            uint256 nextIteration = (block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level)) + 1;
            return boost.startTime + getSecondsPerIteration(boost.level).mul(nextIteration);
        } else {
            return boost.startTime + getSecondsPerIteration(boost.level).mul(boost.endIteration);
        }
    }

    //
    // Returns a list of token data structures, one for each token owned by the caller.
    //
    function getTokens() public view returns(BoostDetail[] memory)
    {
        uint256 ownedTokens = balanceOf(msg.sender);
        BoostDetail[] memory details = new BoostDetail[](ownedTokens);
        if (ownedTokens == 0) {
            return details;
        }
        uint256 currentDetailIndex = 0;
        // Index 0 is a placeholder so skip it.
        for(uint256 currentId = 1; currentId < boostData.length; currentId++) {
            if (!_exists(currentId) || ownerOf(currentId) != msg.sender){
                continue;
            }

            if (currentDetailIndex == details.length){
                break;
            }

            Boost storage currentBoost = boostData[currentId];
            uint256 nextRewardTimestamp = getNextRewardTimestamp(currentBoost);
            details[currentDetailIndex] = BoostDetail(
                currentId,
                currentBoost.startTime,
                currentBoost.principal,
                currentBoost.claimedRewards,
                computeTotalRewards(currentBoost, nextRewardTimestamp),
                getAPYForLevel(currentBoost.level),
                nextRewardTimestamp,
                currentBoost.level,
                nextRewardTimestamp < block.timestamp,
                currentBoost.endIteration == 0
            );

            currentDetailIndex++;
        }

        return details;
    }


    ///
    /// Mutations
    ///

    function approveAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = true;
    }

    function revokeAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = false;
    }

    function setBoostBaseUri(string memory _boostBaseURI) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        boostBaseURI = _boostBaseURI;
    }

    function pause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _pause();
    }

    function unpause() public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        _unpause();
    }

    // Create a boost token
    function mint(address to, uint256 principal, uint16 level, bool autoRenew) public whenNotPaused nonReentrant returns (bool) {
        require(isApproved[msg.sender], "Caller must be approved");

        uint16 endIteration = autoRenew ? 0 : 1;

        boostData.push(Boost(SafeCast.toUint64(block.timestamp), SafeCast.toUint64(principal), 0, 0, endIteration, level));
        uint256 tokenId = boostData.length - 1;

        _safeMint(to, tokenId);
        
        return true;
    }

    function beforeIterationChange(Boost storage boost) private {
        if (getNextRewardTimestamp(boost) < block.timestamp) {
            // Boost is mature so we have to record the number of days that it was mature so we can pay interest on them
            uint256 boostedDuration = getSecondsPerIteration(boost.level).mul(boost.endIteration);
            boost.additionalMatureSeconds += SafeCast.toUint64(block.timestamp - (boost.startTime + boostedDuration));
            boost.startTime = SafeCast.toUint64(block.timestamp - boostedDuration);
        }
    }

    // Set a boost to auto renew.
    // if boost is already auto renew do nothing
    // if boost is not yet mature, just set the iteration count to 0
    // else boost is mature, stash the additionalMatureSeconds, set startTime to currentBlockTime - iterationCount*iterationDuration and set iterationCount to 0
    function setToAutoRenew(uint256 boostId) public whenNotPaused{
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        if (boost.endIteration == 0) {
            return;
        }

        beforeIterationChange(boost);

        boost.endIteration = 0;
    }

    // End the auto renew on a boost. This will allow it to be claimed when the current iteration is over.
    function endAutoRenew(uint256 boostId) public whenNotPaused {
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        if (boost.endIteration != 0) {
            return;
        }

        boost.endIteration = (uint16) ((block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level)) + 1);
    }

    // claim the rewards and principal from a boost. This also burns the boost token.
    function claimPrincipal(uint256 boostId) public whenNotPaused nonReentrant returns (uint256) {
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        // endAutoRenew must be called first
        require(boost.endIteration != 0, "Must not be autoRenew");
        // boost must be mature
        uint256 nextRewardTimestamp = getNextRewardTimestamp(boost);
        require(nextRewardTimestamp < block.timestamp, "Still locked");

        uint256 claimedRewards = claimRewardsCore(boost, nextRewardTimestamp);

        _burn(boostId);
        // Portions of the Principal is held by the staking contract so that it can earn bacon.
        uint256 amountStaked = getStakeAmount(boost.level, boost.principal);
        PoolStakingRewards4(poolStakingRewardAddress).unstakeForWallet(msg.sender, amountStaked);

        if (amountStaked < boost.principal) {
            // Return the non-staked boost principal held in this contract
            IERC20(poolAddress).transfer(msg.sender, boost.principal - amountStaked);
        }

        return boost.principal + claimedRewards;
    }

    // Allow users to unstake all HOME staked using the old staking methods.
    function claimPreBoostStake() public whenNotPaused nonReentrant returns (uint256) {
        uint256 ownedTokenCount = balanceOf(msg.sender);
        uint256 stakedAmount = PoolStakingRewards4(poolStakingRewardAddress).getCurrentBalance(msg.sender);

        uint boostStakedAmount = 0;
        if (ownedTokenCount > 0) {
            // compute the total amount staked by boosts. This is going to grow in cost as the total number of boosts
            // grows, but the common case should be calling this once when the caller has 0 boosts.
            uint256 currentOwnedIndex = 0;
            // Index 0 is a placeholder so skip it.
            for(uint256 currentId = 1; currentId < boostData.length; currentId++) {
                if (!_exists(currentId) || ownerOf(currentId) != msg.sender){
                    continue;
                }

                if (currentOwnedIndex == ownedTokenCount){
                    break;
                }

                Boost storage boost = boostData[currentId];
                boostStakedAmount = boostStakedAmount.add(getStakeAmount(boost.level, boost.principal));

                currentOwnedIndex++;
            }
        }

        //
        uint256 amount = stakedAmount.sub(boostStakedAmount);

        PoolStakingRewards4(poolStakingRewardAddress).unstakeForWallet(msg.sender, amount);

        return amount;
    }

    // Claim all the rewards that can be claimed from this boost. This is only what is earned from past iterations.
    function claimRewards(uint256 boostId) public whenNotPaused nonReentrant returns (uint256) {
        // Claim only the rewards that have been earned so far in this boost - the rewards that have already been claimed
        require(ownerOf(boostId) == msg.sender, "Not the owner");
        Boost storage boost = boostData[boostId];
        uint256 nextRewardTimestamp = getNextRewardTimestamp(boost);

        return claimRewardsCore(boost, nextRewardTimestamp);
    }

    function computeTotalRewards(Boost storage boost, uint256 nextRewardTimestamp) private view returns (uint256) {
        uint256 totalRewardAmount;
        uint256 newMatureSeconds = 0;
        // if the boost is mature, then just udpate how long we've been mature and pay those rewards
        if (nextRewardTimestamp < block.timestamp) {
            newMatureSeconds = block.timestamp - nextRewardTimestamp;
            totalRewardAmount = boost.principal.mul(boost.endIteration).mul(getPerIterationRateForLevel(boost.level, boost.startTime, nextRewardTimestamp)).div(1000000);
        } else {
            // Otherwise the boost isn't mature. We can pay rewards up to the last full iteration
            uint256 completeIterations = (block.timestamp - boost.startTime).div(getSecondsPerIteration(boost.level));
            totalRewardAmount = boost.principal.mul(completeIterations).mul(getPerIterationRateForLevel(boost.level, boost.startTime, block.timestamp)).div(1000000);
        }
        totalRewardAmount += boost.principal.mul(boost.additionalMatureSeconds + newMatureSeconds).div(SECONDS_PER_YEAR).div(100);
        return totalRewardAmount;
    }

    function claimRewardsCore(Boost storage boost, uint256 nextRewardTimestamp) private returns (uint256) {
        uint256 totalRewardAmount = computeTotalRewards(boost, nextRewardTimestamp);
        // subtract out the rewards that we have already paid
        uint256 rewardAmount = totalRewardAmount.sub(boost.claimedRewards);
        boost.claimedRewards = SafeCast.toUint64(totalRewardAmount);

        // pay the rewards if there are any
        if (rewardAmount > 0) {
            Pool13(poolAddress).transferBoostRewards(msg.sender, rewardAmount);
        }

        return rewardAmount;
    }

    function appendInterestRate(uint256 newRate) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        weeklyInterestRates.push(newRate);
    }

    function setWeeklyStartTime(uint256 _weeklyStartTime) public {
        require(msg.sender == guardianAddress, "caller must be guardian");
        weeklyStartTime = _weeklyStartTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

// import "./IERC20Upgradeable.sol";
// import "./extensions/IERC20MetadataUpgradeable.sol";
// import "../../utils/ContextUpgradeable.sol";
// import "../../proxy/utils/Initializable.sol";
// import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";

import './../@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
import "./../@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';

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
contract ERC20UpgradeableFromERC777Rewardable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
/// ERC777 Storage
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;


/// ERC20 Code

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _getBalance(_balances[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalanceStorage = _balances[sender];
        uint256 senderBalance = _getBalance(senderBalanceStorage);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _setBalance(sender, senderBalanceStorage, senderBalance - amount);
        }

        uint256 recipientBalanceStorage = _balances[recipient];
        _setBalance(recipient, recipientBalanceStorage, _getBalance(recipientBalanceStorage) + amount);

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 recepientBalanceStorage = _balances[account];

        _totalSupply += amount;
        _setBalance(account, recepientBalanceStorage, _getBalance(recepientBalanceStorage) + amount);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalanceStorage = _balances[account];
        uint256 accountBalance = _getBalance(accountBalanceStorage);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _setBalance(account, accountBalanceStorage, accountBalance - amount);
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

// ERC777 Storage
    mapping(address => uint256) private _accrued;
    uint256[40] private __gap;


// Rewards tracking
    uint256 constant BASE_MASK     = 0xffffffffffffffffffffffff000000000000000000000000;
    uint256 constant BALANCE_MASK  = 0x000000000000000000000000ffffffffffffffffffffffff;

    uint256 constant SHIFT = 2 ** 128;

    // 60 sec * 60 min * 24 hours * 360 days (mortgage year)
    uint256 constant SECONDS_PER_YEAR = 31104000;

    // Start time of rewards earning. June 1st 2022.
    uint256 constant STARTING_TIME = 1654041600;

    /**
     * @dev
     */
    function _getBalance(uint256 balanceStorage) private view returns (uint256) {
        return balanceStorage & BALANCE_MASK;
    }

    /**
     * @dev
     */
    function _getBase(uint256 balanceStorage) private view returns (uint256) {
        uint256 base = (balanceStorage & BASE_MASK).div(SHIFT);

        if (base == 0) {
            base = block.timestamp;
            if (_getBalance(balanceStorage) > 0) {
                base = STARTING_TIME;
            }
        }
        return base;
    }

    /**
     * @dev
     */
    function _getTokenSeconds(uint256 balanceStorage) private view returns (uint256) {
        return (block.timestamp.sub(_getBase(balanceStorage)).mul(_getBalance(balanceStorage)));
    }

    /**
     * @dev
     */
    function _setBalance(address account, uint256 balanceStorage, uint256 balance) private {
        if(balance == 0) {
            _accrued[account] += _getTokenSeconds(balanceStorage).div(SECONDS_PER_YEAR);
            _balances[account] = 0;
        } else {
            uint256 newBase = block.timestamp;
            if (_getTokenSeconds(balanceStorage).div(balance) < block.timestamp) {
                newBase = block.timestamp.sub(_getTokenSeconds(balanceStorage).div(balance));
            } else {
                _accrued[account] += _getTokenSeconds(balanceStorage).div(SECONDS_PER_YEAR);
            }
            _balances[account] = newBase.mul(SHIFT) | (balance & BALANCE_MASK);
        }
    }

    /**
     * @dev
     *
     * Requirements:
     *
     */
    function getAndClearReward(address account) internal virtual returns (uint256) {
        uint256 reward = 0;

        reward += _accrued[_msgSender()];
        _accrued[_msgSender()] = 0;

        reward += _getTokenSeconds(_balances[_msgSender()]).div(SECONDS_PER_YEAR);
        _balances[_msgSender()] = block.timestamp.mul(SHIFT) | ((_balances[_msgSender()]) & BALANCE_MASK);

        return reward;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

// import "./IERC20Upgradeable.sol";
// import "./extensions/IERC20MetadataUpgradeable.sol";
// import "../../utils/ContextUpgradeable.sol";
// import "../../proxy/utils/Initializable.sol";
// import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";

import './../@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
import "./../@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
contract ERC20UpgradeableFromERC777 is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
/// ERC777 Storage
    using AddressUpgradeable for address;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;


/// ERC20 Code

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

// ERC777 Storage
    uint256[41] private __gap;
}

pragma solidity ^0.8.4;

interface ICurve {
  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy,
    address receiver
  ) external returns (uint256);

  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract BaconCoin3 is Initializable, ERC20UpgradeableFromERC777 {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    address stakingContract;
    address airdropContract;

    /// @notice DEPRECATED  
    /// A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice DEPRECATED  
    /// The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /*****************************************************
    *       Variables added in BaconCoin1
    ******************************************************/

    /// @notice A record of votes checkpoints for a delegate's account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public delegateCheckpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numDelegateCheckpoints;

    /*****************************************************
    *       EVENTS
    ******************************************************/
    
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /*****************************************************
    *       BASE FUNCTIONS
    ******************************************************/

    function setStakingContract(address _stakingContract) public {
        require(msg.sender == stakingContract, "Invalid sender");
        stakingContract = _stakingContract;
    }

    function rinkebyOnlySetStakingContract(address _stakingContract) public {
        require(msg.sender == 0x602eb5180Ce24240cf40f8BE124Cc4d3a2890686 && block.chainid == 4, "BaconCoin: Invalid sender or chain");
        stakingContract = _stakingContract;
    }

    // Transfer func must be overwritten to also moveDelegates when balance is transferred
    function transfer(address dst, uint amount) public override returns (bool) {
        require(super.transfer(dst, amount));
        _moveDelegates(delegates[msg.sender], delegates[dst], amount);
        return true;
    }

    // TransferFrom func must be overwritten to also moveDelegates when balance is transferred
    function transferFrom(address src, address dst, uint256 amount) public override returns (bool) {
        require(super.transferFrom(src, dst, amount));
        _moveDelegates(delegates[src], delegates[dst], amount);
        return true;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == stakingContract || msg.sender == airdropContract, "Invalid mint sender");
        super._mint(account, amount);
        _moveDelegates(address(0), delegates[account], amount);
    }

    function burn(uint256 amount, bytes memory data) public {
        super._burn(msg.sender, amount);
        _moveDelegates(delegates[msg.sender], address(0), amount);
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 3;
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
        return chainId;
    }

    /********************************
    *     GOVERNANCE FUNCTIONS      *
    *********************************/

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BaconCoin: invalid signature");
        require(nonce == nonces[signatory]++, "BaconCoin: invalid nonce");
        require(block.timestamp <= expiry, "BaconCoin: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numDelegateCheckpoints[account];
        return nCheckpoints > 0 ? delegateCheckpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "BaconCoin: not yet determined");

        uint32 nCheckpoints = numDelegateCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (delegateCheckpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return delegateCheckpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (delegateCheckpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = delegateCheckpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return delegateCheckpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numDelegateCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? delegateCheckpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numDelegateCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? delegateCheckpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BaconCoin: block number exceeds 32 bits");

      if (nCheckpoints > 0 && delegateCheckpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          delegateCheckpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          delegateCheckpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numDelegateCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}

// contracts/Pool0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract BaconCoin0 is Initializable, ERC777Upgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    address stakingContract;
    address airdropContract;

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /*****************************************************
    *       EVENTS
    ******************************************************/
    
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /*****************************************************
    *       BASE FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Calls the init function of the inherited ERC777 contract
    *   @param name Name of this particular ERC777 token
    *   @param symbol The ticker this token will go by
    */
    function initialize(string memory name, string memory symbol, address _stakingContractAddress, address _airdropContractAddress) public initializer {
        stakingContract = _stakingContractAddress;
        airdropContract = _airdropContractAddress;
        address[] memory operators;
        ERC777Upgradeable.__ERC777_init(name, symbol, operators );
    }

    // Transfer func must be overwritten to also moveDelegates when balance is transferred
    function transfer(address dst, uint amount) public override returns (bool) {
        require(super.transfer(dst, amount));
        _moveDelegates(delegates[msg.sender], delegates[dst], amount);
        return true;
    }

    // TransferFrom func must be overwritten to also moveDelegates when balance is transferred
    function transferFrom(address src, address dst, uint256 amount) public override returns (bool) {
        require(super.transferFrom(src, dst, amount));
        _moveDelegates(delegates[src], delegates[dst], amount);
        return true;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == stakingContract || msg.sender == airdropContract, "Invalid mint sender");
        super._mint(account, amount, "", "");
        _moveDelegates(address(0), account, amount);
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 0;
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
        return chainId;
    }

    /********************************
    *     GOVERNANCE FUNCTIONS      *
    *********************************/

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BaconCoin: invalid signature");
        require(nonce == nonces[signatory]++, "BaconCoin: invalid nonce");
        require(block.timestamp <= expiry, "BaconCoin: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "BaconCoin: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BaconCoin: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777SenderUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777RecipientUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777Upgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC777SenderUpgradeable.sol";
import "../ERC20/IERC20Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777Upgradeable is Initializable, ContextUpgradeable, IERC777Upgradeable, IERC20Upgradeable {
    using AddressUpgradeable for address;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev `defaultOperators` may be an empty array.
     */
    function __ERC777_init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC777_init_unchained(name_, symbol_, defaultOperators_);
    }

    function __ERC777_init_unchained(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = _msgSender();

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = _msgSender();

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _move(spender, holder, recipient, amount, "", "");

        uint256 currentAllowance = _allowances[holder][spender];
        require(currentAllowance >= amount, "ERC777: transfer amount exceeds allowance");
        _approve(holder, spender, currentAllowance - amount);

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777SenderUpgradeable(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777RecipientUpgradeable(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
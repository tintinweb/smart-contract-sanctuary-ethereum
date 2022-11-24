// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo
pragma solidity >=0.7.0;

contract ERC20 {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public auth { wards[usr] = 1; }
    function deny(address usr) public auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- ERC20 Data ---
    uint8   public constant decimals = 18;
    string  public name;
    string  public symbol;
    string  public constant version = "1";
    uint256 public totalSupply;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed src, address indexed usr, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function safeAdd_(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-add-overflow");
    }
    function safeSub_(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "math-sub-underflow");
    }

    constructor(string memory symbol_, string memory name_) {
        wards[msg.sender] = 1;
        symbol = symbol_;
        name = name_;

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    // --- ERC20 ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public virtual returns (bool)
    {
        require(balanceOf[src] >= wad, "cent/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "cent/insufficient-allowance");
            allowance[src][msg.sender] = safeSub_(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = safeSub_(balanceOf[src], wad);
        balanceOf[dst] = safeAdd_(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external virtual auth {
        balanceOf[usr] = safeAdd_(balanceOf[usr], wad);
        totalSupply    = safeAdd_(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) public {
        require(balanceOf[usr] >= wad, "cent/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max) {
            require(allowance[usr][msg.sender] >= wad, "cent/insufficient-allowance");
            allowance[usr][msg.sender] = safeSub_(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = safeSub_(balanceOf[usr], wad);
        totalSupply    = safeSub_(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }
    function burnFrom(address usr, uint wad) external {
        burn(usr, wad);
    }

    // --- Approve by signature ---
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'cent/past-deadline');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'cent-erc20/invalid-sig');
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity >=0.5.15;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

/// @notice abstract contract for FixedPoint math operations
/// defining ONE with 10^27 precision
abstract contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "./../fixed_point.sol";
import "tinlake-auth/auth.sol";
import "tinlake-math/math.sol";

interface TrancheLike {
    function epochUpdate(
        uint256 epochID,
        uint256 supplyFulfillment_,
        uint256 redeemFulfillment_,
        uint256 tokenPrice_,
        uint256 epochSupplyCurrency,
        uint256 epochRedeemCurrency
    ) external;
    function closeEpoch() external returns (uint256 totalSupply, uint256 totalRedeem);
    function payoutRequestedCurrency() external;
}

abstract contract AssessorLike is FixedPoint {
    // definitions
    function calcSeniorRatio(uint256 seniorAsset, uint256 NAV, uint256 reserve_)
        public
        pure
        virtual
        returns (uint256);
    function calcSeniorAssetValue(
        uint256 seniorRedeem,
        uint256 seniorSupply,
        uint256 currSeniorAsset,
        uint256 reserve_,
        uint256 nav_
    ) public pure virtual returns (uint256 seniorAsset);
    function calcSeniorRatio(
        uint256 seniorRedeem,
        uint256 seniorSupply,
        uint256 currSeniorAsset,
        uint256 newReserve,
        uint256 nav
    ) public pure virtual returns (uint256 seniorRatio);

    // definitions based on assessor state
    function calcSeniorTokenPrice(uint256 NAV, uint256 reserve) public virtual returns (uint256 tokenPrice);
    function calcJuniorTokenPrice(uint256 NAV, uint256 reserve) public virtual returns (uint256 tokenPrice);

    // get state
    function maxReserve() public view virtual returns (uint256);
    function calcUpdateNAV() public virtual returns (uint256);
    function seniorDebt() public virtual returns (uint256);
    function seniorBalance() public virtual returns (uint256);
    function seniorRatioBounds() public view virtual returns (uint256 minSeniorRatio, uint256 maxSeniorRatio);

    function totalBalance() public virtual returns (uint256);
    // change state
    function changeBorrowAmountEpoch(uint256 currencyAmount) public virtual;
    function changeSeniorAsset(uint256 seniorSupply, uint256 seniorRedeem) public virtual;
    function changeSeniorAsset(uint256 seniorRatio, uint256 seniorSupply, uint256 seniorRedeem) public virtual;
}

/// @notice The EpochCoordinator keeps track of the epochs and executes them.
/// An epoch execution happens with the maximum amount of redeem and supply which still satisfies
/// all constraints or at least improve certain pool constraints.
/// In most cases all orders can be fulfilled with order maximum without violating any constraints.
/// If it is not possible to satisfy all orders at maximum the coordinators opens a submission period.
/// The problem of finding the maximum amount of supply and redeem orders which still satisfies all constraints
/// can be seen as a linear programming (linear optimization problem).
/// The optimal solution can be calculated off-chain
contract EpochCoordinator is Auth, Math, FixedPoint {
    struct OrderSummary {
        // all variables are stored in currency
        uint256 seniorRedeem;
        uint256 juniorRedeem;
        uint256 juniorSupply;
        uint256 seniorSupply;
    }

    modifier minimumEpochTimePassed() {
        require(safeSub(block.timestamp, lastEpochClosed) >= minimumEpochTime);
        _;
    }
    // timestamp last epoch closed

    uint256 public lastEpochClosed;
    // default minimum length of an epoch
    // (1 day, with 10 min buffer, so we can close the epochs automatically on a daily basis at the same time)
    uint256 public minimumEpochTime = 1 days - 10 minutes;

    TrancheLike public juniorTranche;
    TrancheLike public seniorTranche;

    AssessorLike public assessor;

    uint256 public lastEpochExecuted;
    uint256 public currentEpoch;
    // current best solution submission for an epoch which satisfies all constraints
    OrderSummary public bestSubmission;
    // current best score of the best solution
    uint256 public bestSubScore;
    // flag which tracks if an submission period received a valid solution
    bool public gotFullValidSolution;
    // snapshot from the the orders in the tranches at epoch close
    OrderSummary public order;
    // snapshot from the senior token price at epoch close
    Fixed27 public epochSeniorTokenPrice;
    // snapshot from the junior token price at epoch close
    Fixed27 public epochJuniorTokenPrice;

    // snapshot from NAV (net asset value of the loans) at epoch close
    uint256 public epochNAV;
    // snapshot from the senior asset value at epoch close
    uint256 public epochSeniorAsset;
    // snapshot from reserve balance at epoch close
    uint256 public epochReserve;
    // flag which indicates if the coordinator is currently in a submission period
    bool public submissionPeriod;

    // weights of the scoring function
    // highest priority senior redeem and junior redeem before junior and senior supply
    uint256 public weightSeniorRedeem = 1000000;
    uint256 public weightJuniorRedeem = 100000;
    uint256 public weightJuniorSupply = 10000;
    uint256 public weightSeniorSupply = 1000;

    // challenge period end timestamp
    uint256 public minChallengePeriodEnd;
    // after a first valid solution is received others can submit better solutions
    // until challenge time is over
    uint256 public challengeTime;
    // if the current state is not healthy improvement submissions are allowed
    // ratio and reserve improvements receive score points
    // keeping track of the best improvements scores
    uint256 public bestRatioImprovement;
    uint256 public bestReserveImprovement;

    // flag for closing the pool (no new supplies allowed only redeem)
    bool public poolClosing = false;

    // constants
    int256 public constant SUCCESS = 0;
    int256 public constant NEW_BEST = 0;
    int256 public constant ERR_CURRENCY_AVAILABLE = -1;
    int256 public constant ERR_MAX_ORDER = -2;
    int256 public constant ERR_MAX_RESERVE = -3;
    int256 public constant ERR_MIN_SENIOR_RATIO = -4;
    int256 public constant ERR_MAX_SENIOR_RATIO = -5;
    int256 public constant ERR_NOT_NEW_BEST = -6;
    int256 public constant ERR_POOL_CLOSING = -7;
    uint256 public constant BIG_NUMBER = ONE * ONE;

    event File(bytes32 indexed name, uint256 value);
    event File(bytes32 indexed name, bool value);
    event Depend(bytes32 indexed contractName, address addr);

    constructor(uint256 challengeTime_) {
        challengeTime = challengeTime_;
        lastEpochClosed = block.timestamp;
        currentEpoch = 1;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice sets parameters for the epoch coordinator by wards
    /// @param name name of the parameter
    /// @param value value of the parameter
    function file(bytes32 name, uint256 value) public auth {
        if (name == "challengeTime") {
            challengeTime = value;
        } else if (name == "minimumEpochTime") {
            minimumEpochTime = value;
        } else if (name == "weightSeniorRedeem") {
            weightSeniorRedeem = value;
        } else if (name == "weightJuniorRedeem") {
            weightJuniorRedeem = value;
        } else if (name == "weightJuniorSupply") {
            weightJuniorSupply = value;
        } else if (name == "weightSeniorSupply") {
            weightSeniorSupply = value;
        } else {
            revert("unknown-name");
        }
        emit File(name, value);
    }

    /// @notice sets parameters for the epoch coordinator by wards
    /// @param name name of the parameter
    /// @param value boolean value
    function file(bytes32 name, bool value) public auth {
        if (name == "poolClosing") {
            poolClosing = value;
        } else {
            revert("unknown-name");
        }
        emit File(name, value);
    }

    /// @notice sets the dependency to another contract
    /// @param contractName name of the contract
    /// @param addr contract address
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "juniorTranche") juniorTranche = TrancheLike(addr);
        else if (contractName == "seniorTranche") seniorTranche = TrancheLike(addr);
        else if (contractName == "assessor") assessor = AssessorLike(addr);
        else revert();
        emit Depend(contractName, addr);
    }

    /// @notice an epoch can be closed after a minimum epoch time has passed
    /// closeEpoch creates a snapshot of the current lender state
    /// if all orders can be fulfilled epoch is executed otherwise
    /// submission period starts
    /// @return epochExecuted returns true if epoch is executed
    function closeEpoch() external minimumEpochTimePassed returns (bool epochExecuted) {
        require(submissionPeriod == false);
        lastEpochClosed = block.timestamp;
        currentEpoch = currentEpoch + 1;
        assessor.changeBorrowAmountEpoch(0);

        (uint256 orderJuniorSupply, uint256 orderJuniorRedeem) = juniorTranche.closeEpoch();
        (uint256 orderSeniorSupply, uint256 orderSeniorRedeem) = seniorTranche.closeEpoch();
        epochSeniorAsset = safeAdd(assessor.seniorDebt(), assessor.seniorBalance());

        // create a snapshot of the current lender state
        epochNAV = assessor.calcUpdateNAV();
        epochReserve = assessor.totalBalance();
        //  if no orders exist epoch can be executed without validation
        if (orderSeniorRedeem == 0 && orderJuniorRedeem == 0 && orderSeniorSupply == 0 && orderJuniorSupply == 0) {
            juniorTranche.epochUpdate(currentEpoch, 0, 0, 0, 0, 0);
            seniorTranche.epochUpdate(currentEpoch, 0, 0, 0, 0, 0);
            // assessor performs re-balancing
            assessor.changeSeniorAsset(0, 0);
            assessor.changeBorrowAmountEpoch(epochReserve);
            lastEpochExecuted = safeAdd(lastEpochExecuted, 1);
            return true;
        }

        // calculate current token prices which are used for the execute

        epochSeniorTokenPrice = Fixed27(assessor.calcSeniorTokenPrice(epochNAV, epochReserve));
        epochJuniorTokenPrice = Fixed27(assessor.calcJuniorTokenPrice(epochNAV, epochReserve));
        // start closing the pool if juniorTranche lost everything
        // the flag will change the behaviour of the validate function for not allowing new supplies
        if (epochJuniorTokenPrice.value == 0) {
            poolClosing = true;
        }

        // convert redeem orders in token into currency
        order.seniorRedeem = rmul(orderSeniorRedeem, epochSeniorTokenPrice.value);
        order.juniorRedeem = rmul(orderJuniorRedeem, epochJuniorTokenPrice.value);
        order.juniorSupply = orderJuniorSupply;
        order.seniorSupply = orderSeniorSupply;

        // epoch is executed if orders can be fulfilled to 100% without constraint violation
        if (validate(order.seniorRedeem, order.juniorRedeem, order.seniorSupply, order.juniorSupply) == SUCCESS) {
            _executeEpoch(order.seniorRedeem, order.juniorRedeem, orderSeniorSupply, orderJuniorSupply);
            return true;
        }
        // if 100% order fulfillment is not possible submission period starts
        // challenge period time starts after first valid submission is received
        submissionPeriod = true;
        return false;
    }

    /// @notice internal method to save new optimum for a solution
    /// orders are expressed as currency
    /// all parameter are 10^18
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param juniorSupply junior supply amount
    /// @param seniorSupply senior supply amount
    /// @param score score of the new optimum
    function _saveNewOptimum(
        uint256 seniorRedeem,
        uint256 juniorRedeem,
        uint256 juniorSupply,
        uint256 seniorSupply,
        uint256 score
    ) internal {
        bestSubmission.seniorRedeem = seniorRedeem;
        bestSubmission.juniorRedeem = juniorRedeem;
        bestSubmission.juniorSupply = juniorSupply;
        bestSubmission.seniorSupply = seniorSupply;

        bestSubScore = score;
    }

    /// @notice method to submit a solution for submission period
    /// anybody can submit a solution for the current execution epoch
    /// if solution satisfies all constraints (or at least improves an unhealthy state)
    /// and has the highest score
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param juniorSupply junior supply amount
    /// @param seniorSupply senior supply amount
    /// @return accepted returns 0 if a solution has been accepted otherwise an error code
    function submitSolution(uint256 seniorRedeem, uint256 juniorRedeem, uint256 juniorSupply, uint256 seniorSupply)
        public
        returns (int256 accepted)
    {
        require(submissionPeriod == true, "submission-period-not-active");

        int256 valid = _submitSolution(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply);

        // if solution is the first valid for this epoch the challenge period starts
        if (valid == SUCCESS && minChallengePeriodEnd == 0) {
            minChallengePeriodEnd = safeAdd(block.timestamp, challengeTime);
        }
        return valid;
    }

    // internal method for submit solution
    function _submitSolution(uint256 seniorRedeem, uint256 juniorRedeem, uint256 juniorSupply, uint256 seniorSupply)
        internal
        returns (int256)
    {
        int256 valid = validate(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

        // every solution needs to satisfy all core constraints
        // there is no exception
        if (valid == ERR_CURRENCY_AVAILABLE || valid == ERR_MAX_ORDER || valid == ERR_POOL_CLOSING) {
            // core constraint violated
            return valid;
        }

        // all core constraints and all pool constraints are satisfied
        if (valid == SUCCESS) {
            uint256 score = scoreSolution(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

            if (gotFullValidSolution == false) {
                gotFullValidSolution = true;
                _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, score);
                // solution is new best => 0
                return SUCCESS;
            }

            if (score < bestSubScore) {
                // solution is not the best => -6
                return ERR_NOT_NEW_BEST;
            }

            _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, score);

            // solution is new best => 0
            return SUCCESS;
        }

        // proposed solution does not satisfy all pool constraints
        // if we never received a solution which satisfies all constraints for this epoch
        // we might accept it as an improvement
        if (gotFullValidSolution == false) {
            return _improveScore(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply);
        }

        // proposed solution doesn't satisfy the pool constraints but a previous submission did
        return ERR_NOT_NEW_BEST;
    }

    /// @notice returns the difference between two values as absolute value
    /// for gas optimization if both values are equal, 1 is returned to avoid a special zero case in other methods
    /// @param x first value
    /// @param y second value
    /// @return delta absolute value of the difference
    function absDistance(uint256 x, uint256 y) public pure returns (uint256 delta) {
        if (x == y) {
            // gas optimization: for avoiding an additional edge case of 0 distance
            // distance is set to the smallest value possible
            return 1;
        }
        if (x > y) {
            return safeSub(x, y);
        }
        return safeSub(y, x);
    }

    /// @notice method to check if a ratio is within a range
    /// @param ratio ratio to check
    /// @param minRatio minimum ratio
    /// @param maxRatio maximum ratio
    /// @return true if ratio is within range
    function checkRatioInRange(uint256 ratio, uint256 minRatio, uint256 maxRatio) public pure returns (bool) {
        if (ratio >= minRatio && ratio <= maxRatio) {
            return true;
        }
        return false;
    }

    /// @notice calculates the improvement score of a solution
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param juniorSupply junior supply amount
    /// @param seniorSupply senior supply amount
    /// @param err_ zero if solution is an improvement otherwise an error code
    function _improveScore(uint256 seniorRedeem, uint256 juniorRedeem, uint256 juniorSupply, uint256 seniorSupply)
        internal
        returns (int256 err_)
    {
        Fixed27 memory currSeniorRatio = Fixed27(assessor.calcSeniorRatio(epochSeniorAsset, epochNAV, epochReserve));

        int256 err = 0;
        uint256 impScoreRatio = 0;
        uint256 impScoreReserve = 0;

        if (bestRatioImprovement == 0) {
            // define no orders (current status) score as benchmark if no previous submission exists
            // if the current state satisfies all pool constraints it has the highest score
            (err, impScoreRatio, impScoreReserve) = scoreImprovement(currSeniorRatio.value, epochReserve);
            _saveNewImprovement(impScoreRatio, impScoreReserve);
        }

        uint256 newReserve = calcNewReserve(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

        Fixed27 memory newSeniorRatio =
            Fixed27(assessor.calcSeniorRatio(seniorRedeem, seniorSupply, epochSeniorAsset, newReserve, epochNAV));

        (err, impScoreRatio, impScoreReserve) = scoreImprovement(newSeniorRatio.value, newReserve);

        if (err == ERR_NOT_NEW_BEST) {
            // solution is not the best => -1
            return err;
        }

        _saveNewImprovement(impScoreRatio, impScoreReserve);

        // solution doesn't satisfy all pool constraints but improves the current violation
        // improvement only gets 0 points only solutions in the feasible region receive more
        _saveNewOptimum(seniorRedeem, juniorRedeem, juniorSupply, seniorSupply, 0);
        return NEW_BEST;
    }

    /// @notice the score improvement reserve uses the normalized distance to maxReserve/2 as score
    /// as smaller the distance as higher is the score
    /// highest possible score if solution is not violating the reserve
    /// @param newReserve_ new reserve value
    /// @return score improvement score for reserve
    function scoreReserveImprovement(uint256 newReserve_) public view returns (uint256 score) {
        if (newReserve_ <= assessor.maxReserve()) {
            // highest possible score
            return BIG_NUMBER;
        }

        return rdiv(ONE, safeSub(newReserve_, assessor.maxReserve()));
    }

    /// @notice the score improvement ratio uses the normalized distance to (minRatio+maxRatio)/2 as score
    /// as smaller the distance as higher is the score
    /// highest possible score if solution is not violating the ratio
    /// @param newSeniorRatio new ratio value
    /// @return score improvement score for ratio
    function scoreRatioImprovement(uint256 newSeniorRatio) public view returns (uint256 score) {
        (uint256 minSeniorRatio, uint256 maxSeniorRatio) = assessor.seniorRatioBounds();
        if (checkRatioInRange(newSeniorRatio, minSeniorRatio, maxSeniorRatio) == true) {
            // highest possible score
            return BIG_NUMBER;
        }
        // absDistance of ratio can never be zero
        return rdiv(ONE, absDistance(newSeniorRatio, safeDiv(safeAdd(minSeniorRatio, maxSeniorRatio), 2)));
    }

    /// @notice internal method to save new improvement score
    /// @param impScoreRatio improvement score for ratio
    /// @param impScoreReserve improvement score for reserve
    function _saveNewImprovement(uint256 impScoreRatio, uint256 impScoreReserve) internal {
        bestRatioImprovement = impScoreRatio;
        bestReserveImprovement = impScoreReserve;
    }

    /// @notice calculates improvement score for reserve and ratio pool constraints
    /// @param newSeniorRatio_ new senior ratio
    /// @param newReserve_ new reserve
    /// @return err error code, zero if no error
    /// @return impScoreRatio improvement score for ratio
    /// @return impScoreReserve improvement score for reserve
    function scoreImprovement(uint256 newSeniorRatio_, uint256 newReserve_)
        public
        view
        returns (int256 err, uint256 impScoreRatio, uint256 impScoreReserve)
    {
        impScoreRatio = scoreRatioImprovement(newSeniorRatio_);
        impScoreReserve = scoreReserveImprovement(newReserve_);

        // the highest priority has fixing the currentSeniorRatio
        // if the ratio is improved, we can ignore reserve
        if (impScoreRatio > bestRatioImprovement) {
            // we found a new best
            return (NEW_BEST, impScoreRatio, impScoreReserve);
        }

        // only if the submitted solution ratio score equals the current best ratio
        // we determine if the submitted solution improves the reserve
        if (impScoreRatio == bestRatioImprovement) {
            if (impScoreReserve >= bestReserveImprovement) {
                return (NEW_BEST, impScoreRatio, impScoreReserve);
            }
        }
        return (ERR_NOT_NEW_BEST, impScoreRatio, impScoreReserve);
    }

    /// @notice scores a solution in the submission period
    /// the scoring function is a linear function with high weights as coefficient to determine
    /// the priorities. (non-preemptive goal programming)
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param juniorSupply junior supply amount
    /// @param seniorSupply senior supply amount
    /// @return score of a valid solution
    function scoreSolution(uint256 seniorRedeem, uint256 juniorRedeem, uint256 juniorSupply, uint256 seniorSupply)
        public
        view
        returns (uint256 score)
    {
        // the default priority order
        // 1. senior redeem
        // 2. junior redeem
        // 3. junior supply
        // 4. senior supply
        return safeAdd(
            safeAdd(safeMul(seniorRedeem, weightSeniorRedeem), safeMul(juniorRedeem, weightJuniorRedeem)),
            safeAdd(safeMul(juniorSupply, weightJuniorSupply), safeMul(seniorSupply, weightSeniorSupply))
        );
    }

    /// @notice validates if a solution satisfy the core constraints
    /// @param currencyAvailable currency available in the pool including the supplies
    /// @param currencyOut currency which would be reedemed
    /// @param seniorSupply senior supply amount
    /// @param juniorSupply junior supply amount
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @return err code for the first constraint which is not satisfied or success
    function validateCoreConstraints(
        uint256 currencyAvailable,
        uint256 currencyOut,
        uint256 seniorRedeem,
        uint256 juniorRedeem,
        uint256 seniorSupply,
        uint256 juniorSupply
    ) public view returns (int256 err) {
        // constraint 1: currency available
        if (currencyOut > currencyAvailable) {
            // currencyAvailableConstraint => -1
            return ERR_CURRENCY_AVAILABLE;
        }

        // constraint 2: max order
        if (
            seniorSupply > order.seniorSupply || juniorSupply > order.juniorSupply || seniorRedeem > order.seniorRedeem
                || juniorRedeem > order.juniorRedeem
        ) {
            // maxOrderConstraint => -2
            return ERR_MAX_ORDER;
        }

        // successful => 0
        return SUCCESS;
    }

    /// @notice validates if a solution satisfies the ratio constraints
    /// @param assets total asset value of the pool (NAV + reserve)
    /// @param seniorAsset senior asset value (seniorDebt + seniorBalance)
    /// @return err code for the first constraint which is not satisfied or success
    function validateRatioConstraints(uint256 assets, uint256 seniorAsset) public view returns (int256 err) {
        (uint256 minSeniorRatio, uint256 maxSeniorRatio) = assessor.seniorRatioBounds();

        // constraint 4: min senior ratio constraint
        if (seniorAsset < rmul(assets, minSeniorRatio)) {
            // minSeniorRatioConstraint => -4
            return ERR_MIN_SENIOR_RATIO;
        }
        // constraint 5: max senior ratio constraint
        if (seniorAsset > rmul(assets, maxSeniorRatio)) {
            // maxSeniorRatioConstraint => -5
            return ERR_MAX_SENIOR_RATIO;
        }
        // successful => 0
        return SUCCESS;
    }

    /// @notice validates if a solution satisfies the pool constraints
    /// @param reserve_ total amount in the reserve
    /// @param seniorAsset senior asset value (seniorDebt + seniorBalance)
    /// @param nav_ net asset value
    /// @return err code for the first constraint which is not satisfied or success
    function validatePoolConstraints(uint256 reserve_, uint256 seniorAsset, uint256 nav_)
        public
        view
        returns (int256 err)
    {
        // constraint 3: max reserve
        if (reserve_ > assessor.maxReserve()) {
            // maxReserveConstraint => -3
            return ERR_MAX_RESERVE;
        }

        uint256 assets = safeAdd(nav_, reserve_);
        return validateRatioConstraints(assets, seniorAsset);
    }

    /// @notice validates if a solution satisfies core and pool constraints
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param seniorSupply senior supply amount
    /// @param juniorSupply junior supply amount
    /// @return err code for the first constraint which is not satisfied or success
    function validate(uint256 seniorRedeem, uint256 juniorRedeem, uint256 seniorSupply, uint256 juniorSupply)
        public
        view
        returns (int256 err)
    {
        return _validate(
            epochReserve,
            epochNAV,
            epochSeniorAsset,
            OrderSummary({
                seniorRedeem: seniorRedeem,
                juniorRedeem: juniorRedeem,
                seniorSupply: seniorSupply,
                juniorSupply: juniorSupply
            })
        );
    }
    /// @notice validates if a solution satisfies core and pool constraints and allows to pass different state variables
    /// @param reserve_ total amount in the reserve
    /// @param nav_ net asset value
    /// @param seniorAsset_ senior asset value (seniorDebt + seniorBalance)
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param seniorSupply senior supply amount
    /// @param juniorSupply junior supply amount
    /// @param err error code for the first constraint which is not satisfied or success

    function validate(
        uint256 reserve_,
        uint256 nav_,
        uint256 seniorAsset_,
        uint256 seniorRedeem,
        uint256 juniorRedeem,
        uint256 seniorSupply,
        uint256 juniorSupply
    ) public view returns (int256 err) {
        return _validate(
            reserve_,
            nav_,
            seniorAsset_,
            OrderSummary({
                seniorRedeem: seniorRedeem,
                juniorRedeem: juniorRedeem,
                seniorSupply: seniorSupply,
                juniorSupply: juniorSupply
            })
        );
    }

    /// @notice internal method to validate a solution
    /// @param reserve_ total amount in the reserve
    /// @param nav_ net asset value
    /// @param seniorAsset_ senior asset value (seniorDebt + seniorBalance)
    /// @param trans the order summary of supplies and redeems
    /// @return err_ error code for the first constraint which is not satisfied or success
    function _validate(uint256 reserve_, uint256 nav_, uint256 seniorAsset_, OrderSummary memory trans)
        internal
        view
        returns (int256 err_)
    {
        uint256 currencyAvailable = safeAdd(safeAdd(reserve_, trans.seniorSupply), trans.juniorSupply);
        uint256 currencyOut = safeAdd(trans.seniorRedeem, trans.juniorRedeem);

        int256 err = validateCoreConstraints(
            currencyAvailable,
            currencyOut,
            trans.seniorRedeem,
            trans.juniorRedeem,
            trans.seniorSupply,
            trans.juniorSupply
        );

        if (err != SUCCESS) {
            return err;
        }

        uint256 newReserve = safeSub(currencyAvailable, currencyOut);
        if (poolClosing == true) {
            if (trans.seniorSupply == 0 && trans.juniorSupply == 0) {
                return SUCCESS;
            }
            return ERR_POOL_CLOSING;
        }
        return validatePoolConstraints(
            newReserve,
            assessor.calcSeniorAssetValue(trans.seniorRedeem, trans.seniorSupply, seniorAsset_, newReserve, nav_),
            nav_
        );
    }

    /// @notice public method to execute an epoch which required a submission period and the challenge period is over
    function executeEpoch() public {
        require(block.timestamp >= minChallengePeriodEnd && minChallengePeriodEnd != 0);

        _executeEpoch(
            bestSubmission.seniorRedeem,
            bestSubmission.juniorRedeem,
            bestSubmission.seniorSupply,
            bestSubmission.juniorSupply
        );
    }

    /// @notice helper function to calculate the percentage of an order type which can be fulfilled for an epoch
    /// @param amount which can be fullFilled
    /// @param totalOrder the total order amount
    /// @return percent percentage of the order which can be fulfilled (RAY 10^27)
    function calcFulfillment(uint256 amount, uint256 totalOrder) public pure returns (uint256 percent) {
        if (amount == 0 || totalOrder == 0) {
            return 0;
        }
        return rdiv(amount, totalOrder);
    }

    /// @notice calculates the new reserve after a solution would be executed
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param seniorSupply senior supply amount
    /// @param juniorSupply junior supply amount
    /// @return newReserve the new reserve after the solution would be executed
    function calcNewReserve(uint256 seniorRedeem, uint256 juniorRedeem, uint256 seniorSupply, uint256 juniorSupply)
        public
        view
        returns (uint256 newReserve)
    {
        return safeSub(safeAdd(safeAdd(epochReserve, seniorSupply), juniorSupply), safeAdd(seniorRedeem, juniorRedeem));
    }

    /// @notice internal execute epoch communicates the order fulfillment of the best solution to the tranches
    /// @param seniorRedeem senior redeem amount
    /// @param juniorRedeem junior redeem amount
    /// @param seniorSupply senior supply amount
    /// @param juniorSupply junior supply amount
    function _executeEpoch(uint256 seniorRedeem, uint256 juniorRedeem, uint256 seniorSupply, uint256 juniorSupply)
        internal
    {
        uint256 epochID = safeAdd(lastEpochExecuted, 1);
        submissionPeriod = false;

        // tranche epochUpdates triggers currency transfers from/to reserve
        // an mint/burn tokens
        seniorTranche.epochUpdate(
            epochID,
            calcFulfillment(seniorSupply, order.seniorSupply),
            calcFulfillment(seniorRedeem, order.seniorRedeem),
            epochSeniorTokenPrice.value,
            order.seniorSupply,
            order.seniorRedeem
        );

        // assessor performs senior debt reBalancing according to new ratio
        assessor.changeSeniorAsset(seniorSupply, seniorRedeem);

        juniorTranche.epochUpdate(
            epochID,
            calcFulfillment(juniorSupply, order.juniorSupply),
            calcFulfillment(juniorRedeem, order.juniorRedeem),
            epochJuniorTokenPrice.value,
            order.juniorSupply,
            order.juniorRedeem
        );

        // sends requested currency to senior tranche, if currency was not available before
        seniorTranche.payoutRequestedCurrency();

        uint256 newReserve = calcNewReserve(seniorRedeem, juniorRedeem, seniorSupply, juniorSupply);

        // reBalancing again because the reserve has updated after the junior epochUpdate
        assessor.changeSeniorAsset(0, 0);
        // the new reserve after this epoch can be used for new loans
        assessor.changeBorrowAmountEpoch(newReserve);

        // reset state for next epochs
        lastEpochExecuted = epochID;
        minChallengePeriodEnd = 0;
        bestSubScore = 0;
        gotFullValidSolution = false;
        bestRatioImprovement = 0;
        bestReserveImprovement = 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import {EpochCoordinator} from "./../coordinator.sol";
import "tinlake-erc20/erc20.sol";
import "../coordinator.sol";

interface CoordinatorFabLike {
    function newCoordinator(uint256) external returns (address);
}

contract CoordinatorFab {
    function newCoordinator(uint256 challengeTime) public returns (address) {
        EpochCoordinator coordinator = new EpochCoordinator(challengeTime);
        coordinator.rely(msg.sender);
        coordinator.deny(address(this));
        return address(coordinator);
    }
}
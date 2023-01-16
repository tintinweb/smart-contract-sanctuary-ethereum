pragma solidity ^0.8.12;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "Strings.sol";
import "AggregatorV3Interface.sol";
import "ChainlinkClient.sol";

library Pricer {

    struct OptionInfo {
        int256 strike;
        int256 exp;
        int256 vol;
        uint256 N;
        int256 T;
        uint256 DT;
        uint256 S;
        uint256 salt;
        int256 BB;
        int256 price;
    }

    function getCallPrice(int256 _strike, int256 _vol, uint256 _ttm, uint256 _simulations, uint256 _salt) public view returns (int256){

        OptionInfo memory optionInfo;
        optionInfo.strike = _strike;
        optionInfo.vol = _vol;
        optionInfo.N = (_ttm / 86400) + 1;
        optionInfo.T = int(((_ttm / 86400) * 10 ** 18) / 365);
        optionInfo.DT = uint256(1 ether) / uint256(365);
        optionInfo.S = _simulations;
        optionInfo.salt = _salt;
        optionInfo.BB = 0;
        optionInfo.price = 99999999;

        int256[] memory V1 = new int256[](optionInfo.S);
        int256[] memory V2 = new int256[](optionInfo.S);

        // TO CHECK: is there really 60 days of binomial? not 59?
        for (uint256 s = 0; s < optionInfo.S; s++) {
            int256 maxPrice1 = optionInfo.strike;
            int256 maxPrice2 = optionInfo.strike;
            int256[] memory gaussianNumbers = getGaussianRandomNumbers(optionInfo.salt * s, optionInfo.N);
            int256[] memory St1 = new int256[](optionInfo.N);
            St1[0] = optionInfo.strike;
            int256[] memory St2 = new int256[](optionInfo.N);
            St2[0] = optionInfo.strike;
            for (uint256 i = 1; i < optionInfo.N; i++) {
                int256 e = int256(gaussianNumbers[i - 1]);
                int256 exp1 = (int((- 1 * (optionInfo.vol ** 2)) / (2 * 10 ** 36)) * int(optionInfo.DT));
                int256 exp2 = (optionInfo.vol * int(sqrt(optionInfo.DT)) * 10 ** 9 * e / 10 ** 21);
                int256 simPrice1 = St1[i - 1] * int(exp(exp1 + exp2)) / 10 ** 18;
                int256 simPrice2 = St2[i - 1] * int(exp(exp1 - exp2)) / 10 ** 18;
                if (simPrice1 >= maxPrice1) {
                    maxPrice1 = simPrice1;
                }
                if (simPrice2 >= maxPrice2) {
                    maxPrice2 = simPrice2;
                }
                St1[i] = simPrice1;
                St2[i] = simPrice2;
            }
            V1[s] = maxPrice1 - optionInfo.strike;
            V2[s] = maxPrice2 - optionInfo.strike;
            optionInfo.BB += int((V1[s] + V2[s]) / 2);
        }
        optionInfo.price = optionInfo.BB / int(optionInfo.S);
        return optionInfo.price;
    }

    function getPutPrice(int256 _strike, int256 _vol, uint256 _ttm, uint256 _simulations, uint256 _salt) public view returns (int256){

        OptionInfo memory optionInfo;
        optionInfo.strike = _strike;
        optionInfo.vol = _vol;
        optionInfo.N = (_ttm / 86400) + 1;
        // ttm is in seconds
        optionInfo.T = int(((_ttm / 86400) * 10 ** 18) / 365);
        optionInfo.DT = uint256(1 ether) / uint256(365);
        optionInfo.S = _simulations;
        optionInfo.salt = _salt;
        optionInfo.BB = 0;
        optionInfo.price = 99999999;

        int256[] memory V1 = new int256[](optionInfo.S);
        int256[] memory V2 = new int256[](optionInfo.S);

        // TO CHECK: is there really 60 days of binomial? not 59?
        for (uint256 s = 0; s < optionInfo.S; s++) {
            int256 minPrice1 = optionInfo.strike;
            int256 minPrice2 = optionInfo.strike;
            int256[] memory gaussianNumbers = getGaussianRandomNumbers(optionInfo.salt * s, optionInfo.N);
            int256[] memory St1 = new int256[](optionInfo.N);
            St1[0] = optionInfo.strike;
            int256[] memory St2 = new int256[](optionInfo.N);
            St2[0] = optionInfo.strike;
            for (uint256 i = 1; i < optionInfo.N; i++) {
                int256 e = int256(gaussianNumbers[i - 1]);
                int256 exp1 = (int((- 1 * (optionInfo.vol ** 2)) / (2 * 10 ** 36)) * int(optionInfo.DT));
                int256 exp2 = (optionInfo.vol * int(sqrt(optionInfo.DT)) * 10 ** 9 * e / 10 ** 21);
                int256 simPrice1 = St1[i - 1] * int(exp(exp1 + exp2)) / 10 ** 18;
                int256 simPrice2 = St2[i - 1] * int(exp(exp1 - exp2)) / 10 ** 18;
                if (simPrice1 <= minPrice1) {
                    minPrice1 = simPrice1;
                }
                if (simPrice2 <= minPrice2) {
                    minPrice2 = simPrice2;
                }
                St1[i] = simPrice1;
                St2[i] = simPrice2;
            }
            V1[s] = optionInfo.strike - minPrice1;
            V2[s] = optionInfo.strike - minPrice2;
            optionInfo.BB += int((V1[s] + V2[s]) / 2);
        }
        optionInfo.price = optionInfo.BB / int(optionInfo.S);
        return optionInfo.price;
    }

    function getGaussianRandomNumbers(uint256 salt, uint256 n) public view returns (int256[] memory) {
        uint256 seed = salt + block.timestamp;
        uint256 _num = uint256(keccak256(abi.encodePacked(seed)));
        int256[] memory results = new int256[](n);
        uint256[] memory nums = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            uint256 result = _countOnes(_num);
            results[i] = int256(result * 125) - 16000;
            _num = uint256(keccak256(abi.encodePacked(_num)));
            nums[i] = _num;
        }
        return results;
    }

    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        assembly {
            for {} gt(n, 0) {} {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }

    function exp(int x) internal pure returns (uint r) {
    unchecked {
        // Input x is in fixed point format, with scale factor 1/1e18.

        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= - 42139678854452767551) {
            return 0;
        }

        // When the result is > (2**255 - 1) / 1e18 we can not represent it
        // as an int256. This happens when x >= floor(log((2**255 -1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert ExpOverflow();

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5 ** 18;

        // Reduce range of x to (-Â½ ln 2, Â½ ln 2) * 2**96 by factoring out powers of two
        // such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
        x = x - k * 54916777467707473351141471128;
        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation
        // p is made monic, we will multiply by a scale factor later
        int p = x + 2772001395605857295435445496992;
        p = ((p * x) >> 96) + 44335888930127919016834873520032;
        p = ((p * x) >> 96) + 398888492587501845352592340339721;
        p = ((p * x) >> 96) + 1993839819670624470859228494792842;
        p = p * x + (4385272521454847904632057985693276 << 96);
        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // Evaluate using using Knuth's scheme from p. 491.
        int z = x + 750530180792738023273180420736;
        z = ((z * x) >> 96) + 32788456221302202726307501949080;
        int w = x - 2218138959503481824038194425854;
        w = ((w * z) >> 96) + 892943633302991980437332862907700;
        int q = z + w - 78174809823045304726920794422040;
        q = ((q * w) >> 96) + 4203224763890128580604056984195872;
        assembly {
        // Div in assembly because solidity adds a zero check despite the `unchecked`.
        // The q polynomial is known not to have zeros in the domain. (All roots are complex)
        // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }
        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by
        //  * the scale factor s = ~6.031367120...,
        //  * the 2**k factor from the range reduction, and
        //  * the 1e18 / 2**96 factor for base converison.
        // We do all of this at once, with an intermediate result in 2**213 basis
        // so the final right shift is always by a positive amount.
        r = (uint(r) * 3822833074963236453042738258902158003155416615667) >> uint(195 - k);
    }
    }

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
        // Start off with z at 1.
            z := 1

        // Used below to help find a nearby power of 2.
            let y := x

        // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
            // Equivalent to 2 ** z.
                z := shl(1, z)
            }

        // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

        // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

        // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    error Overflow();
    error ExpOverflow();

}

contract LookBack is Ownable, Pausable, ReentrancyGuard, ChainlinkClient {

    bytes32 private jobId;
    uint256 private fee;

    uint256 treasury;
    uint256 treasuryFee;
    uint64 collateralRatio;
    uint256 stakeMin;
    uint256 lockingRatio;
    bool isInitialized;
    string baseURL;
    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    mapping(address => uint256[]) public userPositions;
    mapping(address => bool) public isOperator;
    uint256 public lastProductId;
    uint256 public lastPositionId;
    uint256 public lastSettlementId;
    uint256 public lastStakeId;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256) public stakers;
    mapping(uint256 => mapping(address => StakeInfo)) public stakingLedger;
    mapping(bytes32 => BindingBid) public bindingBids;

    receive() external payable {}

    fallback() external payable {}

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    enum ProductStrikeType {
        Fixed,
        Floating
    }

    struct StakeInfo {
        uint256 id;
        uint256 productId;
        uint256 stakeUnits;
        uint256 lockedUntil;
        address user;
        bool isExist;
    }

    struct Product {
        uint256 id;
        bool isCall;
        uint256 timeToExpiry;
        uint256 startValidity;
        uint256 endValidity;
        uint256 minQuantity;
        int256 impliedVol;
        address oracleAddress;
        bool isInitialized;
        uint256 stake;
        uint256 stakeUnits;
        uint256 lockedStake;
        uint256 simulations;
    }

    struct Position {
        uint256 id;
        uint256 productId;
        uint256 startStamp;
        uint256 closeStamp;
        uint256 refPrice;
        uint256 strike;
        uint256 quantity;
        bool isClaimed;
        address user;
    }

    struct BindingBid {
        bytes32 id;
        address user;
        uint256 positionId;
        uint256 productId;
        uint256 bid;
        uint256 bidValidity;
    }

    constructor(uint256 _treasuryFee) {
        treasuryFee = _treasuryFee;
        isOperator[msg.sender] = true;
        lastProductId = 0;
        lastPositionId = 0;
        lastSettlementId = 0;
        lastStakeId = 0;
        collateralRatio = 3;
        lockingRatio = 3;
        stakeMin = 0.005 ether;
    }

    event NewProduct(uint256 indexed id, bool isCall, uint256 timeToExpiry, int256 impliedVol, uint256 startValidity,
        uint256 endValidity, uint256 minQuantity, address oracle);

    function createProduct(
        bool _isCall,
        uint256 _timeToExpiry,
        int256 _impliedVol,
        uint256 _startValidity,
        uint256 _endValidity,
        uint256 _minQuantity,
        address _oracle,
        uint256 _simulations
    )
    public onlyOperator {
        Product memory newProduct = Product({
        id : lastProductId,
        isCall : _isCall,
        timeToExpiry : _timeToExpiry,
        impliedVol : _impliedVol,
        startValidity : _startValidity,
        endValidity : _endValidity,
        minQuantity : _minQuantity,
        oracleAddress : _oracle,
        isInitialized : false,
        stake : 0,
        stakeUnits : 0,
        lockedStake : 0,
        simulations : _simulations
        });
        products[lastProductId] = newProduct;
        emit NewProduct(lastProductId, _isCall, _timeToExpiry, _impliedVol, _startValidity, _endValidity, _minQuantity, _oracle);
        lastProductId++;
    }

    // TODO: add user so can get it back for StakeInfo
    event ProductInitialized(uint256 indexed id, uint256 stake, uint256 stakeUnits, uint256 lockedUntil, address user);

    function initializeProduct(uint256 _productId, uint256 _stakeUnits) external onlyOwner payable {
        Product storage product = products[_productId];
        require(!product.isInitialized, "Product has already been initialized!");
        product.stakeUnits = _stakeUnits;
        product.stake = msg.value;
        product.isInitialized = true;
        StakeInfo memory stakeInfo = StakeInfo({
        id : lastStakeId,
        productId : _productId,
        stakeUnits : _stakeUnits,
        lockedUntil : block.timestamp + (product.timeToExpiry * lockingRatio),
        user : msg.sender,
        isExist : true
        });
        stakingLedger[_productId][msg.sender] = stakeInfo;
        emit ProductInitialized(_productId, msg.value, _stakeUnits, block.timestamp + (product.timeToExpiry * lockingRatio), msg.sender);
    }

    function priceOption(Product memory _product, uint256 _currentPrice) public view returns (uint256) {
        uint256 salt = block.timestamp % 67;
        int256 premium;
        if (_product.isCall) {
            premium = Pricer.getCallPrice(int(_currentPrice), _product.impliedVol, _product.timeToExpiry, _product.simulations, salt);
        } else {
            premium = Pricer.getPutPrice(int(_currentPrice), _product.impliedVol, _product.timeToExpiry, _product.simulations, salt);
        }
        uint256 weiPrice = uint256(premium * 10 ** 18 / int(_currentPrice));
        require(weiPrice > 0, "Looks there is an issue with the premium");
        return weiPrice;
    }

    event NewPosition(uint256 indexed id, uint256 productId, uint256 startStamp, uint256 endStamp, uint256 refPrice, uint256 quantity, uint256 value, address user);

    function createPosition(uint256 _productId) public payable {

        // get product from storage
        Product storage product = products[_productId];
        require(product.endValidity >= block.timestamp + (15 * 60), "This product is not valid anymore");

        // get current price from oracle
        (uint256 currentPrice, uint8 decimals, uint256 currentStamp) = oraclePrice(product.oracleAddress, 0, true);
        require(currentPrice > 0, "Looks there is an issue with the oracle price");

        // get option price
        uint256 optionPrice = priceOption(product, currentPrice);
        uint256 adjustedQuantity = (msg.value * 10 ** 18 / optionPrice);

        treasury += treasuryFee * msg.value;
        product.stake += (1 - treasuryFee / 10000) * msg.value;
        require(adjustedQuantity >= product.minQuantity, "Not enough ETH sent!");
        require((product.stake - product.lockedStake) / collateralRatio >= adjustedQuantity, "Not enough collateral for this position size");
        product.lockedStake += collateralRatio * adjustedQuantity;

        // create empty position
        Position memory position = Position({
        id : lastPositionId,
        productId : _productId,
        startStamp : currentStamp,
        closeStamp : currentStamp + product.timeToExpiry,
        refPrice : currentPrice,
        strike : currentPrice,
        quantity : adjustedQuantity,
        isClaimed : false,
        user : msg.sender
        });
        positions[lastPositionId] = position;
        emit NewPosition(lastPositionId, _productId, currentStamp, currentStamp + product.timeToExpiry, currentPrice, adjustedQuantity, msg.value, msg.sender);
        lastPositionId++;

    }


    event Settlement(uint256 indexed id, uint256 positionId, uint256 refPrice, uint256 closePrice, uint256 stamp, uint256 value, address user);

    function settlePosition(uint256 _positionId, uint80 _roundId, uint80 _closeRoundId) external payable whenNotPaused nonReentrant notContract {
        Position storage position = positions[_positionId];
        require(position.closeStamp <= block.timestamp, "This position cannot be settled yet!");
        require(!position.isClaimed, "Position has already been claimed!");
        require(msg.sender == position.user, "You are not the owner of this position");
        Product storage product = products[position.productId];
        (uint256 historicPrice, uint8 historicDecimals, uint256 historicStamp) = oraclePrice(product.oracleAddress, _roundId, false);
        (uint256 closePrice, uint8 closeDecimals, uint256 closeStamp) = oraclePrice(product.oracleAddress, _closeRoundId, false);
        (uint256 previousPrice, uint8 previousDecimals, uint256 previousStamp) = oraclePrice(product.oracleAddress, _closeRoundId - 1, false);
        require(historicStamp >= position.startStamp && historicStamp <= position.closeStamp, "Wrong historic roundId provided");
        require(closeStamp >= position.closeStamp && position.closeStamp >= previousStamp, "Wrong close roundId provided!");
        position.refPrice = historicPrice;
        uint256 positionResult = 0;
        if (!product.isCall && position.strike > position.refPrice) {
            positionResult = (position.quantity * (position.strike - position.refPrice) / closePrice);
        } else if (product.isCall && position.refPrice > position.strike) {
            positionResult = (position.quantity * (position.refPrice - position.strike) / closePrice);
        }
        require(product.stake >= positionResult, "Collateral is not sufficient to pay you back ... Please contact support");
        position.isClaimed = true;
        product.stake -= positionResult;
        product.lockedStake -= collateralRatio * position.quantity;
        require(positionResult > 0, "Result is 0, nothing to be sent!");
        payable(msg.sender).transfer(positionResult);
        emit Settlement(lastSettlementId, position.id, historicPrice, closePrice, block.timestamp, positionResult, msg.sender);

        lastSettlementId += 1;
    }

    function oraclePrice(address _oracle, uint80 _roundId, bool _isLive) public view returns (uint256, uint8, uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(_oracle);
        if (_isLive) {
            (, int256 roundPrice, uint256 roundStamp,,) = oracle.latestRoundData();
            uint8 decimals = oracle.decimals();
            return (uint256(roundPrice) * 10 ** (18 - decimals), decimals, roundStamp);
        } else {
            (, int256 roundPrice, uint256 roundStamp,,) = oracle.getRoundData(_roundId);
            uint8 decimals = oracle.decimals();
            return (uint256(roundPrice) * 10 ** (18 - decimals), decimals, roundStamp);
        }
    }

    // TODO: add staking value so computation is easier
    event Staked(uint256 indexed id, uint256 productId, address user, uint256 stake, uint256 stakeUnits, uint256 lockedUntil);

    function stake(uint256 _productId) public payable whenNotPaused nonReentrant notContract {
        Product storage product = products[_productId];
        uint256 currentCollateralUnitValue = product.stake / product.stakeUnits;
        uint256 stakeUnitsAttributed = msg.value / currentCollateralUnitValue;
        product.stake += msg.value;
        product.stakeUnits += stakeUnitsAttributed;
        if (!stakingLedger[_productId][msg.sender].isExist) {
            StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
            stakeInfo.stakeUnits += stakeUnitsAttributed;
            stakeInfo.lockedUntil += block.timestamp + (product.timeToExpiry * lockingRatio);
            emit Staked(stakeInfo.id, _productId, msg.sender, msg.value, stakeUnitsAttributed, block.timestamp + (product.timeToExpiry * lockingRatio));
        } else {
            StakeInfo memory stakeInfo = StakeInfo({
            id : lastStakeId,
            productId : _productId,
            user : msg.sender,
            stakeUnits : stakeUnitsAttributed,
            lockedUntil : block.timestamp + (product.timeToExpiry * lockingRatio),
            isExist : true
            });
            emit Staked(lastStakeId, _productId, msg.sender, msg.value, stakeUnitsAttributed, block.timestamp + (product.timeToExpiry * lockingRatio));
            lastStakeId++;
        }
    }

    event Unstaked(uint256 indexed id, uint256 productId, address user, uint256 stakeUnits);

    function unstake(uint256 _productId, uint256 _units) public payable whenNotPaused nonReentrant notContract {
        Product storage product = products[_productId];
        StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
        require(block.timestamp >= stakeInfo.lockedUntil, "Your stake is currently locked");
        require(stakeInfo.stakeUnits > 0, "You don't have any staking units for this product");
        require(_units <= stakeInfo.stakeUnits, "You can't withdraw more units than what you have");
        uint256 currentCollateralUnitValue = product.stake / product.stakeUnits;
        uint256 stakeUnitsValue = _units * currentCollateralUnitValue;
        require(product.stake - stakeUnitsValue >= product.lockedStake, "You can't withdraw that much collateral. Please wait for more positions to be unlocked.");
        stakeInfo.stakeUnits -= _units;
        product.stake -= stakeUnitsValue;
        product.stakeUnits -= _units;
        payable(msg.sender).transfer(stakeUnitsValue);
        emit Unstaked(stakeInfo.id, _productId, msg.sender, _units);
    }

    function withdrawTreasury(uint256 _amount) public payable onlyOwner nonReentrant {
        require(treasury >= _amount, "Not enough treasury to withdraw");
        treasury -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function switchOperator(address _user) public onlyOwner {
        isOperator[_user] = !isOperator[_user];
    }

    event IVUpdated(uint256 _productId, int256 _IV);
    function modifyIV(int256[] memory _IV) public onlyOperator {
        require(_IV.length % 2 == 0, "Looks array is not correct!");
        for (uint256 i=0; i < _IV.length; i+=2) {
            products[i].impliedVol = _IV[i+1];
            emit IVUpdated(i, _IV[i+1]);
        }
    }

    function modifyProduct(uint256 _productId, uint256 _minQuantity, uint256 _endValidity) public onlyOperator {
        Product storage product = products[_productId];
        product.minQuantity = _minQuantity;
        product.endValidity = _endValidity;
    }

    function modifyBaseURL(string memory _newBaseURL) public onlyOwner {
        baseURL = _newBaseURL;
    }

    function modifyCollateralRatio(uint64 _newRatio) public onlyOwner {
        collateralRatio = _newRatio;
    }

    function viewStakeUnits(address _user, uint256 _productId) public view returns (uint256, uint256) {
        StakeInfo storage stakeInfo = stakingLedger[_productId][msg.sender];
        return (stakeInfo.stakeUnits, stakeInfo.lockedUntil);
    }

    function viewCollateral(uint256 _productId) public view returns (uint256, uint256) {
        Product storage product = products[_productId];
        return (product.stake, product.stakeUnits);
    }

    function viewProduct(uint256 _productId) public view returns (Product memory) {
        Product storage product = products[_productId];
        return product;
    }

    function viewProducts() public view returns (Product[] memory) {
        Product[] memory productsArray = new Product[](lastProductId);
        for (uint i = 0; i < lastProductId; i++) {
            Product storage product = products[i];
            productsArray[i] = product;
        }
        return productsArray;
    }

    function viewPosition(uint256 _positionId) public view returns (Position memory) {
        Position storage position = positions[_positionId];
        return position;
    }

    function viewOptionPrice(uint256 _productId) public view returns (uint256) {
        Product storage product = products[_productId];
        int256 premium;
        (uint256 currentPrice, uint8 decimals, uint256 currentStamp) = oraclePrice(product.oracleAddress, 0, true);
        if (product.isCall) {
            premium = Pricer.getCallPrice(int(currentPrice), product.impliedVol, product.timeToExpiry, 10, 1);
        } else {
            premium = Pricer.getPutPrice(int(currentPrice), product.impliedVol, product.timeToExpiry, 10, 1);
        }
        uint256 weiPrice = uint256(premium * 10 ** 18 / int(currentPrice));
        return weiPrice;
    }

    function _isContract(address _account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Chainlink.sol";
import "ENSInterface.sol";
import "LinkTokenInterface.sol";
import "ChainlinkRequestInterface.sol";
import "OperatorInterface.sol";
import "PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "CBORChainlink.sol";
import {BufferChainlink} from "BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OracleInterface.sol";
import "ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}
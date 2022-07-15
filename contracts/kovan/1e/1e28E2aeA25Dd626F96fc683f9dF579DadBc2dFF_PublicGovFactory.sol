// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

pragma solidity ^0.8.13;

interface IKommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function communityStaked() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStakingV2{
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
    function staked(uint256) external view returns (uint256,uint256,uint256);
    function lockPeriod(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPublicGovFactory{
    event ProjectCreated(address indexed project, uint index);
    
    function owner() external  view returns (address);
    function savior() external  view returns (address);
    function operational() external  view returns (address);
    function marketing() external  view returns (address);
    function treasury() external  view returns (address);

    function operationalPercentage_d2() external  view returns (uint64);
    function marketingPercentage_d2() external  view returns (uint64);
    function treasuryPercentage_d2() external  view returns (uint128);

    function stakingV1() external view returns (address);
    function stakingV2() external view returns (address);
    
    function allProjectsLength() external view returns(uint);
    function allPaymentsLength() external view returns(uint);
    function allProjects(uint) external view returns(address);
    function allPayments(uint) external view returns(address);
    function getPaymentIndex(address) external view returns(uint);

    function createProject(uint128, uint128, uint128, uint128, uint128, uint128[4] calldata, address, address) external returns (address);
    
    function transferOwnership(address) external;
    function setPayment(address) external;
    function removePayment(address) external;
    function config(address, address, address, address) external;
    function setPercentage_d2(uint64, uint64, uint128) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPublicGovSale {
    event Sale(address indexed sale,uint index);

    function calculation() external view returns (uint128);
    function totalStaked() external view returns (uint128);

    function setTotalStaked() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IPublicGovFactory.sol";
import "./PublicGovSale.sol";

contract PublicGovFactory is IPublicGovFactory{
    address public override immutable stakingV1;
    address public override immutable stakingV2;

    // d2 = 2 decimal
    uint64 public override operationalPercentage_d2 = 4000;
    uint64 public override marketingPercentage_d2 = 3000;
    uint128 public override treasuryPercentage_d2 = 3000;

    address[] public override allProjects; // all projects created
    address[] public override allPayments; // all payment Token accepted
    
    address public override owner = msg.sender;
    address public override savior; // KOM address to spend left tokens

    address public override operational; // operational address
    address public override marketing; // marketing address
    address public override treasury; // treasury address
    
    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    mapping(address => uint) public override getPaymentIndex;
    
    constructor(
        address _savior,
        address _operational,
        address _marketing,
        address _treasury,
        address _stakingV1,
        address _stakingV2
    ){
        require(
            _savior != address(0) &&
            _operational != address(0) &&
            _marketing != address(0) &&
            _treasury != address(0) &&
            _stakingV1 != address(0) &&
            _stakingV2 != address(0),
            "bad"
        );
        
        savior = _savior;
        operational = _operational;
        marketing = _marketing;
        treasury = _treasury;
        stakingV1 = _stakingV1;
        stakingV2 = _stakingV2;
    }
    
    /**
     * @dev Get total number of projects created
     */
    function allProjectsLength() external override view returns (uint) {
        return allProjects.length;
    }
    
    /**
     * @dev Get total number of payment Toked accepted
     */
    function allPaymentsLength() external override view returns (uint) {
        return allPayments.length;
    }
    
    /**
     * @dev Create new project for raise fund
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     * @param _payment Tokens to raise
     * @param _gov Governance address
     */
    function createProject(
        uint128 _calculation,
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[4] calldata _fee_d2,
        address _payment,
        address _gov
    ) external override onlyOwner returns(address project){
        require(_payment != address(0), "bad");
        require(_payment == allPayments[getPaymentIndex[_payment]], "!exist");
        
        project = address(new PublicGovSale());

        allProjects.push(project);
        
        PublicGovSale(project).initialize(
            _calculation,
            _start,
            _duration,
            _sale,
            _price,
            _fee_d2,
            _payment,
            _gov
        );
        
        emit ProjectCreated(project, allProjects.length-1);
    }
    
    /**
     * @dev Transfer ownership to new owner
     * @param _newOwner New owner
     */
    function transferOwnership(address _newOwner) external override onlyOwner{
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }
    
    /**
     * @dev Set new token to be accepted
     * @param _token New token address
     */
    function setPayment(address _token) external override onlyOwner{
        require(_token != address(0), "bad");
        if(allPayments.length > 0) require(_token != allPayments[getPaymentIndex[_token]], "existed");
        
        allPayments.push(_token);
        getPaymentIndex[_token] = allPayments.length-1;
    }
    
    /**
     * @dev Remove token as payment
     * @param _token Token address
     */
    function removePayment(address _token) external override onlyOwner{
        require(_token != address(0), "bad");
        require(_token == allPayments[getPaymentIndex[_token]], "!found");
        
        uint indexToDelete = getPaymentIndex[_token];
        address addressToMove = allPayments[allPayments.length-1];
        
        allPayments[indexToDelete] = addressToMove;
        getPaymentIndex[addressToMove] = indexToDelete;
        
        allPayments.pop();
        delete getPaymentIndex[_token];
    }

    /**
     * @dev Config Factory addresses
     * @param _savior Savior address
     * @param _operational Operational address
     * @param _marketing Marketing address
     * @param _treasury Treasury address
     */
    function config(address _savior, address _operational, address _marketing, address _treasury) external override onlyOwner{
        require(_savior != address(0) && _operational != address(0) && _marketing != address(0) && _treasury != address(0), "bad");
        savior = _savior;
        operational = _operational;
        marketing = _marketing;
        treasury = _treasury;
    }

    /**
     * @dev Config Factory percentage
     * @param _operationalPercentage Operational percentage in 2 decimal
     * @param _marketingPercentage Marketing percentage in 2 decimal
     * @param _treasuryPercentage Treasury percentage in 2 decimal
     */
    function setPercentage_d2(uint64 _operationalPercentage, uint64 _marketingPercentage, uint128 _treasuryPercentage) external override onlyOwner{
        require(uint128(_operationalPercentage) + uint128(_marketingPercentage) + _treasuryPercentage == 10000, "bad");
        operationalPercentage_d2 = _operationalPercentage;
        marketingPercentage_d2 = _marketingPercentage;
        treasuryPercentage_d2 = _treasuryPercentage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPublicGovFactory.sol";
import "./IKommunitasStaking.sol";
import "./IKommunitasStakingV2.sol";
import "./IPublicGovSale.sol";
import "./TransferHelper.sol";

contract PublicGovSale  is IPublicGovSale{
    IPublicGovFactory public immutable factory = IPublicGovFactory(msg.sender);

    address public owner = tx.origin;
    
    bool private initialized;
    bool public isPaused;
    bool public isRefund;

    enum StakingChoice { V1, V2 }

    uint128 public calculation;
    uint128 public feeMoved;
    
    uint128 public price; // in payment decimal
    uint128 public refund_d2; // refund in percent 2 decimal
    
    uint128 public raised; // sale amount get
    uint128 public revenue; // fee amount get

    uint128 public sale;
    uint128 public totalStaked;

    uint128 public minFCFSBuy;
    uint128 public maxFCFSBuy;

    uint128 public minComBuy;
    uint128 public maxComBuy;

    uint128 public whitelistTotalAlloc;
    uint128 public candidateTotalStaked;

    IERC20 public payment;

    address public gov;

    address[] public buyers;
    address[] public whitelists;
    address[] public candidates;
    
    struct Round{
        uint128 start;
        uint128 end;
        uint128 tokenAchieved;
        uint128 fee_d2; // in percent 2 decimal
    }
    
    struct Invoice{
        uint32 buyersIndex;
        uint32 boosterId;
        uint64 boughtAt;
        uint128 received;
        uint128 bought;
        uint128 charged;
    }
    
    mapping(uint32 => Round) public booster;
    mapping(address => Invoice[]) public invoices;
    mapping(address => string) public recipient;
    mapping(address => uint128) public whitelist;
    mapping(address => mapping(uint32 => uint128)) public purchasePerRound;
    mapping(address => bool) public refunded;
    
    mapping(address => uint128) private userStaked;
    mapping(address => mapping(uint32 => uint128)) private userAllocation;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    modifier isNotPaused{
        require(!isPaused, "paused");
        _;
    }
    
    modifier isBoosterProgress{
        require(boosterProgress() > 0, "!booster");
        _;
    }
    
    event TokenBought(uint32 indexed booster, address indexed buyer, uint128 tokenReceived, uint128 buyAmount, uint128 feeCharged);
    
    /**
     * @dev Initialize project for raise fund
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     * @param _payment Tokens to raise
     * @param _gov Governance address
     */
    function initialize(
        uint128 _calculation,
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[4] calldata _fee_d2,
        address _payment,
        address _gov
    ) external {
        require(!initialized && msg.sender == address(factory) && _calculation < _start, "bad");

        calculation = _calculation;
        sale = _sale;
        price = _price;
        payment = IERC20(_payment);
        gov = _gov;
        
        for(uint32 i=1; i<=4; i++){
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 4) booster[i].end = booster[i].start + _duration;
            booster[i].fee_d2 = _fee_d2[i-1];
        }

        initialized = true;
    }
    
    // **** VIEW AREA ****
    
    /**
     * @dev Get all whitelists length
     */
    function getWhitelistLength() external view returns(uint) {
        return whitelists.length;
    }
    
    /**
     * @dev Get all buyers/participants length
     */
    function getBuyersLength() external view returns(uint) {
        return buyers.length;
    }

    /**
     * @dev Get all candidates length
     */
    function getCandidatesLength() external view returns(uint) {
        return candidates.length;
    }
    
    /**
     * @dev Get total number transactions of buyer
     */
    function getBuyerHistoryLength(address _buyer) external view returns(uint) {
        return invoices[_buyer].length;
    }
    
    /**
     * @dev Get V2Staked
     */
    function getV2Staked() private view returns(uint total) {
        total = 0;
        uint fetch;
        for(uint8 i=0; i<3; i++){
            uint lock = IKommunitasStakingV2(factory.stakingV2()).lockPeriod(i);
            (,,fetch) = IKommunitasStakingV2(factory.stakingV2()).staked(lock);
            total += fetch;
        }
    }

    /**
     * @dev Get User Staked Info
     * @param _choice V1 or V2 Staking
     * @param _target User address
     */
    function getUserStakedInfo(StakingChoice _choice, address _target) private view returns(uint128 staked) {
        if(_choice == StakingChoice.V1){
            staked = uint128(IKommunitasStaking(factory.stakingV1()).getUserStakedTokens(_target));
        }else if(_choice == StakingChoice.V2){
            staked = uint128(IKommunitasStakingV2(factory.stakingV2()).getUserStakedTokensBeforeDate(_target, calculation));
        }else{
            revert("bad");
        }
    }

    /**
     * @dev Get User Total Staked Kom
     * @param _user User address
     */
    function getUserTotalStaked(address _user) public view returns(uint128){
        uint128 userV1Staked = getUserStakedInfo(StakingChoice.V1, _user);
        uint128 userV2Staked = getUserStakedInfo(StakingChoice.V2, _user);
        return userV1Staked + userV2Staked;
    }

    /**
     * @dev Get User Total Staked Allocation
     * @param _user User address
     * @param _boosterRunning Booster progress
     */
    function getUserAllocation(address _user, uint32 _boosterRunning) public view returns(uint128 userAlloc){
        uint128 saleAmount = sale;
        uint128 userStakedToken = _boosterRunning == 1 ? userStaked[_user] : getUserTotalStaked(_user);

        if(_boosterRunning == 1){
            if(userStakedToken > 0){
                uint128 alloc = (userStakedToken * 10**8) / candidateTotalStaked;
                userAlloc = (alloc * (saleAmount - whitelistTotalAlloc)) / 10**8;
            }

            uint128 whitelistAmount = whitelist[_user];

            if(whitelistAmount > 0) userAlloc += whitelistAmount;
        } else if(_boosterRunning == 2){
            uint128 booster1Achieve = booster[1].tokenAchieved;
            if(booster1Achieve > 0 || uint128(block.timestamp) >= booster[_boosterRunning].start) {
                uint128 left = saleAmount - booster1Achieve;
                uint128 alloc = (userStakedToken * 10**8) / totalStaked;

                userAlloc = (alloc * left) / 10**8;
            }
        } else if(_boosterRunning == 3){
            if(userStakedToken > 0) userAlloc = maxFCFSBuy;
        } else if(_boosterRunning == 4){
            userAlloc = maxComBuy;
        }
    }

    /**
     * @dev Check whether buyer/participant or not
     * @param _user User address
     */
    function isBuyer(address _user) private view returns (bool) {
        if(buyers.length == 0) return false;
        return (invoices[_user].length > 0);
    }
    
    /**
     * @dev Get total purchase of a user
     * @param _user User address
     */
    function getTotalPurchase(address _user) public view returns(uint128 total) {
        total = purchasePerRound[_user][1] + purchasePerRound[_user][2] + purchasePerRound[_user][3] + purchasePerRound[_user][4];
    }
    
    /**
     * @dev Get booster running now, 0 = no booster running
     */
    function boosterProgress() public view returns (uint32 running) {
        running = 0;
        for(uint32 i=1; i<=4; i++){
            if( (uint128(block.timestamp) >= booster[i].start && uint128(block.timestamp) <= booster[i].end) ||
                (i == 4 && uint128(block.timestamp) >= booster[i].start)
            ){
                running = i;
                break;
            }
        }
    }
    
    /**
     * @dev Get total sold tokens
     */
    function sold() public view returns(uint128 total) {
        total = 0;
        for(uint32 i=1; i<=4; i++){
            total += booster[i].tokenAchieved;
        }
    }
    
    /**
     * @dev Calculate amount in
     * @param _tokenReceived Token received amount
     * @param _user User address
     * @param _running Booster running
     * @param _boosterPrice Booster running price
     */
    function amountInCalc(
        uint128 _tokenReceived,
        address _user,
        uint32 _running,
        uint128 _boosterPrice
    ) private view returns(uint128 amountInFinal, uint128 tokenReceivedFinal) {
        uint128 left = sale - sold();
        require(left > 0, "!sale");

        if(_tokenReceived > left) _tokenReceived = left;

        amountInFinal = (_tokenReceived * _boosterPrice) / 10**18;
        
        uint128 alloc;
        if(_running < 3){
            alloc = userAllocation[_user][_running];
        } else if(_running == 3){
            require(minFCFSBuy > 0 && maxFCFSBuy > 0 && _tokenReceived >= minFCFSBuy, "<min");
            alloc = maxFCFSBuy;
        } else if(_running == 4){
            require(minComBuy > 0 && maxComBuy > 0 && _tokenReceived >= minComBuy, "<min");
            alloc = maxComBuy;
        }

        uint128 purchaseThisRound = purchasePerRound[_user][_running];
        require(purchaseThisRound < alloc, "max");

        if(purchaseThisRound + _tokenReceived > alloc){
            amountInFinal = ((alloc - purchaseThisRound) * _boosterPrice) / 10**18;
        }

        require(amountInFinal > 0, "small");
        tokenReceivedFinal = (amountInFinal * 10**18) / _boosterPrice;
    }
    
    /**
     * @dev Convert address to string
     * @param x Address to convert
     */
    function toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    // **** MAIN AREA ****
    
    /**
     * @dev Move raised fund to devAddr/project owner
     */
    function moveFund(uint16 _percent_d2, bool _devAddr, address _target) external {
        uint amount = (raised * _percent_d2) / 10000;
        require(payment.balanceOf(address(this)) >= amount && !isRefund && (msg.sender == factory.savior() || msg.sender == owner), "bad");

        if(_devAddr){
            TransferHelper.safeTransfer(address(payment), factory.operational(), amount);
        } else{
            require(_target != address(0), "wat");
            TransferHelper.safeTransfer(address(payment), _target, amount);
        }
    }

    /**
     * @dev Move fee to devAddr
     */
    function moveFee() external {
        uint128 amount = revenue;
        uint128 left = amount - feeMoved;
        require(payment.balanceOf(address(this)) >= left && left > 0 && (msg.sender == factory.savior() || msg.sender == owner), "bad");
        
        feeMoved = amount;

        TransferHelper.safeTransfer(address(payment), factory.operational(), (left * factory.operationalPercentage_d2()) / 10000);
        TransferHelper.safeTransfer(address(payment), factory.marketing(), (left * factory.marketingPercentage_d2()) / 10000);
        TransferHelper.safeTransfer(address(payment), factory.treasury(), (left * factory.treasuryPercentage_d2()) / 10000);
    }
    
    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     */
    function buyToken(uint128 _amountIn) external isBoosterProgress isNotPaused {
        uint32 running = boosterProgress();
        
        if(running == 1){
            require(_setUserAllocation(msg.sender, running), "bad");
            require(candidateTotalStaked > 0 && (userStaked[msg.sender] > 0 || whitelist[msg.sender] > 0), "!eligible");
        } else if(running == 2 || running == 3){
            require(setAllocation(msg.sender, running), "bad");
            require(totalStaked > 0 && userStaked[msg.sender] > 0, "!eligible");
        }

        uint32 buyerId = setBuyer(msg.sender);

        uint128 boosterPrice = price;

        uint128 tokenReceived = (_amountIn * 10**18) / boosterPrice;
        
        (uint128 amountInFinal, uint128 tokenReceivedFinal) = amountInCalc(tokenReceived, msg.sender, running, boosterPrice);
        
        uint128 feeCharged = (amountInFinal * booster[running].fee_d2) / 10000;

        invoices[msg.sender].push(Invoice(buyerId, running, uint64(block.timestamp), tokenReceivedFinal, amountInFinal, feeCharged));
        
        raised += amountInFinal;
        revenue += feeCharged;
        purchasePerRound[msg.sender][running] += tokenReceivedFinal;
        booster[running].tokenAchieved += tokenReceivedFinal;

        TransferHelper.safeTransferFrom(address(payment), msg.sender, address(this), amountInFinal + feeCharged);
        
        emit TokenBought(running, msg.sender, tokenReceivedFinal, amountInFinal, feeCharged);
    }

    /**
     * @dev KOM Team buy some left tokens
     * @param _tokenAmount Token amount to buy
     */
    function teamBuy(uint128 _tokenAmount) external isBoosterProgress isNotPaused {
        require(msg.sender == factory.savior() || msg.sender == owner, "??");

        uint32 running = boosterProgress();
        require(running > 2, "bad");

        uint32 buyerId = setBuyer(msg.sender);

        uint128 left = sale - sold();
        if(_tokenAmount > left) _tokenAmount = left;

        invoices[msg.sender].push(Invoice(buyerId, running, uint64(block.timestamp), _tokenAmount, 0, 0));
        
        purchasePerRound[msg.sender][running] += _tokenAmount;
        booster[running].tokenAchieved += _tokenAmount;
        
        emit TokenBought(running, msg.sender, _tokenAmount, 0, 0);
    }

    /**
     * @dev Refund payment
     */
    function refund() external {
        uint128 _refund_d2 = refund_d2;
        uint256 amount = (uint256(getTotalPurchase(msg.sender)) * uint256(price) * uint256(_refund_d2)) / 1e22; // 1e18 (token decimal) + 1e4 (percent 2 decimal)

        require(isRefund && _refund_d2 > 0 && isBuyer(msg.sender) && !refunded[msg.sender] && payment.balanceOf(address(this)) >= amount, "bad");
        
        refunded[msg.sender] = true;

        TransferHelper.safeTransfer(address(payment), msg.sender, amount);
    }

    /**
     * @dev Set buyer allocation
     * @param _user User address
     * @param _running Booster running
     */
    function setAllocation(address _user, uint32 _running) private returns(bool) {
        require(_setUserTotalStaked(_user), "bad#1");
        require(_setUserAllocation(_user, _running), "bad#2");

        return true;
    }

    /**
     * @dev Set user total KOM staked
     * @param _user User address
     */
    function _setUserTotalStaked(address _user) private returns(bool) {
        if(userStaked[_user] == 0) userStaked[_user] = getUserTotalStaked(_user);

        return true;
    }

    /**
     * @dev Set user allocation token to buy
     * @param _user User address
     * @param _running Booster running
     */
    function _setUserAllocation(address _user, uint32 _running) private returns(bool) {
        if(userAllocation[_user][_running] == 0 && _running < 3) userAllocation[_user][_running] = getUserAllocation(_user, _running);
        
        return true;
    }

    /**
     * @dev Set buyer id
     * @param _user User address
     */
    function setBuyer(address _user) private returns(uint32 buyerId) {
        if(!isBuyer(_user)){
            buyers.push(_user);
            buyerId = uint32(buyers.length - 1);
            
            if(bytes(recipient[_user]).length == 0) recipient[_user] = toAsciiString(_user);
        }else{
            buyerId = invoices[_user][0].buyersIndex;
        }
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string calldata _recipient) external isNotPaused  {
        require(((((sale - sold()) * price) / 10**18) > 0) && bytes(_recipient).length != 0, "bad");

        recipient[msg.sender] = _recipient;
    }
    
    /**
     * @dev Set total KOM staked
     */
    function setTotalStaked() external {
        require(uint128(block.timestamp) >= calculation && totalStaked == 0, "bad");
        
        uint128 v1 = uint128(IKommunitasStaking(factory.stakingV1()).communityStaked());
        uint128 v2 = uint128(getV2Staked());

        totalStaked = v1 + v2;
    }

    /**
     * @dev Migrate candidates from gov contract
     * @param _candidates Candidate address
     */
    function migrateCandidates(address[] calldata _candidates) external returns (bool) {
        require(msg.sender == gov && uint128(block.timestamp) >= calculation && uint128(block.timestamp) < booster[1].start, "bad");

        uint128 candidateStaked = candidateTotalStaked;
        for(uint16 i=0; i<_candidates.length; i++){
            if(userStaked[_candidates[i]] == 0){
                _setUserTotalStaked(_candidates[i]);
                candidateStaked += userStaked[_candidates[i]];
            }
        }

        candidateTotalStaked = candidateStaked;

        candidates = _candidates;

        return true;
    }
    
    // **** ADMIN AREA ****

    function refundAirdrop(address _from, address _to) external onlyOwner {
        uint128 _refund_d2 = refund_d2;
        uint256 amount = (uint256(getTotalPurchase(_from)) * uint256(price) * uint256(_refund_d2)) / 1e22; // 1e18 (token decimal) + 1e4 (percent 2 decimal)

        require(_to != address(0) && isRefund && _refund_d2 > 0 && isBuyer(_from) && !refunded[_from] && payment.balanceOf(address(this)) >= amount, "bad");
        
        refunded[_from] = true;

        TransferHelper.safeTransfer(address(payment), _to, amount);
    }

    /**
     * @dev Set whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function setWhitelist_d6(address[] calldata _user, uint128[] calldata _allocation) external onlyOwner {
        require(uint128(block.timestamp) < calculation && _user.length == _allocation.length, "bad");
        
        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; i++){
            if(whitelist[_user[i]] == 0){
                whitelists.push(_user[i]);
                whitelist[_user[i]] = (_allocation[i] * 10**18) / 10**6;
                whitelistTotal += whitelist[_user[i]];
            }
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Update whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function updateWhitelist_d6(address[] calldata _user, uint128[] calldata _allocation) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start && _user.length == _allocation.length, "bad");

        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; i++){
            if(whitelist[_user[i]] == 0) continue;

            uint128 oldAlloc = whitelist[_user[i]];
            whitelist[_user[i]] = (_allocation[i] * 10**18) / 10**6;
            whitelistTotal = whitelistTotal - oldAlloc + whitelist[_user[i]];
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxFCFSBuy Min and max token to buy
     */
    function setMinMaxFCFS(uint128[2] calldata _minMaxFCFSBuy) external onlyOwner {
        if(boosterProgress() < 3) minFCFSBuy = _minMaxFCFSBuy[0];
        maxFCFSBuy = _minMaxFCFSBuy[1];
    }

    /**
     * @dev Set Min & Max in Community Round
     * @param _minMaxComBuy Min and max token to buy
     */
    function setMinMaxCom(uint128[2] calldata _minMaxComBuy) external onlyOwner {
        if(boosterProgress() < 4) minComBuy = _minMaxComBuy[0];
        maxComBuy = _minMaxComBuy[1];
    }

    /**
     * @dev Set Calculation
     * @param _calculation Epoch date to start buy allocation calculation
     */
    function setCalculation(uint128 _calculation) external onlyOwner {
        require(uint128(block.timestamp) < calculation, "bad");

        calculation = _calculation;
    }

    /**
     * @dev Set Start
     * @param _start Epoch date to start round 1
     */
    function setStart(uint128 _start, uint128 _duration) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        for(uint32 i=1; i<=4; i++){
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 4) booster[i].end = booster[i].start + _duration;
        }
    }

    /**
     * @dev Set Sale
     * @param _sale Amount token project to sell (based on token decimals of project)
     */
    function setSale(uint128 _sale) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        sale = _sale;
    }
    
    /**
     * @dev Set price
     * @param _price Token project price in payment decimal
     */
    function setPrice(uint128 _price) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        price = _price;
    }

    /**
     * @dev Set fee per round
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     */
    function setFee_d2(uint128[4] calldata _fee_d2) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        for(uint32 i=1; i<=4; i++){
            booster[i].fee_d2 = _fee_d2[i-1];
        }
    }

    /**
     * @dev Set Payment
     * @param _payment Tokens to raise
     */
    function setPayment(address _payment) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        payment = IERC20(_payment);
    }

    /**
     * @dev Set Gov
     * @param _gov Governance address
     */
    function setGov(address _gov) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        gov = _gov;
    }

    /**
     * @dev Transfer Ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }

    /**
     * @dev Toggle refund
     * @param _refund_d2 Refund percent in 2 decimal
     */
    function toggleRefund(uint128 _refund_d2) external onlyOwner {
        isRefund = !isRefund;
        refund_d2 = _refund_d2;
    }
    
    /**
     * @dev Toggle buyToken pause
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "../RcaShieldNormalized.sol";
import { IMasterChef } from "../../external/Sushiswap.sol";

contract RcaShieldOnsen is RcaShieldNormalized {
    using SafeERC20 for IERC20Metadata;

    IMasterChef public immutable masterChef;

    // Check our masterchef against this to call the correct functions.
    address private constant MCV1 = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    uint256 public immutable pid;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governance,
        address _controller,
        IMasterChef _masterChef,
        uint256 _pid
    ) RcaShieldNormalized(_name, _symbol, _uToken, _uTokenDecimals, _governance, _controller) {
        masterChef = _masterChef;
        pid = _pid;
        uToken.safeApprove(address(masterChef), type(uint256).max);
    }

    function getReward() external {
        masterChef.harvest(pid, address(this));
    }

    function purchase(
        address _token,
        uint256 _amount, // token amount to buy
        uint256 _tokenPrice,
        bytes32[] calldata _tokenPriceProof,
        uint256 _underlyingPrice,
        bytes32[] calldata _underlyinPriceProof
    ) external {
        require(_token != address(uToken), "cannot buy underlying token");
        controller.verifyPrice(_token, _tokenPrice, _tokenPriceProof);
        controller.verifyPrice(address(uToken), _underlyingPrice, _underlyinPriceProof);
        uint256 underlyingAmount = (_amount * _tokenPrice) / _underlyingPrice;
        if (discount > 0) {
            underlyingAmount -= (underlyingAmount * discount) / DENOMINATOR;
        }

        IERC20Metadata token = IERC20Metadata(_token);
        // normalize token amount to transfer to the user so that it can handle different decimals
        _amount = (_amount * 10**token.decimals()) / BUFFER;

        token.safeTransfer(msg.sender, _amount);
        uToken.safeTransferFrom(msg.sender, address(this), _normalizedUAmount(underlyingAmount));

        masterChef.deposit(pid, underlyingAmount, address(this));
    }

    function _uBalance() internal view override returns (uint256) {
        return
            ((uToken.balanceOf(address(this)) + masterChef.userInfo(pid, address(this)).amount) * BUFFER) /
            BUFFER_UTOKEN;
    }

    function _afterMint(uint256 _uAmount) internal override {
        if (address(masterChef) == MCV1) masterChef.deposit(pid, _uAmount);
        else masterChef.deposit(pid, _uAmount, address(this));
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        if (address(masterChef) == MCV1) masterChef.withdraw(pid, _uAmount);
        else masterChef.withdraw(pid, _uAmount, address(this));
    }
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./RcaShieldBase.sol";

contract RcaShieldNormalized is RcaShieldBase {
    using SafeERC20 for IERC20Metadata;

    uint256 immutable BUFFER_UTOKEN;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governor,
        address _controller
    ) RcaShieldBase(_name, _symbol, _uToken, _governor, _controller) {
        BUFFER_UTOKEN = 10**_uTokenDecimals;
    }

    function mintTo(
        address _user,
        address _referrer,
        uint256 _uAmount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external override {
        // Call controller to check capacity limits, add to capacity limits, emit events, check for new "for sale".
        controller.mint(_user, _uAmount, _expiry, _v, _r, _s, _newCumLiqForClaims, _liqForClaimsProof);

        // Only update fees after potential contract update.
        _update();

        uint256 rcaAmount = _rcaValue(_uAmount, amtForSale);

        // handles decimals diff of underlying tokens
        _uAmount = _normalizedUAmount(_uAmount);
        uToken.safeTransferFrom(msg.sender, address(this), _uAmount);

        _mint(_user, rcaAmount);

        _afterMint(_uAmount);

        emit Mint(msg.sender, _user, _referrer, _uAmount, rcaAmount, block.timestamp);
    }

    function redeemFinalize(
        address _to,
        bytes calldata _routerData,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external override {
        // Removed address user = msg.sender because of stack too deep.

        WithdrawRequest memory request = withdrawRequests[msg.sender];
        delete withdrawRequests[msg.sender];

        // endTime > 0 ensures request exists.
        require(request.endTime > 0 && uint32(block.timestamp) > request.endTime, "Withdrawal not yet allowed.");

        bool isRouterVerified = controller.redeemFinalize(msg.sender, _to, _newCumLiqForClaims, _liqForClaimsProof, _newPercentReserved, _percentReservedProof);

        _update();

        pendingWithdrawal -= uint256(request.rcaAmount);

        // handles decimals diff of underlying tokens
        uint256 uAmount = _uValue(request.rcaAmount, amtForSale, percentReserved);
        if (uAmount > request.uAmount) uAmount = request.uAmount;

        uint256 transferAmount = _normalizedUAmount(uAmount);
        uToken.safeTransfer(_to, transferAmount);

        // The cool part about doing it this way rather than having user send RCAs to router contract,
        // then it exchanging and returning Ether is that it's more gas efficient and no approvals are needed.
        if (isRouterVerified) IRouter(_to).routeTo(msg.sender, transferAmount, _routerData);

        emit RedeemFinalize(msg.sender, _to, transferAmount, uint256(request.rcaAmount), block.timestamp);
    }

    function purchaseU(
        address _user,
        uint256 _uAmount,
        uint256 _uEthPrice,
        bytes32[] calldata _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external payable override {
        // If user submits incorrect price, tx will fail here.
        controller.purchase(_user, address(uToken), _uEthPrice, _priceProof, _newCumLiqForClaims, _liqForClaimsProof);

        _update();

        uint256 price = _uEthPrice - ((_uEthPrice * discount) / DENOMINATOR);
        // divide by 1 ether because price also has 18 decimals.
        uint256 ethAmount = (price * _uAmount) / 1 ether;
        require(msg.value == ethAmount, "Incorrect Ether sent.");

        // If amount is bigger than for sale, tx will fail here.
        amtForSale -= _uAmount;

        // handles decimals diff of underlying tokens
        _uAmount = _normalizedUAmount(_uAmount);
        uToken.safeTransfer(_user, _uAmount);
        treasury.transfer(msg.value);

        emit PurchaseU(_user, _uAmount, ethAmount, _uEthPrice, block.timestamp);
    }

    /**
     * @notice Normalizes underlying token amount by taking consideration of its
     * decimals.
     * @param _uAmount Utoken amount in 18 decimals
     */
    function _normalizedUAmount(uint256 _uAmount) internal view returns (uint256 amount) {
        amount = (_uAmount * BUFFER_UTOKEN) / BUFFER;
    }

    function _uBalance() internal view virtual override returns (uint256) {
        return (uToken.balanceOf(address(this)) * BUFFER) / BUFFER_UTOKEN;
    }

    function _afterMint(uint256) internal virtual override {
        // no-op
    }

    function _afterRedeem(uint256) internal virtual override {
        // no-op
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function deposit(
        uint256 pid,
        uint256 amount
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;
}

/// SPDX-License-Identifier: UNLICENSED

/**
 * By using this contract and/or any other launched by the Ease protocol, you agree to Ease's
 * Terms and Conditions, Privacy Policy, and Terms of Coverage.
 * https://ease.org/about-ease-defi/terms-and-conditions-disclaimer/
 * https://ease.org/about-ease-defi/privacy-policy/
 * https://ease.org/learn-crypto-defi/get-defi-cover-at-ease/ease-defi-cover/terms-of-ease-coverage/
 */

/**

                               ................                            
                          ..',,;;::::::::ccccc:;,'..                       
                      ..',;;;;::::::::::::cccccllllc;..                    
                    .';;;;;;;,'..............',:clllolc,.                  
                  .,;;;;;,..                    .';cooool;.                
                .';;;;;'.           .....          .,coodoc.               
               .,;;;;'.       ..',;:::cccc:;,'.      .;odddl'              
              .,;;;;.       .,:cccclllllllllool:'      ,odddl'             
             .,:;:;.      .;ccccc:;,''''',;cooooo:.     ,odddc.            
             ';:::'     .,ccclc,..         .':odddc.    .cdddo,            
            .;:::,.     ,cccc;.              .:oddd:.    ,dddd:.           
            '::::'     .ccll:.                .ldddo'    'odddc.           
            ,::c:.     ,lllc'    .';;;::::::::codddd;    ,dxxxc.           
           .,ccc:.    .;lllc.    ,oooooddddddddddddd;    :dxxd:            
            ,cccc.     ;llll'    .;:ccccccccccccccc;.   'oxxxo'            
            'cccc,     'loooc.                         'lxxxd;             
            .:lll:.    .;ooooc.                      .;oxxxd:.             
             ,llll;.    .;ooddo:'.                ..:oxxxxo;.              
             .:llol,.     'coddddl:;''.........,;codxxxxd:.                
              .:lool;.     .':odddddddddoooodddxxxxxxdl;.                  
               .:ooooc'       .';codddddddxxxxxxdol:,.                     
                .;ldddoc'.        ...'',,;;;,,''..                         
                  .:oddddl:'.                          .,;:'.              
                    .:odddddoc;,...              ..',:ldxxxx;              
                      .,:odddddddoolcc::::::::cllodxxxxxxxd:.              
                         .';clddxxxxxxxxxxxxxxxxxxxxxxoc;'.                
                             ..',;:ccllooooooollc:;,'..                    
                                        ......                             
                                                                      
**/

pragma solidity 0.8.11;
import "../general/Governable.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IRcaController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RCA Vault
 * @notice Main contract for reciprocally-covered assets. Mints, redeems, and sells.
 * Each underlying token (not protocol) has its own RCA vault. This contract
 * doubles as the vault and the RCA token.
 * @dev This contract assumes uToken decimals of 18.
 * @author Ease -- Robert M.C. Forster, Romke Jonker, Taek Lee, Chiranjibi Poudyal, Dominik Prediger
 **/
abstract contract RcaShieldBase is ERC20, Governable {
    using SafeERC20 for IERC20Metadata;

    uint256 constant YEAR_SECS = 31536000;
    uint256 constant DENOMINATOR = 10000;
    uint256 constant BUFFER = 1e18;

    /// @notice Controller of RCA contract that takes care of actions.
    IRcaController public controller;
    /// @notice Underlying token that is protected by the shield.
    IERC20Metadata public immutable uToken;

    /// @notice Percent to pay per year. 1000 == 10%.
    uint256 public apr;
    /// @notice Current sale discount to sell tokens cheaper.
    uint256 public discount;
    /// @notice Treasury for all funds that accepts payments.
    address payable public treasury;
    /// @notice Percent of the contract that is currently paused and cannot be withdrawn.
    /// Set > 0 when a hack has happened and DAO has not submitted for sales.
    /// Withdrawals during this time will lose this percent. 1000 == 10%.
    uint256 public percentReserved;

    /**
     * @notice Cumulative total amount that has been liquidated lol.
     * @dev Used to make sure we don't run into a situation where liq amount isn't updated,
     * a new hack occurs and current liq is added to, then current liq is updated while
     * DAO votes on the new total liq. In this case we can subtract that interim addition.
     */
    uint256 public cumLiqForClaims;
    /// @notice Amount of tokens currently up for sale.
    uint256 public amtForSale;

    /**
     * @notice Amount of RCA tokens pending withdrawal.
     * @dev When doing value calculations this is required because RCAs are burned immediately
     * upon request, but underlying tokens only leave the contract once the withdrawal is finalized.
     */
    uint256 public pendingWithdrawal;
    /// @notice withdrawal variable for withdrawal delays.
    uint256 public withdrawalDelay;
    /// @notice Requests by users for withdrawals.
    mapping(address => WithdrawRequest) public withdrawRequests;

    /**
     * @notice Last time the contract has been updated.
     * @dev Used to calculate APR if fees are implemented.
     */
    uint256 lastUpdate;

    struct WithdrawRequest {
        uint112 uAmount;
        uint112 rcaAmount;
        uint32 endTime;
    }

    /// @notice Notification of the mint of new tokens.
    event Mint(
        address indexed sender,
        address indexed to,
        address indexed referrer,
        uint256 uAmount,
        uint256 rcaAmount,
        uint256 timestamp
    );
    /// @notice Notification of an initial redeem request.
    event RedeemRequest(address indexed user, uint256 uAmount, uint256 rcaAmount, uint256 endTime, uint256 timestamp);
    /// @notice Notification of a redeem finalization after withdrawal delay.
    event RedeemFinalize(
        address indexed user,
        address indexed to,
        uint256 uAmount,
        uint256 rcaAmount,
        uint256 timestamp
    );
    /// @notice Notification of a purchase of the underlying token.
    event PurchaseU(address indexed to, uint256 uAmount, uint256 ethAmount, uint256 price, uint256 timestamp);
    /// @notice Notification of a purchase of an RCA token.
    event PurchaseRca(
        address indexed to,
        uint256 uAmount,
        uint256 rcaAmount,
        uint256 ethAmount,
        uint256 price,
        uint256 timestamp
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// modifiers //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Restrict set functions to only controller for many variables.
     */
    modifier onlyController() {
        require(msg.sender == address(controller), "Function must only be called by controller.");
        _;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// constructor ////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Construct shield and RCA ERC20 token.
     * @param _name Name of the RCA token.
     * @param _symbol Symbol of the RCA token.
     * @param _uToken Address of the underlying token.
     * @param _governor Address of the governor (owner) of the shield.
     * @param _controller Address of the controller that maintains the shield.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        address _governor,
        address _controller
    ) ERC20(_name, _symbol) {
        initializeGovernable(_governor);
        uToken = IERC20Metadata(_uToken);
        controller = IRcaController(_controller);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// initialize /////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Controller calls to initiate which sets current contract variables. All %s are 1000 == 10%.
     * @param _apr Fees for using the RCA ecosystem.
     * @param _discount Discount for purchases while tokens are being liquidated.
     * @param _treasury Address of the treasury to which Ether from fees and liquidation will be sent.
     * @param _withdrawalDelay Delay of withdrawals from the shield in seconds.
     */
    function initialize(
        uint256 _apr,
        uint256 _discount,
        address payable _treasury,
        uint256 _withdrawalDelay
    ) external onlyController {
        require(treasury == address(0), "Contract has already been initialized.");
        apr = _apr;
        discount = _discount;
        treasury = _treasury;
        withdrawalDelay = _withdrawalDelay;
        lastUpdate = block.timestamp;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// external //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Mint tokens to an address. Not automatically to msg.sender so we can more easily zap assets.
     * @param _user The user to mint tokens to.
     * @param _referrer The address that referred this user.
     * @param _uAmount Amount of underlying tokens desired to use for mint.
     * @param _expiry Time (Unix timestamp) that this request expires.
     * @param _v The recovery byte of the signature.
     * @param _r Half of the ECDSA signature pair.
     * @param _s Half of the ECDSA signature pair.
     * @param _newCumLiqForClaims New total cumulative liquidated if there is one.
     * @param _liqForClaimsProof Merkle proof to verify cumulative liquidated.
     */
    function mintTo(
        address _user,
        address _referrer,
        uint256 _uAmount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external virtual {
        // Call controller to check capacity limits, add to capacity limits, emit events, check for new "for sale".
        controller.mint(_user, _uAmount, _expiry, _v, _r, _s, _newCumLiqForClaims, _liqForClaimsProof);

        // Only update fees after potential contract update.
        _update();

        uint256 rcaAmount = _rcaValue(_uAmount, amtForSale);

        uToken.safeTransferFrom(msg.sender, address(this), _uAmount);

        _mint(_user, rcaAmount);

        _afterMint(_uAmount);

        emit Mint(msg.sender, _user, _referrer, _uAmount, rcaAmount, block.timestamp);
    }

    /**
     * @notice Request redemption of RCAs back to the underlying token.
     * Has a withdrawal delay so it's 2 parts (request and finalize).
     * @param _rcaAmount The amount of tokens (in RCAs) to be redeemed.
     * @param _newCumLiqForClaims New cumulative liquidated if this must be updated.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated.
     * @param _newPercentReserved New percent of funds in shield that are reserved.
     * @param _percentReservedProof Merkle proof for the new percent reserved.
     */
    function redeemRequest(
        uint256 _rcaAmount,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external {
        controller.redeemRequest(
            msg.sender,
            _newCumLiqForClaims,
            _liqForClaimsProof,
            _newPercentReserved,
            _percentReservedProof
        );

        _update();

        uint256 uAmount = _uValue(_rcaAmount, amtForSale, percentReserved);
        _burn(msg.sender, _rcaAmount);

        _afterRedeem(uAmount);

        pendingWithdrawal += _rcaAmount;

        WithdrawRequest memory curRequest = withdrawRequests[msg.sender];
        uint112 newUAmount = uint112(uAmount) + curRequest.uAmount;
        uint112 newRcaAmount = uint112(_rcaAmount) + curRequest.rcaAmount;
        uint32 endTime = uint32(block.timestamp) + uint32(withdrawalDelay);
        withdrawRequests[msg.sender] = WithdrawRequest(newUAmount, newRcaAmount, endTime);

        emit RedeemRequest(msg.sender, uint256(uAmount), _rcaAmount, uint256(endTime), block.timestamp);
    }

    /**
     * @notice Used to exchange RCA tokens back to the underlying token. Will have a 1-2 day delay upon withdrawal.
     * This can mint to a router contract that can exchange the asset for Ether and send to the user.
     * @param _to The destination of the tokens.
     * @param _newCumLiqForClaims New cumulative liquidated if this must be updated.
     * @param _liqForClaimsProof Merkle proof to verify new cumulative liquidation.
     * @param _liqForClaimsProof Merkle proof to verify the new cumulative liquidated.
     * @param _newPercentReserved New percent of funds in shield that are reserved.
     * @param _percentReservedProof Merkle proof for the new percent reserved.
     */
    function redeemFinalize(
        address _to,
        bytes calldata _routerData,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external virtual {
        address user = msg.sender;

        WithdrawRequest memory request = withdrawRequests[user];
        delete withdrawRequests[user];

        // endTime > 0 ensures request exists.
        require(request.endTime > 0 && uint32(block.timestamp) > request.endTime, "Withdrawal not yet allowed.");

        bool isRouterVerified = controller.redeemFinalize(
            user,
            _to,
            _newCumLiqForClaims,
            _liqForClaimsProof,
            _newPercentReserved,
            _percentReservedProof
        );

        _update();

        // We're going to calculate uAmount a second time here then send the lesser of the two.
        // If we only calculate once, users can either get their full uAmount after a hack if percentReserved
        // hasn't been sent in, or users can earn yield after requesting redeem (with the same consequence).
        uint256 uAmount = _uValue(request.rcaAmount, amtForSale, percentReserved);
        if (request.uAmount < uAmount) uAmount = uint256(request.uAmount);

        pendingWithdrawal -= uint256(request.rcaAmount);

        uToken.safeTransfer(_to, uAmount);

        // The cool part about doing it this way rather than having user send RCAs to router contract,
        // then it exchanging and returning Ether is that it's more gas efficient and no approvals are needed.
        // (and no nonsense with the withdrawal delay making routers wonky)
        if (isRouterVerified) IRouter(_to).routeTo(user, uAmount, _routerData);

        emit RedeemFinalize(user, _to, uAmount, uint256(request.rcaAmount), block.timestamp);
    }

    /**
     * @notice Purchase underlying tokens directly. This will be preferred by bots.
     * @param _user The user to purchase tokens for.
     * @param _uAmount Amount of underlying tokens to purchase.
     * @param _uEthPrice Price of the underlying token in Ether per token.
     * @param _priceProof Merkle proof for the price.
     * @param _newCumLiqForClaims New cumulative amount for liquidation.
     * @param _liqForClaimsProof Merkle proof for new liquidation amounts.
     */
    function purchaseU(
        address _user,
        uint256 _uAmount,
        uint256 _uEthPrice,
        bytes32[] calldata _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external payable virtual {
        // If user submits incorrect price, tx will fail here.
        controller.purchase(_user, address(uToken), _uEthPrice, _priceProof, _newCumLiqForClaims, _liqForClaimsProof);

        _update();

        uint256 price = _uEthPrice - ((_uEthPrice * discount) / DENOMINATOR);
        // divide by 1 ether because price also has 18 decimals.
        uint256 ethAmount = (price * _uAmount) / 1 ether;
        require(msg.value == ethAmount, "Incorrect Ether sent.");

        // If amount is bigger than for sale, tx will fail here.
        amtForSale -= _uAmount;

        uToken.safeTransfer(_user, _uAmount);
        treasury.transfer(msg.value);

        emit PurchaseU(_user, _uAmount, ethAmount, _uEthPrice, block.timestamp);
    }

    /**
     * @notice purchaseRca allows a user to purchase the RCA directly with Ether through liquidation.
     * @param _user The user to make the purchase for.
     * @param _uAmount The amount of underlying tokens to purchase.
     * @param _uEthPrice The underlying token price in Ether per token.
     * @param _priceProof Merkle proof to verify this price.
     * @param _newCumLiqForClaims Old cumulative amount for sale.
     * @param _liqForClaimsProof Merkle proof of the for sale amounts.
     */
    function purchaseRca(
        address _user,
        uint256 _uAmount,
        uint256 _uEthPrice,
        bytes32[] calldata _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] calldata _liqForClaimsProof
    ) external payable {
        // If user submits incorrect price, tx will fail here.
        controller.purchase(_user, address(uToken), _uEthPrice, _priceProof, _newCumLiqForClaims, _liqForClaimsProof);

        _update();

        uint256 price = _uEthPrice - ((_uEthPrice * discount) / DENOMINATOR);
        // divide by 1 ether because price also has 18 decimals.
        uint256 ethAmount = (price * _uAmount) / 1 ether;
        require(msg.value == ethAmount, "Incorrect Ether sent.");

        // If amount is too big than for sale, tx will fail here.
        uint256 rcaAmount = _rcaValue(_uAmount, amtForSale);
        amtForSale -= _uAmount;

        _mint(_user, rcaAmount);
        treasury.transfer(msg.value);

        emit PurchaseRca(_user, _uAmount, rcaAmount, _uEthPrice, ethAmount, block.timestamp);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// view ////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev External version of RCA value is needed so that frontend can properly
     * calculate values in cases where the contract has not been recently updated.
     * @param _rcaAmount Amount of RCA tokens (18 decimal) to find the underlying token value of.
     * @param _cumLiqForClaims New cumulative liquidated if this must be updated.
     * @param _percentReserved Percent of tokens that are reserved after a hack payout.
     */
    function uValue(
        uint256 _rcaAmount,
        uint256 _cumLiqForClaims,
        uint256 _percentReserved
    ) external view returns (uint256 uAmount) {
        uint256 extraForSale = getExtraForSale(_cumLiqForClaims);
        uAmount = _uValue(_rcaAmount, amtForSale + extraForSale, _percentReserved);
    }

    /**
     * @dev External version of RCA value is needed so that frontend can properly
     * calculate values in cases where the contract has not been recently updated.
     * @param _uAmount Amount of underlying tokens (18 decimal).
     * @param _cumLiqForClaims New cumulative liquidated if this must be updated.
     */
    function rcaValue(uint256 _uAmount, uint256 _cumLiqForClaims) external view returns (uint256 rcaAmount) {
        uint256 extraForSale = getExtraForSale(_cumLiqForClaims);
        rcaAmount = _rcaValue(_uAmount, amtForSale + extraForSale);
    }

    /**
     * @notice Convert RCA value to underlying tokens. This is internal because new
     * for sale amounts will already have been retrieved and updated.
     * @param _rcaAmount The amount of RCAs to find the underlying value of.
     * @param _totalForSale Used by external value calls cause updates aren't made on those.
     * @param _percentReserved Percent of funds reserved if a hack is being examined.
     */
    function _uValue(
        uint256 _rcaAmount,
        uint256 _totalForSale,
        uint256 _percentReserved
    ) internal view returns (uint256 uAmount) {
        uint256 balance = _uBalance();

        if (totalSupply() == 0) return _rcaAmount;
        else if (balance < _totalForSale) return 0;

        uAmount = ((balance - _totalForSale) * _rcaAmount) / (totalSupply() + pendingWithdrawal);

        if (_percentReserved > 0) uAmount -= ((uAmount * _percentReserved) / DENOMINATOR);
    }

    /**
     * @notice Find the RCA value of an amount of underlying tokens.
     * @param _uAmount Amount of underlying tokens to find RCA value of.
     * @param _totalForSale Used by external value calls cause updates aren't made on those.
     */
    function _rcaValue(uint256 _uAmount, uint256 _totalForSale) internal view returns (uint256 rcaAmount) {
        uint256 balance = _uBalance();

        // Interesting edgecase in which 1 person is in vault, they request redeem, 
        // underlying continue to gain value, then withdraw their original value.
        // Vault is then un-useable because below we're dividing 0 by > 0.
        if (balance == 0 || totalSupply() == 0 || balance < _totalForSale) return _uAmount;

        rcaAmount = ((totalSupply() + pendingWithdrawal) * _uAmount) / (balance - _totalForSale);
    }

    /**
     * @notice For frontend calls. Doesn't need to verify info because it's not changing state.
     */
    function getExtraForSale(uint256 _newCumLiqForClaims) public view returns (uint256 extraForSale) {
        // Check for liquidation, then percent paused, then APR
        uint256 extraLiqForClaims = _newCumLiqForClaims - cumLiqForClaims;
        uint256 extraFees = _getInterimFees(controller.apr(), uint256(controller.getAprUpdate()));
        extraForSale = extraFees + extraLiqForClaims;
        return extraForSale;
    }

    /**
     * @notice Get the amount that should be added to "amtForSale" based on actions within the time since last update.
     * @dev If values have changed within the interim period,
     * this function averages them to find new owed amounts for fees.
     * @param _newApr new APR.
     * @param _aprUpdate start time for new APR.
     */
    function _getInterimFees(uint256 _newApr, uint256 _aprUpdate) internal view returns (uint256 fees) {
        // Get all variables that are currently in this contract's state.
        uint256 balance = _uBalance();
        uint256 aprAvg = apr * BUFFER;
        uint256 totalTimeElapsed = block.timestamp - lastUpdate;

        // Find average APR throughout period if it has been updated.
        if (_aprUpdate > lastUpdate) {
            uint256 aprPrev = apr * (_aprUpdate - lastUpdate);
            uint256 aprCur = _newApr * (block.timestamp - _aprUpdate);
            aprAvg = ((aprPrev + aprCur) * BUFFER) / totalTimeElapsed;
        }

        // Will probably never occur, but just in case.
        if (balance < amtForSale) return 0;

        // Calculate fees based on average active amount.
        uint256 activeInclReserved = balance - amtForSale;
        fees = (activeInclReserved * aprAvg * totalTimeElapsed) / YEAR_SECS / DENOMINATOR / BUFFER;
    }

    /**
     * @notice Grabs full underlying balance to make frontend fetching much easier.
     */
    function uBalance() external view returns (uint256) {
        return _uBalance();
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// internal ///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Update the amtForSale if there's an active fee.
     */
    function _update() internal {
        if (apr > 0) {
            uint256 balance = _uBalance();

            // If liquidation for claims is set incorrectly this could occur and break the contract.
            if (balance < amtForSale) return;

            uint256 secsElapsed = block.timestamp - lastUpdate;
            uint256 active = balance - amtForSale;
            uint256 activeExclReserved = active - ((active * percentReserved) / DENOMINATOR);

            amtForSale += (activeExclReserved * secsElapsed * apr) / YEAR_SECS / DENOMINATOR;
        }

        lastUpdate = block.timestamp;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// virtual ///////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Check balance of underlying token.
    function _uBalance() internal view virtual returns (uint256);

    /// @notice Logic to run after a mint, such as if we need to stake the underlying token.
    function _afterMint(uint256 _uAmount) internal virtual;

    /// @notice Logic to run after a redeem, such as unstaking.
    function _afterRedeem(uint256 _uAmount) internal virtual;

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////// onlyController //////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Update function to be called by controller. This is only called when a controller has made
     * an APR update since the last shield update was made, so it must do extra calculations to determine
     * what the exact costs throughout the period were according to when system updates were made.
     */
    function controllerUpdate(uint256 _newApr, uint256 _aprUpdate) external onlyController {
        uint256 extraFees = _getInterimFees(_newApr, _aprUpdate);

        amtForSale += extraFees;
        lastUpdate = block.timestamp;
    }

    /**
     * @notice Add a for sale amount to this shield vault.
     * @param _newCumLiqForClaims New cumulative total for sale.
     **/
    function setLiqForClaims(uint256 _newCumLiqForClaims) external onlyController {
        if (_newCumLiqForClaims > cumLiqForClaims) {
            amtForSale += _newCumLiqForClaims - cumLiqForClaims;
        } else {
            uint256 subtrahend = cumLiqForClaims - _newCumLiqForClaims;
            amtForSale = amtForSale > subtrahend ? amtForSale - subtrahend : 0;
        }

        require(_uBalance() >= amtForSale, "amtForSale is too high.");

        cumLiqForClaims = _newCumLiqForClaims;
    }

    /**
     * @notice Change the treasury address to which funds will be sent.
     * @param _newTreasury New treasury address.
     **/
    function setTreasury(address _newTreasury) external onlyController {
        treasury = payable(_newTreasury);
    }

    /**
     * @notice Change the percent reserved on this vault. 1000 == 10%.
     * @param _newPercentReserved New percent reserved.
     **/
    function setPercentReserved(uint256 _newPercentReserved) external onlyController {
        // Protection to not have too much reserved from any single vault.
        if (_newPercentReserved > 3300) {
            percentReserved = 3300;
        } else {
            percentReserved = _newPercentReserved;
        }
    }

    /**
     * @notice Change the withdrawal delay of withdrawing underlying tokens from vault. In seconds.
     * @param _newWithdrawalDelay New withdrawal delay.
     **/
    function setWithdrawalDelay(uint256 _newWithdrawalDelay) external onlyController {
        withdrawalDelay = _newWithdrawalDelay;
    }

    /**
     * @notice Change the discount that users get for purchasing from us. 1000 == 10%.
     * @param _newDiscount New discount.
     **/
    function setDiscount(uint256 _newDiscount) external onlyController {
        discount = _newDiscount;
    }

    /**
     * @notice Change the treasury address to which funds will be sent.
     * @param _newApr New APR. 1000 == 10%.
     **/
    function setApr(uint256 _newApr) external onlyController {
        apr = _newApr;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////// onlyGov //////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Update Controller to a new address. Very rare case for this to be used.
     * @param _newController Address of the new Controller contract.
     */
    function setController(address _newController) external onlyGov {
        controller = IRcaController(_newController);
    }

    /**
     * @notice Needed for Nexus to prove this contract lost funds. We'll likely have reinsurance
     * at least at the beginning to ensure we don't have too much risk in certain protocols.
     * @param _coverAddress Address that we need to send 0 eth to to confirm we had a loss.
     */
    function proofOfLoss(address payable _coverAddress) external onlyGov {
        _coverAddress.transfer(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract Governable {
    address payable private _governor;
    address payable private _pendingGovernor;

    event OwnershipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event PendingOwnershipTransfer(address indexed from, address indexed to);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeGovernable(address _newGovernor) internal {
        require(_governor == address(0), "already initialized");
        _governor = payable(_newGovernor);
        emit OwnershipTransferred(address(0), _newGovernor);
    }

    /**
     * @return the address of the owner.
     */
    function governor() public view returns (address payable) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGov() {
        require(isGov(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isGov() public view returns (bool) {
        return msg.sender == _governor;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function transferOwnership(address payable newGovernor) public onlyGov {
        _pendingGovernor = newGovernor;
        emit PendingOwnershipTransfer(_governor, newGovernor);
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingGovernor, "Only pending governor can call this function");
        _transferOwnership(_pendingGovernor);
        _pendingGovernor = payable(address(0));
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newGovernor The address to transfer ownership to.
     */
    function _transferOwnership(address payable newGovernor) internal {
        require(newGovernor != address(0));
        emit OwnershipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }

    uint256[50] private __gap;
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IRouter {
    function routeTo(
        address user,
        uint256 uAmount,
        bytes calldata data
    ) external;
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IRcaController {
    function mint(
        address user,
        uint256 uAmount,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 _newCumLiq,
        bytes32[] calldata cumLiqProof
    ) external;

    function redeemRequest(
        address user,
        uint256 _newCumLiq,
        bytes32[] calldata cumLiqProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external;

    function redeemFinalize(
        address user,
        address _to,
        uint256 _newCumLiq,
        bytes32[] calldata cumLiqProof,
        uint256 _newPercentReserved,
        bytes32[] calldata _percentReservedProof
    ) external returns (bool);

    function purchase(
        address user,
        address uToken,
        uint256 uEthPrice,
        bytes32[] calldata priceProof,
        uint256 _newCumLiq,
        bytes32[] calldata cumLiqProof
    ) external;

    function verifyLiq(
        address shield,
        uint256 _newCumLiq,
        bytes32[] memory cumLiqProof
    ) external view;

    function verifyPrice(
        address shield,
        uint256 _value,
        bytes32[] memory _proof
    ) external view;

    function apr() external view returns (uint256);

    function getAprUpdate() external view returns (uint32);

    function systemUpdates()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        );
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
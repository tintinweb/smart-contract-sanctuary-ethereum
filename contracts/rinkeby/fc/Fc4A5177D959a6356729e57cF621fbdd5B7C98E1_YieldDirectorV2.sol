// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20} from "../interfaces/IERC20.sol";
import {IsOHM} from "../interfaces/IsOHM.sol";
import {IStaking} from "../interfaces/IStaking.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";
import {YieldSplitter} from "../types/YieldSplitter.sol";
import {OlympusAccessControlled, IOlympusAuthority} from "../types/OlympusAccessControlled.sol";

/**
    @title  YieldDirectorV2 (codename Tyche) 
    @notice This contract allows donors to deposit their gOHM and donate their rebases
            to any address. Donors will be able to withdraw the sOHM equivalent of their principal
            gOHM at any time. Donation recipients can also redeem accrued rebases at any time.
    @dev    Any functions dealing with initial deposits will take an address (because no ID has been
            assigned). After a user has deposited, all functions dealing with deposits (like
            withdraw or redeem functions) will take the ID of the deposit. All functions that return
            aggregated data grouped by user will take an address (iterates across all relevant IDs).
 */
contract YieldDirectorV2 is YieldSplitter, OlympusAccessControlled {
    using SafeERC20 for IERC20;

    error YieldDirector_InvalidAddress();
    error YieldDirector_InvalidDeposit();
    error YieldDirector_InvalidUpdate();
    error YieldDirector_InvalidWithdrawal();
    error YieldDirector_NotYourDeposit();
    error YieldDirector_NoDeposits();
    error YieldDirector_NoRedeemableBalance();
    error YieldDirector_WithdrawalsDisabled();
    error YieldDirector_RedeemsDisabled();

    address public immutable sOHM;
    address public immutable gOHM;
    IStaking public immutable staking;

    mapping(address => uint256[]) public recipientIds; // address -> array of deposit id's donating yield to the user
    mapping(uint256 => address) public recipientLookup; // depositId -> recipient

    bool public depositDisabled;
    bool public withdrawDisabled;
    bool public redeemDisabled;

    event Deposited(address indexed donor_, address indexed recipient_, uint256 amount_);
    event Withdrawn(address indexed donor_, address indexed recipient_, uint256 amount_);
    event AllWithdrawn(address indexed donor_, uint256 indexed amount_);
    event Donated(address indexed donor_, address indexed recipient_, uint256 amount_);
    event Redeemed(address indexed recipient_, uint256 amount_);
    event EmergencyShutdown(bool active_);

    constructor(
        address sOhm_,
        address gOhm_,
        address staking_,
        address authority_
    ) OlympusAccessControlled(IOlympusAuthority(authority_)) YieldSplitter(sOhm_) {
        if (sOhm_ == address(0) || gOhm_ == address(0) || staking_ == address(0) || authority_ == address(0))
            revert YieldDirector_InvalidAddress();

        sOHM = sOhm_;
        gOHM = gOhm_;
        staking = IStaking(staking_);
    }

    /************************
     * Modifiers
     ************************/
    function isInvalidDeposit(uint256 amount_, address recipient_) internal view returns (bool) {
        return depositDisabled || amount_ <= 0 || recipient_ == address(0);
    }

    function isInvalidUpdate(uint256 depositId_, uint256 amount_) internal view returns (bool) {
        return depositDisabled || amount_ <= 0 || depositInfo[depositId_].depositor == address(0);
    }

    function isInvalidWithdrawal(uint256 amount_) internal view returns (bool) {
        return withdrawDisabled || amount_ <= 0;
    }

    /************************
     * Donor Functions
     ************************/

    /**
        @notice Deposit gOHM, records sender address and assign rebases to recipient
        @param amount_ Amount of gOHM debt issued from donor to recipient
        @param recipient_ Address to direct staking yield and vault shares to
    */
    function deposit(uint256 amount_, address recipient_) external returns (uint256 depositId) {
        if (isInvalidDeposit(amount_, recipient_)) revert YieldDirector_InvalidDeposit();

        IERC20(gOHM).safeTransferFrom(msg.sender, address(this), amount_);

        depositId = _createDeposit(amount_, recipient_);
    }

    /**
        @notice Deposit sOHM, wrap to gOHM, and records sender address and assign rebases to recipeint
        @param amount_ Amount of sOHM debt issued from donor to recipient
        @param recipient_ Address to direct staking yield and vault shares to
    */
    function depositSohm(uint256 amount_, address recipient_) external returns (uint256 depositId) {
        if (isInvalidDeposit(amount_, recipient_)) revert YieldDirector_InvalidDeposit();

        IERC20(sOHM).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20(sOHM).approve(address(staking), amount_);
        uint256 gohmAmount = staking.wrap(address(this), amount_);

        depositId = _createDeposit(gohmAmount, recipient_);
    }

    /**
        @notice Deposit additional gOHM, and update deposit record
        @param depositId_ Deposit ID to direct additional gOHM to
        @param amount_ Amount of new gOHM debt issued from donor to recipient
    */
    function addToDeposit(uint256 depositId_, uint256 amount_) external {
        if (isInvalidUpdate(depositId_, amount_)) revert YieldDirector_InvalidUpdate();
        if (depositInfo[depositId_].depositor != msg.sender) revert YieldDirector_NotYourDeposit();

        IERC20(gOHM).safeTransferFrom(msg.sender, address(this), amount_);

        _increaseDeposit(depositId_, amount_);
    }

    /**
        @notice Deposit additional sOHM, wrap to gOHM, and update deposit record
        @param depositId_ Deposit ID to direct additional gOHM to
        @param amount_ Amount of new sOHM debt issued from donor to recipient
    */
    function addToSohmDeposit(uint256 depositId_, uint256 amount_) external {
        if (isInvalidUpdate(depositId_, amount_)) revert YieldDirector_InvalidUpdate();
        if (depositInfo[depositId_].depositor != msg.sender) revert YieldDirector_NotYourDeposit();

        IERC20(sOHM).safeTransferFrom(msg.sender, address(this), amount_);
        IERC20(sOHM).approve(address(staking), amount_);
        uint256 gohmAmount = staking.wrap(address(this), amount_);

        _increaseDeposit(depositId_, gohmAmount);
    }

    /**
        @notice Withdraw donor's gOHM from vault
        @param depositId_ Deposit ID to remove gOHM deposit from
        @param amount_ Amount of gOHM deposit to remove and return to donor
    */
    function withdrawPrincipal(uint256 depositId_, uint256 amount_) external {
        uint256 amountWithdrawn = _withdraw(depositId_, amount_);

        IERC20(gOHM).safeTransfer(msg.sender, amountWithdrawn);
    }

    /**
        @notice Withdraw donor's gOHM from vault, and return it as sOHM
        @param depositId_ Deposit ID to remove gOHM debt from
        @param amount_ Amount of gOHM debt to remove and return to donor as sOHM
    */
    function withdrawPrincipalAsSohm(uint256 depositId_, uint256 amount_) external {
        uint256 amountWithdrawn = _withdraw(depositId_, amount_);

        IERC20(sOHM).approve(address(staking), amountWithdrawn);
        staking.unwrap(msg.sender, amountWithdrawn);
    }

    /**
        @notice Withdraw all gOHM from all donor positions
    */
    function withdrawAll() external {
        if (withdrawDisabled) revert YieldDirector_WithdrawalsDisabled();

        uint256[] memory depositIds = depositorIds[msg.sender];

        uint256 depositsLength = depositIds.length;
        if (depositsLength == 0) revert YieldDirector_NoDeposits();

        uint256 principalTotal = 0;

        for (uint256 index = 0; index < depositsLength; ++index) {
            DepositInfo storage currDeposit = depositInfo[depositIds[index]];

            principalTotal += currDeposit.principalAmount;

            _withdrawAllPrincipal(depositIds[index]);
        }

        IERC20(gOHM).safeTransfer(msg.sender, _toAgnostic(principalTotal));

        emit AllWithdrawn(msg.sender, _toAgnostic(principalTotal));
    }

    /**
        @notice Get deposited gOHM amounts for specific recipient (updated to current index
                based on sOHM equivalent amount deposit)
        @param donor_ Address of user donating yield
        @param recipient_ Address of user receiving donated yield
    */
    function depositsTo(address donor_, address recipient_) external view returns (uint256) {
        uint256[] storage depositIds = depositorIds[donor_];

        for (uint256 index = 0; index < depositIds.length; ++index) {
            uint256 id = depositIds[index];

            if (recipientLookup[id] == recipient_) {
                return _toAgnostic(depositInfo[id].principalAmount);
            }
        }

        return 0;
    }

    /**
        @notice Return total amount of donor's gOHM deposited (updated to current index based
                on sOHM equivalent amount deposited)
        @param donor_ Address of user donating yield
    */
    function totalDeposits(address donor_) external view returns (uint256) {
        uint256[] storage depositIds = depositorIds[donor_];
        uint256 principalTotal = 0;

        for (uint256 index = 0; index < depositIds.length; ++index) {
            principalTotal += depositInfo[depositIds[index]].principalAmount;
        }

        return _toAgnostic(principalTotal);
    }

    /**
        @notice Return arrays of donor's recipients and deposit amounts (gOHM value based on
                sOHM equivalent deposit), matched by index
        @param donor_ Address of user donating yield
    */
    function getAllDeposits(address donor_) external view returns (address[] memory, uint256[] memory) {
        uint256[] storage depositIds = depositorIds[donor_];

        uint256 len = depositIds.length == 0 ? 1 : depositIds.length;

        address[] memory addresses = new address[](len);
        uint256[] memory agnosticDeposits = new uint256[](len);

        if (depositIds.length == 0) {
            addresses[0] = address(0);
            agnosticDeposits[0] = 0;
        } else {
            for (uint256 index = 0; index < len; ++index) {
                addresses[index] = recipientLookup[depositIds[index]];
                agnosticDeposits[index] = _toAgnostic(depositInfo[depositIds[index]].principalAmount);
            }
        }

        return (addresses, agnosticDeposits);
    }

    /**
        @notice Return total amount of gOHM donated to recipient since last full redemption
        @param donor_ Address of user donating yield
        @param recipient_ Address of user recieiving donated yield
    */
    function donatedTo(address donor_, address recipient_) external view returns (uint256) {
        uint256[] storage depositIds = depositorIds[donor_];

        for (uint256 index = 0; index < depositIds.length; ++index) {
            if (recipientLookup[depositIds[index]] == recipient_) {
                return redeemableBalance(depositIds[index]);
            }
        }

        return 0;
    }

    /**
        @notice Return total amount of gOHM donated from donor since last full redemption
        @param donor_ Address of user donating yield
    */
    function totalDonated(address donor_) external view returns (uint256) {
        uint256[] storage depositIds = depositorIds[donor_];

        uint256 principalTotal = 0;
        uint256 agnosticTotal = 0;

        for (uint256 index = 0; index < depositIds.length; ++index) {
            DepositInfo storage currDeposit = depositInfo[depositIds[index]];

            principalTotal += currDeposit.principalAmount;
            agnosticTotal += currDeposit.agnosticAmount;
        }

        return _getOutstandingYield(principalTotal, agnosticTotal);
    }

    /************************
     * Recipient Functions
     ************************/

    /**
        @notice Get redeemable gOHM balance of a specific deposit
        @param depositId_ Deposit ID for this donation
    */
    function redeemableBalance(uint256 depositId_) public view returns (uint256) {
        DepositInfo storage currDeposit = depositInfo[depositId_];

        return _getOutstandingYield(currDeposit.principalAmount, currDeposit.agnosticAmount);
    }

    /**
        @notice Get redeemable gOHM balance of a recipient address
        @param recipient_ Address of user receiving donated yield
     */
    function totalRedeemableBalance(address recipient_) public view returns (uint256) {
        uint256[] storage receiptIds = recipientIds[recipient_];

        uint256 agnosticRedeemable = 0;

        for (uint256 index = 0; index < receiptIds.length; ++index) {
            agnosticRedeemable += redeemableBalance(receiptIds[index]);
        }

        return agnosticRedeemable;
    }

    /**
        @notice Redeem recipient's donated amount of sOHM at current index from one donor as gOHM
        @param depositId_ Deposit ID for this donation
    */
    function redeemYield(uint256 depositId_) external {
        uint256 amountRedeemed = _redeem(depositId_);

        IERC20(gOHM).safeTransfer(msg.sender, amountRedeemed);
    }

    /**
        @notice Redeem recipient's donated amount of sOHM at current index
        @param depositId_ Deposit id for this donation
    */
    function redeemYieldAsSohm(uint256 depositId_) external {
        uint256 amountRedeemed = _redeem(depositId_);

        IERC20(sOHM).approve(address(staking), amountRedeemed);
        staking.unwrap(msg.sender, amountRedeemed);
    }

    /**
        @notice Redeem recipient's full donated amount of sOHM at current index as gOHM
    */
    function redeemAllYield() external {
        uint256 amountRedeemed = _redeemAll();

        IERC20(gOHM).safeTransfer(msg.sender, amountRedeemed);
    }

    /**
        @notice Redeem recipient's full donated amount of sOHM at current index as gOHM
    */
    function redeemAllYieldAsSohm() external {
        uint256 amountRedeemed = _redeemAll();

        IERC20(sOHM).approve(address(staking), amountRedeemed);
        staking.unwrap(msg.sender, amountRedeemed);
    }

    /************************
     * Internal Functions
     ************************/

    /**
        @notice Creates a new deposit directing the yield from the deposited gOHM amount
                to the prescribed recipient
        @param amount_ Quantity of gOHM deposited redirecting yield to the recipient
        @param recipient_ The address of the user who will be entitled to claim the donated yield
    */
    function _createDeposit(uint256 amount_, address recipient_) internal returns (uint256 depositId) {
        depositId = _deposit(msg.sender, amount_);
        recipientIds[recipient_].push(depositId);
        recipientLookup[depositId] = recipient_;

        emit Deposited(msg.sender, recipient_, amount_);
    }

    /**
        @notice Increases the amount of gOHM directing yield to a recipient
        @param depositId_ The global ID number of the deposit to add the additional deposit to
        @param amount_ Quantity of new gOHM deposited redirecting yield to the current deposit's recipient
    */
    function _increaseDeposit(uint256 depositId_, uint256 amount_) internal {
        _addToDeposit(depositId_, amount_);

        emit Deposited(depositInfo[depositId_].depositor, recipientLookup[depositId_], amount_);
    }

    /**
        @notice Withdraw gOHM deposit from vault
        @param depositId_ Deposit ID to remove gOHM deposit from
        @param amount_ Amount of gOHM deposit to remove and return to donor 
    */
    function _withdraw(uint256 depositId_, uint256 amount_) internal returns (uint256 amountWithdrawn) {
        if (isInvalidWithdrawal(amount_)) revert YieldDirector_InvalidWithdrawal();

        if (amount_ >= _toAgnostic(depositInfo[depositId_].principalAmount)) {
            amountWithdrawn = _withdrawAllPrincipal(depositId_);
        } else {
            _withdrawPrincipal(depositId_, amount_);
            amountWithdrawn = amount_;
        }

        emit Withdrawn(msg.sender, recipientLookup[depositId_], amountWithdrawn);
    }

    /**
        @notice Redeem available gOHM yield from a specific deposit
        @param depositId_ Deposit ID to withdraw gOHM yield from
    */
    function _redeem(uint256 depositId_) internal returns (uint256 amountRedeemed) {
        if (redeemDisabled) revert YieldDirector_RedeemsDisabled();
        if (recipientLookup[depositId_] != msg.sender) revert YieldDirector_NotYourDeposit();

        amountRedeemed = _redeemYield(depositId_);
        if (amountRedeemed == 0) revert YieldDirector_NoRedeemableBalance();

        if (depositInfo[depositId_].principalAmount == 0) {
            _closeDeposit(depositId_);

            uint256[] storage receiptIds = recipientIds[msg.sender];
            for (uint256 i = 0; i < receiptIds.length; ++i) {
                if (receiptIds[i] == depositId_) {
                    // Remove id from depositor's ids array
                    receiptIds[i] = receiptIds[receiptIds.length - 1]; // Delete integer from array by swapping with last element and calling pop()
                    receiptIds.pop();
                    break;
                }
            }

            delete recipientLookup[depositId_];
        }

        emit Redeemed(msg.sender, amountRedeemed);
        emit Donated(depositInfo[depositId_].depositor, msg.sender, amountRedeemed);
    }

    /**
        @notice Redeem all available gOHM yield from the vault
    */
    function _redeemAll() internal returns (uint256 amountRedeemed) {
        if (redeemDisabled) revert YieldDirector_RedeemsDisabled();

        amountRedeemed = 0;

        // Have to read the IDs into memory because with each redemption
        // an ID is removed from the state array
        uint256[] memory receiptIds = recipientIds[msg.sender];

        for (uint256 index = 0; index < receiptIds.length; ++index) {
            uint256 currRedemption = _redeem(receiptIds[index]);
            amountRedeemed += currRedemption;

            emit Donated(depositInfo[receiptIds[index]].depositor, msg.sender, currRedemption);
        }

        emit Redeemed(msg.sender, amountRedeemed);
    }

    /************************
     * Emergency Functions
     ************************/

    function emergencyShutdown(bool active_) external onlyGovernor {
        depositDisabled = active_;
        withdrawDisabled = active_;
        redeemDisabled = active_;
        emit EmergencyShutdown(active_);
    }

    function disableDeposits(bool active_) external onlyGovernor {
        depositDisabled = active_;
    }

    function disableWithdrawals(bool active_) external onlyGovernor {
        withdrawDisabled = active_;
    }

    function disableRedeems(bool active_) external onlyGovernor {
        redeemDisabled = active_;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IsOHM is IERC20 {
    function rebase(uint256 ohmProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20} from "../interfaces/IERC20.sol";
import {IgOHM} from "../interfaces/IgOHM.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";

/**
    @title IOHMIndexWrapper
    @notice This interface is used to wrap cross-chain oracles to feed an index without needing IsOHM, 
    while also being able to use sOHM on mainnet.
 */
interface IOHMIndexWrapper {
    function index() external view returns (uint256 index);
}

/**
    @title YieldSplitter
    @notice Abstract contract that allows users to create deposits for their gOHM and have
            their yield claimable by the specified recipient party. This contract's functions
            are designed to be as generic as possible. This contract's responsibility is
            the accounting of the yield splitting. All other logic such as error handling,
            emergency controls, sending and recieving gOHM is up to the implementation of
            this abstract contract to handle.
 */
abstract contract YieldSplitter {
    using SafeERC20 for IERC20;

    error YieldSplitter_NotYourDeposit();

    IOHMIndexWrapper public immutable indexWrapper;

    struct DepositInfo {
        uint256 id;
        address depositor;
        uint256 principalAmount; // Total amount of sOhm deposited as principal, 9 decimals.
        uint256 agnosticAmount; // Total amount deposited priced in gOhm. 18 decimals.
    }

    uint256 public idCount;
    mapping(uint256 => DepositInfo) public depositInfo; // depositId -> DepositInfo
    mapping(address => uint256[]) public depositorIds; // address -> Array of the deposit id's deposited by user

    /**
        @notice Constructor
        @param indexWrapper_ Address of contract that will return the sOHM to gOHM index. 
                             On mainnet this will be sOHM but on other chains can be an oracle wrapper.
    */
    constructor(address indexWrapper_) {
        indexWrapper = IOHMIndexWrapper(indexWrapper_);
    }

    /**
        @notice Create a deposit.
        @param depositor_ Address of depositor
        @param amount_ Amount in gOhm. 18 decimals.
    */
    function _deposit(address depositor_, uint256 amount_) internal returns (uint256 depositId) {
        depositorIds[depositor_].push(idCount);

        depositInfo[idCount] = DepositInfo({
            id: idCount,
            depositor: depositor_,
            principalAmount: _fromAgnostic(amount_),
            agnosticAmount: amount_
        });

        depositId = idCount;
        idCount++;
    }

    /**
        @notice Add more gOhm to the depositor's principal deposit.
        @param id_ Id of the deposit.
        @param amount_ Amount of gOhm to add. 18 decimals.
    */
    function _addToDeposit(uint256 id_, uint256 amount_) internal {
        DepositInfo storage userDeposit = depositInfo[id_];
        userDeposit.principalAmount += _fromAgnostic(amount_);
        userDeposit.agnosticAmount += amount_;
    }

    /**
        @notice Withdraw part of the principal amount deposited.
        @param id_ Id of the deposit.
        @param amount_ Amount of gOHM to withdraw.
    */
    function _withdrawPrincipal(uint256 id_, uint256 amount_) internal {
        if (depositInfo[id_].depositor != msg.sender) revert YieldSplitter_NotYourDeposit();

        DepositInfo storage userDeposit = depositInfo[id_];
        userDeposit.principalAmount -= _fromAgnostic(amount_); // Reverts if amount > principal due to underflow
        userDeposit.agnosticAmount -= amount_;
    }

    /**
        @notice Withdraw all of the principal amount deposited.
        @param id_ Id of the deposit.
        @return amountWithdrawn : amount of gOHM withdrawn. 18 decimals.
    */
    function _withdrawAllPrincipal(uint256 id_) internal returns (uint256 amountWithdrawn) {
        if (depositInfo[id_].depositor != msg.sender) revert YieldSplitter_NotYourDeposit();

        DepositInfo storage userDeposit = depositInfo[id_];
        amountWithdrawn = _toAgnostic(userDeposit.principalAmount);
        userDeposit.principalAmount = 0;
        userDeposit.agnosticAmount -= amountWithdrawn;
    }

    /**
        @notice Redeem excess yield from your deposit in sOHM.
        @param id_ Id of the deposit.
        @return amountRedeemed : amount of yield redeemed in gOHM. 18 decimals.
    */
    function _redeemYield(uint256 id_) internal returns (uint256 amountRedeemed) {
        DepositInfo storage userDeposit = depositInfo[id_];

        amountRedeemed = _getOutstandingYield(userDeposit.principalAmount, userDeposit.agnosticAmount);
        userDeposit.agnosticAmount = _toAgnostic(userDeposit.principalAmount);
    }

    /**
        @notice Close a deposit. Remove all information in both the deposit info, depositorIds and recipientIds.
        @param id_ Id of the deposit.
        @dev Internally for accounting reasons principal amount is stored in 9 decimal OHM terms. 
        Since most implementations will work will gOHM, principal here is returned externally in 18 decimal gOHM terms.
        @return principal : amount of principal that was deleted. in gOHM. 18 decimals.
        @return agnosticAmount : total amount of gOHM deleted. Principal + Yield. 18 decimals.
    */
    function _closeDeposit(uint256 id_) internal returns (uint256 principal, uint256 agnosticAmount) {
        principal = _toAgnostic(depositInfo[id_].principalAmount);
        agnosticAmount = depositInfo[id_].agnosticAmount;

        uint256[] storage depositorIdsArray = depositorIds[depositInfo[id_].depositor];
        for (uint256 i = 0; i < depositorIdsArray.length; i++) {
            if (depositorIdsArray[i] == id_) {
                // Remove id from depositor's ids array
                depositorIdsArray[i] = depositorIdsArray[depositorIdsArray.length - 1]; // Delete integer from array by swapping with last element and calling pop()
                depositorIdsArray.pop();
                break;
            }
        }

        delete depositInfo[id_];
    }

    /**
        @notice Calculate outstanding yield redeemable based on principal and agnosticAmount.
        @return uint256 amount of yield in gOHM. 18 decimals.
     */
    function _getOutstandingYield(uint256 principal_, uint256 agnosticAmount_) internal view returns (uint256) {
        return agnosticAmount_ - _toAgnostic(principal_);
    }

    /**
        @notice Convert flat sOHM value to agnostic gOHM value at current index
        @dev Agnostic value earns rebases. Agnostic value is amount / rebase_index.
             1e18 is because sOHM has 9 decimals, gOHM has 18 and index has 9.
     */
    function _toAgnostic(uint256 amount_) internal view returns (uint256) {
        return (amount_ * 1e18) / (indexWrapper.index());
    }

    /**
        @notice Convert agnostic gOHM value at current index to flat sOHM value
        @dev Agnostic value earns rebases. sOHM amount is gOHMamount * rebase_index.
             1e18 is because sOHM has 9 decimals, gOHM has 18 and index has 9.
     */
    function _fromAgnostic(uint256 amount_) internal view returns (uint256) {
        return (amount_ * (indexWrapper.index())) / 1e18;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IgOHM is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}
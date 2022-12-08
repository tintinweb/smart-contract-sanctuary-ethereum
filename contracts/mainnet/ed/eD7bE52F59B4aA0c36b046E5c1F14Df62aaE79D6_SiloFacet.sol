/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./TokenSilo.sol";
import "../../ReentrancyGuard.sol";
import "../../../libraries/Token/LibTransfer.sol";
import "../../../libraries/Silo/LibSiloPermit.sol";

/*
 * @author Publius
 * @title SiloFacet handles depositing, withdrawing and claiming whitelisted Silo tokens.
 */
contract SiloFacet is TokenSilo {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;

    /*
     * Deposit
     */

    function deposit(
        address token,
        uint256 amount,
        LibTransfer.From mode
    ) external payable nonReentrant updateSilo {
        amount = LibTransfer.receiveToken(
            IERC20(token),
            amount,
            msg.sender,
            mode
        );
        _deposit(msg.sender, token, amount);
    }

    /*
     * Withdraw
     */

    function withdrawDeposit(
        address token,
        uint32 season,
        uint256 amount
    ) external payable updateSilo {
        _withdrawDeposit(msg.sender, token, season, amount);
    }

    function withdrawDeposits(
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external payable updateSilo {
        _withdrawDeposits(msg.sender, token, seasons, amounts);
    }

    /*
     * Claim
     */

    function claimWithdrawal(
        address token,
        uint32 season,
        LibTransfer.To mode
    ) external payable nonReentrant {
        uint256 amount = _claimWithdrawal(msg.sender, token, season);
        LibTransfer.sendToken(IERC20(token), amount, msg.sender, mode);
    }

    function claimWithdrawals(
        address token,
        uint32[] calldata seasons,
        LibTransfer.To mode
    ) external payable nonReentrant {
        uint256 amount = _claimWithdrawals(msg.sender, token, seasons);
        LibTransfer.sendToken(IERC20(token), amount, msg.sender, mode);
    }

    /*
     * Transfer
     */

    function transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) external payable nonReentrant returns (uint256 bdv) {
        if (sender != msg.sender) {
            _spendDepositAllowance(sender, msg.sender, token, amount);
        }
        _update(sender);
        // Need to update the recipient's Silo as well.
        _update(recipient);
        bdv = _transferDeposit(sender, recipient, token, season, amount);
    }

    function transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external payable nonReentrant returns (uint256[] memory bdvs) {
        require(amounts.length > 0, "Silo: amounts array is empty");
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Silo: amount in array is 0");
            if (sender != msg.sender) {
                _spendDepositAllowance(sender, msg.sender, token, amounts[i]);
            }
        }
       
        _update(sender);
        // Need to update the recipient's Silo as well.
        _update(recipient);
        bdvs = _transferDeposits(sender, recipient, token, seasons, amounts);
    }

    /*
     * Approval
     */

    function approveDeposit(
        address spender,
        address token,
        uint256 amount
    ) external payable nonReentrant {
        require(spender != address(0), "approve from the zero address");
        require(token != address(0), "approve to the zero address");
        _approveDeposit(msg.sender, spender, token, amount);
    }

    function increaseDepositAllowance(address spender, address token, uint256 addedValue) public virtual nonReentrant returns (bool) {
        _approveDeposit(msg.sender, spender, token, depositAllowance(msg.sender, spender, token).add(addedValue));
        return true;
    }

    function decreaseDepositAllowance(address spender, address token, uint256 subtractedValue) public virtual nonReentrant returns (bool) {
        uint256 currentAllowance = depositAllowance(msg.sender, spender, token);
        require(currentAllowance >= subtractedValue, "Silo: decreased allowance below zero");
        _approveDeposit(msg.sender, spender, token, currentAllowance.sub(subtractedValue));
        return true;
    }

    function permitDeposits(
        address owner,
        address spender,
        address[] calldata tokens,
        uint256[] calldata values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        LibSiloPermit.permits(owner, spender, tokens, values, deadline, v, r, s);
        for (uint256 i; i < tokens.length; ++i) {
            _approveDeposit(owner, spender, tokens[i], values[i]);
        }
    }

    function permitDeposit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        LibSiloPermit.permit(owner, spender, token, value, deadline, v, r, s);
        _approveDeposit(owner, spender, token, value);
    }

    function depositPermitNonces(address owner) public view virtual returns (uint256) {
        return LibSiloPermit.nonces(owner);
    }

     /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function depositPermitDomainSeparator() external view returns (bytes32) {
        return LibSiloPermit._domainSeparatorV4();
    }
    /*
     * Silo
     */

    function update(address account) external payable {
        _update(account);
    }

    function plant() external payable returns (uint256 beans) {
        return _plant(msg.sender);
    }

    function claimPlenty() external payable {
        _claimPlenty(msg.sender);
    }

    /*
     * Update Unripe Deposits
     */

    function enrootDeposits(
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external nonReentrant updateSilo {
        require(s.u[token].underlyingToken != address(0), "Silo: token not unripe");
        // First, remove Deposits because every deposit is in a different season, we need to get the total Stalk/Seeds, not just BDV
        AssetsRemoved memory ar = removeDeposits(msg.sender, token, seasons, amounts);

        // Get new BDV and calculate Seeds (Seeds are not Season dependent like Stalk)
        uint256 newBDV = LibTokenSilo.beanDenominatedValue(token, ar.tokensRemoved);
        uint256 newStalk;

        // Iterate through all seasons, redeposit the tokens with new BDV and summate new Stalk.
        for (uint256 i; i < seasons.length; ++i) {
            uint256 bdv = amounts[i].mul(newBDV).div(ar.tokensRemoved); // Cheaper than calling the BDV function multiple times.
            LibTokenSilo.addDeposit(
                msg.sender,
                token,
                seasons[i],
                amounts[i],
                bdv
            );
            newStalk = newStalk.add(
                bdv.mul(s.ss[token].stalk).add(
                    LibSilo.stalkReward(
                        bdv.mul(s.ss[token].seeds),
                        season() - seasons[i]
                    )
                )
            );
        }

        uint256 newSeeds = newBDV.mul(s.ss[token].seeds);

        // Add new Stalk
        LibSilo.depositSiloAssets(
            msg.sender,
            newSeeds.sub(ar.seedsRemoved),
            newStalk.sub(ar.stalkRemoved)
        );
    }

    function enrootDeposit(
        address token,
        uint32 _season,
        uint256 amount
    ) external nonReentrant updateSilo {
        require(s.u[token].underlyingToken != address(0), "Silo: token not unripe");
        // First, remove Deposit and Redeposit with new BDV
        uint256 ogBDV = LibTokenSilo.removeDeposit(
            msg.sender,
            token,
            _season,
            amount
        );
        emit RemoveDeposit(msg.sender, token, _season, amount); // Remove Deposit does not emit an event, while Add Deposit does.
        uint256 newBDV = LibTokenSilo.beanDenominatedValue(token, amount);
        LibTokenSilo.addDeposit(msg.sender, token, _season, amount, newBDV);

        // Calculate the different in BDV. Will fail if BDV is lower.
        uint256 deltaBDV = newBDV.sub(ogBDV);

        // Calculate the new Stalk/Seeds associated with BDV and increment Stalk/Seed balances
        uint256 deltaSeeds = deltaBDV.mul(s.ss[token].seeds);
        uint256 deltaStalk = deltaBDV.mul(s.ss[token].stalk).add(
            LibSilo.stalkReward(deltaSeeds, season() - _season)
        );
        LibSilo.depositSiloAssets(msg.sender, deltaSeeds, deltaStalk);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;
import "./AppStorage.sol";

/**
 * @author Beanstalk Farms
 * @title Variation of Oepn Zeppelins reentrant guard to include Silo Update
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
**/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;
    
    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./Silo.sol";

/**
 * @author Publius
 * @title Token Silo
 **/
contract TokenSilo is Silo {
    uint32 private constant ASSET_PADDING = 100;

    using SafeMath for uint256;
    using LibSafeMath32 for uint32;

    event AddDeposit(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount,
        uint256 bdv
    );
    event RemoveDeposits(
        address indexed account,
        address indexed token,
        uint32[] seasons,
        uint256[] amounts,
        uint256 amount
    );
    event RemoveDeposit(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );

    event AddWithdrawal(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );
    event RemoveWithdrawals(
        address indexed account,
        address indexed token,
        uint32[] seasons,
        uint256 amount
    );
    event RemoveWithdrawal(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );

    event DepositApproval(
        address indexed owner,
        address indexed spender,
        address token,
        uint256 amount
    );

    struct AssetsRemoved {
        uint256 tokensRemoved;
        uint256 stalkRemoved;
        uint256 seedsRemoved;
        uint256 bdvRemoved;
    }

    /**
     * Getters
     **/

    function getDeposit(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256, uint256) {
        return LibTokenSilo.tokenDeposit(account, token, season);
    }

    function getWithdrawal(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256) {
        return LibTokenSilo.tokenWithdrawal(account, token, season);
    }

    function getTotalDeposited(address token) external view returns (uint256) {
        return s.siloBalances[token].deposited;
    }

    function getTotalWithdrawn(address token) external view returns (uint256) {
        return s.siloBalances[token].withdrawn;
    }

    function tokenSettings(address token)
        external
        view
        returns (Storage.SiloSettings memory)
    {
        return s.ss[token];
    }

    function withdrawFreeze() public view returns (uint8) {
        return s.season.withdrawSeasons;
    }

    /**
     * Internal
     **/

    // Deposit

    function _deposit(
        address account,
        address token,
        uint256 amount
    ) internal {
        (uint256 seeds, uint256 stalk) = LibTokenSilo.deposit(
            account,
            token,
            _season(),
            amount
        );
        LibSilo.depositSiloAssets(account, seeds, stalk);
    }

    // Withdraw

    function _withdrawDeposits(
        address account,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) internal {
        require(
            seasons.length == amounts.length,
            "Silo: Crates, amounts are diff lengths."
        );
        AssetsRemoved memory ar = removeDeposits(
            account,
            token,
            seasons,
            amounts
        );
        _withdraw(
            account,
            token,
            ar.tokensRemoved,
            ar.stalkRemoved,
            ar.seedsRemoved
        );
    }

    function _withdrawDeposit(
        address account,
        address token,
        uint32 season,
        uint256 amount
    ) internal {
        (uint256 stalkRemoved, uint256 seedsRemoved, ) = removeDeposit(
            account,
            token,
            season,
            amount
        );
        _withdraw(account, token, amount, stalkRemoved, seedsRemoved);
    }

    function _withdraw(
        address account,
        address token,
        uint256 amount,
        uint256 stalk,
        uint256 seeds
    ) private {
        uint32 arrivalSeason = _season() + s.season.withdrawSeasons;
        addTokenWithdrawal(account, token, arrivalSeason, amount);
        LibTokenSilo.decrementDepositedToken(token, amount);
        LibSilo.withdrawSiloAssets(account, seeds, stalk);
    }

    function removeDeposit(
        address account,
        address token,
        uint32 season,
        uint256 amount
    )
        private
        returns (
            uint256 stalkRemoved,
            uint256 seedsRemoved,
            uint256 bdv
        )
    {
        bdv = LibTokenSilo.removeDeposit(account, token, season, amount);
        seedsRemoved = bdv.mul(s.ss[token].seeds);
        stalkRemoved = bdv.mul(s.ss[token].stalk).add(
            LibSilo.stalkReward(seedsRemoved, _season() - season)
        );
        emit RemoveDeposit(account, token, season, amount);
    }

    function removeDeposits(
        address account,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) internal returns (AssetsRemoved memory ar) {
        for (uint256 i; i < seasons.length; ++i) {
            uint256 crateBdv = LibTokenSilo.removeDeposit(
                account,
                token,
                seasons[i],
                amounts[i]
            );
            ar.bdvRemoved = ar.bdvRemoved.add(crateBdv);
            ar.tokensRemoved = ar.tokensRemoved.add(amounts[i]);
            ar.stalkRemoved = ar.stalkRemoved.add(
                LibSilo.stalkReward(
                    crateBdv.mul(s.ss[token].seeds),
                    _season() - seasons[i]
                )
            );
        }
        ar.seedsRemoved = ar.bdvRemoved.mul(s.ss[token].seeds);
        ar.stalkRemoved = ar.stalkRemoved.add(
            ar.bdvRemoved.mul(s.ss[token].stalk)
        );
        emit RemoveDeposits(account, token, seasons, amounts, ar.tokensRemoved);
    }

    function addTokenWithdrawal(
        address account,
        address token,
        uint32 arrivalSeason,
        uint256 amount
    ) private {
        s.a[account].withdrawals[token][arrivalSeason] = s
        .a[account]
        .withdrawals[token][arrivalSeason].add(amount);
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn.add(
            amount
        );
        emit AddWithdrawal(account, token, arrivalSeason, amount);
    }

        // Claim

    function _claimWithdrawal(
        address account,
        address token,
        uint32 season
    ) internal returns (uint256) {
        uint256 amount = _removeTokenWithdrawal(account, token, season);
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn.sub(
            amount
        );
        emit RemoveWithdrawal(msg.sender, token, season, amount);
        return amount;
    }

    function _claimWithdrawals(
        address account,
        address token,
        uint32[] calldata seasons
    ) internal returns (uint256 amount) {
        for (uint256 i; i < seasons.length; ++i) {
            amount = amount.add(
                _removeTokenWithdrawal(account, token, seasons[i])
            );
        }
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn.sub(
            amount
        );
        emit RemoveWithdrawals(msg.sender, token, seasons, amount);
        return amount;
    }

    function _removeTokenWithdrawal(
        address account,
        address token,
        uint32 season
    ) private returns (uint256) {
        require(
            season <= s.season.current,
            "Claim: Withdrawal not receivable"
        );
        uint256 amount = s.a[account].withdrawals[token][season];
        delete s.a[account].withdrawals[token][season];
        return amount;
    }

    // Transfer

    function _transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) internal returns (uint256) {
        (uint256 stalk, uint256 seeds, uint256 bdv) = removeDeposit(
            sender,
            token,
            season,
            amount
        );
        LibTokenSilo.addDeposit(recipient, token, season, amount, bdv);
        LibSilo.transferSiloAssets(sender, recipient, seeds, stalk);
        return bdv;
    }

    function _transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) internal returns (uint256[] memory) {
        require(
            seasons.length == amounts.length,
            "Silo: Crates, amounts are diff lengths."
        );
        AssetsRemoved memory ar;
        uint256[] memory bdvs = new uint256[](seasons.length);

        for (uint256 i; i < seasons.length; ++i) {
            uint256 crateBdv = LibTokenSilo.removeDeposit(
                sender,
                token,
                seasons[i],
                amounts[i]
            );
            LibTokenSilo.addDeposit(
                recipient,
                token,
                seasons[i],
                amounts[i],
                crateBdv
            );
            ar.bdvRemoved = ar.bdvRemoved.add(crateBdv);
            ar.tokensRemoved = ar.tokensRemoved.add(amounts[i]);
            ar.stalkRemoved = ar.stalkRemoved.add(
                LibSilo.stalkReward(
                    crateBdv.mul(s.ss[token].seeds),
                    _season() - seasons[i]
                )
            );
            bdvs[i] = crateBdv;
        }
        ar.seedsRemoved = ar.bdvRemoved.mul(s.ss[token].seeds);
        ar.stalkRemoved = ar.stalkRemoved.add(
            ar.bdvRemoved.mul(s.ss[token].stalk)
        );
        emit RemoveDeposits(sender, token, seasons, amounts, ar.tokensRemoved);
        LibSilo.transferSiloAssets(
            sender,
            recipient,
            ar.seedsRemoved,
            ar.stalkRemoved
        );
        return bdvs;
    }

    function _spendDepositAllowance(
        address owner,
        address spender,
        address token,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = depositAllowance(owner, spender, token);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Silo: insufficient allowance");
            _approveDeposit(owner, spender, token, currentAllowance - amount);
        }
    }
        
    function _approveDeposit(address account, address spender, address token, uint256 amount) internal {
        s.a[account].depositAllowances[spender][token] = amount;
        emit DepositApproval(account, spender, token, amount);
    }

    function depositAllowance(
        address account,
        address spender,
        address token
    ) public view virtual returns (uint256) {
        return s.a[account].depositAllowances[spender][token];
    }

    function _season() private view returns (uint32) {
        return s.season.current;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

/**
 * @author publius
 * @title LibTransfer handles the recieving and sending of Tokens to/from internal Balances.
 **/
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/IBean.sol";
import "./LibBalance.sol";

library LibTransfer {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum From {
        EXTERNAL,
        INTERNAL,
        EXTERNAL_INTERNAL,
        INTERNAL_TOLERANT
    }
    enum To {
        EXTERNAL,
        INTERNAL
    }

    function transferToken(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount,
        From fromMode,
        To toMode
    ) internal returns (uint256 transferredAmount) {
        if (fromMode == From.EXTERNAL && toMode == To.EXTERNAL) {
            uint256 beforeBalance = token.balanceOf(recipient);
            token.safeTransferFrom(sender, recipient, amount);
            return token.balanceOf(recipient).sub(beforeBalance);
        }
        amount = receiveToken(token, amount, sender, fromMode);
        sendToken(token, amount, recipient, toMode);
        return amount;
    }

    function receiveToken(
        IERC20 token,
        uint256 amount,
        address sender,
        From mode
    ) internal returns (uint256 receivedAmount) {
        if (amount == 0) return 0;
        if (mode != From.EXTERNAL) {
            receivedAmount = LibBalance.decreaseInternalBalance(
                sender,
                token,
                amount,
                mode != From.INTERNAL
            );
            if (amount == receivedAmount || mode == From.INTERNAL_TOLERANT)
                return receivedAmount;
        }
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount - receivedAmount);
        return receivedAmount.add(token.balanceOf(address(this)).sub(beforeBalance));
    }

    function sendToken(
        IERC20 token,
        uint256 amount,
        address recipient,
        To mode
    ) internal {
        if (amount == 0) return;
        if (mode == To.INTERNAL)
            LibBalance.increaseInternalBalance(recipient, token, amount);
        else token.safeTransfer(recipient, amount);
    }

    function burnToken(
        IBean token,
        uint256 amount,
        address sender,
        From mode
    ) internal returns (uint256 burnt) {
        // burnToken only can be called with Unripe Bean, Unripe Bean:3Crv or Bean token, which are all Beanstalk tokens.
        // Beanstalk's ERC-20 implementation uses OpenZeppelin's ERC20Burnable
        // which reverts if burnFrom function call cannot burn full amount.
        if (mode == From.EXTERNAL) {
            token.burnFrom(sender, amount);
            burnt = amount;
        } else {
            burnt = LibTransfer.receiveToken(token, amount, sender, mode);
            token.burn(burnt);
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib Silo Permit
 **/
library LibSiloPermit {

    bytes32 private constant DEPOSIT_PERMIT_HASHED_NAME = keccak256(bytes("SiloDeposit"));
    bytes32 private constant DEPOSIT_PERMIT_HASHED_VERSION = keccak256(bytes("1"));
    bytes32 private constant DEPOSIT_PERMIT_EIP712_TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant DEPOSIT_PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,address token,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant DEPOSITS_PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,address[] tokens,uint256[] values,uint256 nonce,uint256 deadline)");

    function permit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, "Silo: permit expired deadline");
        bytes32 structHash = keccak256(abi.encode(DEPOSIT_PERMIT_TYPEHASH, owner, spender, token, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "Silo: permit invalid signature");
    }

    function permits(
        address owner,
        address spender,
        address[] memory tokens,
        uint256[] memory values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, "Silo: permit expired deadline");
        bytes32 structHash = keccak256(abi.encode(DEPOSITS_PERMIT_TYPEHASH, owner, spender, keccak256(abi.encodePacked(tokens)), keccak256(abi.encodePacked(values)), _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "Silo: permit invalid signature");
    }

    function nonces(address owner) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.a[owner].depositPermitNonces;
    }

    function _useNonce(address owner) internal returns (uint256 current) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        current = s.a[owner].depositPermitNonces;
        ++s.a[owner].depositPermitNonces;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(DEPOSIT_PERMIT_EIP712_TYPE_HASH, DEPOSIT_PERMIT_HASHED_NAME, DEPOSIT_PERMIT_HASHED_VERSION);
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                C.getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Beanstalk.
**/

// The Account contract stores all of the Farmer specific storage data.
// Each unique Ethereum address is a Farmer.
// Account.State is the primary struct that is referenced in the greater Storage.State struct.
// All other structs in Account are stored in Account.State.
contract Account {

    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and formerly stored Withdrawals.
    // Asset Silo currently stores Unripe Bean and Unripe LP Deposits.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals; // DEPRECATED – Silo V1 Withdrawals are no longer referenced.
        mapping(uint32 => uint256) deposits; // Unripe Bean/LP Deposits (previously Bean/LP Deposits).
        mapping(uint32 => uint256) depositSeeds; // BDV of Unripe LP Deposits / 4 (previously # of Seeds in corresponding LP Deposit).
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount; // The amount of Tokens in the Deposit.
        uint128 bdv; // The Bean-denominated-value of the total amount of Tokens in the Deposit.
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        // uint256 base; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        // uint256 basePerRoot; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 plentyPerRoot; // The global Plenty Per Root index at the last time a Farmer updated their Silo. 
        uint256 plenty; // The balance of a Farmer's plenty. Plenty can be claimed directly for 3Crv.
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    // The global AppStorage state stores a mapping from account address to Account.State.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo bean; // A Farmer's Unripe Bean Deposits only as a result of Replant (previously held the V1 Silo Deposits/Withdrawals for Beans).
        AssetSilo lp;  // A Farmer's Unripe LP Deposits as a result of Replant of BEAN:ETH Uniswap v2 LP Tokens (previously held the V1 Silo Deposits/Withdrawals for BEAN:ETH Uniswap v2 LP Tokens).
        Silo s; // A Farmer's Silo storage.
        uint32 votedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to vote on BIPs.
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        uint32 lastSIs; // DEPRECATED – In Silo V1.2, the Silo reward mechanism was updated to no longer need to store the number of the Supply Increases at the time the Farmer last updated their Silo.
        uint32 proposedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to propose BIPs.
        SeasonOfPlenty deprecated; // DEPRECATED – Replant reset the Season of Plenty mechanism
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedBeans; // DEPRECATED – Replant generalized Internal Balances. Wrapped Beans are now stored at the AppStorage level.
        mapping(address => mapping(uint32 => Deposit)) deposits; // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals; // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
        mapping(address => mapping(address => uint256)) depositAllowances; // Spender => Silo Token
        mapping(address => mapping(IERC20 => uint256)) tokenAllowances; // Token allowances
        uint256 depositPermitNonces; // A Farmer's current deposit permit nonce
        uint256 tokenPermitNonces; // A Farmer's current token permit nonce
    }
}

// Storage stores the Global Beanstalk State.
// Storage.State stores the highest level State
// All Facets define Storage.State as the first and only state variable in the contract.
contract Storage {

    // DEPRECATED – After Replant, Beanstalk stores Token addresses as constants to save gas.
    // Contracts stored the contract addresses of various important contracts to Beanstalk.
    struct Contracts {
        address bean; // DEPRECATED – See above note
        address pair; // DEPRECATED – See above note
        address pegPair; // DEPRECATED – See above note
        address weth; // DEPRECATED – See above note
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Beans.
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Bip stores Bip related data.
    struct Bip {
        address proposer; // DEPRECATED – See above note
        uint32 start; // DEPRECATED – See above note
        uint32 period; // DEPRECATED – See above note
        bool executed; // DEPRECATED – See above note
        int pauseOrUnpause; // DEPRECATED – See above note
        uint128 timestamp; // DEPRECATED – See above note
        uint256 roots; // DEPRECATED – See above note
        uint256 endTotalRoots; // DEPRECATED – See above note
    }

    // DEPRECATED – Replant moved governance off-chain.
    // DiamondCut stores DiamondCut related data for each Bip.
    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Governance stores global Governance balances.
    struct Governance {
        uint32[] activeBips; // DEPRECATED – See above note
        uint32 bipIndex; // DEPRECATED – See above note
        mapping(uint32 => DiamondCut) diamondCuts; // DEPRECATED – See above note
        mapping(uint32 => mapping(address => bool)) voted; // DEPRECATED – See above note
        mapping(uint32 => Bip) bips; // DEPRECATED – See above note
    }

    // AssetSilo stores global Token level Silo balances.
    // In Storage.State there is a mapping from Token address to AssetSilo.
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    // Silo stores global level Silo balances.
    struct Silo {
        uint256 stalk; // The total amount of active Stalk (including Earned Stalk, excluding Grown Stalk).
        uint256 seeds; // The total amount of active Seeds (excluding Earned Seeds).
        uint256 roots; // Total amount of Roots.
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average delta b calculated from the Bean:3Crv pool.
    struct Oracle {
        bool initialized; // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint32 startSeason; // The Season the Oracle started minting. Used to ramp up delta b when oracle is first added.
        uint256[2] balances; // The cumulative reserve balances of the pool at the start of the Season (used for computing time weighted average delta b).
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    // Note: The `raining` storage variable is stored in the Season section for a gas efficient read operation.
    struct Rain {
        uint256 depreciated; // Ocupies a storage slot in place of a deprecated State variable.
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Beanstalk.
        uint32 lastSop; // The Season in which the most recent consecutive series of Seasons of Plenty started.
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint32 lastSopSeason; // The Season in which the most recent consecutive series of Seasons of Plenty ended.
        uint32 rainStart; // rainStart stores the most recent Season in which Rain started.
        bool raining; // True if it is Raining (P < 1, Pod Rate Excessively Low).
        bool fertilizing; // True if Beanstalk has Fertilizer left to be paid off.
        uint256 start; // The timestamp of the Beanstalk deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Beanstalk.
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint96 lastSoilPercent; // DEPRECATED: Was removed with Extreme Weather V2
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Beans in Soil.
        bool didSowBelowMin; // DEPRECATED: Was removed with Extreme Weather V2
        bool didSowFaster; // DEPRECATED: Was removed with Extreme Weather V2
    }

    // Fundraiser stores Fundraiser data for a given Fundraiser.
    struct Fundraiser {
        address payee; // The address to be paid after the Fundraiser has been fully funded.
        address token; // The token address that used to raise funds for the Fundraiser.
        uint256 total; // The total number of Tokens that need to be raised to complete the Fundraiser.
        uint256 remaining; // The remaining number of Tokens that need to to complete the Fundraiser.
        uint256 start; // The timestamp at which the Fundraiser started (Fundraisers cannot be started and funded in the same block).
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        // selector is an encoded function selector 
        // that pertains to an external view Beanstalk function 
        // with the following signature:
        // function tokenToBdv(uint256 amount) public view returns (uint256);
        // It is called by `LibTokenSilo` through the use of delegatecall
        // To calculate the BDV of a Deposit at the time of Deposit.
        bytes4 selector; // The encoded BDV function selector for the Token.
        uint32 seeds; // The Seeds Per BDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per BDV that the Silo mints in exchange for Depositing this Token.
    }

    // UnripeSettings stores the settings for an Unripe Token in Beanstalk.
    // An Unripe token is a vesting Token that is redeemable for a a pro rata share
    // of the balanceOfUnderlying subject to a penalty based on the percent of
    // Unfertilized Beans paid back.
    // There were two Unripe Tokens added at Replant: 
    // Unripe Bean with its underlying Token as Bean; and
    // Unripe LP with its underlying Token as Bean:3Crv LP.
    // Unripe Tokens are distirbuted through the use of a merkleRoot.
    // The existence of a non-zero UnripeSettings implies that a Token is an Unripe Token.
    struct UnripeSettings {
        address underlyingToken; // The address of the Token underlying the Unripe Token.
        uint256 balanceOfUnderlying; // The number of Tokens underlying the Unripe Tokens (redemption pool).
        bytes32 merkleRoot; // The Merkle Root used to validate a claim of Unripe Tokens.
    }
}

struct AppStorage {
    uint8 index; // DEPRECATED - Was the index of the Bean token in the Bean:Eth Uniswap v2 pool, which has been depreciated.
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Beanstalk is Paused.
    uint128 pausedAt; // The timestamp at which Beanstalk was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c; // DEPRECATED - Previously stored the Contracts State struct. Removed when contract addresses were moved to constants in C.sol.
    Storage.Field f; // The Field storage struct found above.
    Storage.Governance g; // The Governance storage struct found above.
    Storage.Oracle co; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance.
    Storage.Weather w; // The Weather storage struct found above.

    //////////////////////////////////

    uint256 earnedBeans; // The number of Beans distributed to the Silo that have not yet been Deposited as a result of the Earn function being called.
    uint256[14] depreciated; // DEPRECATED - 14 slots that used to store state variables which have been deprecated through various updates. Storage slots can be left alone or reused.
    mapping (address => Account.State) a; // A mapping from Farmer address to Account state.
    uint32 bip0Start; // DEPRECATED - bip0Start was used to aid in a migration that occured alongside BIP-0.
    uint32 hotFix3Start; // DEPRECATED - hotFix3Start was used to aid in a migration that occured alongside HOTFIX-3.
    mapping (uint32 => Storage.Fundraiser) fundraisers; // A mapping from Fundraiser Id to Fundraiser storage.
    uint32 fundraiserIndex; // The number of Fundraisers that have occured.
    mapping (address => bool) isBudget; // DEPRECATED - Budget Facet was removed in BIP-14. 
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss; // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    uint256[3] depreciated2; // DEPRECATED - 3 slots that used to store state variables which have been depreciated through various updates. Storage slots can be left alone or reused.

    // New Sops
    mapping (uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.

    // Internal Balances
    mapping(address => mapping(IERC20 => uint256)) internalTokenBalance; // A mapping from Farmer address to Token address to Internal Balance. It stores the amount of the Token that the Farmer has stored as an Internal Balance in Beanstalk.

    // Unripe
    mapping(address => mapping(address => bool)) unripeClaimed; // True if a Farmer has Claimed an Unripe Token. A mapping from Farmer to Unripe Token to its Claim status.
    mapping(address => Storage.UnripeSettings) u; // Unripe Settings for a given Token address. The existence of a non-zero Unripe Settings implies that the token is an Unripe Token. The mapping is from Token address to Unripe Settings.

    // Fertilizer
    mapping(uint128 => uint256) fertilizer; // A mapping from Fertilizer Id to the supply of Fertilizer for each Id.
    mapping(uint128 => uint128) nextFid; // A linked list of Fertilizer Ids ordered by Id number. Fertilizer Id is the Beans Per Fertilzer level at which the Fertilizer no longer receives Beans. Sort in order by which Fertilizer Id expires next.
    uint256 activeFertilizer; // The number of active Fertilizer.
    uint256 fertilizedIndex; // The total number of Fertilizer Beans.
    uint256 unfertilizedIndex; // The total number of Unfertilized Beans ever.
    uint128 fFirst; // The lowest active Fertilizer Id (start of linked list that is stored by nextFid). 
    uint128 fLast; // The highest active Fertilizer Id (end of linked list that is stored by nextFid). 
    uint128 bpf; // The cumulative Beans Per Fertilizer (bfp) minted over all Season.
    uint256 recapitalized; // The nubmer of USDC that has been recapitalized in the Barn Raise.
    uint256 isFarm; // Stores whether the function is wrapped in the `farm` function (1 if not, 2 if it is).
    address ownerCandidate; // Stores a candidate address to transfer ownership to. The owner must claim the ownership transfer.
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./SiloExit.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../libraries/Silo/LibTokenSilo.sol";

/**
 * @author Publius
 * @title Silo Entrance
 **/
contract Silo is SiloExit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Plant(
        address indexed account,
        uint256 beans
    );

    event ClaimPlenty(
        address indexed account,
        uint256 plenty
    );

    event SeedsBalanceChanged(
        address indexed account,
        int256 delta
    );

    event StalkBalanceChanged(
        address indexed account,
        int256 delta,
        int256 deltaRoots
    );

    /**
     * Internal
     **/

    function _update(address account) internal {
        uint32 _lastUpdate = lastUpdate(account);
        if (_lastUpdate >= season()) return;
        // Increment Plenty if a SOP has occured or save Rain Roots if its Raining.
        handleRainAndSops(account, _lastUpdate);
        // Earn Grown Stalk -> The Stalk gained from Seeds.
        earnGrownStalk(account);
        s.a[account].lastUpdate = season();
    }

    function _plant(address account) internal returns (uint256 beans) {
        // Need to update account before we make a Deposit
        _update(account);
        uint256 accountStalk = s.a[account].s.stalk;
        // Calculate balance of Earned Beans.
        beans = _balanceOfEarnedBeans(account, accountStalk);
        if (beans == 0) return 0;
        s.earnedBeans = s.earnedBeans.sub(beans);
        // Deposit Earned Beans
        LibTokenSilo.addDeposit(
            account,
            C.beanAddress(),
            season(),
            beans,
            beans
        );
        uint256 seeds = beans.mul(C.getSeedsPerBean());

        // Earned Seeds don't auto-compound, so we need to mint new Seeds
        LibSilo.incrementBalanceOfSeeds(account, seeds);

        // Earned Stalk auto-compounds and thus is minted alongside Earned Beans
        // Farmers don't receive additional Roots from Earned Stalk.
        uint256 stalk = beans.mul(C.getStalkPerBean());
        s.a[account].s.stalk = accountStalk.add(stalk);

        emit StalkBalanceChanged(account, int256(stalk), 0);
        emit Plant(account, beans);
    }

    function _claimPlenty(address account) internal {
        // Each Plenty is earned in the form of 3Crv.
        uint256 plenty = s.a[account].sop.plenty;
        C.threeCrv().safeTransfer(account, plenty);
        delete s.a[account].sop.plenty;

        emit ClaimPlenty(account, plenty);
    }

    function earnGrownStalk(address account) private {
        // If they have no seeds, we can save gas.
        if (s.a[account].s.seeds == 0) return;
        LibSilo.incrementBalanceOfStalk(account, balanceOfGrownStalk(account));
    }

    function handleRainAndSops(address account, uint32 _lastUpdate) private {
        // If no roots, reset Sop counters variables
        if (s.a[account].roots == 0) {
            s.a[account].lastSop = s.season.rainStart;
            s.a[account].lastRain = 0;
            return;
        }
        // If a Sop has occured since last update, calculate rewards and set last Sop.
        if (s.season.lastSopSeason > _lastUpdate) {
            s.a[account].sop.plenty = balanceOfPlenty(account);
            s.a[account].lastSop = s.season.lastSop;
        }
        if (s.season.raining) {
            // If rain started after update, set account variables to track rain.
            if (s.season.rainStart > _lastUpdate) {
                s.a[account].lastRain = s.season.rainStart;
                s.a[account].sop.roots = s.a[account].roots;
            }
            // If there has been a Sop since rain started,
            // save plentyPerRoot in case another SOP happens during rain.
            if (s.season.lastSop == s.season.rainStart)
                s.a[account].sop.plentyPerRoot = s.sops[s.season.lastSop];
        } else if (s.a[account].lastRain > 0) {
            // Reset Last Rain if not raining.
            s.a[account].lastRain = 0;
        }
    }

    modifier updateSilo() {
        _update(msg.sender);
        _;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../LibAppStorage.sol";
import "../../C.sol";
import "./LibUnripeSilo.sol";

/**
 * @author Publius
 * @title Lib Token Silo
 **/
library LibTokenSilo {
    using SafeMath for uint256;

    event AddDeposit(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount,
        uint256 bdv
    );

    /*
     * Deposit
     */

    function deposit(
        address account,
        address token,
        uint32 _s,
        uint256 amount
    ) internal returns (uint256, uint256) {
        uint256 bdv = beanDenominatedValue(token, amount);
        return depositWithBDV(account, token, _s, amount, bdv);
    }

    function depositWithBDV(
        address account,
        address token,
        uint32 _s,
        uint256 amount,
        uint256 bdv
    ) internal returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bdv > 0, "Silo: No Beans under Token.");
        incrementDepositedToken(token, amount);
        addDeposit(account, token, _s, amount, bdv);
        return (bdv.mul(s.ss[token].seeds), bdv.mul(s.ss[token].stalk));
    }

    function incrementDepositedToken(address token, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.siloBalances[token].deposited = s.siloBalances[token].deposited.add(
            amount
        );
    }

    function addDeposit(
        address account,
        address token,
        uint32 _s,
        uint256 amount,
        uint256 bdv
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].deposits[token][_s].amount += uint128(amount);
        s.a[account].deposits[token][_s].bdv += uint128(bdv);
        emit AddDeposit(account, token, _s, amount, bdv);
    }

    function decrementDepositedToken(address token, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.siloBalances[token].deposited = s.siloBalances[token].deposited.sub(
            amount
        );
    }

    /*
     * Remove
     */

    function removeDeposit(
        address account,
        address token,
        uint32 id,
        uint256 amount
    ) internal returns (uint256 crateBDV) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 crateAmount;
        (crateAmount, crateBDV) = (
            s.a[account].deposits[token][id].amount,
            s.a[account].deposits[token][id].bdv
        );
        if (amount < crateAmount) {
            uint256 base = amount.mul(crateBDV).div(crateAmount);
            uint256 newBase = uint256(s.a[account].deposits[token][id].bdv).sub(
                base
            );
            uint256 newAmount = uint256(s.a[account].deposits[token][id].amount)
                .sub(amount);
            require(
                newBase <= uint128(-1) && newAmount <= uint128(-1),
                "Silo: uint128 overflow."
            );
            s.a[account].deposits[token][id].amount = uint128(newAmount);
            s.a[account].deposits[token][id].bdv = uint128(newBase);
            return base;
        }

        if (crateAmount > 0) delete s.a[account].deposits[token][id];

        if (amount > crateAmount) {
            amount -= crateAmount;
            if (LibUnripeSilo.isUnripeBean(token))
                return
                    crateBDV.add(
                        LibUnripeSilo.removeUnripeBeanDeposit(
                            account,
                            id,
                            amount
                        )
                    );
            else if (LibUnripeSilo.isUnripeLP(token))
                return
                    crateBDV.add(
                        LibUnripeSilo.removeUnripeLPDeposit(account, id, amount)
                    );
            revert("Silo: Crate balance too low.");
        }
    }

    /*
     * Getters
     */

    function tokenDeposit(
        address account,
        address token,
        uint32 id
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (LibUnripeSilo.isUnripeBean(token))
            return LibUnripeSilo.unripeBeanDeposit(account, id);
        if (LibUnripeSilo.isUnripeLP(token))
            return LibUnripeSilo.unripeLPDeposit(account, id);
        return (
            s.a[account].deposits[token][id].amount,
            s.a[account].deposits[token][id].bdv
        );
    }

    function beanDenominatedValue(address token, uint256 amount)
        internal
        returns (uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes memory myFunctionCall = abi.encodeWithSelector(
            s.ss[token].selector,
            amount
        );
        (bool success, bytes memory data) = address(this).call(
            myFunctionCall
        );
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
        assembly {
            bdv := mload(add(data, add(0x20, 0)))
        }
    }

    function tokenWithdrawal(
        address account,
        address token,
        uint32 id
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.a[account].withdrawals[token][id];
    }

    function seeds(address token) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return uint256(s.ss[token].seeds);
    }

    function stalk(address token) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return uint256(s.ss[token].stalk);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib Silo
 **/
library LibSilo {
    using SafeMath for uint256;

    event SeedsBalanceChanged(
        address indexed account,
        int256 delta
    );

    event StalkBalanceChanged(
        address indexed account,
        int256 delta,
        int256 deltaRoots
    );

    /**
     * Silo
     **/

    function depositSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        incrementBalanceOfStalk(account, stalk);
        incrementBalanceOfSeeds(account, seeds);
    }

    function withdrawSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        decrementBalanceOfStalk(account, stalk);
        decrementBalanceOfSeeds(account, seeds);
    }

    function transferSiloAssets(
        address sender,
        address recipient,
        uint256 seeds,
        uint256 stalk
    ) internal {
        transferStalk(sender, recipient, stalk);
        transferSeeds(sender, recipient, seeds);
    }

    function incrementBalanceOfSeeds(address account, uint256 seeds) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds.add(seeds);
        s.a[account].s.seeds = s.a[account].s.seeds.add(seeds);
        emit SeedsBalanceChanged(account, int256(seeds));
    }

    function incrementBalanceOfStalk(address account, uint256 stalk) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 roots;
        if (s.s.roots == 0) roots = stalk.mul(C.getRootsBase());
        else roots = s.s.roots.mul(stalk).div(s.s.stalk);

        s.s.stalk = s.s.stalk.add(stalk);
        s.a[account].s.stalk = s.a[account].s.stalk.add(stalk);

        s.s.roots = s.s.roots.add(roots);
        s.a[account].roots = s.a[account].roots.add(roots);
        emit StalkBalanceChanged(account, int256(stalk), int256(roots));
    }

    function decrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds.sub(seeds);
        s.a[account].s.seeds = s.a[account].s.seeds.sub(seeds);
        emit SeedsBalanceChanged(account, -int256(seeds));
    }

    function decrementBalanceOfStalk(address account, uint256 stalk) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (stalk == 0) return;

        uint256 roots = s.s.roots.mul(stalk).div(s.s.stalk);
        if (roots > s.a[account].roots) roots = s.a[account].roots;

        s.s.stalk = s.s.stalk.sub(stalk);
        s.a[account].s.stalk = s.a[account].s.stalk.sub(stalk);

        s.s.roots = s.s.roots.sub(roots);
        s.a[account].roots = s.a[account].roots.sub(roots);
        
        if (s.season.raining) {
            s.r.roots = s.r.roots.sub(roots);
            s.a[account].sop.roots = s.a[account].roots;
        }

        emit StalkBalanceChanged(account, -int256(stalk), -int256(roots));
    }

    function transferSeeds(
        address sender,
        address recipient,
        uint256 seeds
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[sender].s.seeds = s.a[sender].s.seeds.sub(seeds);
        emit SeedsBalanceChanged(sender, -int256(seeds));

        s.a[recipient].s.seeds = s.a[recipient].s.seeds.add(seeds);
        emit SeedsBalanceChanged(recipient, int256(seeds));
    }

    function transferStalk(
        address sender,
        address recipient,
        uint256 stalk
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 roots = stalk == s.a[sender].s.stalk
            ? s.a[sender].roots
            : s.s.roots.sub(1).mul(stalk).div(s.s.stalk).add(1);

        s.a[sender].s.stalk = s.a[sender].s.stalk.sub(stalk);
        s.a[sender].roots = s.a[sender].roots.sub(roots);
        emit StalkBalanceChanged(sender, -int256(stalk), -int256(roots));

        s.a[recipient].s.stalk = s.a[recipient].s.stalk.add(stalk);
        s.a[recipient].roots = s.a[recipient].roots.add(roots);
        emit StalkBalanceChanged(recipient, int256(stalk), int256(roots));
    }

    function stalkReward(uint256 seeds, uint32 seasons)
        internal
        pure
        returns (uint256)
    {
        return seeds.mul(seasons);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../ReentrancyGuard.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../libraries/LibSafeMath32.sol";
import "../../../C.sol";

/**
 * @author Publius
 * @title Silo Exit
 **/
contract SiloExit is ReentrancyGuard {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;

    struct AccountSeasonOfPlenty {
        uint32 lastRain;
        uint32 lastSop;
        uint256 roots;
        uint256 plentyPerRoot;
        uint256 plenty;
    }

    /**
     * Silo
     **/

    function totalStalk() public view returns (uint256) {
        return s.s.stalk;
    }

    function totalRoots() public view returns (uint256) {
        return s.s.roots;
    }

    function totalSeeds() public view returns (uint256) {
        return s.s.seeds;
    }

    function totalEarnedBeans() public view returns (uint256) {
        return s.earnedBeans;
    }

    function balanceOfSeeds(address account) public view returns (uint256) {
        return s.a[account].s.seeds; // Earned Seeds do not earn Grown stalk, so we do not include them.
    }

    function balanceOfStalk(address account) public view returns (uint256) {
        return s.a[account].s.stalk.add(balanceOfEarnedStalk(account)); // Earned Stalk earns Bean Mints, but Grown Stalk does not.
    }

    function balanceOfRoots(address account) public view returns (uint256) {
        return s.a[account].roots;
    }

    function balanceOfGrownStalk(address account)
        public
        view
        returns (uint256)
    {
        return
            LibSilo.stalkReward(
                s.a[account].s.seeds,
                season() - lastUpdate(account)
            );
    }

    function balanceOfEarnedBeans(address account)
        public
        view
        returns (uint256 beans)
    {
        beans = _balanceOfEarnedBeans(account, s.a[account].s.stalk);
    }

    function _balanceOfEarnedBeans(address account, uint256 accountStalk)
        internal
        view
        returns (uint256 beans)
    {
        // There will be no Roots when the first deposit is made.
        if (s.s.roots == 0) return 0;

        // Determine expected user Stalk based on Roots balance
        // userStalk / totalStalk = userRoots / totalRoots
        uint256 stalk = s.s.stalk.mul(s.a[account].roots).div(s.s.roots);

        // Handle edge case caused by rounding
        if (stalk <= accountStalk) return 0;

        // Calculate Earned Stalk and convert to Earned Beans.
        beans = (stalk - accountStalk).div(C.getStalkPerBean()); // Note: SafeMath is redundant here.
        if (beans > s.earnedBeans) return s.earnedBeans;
        return beans;
    }

    function balanceOfEarnedStalk(address account)
        public
        view
        returns (uint256)
    {
        return balanceOfEarnedBeans(account).mul(C.getStalkPerBean());
    }

    function balanceOfEarnedSeeds(address account)
        public
        view
        returns (uint256)
    {
        return balanceOfEarnedBeans(account).mul(C.getSeedsPerBean());
    }

    function lastUpdate(address account) public view returns (uint32) {
        return s.a[account].lastUpdate;
    }

    /**
     * Season Of Plenty
     **/

    function lastSeasonOfPlenty() public view returns (uint32) {
        return s.season.lastSop;
    }

    function balanceOfPlenty(address account)
        public
        view
        returns (uint256 plenty)
    {
        Account.State storage a = s.a[account];
        plenty = a.sop.plenty;
        uint256 previousPPR;
        // If lastRain > 0, check if SOP occured during the rain period.
        if (s.a[account].lastRain > 0) {
            // if the last processed SOP = the lastRain processed season,
            // then we use the stored roots to get the delta.
            if (a.lastSop == a.lastRain) previousPPR = a.sop.plentyPerRoot;
            else previousPPR = s.sops[a.lastSop];
            uint256 lastRainPPR = s.sops[s.a[account].lastRain];

            // If there has been a SOP duing this rain sesssion since last update, process spo.
            if (lastRainPPR > previousPPR) {
                uint256 plentyPerRoot = lastRainPPR - previousPPR;
                previousPPR = lastRainPPR;
                plenty = plenty.add(
                    plentyPerRoot.mul(s.a[account].sop.roots).div(
                        C.getSopPrecision()
                    )
                );
            }
        } else {
            // If it was not raining, just use the PPR at previous sop
            previousPPR = s.sops[s.a[account].lastSop];
        }

        // Handle and SOPs that started + ended before after last Rain where t
        if (s.season.lastSop > lastUpdate(account)) {
            uint256 plentyPerRoot = s.sops[s.season.lastSop].sub(previousPPR);
            plenty = plenty.add(
                plentyPerRoot.mul(balanceOfRoots(account)).div(
                    C.getSopPrecision()
                )
            );
        }
    }

    function balanceOfRainRoots(address account) public view returns (uint256) {
        return s.a[account].sop.roots;
    }

    function balanceOfSop(address account)
        external
        view
        returns (AccountSeasonOfPlenty memory sop)
    {
        sop.lastRain = s.a[account].lastRain;
        sop.lastSop = s.a[account].lastSop;
        sop.roots = s.a[account].sop.roots;
        sop.plenty = balanceOfPlenty(account);
        sop.plentyPerRoot = s.a[account].sop.plentyPerRoot;
    }

    /**
     * Internal
     **/

    function season() internal view returns (uint32) {
        return s.season.current;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Beanstalk's state.
**/
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IBean.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IFertilizer.sol";
import "./interfaces/IProxyAdmin.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Beanstalk.
**/
library C {

    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    // Chain
    uint256 private constant CHAIN_ID = 1; // Mainnet

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e6; // 100 beans
    uint256 private constant SOP_PRECISION = 1e24;

    // Sun
    uint256 private constant FERTILIZER_DENOMINATOR = 3;
    uint256 private constant HARVEST_DENOMINATOR = 2;
    uint256 private constant SOIL_COEFFICIENT_HIGH = 0.5e18;
    uint256 private constant SOIL_COEFFICIENT_LOW = 1.5e18;

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%
    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    // Silo
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;


    // Exploit
    uint256 private constant UNRIPE_LP_PER_DOLLAR = 1884592; // 145_113_507_403_282 / 77_000_000
    uint256 private constant ADD_LP_RATIO = 866616;
    uint256 private constant INITIAL_HAIRCUT = 185564685220298701; // SET

    // Contracts
    address private constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address private constant CURVE_BEAN_METAPOOL = 0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49;
    address private constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant UNRIPE_BEAN = 0x1BEA0050E63e05FBb5D8BA2f10cf5800B6224449;
    address private constant UNRIPE_LP = 0x1BEA3CcD22F4EBd3d37d731BA31Eeca95713716D;
    address private constant FERTILIZER = 0x402c84De2Ce49aF88f5e2eF3710ff89bFED36cB6;
    address private constant FERTILIZER_ADMIN = 0xfECB01359263C12Aa9eD838F878A596F0064aa6e;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address private constant TRI_CRYPTO = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    address private constant TRI_CRYPTO_POOL = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant CURVE_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    address private constant UNRIPE_CURVE_BEAN_LUSD_POOL = 0xD652c40fBb3f06d6B58Cb9aa9CFF063eE63d465D;
    address private constant UNRIPE_CURVE_BEAN_METAPOOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;

    /**
     * Getters
    **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getFertilizerDenominator() internal pure returns (uint256) {
        return FERTILIZER_DENOMINATOR;
    }

    function getHarvestDenominator() internal pure returns (uint256) {
        return HARVEST_DENOMINATOR;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
      return STALK_PER_BEAN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getSopPrecision() internal pure returns (uint256) {
        return SOP_PRECISION;
    }

    function beanAddress() internal pure returns (address) {
        return BEAN;
    }

    function curveMetapoolAddress() internal pure returns (address) {
        return CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool1() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool2() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_LUSD_POOL;
    }

    function unripeBeanAddress() internal pure returns (address) {
        return UNRIPE_BEAN;
    }

    function unripeLPAddress() internal pure returns (address) {
        return UNRIPE_LP;
    }

    function unripeBean() internal pure returns (IERC20) {
        return IERC20(UNRIPE_BEAN);
    }

    function unripeLP() internal pure returns (IERC20) {
        return IERC20(UNRIPE_LP);
    }

    function bean() internal pure returns (IBean) {
        return IBean(BEAN);
    }

    function usdc() internal pure returns (IERC20) {
        return IERC20(USDC);
    }

    function curveMetapool() internal pure returns (ICurvePool) {
        return ICurvePool(CURVE_BEAN_METAPOOL);
    }

    function curve3Pool() internal pure returns (I3Curve) {
        return I3Curve(CURVE_3_POOL);
    }
    
    function curveZap() internal pure returns (ICurveZap) {
        return ICurveZap(CURVE_ZAP);
    }

    function curveZapAddress() internal pure returns (address) {
        return CURVE_ZAP;
    }

    function curve3PoolAddress() internal pure returns (address) {
        return CURVE_3_POOL;
    }

    function threeCrv() internal pure returns (IERC20) {
        return IERC20(THREE_CRV);
    }

    function fertilizer() internal pure returns (IFertilizer) {
        return IFertilizer(FERTILIZER);
    }

    function fertilizerAddress() internal pure returns (address) {
        return FERTILIZER;
    }

    function fertilizerAdmin() internal pure returns (IProxyAdmin) {
        return IProxyAdmin(FERTILIZER_ADMIN);
    }

    function triCryptoPoolAddress() internal pure returns (address) {
        return TRI_CRYPTO_POOL;
    }

    function triCrypto() internal pure returns (IERC20) {
        return IERC20(TRI_CRYPTO);
    }

    function unripeLPPerDollar() internal pure returns (uint256) {
        return UNRIPE_LP_PER_DOLLAR;
    }

    function dollarPerUnripeLP() internal pure returns (uint256) {
        return 1e12/UNRIPE_LP_PER_DOLLAR;
    }

    function exploitAddLPRatio() internal pure returns (uint256) {
        return ADD_LP_RATIO;
    }

    function precision() internal pure returns (uint256) {
        return PRECISION;
    }

    function initialRecap() internal pure returns (uint256) {
        return INITIAL_HAIRCUT;
    }

    function soilCoefficientHigh() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_HIGH;
    }

    function soilCoefficientLow() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_LOW;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../LibAppStorage.sol";
import "../LibSafeMath128.sol";
import "../../C.sol";

/**
 * @author Publius
 * @title Lib Unripe Silo
 **/
library LibUnripeSilo {
    using SafeMath for uint256;
    using LibSafeMath128 for uint128;

    uint256 private constant AMOUNT_TO_BDV_BEAN_ETH = 119894802186829;
    uint256 private constant AMOUNT_TO_BDV_BEAN_3CRV = 992035;
    uint256 private constant AMOUNT_TO_BDV_BEAN_LUSD = 983108;

    function removeUnripeBeanDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) internal returns (uint256 bdv) {
        _removeUnripeBeanDeposit(account, id, amount);
        bdv = amount.mul(C.initialRecap()).div(1e18);
    }

    function _removeUnripeBeanDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].bean.deposits[id] = s.a[account].bean.deposits[id].sub(
            amount,
            "Silo: Crate balance too low."
        );
    }

    function isUnripeBean(address token) internal pure returns (bool b) {
        b = token == C.unripeBeanAddress();
    }

    function unripeBeanDeposit(address account, uint32 season)
        internal
        view
        returns (uint256 amount, uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 legacyAmount = s.a[account].bean.deposits[season];
        amount = uint256(
            s.a[account].deposits[C.unripeBeanAddress()][season].amount
        ).add(legacyAmount);
        bdv = uint256(s.a[account].deposits[C.unripeBeanAddress()][season].bdv)
            .add(legacyAmount.mul(C.initialRecap()).div(1e18));
    }

    function removeUnripeLPDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) internal returns (uint256 bdv) {
        bdv = _removeUnripeLPDeposit(account, id, amount);
        bdv = bdv.mul(C.initialRecap()).div(1e18);
    }

    function _removeUnripeLPDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) private returns (uint256 bdv) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (uint256 amount1, uint256 bdv1) = getBeanEthUnripeLP(account, id);
        if (amount1 >= amount) {
            uint256 removed = amount.mul(s.a[account].lp.deposits[id]).div(
                amount1
            );
            s.a[account].lp.deposits[id] = s.a[account].lp.deposits[id].sub(
                removed
            );
            removed = amount.mul(bdv1).div(amount1);
            s.a[account].lp.depositSeeds[id] = s
                .a[account]
                .lp
                .depositSeeds[id]
                .sub(removed.mul(4));
            return removed;
        }
        amount -= amount1;
        bdv = bdv1;
        delete s.a[account].lp.depositSeeds[id];
        delete s.a[account].lp.deposits[id];

        (amount1, bdv1) = getBean3CrvUnripeLP(account, id);
        if (amount1 >= amount) {
            Account.Deposit storage d = s.a[account].deposits[
                C.unripeLPPool1()
            ][id];
            uint128 removed = uint128(amount.mul(d.amount).div(amount1));
            s.a[account].deposits[C.unripeLPPool1()][id].amount = d.amount.sub(
                removed
            );
            removed = uint128(amount.mul(d.bdv).div(amount1));
            s.a[account].deposits[C.unripeLPPool1()][id].bdv = d.bdv.sub(
                removed
            );
            return bdv.add(removed);
        }
        amount -= amount1;
        bdv = bdv.add(bdv1);
        delete s.a[account].deposits[C.unripeLPPool1()][id];

        (amount1, bdv1) = getBeanLusdUnripeLP(account, id);
        if (amount1 >= amount) {
            Account.Deposit storage d = s.a[account].deposits[
                C.unripeLPPool2()
            ][id];
            uint128 removed = uint128(amount.mul(d.amount).div(amount1));
            s.a[account].deposits[C.unripeLPPool2()][id].amount = d.amount.sub(
                removed
            );
            removed = uint128(amount.mul(d.bdv).div(amount1));
            s.a[account].deposits[C.unripeLPPool2()][id].bdv = d.bdv.sub(
                removed
            );
            return bdv.add(removed);
        }
        revert("Silo: Crate balance too low.");
    }

    function isUnripeLP(address token) internal pure returns (bool b) {
        b = token == C.unripeLPAddress();
    }

    function unripeLPDeposit(address account, uint32 season)
        internal
        view
        returns (uint256 amount, uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (amount, bdv) = getBeanEthUnripeLP(account, season);
        (uint256 amount1, uint256 bdv1) = getBean3CrvUnripeLP(account, season);
        (uint256 amount2, uint256 bdv2) = getBeanLusdUnripeLP(account, season);

        amount = uint256(
            s.a[account].deposits[C.unripeLPAddress()][season].amount
        ).add(amount.add(amount1).add(amount2));

        uint256 legBdv = bdv.add(bdv1).add(bdv2).mul(C.initialRecap()).div(
            C.precision()
        );
        bdv = uint256(s.a[account].deposits[C.unripeLPAddress()][season].bdv)
            .add(legBdv);
    }

    function getBeanEthUnripeLP(address account, uint32 season)
        private
        view
        returns (uint256 amount, uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bdv = s.a[account].lp.depositSeeds[season].div(4);
        amount = s
            .a[account]
            .lp
            .deposits[season]
            .mul(AMOUNT_TO_BDV_BEAN_ETH)
            .div(1e18);
    }

    function getBeanLusdUnripeLP(address account, uint32 season)
        private
        view
        returns (uint256 amount, uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bdv = uint256(s.a[account].deposits[C.unripeLPPool2()][season].bdv);
        amount = uint256(
            s.a[account].deposits[C.unripeLPPool2()][season].amount
        ).mul(AMOUNT_TO_BDV_BEAN_LUSD).div(C.precision());
    }

    function getBean3CrvUnripeLP(address account, uint32 season)
        private
        view
        returns (uint256 amount, uint256 bdv)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bdv = uint256(s.a[account].deposits[C.unripeLPPool1()][season].bdv);
        amount = uint256(
            s.a[account].deposits[C.unripeLPPool1()][season].amount
        ).mul(AMOUNT_TO_BDV_BEAN_3CRV).div(C.precision());
    }
}

/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @author Publius
 * @title Bean Interface
**/
abstract contract IBean is IERC20 {

    function burn(uint256 amount) public virtual;
    function burnFrom(address account, uint256 amount) public virtual;
    function mint(address account, uint256 amount) public virtual;

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface ICurvePool {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    function totalSupply() external view returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external returns (uint256);
    function balances(int128 i) external view returns (uint256);
    function fee() external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICurveZap {
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
    function calc_token_amount(address _pool, uint256[4] memory _amounts, bool _is_deposit) external returns (uint256);
}

interface ICurvePoolR {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount, address receiver) external returns (uint256);
}

interface ICurvePool2R {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address reciever) external returns (uint256[2] calldata);
    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool3R {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts, address reciever) external returns (uint256[3] calldata);
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool4R {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[4] memory _min_amounts, address reciever) external returns (uint256[4] calldata);
    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface I3Curve {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFactory {
    function get_coins(address _pool) external view returns (address[4] calldata);
    function get_underlying_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurveCryptoFactory {
    function get_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurvePoolC {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

interface ICurvePoolNoReturn {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts) external;
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;
}

interface ICurvePoolNoReturn128 {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface IFertilizer {
    struct Balance {
        uint128 amount;
        uint128 lastBpf;
    }
    function beanstalkUpdate(
        address account,
        uint256[] memory ids,
        uint128 bpf
    ) external returns (uint256);
    function beanstalkMint(address account, uint256 id, uint128 amount, uint128 bpf) external;
    function balanceOfFertilized(address account, uint256[] memory ids) external view returns (uint256);
    function balanceOfUnfertilized(address account, uint256[] memory ids) external view returns (uint256);
    function lastBalanceOf(address account, uint256 id) external view returns (Balance memory);
    function lastBalanceOfBatch(address[] memory account, uint256[] memory id) external view returns (Balance[] memory);
    function setURI(string calldata newuri) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @author Publius
 * @title LibSafeMath128 is a uint128 variation of Open Zeppelin's Safe Math library.
**/
library LibSafeMath128 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        uint128 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint128 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) return 0;
        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @author Publius
 * @title LibSafeMath32 is a uint32 variation of Open Zeppelin's Safe Math library.
**/
library LibSafeMath32 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        uint32 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint32 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) return 0;
        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import "../LibAppStorage.sol";

/**
 * @author LeoFib, Publius
 * @title LibInternalBalance Library handles internal read/write functions for Internal User Balances.
 * Largely inspired by Balancer's Vault
 **/

library LibBalance {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Emitted when a account's Internal Balance changes, through interacting using Internal Balance.
     *
     */
    event InternalBalanceChanged(
        address indexed account,
        IERC20 indexed token,
        int256 delta
    );

    function getBalance(address account, IERC20 token)
        internal
        view
        returns (uint256 combined_balance)
    {
        combined_balance = token.balanceOf(account).add(
            getInternalBalance(account, token)
        );
        return combined_balance;
    }

    /**
     * @dev Increases `account`'s Internal Balance for `token` by `amount`.
     */
    function increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal {
        uint256 currentBalance = getInternalBalance(account, token);
        uint256 newBalance = currentBalance.add(amount);
        setInternalBalance(account, token, newBalance, amount.toInt256());
    }

    /**
     * @dev Decreases `account`'s Internal Balance for `token` by `amount`. If `allowPartial` is true, this function
     * doesn't revert if `account` doesn't have enough balance, and sets it to zero and returns the deducted amount
     * instead.
     */
    function decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool allowPartial
    ) internal returns (uint256 deducted) {
        uint256 currentBalance = getInternalBalance(account, token);
        require(
            allowPartial || (currentBalance >= amount),
            "Balance: Insufficient internal balance"
        );

        deducted = Math.min(currentBalance, amount);
        // By construction, `deducted` is lower or equal to `currentBalance`, so we don't need to use checked
        // arithmetic.
        uint256 newBalance = currentBalance - deducted;
        setInternalBalance(account, token, newBalance, -(deducted.toInt256()));
    }

    /**
     * @dev Sets `account`'s Internal Balance for `token` to `newBalance`.
     *
     * Emits an `InternalBalanceChanged` event. This event includes `delta`, which is the amount the balance increased
     * (if positive) or decreased (if negative). To avoid reading the current balance in order to compute the delta,
     * this function relies on the caller providing it directly.
     */
    function setInternalBalance(
        address account,
        IERC20 token,
        uint256 newBalance,
        int256 delta
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.internalTokenBalance[account][token] = newBalance;
        emit InternalBalanceChanged(account, token, delta);
    }

    /**
     * @dev Returns `account`'s Internal Balance for `token`.
     */
    function getInternalBalance(address account, IERC20 token)
        internal
        view
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.internalTokenBalance[account][token];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
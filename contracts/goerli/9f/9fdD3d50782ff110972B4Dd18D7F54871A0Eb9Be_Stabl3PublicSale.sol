// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";

contract Stabl3PublicSale is Ownable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint8 constant BUY_POOL = 1;

    ITreasury public treasury;
    address public ROI;
    address public HQ;

    IERC20 public stabl3;

    uint256 public treasuryPercentage;
    uint256 public ROIPercentage;
    uint256 public HQPercentage;

    uint256 public exchangeFee;

    bool public saleState;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedExchangeFee(uint256 newExchangeFee, uint256 oldExchangeFee);

    event Buy(address indexed recipient, uint256 amountStabl3, IERC20 token, uint256 amountToken);

    event Exchanged(address indexed recipient, IERC20 exchangingToken, uint256 amountExchangingToken, uint256 fee, IERC20 token, uint256 amountToken);

    // constructor

    constructor(address _treasury, address _ROI) {
        treasury = ITreasury(_treasury);
        ROI = _ROI;
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        treasuryPercentage = 800;
        ROIPercentage = 161;
        HQPercentage = 39;

        exchangeFee = 3;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "Stabl3PublicSale: Treasury is already this address");
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(ROI != _ROI, "Stabl3PublicSale: ROI is already this address");
        emit UpdatedROI(_ROI, ROI);
        ROI = _ROI;
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3PublicSale: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _ROIPercentage,
        uint256 _HQPercentage
    ) external onlyOwner {
        require(_treasuryPercentage + _ROIPercentage + _HQPercentage == 1000,
            "STABL3: Sum of magnified percentages should equal 1000");

        treasuryPercentage = _treasuryPercentage;
        ROIPercentage = _ROIPercentage;
        HQPercentage = _HQPercentage;
    }

    function updateExchangeFee(uint256 _exchangeFee) external onlyOwner {
        require(exchangeFee != _exchangeFee, "Stabl3PublicSale: Exchange Fee is already this value");
        emit UpdatedExchangeFee(_exchangeFee, exchangeFee);
        exchangeFee = _exchangeFee;
    }

    function updateSaleState(bool _state) external onlyOwner {
        require(saleState != _state, "Stabl3PublicSale: Sale state is already of the value 'state'");
        saleState = _state;
    }

    function buy(IERC20 _token, uint256 _amountToken) external saleActive reserved(_token) {
        require(_amountToken > 0, "Stabl3PublicSale: Insufficient amount");

        uint256 amountStabl3 = treasury.getAmountOut(_token, _amountToken);

        uint256 amountTreasury = _amountToken.mul(treasuryPercentage).ceilDiv(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);

        uint256 amountROI = _amountToken.mul(ROIPercentage).div(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, ROI, amountROI);

        uint256 amountHQ = _amountToken.mul(HQPercentage).div(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

        stabl3.transferFrom(address(treasury), msg.sender, amountStabl3);

        emit Buy(msg.sender, amountStabl3, _token, _amountToken);
        treasury.updatePool(BUY_POOL, _token, amountTreasury, amountROI, amountHQ, true);
        treasury.updateRate(_token, _amountToken);
    }

    function exchange(
        IERC20 _exchangingToken,
        IERC20 _token,
        uint256 _amountToken
    ) external saleActive reserved(_exchangingToken) reserved(_token) {
        require(_exchangingToken != _token, "Stabl3PublicSale: Invalid exchange");
        require(_amountToken > 0, "Stabl3PublicSale: Insufficient amount");

        uint256 fee = (_amountToken * exchangeFee) / 1000;
        _amountToken -= fee;

        uint256 amountStabl3 = treasury.getAmountOut(_token, fee);

        SafeERC20.safeTransferFrom(_token, msg.sender, ROI, fee);

        stabl3.transferFrom(address(treasury), msg.sender, amountStabl3);

        emit Buy(msg.sender, amountStabl3, _token, fee);
        treasury.updatePool(BUY_POOL, _token, 0, fee, 0, true);
        treasury.updateRate(_token, fee);

        uint256 amountExchangingToken;

        if (_exchangingToken.decimals() > _token.decimals()) {
            amountExchangingToken = _amountToken * (10 ** (_exchangingToken.decimals() - _token.decimals()));
        }
        else if (_token.decimals() > _exchangingToken.decimals()) {
            amountExchangingToken = _amountToken / (10 ** (_token.decimals() - _exchangingToken.decimals()));
        }
        else {
            amountExchangingToken = _amountToken;
        }

        uint256 amountTreasury = _amountToken.mul(treasuryPercentage).ceilDiv(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);

        uint256 amountROI = _amountToken.mul(ROIPercentage).div(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, ROI, amountROI);

        uint256 amountHQ = _amountToken.mul(HQPercentage).div(1000);
        SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

        SafeERC20.safeTransferFrom(_exchangingToken, address(treasury), msg.sender, amountExchangingToken);

        emit Exchanged(msg.sender, _exchangingToken, amountExchangingToken, fee, _token, _amountToken);
        treasury.updatePool(BUY_POOL, _token, amountTreasury, amountROI, amountHQ, true);
        treasury.updatePool(BUY_POOL, _exchangingToken, amountExchangingToken, 0, 0, false);
    }

    // modifiers

    modifier saleActive() {
        require(saleState, "Stabl3PublicSale: Sale not yet started");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "Stabl3PublicSale: Not a reserved token");
        _;
    }
}
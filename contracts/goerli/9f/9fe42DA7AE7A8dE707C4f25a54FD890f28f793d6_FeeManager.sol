// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./FeeManagerHelper.sol";

contract FeeManager is FeeManagerHelper {

    constructor(
        address _multisig,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
        DeclarationsFeeManager(
            _multisig,
            _wiseLendingAddress,
            _oracleHubAddress,
            _wiseSecurityAddress,
            _positionNFTAddress
        )
    {}

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external
        onlyMultisig
    {
        if (_newFee > PRECISION_FACTOR_E18) {
            revert TooHighValue();
        }

        if (_newFee < PRECISION_FACTOR_E16) {
            revert TooLowValue();
        }

        WISE_LENDING.setPoolFee(
            _poolToken,
            _newFee
        );
    }

    function renounceIncentiveMaster(
        address _newIncentiveMaster
    )
        external
        onlyIncentiveMaster
    {
        renouncedIncentiveMaster = _newIncentiveMaster;
    }

    function claimNewIncentiveMaster()
        external
    {
        if (msg.sender != renouncedIncentiveMaster) {
            revert NotAllowed();
        }

        incentiveMaster = renouncedIncentiveMaster;
        renouncedIncentiveMaster = ZERO_ADDRESS;
    }

    function increaseIncentiveA(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerA] += _value;
    }

    function increaseIncentiveB(
        uint256 _value
    )
        external
        onlyIncentiveMaster
    {
        incentiveUSD[incentiveOwnerB] += _value;
    }

    function claimIncentivesBulk()
        external
    {
        for (uint8 i = 0; i < poolTokenAddresses.length; i++) {

            claimIncentives(
                poolTokenAddresses[i]
            );
        }
    }

    function claimIncentives(
        address _poolToken
    )
        public
    {
        address caller = msg.sender;

        _safeTransfer(
            _poolToken,
            caller,
            gatheredIncentiveToken[caller][_poolToken]
        );

        gatheredIncentiveToken[caller][_poolToken] = 0;
    }

    function approveWiseLending()
        external
    {
        for (uint8 i = 0 ; i < poolTokenAddresses.length; i++ ) {
            IERC20(poolTokenAddresses[i]).approve(
                address(WISE_LENDING),
                HUGE_AMOUNT
            );
        }
    }

    function changeIncentiveUSDA(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerA) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[incentiveOwnerA];
        incentiveUSD[incentiveOwnerA] = 0;

        incentiveOwnerA = _newOwner;
    }

    function changeIncentiveUSDB(
        address _newOwner
    )
        external
    {
        if (msg.sender != incentiveOwnerB) {
            revert NotAllowed();
        }

        incentiveUSD[_newOwner] = incentiveUSD[incentiveOwnerB];
        incentiveUSD[incentiveOwnerB] = 0;

        incentiveOwnerB= _newOwner;
    }

    function addPoolTokenAddress(
        address _poolToken
    )
        external
        onlyWiseLending
    {
        poolTokenAddresses.push(_poolToken);

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    function addPoolTokenAddressManual(
        address _poolToken
    )
        external
        onlyMultisig
    {
        if (poolTokenAdded[_poolToken] == true) {
            revert PoolAlreadyAdded();
        }

        poolTokenAddresses.push(_poolToken);

        poolTokenAdded[_poolToken] = true;

        emit PoolTokenAdded(
            _poolToken,
            block.timestamp
        );
    }

    function getNumberRegisteredPools()
        external
        view
        returns (uint256)
    {
        return poolTokenAddresses.length;
    }

    function removePoolTokenManual(
        address _poolToken
    )
        external
        onlyMultisig
    {
        uint256 len = poolTokenAddresses.length;
        uint256 lastEntry = len - 1;

        for (uint8 i = 0; i < len; i++) {

            if (_poolToken != poolTokenAddresses[i]) {

                continue;
            }

            poolTokenAddresses[i] = poolTokenAddresses[lastEntry];

            poolTokenAddresses.pop();

            poolTokenAdded[_poolToken] = false;

            break;
        }
    }

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _increaseTotalBadDebt(
            _amount
        );

        emit BadDebtIncreasedLiquidation(
            _amount,
            block.timestamp
        );
    }

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external
        onlyWiseSecurity
    {
        _setBadDebtUser(
            _nftId,
            _amount
        );

        emit SetBadDebtPosition(
            _nftId,
            _amount,
            block.timestamp
        );
    }

    function setBeneficial(
        address _user,
        address[] memory _poolTokens
    )
        external
        onlyMultisig
    {
        for (uint8 i = 0; i < _poolTokens.length; i++) {
            _setAllowedTokens(
                _user,
                _poolTokens[i],
                true
            );
        }

        emit SetBeneficial(
            _user,
            _poolTokens,
            block.timestamp
        );
    }

    function revokeBeneficial(
        address _user,
        address[] memory _poolTokens
    )
        external
        onlyMultisig
    {
        for (uint8 i = 0; i < _poolTokens.length; i++) {
            _setAllowedTokens(
                _user,
                _poolTokens[i],
                false
            );
        }

        emit RevokeBeneficial(
            _user,
            _poolTokens,
            block.timestamp
        );
    }

    function claimWiseFeesBulk()
        external
    {
        for(uint8 i = 0; i < poolTokenAddresses.length; i++) {
            claimWiseFees(
                poolTokenAddresses[i]
            );
        }
    }

    function claimWiseFees(
        address _poolToken
    )
        public
    {
        uint256 shares = WISE_LENDING.getPositionLendingShares(
            FEE_MASTER_NFT_ID,
            _poolToken
        );

        if (shares == 0) {
            return;
        }

        uint256 tokenAmount = WISE_LENDING.withdrawExactShares(
            FEE_MASTER_NFT_ID,
            _poolToken,
            shares
        );

        if (totalBadDebtUSD == 0) {

            tokenAmount = _distributeIncentives(
                tokenAmount,
                _poolToken
            );
        }

        _increaseFeeTokens(
            _poolToken,
            tokenAmount
        );

        emit ClaimedFeesWise(
            _poolToken,
            tokenAmount,
            block.timestamp
        );
    }

    function claimFeesBeneficial(
        address _poolToken,
        uint256 _amount
    )
        external
    {
        address caller = msg.sender;

        if (totalBadDebtUSD > 0) {
            revert ExistingBadDebt();
        }

        if (allowedTokens[caller][_poolToken] == false) {
            revert NotAllowed();
        }

        _decreaseFeeTokens(
            _poolToken,
            _amount
        );

        _safeTransfer(
            _poolToken,
            caller,
            _amount
        );

        emit ClaimedFeesBeneficial(
            caller,
            _poolToken,
            _amount,
            block.timestamp
        );
    }

    function payBackBadDebtForToken(
        uint256 _nftId,
        address _paybackToken,
        address _receivingToken,
        uint256 _shares
    )
        external
        returns (uint256 paybackAmount, uint256 receivingAmount)
    {
        address caller = msg.sender;

        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return (0, 0);
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        _safeTransferFrom(
            _paybackToken,
            caller,
            address(this),
            paybackAmount
        );

        WISE_LENDING.corePaybackFeeMananger(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        receivingAmount = getReceivingToken(
            _paybackToken,
            _receivingToken,
            paybackAmount
        );

        _decreaseFeeTokens(
            _receivingToken,
            receivingAmount
        );

        _safeTransfer(
            _receivingToken,
            caller,
            receivingAmount
        );

        emit PayedBackBadDebt(
            _nftId,
            caller,
            _paybackToken,
            _receivingToken,
            paybackAmount,
            block.timestamp
        );
    }

    function paybackBadDebtForFree(
        uint256 _nftId,
        address _paybackToken,
        uint256 _shares
    )
        external
        returns (uint256 paybackAmount)
    {
        address caller = msg.sender;

        updatePositionCurrentBadDebt(
            _nftId
        );

        if (badDebtPosition[_nftId] == 0) {
            return 0;
        }

        paybackAmount = WISE_LENDING.paybackAmount(
            _paybackToken,
            _shares
        );

        _safeTransferFrom(
            _paybackToken,
            caller,
            address(this),
            paybackAmount
        );

        WISE_LENDING.corePaybackFeeMananger(
            _paybackToken,
            _nftId,
            paybackAmount,
            _shares
        );

        _updateUserBadDebt(
            _nftId
        );

        emit PayedBackBadDebtFree(
            _nftId,
            caller,
            _paybackToken,
            paybackAmount,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./DeclarationsFeeManager.sol";
import "../TransferHub/TransferHelper.sol";

abstract contract FeeManagerHelper is DeclarationsFeeManager, TransferHelper {

    // @TODO we have duplicate?
    function _prepareBorrows(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionBorrowTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }

    // @TODO we have duplicate?
    function _prepareCollaterals(
        uint256 _nftId
    )
        internal
    {
        for (uint256 i = 0; i < WISE_LENDING.getPositionLendingTokenLength(_nftId); i++) {

            address currentAddress = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            WISE_LENDING.curveSecurityCheck(
                currentAddress
            );

            WISE_LENDING.preparePool(
                currentAddress
            );
        }
    }

    function _setBadDebtUser(
        uint256 _nftId,
        uint256 _amount
    )
        internal
    {
        badDebtPosition[_nftId] = _amount;
    }

    function _increaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtUSD += _amount;

        emit TotalBadDebtIncreased(
            _amount,
            block.timestamp
        );
    }

    function _decreaseTotalBadDebt(
        uint256 _amount
    )
        internal
    {
        totalBadDebtUSD -= _amount;

        emit TotalBadDebtDecreased(
            _amount,
            block.timestamp
        );
    }

    function _eraseBadDebtUser(
        uint256 _nftId
    )
        internal
    {
        badDebtPosition[_nftId] = 0;
    }

    function _updateUserBadDebt(
        uint256 _nftId
    )
        internal
    {
        uint256 currentBorrowUSD = WISE_SECURITY.overallUSDBorrow(
            _nftId
        );

        uint256 currentCollateralBareUSD = WISE_SECURITY.overallUSDCollateralsBare(
            _nftId
        );

        uint256 currentBadDebt = badDebtPosition[_nftId];

        if (currentBorrowUSD < currentCollateralBareUSD) {

            _eraseBadDebtUser(
                _nftId
            );

            _decreaseTotalBadDebt(
                currentBadDebt
            );

            emit UpdateBadDebtPosition(
                _nftId,
                0,
                block.timestamp
            );

            return;
        }

        uint256 newBadDebt = currentBorrowUSD
            - currentCollateralBareUSD;

        _setBadDebtUser(
            _nftId,
            newBadDebt
        );

        newBadDebt > currentBadDebt
            ? _increaseTotalBadDebt(newBadDebt - currentBadDebt)
            : _decreaseTotalBadDebt(currentBadDebt - newBadDebt);

        emit UpdateBadDebtPosition(
            _nftId,
            newBadDebt,
            block.timestamp
        );
    }

    function _increaseFeeTokens(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_poolToken] += _amount;
    }

    function _decreaseFeeTokens(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        feeTokens[_poolToken] -= _amount;
    }

    function _setAllowedTokens(
        address _user,
        address _poolToken,
        bool _state
    )
        internal
    {
        allowedTokens[_user][_poolToken] = _state;
    }

    function getReceivingToken(
        address _paybackToken,
        address _receivingToken,
        uint256 _paybackAmount
    )
        public
        returns (uint256 receivingAmount)
    {
        uint256 paybackUSD = ORACLE_HUB.getTokensInUSD(
            _paybackToken,
            _paybackAmount
        );

        totalBadDebtUSD -= paybackUSD;

        receivingAmount = PAYBACK_INCENTIVE
            * ORACLE_HUB.getTokensFromUSD(
                _receivingToken,
                paybackUSD
            )
            / PRECISION_FACTOR_E18 ;
    }

    function updatePositionCurrentBadDebt(
        uint256 _nftId
    )
        public
    {
        _prepareCollaterals(
            _nftId
        );

        _prepareBorrows(
            _nftId
        );

        _updateUserBadDebt(
            _nftId
        );
    }

    function _distributeIncentives(
        uint256 _amount,
        address _poolToken
    )
        internal
        returns (uint256)
    {
        uint256 reduceAmount;

        if (incentiveUSD[incentiveOwnerA] != 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                incentiveOwnerA,
                _amount
            );
        }

        if (incentiveUSD[incentiveOwnerB] != 0) {

            reduceAmount += _gatherIncentives(
                _poolToken,
                incentiveOwnerB,
                _amount
            );
        }

        return _amount - reduceAmount;
    }

    function _gatherIncentives(
        address _poolToken,
        address _incentiveOwner,
        uint256 _amount
    )
        internal
        returns (uint256 )
    {
        uint256 incentiveAmount = _amount
            * INCENTIVE_PORTION
            / WISE_LENDING.globalPoolData(_poolToken).poolFee;

        uint256 usdEquivalent = ORACLE_HUB.getTokensInUSD(
            _poolToken,
            incentiveAmount
        );

        uint256 openUSD = usdEquivalent < incentiveUSD[_incentiveOwner]
            ? usdEquivalent
            : incentiveUSD[_incentiveOwner];

        if (openUSD == usdEquivalent) {

            incentiveUSD[_incentiveOwner] -= usdEquivalent;
            gatheredIncentiveToken[_incentiveOwner][_poolToken] += incentiveAmount;

            return incentiveAmount;
        }

        incentiveAmount = ORACLE_HUB.getTokensFromUSD(
            _poolToken,
            openUSD
        );

        incentiveUSD[_incentiveOwner] = 0;
        gatheredIncentiveToken[_incentiveOwner][_poolToken] += incentiveAmount;

        return incentiveAmount;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";

contract TransferHelper {

    /**
     * @dev
     * Allows to execute transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Helper function to do the token call
     */
    function _callOptionalReturn(
        address _token,
        bytes memory _data
    )
        private
    {
        (
            bool success,
            bytes memory returndata
        ) = _token.call(_data);

        require(
            success,
            "TransferHelper: CALL_FAILED"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(
                    returndata,
                    (bool)
                ),
                "TransferHelper: OPERATION_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";
import "../InterfaceHub/IWiseLending.sol";
import "../InterfaceHub/IFeeManager.sol";
import "../InterfaceHub/IWiseSecurity.sol";
import "../InterfaceHub/IPositionNFTs.sol";
import "../InterfaceHub/IWiseOracleHub.sol";

import "./FeeManagerEvents.sol";

error NotWiseLiquidation();
error AlreadySet();
error ExistingBadDebt();
error TransferFromFailedFeeManager();
error TransferFailedFeeManager();
error NotWiseLending();
error NotAllowed();
error NotIncentiveMaster();
error PoolAlreadyAdded();
error TooHighValue();
error TooLowValue();

contract DeclarationsFeeManager is FeeManagerEvents {

    modifier onlyWiseSecurity() {
        _onlyWiseSecurity();
        _;
    }

    modifier onlyWiseLending() {
        _onlyWiseLending();
        _;
    }

    modifier onlyMultisig {
        _onlyMultisig();
        _;
    }

    modifier onlyIncentiveMaster() {
        _onlyIncentiveMaster();
        _;
    }

    function _onlyIncentiveMaster()
        private
        view
    {
        if (msg.sender == incentiveMaster) {
            return;
        }

        revert NotIncentiveMaster();
    }

    function _onlyWiseSecurity()
        private
        view
    {
        if (msg.sender == address(WISE_SECURITY)) {
            return;
        }

        revert NotWiseLiquidation();
    }

    function _onlyWiseLending()
        private
        view
    {
        if (msg.sender == address(WISE_LENDING)) {
            return;
        }

        revert NotWiseLending();
    }

    function _onlyMultisig()
        private
        view
    {
        if (msg.sender == multisig) {
            return;
        }

        revert NotAllowed();
    }

    constructor(
        address _multisig,
        address _wiseLendingAddress,
        address _oracleHubAddress,
        address _wiseSecurityAddress,
        address _positionNFTAddress
    )
    {
        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            _oracleHubAddress
        );

        WISE_SECURITY = IWiseSecurity(
            address(_wiseSecurityAddress)
        );

        POSITION_NFTS = IPositionNFTs(
            address(_positionNFTAddress)
        );

        POSITION_NFTS.mintPosition();

        FEE_MASTER_NFT_ID = POSITION_NFTS.tokenOfOwnerByIndex(
            address(this),
            0
        );

        multisig = _multisig;
        incentiveMaster = _multisig;

        incentiveOwnerA = 0xA7f676d112CA58a2e5045F22631A8388E9D7D8dE;
        incentiveOwnerB = 0x8f741ea9C9ba34B5B8Afc08891bDf53faf4B3FE7;

        incentiveUSD[incentiveOwnerA] = 220000 * PRECISION_FACTOR_E18;
        incentiveUSD[incentiveOwnerB] = 220000 * PRECISION_FACTOR_E18;
    }

    IWiseLending immutable public WISE_LENDING;
    IPositionNFTs immutable public POSITION_NFTS;
    IWiseSecurity immutable public WISE_SECURITY;
    IWiseOracleHub immutable public ORACLE_HUB;

    uint256 immutable public FEE_MASTER_NFT_ID;

    address public multisig;
    address public incentiveMaster;
    uint256 public totalBadDebtUSD;
    address[] public poolTokenAddresses;

    address public renouncedIncentiveMaster;

    address public incentiveOwnerA;
    address public incentiveOwnerB;

    mapping (uint256 => uint256) public badDebtPosition;
    mapping (address => uint256) public feeTokens;
    mapping (address => uint256) public incentiveUSD;
    mapping (address => bool) public poolTokenAdded;

    mapping (address => mapping (address => bool)) public allowedTokens;
    mapping (address => mapping (address => uint256)) public gatheredIncentiveToken;

    address constant ZERO_ADDRESS = address(0);

    uint256 constant PRECISION_FACTOR_E16 = 0.01 ether;
    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant HUGE_AMOUNT = type(uint256).max;
    uint256 constant public PAYBACK_INCENTIVE = 1.05 ether;
    uint256 constant public INCENTIVE_PORTION = 0.005 ether;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external;
        // returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

contract FeeManagerEvents {

    event PoolTokenAdded(
        address poolToken,
        uint256 timestamp
    );

    event BadDebtIncreasedLiquidation(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtIncreased(
        uint256 amount,
        uint256 timestamp
    );

    event TotalBadDebtDecreased(
        uint256 amount,
        uint256 timestamp
    );

    event SetBadDebtPosition(
        uint256 nftId,
        uint256 amount,
        uint256 timestamp
    );

    event UpdateBadDebtPosition(
        uint256 nftId,
        uint256 newAmount,
        uint256 timestamp
    );

    event SetBeneficial(
        address user,
        address[] token,
        uint256 timestamp
    );

    event RevokeBeneficial(
        address user,
        address[] token,
        uint256 timestamp
    );

    event ClaimedFeesWise(
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimedFeesBeneficial(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 indexed timestamp
    );

    event PayedBackBadDebt(
        uint256 nftId,
        address indexed sender,
        address paybackToken,
        address receivingToken,
        uint256 indexed paybackAmount,
        uint256 timestamp
    );

    event PayedBackBadDebtFree(
        uint256 nftId,
        address indexed sender,
        address paybackToken,
        uint256 indexed paybackAmount,
        uint256 timestampp
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IWiseOracleHub {

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function getTokenUSDFiat(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
        uint256 _nftId
    )
        external
        view
        returns (address);


    function totalSupply()
        external
        view
        returns (uint256);

    function mintPosition()
        external;

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

struct curveSwapStruct {
    uint256 curvePoolTokenIndexFrom;
    uint256 curvePoolTokenIndexTo;
    uint256 curveMetaPoolTokenIndexFrom;
    uint256 curveMetaPoolTokenIndexTo;
    uint256 curvePoolSwapAmount;
    uint256 curveMetaPoolSwapAmount;
}

interface IWiseSecurity {

    function checkBadDebt(
        uint256 _nftId
    )
        external;

    function getCollateralOfTokenUSD(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _caller,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view;

    function onlyIsolationPool(
        address _poolAddress
    )
        external
        view;

    function overallUSDBorrow(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function checkRegisteredForPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view;

    function FEE_MANAGER()
        external
        returns (address);

    function WISE_LIQUIDATION()
        external
        returns (address);

    function curveSecurityCheck(
        address _poolAddress
    )
        external;

    function prepareCurvePools(
        address _poolToken,
        address _curvePool,
        address _curveMetaPool,
        curveSwapStruct memory _curveSwapStruct
    )
        external;

    function setUnderlyingPoolTokensFromPoolToken(
        address _poolToken,
        address[] memory _underlyingTokens
    )
        external;

    function checksDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view;

    function checksDecollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken
    )
        external
        view;

    function checkBorrowLimit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkPaybackLendingShares(
        uint256 _nftIdReceiver,
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksRegistrationIsolationPool(
        uint256 _nftId,
        address _caller,
        address _isolationPool
    )
        external
        view;

    function checkUnregister(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkOnlyMaster(
        address _caller
    )
        external
        view;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IFeeManager {

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external;

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external;

    function FEE_MASTER_NFT_ID()
        external
        returns (uint256);

    function addPoolTokenAddress(
        address _poolToken
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

struct GlobalPoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

struct BorrowPoolEntry {
    bool allowBorrow;
    uint256 pseudoTotalBorrowAmount;
    uint256 borrowPercentageCap;
    uint256 totalBorrowShares;
    uint256 borrowRate;
}

struct LendingPoolEntry {
    uint256 pseudoTotalPool;
    uint256 totalDepositShares;
    uint256 collateralFactor;
}

struct PoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

interface IWiseLending {

    function borrowPoolData(
        address _poolToken
    )
        external
        view
        returns (BorrowPoolEntry memory);

    function lendingPoolData(
        address _poolToken
    )
        external
        view
        returns (LendingPoolEntry memory);

    function getPositionBorrowShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getCollateralState(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (bool);

    function veryfiedIsolationPool(
        address _poolAddress
    )
        external
        view
        returns (bool);

    function positionLocked(
        uint256 _nftId
    )
        external
        view
        returns (bool);

    function getTotalBareToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function maxDepositValueToken(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function lendingMaster()
        external
        view
        returns (address);

    function isolationPoolRegistered(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view
        returns (bool);

    function calculateLendingShares(
        address _poolToken,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function corePaybackLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function decreaseCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function decreaseTotalBareTokenLiquidation(
        address _poolToken,
        uint256 _amount
    )
        external;

    function positionPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        external
        returns (uint256);

    function coreWithdrawLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function decreaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external;

    function increaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external;

    function addPositionLendingTokenDataLiquidation(
        uint256 _nftId,
        address _poolToken
    )
        external;

    function getTotalPool(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        bool _collateralState
    )
        external
        returns (uint256);

    function withdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function syncManually(
        address _poolToken
    )
        external;

    function withdrawOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function borrowOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function solelyDepositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function solelyWithdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external;

    function paybackExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        returns (uint256);

    function paybackExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external;

    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        returns (uint256);

    function poolTokenAddresses()
        external
        returns (address[] memory);

    function corePaybackFeeMananger(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external;

    function curveSecurityCheck(
        address _poolToken
    )
        external;

    function preparePool(
        address _poolToken
    )
        external;

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function globalPoolData(
        address _poolToken
    )
        external
        view
        returns (GlobalPoolEntry memory);


    function getGlobalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalBorrowAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialBorrowAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getPseudoTotalPool(
        address _token
    )
        external
        view
        returns (uint256);

    function getInitialDepositAmountUser(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getGlobalDepositAmount(
        address _token
    )
        external
        view
        returns (uint256);

    function paybackAmount(
        address _token,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getPositionBorrowShares(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function getPositionLendingShares(
        address _user,
        address _token
    )
        external
        view
        returns (uint256);

    function cashoutAmount(
        address _token,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getTotalDepositShares(
        address _token
    )
        external
        view
        returns (uint256);

    function getTotalBorrowShares(
        address _token
    )
        external
        view
        returns (uint256);
}
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./TreasuryStorage.sol";
import "./common/ProxyAccessCommon.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/LibTreasury.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/ITreasuryEvent.sol";

// import "hardhat/console.sol";

interface IIERC20 {
    function burn(address account, uint256 amount) external returns (bool);
}

interface IITOSValueCalculator {

    function convertAssetBalanceToWethOrTos(address _asset, uint256 _amount)
        external view
        returns (bool existedWethPool, bool existedTosPool,  uint256 priceWethOrTosPerAsset, uint256 convertedAmount);

    function getTOSPricePerETH() external view returns (uint256 price);

    function getETHPricePerTOS() external view returns (uint256 price);
}

interface IIStaking {
    function stakedOfAll() external view returns (uint256) ;
}

interface IIIUniswapV3Pool {
    function liquidity() external view returns (uint128);
}

contract Treasury is
    TreasuryStorage,
    ProxyAccessCommon,
    ITreasury,
    ITreasuryEvent
{
    using SafeERC20 for IERC20;


    constructor() {
    }

    /* ========== onlyPolicyOwner ========== */

    /// @inheritdoc ITreasury
    function enable(
        uint _status,
        address _address
    )
        external override
        onlyPolicyOwner
    {
        LibTreasury.STATUS role = LibTreasury.getStatus(_status);

        require(role != LibTreasury.STATUS.NONE, "NONE permission");
        require(permissions[role][_address] == false, "already set");

        permissions[role][_address] = true;

        (bool registered, ) = indexInRegistry(_address, role);

        if (!registered) {
            registry[role].push(_address);
        }

        emit Permissioned(_address, _status, true);
    }

    /// @inheritdoc ITreasury
    function disable(uint _status, address _toDisable)
        external override onlyPolicyOwner
    {
        LibTreasury.STATUS role = LibTreasury.getStatus(_status);
        require(role != LibTreasury.STATUS.NONE, "NONE permission");
        require(permissions[role][_toDisable] == true, "hasn't permissions");

        permissions[role][_toDisable] = false;

        (bool registered, uint256 _index) = indexInRegistry(_toDisable, role);
        if (registered && registry[role].length > 0) {
            if (_index < registry[role].length-1) registry[role][_index] = registry[role][registry[role].length-1];
            registry[role].pop();
        }

        emit Permissioned(_toDisable, uint(role), false);
    }

    /// @inheritdoc ITreasury
    function approve(
        address _address
    ) external override onlyPolicyOwner {
        tos.approve(_address, 1e45);
    }

    /// @inheritdoc ITreasury
    function setMR(uint256 _mrRate, uint256 amount) external override onlyPolicyOwner {

        require(mintRate != _mrRate || amount > 0, "check input value");

        require(checkTosSolvencyAfterTOSMint(_mrRate, amount), "unavailable mintRate");

        if (mintRate != _mrRate) mintRate = _mrRate;
        if (amount > 0) tos.mint(address(this), amount);

        emit SetMintRate(_mrRate, amount);
    }

    /// @inheritdoc ITreasury
    function setPoolAddressTOSETH(address _poolAddressTOSETH) external override onlyPolicyOwner {
        require(poolAddressTOSETH != _poolAddressTOSETH, "same address");
        poolAddressTOSETH = _poolAddressTOSETH;

        emit SetPoolAddressTOSETH(_poolAddressTOSETH);
    }

    /// @inheritdoc ITreasury
    function setUniswapV3Factory(address _uniswapFactory) external override onlyPolicyOwner {
        require(uniswapV3Factory != _uniswapFactory, "same address");
        uniswapV3Factory = _uniswapFactory;

        emit SetUniswapV3Factory(_uniswapFactory);
    }

    /// @inheritdoc ITreasury
    function setMintRateDenominator(uint256 _mintRateDenominator) external override onlyPolicyOwner {
        require(mintRateDenominator != _mintRateDenominator && _mintRateDenominator > 0, "check input value");
        mintRateDenominator = _mintRateDenominator;

        emit SetMintRateDenominator(_mintRateDenominator);
    }

    /// @inheritdoc ITreasury
    function addBackingList(address _address)
        external override onlyPolicyOwner
        nonZeroAddress(_address)
    {
        _addBackingList(_address);
    }

    function _addBackingList(address _address) internal
    {
        bool existAsset = false;
        uint256 len = backings.length;

        for (uint256 i = 0; i < len; i++)
            if (_address == backings[i]) {
                existAsset = true;
                break;
            }

        if(!existAsset) {
            backings.push(_address);
            emit AddedBackingList(_address);
        }
    }

    /// @inheritdoc ITreasury
    function deleteBackingList(
        address _address
    )
        external override onlyPolicyOwner
        nonZeroAddress(_address)
    {
        uint256 len = backings.length;

        for (uint256 i = 0; i < len; i++){
            if (_address == backings[i]) {
                if (i < len-1) backings[i] = backings[len-1];
                backings.pop();
                emit DeletedBackingList(_address);
                break;
            }
        }
    }

    /// @inheritdoc ITreasury
    function setFoundationDistributeInfo(
        address[] calldata  _address,
        uint256[] calldata _percents
    )
        external override onlyPolicyOwner
    {
        require(_address.length > 0, "zero length");
        require(_address.length == _percents.length, "wrong length");
        foundationTotalPercentage = 0;

        uint256 len = _address.length;
        for (uint256 i = 0; i< len ; i++){
            require(_address[i] != address(0), "zero address");
            require(_percents[i] > 0, "zero _percents");
            foundationTotalPercentage += _percents[i];
        }
        require(foundationTotalPercentage < 100, "wrong _percents");

        delete mintings;

        for (uint256 i = 0; i< len ; i++) {
            mintings.push(
                LibTreasury.Minting({
                    mintAddress: _address[i],
                    mintPercents: _percents[i]
                })
            );
        }

        emit SetFoundationDistributeInfo(_address, _percents);
    }

    function foundationDistribute() external onlyPolicyOwner {
        require(foundationAmount > 0 && mintings.length > 0, "No funds or no distribution");
        uint256 _amount = foundationAmount;

        for (uint256 i = 0; i < mintings.length ; i++) {
            uint256 _distributeAmount = foundationAmount * mintings[i].mintPercents / 100;
            _amount -= _distributeAmount;
            tos.safeTransfer(mintings[i].mintAddress, _distributeAmount);
        }

        foundationAmount = _amount;
    }

    /* ========== permissions : LibTreasury.STATUS.RESERVEDEPOSITOR ========== */

    function requestMint(
        uint256 _mintAmount,
        bool _distribute
    ) external override nonZero(_mintAmount)
    {
        require(isBonder(msg.sender), notApproved);
        tos.mint(address(this), _mintAmount);

        if (_distribute && foundationTotalPercentage > 0 )
          foundationAmount += (_mintAmount * foundationTotalPercentage / 100);

        emit RquestedMint(_mintAmount, _distribute);

    }

    /// @inheritdoc ITreasury
    function addBondAsset(address _address)  external override
    {
        require(isBonder(msg.sender), "caller is not bonder");
        require(_address != address(0), "zero asset");
        _addBackingList(_address);
    }

    /// @inheritdoc ITreasury
    function requestTransfer(
        address _recipient,
        uint256 _amount
    ) external override {
        require(isStaker(msg.sender), notApproved);
        require(_recipient != address(0) && _amount > 0, "zero recipient or amount");

        require(enableStaking() >= _amount, "treasury balance is insufficient");

        tos.safeTransfer(_recipient, _amount);

        emit RequestedTransfer(_recipient, _amount);
    }


    /* ========== VIEW ========== */

    /// @inheritdoc ITreasury
    function getMintRate() public override view returns (uint256) {
        return mintRate;
    }

    /// @inheritdoc ITreasury
    function backingRateETHPerTOS() public override view returns (uint256) {
        return (backingReserve() / tos.totalSupply()) ;
    }

    /// @inheritdoc ITreasury
    function indexInRegistry(
        address _address,
        LibTreasury.STATUS _status
    )
        public override view returns (bool, uint256)
    {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /// @inheritdoc ITreasury
    function enableStaking() public override view returns (uint256) {
        uint256 _balance = tos.balanceOf(address(this));
        if (_balance >= foundationAmount) return (_balance - foundationAmount);
        return 0;
    }

    /// @inheritdoc ITreasury
    function backingReserve() public override view returns (uint256) {
        uint256 totalValue = 0;

        bool applyWTON = false;
        uint256 tosETHPricePerTOS = IITOSValueCalculator(calculator).getETHPricePerTOS();

        uint256 len = backings.length;
        for(uint256 i = 0; i < len; i++) {

            if (backings[i] == wethAddress)  {
                totalValue += IERC20(wethAddress).balanceOf(address(this));
                applyWTON = true;

            } else if (backings[i] != address(0) && backings[i] != address(tos))  {

                (bool existedWethPool, bool existedTosPool, , uint256 convertedAmount) =
                    IITOSValueCalculator(calculator).convertAssetBalanceToWethOrTos(backings[i], IERC20(backings[i]).balanceOf(address(this)));

                if (existedWethPool) totalValue += convertedAmount;
                else if (existedTosPool){
                    if (poolAddressTOSETH != address(0) && IIIUniswapV3Pool(poolAddressTOSETH).liquidity() == 0) {
                        //  TOS * 1e18 / (TOS/ETH) = ETH
                        totalValue +=  (convertedAmount * mintRateDenominator / mintRate );
                    } else {
                        // TOS * ETH/TOS / token decimal = ETH
                        totalValue += (convertedAmount * tosETHPricePerTOS / 1e18);
                    }
                }
            }
        }

        if (!applyWTON && wethAddress != address(0)) totalValue += IERC20(wethAddress).balanceOf(address(this));

        totalValue += address(this).balance;

        return totalValue;
    }

    /// @inheritdoc ITreasury
    function totalBacking() public override view returns(uint256) {
         return backings.length;
    }


    /// @inheritdoc ITreasury
    function allBacking() external override view
        returns (address[] memory)
    {
        return backings;
    }

    /// @inheritdoc ITreasury
    function totalMinting() external override view returns(uint256) {
         return mintings.length;
    }

    /// @inheritdoc ITreasury
    function viewMintingInfo(uint256 _index)
        external override view returns(address mintAddress, uint256 mintPercents)
    {
         return (mintings[_index].mintAddress, mintings[_index].mintPercents);
    }

    /// @inheritdoc ITreasury
    function allMinting() external override view
        returns (
            address[] memory mintAddress,
            uint256[] memory mintPercents
            )
    {
        uint256 len = mintings.length;
        mintAddress = new address[](len);
        mintPercents = new uint256[](len);

        for (uint256 i = 0; i < len; i++){
            mintAddress[i] = mintings[i].mintAddress;
            mintPercents[i] = mintings[i].mintPercents;
        }
    }

    /// @inheritdoc ITreasury
    function hasPermission(uint role, address account) public override view returns (bool) {
        return permissions[LibTreasury.getStatus(role)][account];
    }

    /// @inheritdoc ITreasury
    function checkTosSolvencyAfterTOSMint(uint256 _checkMintRate, uint256 amount)
        public override view returns (bool)
    {
        if (tos.totalSupply() + amount  <= backingReserve() * _checkMintRate / mintRateDenominator)  return true;
        else return false;
    }

    /// @inheritdoc ITreasury
    function  checkTosSolvency(uint256 amount) public override view returns (bool)
    {
        if ( tos.totalSupply() + amount <= backingReserve() * mintRate / mintRateDenominator)  return true;
        else return false;
    }

    /// @inheritdoc ITreasury
    function backingReserveETH() public override view returns (uint256) {
        return backingReserve();
    }

    /// @inheritdoc ITreasury
    function backingReserveTOS() public override view returns (uint256) {

        return backingReserve() * getTOSPricePerETH() / 1e18;
    }

    /// @inheritdoc ITreasury
    function getETHPricePerTOS() public override view returns (uint256) {
        if (poolAddressTOSETH != address(0) && IIIUniswapV3Pool(poolAddressTOSETH).liquidity() == 0) {
            return  (mintRateDenominator / mintRate);
        } else {
            return IITOSValueCalculator(calculator).getETHPricePerTOS();
        }
    }

    /// @inheritdoc ITreasury
    function getTOSPricePerETH() public override view returns (uint256) {
        if (poolAddressTOSETH != address(0) && IIIUniswapV3Pool(poolAddressTOSETH).liquidity() == 0) {
            return  mintRate;
        } else {
            return IITOSValueCalculator(calculator).getTOSPricePerETH();
        }
    }

    /// @inheritdoc ITreasury
    function isBonder(address account) public override view virtual returns (bool) {
        return permissions[LibTreasury.STATUS.BONDER][account];
    }

    /// @inheritdoc ITreasury
    function isStaker(address account) public override view virtual returns (bool) {
        return permissions[LibTreasury.STATUS.STAKER][account];
    }

    function withdrawEther(address account) external onlyPolicyOwner nonZeroAddress(account) {
        require(address(this).balance > 0, "zero balance");
        payable(account).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibTreasury.sol";
import "./interfaces/IERC20.sol";

contract TreasuryStorage {

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
    string internal insufficientReserves = "Treasury: insufficient reserves";

    IERC20 public tos;
    address public calculator;
    address public wethAddress;
    address public uniswapV3Factory;
    address public stakingV2;
    address public poolAddressTOSETH;

    uint256 public mintRate;
    uint256 public mintRateDenominator;
    uint256 public foundationAmount;
    uint256 public foundationTotalPercentage;

    mapping(LibTreasury.STATUS => address[]) public registry;
    mapping(LibTreasury.STATUS => mapping(address => bool)) public permissions;

    address[] public backings;
    LibTreasury.Minting[] public mintings;
    uint256[] public lpTokens;


    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "Treasury: zero uint");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "Treasury:zero address"
        );
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract ProxyAccessCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender) || isProxyAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    modifier onlyProxyOwner() {
        require(isProxyAdmin(msg.sender), "Accessible: Caller is not an proxy admin");
        _;
    }

    modifier onlyPolicyOwner() {
        require(isPolicy(msg.sender), "Accessible: Caller is not an policy admin");
        _;
    }

    function addProxyAdmin(address _owner)
        external
        onlyProxyOwner
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function removeProxyAdmin()
        public virtual onlyProxyOwner
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferProxyAdmin(address newAdmin)
        external virtual
        onlyProxyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyProxyOwner {
        grantRole(PROJECT_ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(PROJECT_ADMIN_ROLE, newAdmin);
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    function addPolicy(address _account) public virtual onlyProxyOwner {
        grantRole(POLICY_ROLE, _account);
    }

    function removePolicy() public virtual onlyPolicyOwner {
        renounceRole(POLICY_ROLE, msg.sender);
    }

    function transferPolicyAdmin(address newAdmin)
        external virtual
        onlyPolicyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(POLICY_ROLE, newAdmin);
        renounceRole(POLICY_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(PROJECT_ADMIN_ROLE, account);
    }

    function isProxyAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isPolicy(address account) public view virtual returns (bool) {
        return hasRole(POLICY_ROLE, account);
    }
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
pragma solidity ^0.8.4;

/// @title LibTreasury
library LibTreasury
{

    enum STATUS {
        NONE,              //
        RESERVEDEPOSITOR,  // 트래저리에 예치할수있는 권한
        RESERVESPENDER,    // 트래저리에서 자산 사용할 수 있는 권한
        RESERVETOKEN,      // 트래저리에서 사용가능한 토큰
        RESERVEMANAGER,     // 트래저리 어드민 권한
        LIQUIDITYDEPOSITOR, // 트래저리에 유동성 권한
        LIQUIDITYTOKEN,     // 트래저리에 유동성 토큰으로 사용할 수 있는 토큰
        LIQUIDITYMANAGER,   // 트래저리에 유동성 제공 가능자
        REWARDMANAGER,       // 트래저리에 민트 사용 권한.
        BONDER,              // 본더
        STAKER                  // 스테이커
    }

    // 민트된 양에서 원금(토스 평가금)빼고,
    // 나머지에서 기관에 분배 정보 (기관주소, 남는금액에서 퍼센트)의 구조체
    struct Minting {
        address mintAddress;
        uint256 mintPercents;
    }

    function getStatus(uint role) external pure returns (STATUS _status) {
        if (role == uint(STATUS.RESERVEDEPOSITOR)) return  STATUS.RESERVEDEPOSITOR;
        else if (role == uint(STATUS.RESERVESPENDER)) return  STATUS.RESERVESPENDER;
        else if (role == uint(STATUS.RESERVETOKEN)) return  STATUS.RESERVETOKEN;
        else if (role == uint(STATUS.RESERVEMANAGER)) return  STATUS.RESERVEMANAGER;
        else if (role == uint(STATUS.LIQUIDITYDEPOSITOR)) return  STATUS.LIQUIDITYDEPOSITOR;
        else if (role == uint(STATUS.LIQUIDITYTOKEN)) return  STATUS.LIQUIDITYTOKEN;
        else if (role == uint(STATUS.LIQUIDITYMANAGER)) return  STATUS.LIQUIDITYMANAGER;
        else if (role == uint(STATUS.REWARDMANAGER)) return  STATUS.REWARDMANAGER;
        else if (role == uint(STATUS.BONDER)) return  STATUS.BONDER;
        else if (role == uint(STATUS.STAKER)) return  STATUS.STAKER;
        else   return  STATUS.NONE;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../libraries/LibTreasury.sol";

interface ITreasury {


    /* ========== onlyPolicyOwner ========== */
    /// @dev Set Permissions enable to Address
    /// @param _status  permission number you want to change
    /// @param _address permission the address
    function enable(uint _status,  address _address) external ;

    /// @dev Set Permissions disable to Address
    /// @param _status  permission number you want to change
    /// @param _toDisable permission the address
    function disable(uint _status, address _toDisable) external;

    /// @dev Approval of token use, (Approve to staking contract)
    /// @param _addr  approve Address
    function approve(address _addr) external ;

    /// @dev Set mintRate. mintRate is the ratio of setting how many TOS mint per 1 ETH as TOS/ETH.
    /// @param _mrRate mintRate
    /// @param amount  mint amount (After checking whether backing is performed even after mint by amount, mint TOS in treasury.)
    function setMR(uint256 _mrRate, uint256 amount) external;


    /// @dev set the TOS-ETH Pool address
    /// @param _poolAddressTOSETH  TOS-ETH Pool address
    function setPoolAddressTOSETH(address _poolAddressTOSETH) external;

    /// @dev set the uniswapV3Factory address
    /// @param _uniswapFactory  uniswapV3factory address
    function setUniswapV3Factory(address _uniswapFactory) external;

    /// @dev set the mintRateDenominator
    /// @param _mintRateDenominator  mintRateDenominator
    function setMintRateDenominator(uint256 _mintRateDenominator) external;

    /// @dev Add erc20 token, which is used as a backing asset in treasury.
    /// @param _address  erc20 Address
    function addBackingList(address _address) external ;

    /// @dev delete erc20 token, which is used as a backing asset in treasury.
    /// @param _address  erc20 Address
    function deleteBackingList(address _address) external;

    /// @dev Set the foundation address and distribution rate.
    /// @param _addr      foundation Address
    /// @param _percents  percents
    function setFoundationDistributeInfo(
        address[] memory  _addr,
        uint256[] memory _percents
    ) external ;


    /* ========== onlyOwner ========== */

    /// @dev Mint TOS and send tos to recipient. Decide whether to distribute to the foundation or not according to the distribution.
    /// @param _mintAmount      mintAmount
    /// @param _distribute      Foundation distribution check
    function requestMint(uint256 _mintAmount, bool _distribute) external ;

    /// @dev addbackingList called by bonder
    /// @param _address         erc20 Address
    function addBondAsset(
        address _address
    )
        external;

    /* ========== onlyStaker ========== */

    /// @dev TOS transfer called by Staker
    /// @param _recipient   recipient Address
    /// @param _amount      recipient get Amount
    function requestTransfer(address _recipient, uint256 _amount)  external;

    /* ========== Anyone can execute ========== */

    /* ========== VIEW ========== */

    /// @dev return the now mintRate
    /// @return uint256  mintRate
    function getMintRate() external view returns (uint256);

    /// @dev How much tokens are valued as TOS
    /// @return uint256  the amount evaluated as TOS
    function backingRateETHPerTOS() external view returns (uint256);

    /// @dev check if registry contains address
    /// @return (bool, uint256)
    function indexInRegistry(address _address, LibTreasury.STATUS _status) external view returns (bool, uint256);


    /// @dev return treasury tos balance
    /// @return uint256
    function enableStaking() external view returns (uint256);

    /// @dev The assets held by the treasury are converted into ETH and returned
    /// @return uint256
    function backingReserve() external view returns (uint256) ;

    /// @dev Total number of tokens backing by treasury
    /// @return uint256
    function totalBacking() external view returns (uint256);

    /// @dev Returns the backing information of all backings
    /// @return erc20Address   erc20Address
    function allBacking() external view returns (
        address[] memory erc20Address
    );

    /// @dev Returns the total length of mintings
    /// @return uint256  mintings
    function totalMinting() external view returns(uint256) ;

    /// @dev Returns the mintings information of mintings index
    /// @param _index   mintings.index
    /// @return mintAddress   mintAddress
    /// @return mintPercents  mintPercents
    function viewMintingInfo(uint256 _index)
        external view returns(address mintAddress, uint256 mintPercents);

    /// @dev Returns the mintings information of all mintings
    /// @return mintAddress   mintAddress
    /// @return mintPercents  mintPercents
    function allMinting() external view
        returns (
            address[] memory mintAddress,
            uint256[] memory mintPercents
            );

    /// @dev check the permission
    /// @param role      STATUS
    /// @param account   address
    /// @return bool     true or false
    function hasPermission(uint role, address account) external view returns (bool);

    /// @dev Check if mint can be added as much as amount when mintRate is change
    /// @param _checkMintRate      change mintRate
    /// @param amount              mint Amount
    /// @return bool               true or false
    function checkTosSolvencyAfterTOSMint (uint256 _checkMintRate, uint256 amount) external view returns (bool);

    /// @dev Check if mint can be added as much as amount when now mintRate
    /// @param amount              mint Amount
    /// @return bool               true or false
    function checkTosSolvency (uint256 amount) external view returns (bool);

    /// @dev return The value calculated by converting the value of all assets held by the treasury into ETH
    /// @return uint256 ETH Value
    function backingReserveETH() external view returns (uint256);

    /// @dev return The value calculated by converting the value of all assets owned by the treasury into TOS
    /// @return uint256 TOS Value
    function backingReserveTOS() external view returns (uint256);

    /// @dev Return the current ETH/TOS price
    /// @return uint256 ETH/TOS
    function getETHPricePerTOS() external view returns (uint256);

    /// @dev Return the current TOS/ETH price
    /// @return uint256 TOS/ETH
    function getTOSPricePerETH() external view returns (uint256);

    /// @dev Check if the account is bond permission
    /// @param account   BonderAddress
    /// @return bool     true or false
    function isBonder(address account) external view returns (bool);

    /// @dev Check if the account has staker permission
    /// @param account   stakerAddress
    /// @return bool     true or false
    function isStaker(address account) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITreasuryEvent{

    /// @dev This event occurs when permission is change.
    /// @param addr    address
    /// @param status  STATUS
    /// @param result  true or false
    event Permissioned(address addr, uint indexed status, bool result);

    /// @dev This event occurs when setting the mint rate.
    /// @param mrRate    the mint rate
    /// @param amount    the TOS amountto add
    event SetMintRate(uint256 mrRate, uint256 amount);

    /// @dev This event occurs when set the PoolAddressTOSETH
    /// @param _poolAddressTOSETH    the pool address of TOS-ETH pair
    event SetPoolAddressTOSETH(address _poolAddressTOSETH);

    /// @dev This event occurs when set the UniswapV3Factory
    /// @param _uniswapFactory    the address of uniswapFactory
    event SetUniswapV3Factory(address _uniswapFactory);

    /// @dev This event occurs when set the MintRateDenominator
    /// @param _mintRateDenominator    the _mintRateDenominator
    event SetMintRateDenominator(uint256 _mintRateDenominator);

    /// @dev This event occurs when add the BackingList
    /// @param _address    the asset address
    event AddedBackingList(address _address);

    /// @dev This event occurs when delete the BackingList
    /// @param _address    the asset address
    event DeletedBackingList(
        address _address
    );


    /// @dev This event occurs when set the Foundation Distribute Info
    /// @param _addr    the address list
    /// @param _percents    the percentage list
    event SetFoundationDistributeInfo(
        address[]  _addr,
        uint256[] _percents
    );

    /// @dev This event occurs when request mint and transfer TOS
    /// @param _mintAmount    the TOS amount to mint
    /// @param _distribute   If true,  distribute a percentage of the remaining amount to the foundation after mint and transfer.
    event RquestedMint(
        uint256 _mintAmount,
        bool _distribute
    );

    /// @dev This event occurs when add the BondAsset
    /// @param _address    the asset address
    /// @param _tosPooladdress    the asset's _tosPooladdress
    /// @param _fee    the _tosPool's fee
    event AddedBondAsset(
        address _address,
        address _tosPooladdress,
        uint24 _fee
    );

    /// @dev This event occurs when request transfer TOS
    /// @param _recipient    the recipient
    /// @param _amount   the TOS amount to transfer
    event RequestedTransfer(
        address _recipient,
        uint256 _amount
    );

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

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

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");

    bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
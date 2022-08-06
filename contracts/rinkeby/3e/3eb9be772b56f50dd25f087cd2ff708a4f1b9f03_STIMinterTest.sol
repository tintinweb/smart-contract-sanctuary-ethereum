// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./STIMinter.sol";
import "../bni/priceOracle/IPriceOracle.sol";
import "../bni/constant/AuroraConstantTest.sol";
import "../bni/constant/AvaxConstantTest.sol";
import "../bni/constant/BscConstantTest.sol";
import "../bni/constant/EthConstantTest.sol";
import "../../libs/Const.sol";

contract STIMinterTest is STIMinter {

    function initialize(
        address _admin, address _biconomy,
        address _STI, address _priceOracle
    ) external override initializer {
        __Ownable_init();

        admin = _admin;
        trustedForwarder = _biconomy;
        STI = ISTI(_STI);
        priceOracle = IPriceOracle(_priceOracle);

        chainIDs.push(EthConstantTest.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // ETH
        chainIDs.push(EthConstantTest.CHAINID);
        tokens.push(EthConstantTest.MATIC);
        chainIDs.push(BscConstantTest.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // BNB
        chainIDs.push(AvaxConstantTest.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // AVAX
        chainIDs.push(AuroraConstantTest.CHAINID);
        tokens.push(AuroraConstantTest.WNEAR);

        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%

        updateTid();

        urls.push("http://localhost:8001/");
        gatewaySigner = _admin;
    }

    /// @return the price of USDT in USD.
    function getUSDTPriceInUSD() public view override returns(uint, uint8) {
        return priceOracle.getAssetPrice(EthConstantTest.USDT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../bni/priceOracle/IPriceOracle.sol";
import "../bni/constant/AuroraConstant.sol";
import "../bni/constant/AvaxConstant.sol";
import "../bni/constant/BscConstant.sol";
import "../bni/constant/EthConstant.sol";
import "../../libs/Const.sol";
import "../../libs/BaseRelayRecipient.sol";

interface ISTI is IERC20Upgradeable {
    function decimals() external view returns (uint8);
    function mint(address account_, uint256 amount_) external;
    function burn(uint256 amount) external;
    function burnFrom(address account_, uint256 amount_) external;
}

error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

interface Gateway {
    function getCurrentTokenCompositionPerc1() external view returns (
        uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs,
        bytes memory sig
    );
    function getAllPoolInUSD1() external view returns (
        uint[] memory _allPoolInUSDs,
        bytes memory sig
    );
    function getPricePerFullShare1() external view returns (
        uint[] memory _allPoolInUSDs,
        bytes memory sig
    );
    function getAPR1() external view returns (
        uint[] memory _allPoolInUSDs,  uint[] memory _APRs,
        bytes memory sig
    );
    function getDepositTokenComposition1() external view returns (
        uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs,
        bytes memory sig
    );
    function getPoolsUnbonded1() external view returns (
        uint[] memory _chainIDs, address[] memory _tokens,
        uint[] memory _waitings, uint[] memory _waitingInUSDs,
        uint[] memory _unbondeds, uint[] memory _unbondedInUSDs,
        uint[] memory _waitForTses,
        bytes memory sig
    );
    function getWithdrawableSharePerc1() external view returns(
        uint _sharePerc,
        bytes memory sig
    );
}

contract STIMinter is BaseRelayRecipient, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    uint[] public chainIDs;
    address[] public tokens;
    uint[] public targetPercentages;
    mapping(uint => mapping(address => uint)) public tid; // Token indices in arrays

    address public admin;
    ISTI public STI;
    IPriceOracle public priceOracle;

    string[] public urls;
    address public gatewaySigner;

    event SetAdminWallet(address oldAdmin, address newAdmin);
    event SetBiconomy(address oldBiconomy, address newBiconomy);
    event AddToken(uint chainID, address token, uint tid);
    event RemoveToken(uint chainID, address token, uint targetPerc, uint tid);
    event Mint(address caller, uint amtDeposit, uint shareMinted);
    event Burn(address caller, uint shareBurned);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
        address _admin, address _biconomy,
        address _STI, address _priceOracle
    ) external virtual initializer {
        __Ownable_init();

        admin = _admin;
        trustedForwarder = _biconomy;
        STI = ISTI(_STI);
        priceOracle = IPriceOracle(_priceOracle);

        chainIDs.push(EthConstant.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // ETH
        chainIDs.push(EthConstant.CHAINID);
        tokens.push(EthConstant.MATIC);
        chainIDs.push(BscConstant.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // BNB
        chainIDs.push(AvaxConstant.CHAINID);
        tokens.push(Const.NATIVE_ASSET); // AVAX
        chainIDs.push(AuroraConstant.CHAINID);
        tokens.push(AuroraConstant.WNEAR);

        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%
        targetPercentages.push(2000); // 20%

        updateTid();

        urls.push("http://localhost:8001/");
        gatewaySigner = _admin;
    }

    function updateTid() internal {
        uint[] memory _chainIDs = chainIDs;
        address[] memory _tokens = tokens;

        uint tokenCnt = _tokens.length;
        for (uint i = 0; i < tokenCnt; i ++) {
            tid[_chainIDs[i]][_tokens[i]] = i;
        }
    }

    function setAdmin(address _admin) external onlyOwner {
        address oldAdmin = admin;
        admin = _admin;
        emit SetAdminWallet(oldAdmin, _admin);
    }

    function setBiconomy(address _biconomy) external onlyOwner {
        address oldBiconomy = trustedForwarder;
        trustedForwarder = _biconomy;
        emit SetBiconomy(oldBiconomy, _biconomy);
    }

    function _msgSender() internal override(ContextUpgradeable, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function setGatewaySigner(address _signer) external onlyOwner {
        gatewaySigner = _signer;
    }

    /// @notice After this method called, setTokenCompositionTargetPerc should be called to adjust percentages.
    function addToken(uint _chainID, address _token) external onlyOwner {
        uint _tid = tid[_chainID][_token];
        require ((_tid == 0 && _chainID != chainIDs[0] && _token != tokens[0]), "Already added");

        chainIDs.push(_chainID);
        tokens.push(_token);
        targetPercentages.push(0);

        _tid = tokens.length-1;
        tid[_chainID][_token] = _tid;

        emit AddToken(_chainID, _token, _tid);
    }

    /// @notice After this method called, setTokenCompositionTargetPerc should be called to adjust percentages.
    function removeToken(uint _tid) external onlyOwner {
        uint tokenCnt = tokens.length;
        require(_tid < tokenCnt, "Invalid tid");

        uint _chainID = chainIDs[_tid];
        address _token = tokens[_tid];
        uint _targetPerc = targetPercentages[_tid];

        chainIDs[_tid] = chainIDs[tokenCnt-1];
        chainIDs.pop();
        tokens[_tid] = tokens[tokenCnt-1];
        tokens.pop();
        targetPercentages[_tid] = targetPercentages[tokenCnt-1];
        targetPercentages.pop();

        tid[_chainID][_token] = 0;
        updateTid();

        emit RemoveToken(_chainID, _token, _targetPerc, _tid);
    }

    /// @notice The length of array is based on token count.
    function setTokenCompositionTargetPerc(uint[] calldata _targetPerc) public onlyOwner {
        uint targetCnt = _targetPerc.length;
        require(targetCnt == targetPercentages.length, "Invalid count");

        uint sum;
        for (uint i = 0; i < targetCnt; i ++) {
            targetPercentages[i] = _targetPerc[i];
            sum += _targetPerc[i];
        }
        require(sum == Const.DENOMINATOR, "Invalid parameter");
    }

    /// @notice The length of array is based on token count. And the lengths should be same on the arraies.
    function getEachPoolInUSD(
        uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs
    ) private view returns (uint[] memory pools) {
        uint inputCnt = _tokens.length;
        uint tokenCnt = tokens.length;
        pools = new uint[](tokenCnt);

        for (uint i = 0; i < inputCnt; i ++) {
            uint _chainID = _chainIDs[i];
            address _token = _tokens[i];
            uint _tid = tid[_chainID][_token];
            if (tokenCnt <= _tid) continue;
            if (_tid == 0 && (_chainID != chainIDs[0] || _token != tokens[0])) continue;

            pools[_tid] = _poolInUSDs[i];
        }
    }

    /// @notice The length of array is based on token count. And the lengths should be same on the arraies.
    function getCurrentTokenCompositionPerc(
        uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs
    ) public view returns (
        uint[] memory, address[] memory, uint[] memory pools, uint[] memory percentages
    ) {
        pools = getEachPoolInUSD(_chainIDs, _tokens, _poolInUSDs);
        uint poolCnt = pools.length;

        uint allPool;
        for (uint i = 0; i < poolCnt; i ++) {
            allPool += pools[i];
        }

        percentages = new uint[](poolCnt);
        for (uint i = 0; i < poolCnt; i ++) {
            percentages[i] = allPool == 0 ? targetPercentages[i] : pools[i] * Const.DENOMINATOR / allPool;
        }

        return (chainIDs, tokens, pools, percentages);
    }
    function getCurrentTokenCompositionPerc1() external view returns (
        uint[] memory, address[] memory, uint[] memory, uint[] memory
    ) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getCurrentTokenCompositionPerc1.selector),
            STIMinter.getCurrentTokenCompositionPercWithSig.selector,
            abi.encode(0)
        );
    }
    function getCurrentTokenCompositionPercWithSig(bytes calldata result, bytes calldata extraData) external view returns(
        uint[] memory, address[] memory, uint[] memory, uint[] memory
    ) {
        extraData;
        (uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs, bytes memory sig)
            = abi.decode(result, (uint[], address[], uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_chainIDs, _tokens, _poolInUSDs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        return getCurrentTokenCompositionPerc(_chainIDs, _tokens, _poolInUSDs);
    }

    /// @notice The length of array is based on network count. And the lengths should be same on the arraies.
    function getAllPoolInUSD(uint[] memory _allPoolInUSDs) public pure returns (uint) {
        uint networkCnt = _allPoolInUSDs.length;
        uint allPoolInUSD;
        for (uint i = 0; i < networkCnt; i ++) {
            allPoolInUSD += _allPoolInUSDs[i];
        }
        return allPoolInUSD;
    }
    function getAllPoolInUSD1() external view returns (uint) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getAllPoolInUSD1.selector),
            STIMinter.getAllPoolInUSD1WithSig.selector,
            abi.encode(0)
        );
    }
    function getAllPoolInUSD1WithSig(bytes calldata result, bytes calldata extraData) external view returns(uint) {
        extraData;
        (uint[] memory _allPoolInUSDs, bytes memory sig) = abi.decode(result, (uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_allPoolInUSDs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        return getAllPoolInUSD(_allPoolInUSDs);
    }

    /// @notice Can be used for calculate both user shares & APR
    function getPricePerFullShare(uint[] memory _allPoolInUSDs) public view returns (uint) {
        uint _totalSupply = STI.totalSupply();
        if (_totalSupply == 0) return 1e18;
        return getAllPoolInUSD(_allPoolInUSDs) * 1e18 / _totalSupply;
    }
    function getPricePerFullShare1() external view returns (uint) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getPricePerFullShare1.selector),
            STIMinter.getPricePerFullShare1WithSig.selector,
            abi.encode(0)
        );
    }
    function getPricePerFullShare1WithSig(bytes calldata result, bytes calldata extraData) external view returns(uint) {
        extraData;
        (uint[] memory _allPoolInUSDs, bytes memory sig) = abi.decode(result, (uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_allPoolInUSDs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        return getPricePerFullShare(_allPoolInUSDs);
    }

    /// @notice The length of array is based on network count. And the lengths should be same on the arraies.
    function getAPR(uint[] memory _allPoolInUSDs, uint[] memory _APRs) public pure returns (uint) {
        uint networkCnt = _allPoolInUSDs.length;
        require(networkCnt == _APRs.length, "Not match array length");

        uint pool = getAllPoolInUSD(_allPoolInUSDs);
        if (pool == 0) return 0;

        uint allApr;
        for (uint i = 0; i < networkCnt; i ++) {
            allApr += (_APRs[i] * _allPoolInUSDs[i]);
        }
        return (allApr / pool);
    }
    function getAPR1() external view returns (uint) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getAPR1.selector),
            STIMinter.getAPR1WithSig.selector,
            abi.encode(0)
        );
    }
    function getAPR1WithSig(bytes calldata result, bytes calldata extraData) external view returns(uint) {
        extraData;
        (uint[] memory _allPoolInUSDs,  uint[] memory _APRs, bytes memory sig) = abi.decode(result, (uint[], uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_allPoolInUSDs, _APRs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        return getAPR(_allPoolInUSDs, _APRs);
    }

    /// @return the price of USDT in USD.
    function getUSDTPriceInUSD() public view virtual returns(uint, uint8) {
        return priceOracle.getAssetPrice(AvaxConstant.USDT);
    }

    /// @notice The length of array is based on token count. And the lengths should be same on the arraies.
    /// @param _USDTAmt amount of USDT with 6 decimals
    /// @return _USDTAmts amount of USDT should be deposited to each pools
    function getDepositTokenComposition(
        uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs, uint _USDTAmt
    ) public view returns (
        uint[] memory, address[] memory, uint[] memory _USDTAmts
    ) {
        (,, uint[] memory pools, uint[] memory perc) = getCurrentTokenCompositionPerc(_chainIDs, _tokens, _poolInUSDs);
        uint poolCnt = perc.length;
        (uint USDTPriceInUSD, uint8 USDTPriceDecimals) = getUSDTPriceInUSD();

        uint allPool = _USDTAmt * 1e12 * USDTPriceInUSD / (10 ** USDTPriceDecimals); // USDT's decimals is 6
        for (uint i = 0; i < poolCnt; i ++) {
            allPool += pools[i];
        }

        uint totalAllocation;
        uint[] memory allocations = new uint[](poolCnt);
        for (uint i = 0; i < poolCnt; i ++) {
            uint target = allPool * targetPercentages[i] / Const.DENOMINATOR;
            if (pools[i] < target) {
                uint diff = target - pools[i];
                allocations[i] = diff;
                totalAllocation += diff;
            }
        }

        _USDTAmts = new uint[](poolCnt);
        for (uint i = 0; i < poolCnt; i ++) {
            _USDTAmts[i] = _USDTAmt * allocations[i] / totalAllocation;
        }

        return (chainIDs, tokens, _USDTAmts);
    }
    function getDepositTokenComposition1(uint _USDTAmt) external view returns (
        uint[] memory, address[] memory, uint[] memory
    ) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getDepositTokenComposition1.selector),
            STIMinter.getDepositTokenComposition1WithSig.selector,
            abi.encode(_USDTAmt)
        );
    }
    function getDepositTokenComposition1WithSig(bytes calldata result, bytes calldata extraData) external view returns(
        uint[] memory, address[] memory, uint[] memory
    ) {
        (uint _USDTAmt) = abi.decode(extraData, (uint));
        (uint[] memory _chainIDs, address[] memory _tokens, uint[] memory _poolInUSDs, bytes memory sig)
            = abi.decode(result, (uint[], address[], uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_chainIDs, _tokens, _poolInUSDs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        return getDepositTokenComposition(_chainIDs, _tokens, _poolInUSDs, _USDTAmt);
    }

    ///@return _chainIDs is an array of chain IDs.
    ///@return _tokens is an array of tokens.
    ///@return _waitings is an array of token amounts that is not unbonded.
    ///@return _waitingInUSDs is an array of USD value of token amounts that is not unbonded.
    ///@return _unbondeds is an array of token amounts that is unbonded.
    ///@return _unbondedInUSDs is an array USD value of token amounts that is unbonded.
    ///@return _waitForTses is an array of timestamps to wait to the next claim.
    function getPoolsUnbonded1(address _account) external view returns (
        uint[] memory, // _chainIDs
        address[] memory, // _tokens
        uint[] memory, // _waitings
        uint[] memory, // _waitingInUSDs
        uint[] memory, // _unbondeds
        uint[] memory, // _unbondedInUSDs
        uint[] memory // _waitForTses
    ) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getPoolsUnbonded1.selector),
            STIMinter.getPoolsUnbonded1WithSig.selector,
            abi.encode(_account)
        );
    }
    function getPoolsUnbonded1WithSig(bytes calldata result, bytes calldata) external view returns(
        uint[] memory _chainIDs,
        address[] memory _tokens,
        uint[] memory _waitings,
        uint[] memory _waitingInUSDs,
        uint[] memory _unbondeds,
        uint[] memory _unbondedInUSDs,
        uint[] memory _waitForTses
    ) {
        bytes memory sig;
        (_chainIDs, _tokens, _waitings, _waitingInUSDs, _unbondeds, _unbondedInUSDs, _waitForTses, sig)
            = abi.decode(result, (uint[], address[], uint[], uint[], uint[], uint[], uint[], bytes));

        bytes32 messageHash1 = keccak256(abi.encodePacked(_chainIDs, _tokens, _waitings, _waitingInUSDs, _unbondeds, _unbondedInUSDs));
        bytes32 messageHash2 = keccak256(abi.encodePacked(_waitForTses));
        bytes32 messageHash = keccak256(abi.encodePacked(messageHash1, messageHash2));
        address recovered = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");
    }

    /// @dev mint STIs according to the deposited USDT
    /// @param _pool total USD worth in all pools of STI after deposited
    /// @param _account account to which STIs will be minted
    /// @param _USDTAmt the deposited amount of USDT with 6 decimals
    function mintByAdmin(uint _pool, address _account, uint _USDTAmt) external onlyOwnerOrAdmin nonReentrant whenNotPaused {
        (uint USDTPriceInUSD, uint8 USDTPriceDecimals) = getUSDTPriceInUSD();
        uint amtDeposit = _USDTAmt * 1e12 * USDTPriceInUSD / (10 ** USDTPriceDecimals); // USDT's decimals is 6
        _pool = (amtDeposit < _pool) ? _pool - amtDeposit : 0;

        uint _totalSupply = STI.totalSupply();
        uint share = (_pool == 0 ||_totalSupply == 0)  ? amtDeposit : _totalSupply * amtDeposit / _pool;
        // When assets invested in strategy, around 0.3% lost for swapping fee. We will consider it in share amount calculation to avoid pricePerFullShare fall down under 1.
        share = share * 997 / 1000;

        STI.mint(_account, share);
        emit Mint(_account, amtDeposit, share);
    }

    /// @param _share amount of STI to be withdrawn
    /// @return _sharePerc percentage of assets which should be withdrawn. It's 18 decimals
    function getWithdrawPerc(address _account, uint _share) public view returns (uint _sharePerc) {
        require(0 < _share && _share <= STI.balanceOf(_account), "Invalid share amount");
        return (_share * 1e18) / STI.totalSupply();
    }

    function getWithdrawableSharePerc1() external view returns (
        uint // _sharePerc
    ) {
        revert OffchainLookup(address(this), urls,
            abi.encodeWithSelector(Gateway.getWithdrawableSharePerc1.selector),
            STIMinter.getWithdrawableSharePerc1WithSig.selector,
            abi.encode(0)
        );
    }
    function getWithdrawableSharePerc1WithSig(bytes calldata result, bytes calldata extraData) external view returns(
        uint _sharePerc
    ) {
        extraData;
        (uint[] memory _chainIDs, uint[] memory _sharePercs, bytes memory sig)
            = abi.decode(result, (uint[], uint[], bytes));

        address recovered = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_chainIDs, _sharePercs))
        )).recover(sig);
        require(gatewaySigner == recovered, "Signer is incorrect");

        uint length = _sharePercs.length;
        if (length > 0) {
            _sharePerc = _sharePercs[0];
        }
        for (uint i = 1; i < length; i++) {
            uint perc = _sharePercs[i];
            if (_sharePerc > perc) _sharePerc = perc;
        }
    }

    /// @dev mint STIs according to the deposited USDT
    /// @param _account account to which STIs will be minted
    /// @param _share amount of STI to be burnt
    function burnByAdmin(address _account, uint _share) external onlyOwnerOrAdmin nonReentrant {
        require(0 < _share && _share <= STI.balanceOf(_account), "Invalid share amount");
        STI.burnFrom(_account, _share);
        emit Burn(_account, _share);
    }

    function setUrls(string[] memory _urls) external onlyOwner {
        urls = _urls;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IPriceOracle {

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] memory assets, address[] memory sources) external;

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return prices The prices of the given assets
     */
    function getAssetsPrices(address[] memory assets) external view returns (uint[] memory prices, uint8[] memory decimalsArray);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param asset The asset address
     * @return price The prices of the given assets
     */
    function getAssetPrice(address asset) external view returns (uint price, uint8 decimals);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library AuroraConstantTest {
    uint internal constant CHAINID = 1313161555;

    address internal constant BSTN = 0x9f1F933C660a1DC856F0E0Fe058435879c5CCEf0; // Should be replaced with testnet address
    address internal constant META = 0xc21Ff01229e982d7c8b8691163B0A3Cb8F357453; // Should be replaced with testnet address
    address internal constant stNEAR = 0x2137df2e54abd6bF1c1a8c1739f2EA6A8C15F144;
    address internal constant USDC = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802; // Should be replaced with testnet address
    address internal constant USDT = 0xF9C249974c1Acf96a59e5757Cc9ba7035cE489B1;
    address internal constant WETH = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB; // Should be replaced with testnet address
    address internal constant WNEAR = 0x4861825E75ab14553E5aF711EbbE6873d369d146;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library AvaxConstantTest {
    uint internal constant CHAINID = 43113;

    address internal constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664; // Should be replaced with testnet address
    address internal constant USDT = 0x78ae2880bd1672b49a33cF796CF53FE6db0aB01D;
    address internal constant WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address internal constant aAVAXb = 0xBd97c29aa3E83C523C9714edCA8DB8881841a593;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library BscConstantTest {
    uint internal constant CHAINID = 97;

    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // Should be replaced with testnet address
    address internal constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; // Should be replaced with testnet address
    address internal constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // Should be replaced with testnet address
    address internal constant USDT = 0x1F326a8CA5399418a76eA0efa0403Cbb00790C67;
    address internal constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    address internal constant aBNBb = 0xaB56897fE4e9f0757e02B54C27E81B9ddd6A30AE;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library EthConstantTest {
    uint internal constant CHAINID = 4;

    address internal constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // Should be replaced with testnet address
    address internal constant stETH = 0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD;
    address internal constant stMATIC = 0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599; // Should be replaced with testnet address
    address internal constant USDC = 0xDf5324ebe6F6b852Ff5cBf73627eE137e9075276;
    address internal constant USDT = 0x21e48034753E490ff04f2f75f7CAEdF081B320d5;
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Const {

    uint internal constant DENOMINATOR = 10000;

    uint internal constant APR_SCALE = 1e18;
    
    uint internal constant YEAR_IN_SEC = 365 days;

    address internal constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library AuroraConstant {
    uint internal constant CHAINID = 1313161554;

    address internal constant BSTN = 0x9f1F933C660a1DC856F0E0Fe058435879c5CCEf0;
    address internal constant META = 0xc21Ff01229e982d7c8b8691163B0A3Cb8F357453;
    address internal constant stNEAR = 0x07F9F7f963C5cD2BBFFd30CcfB964Be114332E30;
    address internal constant USDC = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;
    address internal constant USDT = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;
    address internal constant WETH = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;
    address internal constant WNEAR = 0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library AvaxConstant {
    uint internal constant CHAINID = 43114;

    address internal constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address internal constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    address internal constant aAVAXb = 0x6C6f910A79639dcC94b4feEF59Ff507c2E843929;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library BscConstant {
    uint internal constant CHAINID = 56;

    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address internal constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address internal constant aBNBb = 0xBb1Aa6e59E5163D8722a122cd66EBA614b59df0d;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library EthConstant {
    uint internal constant CHAINID = 1;

    address internal constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address internal constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant stMATIC = 0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "../interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    function versionRecipient() external virtual view returns (string memory);
}